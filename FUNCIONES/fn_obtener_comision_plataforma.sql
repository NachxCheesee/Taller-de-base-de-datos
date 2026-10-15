/*
============================================================================
OBJETIVO DEL SCRIPT:
Función almacenada sin parámetros para centralizar el porcentaje de comisión 
oficial cobrado por ChileRemates en cada transacción cerrada. Permite 
que cualquier procedimiento o cálculo financiero consulte el valor vigente de la comisión.
============================================================================
*/

CREATE OR REPLACE FUNCTION fn_obtener_comision_plataforma 
RETURN NUMBER IS
    -- Tasa oficial de comisión de la plataforma: 5% (0.05)
    v_comision CONSTANT NUMBER(4,2) := 0.05;
BEGIN
    RETURN v_comision;
END fn_obtener_comision_plataforma;
/