# Taller de Base de Datos: Sistema de Subastas y marketPlace en Oracle PL/SQL

Repositorio que contiene una base de datos y bloques anónimos en PL/SQL orientados a la gestión, validación, análisis y cierre automatizado para un proyecto de marketplace de subastas.

## Integrantes
* Ignacio Catalán Peralta
* Brayan González
* Jeremy Ibáñez

## Descripción de los Scripts

* **`01_registro_oferta.sql`**: Valida y registra de manera segura una nueva oferta. Verifica que la subasta exista, se encuentre activa y dentro del plazo límite mediante excepciones personalizadas antes de persistir los datos.
* **`02_top3_pujas.sql`**: Consulta y estructura en memoria el podio de las tres ofertas más altas para una subasta específica utilizando `VARRAY(3)` combinada con un `RECORD` para mostrar los datos de los usuarios.
* **`03_cierre_subastas.sql`**: Proceso automatizado que recorre subastas vencidas, determina la puja ganadora desempatando por monto y marca cronológica mediante cursores explícitos anidados, registrando la transacción comercial.

## Modelo de Datos Principal

* **`USUARIO`**: Almacena la información de los participantes del marketplace, incluyendo nombres, apellidos y ubicación.
* **`PRODUCTO`**: Contiene los artículos publicados para la venta o subasta asociados a sus categorías y estados.
* **`SUBASTA`**: Gestiona las reglas, precios mínimos, fechas límite y estados operativos (`1: Activa`, `3: Finalizada`, `4: Cancelada`).
* **`OFERTA`**: Registra cada puja realizada por los usuarios con precisión de marca de tiempo (`TIMESTAMP`).
* **`TRANSACCION_SUBASTA`**: Almacena las transacciones oficiales de las subastas, asociando al ganador, vendedor, monto final y cálculo automático de la comisión de la plataforma (5%).

## Criterios Técnicos Implementados

* **Tipos Compuestos**: Uso de `VARRAY` para limitar colecciones en memoria y `RECORD` para empaquetar estructuras de datos relacionales del ganador.
* **Cursores Explícitos con Parámetros**: Implementación de bucles anidados para procesar lotes y consultar subastas de forma dinámica.
* **Manejo Integral de Excepciones**: Combinación de excepciones personalizadas de negocio (`e_subasta_inactiva`, `e_sin_ofertas`) con excepciones predefinidas de Oracle (`NO_DATA_FOUND`, `DUP_VAL_ON_INDEX`).
* **Preservación**: Uso exclusivo de actualizaciones de estado (`UPDATE`) e inserciones transaccionales, asegurando que toda la información se preserve.

## Requisitos y Entorno
* **Motor de Base de Datos**: Oracle Database (compatible con versiones 19c, 21c o 23c).
* **Herramienta de Gestión**: Oracle SQL Developer o Visual Studio Code con las extensiones de Oracle SQL.
* **Configuración de Sesión**: Requiere activar la salida por consola mediante `SET SERVEROUTPUT ON;` antes de ejecutar cada bloque PL/SQL.