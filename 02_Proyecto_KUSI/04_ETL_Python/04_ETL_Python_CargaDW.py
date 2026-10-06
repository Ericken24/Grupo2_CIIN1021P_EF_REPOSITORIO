"""
KUSI MINIMARKET — ETL al Data Warehouse (v2, Capítulo 8 del informe EF)

Flujo: CSV -> extracción -> transformación -> validación -> dimensiones/hecho
       -> carga atómica -> validación post-carga -> log por transformación.

Mejoras respecto de la v1 (03_ETL_Python_CargaDW.py):
  1. Log POR TRANSFORMACIÓN (T01..T12): el rubro EF exige documentar cada
     transformación aplicada, no solo los totales por entidad.
  2. Conciliación automática: el ETL se detiene si el hecho no cuadra con las
     ventas válidas o si existen claves huérfanas respecto de las dimensiones.
  3. Carga ATÓMICA: borrado + inserción dentro de una sola transacción; si algo
     falla, el DW queda como estaba (ROLLBACK).
  4. Validación POST-CARGA: conteos leídos desde KUSI_DW y comparados con lo
     transformado.
  5. Rutas y modo de carga por parámetros (no hace falta editar el script).

Uso (PowerShell):
  python 04_ETL_Python_CargaDW_v2.py --csv "C:\\KUSI_MINIMARKET\\csv_fuente" --solo-csv
  python 04_ETL_Python_CargaDW_v2.py --csv "C:\\KUSI_MINIMARKET\\csv_fuente" --servidor ".\\SQLEXPRESS" --cargar

El ETL NO modifica los CSV fuente (supuesto R10: no corregir en silencio).
"""
import argparse
import sys
import urllib.parse
from datetime import datetime
from pathlib import Path

import pandas as pd

# ------------------------------ PARÁMETROS ------------------------------
ap = argparse.ArgumentParser(description="ETL KUSI MINIMARKET -> KUSI_DW")
ap.add_argument("--csv", default=r"C:\KUSI_MINIMARKET\csv_fuente")
ap.add_argument("--salida", default=r"C:\KUSI_MINIMARKET\dw_listos_para_cargar")
ap.add_argument("--servidor", default=r".\SQLEXPRESS")
ap.add_argument("--base", default="KUSI_DW")
g = ap.add_mutually_exclusive_group()
g.add_argument("--cargar", action="store_true", help="Carga a SQL Server (modo por defecto)")
g.add_argument("--solo-csv", action="store_true", help="Solo genera CSV y log, sin cargar")
args = ap.parse_args()

CARPETA_CSV = Path(args.csv)
CARPETA_SALIDA = Path(args.salida)
CARPETA_SALIDA.mkdir(parents=True, exist_ok=True)
CARGAR = not args.solo_csv

CADENA_ODBC = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    f"SERVER={args.servidor};DATABASE={args.base};"
    "Trusted_Connection=yes;TrustServerCertificate=yes;"
)
CONNECTION_STRING = "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(CADENA_ODBC)

FECHA_INICIO = pd.Timestamp("2023-01-01")   # R01
FECHA_FIN = pd.Timestamp("2025-08-31")      # R01

DICCIONARIO_DISTRITOS = {                    # Q05
    "CAJAMARCA": "Cajamarca", "BAÑOS DEL INCA": "Baños del Inca",
    "BANOS DEL INCA": "Baños del Inca", "SAN SEBASTIÁN": "San Sebastián",
    "SAN SEBASTIAN": "San Sebastián", "PORCON": "Porcón", "PORCÓN": "Porcón",
    "LA ENCAÑADA": "La Encañada", "JESUS": "Jesús", "JESÚS": "Jesús",
}

log_ejecucion = []
T0 = datetime.now()


