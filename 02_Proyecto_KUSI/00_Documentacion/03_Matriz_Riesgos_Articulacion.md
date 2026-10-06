# Riesgos y articulación curricular

## Matriz de riesgos

| Riesgo | Prob. | Impacto | Mitigación | Evidencia |
|---|---|---|---|---|
| Fechas fuera del periodo | Media | Alta | Observación Q01 + filtro parametrizado del DW | Consulta Q01 |
| Registros con total cero/sin detalle | Alta | Alta | Cuarentena Q06/Q07 y validación transaccional | `VentasRechazadas` |
| Error en transformación ETL | Media | Alta | Log por entidad + validaciones de conteo | `etl_log_local.csv` |
| Fallo de permisos | Media | Alta | Roles diferenciados y pruebas de acceso | script 10 |
| Backup no restaurable | Baja | Muy alta | `VERIFYONLY` + restore de prueba | script 11 |
| Degradación de consulta | Media | Media | Plan de ejecución + índice + comparación | script 12 |

## Saberes retomados de Base de Datos (ciclo 3)

1. **Modelo entidad-relación y normalización:** se extiende al modelo operacional y luego se transforma a un modelo dimensional.
2. **Integridad referencial:** PK/FK/CHECK se usan como barreras estructurales de calidad.
3. **Consultas SQL con JOIN/GROUP BY:** se amplían para auditoría, KPIs y análisis de negocio.
4. **Transacciones:** se llevan a procedimientos con TRY/CATCH, COMMIT/ROLLBACK y SAVE TRANSACTION.

## Cursos posteriores

### Ciencia de Datos
Competencia desarrollada: preparar datos reproducibles y estructurados para análisis descriptivo y modelos posteriores. El DW y el ETL dejan una base limpia y trazable para demanda, segmentación y pronósticos.

### Ingeniería de Software
Competencia desarrollada: diseñar componentes con separación de responsabilidades, seguridad, trazabilidad, manejo de errores y recuperación ante fallos.
