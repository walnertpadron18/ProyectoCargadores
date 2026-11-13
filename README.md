# ¿Dónde invertir en carga pública en Europa?
### Ranking de oportunidad para una empresa de puntos de carga para vehículos eléctricos

**Autor:** Walnert Padrón · Proyecto final Data Analytics · Ironhack 2026
**Herramientas:** Python (pandas, requests, SQLAlchemy, pycountry) · MySQL · Tableau

---

## 🎯 Objetivo del proyecto

Identificar los **5 países de la Unión Europea** donde una empresa de puntos de carga pública debería invertir en los próximos **12 a 24 meses**. La decisión importa porque instalar cargadores exige una inversión alta y un retorno lento: elegir mal el país significa cargadores infrautilizados durante años.

## 🏢 Contexto del negocio

- **Empresa (simulada):** operador europeo de puntos de carga pública que quiere expandirse.
- **Desafío:** hay más de 1,18 millones de puntos de carga públicos en la UE, pero están repartidos de forma muy desigual. En algunos países sobran cargadores y en otros la demanda va por delante de la red.
- **Decisiones que tomar:**
  - ¿En qué países invertir primero?
  - ¿Qué tipo de cargador instalar (lento o rápido)?
  - ¿Qué mercados vigilar para una segunda fase?

## 📊 Dataset

Datos reales de cuatro fuentes públicas:

| Fuente | Formato | Contenido |
| --- | --- | --- |
| **Ember** | CSV | Matriculaciones mensuales de coches por país y tipo de motor |
| **EAFO** (Observatorio Europeo de Combustibles Alternativos) | CSV | Puntos de carga públicos por país y potencia |
| **Eurostat** | API | Población a 1 de enero por país |
| **ACEA** | CSV | Ayudas e incentivos al coche eléctrico por país (2026) |

Los datos se limpian en Python y se guardan en una base de datos MySQL (`coches_electricos`) con 7 tablas:

| Tabla | Variables principales | Descripción |
| --- | --- | --- |
| `paises` | `iso3`, `pais`, `continente` | Los 27 países de la UE |
| `tipos_motor` | `tipo_motor`, `es_agregado` | Tipos de motor (BEV, PHEV, gasolina…) y si son una suma de otros |
| `matriculaciones` | `iso3`, `fecha`, `tipo_motor`, `matriculaciones` | Matriculaciones mensuales por país y tipo de motor |
| `puntos_carga` | `iso3`, `carga_lenta`, `carga_media`, `carga_rapida`, `total_puntos` | Puntos de carga públicos por potencia |
| `poblacion` | `iso3`, `año`, `poblacion` | Población del último año disponible |
| `ayudas` | `iso3`, `ayuda_compra`, `ayuda_infraestructura`, `ventaja_fiscal_compra`, `ventaja_fiscal_propiedad`, `ventaja_coche_empresa`, `indice_apoyo` | Ayudas públicas (1 = sí, 0 = no) |
| `flota` | `iso3`, `bev_circulacion`, `phev_circulacion` | Eléctricos en circulación estimados |

**Diccionario breve**

- **BEV:** coche 100 % eléctrico (*Battery Electric Vehicle*).
- **PHEV:** híbrido enchufable (*Plug-in Hybrid Electric Vehicle*).
- **Carga lenta:** corriente alterna hasta 22 kW.
- **Carga media:** alterna de más de 22 kW y continua de menos de 50 kW.
- **Carga rápida:** corriente continua de 50 kW o más.

### Notas sobre calidad del dato

- Se comprobó que, en cada país y mes, **BEV + PHEV = total de eléctricos**, y que todos los países tienen datos de gasolina.
- La **flota en circulación** es una estimación: suma las matriculaciones acumuladas hasta la última fecha común a todos los países, sin descontar los coches dados de baja.
- Los **puntos de carga** son una foto fija (julio de 2026) y cubren 26 países.
- Eurostat usa el código `EL` para Grecia; se convirtió a `GR` antes de pasar a ISO3.
- Si a un país le falta la población de 2026, se usa su último año disponible.

## ❓ Preguntas clave

1. ¿Dónde hay más coches eléctricos por habitante?
2. ¿Qué países tienen la red de carga más saturada (más eléctricos por punto de carga)?
3. ¿Dónde es más escasa la carga rápida?
4. ¿En qué países se matriculan ya más eléctricos que coches de gasolina?
5. ¿Qué mercados crecen más rápido?
6. ¿Qué países ofrecen ayudas públicas que reduzcan el riesgo de la inversión?

## 🔍 Proceso de análisis

1. **Limpieza (Python):** filtrado de países de la UE, renombrado de columnas, formato de fechas, control de nulos y duplicados, conversión de códigos de país y comprobaciones de coherencia. Las funciones están en `cleaning.py`.
2. **Modelo de datos (MySQL):** 7 tablas relacionadas por `iso3`, con claves primarias y foráneas.
3. **KPIs calculados (SQL):**
   - Eléctricos por cada 1.000 habitantes
   - Eléctricos por punto de carga (saturación de la red)
   - Porcentaje de carga rápida y BEV por punto rápido
   - Ratio de matriculaciones eléctricos / gasolina (últimos 12 meses)
   - Cuota BEV frente a PHEV (últimos 12 meses)
   - Índice de crecimiento de las matriculaciones
   - Índice de apoyo público
