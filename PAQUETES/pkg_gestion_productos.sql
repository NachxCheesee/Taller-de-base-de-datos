/*
============================================================================
OBJETIVO DEL SCRIPT:
Empaquetar y modularizar la lógica de negocio para la administración y control
de precios del catálogo en ChileRemates. El paquete define una interfaz pública
y su correspondiente cuerpo de implementación, desacoplando responsabilidades:

1. Función 'fn_calcular_variacion':
   Calcula la variación porcentual entre el valor previo y el nuevo (+ alza, 
   - rebaja). 

2. Procedimiento 'sp_actualizar_precio_producto':
   Orquesta la modificación de precios validando la existencia del producto 
   y ejecutando la actualización en la tabla PRODUCTO, lo que activa 
   de forma transparente la auditoría histórica.
============================================================================
*/

-- ============================================================================
-- CABECERA 
-- ============================================================================
CREATE OR REPLACE PACKAGE PKG_GESTION_PRODUCTOS AS

    -- Función: Determina la variación porcentual entre dos montos (+ alza, - baja)
    FUNCTION fn_calcular_variacion (
        p_precio_anterior NUMBER,
        p_precio_nuevo    NUMBER
    ) RETURN NUMBER;

    -- Procedimiento: Modifica el precio base del producto (permite alzas o rebajas)
    PROCEDURE sp_actualizar_precio_producto (
        p_id_producto  NUMBER,
        p_nuevo_precio NUMBER
    );

END PKG_GESTION_PRODUCTOS;
/

-- ============================================================================
-- CUERPO 
-- ============================================================================
CREATE OR REPLACE PACKAGE BODY PKG_GESTION_PRODUCTOS AS

    -- Implementación de la Función de variación
    FUNCTION fn_calcular_variacion (
        p_precio_anterior NUMBER,
        p_precio_nuevo    NUMBER
    ) RETURN NUMBER IS
        v_variacion NUMBER(6,2);
    BEGIN
        -- Validación básica: no permitir montos negativos
        IF p_precio_nuevo < 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'El precio nuevo no puede ser negativo.');
        END IF;

        -- Si el precio anterior era 0 (ej: era un regalo), el aumento es directo
        IF p_precio_anterior = 0 THEN
            RETURN 100;
        END IF;

        -- Fórmula de variación porcentual: ((Nuevo - Anterior) / Anterior) * 100
        v_variacion := ROUND(((p_precio_nuevo - p_precio_anterior) / p_precio_anterior) * 100, 1);
        
        RETURN v_variacion;
    END fn_calcular_variacion;

    -- Implementación del Procedimiento de actualización
    PROCEDURE sp_actualizar_precio_producto (
        p_id_producto  NUMBER,
        p_nuevo_precio NUMBER
    ) IS
        v_precio_actual   PRODUCTO.PRECIO%TYPE;
        v_variacion_calc  NUMBER(6,2);
    BEGIN
        -- Consulta el precio actual del producto
        SELECT PRECIO 
        INTO v_precio_actual 
        FROM PRODUCTO 
        WHERE ID_PRODUCTO = p_id_producto;

        -- Validación: Evitar operaciones redundantes si el precio no cambió
        IF p_nuevo_precio = v_precio_actual THEN
            RAISE_APPLICATION_ERROR(-20003, 'El precio ingresado es idéntico al valor actual del producto ($' || v_precio_actual || ').');
        END IF;

        -- Si es distinto, calcula la variación (alza o baja)
        v_variacion_calc := fn_calcular_variacion(v_precio_actual, p_nuevo_precio);

        -- Actualiza la tabla (disparando el trigger de auditoría)
        UPDATE PRODUCTO
        SET PRECIO = p_nuevo_precio
        WHERE ID_PRODUCTO = p_id_producto;

        -- Despliegue de confirmación
        DBMS_OUTPUT.PUT_LINE('--- Actualización Exitosa: Producto ' || p_id_producto || ' ---');
        DBMS_OUTPUT.PUT_LINE('Precio anterior: $' || v_precio_actual);
        DBMS_OUTPUT.PUT_LINE('Precio nuevo:    $' || p_nuevo_precio);

        IF v_variacion_calc > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Resultado: Alza del +' || v_variacion_calc || '%');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Resultado: Rebaja del ' || ABS(v_variacion_calc) || '%');
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'El producto con ID ' || p_id_producto || ' no existe en el catálogo.');
    END sp_actualizar_precio_producto;

END PKG_GESTION_PRODUCTOS;
/