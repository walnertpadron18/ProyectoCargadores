-- ##################################################################
-- Proyecto final: ¿Dónde invertir en carga pública en Europa?
-- ##################################################################

USE coches_electricos;

-- ##################################################################
-- Métrica 1: eléctricos por cada 1.000 habitantes
-- (eléctricos en circulación / población) x 1.000
-- ##################################################################

CREATE OR REPLACE VIEW v_m1_electricos_por_habitante AS
SELECT p.iso3,
       p.pais,
       f.bev_circulacion + f.phev_circulacion AS electricos_circulacion,
       po.poblacion,
       ROUND(1000 * (f.bev_circulacion + f.phev_circulacion) / po.poblacion, 1)
           AS electricos_por_1000_hab
FROM paises p
JOIN flota f      ON f.iso3 = p.iso3
JOIN poblacion po ON po.iso3 = p.iso3;


-- ##################################################################
-- Métrica 2: eléctricos por punto de carga público
-- Cuanto más alto, más saturada está la red y más oportunidad hay.
-- ##################################################################

CREATE OR REPLACE VIEW v_m2_electricos_por_punto AS
SELECT p.iso3,
       p.pais,
       pc.total_puntos,
       pc.carga_rapida,
       ROUND((f.bev_circulacion + f.phev_circulacion) / pc.total_puntos, 1)
           AS electricos_por_punto,
       ROUND(f.bev_circulacion / NULLIF(pc.carga_rapida, 0), 1)
           AS bev_por_punto_rapido,
       ROUND(100 * pc.carga_rapida / pc.total_puntos, 1)
           AS pct_carga_rapida
FROM paises p
JOIN flota f         ON f.iso3 = p.iso3
JOIN puntos_carga pc ON pc.iso3 = p.iso3;

-- ##################################################################
-- Metrica 2.5 
-- ##################################################################

CREATE OR REPLACE VIEW v_m2_electricos_por_punto22 AS
SELECT p.iso3,
       p.pais,
       f.bev_circulacion + f.phev_circulacion AS electricos_circulacion,
       pc.total_puntos,
       ROUND((f.bev_circulacion + f.phev_circulacion) / pc.total_puntos, 1)
           AS electricos_por_punto
FROM paises p
JOIN flota f         ON f.iso3 = p.iso3
JOIN puntos_carga pc ON pc.iso3 = p.iso3;

-- ##################################################################
-- Métrica 3: ratio eléctricos / gasolina (últimos 12 meses)
-- Misma ventana de 12 meses para todos los países.
-- Más de 1: ya se matriculan más eléctricos que coches de gasolina.
-- ##################################################################

CREATE OR REPLACE VIEW v_m3_ratio_electricos_gasolina AS

WITH ultima AS (
    SELECT iso3, MAX(fecha) AS ultima_fecha
    FROM matriculaciones
    GROUP BY iso3
),
ventana AS (
    SELECT MIN(ultima_fecha) AS fin,
           DATE_SUB(MIN(ultima_fecha), INTERVAL 11 MONTH) AS ini
    FROM ultima
),
ultimos12 AS (
    SELECT m.iso3,
           SUM(CASE WHEN m.tipo_motor = 'Electric vehicle (BEV+PHEV)'
                    THEN m.matriculaciones END) AS electricos,
           SUM(CASE WHEN m.tipo_motor IN ('Petrol')
                    THEN m.matriculaciones END) AS gasolina
    FROM matriculaciones m
    CROSS JOIN ventana v
    WHERE m.fecha BETWEEN v.ini AND v.fin
    GROUP BY m.iso3
)
SELECT p.iso3,
       p.pais,
       u.electricos AS electricos_12m,
       u.gasolina   AS gasolina_12m,
       ROUND(u.electricos / NULLIF(u.gasolina, 0), 2) AS ratio_elec_gasolina
FROM ultimos12 u
JOIN paises p ON p.iso3 = u.iso3;


-- ##################################################################
-- Métrica 4: índice de apoyo público (0 a 5, según ACEA)
-- ##################################################################

CREATE OR REPLACE VIEW v_m4_apoyo_publico AS
SELECT p.iso3,
       p.pais,
       a.ventaja_fiscal_compra,
       a.ventaja_fiscal_propiedad,
       a.ventaja_coche_empresa,
       a.ayuda_compra,
       a.ayuda_infraestructura,
       a.indice_apoyo
FROM paises p
LEFT JOIN ayudas a ON a.iso3 = p.iso3;


-- ##################################################################
-- Métrica 5: cumplimiento estimado del objetivo
-- Exigida = para coches electricos en autopistas. ver resultados
-- ##################################################################

