/*
============================================================================
OBJETIVO DEL SCRIPT:
Procedimiento almacenado sin parámetros para automatizar el cierre por lotes 
de subastas vencidas y la liquidación comercial. El procedimiento recorre las 
subastas activas cuya fecha límite ya expiró, obtiene la comisión vigente 
invocando a fn_obtener_comision_plataforma, determina la mejor puja mediante 
un cursor parametrizado y registra atómicamente la venta en TRANSACCION_SUBASTA 
actualizando los estados del catálogo.
============================================================================
*/

CREATE OR REPLACE PROCEDURE sp_cerrar_subastas_vencidas IS
    -- Obtención dinámica de la comisión desde la función almacenada
    v_porcentaje_comision NUMBER(4,2) := fn_obtener_comision_plataforma();

    -- Estructura para almacenar los datos del ganador y la comisión
    TYPE r_ganador IS RECORD (
        id_usuario  OFERTA.ID_USUARIO%TYPE,
        monto       OFERTA.MONTO%TYPE,
        comision    NUMBER(12)
    );
    v_ganador   r_ganador;
    v_id_trans  NUMBER;

    -- Cursor principal: subastas activas vencidas
    CURSOR cur_subastas IS
        SELECT ID_SUBASTA, ID_PRODUCTO, ID_USUARIO
        FROM SUBASTA
        WHERE ID_ESTADO_VENTA = 1 
          AND FECHA_FINALIZACION <= SYSDATE;

    -- Cursor parametrizado: ofertas de cada subasta ordenadas por monto y tiempo
    CURSOR cur_ofertas (p_id NUMBER) IS
        SELECT ID_USUARIO, MONTO, ROUND(MONTO * v_porcentaje_comision) AS COMISION
        FROM OFERTA
        WHERE ID_SUBASTA = p_id
        ORDER BY MONTO DESC, FECHA_OFERTA ASC;

    -- Excepción de negocio para subastas finalizadas sin ofertas
    e_sin_ofertas EXCEPTION;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO PROCESO BATCH DE CIERRE DE SUBASTAS ===');

    FOR sub IN cur_subastas LOOP
        BEGIN
            -- Reinicio de la estructura de memoria por cada subasta
            v_ganador := NULL;

            -- Extracción de la oferta con mayor valor
            FOR ofr IN cur_ofertas(sub.ID_SUBASTA) LOOP
                v_ganador.id_usuario := ofr.ID_USUARIO;
                v_ganador.monto      := ofr.MONTO;
                v_ganador.comision   := ofr.COMISION;
                EXIT; -- Solo se extrae el primer registro (ganador)
            END LOOP;

            -- Si no se registraron ofertas, se dispara la excepción de subasta desierta
            IF v_ganador.id_usuario IS NULL THEN
                RAISE e_sin_ofertas;
            END IF;

            -- Generación de clave primaria para la transacción
            SELECT NVL(MAX(ID_TRANSACCION), 0) + 1 INTO v_id_trans FROM TRANSACCION_SUBASTA;

            -- Registro de la liquidación oficial
            INSERT INTO TRANSACCION_SUBASTA (
                ID_TRANSACCION, ID_SUBASTA, ID_PRODUCTO, 
                ID_USUARIO_GANADOR, ID_USUARIO_VENDEDOR, MONTO_FINAL, COMISION_PLATAFORMA, FECHA_CIERRE
            )
            VALUES (
                v_id_trans, sub.ID_SUBASTA, sub.ID_PRODUCTO, 
                v_ganador.id_usuario, sub.ID_USUARIO, v_ganador.monto, v_ganador.comision, SYSDATE
            );

            -- Actualización de estados a Finalizado / Vendido
            UPDATE SUBASTA SET ID_ESTADO_VENTA = 3 WHERE ID_SUBASTA = sub.ID_SUBASTA;
            UPDATE PRODUCTO SET ID_ESTADO_VENTA = 3 WHERE ID_PRODUCTO = sub.ID_PRODUCTO;
            
            DBMS_OUTPUT.PUT_LINE('Subasta ' || sub.ID_SUBASTA || ' cerrada con éxito. Ganador ID: ' || v_ganador.id_usuario || ' por $' || v_ganador.monto);

        EXCEPTION
            -- Subasta desierta: el producto no se adjudica y la subasta pasa a Cancelada
            WHEN e_sin_ofertas THEN
                UPDATE SUBASTA SET ID_ESTADO_VENTA = 4 WHERE ID_SUBASTA = sub.ID_SUBASTA;
                DBMS_OUTPUT.PUT_LINE('Subasta ' || sub.ID_SUBASTA || ' cancelada (sin ofertas registradas).');

            -- Evita duplicidades si la transacción ya existía
            WHEN DUP_VAL_ON_INDEX THEN
                DBMS_OUTPUT.PUT_LINE('Error de integridad: La subasta ' || sub.ID_SUBASTA || ' ya posee una transacción registrada.');

            -- Manejo de fallos imprevistos a nivel de fila sin abortar el lote completo
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error inesperado en subasta ' || sub.ID_SUBASTA || ': ' || SQLERRM);
        END;
    END LOOP;

    -- Confirmación general del lote procesado
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=== CIERRE DE SUBASTAS FINALIZADO Y CONFIRMADO (COMMIT) ===');
END sp_cerrar_subastas_vencidas;
/