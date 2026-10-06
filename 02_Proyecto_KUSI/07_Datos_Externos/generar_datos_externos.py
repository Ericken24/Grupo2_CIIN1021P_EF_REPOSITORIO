"""Genera los 3 archivos de datos externos de KUSI MINIMARKET (Capítulo 10).
Uso: python generar_datos_externos.py --feriados-md ruta\\datos_por_empresa.md (opcional) --salida .
Cada fila lleva la columna `origen` para no confundir dato verificable con dato calculado o sintético.
  1) feriados_peru.csv       -> origen: referencial (lista del proyecto, 36 fechas 2023-2025)
  2) festividades_cajamarca.csv -> origen: calculado (Pascua) | calendario_fijo | supuesto (campañas comerciales)
  3) clima_cajamarca_diario.csv -> origen: sintetico (climatología aproximada + ruido, semilla 2026)
     Para clima REAL use fetch_clima_open_meteo.py (misma estructura)."""
import argparse, re, csv
from datetime import date, timedelta
import numpy as np
import pandas as pd
from dateutil.easter import easter

ap = argparse.ArgumentParser(); ap.add_argument("--feriados-md", default=""); ap.add_argument("--salida", default=".")
a = ap.parse_args()
INI, FIN = date(2023, 1, 1), date(2025, 8, 31)

# ---------- 1. Feriados ----------
FER = [("2023-01-01","Año Nuevo"),("2023-04-06","Jueves Santo"),("2023-04-07","Viernes Santo"),("2023-05-01","Día del Trabajo"),
("2023-06-29","San Pedro y San Pablo"),("2023-07-28","Fiestas Patrias"),("2023-07-29","Fiestas Patrias"),("2023-08-30","Santa Rosa de Lima"),
("2023-10-08","Combate de Angamos"),("2023-11-01","Todos los Santos"),("2023-12-08","Inmaculada Concepción"),("2023-12-25","Navidad"),
("2024-01-01","Año Nuevo"),("2024-03-28","Jueves Santo"),("2024-03-29","Viernes Santo"),("2024-05-01","Día del Trabajo"),
("2024-06-29","San Pedro y San Pablo"),("2024-07-28","Fiestas Patrias"),("2024-07-29","Fiestas Patrias"),("2024-08-30","Santa Rosa de Lima"),
("2024-10-08","Combate de Angamos"),("2024-11-01","Todos los Santos"),("2024-12-08","Inmaculada Concepción"),("2024-12-25","Navidad"),
("2025-01-01","Año Nuevo"),("2025-04-17","Jueves Santo"),("2025-04-18","Viernes Santo"),("2025-05-01","Día del Trabajo"),
("2025-06-29","San Pedro y San Pablo"),("2025-07-28","Fiestas Patrias"),("2025-07-29","Fiestas Patrias"),("2025-08-30","Santa Rosa de Lima"),
("2025-10-08","Combate de Angamos"),("2025-11-01","Todos los Santos"),("2025-12-08","Inmaculada Concepción"),("2025-12-25","Navidad")]
if a.feriados_md:   # si se entrega el archivo del proyecto, se usa tal cual
    txt = open(a.feriados_md, encoding="utf-8").read().split("## File: feriados_peru_referencial.csv")[1].split("## File:")[0]
    FER = [(m[0], m[1].strip()) for m in re.findall(r"\|\s*(\d{4}-\d{2}-\d{2})\s*\|\s*([^|]+?)\s*\|\s*referencial", txt)]
dias = ["lunes","martes","miércoles","jueves","viernes","sábado","domingo"]
fer = pd.DataFrame(FER, columns=["fecha","nombre"]); fd = pd.to_datetime(fer["fecha"])
fer["tipo"] = "nacional"; fer["dia_semana"] = [dias[d] for d in fd.dt.dayofweek]
fer["fin_semana_largo"] = fd.dt.dayofweek.isin([0, 4]).astype(int)   # lunes o viernes
fer["origen"] = "referencial"
fer.to_csv(f"{a.salida}/feriados_peru.csv", index=False, encoding="utf-8-sig")

# ---------- 2. Festividades de Cajamarca ----------
def nth_weekday(y, m, wd, n):                       # n-ésimo día de la semana (0=lunes) del mes
    d = date(y, m, 1); d += timedelta(days=(wd - d.weekday()) % 7); return d + timedelta(weeks=n - 1)
rows = []
for y in (2023, 2024, 2025):
    p = easter(y)
    rows += [("Carnaval de Cajamarca", p - timedelta(days=50), p - timedelta(days=47), "cultural", "calculado"),   # sábado a martes de carnaval
             ("Semana Santa", p - timedelta(days=7), p, "religiosa", "calculado"),
             ("Corpus Christi", p + timedelta(days=60), p + timedelta(days=60), "religiosa", "calculado"),
             ("Día del Amor y la Amistad", date(y, 2, 14), date(y, 2, 14), "comercial", "calendario_fijo"),
             ("Día de la Madre", nth_weekday(y, 5, 6, 2), nth_weekday(y, 5, 6, 2), "comercial", "calendario_fijo"),
             ("Día del Padre", nth_weekday(y, 6, 6, 3), nth_weekday(y, 6, 6, 3), "comercial", "calendario_fijo"),
             ("Campaña escolar", date(y, 2, 15), date(y, 3, 15), "comercial", "supuesto"),
             ("Campaña navideña", date(y, 12, 15), date(y, 12, 24), "comercial", "supuesto"),
             ("Fin de año", date(y, 12, 26), date(y + 1, 1, 1), "comercial", "supuesto")]
fest = pd.DataFrame(rows, columns=["nombre","fecha_inicio","fecha_fin","tipo","origen"]).sort_values("fecha_inicio")
fest = fest[(fest.fecha_inicio <= FIN)]
fest.to_csv(f"{a.salida}/festividades_cajamarca.csv", index=False, encoding="utf-8-sig")

# ---------- 3. Clima sintético (climatología aproximada de Cajamarca, ~2 750 m s. n. m.) ----------
tmax = [20,19.5,19.5,20,20.5,20.5,20.5,21,21.5,21,21,20.5]; tmin = [9,9.5,9.5,9,7.5,6,5.5,5.5,7,8.5,8.5,9]
pllu = [.55,.65,.70,.55,.25,.08,.05,.08,.20,.45,.45,.45]
rng = np.random.default_rng(2026); out = []; ar = 0.0
for d in pd.date_range(INI, FIN):
    m = d.month - 1; ar = 0.7 * ar + rng.normal(0, 0.8)
    llueve = rng.random() < pllu[m]
    pr = round(float(rng.gamma(1.2, 4.5)), 1) if llueve else 0.0
    mx = round(tmax[m] + ar - (1.5 if pr > 5 else 0) + rng.normal(0, 0.8), 1); mn = round(tmin[m] + 0.5 * ar + rng.normal(0, 0.7), 1)
    temporada = "Lluviosa" if d.month in (12,1,2,3,4) else ("Transición" if d.month in (10,11) else "Seca")
    out.append((d.date(), mx, mn, round((mx + mn) / 2, 1), pr, temporada, "sintetico"))
pd.DataFrame(out, columns=["fecha","temp_max_c","temp_min_c","temp_media_c","precipitacion_mm","temporada","origen"]).to_csv(
    f"{a.salida}/clima_cajamarca_diario.csv", index=False, encoding="utf-8-sig")
print("OK: feriados", len(fer), "| festividades", len(fest), "| clima", len(out))
