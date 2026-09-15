/*
============================================================================
OBJETIVO DEL SCRIPT:
Consultar y estructurar en memoria el podio con las tres ofertas más altas
registradas para una subasta específica. El bloque combina un RECORD con una
colección VARRAY para almacenar tanto el nombre y apellido del usuario como 
el monto de cada puja, asegurando la verificación de existencia de la subasta 
y el control de registros vacíos mediante excepciones.
============================================================================
*/

SET SERVEROUTPUT ON;
DECLARE
    -- Identificador de la subasta a consultar
    v_id_subasta    SUBASTA.ID_SUBASTA%TYPE := 501;
    v_existe        NUMBER;

    -- Estructura para agrupar el nombre del postor y su monto basándose en las columnas reales
    TYPE r_postor IS RECORD (
        nombre_completo VARCHAR2(100),
        monto           OFERTA.MONTO%TYPE
    );

    -- Colección de tamaño fijo para almacenar el podio de los tres mejores postores
    TYPE t_top_pujas IS VARRAY(3) OF r_postor;
    v_podio         t_top_pujas := t_top_pujas();
    v_indice        PLS_INTEGER := 0;

    -- Excepción personalizada para subastas que no tienen ofertas
    e_sin_postores  EXCEPTION;
BEGIN
    -- Validación de existencia previa de la subasta en el sistema
    SELECT COUNT(*)
    INTO v_existe
    FROM SUBASTA
    WHERE ID_SUBASTA = v_id_subasta;

    IF v_existe = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;

    -- Extracción de las mejores ofertas uniendo con la tabla USUARIO mediante PNOMBRE y PAPELLIDO
    FOR reg IN (
        SELECT u.PNOMBRE || ' ' || u.PAPELLIDO AS nom_completo, o.MONTO 
        FROM OFERTA o
        JOIN USUARIO u ON o.ID_USUARIO = u.ID_USUARIO
        WHERE o.ID_SUBASTA = v_id_subasta 
        ORDER BY o.MONTO DESC, o.FECHA_OFERTA ASC
        FETCH FIRST 3 ROWS ONLY
    ) LOOP
        v_podio.EXTEND;
        v_indice := v_indice + 1;
        v_podio(v_indice).nombre_completo := reg.nom_completo;
        v_podio(v_indice).monto           := reg.MONTO;
    END LOOP;

    -- Validación de postores registrados en la colección
    IF v_podio.COUNT = 0 THEN
        RAISE e_sin_postores;
    END IF;

    -- Despliegue estructurado del podio en consola
    DBMS_OUTPUT.PUT_LINE('--- TOP 3 POSTORES (SUBASTA ' || v_id_subasta || ') ---');
    FOR i IN 1..v_podio.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Lugar ' || i || ': ' || v_podio(i).nombre_completo || ' con una oferta de $' || v_podio(i).monto);
    END LOOP;

EXCEPTION
    -- Control cuando la subasta no existe en el catálogo
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: La subasta ' || v_id_subasta || ' no existe en el sistema.');

    -- Control de negocio cuando la subasta no tiene pujas ingresadas
    WHEN e_sin_postores THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: La subasta ' || v_id_subasta || ' aún no registra ofertas de compradores.');

    -- Captura de contingencias imprevistas
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado en el sistema: ' || SQLERRM);
END;
/