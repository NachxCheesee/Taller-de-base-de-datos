/*
============================================================================
OBJETIVO DEL SCRIPT:
Validar y registrar de manera segura una nueva oferta para una SUBASTA. El bloque comprueba las reglas de negocio:
verifica la existencia de la subasta, confirma que permanezca activa 
y valida que el plazo límite de publicación no haya expirado, controlando los 
posibles errores mediante excepciones.
============================================================================
*/

SET SERVEROUTPUT ON;
DECLARE
    -- Definición de datos de prueba para simular el ingreso de la puja
    v_id_subasta    SUBASTA.ID_SUBASTA%TYPE := 501;
    v_id_usuario    USUARIO.ID_USUARIO%TYPE := 3;
    v_monto         OFERTA.MONTO%TYPE       := 130000;
    v_comentario    OFERTA.COMENTARIO%TYPE  := 'Oferta formal';

    -- Variables para capturar la información operativa de la subasta
    v_estado        SUBASTA.ID_ESTADO_VENTA%TYPE;
    v_fecha_fin     SUBASTA.FECHA_FINALIZACION%TYPE;
    v_nuevo_id      OFERTA.ID_OFERTA%TYPE;

    -- Excepciones de usuario para controlar infracciones a las reglas del negocio
    e_subasta_inactiva  EXCEPTION;
    e_plazo_expirado    EXCEPTION;
BEGIN
    -- Se recupera el estado de venta y la fecha de término de la subasta indicada
    SELECT ID_ESTADO_VENTA, FECHA_FINALIZACION
    INTO v_estado, v_fecha_fin
    FROM SUBASTA
    WHERE ID_SUBASTA = v_id_subasta;

    -- Validación: La subasta debe encontrarse en estado activo para recibir ofertas
    IF v_estado <> 1 THEN
        RAISE e_subasta_inactiva;
    END IF;

    -- Validación: La fecha y hora actual no debe sobrepasar el tiempo límite fijado
    IF v_fecha_fin <= SYSDATE THEN
        RAISE e_plazo_expirado;
    END IF;

    -- Generación del correlativo para la clave primaria de la nueva oferta
    SELECT NVL(MAX(ID_OFERTA), 0) + 1 INTO v_nuevo_id FROM OFERTA;

    -- Inserción de la puja una vez superadas con éxito todas las validaciones
    INSERT INTO OFERTA (ID_OFERTA, ID_SUBASTA, ID_USUARIO, MONTO, FECHA_OFERTA, COMENTARIO)
    VALUES (v_nuevo_id, v_id_subasta, v_id_usuario, v_monto, SYSTIMESTAMP, v_comentario);

    -- Confirmación de los cambios en la base de datos
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Oferta registrada exitosamente (ID: ' || v_nuevo_id || ') por $' || v_monto);

EXCEPTION
    -- Captura el caso en que el identificador de la subasta no exista
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: La subasta ' || v_id_subasta || ' no existe en el sistema.');

    -- Tratamiento cuando la subasta no está disponible para recibir ofertas
    WHEN e_subasta_inactiva THEN
        DBMS_OUTPUT.PUT_LINE('Regla de negocio: La subasta se encuentra inactiva o finalizada.');

    -- Tratamiento cuando el periodo de ofertas ha concluido
    WHEN e_plazo_expirado THEN
        DBMS_OUTPUT.PUT_LINE('Regla de negocio: El plazo para ofertar en esta subasta ya venció.');

    -- Control de contingencia ante fallos imprevistos con reversión transaccional
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error inesperado en el sistema: ' || SQLERRM);
END;
/