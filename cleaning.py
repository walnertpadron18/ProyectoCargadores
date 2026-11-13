"""Funciones de limpieza del proyecto: ¿Dónde invertir en carga pública en Europa?"""

import requests
import pandas as pd
import pycountry

# Nombres de los tipos de motor en Ember
EV = "Electric vehicle (BEV+PHEV)"
BEV = "Battery electric"
PHEV = "Plug-in hybrid"


# ---------- 1. Matriculaciones (Ember) ----------

def limpiar_ember(df):
    """Deja solo los países de la UE, las columnas útiles y nombres en español."""
    ue = df[(df["Area type"] == "Country or economy") & (df["EU member"] == True)].copy()

    ue = ue[["Area", "ISO 3 code", "Continent", "Date", "Drivetrain",
             "Is aggregate drivetrain", "Registrations"]]

    ue = ue.rename(columns={
        "Area": "pais",
        "ISO 3 code": "iso3",
        "Continent": "continente",
        "Date": "fecha",
        "Drivetrain": "tipo_motor",
        "Is aggregate drivetrain": "es_agregado",
        "Registrations": "matriculaciones",
    })

    ue["fecha"] = pd.to_datetime(ue["fecha"]).dt.strftime("%Y-%m-%d")
    ue["es_agregado"] = ue["es_agregado"].astype(int)
    return ue


def crear_paises(ue):
    return ue[["iso3", "pais", "continente"]].drop_duplicates().reset_index(drop=True)


def crear_tipos_motor(ue):
    return ue[["tipo_motor", "es_agregado"]].drop_duplicates().reset_index(drop=True)


def crear_matriculaciones(ue):
    return ue[["iso3", "fecha", "tipo_motor", "matriculaciones"]].reset_index(drop=True)


def comprobar_coherencia(matriculaciones, paises):
    """Comprueba que BEV + PHEV = EV y que todos los países tengan gasolina."""
    tabla = matriculaciones.pivot_table(index=["iso3", "fecha"], columns="tipo_motor",
                                        values="matriculaciones", aggfunc="sum")
    diferencia = (tabla[BEV] + tabla[PHEV] - tabla[EV]).abs()
    print("Filas donde BEV + PHEV no coincide con EV:", (diferencia > 0).sum())

    con_gasolina = matriculaciones[matriculaciones["tipo_motor"] == "Petrol"]["iso3"].unique()
    print("Países sin gasolina:", sorted(set(paises["iso3"]) - set(con_gasolina)))


# ---------- 2. Puntos de carga (EAFO) ----------

def limpiar_puntos_carga(puntos_raw, fecha="2026-07-01"):
    puntos = puntos_raw[["iso3", "carga_lenta", "carga_media", "carga_rapida", "total_puntos"]].copy()
    puntos.insert(1, "fecha_referencia", fecha)
    return puntos


# ---------- 3. Población (Eurostat, API) ----------

def descargar_poblacion():
    """Descarga la población de Eurostat y la devuelve como tabla: país, año, población."""
    url = ("https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
           "TPS00001?lang=EN&sinceTimePeriod=2020")
    data = requests.get(url, timeout=60).json()

    paises_api = data["dimension"]["geo"]["category"]["index"]   # {"ES": 0, "FR": 1, ...}
    años_api = data["dimension"]["time"]["category"]["index"]    # {"2020": 0, "2021": 1, ...}
    n_años = len(años_api)

    filas = []
    for pais, i_pais in paises_api.items():
        for año, i_año in años_api.items():
            # Eurostat guarda los valores en una lista: posición = país * nº de años + año
            valor = data["value"].get(str(i_pais * n_años + i_año))
            if valor is not None:
                filas.append({"iso2": pais, "año": int(año), "poblacion": int(valor)})

    return pd.DataFrame(filas)


def iso2_a_iso3(codigo):
    pais = pycountry.countries.get(alpha_2=codigo)
    return pais.alpha_3 if pais else None


def limpiar_poblacion(poblacion_raw, paises, año_max=2026):
    """Pasa los códigos a ISO3 y se queda con el último año disponible de cada país."""
    pob = poblacion_raw[poblacion_raw["iso2"].str.len() == 2].copy() 
    pob["iso2"] = pob["iso2"].replace({"EL": "GR", "UK": "GB"})       
    pob["iso3"] = pob["iso2"].apply(iso2_a_iso3)

    pob = pob[pob["iso3"].isin(paises["iso3"]) & (pob["año"] <= año_max)]
    pob = pob.sort_values("año").groupby("iso3").tail(1)
    return pob[["iso3", "año", "poblacion"]].reset_index(drop=True)


# ---------- 4. Ayudas públicas (ACEA) ----------

def limpiar_ayudas(ayudas_raw, paises):
    columnas = ["iso3", "ventaja_fiscal_compra", "ventaja_fiscal_propiedad", "ventaja_coche_empresa",
                "ayuda_compra", "ayuda_infraestructura", "indice_apoyo"]
    ayudas = ayudas_raw[columnas]
    return ayudas[ayudas["iso3"].isin(paises["iso3"])].reset_index(drop=True)


# ---------- 5. Flota de eléctricos ----------

def calcular_flota(matriculaciones):
    """Suma las matriculaciones BEV y PHEV de cada país hasta la última fecha común."""
    m = matriculaciones.copy()
    m["fecha"] = pd.to_datetime(m["fecha"])
    fin = m.groupby("iso3")["fecha"].max().min()   # última fecha que tienen todos los países

    m = m[(m["fecha"] <= fin) & (m["tipo_motor"].isin([BEV, PHEV]))]
    acumulado = m.pivot_table(index="iso3", columns="tipo_motor",
                              values="matriculaciones", aggfunc="sum")

    flota = pd.DataFrame({
        "iso3": acumulado.index,
        "fecha_referencia": fin.strftime("%Y-%m-%d"),
        "bev_circulacion": acumulado[BEV].astype(int).values,
        "phev_circulacion": acumulado[PHEV].astype(int).values,
    })
    return flota


# ---------- 6. Guardar en SQL ----------

def guardar_en_sql(tablas, engine):
    """tablas = {"nombre_tabla": dataframe}. Se guardan en el orden del diccionario."""
    for nombre, df in tablas.items():
        df.to_sql(nombre, con=engine, if_exists="append", index=False)
        print(f"{nombre}: {len(df)} filas guardadas")