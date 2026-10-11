# Limpieza de datos: Global Freelancers (MySQL)

Proyecto de limpieza y estandarización de un dataset crudo de freelancers usando **SQL (MySQL 8.0)**. El objetivo es dejar los datos tipados, consistentes y listos para análisis.

## Dataset

- **Fuente:** [Global Freelancers Raw Dataset (Kaggle)](https://www.kaggle.com/datasets/urvishahir/global-freelancers-raw-dataset/data)
- **Tamaño:** 1000 filas y 12 columnas
- **Columnas:** `freelancer_ID`, `name`, `gender`, `age`, `country`, `language`, `primary_skill`, `years_of_experience`, `hourly_rate (USD)`, `rating`, `is_active`, `client_satisfaction`

## Problemas encontrados

|Columna|Problema|
|---|---|
|`name`|Prefijos (`Mr.`, `Mrs.`, `Ms.`, `Miss`, `Dr.`) y sufijos (`Jr.`, `III`, `MD`, `DDS`, `DVM`, `PhD`)|
|`gender`|10 variantes de `Male` / `Female` (`f`, `F`, `FEMALE`, `female`, `Female`, `m`, `M`, `MALE`, `Male` `male`)|
|`age`, `years_of_experience`|Enteros guardados como decimal (`52.0`) y valores vacíos|
|`hourly_rate (USD)`|Símbolos (`$40`, `USD 100`) y valores vacíos|
|`rating`|Valores vacíos y valores `0.0` (la escala real es de 1 a 5)|
|`is_active`|8 variantes (`1/0`, `Y/N`, `yes/no`, `True/False`) y valores vacíos|
|`client_satisfaction`|Mezcla de `84%` y `90`, y valores vacíos|

## Proceso de limpieza (9 pasos)

1. **Tabla de trabajo:** copia de `freelancers_raw` en `freelancers_staging` (la original no se toca).
2. **Perfilado:** conteos, valores distintos, nulos/vacíos, prefijos y sufijos.
3. **Limpieza de texto:** `TRIM`, nombres, `gender`, `is_active`, símbolos y `.0` finales.
4. **Vacíos a NULL.**
5. **Conversión de tipos:** `TINYINT`, `DECIMAL`, `BOOLEAN`, etc. y renombrado de `hourly_rate (USD)` a `hourly_rate_usd`.
6. **Duplicados:** se revisaron IDs y registros completos con `ROW_NUMBER()`; no se encontraron duplicados.
7. **Validación lógica:** rangos de edad, experiencia, tarifa, rating, satisfacción, `gender` e `is_active`.
8. **Tratamiento de NULL:** ver decisiones clave.
9. **Verificación final** sobre la tabla limpia.

## Decisiones clave

- `rating = 0.0` se trata como "sin calificación" y se convierte a `NULL`.
- Los demás `NULL` se conservan, no se imputan con promedios.
- No se eliminó ninguna fila.
- Hay 8 nombres repetidos, pero son personas distintas (distinto país, skill y datos), por lo que no son duplicados.
- Se mantiene la tabla plana, sin normalizar en catálogos.

## Resultado

Tabla `freelancers_staging` con **1000 filas**, tipada y validada.

|Campo|Rango final|
|---|---|
|`hourly_rate_usd`|20 a 100|
|`rating`|1.0 a 5.0 (o `NULL`)|
|`client_satisfaction`|60 a 100|

## Archivos

- `limpieza_freelancers.sql`: script completo de limpieza, comentado paso a paso.
- `global_freelancers_raw.csv`: datos crudos.
- `global_freelancers_staging.csv`: datos limpios.

## Cómo reproducirlo

1. Descarga el CSV desde Kaggle.
2. Ejecuta la sección 0 del script para crear la base de datos y la tabla `freelancers_raw` (todas las columnas como `VARCHAR`).
3. Importa el CSV a `freelancers_raw` (por ejemplo, con el Table Data Import Wizard de MySQL Workbench).
4. Ejecuta el resto del script en orden (secciones 1 a 9).
