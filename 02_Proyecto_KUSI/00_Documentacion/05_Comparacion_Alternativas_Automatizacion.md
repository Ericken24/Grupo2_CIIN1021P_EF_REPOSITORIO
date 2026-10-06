# Fundamentación de la automatización

Se compara la solución elegida con dos alternativas antes de fijar la arquitectura.

| Criterio | Procedimientos/BD | Lógica en aplicación | ETL externo/orquestador |
|---|---|---|---|
| Integridad | Alta: reglas cerca de los datos | Depende de que toda aplicación las respete | Alta para cargas, menor para operación interactiva |
| Trazabilidad | Centralizada con triggers/log | Debe implementarse en cada aplicación | Buena para procesos batch |
| Mantenibilidad | Reglas centralizadas | Puede duplicarse entre aplicaciones | Buena en pipelines, mayor complejidad de infraestructura |
| Latencia operativa | Adecuada para transacciones | Adecuada si la app está bien diseñada | Pensado principalmente para lotes |

## Decisión

Se mantiene la lógica crítica de integridad y trazabilidad en SQL Server, mientras Python se utiliza para transformación y carga analítica. Esta combinación evita colocar toda la responsabilidad en una sola capa.

## Cuándo sería preferible una alternativa

La lógica de aplicación sería preferible si las reglas dependieran de interacción de usuario o de servicios externos. Un orquestador ETL tendría ventaja si el número de fuentes, dependencias y ejecuciones programadas creciera lo suficiente como para requerir una plataforma dedicada.
