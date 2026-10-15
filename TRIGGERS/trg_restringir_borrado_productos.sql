/*
============================================================================
OBJETIVO DEL SCRIPT:
Trigger a nivel de sentencia sobre la tabla PRODUCTO.
Asegura la política de preservación e integridad histórica del marketplace:
bloquea cualquier intento de eliminación física (DELETE) sobre el catálogo.
============================================================================
*/

CREATE OR REPLACE TRIGGER TRG_PREVENIR_BORRADO_PRODUCTOS
BEFORE DELETE ON PRODUCTO
BEGIN
    RAISE_APPLICATION_ERROR(
        -20005, 
        'Operación rechazada: En ChileRemates los productos no pueden eliminarse físicamente. Actualice el estado a Cancelado o Pausado.'
    );
END;
/