def log(origen, leidas, aceptadas, motivo=""):
    """Registra una transformación. Mantiene las columnas de dw.LogETL."""
    rech = int(leidas - aceptadas)
    log_ejecucion.append({
        "fecha_ejecucion": datetime.now(), "origen": origen,
        "filas_leidas": int(leidas), "filas_aceptadas": int(aceptadas),
        "filas_rechazadas": rech, "motivo_rechazo": motivo[:480],
    })
    print(f"[LOG] {origen}: leidas={leidas:,} aceptadas={aceptadas:,} rechazadas={rech:,}")


def normalizar_distrito(v):
    if pd.isna(v):
        return None
    return DICCIONARIO_DISTRITOS.get(str(v).strip().upper(), str(v).strip().title())


def abortar(msg):
    print(f"\n[ERROR] {msg}\nEl ETL se detiene sin cargar nada al DW.")
    sys.exit(1)


# ============================ 1. EXTRACCIÓN =============================
print("=== 1. EXTRACCIÓN ===")
nombres = ["categorias", "proveedores", "sucursales", "metodos_pago", "productos",
            "empleados", "clientes", "ventas", "detalle_ventas", "compras",
            "detalle_compras", "feriados_peru"]
for n in nombres:
    if not (CARPETA_CSV / f"{n}.csv").exists():
        abortar(f"No se encontró {CARPETA_CSV / (n + '.csv')}")
d = {n: pd.read_csv(CARPETA_CSV / f"{n}.csv") for n in nombres}
for n, df in d.items():
    print(f"{n}: {len(df):,} filas")
categorias, proveedores, sucursales = d["categorias"], d["proveedores"], d["sucursales"]
metodos_pago, productos, empleados = d["metodos_pago"], d["productos"], d["empleados"]
clientes, ventas, detalle_ventas, feriados = d["clientes"], d["ventas"], d["detalle_ventas"], d["feriados_peru"]
log("T01 Extraccion CSV (ventas)", len(ventas), len(ventas))
log("T01 Extraccion CSV (detalle_ventas)", len(detalle_ventas), len(detalle_ventas))

# ========================== 2. TRANSFORMACIÓN ===========================
print("\n=== 2. TRANSFORMACIÓN ===")
# T02 Conversión de tipos. errors='coerce' -> NaT/NaN, que se cuentan (no se ocultan).
ventas["fecha_venta"] = pd.to_datetime(ventas["fecha_venta"], errors="coerce")
for c in ["total_venta", "subtotal", "igv"]:
    ventas[c] = pd.to_numeric(ventas[c], errors="coerce")
for c in ["cantidad", "precio_unitario", "subtotal"]:
    detalle_ventas[c] = pd.to_numeric(detalle_ventas[c], errors="coerce")
clientes_t = clientes.copy()
clientes_t["fecha_registro"] = pd.to_datetime(clientes_t["fecha_registro"], errors="coerce")
n_inval = int((ventas["fecha_venta"].isna() | ventas["total_venta"].isna()).sum())
log("T02 Conversion de tipos (ventas)", len(ventas), len(ventas) - n_inval,
    "fecha_venta o total_venta no convertible")

# T03 Normalización de distritos (Q05)
orig = clientes_t["distrito"].copy()
clientes_t["distrito"] = clientes_t["distrito"].apply(normalizar_distrito)
cambiados = int((orig.fillna("") != clientes_t["distrito"].fillna("")).sum())
log("T03 Normalizacion de distritos (clientes)", len(clientes_t), len(clientes_t),
    f"{cambiados} valores normalizados con diccionario (no es rechazo)")
sucursales["distrito"] = sucursales["distrito"].apply(normalizar_distrito)

# T04 Feriados: fecha válida y sin duplicados
fer_antes = len(feriados)
feriados["fecha"] = pd.to_datetime(feriados["fecha"], errors="coerce")
feriados = feriados.dropna(subset=["fecha"]).drop_duplicates(subset=["fecha"])
log("T04 Depuracion de feriados", fer_antes, len(feriados), "fechas invalidas o duplicadas")

