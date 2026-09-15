/*
============================================================================
OBJETIVO DEL SCRIPT:
Automatizar el cierre de subastas vencidas y el registro de ventas.
El bloque recorre las subastas activas cuyo plazo de tiempo ha expirado, 
identifica la oferta ganadora, almacena los datos en un RECORD y guarda el 
resultado final en la tabla de transacciones, actualizando los estados del 
catálogo.
============================================================================
*/

SET SERVEROUTPUT ON;
DECLARE
    -- Variable para configurar el porcentaje de la comisión de la plataforma
    v_porcentaje_comision NUMBER(4,2) := 0.05;

    -- Estructura compuesta para encapsular los datos comerciales del ganador y la comisión
    TYPE r_ganador IS RECORD (
        id_usuario  OFERTA.ID_USUARIO%TYPE,
        monto       OFERTA.MONTO%TYPE,
        comision    NUMBER(12)
    );
    v_ganador   r_ganador;
    v_id_trans  NUMBER;

    -- Cursor principal: Recupera las subastas activas que ya sobrepasaron su fecha límite
    CURSOR cur_subastas IS
        SELECT ID_SUBASTA, ID_PRODUCTO, ID_USUARIO
        FROM SUBASTA
        WHERE ID_ESTADO_VENTA = 1 
          AND FECHA_FINALIZACION <= SYSDATE;

    -- Cursor parametrizado: Recupera las ofertas de una subasta ordenadas por mayor monto y prioridad temporal
    CURSOR cur_ofertas (p_id NUMBER) IS
        SELECT ID_USUARIO, MONTO, ROUND(MONTO * v_porcentaje_comision) AS COMISION
        FROM OFERTA
        WHERE ID_SUBASTA = p_id
        ORDER BY MONTO DESC, FECHA_OFERTA ASC;

    -- Excepción de negocio para gestionar subastas finalizadas sin ningún postor
    e_sin_ofertas EXCEPTION;
BEGIN
    -- Recorrido del lote de subastas vencidas
    FOR sub IN cur_subastas LOOP
        BEGIN
            -- Reinicio de la estructura de memoria antes de evaluar cada subasta
            v_ganador := NULL;

            -- Lectura de la mejor puja mediante el cursor con parámetro
            FOR ofr IN cur_ofertas(sub.ID_SUBASTA) LOOP
                v_ganador.id_usuario := ofr.ID_USUARIO;
                v_ganador.monto      := ofr.MONTO;
                v_ganador.comision   := ofr.COMISION;
                EXIT; -- Solo se extrae el primer registro, correspondiente al ganador
            END LOOP;

            -- Si no se encontraron registros de ofertas, se dispara la excepción de subasta desierta
            IF v_ganador.id_usuario IS NULL THEN
                RAISE e_sin_ofertas;
            END IF;

            -- Generación de la clave primaria para la transacción de cierre
            SELECT NVL(MAX(ID_TRANSACCION), 0) + 1 INTO v_id_trans FROM TRANSACCION_SUBASTA;

            -- Registro oficial de la liquidación en la tabla transaccional
            INSERT INTO TRANSACCION_SUBASTA (
                ID_TRANSACCION, ID_SUBASTA, ID_PRODUCTO, 
                ID_USUARIO_GANADOR, ID_USUARIO_VENDEDOR, MONTO_FINAL, COMISION_PLATAFORMA, FECHA_CIERRE
            )
            VALUES (
                v_id_trans, sub.ID_SUBASTA, sub.ID_PRODUCTO, 
                v_ganador.id_usuario, sub.ID_USUARIO, v_ganador.monto, v_ganador.comision, SYSDATE
            );

            -- Actualización de estado: Subasta y Producto pasan a Finalizado / Vendido
            UPDATE SUBASTA SET ID_ESTADO_VENTA = 3 WHERE ID_SUBASTA = sub.ID_SUBASTA;
            UPDATE PRODUCTO SET ID_ESTADO_VENTA = 3 WHERE ID_PRODUCTO = sub.ID_PRODUCTO;
            
            DBMS_OUTPUT.PUT_LINE('Subasta ' || sub.ID_SUBASTA || ' cerrada con éxito. Ganador ID: ' || v_ganador.id_usuario || ' por $' || v_ganador.monto);

        EXCEPTION
            -- Gestión de subasta desierta: el producto no se adjudica y la subasta pasa a Cancelada
            WHEN e_sin_ofertas THEN
                UPDATE SUBASTA SET ID_ESTADO_VENTA = 4 WHERE ID_SUBASTA = sub.ID_SUBASTA;
                DBMS_OUTPUT.PUT_LINE('Subasta ' || sub.ID_SUBASTA || ' cancelada (sin ofertas registradas).');

            -- Excepción predefinida: Controla intentos de duplicidad sobre subastas ya liquidadas
            WHEN DUP_VAL_ON_INDEX THEN
                DBMS_OUTPUT.PUT_LINE('Error de integridad: La subasta ' || sub.ID_SUBASTA || ' ya posee una transacción registrada.');

            -- Manejo de cualquier otro imprevisto a nivel de fila para no interrumpir el resto del lote
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error inesperado en subasta ' || sub.ID_SUBASTA || ': ' || SQLERRM);
        END;
    END LOOP;

    -- Confirmación general de todas las operaciones realizadas en el lote
    COMMIT;
END;
/