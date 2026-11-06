CREATE DATABASE coches_electricos;
USE coches_electricos;

CREATE TABLE paises (
    iso3 CHAR(3) PRIMARY KEY,
    pais VARCHAR(100) NOT NULL,
    continente VARCHAR(50)
);

CREATE TABLE tipos_motor (
    tipo_motor VARCHAR(50) PRIMARY KEY,
    es_agregado INT NOT NULL
);

CREATE TABLE matriculaciones (
    iso3 CHAR(3) NOT NULL,
    fecha DATE NOT NULL,
    tipo_motor VARCHAR(50) NOT NULL,
    matriculaciones INT,
    PRIMARY KEY (iso3, fecha, tipo_motor),
    FOREIGN KEY (iso3) REFERENCES paises(iso3),
    FOREIGN KEY (tipo_motor) REFERENCES tipos_motor(tipo_motor)
);

CREATE TABLE flota (
    iso3 CHAR(3) NOT NULL,
    fecha_referencia DATE NOT NULL,
    bev_circulacion INT,
    phev_circulacion INT,
    PRIMARY KEY (iso3, fecha_referencia),
    FOREIGN KEY (iso3) REFERENCES paises(iso3)
);

CREATE TABLE puntos_carga (
    iso3 CHAR(3) NOT NULL,
    fecha_referencia DATE NOT NULL,
    carga_lenta INT,
    carga_media INT,
    carga_rapida INT,
    total_puntos INT,
    PRIMARY KEY (iso3, fecha_referencia),
    FOREIGN KEY (iso3) REFERENCES paises(iso3)
);

CREATE TABLE poblacion (
    iso3 CHAR(3) NOT NULL,
    año INT NOT NULL,
    poblacion INT,
    PRIMARY KEY (iso3, anio),
    FOREIGN KEY (iso3) REFERENCES paises(iso3)
);

CREATE TABLE ayudas (
    iso3 CHAR(3) PRIMARY KEY,
    ventaja_fiscal_compra INT,
    ventaja_fiscal_propiedad INT,
    ventaja_coche_empresa INT,
    ayuda_compra INT,
    ayuda_infraestructura INT,
    indice_apoyo INT,
    FOREIGN KEY (iso3) REFERENCES paises(iso3)
);