# ============================ 3. DIMENSIONES =============================
print("\n=== 3. DIMENSIONES ===")
rango = pd.date_range(FECHA_INICIO, FECHA_FIN, freq="D")
dia_semana = (rango.dayofweek + 1) % 7 + 1          # domingo=1 ... sábado=7
feriados_set = set(feriados["fecha"].dt.date)
meses = {1: "Enero", 2: "Febrero", 3: "Marzo", 4: "Abril", 5: "Mayo", 6: "Junio", 7: "Julio",
        8: "Agosto", 9: "Septiembre", 10: "Octubre", 11: "Noviembre", 12: "Diciembre"}
dias = {1: "Domingo", 2: "Lunes", 3: "Martes", 4: "Miércoles", 5: "Jueves", 6: "Viernes", 7: "Sábado"}
dim_fecha = pd.DataFrame({
    "KeyFecha": rango.strftime("%Y%m%d").astype(int), "Fecha": rango.date,
    "Anio": rango.year, "Mes": rango.month, "NombreMes": rango.month.map(meses),
    "Trimestre": rango.quarter, "DiaSemana": dia_semana,
    "NombreDia": [dias[int(x)] for x in dia_semana],
    "EsFinDeSemana": rango.dayofweek >= 5, "EsFeriado": [f.date() in feriados_set for f in rango],
})
log("T05 Generacion DimFecha (calendario)", len(rango), len(dim_fecha))

dim_sucursal = sucursales.rename(columns={"id": "KeySucursal", "nombre": "NombreSucursal", "distrito": "Distrito",
    "tipo": "TipoLocal", "vende": "EsOperativa", "apertura": "FechaApertura"})[
    ["KeySucursal", "NombreSucursal", "Distrito", "TipoLocal", "EsOperativa", "FechaApertura"]].copy()

dim_producto = (productos.merge(categorias[["id_categoria", "nombre_categoria"]], on="id_categoria", how="left")
                .merge(proveedores[["id_proveedor", "nombre_proveedor"]], on="id_proveedor", how="left")
                .rename(columns={"id_producto": "KeyProducto", "codigo_barras": "CodigoBarras",
                                    "nombre_producto": "NombreProducto", "nombre_categoria": "Categoria",
                                    "nombre_proveedor": "Proveedor", "precio_venta": "PrecioVentaActual"})[
    ["KeyProducto", "CodigoBarras", "NombreProducto", "Categoria", "Proveedor", "PrecioVentaActual"]])
sin_cat = int((dim_producto["Categoria"].isna() | dim_producto["Proveedor"].isna()).sum())
log("T06 Enriquecimiento DimProducto (categoria+proveedor)", len(productos), len(productos) - sin_cat,
    "productos sin categoria o proveedor resuelto")

dim_metodo_pago = metodos_pago.rename(columns={"id_metodo_pago": "KeyMetodoPago",
    "nombre_metodo": "NombreMetodo", "tipo": "Tipo"})[["KeyMetodoPago", "NombreMetodo", "Tipo"]]
dim_empleado = (empleados.merge(sucursales[["id", "nombre"]], left_on="id_sucursal", right_on="id", how="left")
                .rename(columns={"id_empleado": "KeyEmpleado", "nombre_completo": "NombreCompleto",
                                    "cargo": "Cargo", "nombre": "Sucursal"})[
    ["KeyEmpleado", "NombreCompleto", "Cargo", "Sucursal"]])

# T07..T10 Reglas de elegibilidad de ventas (Q01, Q06, Q07, R09)
n0 = len(ventas)
en_periodo = ventas["fecha_venta"].dt.normalize().between(FECHA_INICIO, FECHA_FIN)
log("T07 Filtro periodo analitico (Q01)", n0, int(en_periodo.sum()), "ventas fuera de 2023-01-01..2025-08-31")
v1 = ventas[en_periodo]
con_total = v1["total_venta"] > 0
log("T08 Filtro total > 0 (Q06)", len(v1), int(con_total.sum()), "ventas con total cero")
v2 = v1[con_total]
detalle_ids = set(pd.to_numeric(detalle_ventas["id_venta"], errors="coerce").dropna().astype(int))
con_det = v2["id_venta"].astype(int).isin(detalle_ids)
log("T09 Filtro con detalle asociado (Q07)", len(v2), int(con_det.sum()), "ventas sin detalle")
v3 = v2[con_det]
compl = v3["estado"].eq("completada")
log("T10 Filtro estado completada (R09)", len(v3), int(compl.sum()), "ventas con estado distinto de completada")
ventas_validas = v3[compl].copy()

