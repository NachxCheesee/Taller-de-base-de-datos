/*
============================================================================
OBJETIVO DEL SCRIPT:
Automatizar la auditoría y trazabilidad histórica de las variaciones de precios 
en el catálogo de PRODUCTOS. Este trigger se activa ante 
cualquier modificación sobre la columna PRECIO de la tabla PRODUCTO, 
comprueba que exista un cambio efectivo de valor, invoca a la función del paquete 
PKG_GESTION_PRODUCTOS para calcular la variación porcentual y registra de 
forma automática el precio anterior, el nuevo importe, el porcentaje y la 
fecha en la tabla HISTORIAL_PRECIO_PRODUCTO sin requerir intervención manual.
============================================================================
*/

CREATE OR REPLACE TRIGGER TRG_AUDITORIA_PRECIOS
AFTER UPDATE OF PRECIO ON PRODUCTO
FOR EACH ROW
DECLARE
    v_variacion NUMBER(6,2);
BEGIN
    -- Se dispara únicamente si hubo un cambio real
    IF :OLD.PRECIO <> :NEW.PRECIO THEN
        
        -- Llamamos a la función pública del paquete para obtener la variación matemática
        v_variacion := PKG_GESTION_PRODUCTOS.fn_calcular_variacion(:OLD.PRECIO, :NEW.PRECIO);

        INSERT INTO HISTORIAL_PRECIO_PRODUCTO (
            ID_PRODUCTO,
            PRECIO_ANTERIOR,
            PRECIO_NUEVO,
            PORCENTAJE_VARIACION,
            FECHA_CAMBIO
        ) VALUES (
            :NEW.ID_PRODUCTO,
            :OLD.PRECIO,
            :NEW.PRECIO,
            v_variacion,
            SYSDATE
        );
    END IF;
END;
/