CREATE OR REPLACE VIEW v_m5_carga_rapida2 AS
SELECT p.iso3,
       p.pais,
       pc.carga_rapida,
       pc.total_puntos,
       ROUND(100 * pc.carga_rapida / pc.total_puntos, 1)          AS pct_carga_rapida,
       f.bev_circulacion,
       ROUND(f.bev_circulacion / NULLIF(pc.carga_rapida, 0), 1)   AS bev_por_punto_rapido
FROM paises p
JOIN puntos_carga pc ON pc.iso3 = p.iso3
JOIN flota f         ON f.iso3 = p.iso3;


-- ##################################################################
-- VISTAS PARA TABLEAU
-- ##################################################################

-- 1) Una fila por país con todas las métricas 

CREATE OR REPLACE VIEW v_tableau_metricas_pais AS
SELECT p.iso3,
       p.pais,
       m1.electricos_circulacion,
       m1.poblacion,
       m1.electricos_por_1000_hab,
       m2.total_puntos,
       m2.electricos_por_punto,
       m3.electricos_12m,
       m3.gasolina_12m,
       m3.ratio_elec_gasolina,
       m4.indice_apoyo,
       m4.ayuda_infraestructura,
       m5.carga_rapida,
       m5.pct_carga_rapida,
       m5.bev_por_punto_rapido,
       m6.crecimiento_pct
FROM paises p
LEFT JOIN v_m1_electricos_por_habitante  m1 ON m1.iso3 = p.iso3
LEFT JOIN v_m2_electricos_por_punto      m2 ON m2.iso3 = p.iso3
LEFT JOIN v_m3_ratio_electricos_gasolina m3 ON m3.iso3 = p.iso3
LEFT JOIN v_m4_apoyo_publico             m4 ON m4.iso3 = p.iso3
LEFT JOIN v_m5_carga_rapida              m5 ON m5.iso3 = p.iso3
LEFT JOIN v_m6_crecimiento               m6 ON m6.iso3 = p.iso3;


-- 2) Una fila por país y mes (gráficos de evolución)

CREATE OR REPLACE VIEW v_tableau_evolucion_mensual AS
SELECT p.iso3,
       p.pais,
       m.fecha,
       SUM(CASE WHEN m.tipo_motor = 'Battery electric'            THEN m.matriculaciones END) AS bev,
       SUM(CASE WHEN m.tipo_motor = 'Plug-in hybrid'              THEN m.matriculaciones END) AS phev,
       SUM(CASE WHEN m.tipo_motor = 'Electric vehicle (BEV+PHEV)' THEN m.matriculaciones END) AS electricos,
       SUM(CASE WHEN m.tipo_motor = 'Petrol'                      THEN m.matriculaciones END) AS gasolina,
       SUM(CASE WHEN m.tipo_motor = 'Diesel'                      THEN m.matriculaciones END) AS diesel,
       SUM(CASE WHEN m.tipo_motor = 'All drivetrains'             THEN m.matriculaciones END) AS total_coches
FROM matriculaciones m
JOIN paises p ON p.iso3 = m.iso3
GROUP BY p.iso3, p.pais, m.fecha;

##########################################
-- 	Resultado
##########################################

CREATE OR REPLACE VIEW v_indice_oportunidad AS
WITH base AS (
    SELECT * FROM v_tableau_metricas_pais
    WHERE iso3 <> 'MLT'          -- Malta excluida por sus valores extremos
),
norm AS (
    SELECT iso3, pais,
        (electricos_por_punto - MIN(electricos_por_punto) OVER ())
          / (MAX(electricos_por_punto) OVER () - MIN(electricos_por_punto) OVER ()) AS n_saturacion,
        (bev_por_punto_rapido - MIN(bev_por_punto_rapido) OVER ())
          / (MAX(bev_por_punto_rapido) OVER () - MIN(bev_por_punto_rapido) OVER ()) AS n_carga_rapida,
        (crecimiento_pct - MIN(crecimiento_pct) OVER ())
          / (MAX(crecimiento_pct) OVER () - MIN(crecimiento_pct) OVER ())           AS n_crecimiento,
        (ratio_elec_gasolina - MIN(ratio_elec_gasolina) OVER ())
          / (MAX(ratio_elec_gasolina) OVER () - MIN(ratio_elec_gasolina) OVER ())   AS n_madurez,
        (indice_apoyo - MIN(indice_apoyo) OVER ())
          / (MAX(indice_apoyo) OVER () - MIN(indice_apoyo) OVER ())                 AS n_apoyo
    FROM base
)
SELECT iso3, pais,
       ROUND(0.20 * n_saturacion + 0.30 * n_carga_rapida + 0.25 * n_crecimiento
           + 0.10 * n_madurez   + 0.15 * n_apoyo, 3) AS indice_oportunidad,
       n_saturacion, n_carga_rapida, n_crecimiento, n_madurez, n_apoyo
FROM norm;


