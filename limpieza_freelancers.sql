-- =====================================================
-- Proyecto : Limpieza del dataset Global Freelancers
-- Script   : limpieza_freelancers.sql
-- Autor    : Elliot Herrera Principe
-- Fecha    : 2026-10-07
-- Motor    : MySQL 8.0
-- Dataset  : global_freelancers_raw.csv (1000 filas, 12 columnas)
-- Fuente   : https://www.kaggle.com/datasets/urvishahir/global-freelancers-raw-dataset/data
--
-- Objetivo : Limpiar y estandarizar el dataset crudo para dejarlo
--            listo para análisis.
--
-- Decisiones clave:
--   - rating = 0.0 se trata como "sin calificación" (escala real 1-5) -> NULL
--   - Los NULL restantes se conservan, no se imputan
--   - Se mantiene la tabla plana (sin normalización en catálogos)
--
-- Resultado: freelancers_staging (1000 filas, tipada y validada)
-- =====================================================

-- =====================================================
-- 0. Preparar database y tabla
-- =====================================================

-- Database para alojar tabla
CREATE DATABASE IF NOT EXISTS global_freelancers;
USE global_freelancers;

-- Creamos e insertamos tabla
DROP TABLE IF EXISTS freelancers_raw;

CREATE TABLE freelancers_raw (
    freelancer_ID         VARCHAR(50),
    name                  VARCHAR(50),
    gender                VARCHAR(50),
    age                   VARCHAR(50),
    country               VARCHAR(50),
    language              VARCHAR(50),
    primary_skill         VARCHAR(50),
    years_of_experience   VARCHAR(50),
    `hourly_rate (USD)`   VARCHAR(50),
    rating                VARCHAR(50),
    is_active             VARCHAR(50),
    client_satisfaction   VARCHAR(50)
);

-- Insertamos datos con el sistema gestor de bases de datos

-- =====================================================
-- 1. Crear la tabla de trabajo
-- =====================================================

DROP TABLE IF EXISTS freelancers_staging;
CREATE TABLE freelancers_staging LIKE freelancers_raw;

INSERT INTO freelancers_staging
SELECT * FROM freelancers_raw;

-- =====================================================
-- 2. Perfilado
-- =====================================================

-- Tamaño y estructura
SELECT COUNT(*) FROM freelancers_staging;	-- 1000 registros
DESCRIBE freelancers_staging;

-- Mostrar registros distintos (sensible a acentos/mayusculas), longitud y veces
SELECT name COLLATE utf8mb4_0900_bin AS name, LENGTH(name) AS longitud, COUNT(*) AS veces
FROM freelancers_staging
GROUP BY name COLLATE utf8mb4_0900_bin, LENGTH(name)
HAVING veces > 1
ORDER BY 1;	-- 8 nombres se repiten 2 veces

SELECT gender COLLATE utf8mb4_0900_bin AS gender, LENGTH(gender) AS longitud, COUNT(*) AS veces
FROM freelancers_staging
GROUP BY gender COLLATE utf8mb4_0900_bin, LENGTH(gender)
ORDER BY 1;	-- 10 variantes de (Male, Female)

SELECT age COLLATE utf8mb4_0900_bin AS age, LENGTH(age) AS longitud, COUNT(*) AS veces
FROM freelancers_staging
GROUP BY age COLLATE utf8mb4_0900_bin, LENGTH(age)
ORDER BY 1;	-- 30 vacios

SELECT country COLLATE utf8mb4_0900_bin AS country, LENGTH(country) AS longitud, COUNT(*) AS veces
FROM freelancers_staging
GROUP BY country COLLATE utf8mb4_0900_bin, LENGTH(country)
ORDER BY 1;	-- limpio

SELECT language COLLATE utf8mb4_0900_bin AS language, LENGTH(language) AS longitud, COUNT(*) AS veces
FROM freelancers_staging
GROUP BY language COLLATE utf8mb4_0900_bin, LENGTH(language)
ORDER BY 1;	-- limpio

SELECT primary_skill COLLATE utf8mb4_0900_bin AS primary_skill, LENGTH(primary_skill) AS longitud, COUNT(*) AS veces
FROM freelancers_staging
GROUP BY primary_skill COLLATE utf8mb4_0900_bin, LENGTH(primary_skill)
ORDER BY 1;	-- limpio

