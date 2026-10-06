# SQL Server vs MongoDB — decisión arquitectónica

| Criterio | SQL Server | MongoDB | Aplicación al proyecto |
|---|---|---|---|
| Modelo de datos | Relacional, estructurado, FK/CHECK | Documental, campos variables | Ventas y maestros → SQL; promociones variables → MongoDB |
| Consistencia | Transacciones y restricciones fuertes | Consistencia configurable y modelo documental | La venta requiere integridad relacional |
| Escalabilidad | Escala vertical y horizontal según arquitectura | Facilita distribución documental | MongoDB es útil para documentos de promoción y crecimiento de catálogos variables |
| Latencia de consulta | Muy buena en consultas estructuradas e índices relacionales | Muy buena para documentos y filtros sobre campos indexados | Cada motor se usa donde su modelo encaja mejor |

## Decisión

Se adopta una **arquitectura híbrida**. SQL Server es el sistema operacional y analítico estructurado; MongoDB gestiona promociones semiestructuradas. No se pretende reemplazar la integridad transaccional de SQL con MongoDB.
