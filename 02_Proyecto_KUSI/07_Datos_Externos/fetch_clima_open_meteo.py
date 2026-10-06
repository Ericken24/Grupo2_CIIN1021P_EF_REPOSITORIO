"""OPCIONAL (requiere internet): descarga el clima REAL diario de Cajamarca desde Open-Meteo (gratuito, sin clave)
y lo guarda con la misma estructura que el clima sintético, con origen='open-meteo'.
Uso: python fetch_clima_open_meteo.py --salida .   (sobrescribe clima_cajamarca_diario.csv: guarde antes el sintético si lo desea)
Citar: Open-Meteo.com (API de datos históricos). NO se probó desde el entorno de desarrollo; verifique el resultado."""
import argparse, json, urllib.request
import pandas as pd
ap = argparse.ArgumentParser(); ap.add_argument("--salida", default="."); a = ap.parse_args()
url = ("https://archive-api.open-meteo.com/v1/archive?latitude=-7.1638&longitude=-78.5003&start_date=2023-01-01&end_date=2025-08-31"
       "&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=America%2FLima")
d = json.load(urllib.request.urlopen(url, timeout=60))["daily"]
df = pd.DataFrame({"fecha": d["time"], "temp_max_c": d["temperature_2m_max"], "temp_min_c": d["temperature_2m_min"],
                   "precipitacion_mm": d["precipitation_sum"]})
df["temp_media_c"] = ((df.temp_max_c + df.temp_min_c) / 2).round(1)
m = pd.to_datetime(df.fecha).dt.month
df["temporada"] = m.map(lambda x: "Lluviosa" if x in (12,1,2,3,4) else ("Transición" if x in (10,11) else "Seca"))
df["origen"] = "open-meteo"
df[["fecha","temp_max_c","temp_min_c","temp_media_c","precipitacion_mm","temporada","origen"]].to_csv(
    f"{a.salida}/clima_cajamarca_diario.csv", index=False, encoding="utf-8-sig")
print("OK", len(df), "días")