SELECT years_of_experience COLLATE utf8mb4_0900_bin AS years_of_experience, LENGTH(years_of_experience) AS longitud, COUNT(*) AS veces
FROM freelancers_staging
GROUP BY years_of_experience COLLATE utf8mb4_0900_bin, LENGTH(years_of_experience)
ORDER BY 1;	-- 51 vacios, 0.0 != Null

SELECT `hourly_rate (USD)` COLLATE utf8mb4_0900_bin AS `hourly_rate (USD)`, LENGTH(`hourly_rate (USD)`) AS longitud, COUNT(*) AS veces
FROM freelancers_staging
GROUP BY `hourly_rate (USD)` COLLATE utf8mb4_0900_bin, LENGTH(`hourly_rate (USD)`)
ORDER BY 1;	-- 3 variantes, 94 vacios

SELECT rating COLLATE utf8mb4_0900_bin AS rating, LENGTH(rating) AS longitud, COUNT(*) AS veces
FROM freelancers_staging
GROUP BY rating COLLATE utf8mb4_0900_bin, LENGTH(rating)
ORDER BY 1;	-- 101 vacios, valores 0.0 = Null en un rating de (1 a 5)

SELECT is_active COLLATE utf8mb4_0900_bin AS is_active, LENGTH(is_active) AS longitud, COUNT(*) AS veces
FROM freelancers_staging
GROUP BY is_active COLLATE utf8mb4_0900_bin, LENGTH(is_active)
ORDER BY 1;	-- 8 variantes (0, 1), 89 vacios

SELECT client_satisfaction COLLATE utf8mb4_0900_bin AS client_satisfaction, LENGTH(client_satisfaction) AS longitud, COUNT(*) AS veces
FROM freelancers_staging
GROUP BY client_satisfaction COLLATE utf8mb4_0900_bin, LENGTH(client_satisfaction)
ORDER BY 1;	-- 2 variantes, 176 vacios


-- Detectar prefijos y sufijos en nombres, elevarlos por frecuencia
-- Primer token (candidatos a prefijo)
SELECT SUBSTRING_INDEX(TRIM(name), ' ', 1) AS token, COUNT(*) AS freq
FROM freelancers_staging
GROUP BY token
ORDER BY freq DESC
LIMIT 100;

-- Último token (candidatos a sufijo)
SELECT SUBSTRING_INDEX(TRIM(name), ' ', -1) AS token, COUNT(*) AS freq
FROM freelancers_staging
GROUP BY token
ORDER BY freq DESC
LIMIT 100;

-- El mas efectivo para este caso es buscar name con más de 2 palabras (detectar los extras)
SELECT name FROM freelancers_staging
WHERE LENGTH(TRIM(name)) - LENGTH(REPLACE(TRIM(name), ' ', '')) >= 2;	-- Prefijos (Mr.|Mrs.|Ms.|Miss|Dr.) Sufijos (Jr.|III|MD|DDS|DVM|PhD)

-- Rangos (aún como texto; se repiten en el Paso 7 ya con tipo numérico)
SELECT MIN(rating), MAX(rating) FROM freelancers_staging;


-- =====================================================
-- 3. Limpieza de texto
-- =====================================================

-- 3.1 Espacios sobrantes en todas las columnas de texto
UPDATE freelancers_staging
SET freelancer_ID       = TRIM(freelancer_ID),
    name                = TRIM(name),
    gender              = TRIM(gender),
    age                 = TRIM(age),
    country             = TRIM(country),
    language            = TRIM(language),
    primary_skill       = TRIM(primary_skill),
    years_of_experience = TRIM(years_of_experience),
    `hourly_rate (USD)` = TRIM(`hourly_rate (USD)`),
    rating              = TRIM(rating),
    is_active           = TRIM(is_active),
    client_satisfaction = TRIM(client_satisfaction);

-- 3.2 name: quitar prefijos (Mr., Mrs., Ms., Miss, Dr.)
SELECT name, REGEXP_REPLACE(name, '^(Mr|Mrs|Ms|Miss|Dr)\\.? ', '') AS name_limpio
FROM freelancers_staging
WHERE name REGEXP '^(Mr|Mrs|Ms|Miss|Dr)\\.? ';

UPDATE freelancers_staging
SET name = REGEXP_REPLACE(name, '^(Mr|Mrs|Ms|Miss|Dr)\\.? ', '')
WHERE name REGEXP '^(Mr|Mrs|Ms|Miss|Dr)\\.? ';

