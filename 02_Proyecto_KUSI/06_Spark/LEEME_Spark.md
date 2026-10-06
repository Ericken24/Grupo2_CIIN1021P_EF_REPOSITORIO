# Capítulo 10 — Spark en Visual Studio Code

1. **Requisitos:** Java 17 (con `JAVA_HOME`), Python 3.10+ y `pip install pyspark pandas ipykernel`. En VS Code instale la extensión *Jupyter* y elija el kernel de Python donde instaló PySpark. (PySpark 4.x necesita Java 17 o superior.)
2. **Carpetas:** copie a una carpeta (p. ej. `C:\KUSI_MINIMARKET\datos_externos`) los 3 CSV de `08_Datos_Externos`. Los CSV del DW ya los tiene en `dw_listos_para_cargar`.
3. Abra `Notebook_Spark_KUSI.ipynb`, ajuste las rutas de la **primera celda** y use *Run All*.
4. **Salidas** (carpeta `spark_salidas`): ventas diarias con eventos, efecto de eventos, efecto del clima, categoría y producto por temporada, pronóstico a 14 días, métricas del pronóstico y tiempos de Spark. Son la fuente del Dashboard 2.
5. **Captura (Figura 16):** una sola de VS Code con las salidas de estadística, eventos/clima, top por temporada y tiempos.
6. **SQL Server:** ejecute `07_Benchmark_SQLServer.sql` y anote la mediana de cada escala para la Tabla 33 (use el *elapsed time*).
7. Validé el código con datos sintéticos de prueba (solo comprueba que corre); los resultados reales saldrán de sus datos.