4. **Metodología:** **índice de oportunidad compuesto** (*scoring* ponderado). Cada criterio se normaliza y se pondera:

   | Criterio | Peso |
   | --- | --- |
   | Carga rápida | 30 % |
   | Crecimiento | 25 % |
   | Saturación | 20 % |
   | Apoyo público | 15 % |
   | Madurez del mercado | 10 % |

5. **Visualización (Tableau):** dashboard ejecutivo con el ranking, mapas y gráficos de apoyo.

## 💡 Resultados / Insights

- **Top 5 del índice de oportunidad:** Irlanda (0,66), Países Bajos (0,54), Luxemburgo (0,51), Alemania (0,44) y Eslovenia (0,43).
- **Irlanda tiene la red más saturada:** casi 50 eléctricos por punto de carga, más del doble que Alemania, Portugal o Luxemburgo.
- **La carga rápida se queda corta donde más eléctricos hay:** Países Bajos, Chipre y Luxemburgo superan los 100 eléctricos por cada punto rápido.
- **El eléctrico ya supera a la gasolina en 14 de los 27 países.** Países Bajos matricula unos 8 eléctricos por cada coche de gasolina.
- **El eléctrico puro gana terreno:** en 19 de los 27 países los BEV superan a los híbridos enchufables.
- **Mercados emergentes:** Croacia (154) y Eslovenia (110) crecen por encima de la media (≈ 100).
- **15 de los 27 países** ofrecen ayudas para instalar puntos de carga.

## ✅ Recomendaciones de negocio

1. **Entrar primero en Irlanda:** red saturada y primer puesto del índice. Hay demanda sin cubrir.
2. **Apostar por la carga rápida en los mercados maduros:** es el servicio más escaso y el de mayor valor para el conductor.
3. **Priorizar países con ayudas a la infraestructura** (Irlanda, Países Bajos, Luxemburgo, Alemania) para reducir el coste inicial y el riesgo.
4. **Elegir mercados donde domina el BEV:** dependen al 100 % del cargador, lo que aumenta el uso de cada punto.
5. **Entrar por fases en los emergentes** (Croacia, Eslovenia): inversión pequeña al principio y ampliación si el crecimiento se mantiene.

## ⚠️ Limitaciones

- **Pesos del índice:** los porcentajes son una decisión propia; con otros pesos el ranking podría cambiar.
- **Datos que cambian rápido:** el mercado evoluciona cada mes y las cifras pueden quedarse desactualizadas.
- **Flota estimada:** no descuenta bajas ni coches importados de segunda mano.
- **Definición de carga rápida:** cada fuente usa umbrales distintos, así que las comparaciones con otros informes no siempre son directas.
- **Análisis a nivel país:** no tiene en cuenta diferencias entre regiones o ciudades, ni la competencia de operadores ya instalados, ni el coste de conexión a la red.
- **Retorno lento:** el análisis no incluye costes ni ingresos, que son claves para la decisión final.

## 🚀 Próximos pasos

- **Análisis de sensibilidad:** comprobar si el top 5 se mantiene al cambiar los pesos.
- **Detalle regional:** bajar a regiones y ciudades dentro de los 5 países.
- **Estudio de rentabilidad (ROI):** estimar costes, uso esperado y plazo de retorno por país.
- **Predicción con machine learning:** anticipar las ventas de eléctricos.
- **Actualización automática:** conectar el dashboard a la base de datos para que se actualice cada mes.

## 🔁 Cómo replicar el proyecto

**Archivos**
- 📓 Notebook: [`Proyecto_final_cargadores.ipynb`](Proyecto_final_cargadores.ipynb)
- 🧹 Funciones de limpieza: [`cleaning.py`](cleaning.py)
- 🗄️ Consultas SQL: [`sql/`](sql/)
- 📈 Dashboard en Tableau: [enlace al dashboard](#)

**Pasos**

1. Instala las librerías:
   ```
   pip install pandas requests sqlalchemy pymysql pycountry
   ```
2. Crea la base de datos en MySQL y ejecuta el script de creación de tablas:
   ```sql
   CREATE DATABASE coches_electricos;
   ```
3. Coloca los CSV en la carpeta `data/` y `cleaning.py` junto al notebook.
4. Ejecuta el notebook en orden. Te pedirá la contraseña de MySQL y guardará las 7 tablas.
5. Ejecuta las consultas SQL de métricas y exporta los resultados a CSV.
6. Abre el dashboard de Tableau y, si hace falta, actualiza la ruta de los CSV en **Fuente de datos → Editar conexión**.

**Estructura del repositorio**
```
├── README.md
├── Proyecto_final_cargadores.ipynb
├── cleaning.py
├── data/
│   ├── monthly_ev_sales.csv
│   ├── puntos_carga.csv
│   └── ayudas.csv
└── sql/
```