-- 3.3 name: quitar sufijos (Jr., III, MD, DDS, DVM, PhD...) -- 'c' = distingue mayúsculas
SELECT name,
       REGEXP_REPLACE(name, ' (Jr\\.?|III|MD|DDS|DVM|PhD)$', '', 1, 0, 'c') AS name_limpio
FROM freelancers_staging
WHERE REGEXP_LIKE(name, ' (Jr\\.?|III|MD|DDS|DVM|PhD)$', 'c');     -- esperado: 24 filas

UPDATE freelancers_staging
SET name = REGEXP_REPLACE(name, ' (Jr\\.?|III|MD|DDS|DVM|PhD)$', '', 1, 0, 'c')
WHERE REGEXP_LIKE(name, ' (Jr\\.?|III|MD|DDS|DVM|PhD)$', 'c');

-- 3.4 gender: 10 variantes -> 'Female' / 'Male'
UPDATE freelancers_staging
SET gender = CASE
    WHEN LOWER(gender) IN ('f', 'female') THEN 'Female'
    WHEN LOWER(gender) IN ('m', 'male')   THEN 'Male'
    ELSE gender
END;

-- 3.5 is_active: 8 variantes -> '1' / '0' (los vacíos se quedan como '' y pasan a NULL en el Paso 4)
UPDATE freelancers_staging
SET is_active = CASE
    WHEN LOWER(is_active) IN ('1', 'y', 'yes', 'true')  THEN '1'
    WHEN LOWER(is_active) IN ('0', 'n', 'no', 'false')  THEN '0'
    ELSE is_active
END;

-- 3.6 Símbolos en columnas numéricas ('$40', 'USD 100', '84%')
UPDATE freelancers_staging
SET `hourly_rate (USD)` = REGEXP_REPLACE(`hourly_rate (USD)`, '[^0-9.]', ''),
    client_satisfaction = REGEXP_REPLACE(client_satisfaction, '[^0-9.]', '');

-- 3.7 Quitar el '.0' final de enteros guardados como decimal ('52.0' -> '52')
--     (evita errores de conversión a TINYINT en el Paso 5 con sql_mode estricto)
UPDATE freelancers_staging
SET age                 = REGEXP_REPLACE(age, '\\.0+$', ''),
    years_of_experience = REGEXP_REPLACE(years_of_experience, '\\.0+$', '');

-- Verificación rápida
SELECT gender, COUNT(*) FROM freelancers_staging GROUP BY gender;                    -- Female 490 / Male 510
SELECT is_active, COUNT(*) FROM freelancers_staging GROUP BY is_active;              -- '1', '0' y ''
SELECT DISTINCT `hourly_rate (USD)` FROM freelancers_staging ORDER BY 1;             -- 20, 30, 40, 50, 75, 100, ''

-- =====================================================
-- 4. Vacios a NULL
-- =====================================================

UPDATE freelancers_staging
SET name                = NULLIF(name, ''),
    gender              = NULLIF(gender, ''),
    age                 = NULLIF(age, ''),
    country             = NULLIF(country, ''),
    language            = NULLIF(language, ''),
    primary_skill       = NULLIF(primary_skill, ''),
    years_of_experience = NULLIF(years_of_experience, ''),
    `hourly_rate (USD)` = NULLIF(`hourly_rate (USD)`, ''),
    rating              = NULLIF(rating, ''),
    is_active           = NULLIF(is_active, ''),
    client_satisfaction = NULLIF(client_satisfaction, '');

-- =====================================================
-- 5. Convertir segun tipo de columna
-- =====================================================

ALTER TABLE freelancers_staging
    MODIFY COLUMN freelancer_ID       CHAR(8) NOT NULL,
    MODIFY COLUMN name                VARCHAR(100),
    MODIFY COLUMN gender              VARCHAR(6),
    MODIFY COLUMN age                 TINYINT UNSIGNED,
    MODIFY COLUMN country             VARCHAR(30),
    MODIFY COLUMN language            VARCHAR(20),
    MODIFY COLUMN primary_skill       VARCHAR(30),
    MODIFY COLUMN years_of_experience TINYINT UNSIGNED,
    CHANGE COLUMN `hourly_rate (USD)` hourly_rate_usd DECIMAL(6,2),   -- renombrada: sin espacios ni paréntesis
    MODIFY COLUMN rating              DECIMAL(2,1),
    MODIFY COLUMN is_active           BOOLEAN,
    MODIFY COLUMN client_satisfaction TINYINT UNSIGNED;               -- porcentaje 0-100 (sin el símbolo %)

