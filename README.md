¿Dónde invertir en carga pública en Europa?
Ranking de oportunidad para una empresa de puntos de carga · UE-27 ·

Objetivo

Priorizar los países de la UE en los que una empresa de puntos de carga pública debería invertir en los próximos 12 a 24 meses. La decisión importa porque cada punto de carga es una inversión cara: instalarlo donde la demanda crece y la red aún no la cubre es lo que lo hace rentable.

Contexto del negocio
Empresa (simulada): operador de puntos de carga pública que quiere expandirse en Europa.
Desafío: la venta de coches eléctricos crece de forma muy desigual entre países, igual que la infraestructura de carga y las ayudas públicas.
Decisión: en qué países entrar primero y qué tipo de carga priorizar (lenta o rápida).
Público del dashboard: comité de dirección.

Fuentes reales y públicas:

Tabla	Fuente	Variables principales
paises	Ember	iso3 (clave), pais, continente
tipos_motor	Ember	tipo_motor, es_agregado (1 = suma de otros tipos)
matriculaciones	Ember (CSV)	iso3, fecha (mensual), tipo_motor, matriculaciones
flota	Calculada	bev_circulacion, phev_circulacion (eléctricos en circulación)
puntos_carga	Observatorio Europeo (EAFO)	carga_lenta (≤22 kW AC), carga_media, carga_rapida (≥50 kW DC), total_puntos
poblacion	Eurostat (API)	anio, poblacion
ayudas	ACEA 2026	5 tipos de ayuda (1/0) e indice_apoyo (0 a 5)

BEV = eléctrico puro de batería · PHEV = híbrido enchufable.

Calidad del dato
Se probó Open Charge Map como fuente de cargadores y se descartó: en Bélgica recogía menos del 2 % de los puntos oficiales. Se sustituyó por el Observatorio Europeo.
Ember es coherente: en todos los países y meses, BEV + PHEV coincide con el agregado de eléctricos.
Preguntas clave
¿Dónde hay más eléctricos en circulación por habitante?
¿Qué redes de carga están más saturadas?
¿Dónde el eléctrico ya supera a la gasolina en matriculaciones?
¿Qué países apoyan más la transición con ayudas públicas?
¿Qué países cumplen el mínimo legal de carga de la UE (reglamento AFIR)?
Proceso de análisis
Limpieza (Python): filtrado a los 27 países de la UE, renombrado de columnas, control de nulos y duplicados, y conversión de códigos de país (Eurostat usa EL y UK).
Modelo de datos (MySQL): 7 tablas unidas por iso3, con claves primarias y foráneas.
KPIs (SQL):
Eléctricos por cada 1.000 habitantes
Eléctricos por punto de carga público
Ratio eléctricos / gasolina (últimos 12 meses, misma ventana para todos)
Índice de apoyo público (0 a 5)
Cumplimiento estimado del objetivo AFIR (1,3 kW por BEV y 0,8 kW por PHEV)
Dashboard (Tableau): mapa, ranking y evolución mensual.
Resultados:
Países Bajos tiene la mayor red de la UE (más de 240.000 puntos), pero solo el 3 % es de carga rápida.
En Países Bajos, Dinamarca y Suecia ya se matriculan entre 3 y 8 eléctricos por cada coche de gasolina; en Bulgaria y Chequia, menos de 0,2.
Croacia, Eslovenia e Italia tienen el mayor crecimiento interanual de eléctricos.
España, Irlanda y Francia tienen ayudas dirigidas a operadores de carga pública.

Recomendaciones de negocio
Priorizar la carga rápida en mercados con mucha red lenta y poca rápida.
Entrar primero donde coincidan demanda en crecimiento y ayudas para operadores de carga.
Vigilar los mercados emergentes (alto crecimiento, base pequeña) como segunda fase de expansión.
Limitaciones
Flota aproximada (suma de ventas): subestima los países con poco histórico y no descuenta bajas.
AFIR estimado con supuestos de potencia por punto; el dato oficial del Observatorio es la referencia.
Ayudas: clasificación propia; algunas han caducado y el índice no mide importes.
Normativa 2035 en revisión.
Próximos pasos
Estimar costes y retorno de la inversión (ROI) por país.
Añadir precio de la electricidad y uso real de los cargadores para estimar rentabilidad.
Analizar a nivel regional (por ejemplo, autopistas frente a ciudades).
Predecir las ventas de eléctricos con un modelo de machine learning.