# T11 Clasificación de clientes con ventas válidas + cliente anónimo
compras_por_cliente = ventas_validas["id_cliente"].dropna().astype(int).value_counts()


def clasificar(n):
    if n >= 20:
        return "Frecuente"
    if n >= 3:
        return "Ocasional"
    if n >= 1:
        return "Nuevo"
    return "Sin compras"


clientes_t["_n"] = clientes_t["id_cliente"].map(compras_por_cliente).fillna(0).astype(int)
clientes_t["ClasificacionCliente"] = clientes_t["_n"].apply(clasificar)
dim_cliente = clientes_t.rename(columns={"id_cliente": "KeyCliente", "distrito": "Distrito",
    "consentimiento_datos": "Consentimiento"})[["KeyCliente", "Distrito", "ClasificacionCliente", "Consentimiento"]]
dim_cliente["ClienteAnonimo"] = False
anon = pd.DataFrame([{"KeyCliente": 0, "Distrito": "Sin dato", "ClasificacionCliente": "Anonimo",
                        "ClienteAnonimo": True, "Consentimiento": None}])
dim_cliente = pd.concat([anon, dim_cliente], ignore_index=True)[
    ["KeyCliente", "Distrito", "ClasificacionCliente", "ClienteAnonimo", "Consentimiento"]]
log("T11 Clasificacion de clientes + KeyCliente=0", len(clientes), len(clientes),
    "se agrega 1 fila tecnica (KeyCliente=0) para venta anonima")

# ============================== 4. HECHO =================================
print("\n=== 4. TABLA DE HECHOS (grano: un producto dentro de una venta) ===")
ids_validos = set(ventas_validas["id_venta"].astype(int))
det_ok = detalle_ventas[pd.to_numeric(detalle_ventas["id_venta"], errors="coerce").isin(ids_validos)]
hechos = det_ok.merge(ventas_validas, on="id_venta", how="inner", suffixes=("_detalle", "_venta"))
anonimas = int(hechos["id_cliente"].isna().sum())
hechos["id_cliente"] = hechos["id_cliente"].fillna(0).astype(int)
hechos["KeyFecha"] = hechos["fecha_venta"].dt.strftime("%Y%m%d").astype(int)
hechos["VentaNeta"] = (hechos["cantidad"] * hechos["precio_unitario"]).round(2)
fact_ventas = hechos.rename(columns={"id_sucursal": "KeySucursal", "id_producto": "KeyProducto",
    "id_cliente": "KeyCliente", "id_metodo_pago": "KeyMetodoPago", "id_empleado": "KeyEmpleado",
    "id_venta": "IdVentaOrigen", "id_detalle": "IdDetalleOrigen", "cantidad": "Cantidad",
    "precio_unitario": "PrecioUnitario"})[
    ["KeyFecha", "KeySucursal", "KeyProducto", "KeyCliente", "KeyMetodoPago", "KeyEmpleado",
        "IdVentaOrigen", "IdDetalleOrigen", "Cantidad", "PrecioUnitario", "VentaNeta"]]
log("T12 Construccion FactVentas (detalle -> hecho)", len(detalle_ventas), len(fact_ventas),
    "detalles de ventas excluidas por T07-T10")
log("T12b Filas de hecho con venta anonima", len(fact_ventas), len(fact_ventas),
    f"{anonimas} filas con KeyCliente=0 conservadas (no se descartan)")

