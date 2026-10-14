/*
============================================================================
OBJETIVO DEL SCRIPT:
Probar la integración integral del paquete PKG_GESTION_PRODUCTOS y el trigger 
TRG_AUDITORIA_PRECIOS evaluando dos escenarios:
1. Una rebaja de precio.
2. Un alza de precio.
Ambas operaciones validan el negocio, calculan la variación y disparan el 
trigger para registrar la auditoría histórica.
============================================================================
*/

SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  PRUEBA 1: APLICAR REBAJA DE PRECIO (DESCUENTO)');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    
    -- Producto 101: Monitor ASUS (Precio base: $140.000 -> Baja a $120.000)
    PKG_GESTION_PRODUCTOS.sp_actualizar_precio_producto(
        p_id_producto  => 101,
        p_nuevo_precio => 120000
    );

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  PRUEBA 2: APLICAR ALZA DE PRECIO (INCREMENTO)');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    
    -- Producto 102: PlayStation 4 Slim (Precio base: $180.000 -> Sube a $210.000)
    PKG_GESTION_PRODUCTOS.sp_actualizar_precio_producto(
        p_id_producto  => 102,
        p_nuevo_precio => 210000
    );

    -- Confirmación atómica de ambas operaciones y sus registros en el historial
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> Transacciones confirmadas exitosamente con COMMIT. <<<');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error en la ejecución: ' || SQLERRM);
END;
/


SELECT ID_HISTORIAL, ID_PRODUCTO, PRECIO_ANTERIOR, PRECIO_NUEVO, PORCENTAJE_VARIACION, FECHA_CAMBIO 
FROM HISTORIAL_PRECIO_PRODUCTO;