DESCRIBE freelancers_staging;

-- =====================================================
-- 6. Detectar y eliminar duplicados
-- =====================================================

-- Checkeo de ID duplicados
SELECT
    COUNT(*)                     AS total_filas,
    COUNT(DISTINCT freelancer_ID) AS ids_distintos,
    COUNT(*) - COUNT(DISTINCT freelancer_ID) AS ids_repetidos
FROM freelancers_staging;
-- Resultado: 1000 | 1000 | 0  -> no se encontraron IDs duplicados

-- 1) Detectar registros duplicados (mismo registro = todas las columnas menos el ID)
WITH dup_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY name, gender, age, country, language, primary_skill,
                            years_of_experience, hourly_rate_usd, rating,
                            is_active, client_satisfaction
               ORDER BY freelancer_ID
           ) AS row_num
    FROM freelancers_staging
)
SELECT *
FROM dup_cte
WHERE row_num > 1;
-- Resultado: 0 filas -> no se encontraron duplicados

-- =====================================================
-- 7. Validar consistencia logica
-- =====================================================

-- Edad fuera de rango razonable para un freelancer
SELECT * FROM freelancers_staging WHERE age < 18 OR age > 70;

-- Más años de experiencia de los posibles (empezar a trabajar antes de los 16)
SELECT * FROM freelancers_staging
WHERE age IS NOT NULL
  AND years_of_experience IS NOT NULL
  AND years_of_experience > age - 16;

-- Tarifa no positiva
SELECT * FROM freelancers_staging WHERE hourly_rate_usd <= 0;

-- Rating fuera de la escala 0-5
SELECT * FROM freelancers_staging WHERE rating NOT BETWEEN 0 AND 5;

-- Satisfacción fuera de 0-100
SELECT * FROM freelancers_staging WHERE client_satisfaction NOT BETWEEN 0 AND 100;

-- is_active solo 0 o 1
SELECT * FROM freelancers_staging WHERE is_active NOT IN (0, 1);

-- Valores de gender inesperados
SELECT * FROM freelancers_staging WHERE gender NOT IN ('Female', 'Male');

-- Nombres con caracteres raros o sin apellido
SELECT * FROM freelancers_staging
WHERE name REGEXP '[^A-Za-z '' -]' OR name NOT LIKE '% %';

-- =====================================================
-- 8. Tratar los Null
-- =====================================================

-- Conteo de NULL por columna (antes de decidir)
SELECT
    SUM(age IS NULL)                 AS age_null,        -- 30
    SUM(years_of_experience IS NULL) AS exp_null,        -- 51
    SUM(hourly_rate_usd IS NULL)     AS rate_null,       -- 94
    SUM(rating IS NULL)              AS rating_null,     -- 101
    SUM(rating = 0)                  AS rating_cero,     -- 145
    SUM(is_active IS NULL)           AS active_null,     -- 89
    SUM(client_satisfaction IS NULL) AS sat_null         -- 176
FROM freelancers_staging;

-- Decisión: rating = 0.0 significa "sin calificación" (la escala real va de 1.0 a 5.0) -> NULL
SELECT * FROM freelancers_staging WHERE rating = 0;     -- 145 filas

UPDATE freelancers_staging
SET rating = NULL
WHERE rating = 0;

-- =====================================================
-- 9. Verificar
-- =====================================================

DESCRIBE freelancers_staging;

-- Repetir el perfilado del Paso 2 sobre la tabla limpia
SELECT gender, COUNT(*) FROM freelancers_staging GROUP BY gender;
SELECT is_active, COUNT(*) FROM freelancers_staging GROUP BY is_active;
SELECT MIN(age), MAX(age), MIN(years_of_experience), MAX(years_of_experience) FROM freelancers_staging;
SELECT MIN(hourly_rate_usd), MAX(hourly_rate_usd) FROM freelancers_staging;            -- 20 a 100
SELECT MIN(rating), MAX(rating) FROM freelancers_staging;                              -- 1.0 a 5.0
SELECT MIN(client_satisfaction), MAX(client_satisfaction) FROM freelancers_staging;    -- 60 a 100

SELECT * FROM freelancers_staging LIMIT 20;












