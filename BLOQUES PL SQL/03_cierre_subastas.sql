/*
============================================================================
OBJETIVO DEL SCRIPT:
Bloque anónimo de ejecución para disparar el proceso automatizado de cierre 
masivo de subastas vencidas. Invoca al procedimiento sp_cerrar_subastas_vencidas.
============================================================================
*/

SET SERVEROUTPUT ON;
BEGIN
    -- Invocación directa del procedimiento almacenado
    sp_cerrar_subastas_vencidas;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error crítico al ejecutar el procedimiento de cierre: ' || SQLERRM);
END;
/