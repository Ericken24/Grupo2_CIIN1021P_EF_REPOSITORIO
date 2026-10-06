# [1.1] Relevamiento, problemas de calidad, supuestos y requisitos

## 1. Contexto

KUSI MINIMARKET representa una cadena de 7 tiendas comerciales y 1 sede administrativa en Cajamarca. El conjunto de datos es sintético y fue construido específicamente para el proyecto. El cambio de dominio respecto del enunciado original fue autorizado por el docente, manteniendo los mismos desafíos técnicos.

El periodo analítico definido es **01/01/2023–31/08/2025 (32 meses)**.

## 2. Volumen

| Entidad | Registros |
|---|---:|
| Categorías | 10 |
| Proveedores | 15 |
| Sucursales/puntos físicos | 8 |
| Métodos de pago | 6 |
| Productos | 515 |
| Empleados | 36 |
| Clientes | 2,500 |
| Ventas | 180,000 |
| Detalles de venta | 447,532 |
| Compras | 1,000 |
| Detalles de compra | 8,751 |
| Promociones MongoDB | 17 |

## 3. Problemas de calidad

| ID | Problema | Registros/incidencias | Tratamiento |
|---|---|---:|---|
| Q01 | Ventas fuera del periodo analítico | 2 | Se conservan en OLTP y se observan en `calidad.VentasObservadas`; se excluyen del DW. |
| Q02 | Ventas sin cliente identificado | 54,000 | Se mantienen como ventas anónimas; no se intenta inferir identidad. |
| Q03 | DNI con longitud distinta de 8 | 12 | Se observa y conserva; no se inventa información personal. |
| Q04 | Email inválido o vacío | 213 | Se observa; no se usa para comunicaciones automatizadas. |
| Q05 | Distritos con variantes de escritura | 9 | Se normalizan mediante diccionario explícito en ETL. |
| Q06 | Ventas con total cero | 4 | Se rechazan para el modelo operacional y el DW. |
| Q07 | Ventas de cabecera sin detalle | 4 | Se rechazan para el modelo operacional y el DW. |
| Q08 | Productos con stock ≤ stock mínimo | 6 | Se genera alerta de reabastecimiento; no se altera el stock físico. |

### Precisión importante sobre Q06/Q07

Q06 y Q07 son conteos de incidencias, no conteos de ventas únicas. En este dataset las cuatro ventas con total cero son también las cuatro ventas sin detalle. Por ello:

- Q06 = 4 incidencias.
- Q07 = 4 incidencias.
- Ventas únicas afectadas por Q06/Q07 = 4.
- Sumando además las 2 ventas fuera de periodo (Q01), existen **6 ventas únicas problemáticas**.

Las dos ventas Q01 tienen total positivo y detalle, por lo que no se rechazan del OLTP: se conservan para trazabilidad y se excluyen del periodo analítico del DW.

## 4. Supuestos

| ID | Supuesto | Efecto técnico |
|---|---|---|
| R01 | El periodo analítico termina el 31/08/2025 | El ETL filtra el DW con fechas parametrizadas. |
| R02 | Existen 7 tiendas y 1 sede administrativa | `vende=1/0` evita incluir la sede administrativa en KPIs de ventas. |
| R03 | Las tiendas operan 24/7 | Permite analizar franjas nocturnas. |
| R04 | Vía de Evitamiento concentra mayor flujo | Se utiliza como contexto de análisis, no como regla que fuerce resultados. |
| R05 | Baños del Inca, Jesús y La Encañada se consideran mercados potenciales | Permite separar presencia actual de oportunidad geográfica. |
| R06 | El 30% de ventas se mantiene anónimo | `DimCliente` usa `KeyCliente=0` para no imputar identidad. |
| R07 | Clientes identificados tienen fecha de registro ≤ fecha de venta | Protege coherencia temporal del modelo. |
| R08 | IGV = 18% | Se valida subtotal, IGV y total en procedimientos. |
| R09 | Una venta completada requiere total > 0 y al menos un detalle | Sustenta Q06/Q07 y el filtro del DW. |
| R10 | Los problemas de calidad no se corrigen silenciosamente | Se usan staging, observaciones y cuarentenas. |
| R11 | Promociones son documentos variables | Se gestionan en MongoDB. |
| R12 | SQL Server 2022 es el motor relacional | Orienta DDL, transacciones, seguridad y rendimiento. |

## 5. Requisitos funcionales

| ID | Requisito | Criterio verificable |
|---|---|---|
| RF01 | Validar ventas | Una venta no se marca completada si no cuadra cabecera/detalle. |
| RF02 | Trazabilidad | `audit.LogAuditoria` registra usuario, fecha, operación y clave. |
| RF03 | Segregación de acceso | El analista no puede modificar `dbo`; el auditor no consulta el OLTP. |
| RF04 | Recuperación | El restore de prueba recupera la base y conserva el conteo de ventas. |
| RF05 | Reabastecimiento | La función devuelve productos con stock ≤ mínimo. |
| RF06 | Expansión | El procedimiento identifica distritos candidatos sin tienda operativa. |
| RF07 | Promociones | Se comparan ventas de una categoría en día promocionado vs. normal. |

## 6. Fuente y trazabilidad

Los CSV de trabajo se encuentran en `01_Datos_Fuente/`. El archivo `auditoria_dataset_v4.md` del paquete anterior se conserva como referencia de la construcción del escenario. La autorización docente del cambio de dominio debe conservarse como evidencia administrativa externa al código.
