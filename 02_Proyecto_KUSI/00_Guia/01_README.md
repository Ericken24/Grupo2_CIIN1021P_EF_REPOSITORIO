# KUSI MINIMARKET — Proyecto integrador CIIN1021P

Este repositorio contiene la versión construida del proyecto, organizada para que el desarrollo sea repetible y para que cada resultado importante pueda convertirse en evidencia del informe y de la sustentación.

## Estructura

- `01_Datos_Fuente/`: CSV originales del escenario KUSI.
- `02_Proyecto_KUSI/01_SQLServer/`: base operacional, automatización, seguridad, rendimiento y pruebas.
- `02_Proyecto_KUSI/02_MongoDB/`: promociones semiestructuradas y CRUD.
- `02_Proyecto_KUSI/03_DataWarehouse/`: modelo dimensional y ETL.
- `02_Proyecto_KUSI/04_Documentacion/`: relevamiento, cronograma, riesgos y matriz de evidencias.
- `02_Proyecto_KUSI/05_Evidencias/`: espacio para capturas y resultados reales.

## Principios de trabajo

1. Los CSV fuente no se modifican para ocultar problemas de calidad.
2. Los registros problemáticos se identifican y, cuando corresponde, se envían a cuarentena.
3. El período analítico es 2023-01-01 a 2025-08-31.
4. Las 6 ventas problemáticas únicas se conservan en la fuente: 2 están fuera del período y 4 presentan simultáneamente total cero y ausencia de detalle.
5. Las mediciones de rendimiento y las pruebas de restauración se documentan con resultados reales, no con números de ejemplo.
6. Las credenciales de acceso no se almacenan en el repositorio.

## Requisitos principales

- SQL Server 2022.
- MongoDB / MongoDB Compass.
- Python 3.x con pandas, numpy, SQLAlchemy y pyodbc para el ETL.
- ODBC Driver 18 for SQL Server.

## Evidencia

La guía `04_Documentacion/04_Matriz_Evidencias_EP.md` indica qué captura tomar, en qué momento y para qué criterio de la EP sirve.