# ========================= 5. VALIDACIONES ===============================
print("\n=== 5. VALIDACIONES ===")
tablas = {"DimFecha": dim_fecha, "DimSucursal": dim_sucursal, "DimProducto": dim_producto,
            "DimMetodoPago": dim_metodo_pago, "DimEmpleado": dim_empleado,
            "DimCliente": dim_cliente, "FactVentas": fact_ventas}
if fact_ventas["IdVentaOrigen"].nunique() != len(ventas_validas):
    abortar("Conciliacion fallida: ventas distintas en el hecho != ventas validas.")
for col, dim in [("KeyFecha", dim_fecha), ("KeySucursal", dim_sucursal), ("KeyProducto", dim_producto),
                    ("KeyCliente", dim_cliente), ("KeyMetodoPago", dim_metodo_pago), ("KeyEmpleado", dim_empleado)]:
    huerf = int((~fact_ventas[col].isin(dim[col])).sum())
    if huerf:
        abortar(f"Claves huerfanas en FactVentas.{col}: {huerf}")
if (fact_ventas["VentaNeta"] <= 0).any() or (fact_ventas["Cantidad"] <= 0).any():
    abortar("Hecho con Cantidad/VentaNeta no positivas (violaria CHECK del DDL).")
log("V01 Conciliacion: ventas validas = ventas en hecho", len(ventas_validas), fact_ventas["IdVentaOrigen"].nunique())
log("V02 Integridad de claves (0 huerfanas)", len(fact_ventas), len(fact_ventas))
print("Validaciones superadas.")

# ============================== 6. SALIDA ================================
for n, df in tablas.items():
    df.to_csv(CARPETA_SALIDA / f"{n}.csv", index=False, encoding="utf-8-sig")
print("\n=== RESUMEN ETL ===")
for n, df in tablas.items():
    print(f"{n}: {len(df):,} filas")

# ============================== 7. CARGA =================================
if CARGAR:
    from sqlalchemy import create_engine, text
    engine = create_engine(CONNECTION_STRING, fast_executemany=True)
    with engine.begin() as conn:                      # una sola transacción: todo o nada
        conn.execute(text("DELETE FROM dw.FactVentas"))
        for t in ["DimCliente", "DimEmpleado", "DimMetodoPago", "DimProducto", "DimSucursal", "DimFecha"]:
            conn.execute(text(f"DELETE FROM dw.{t}"))
        conn.execute(text("DELETE FROM dw.LogETL"))
        for n in ["DimFecha", "DimSucursal", "DimProducto", "DimMetodoPago", "DimEmpleado", "DimCliente", "FactVentas"]:
            tablas[n].to_sql(n, conn, schema="dw", if_exists="append", index=False, chunksize=5000)
    # Validación post-carga: conteos leídos realmente desde KUSI_DW
    with engine.connect() as conn:
        for n, df in tablas.items():
            en_dw = conn.execute(text(f"SELECT COUNT(*) FROM dw.{n}")).scalar()
            estado = "OK" if en_dw == len(df) else "DIFERENCIA"
            print(f"[POST-CARGA] dw.{n}: transformadas={len(df):,} en_DW={en_dw:,} -> {estado}")
            log(f"V03 Post-carga dw.{n}", len(df), min(en_dw, len(df)),
                "" if estado == "OK" else "diferencia entre transformado y DW")
    pd.DataFrame(log_ejecucion).to_sql("LogETL", engine, schema="dw", if_exists="append", index=False)
    print("Carga directa a KUSI_DW completada.")
else:
    print("Modo --solo-csv: no se cargó a SQL Server.")

pd.DataFrame(log_ejecucion).to_csv(CARPETA_SALIDA / "etl_log_local.csv", index=False, encoding="utf-8-sig")
print(f"Log: {CARPETA_SALIDA / 'etl_log_local.csv'}  | Duración: {(datetime.now()-T0).total_seconds():.1f} s")
