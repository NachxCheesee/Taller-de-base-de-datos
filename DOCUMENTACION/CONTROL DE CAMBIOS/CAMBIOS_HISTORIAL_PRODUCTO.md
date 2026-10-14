# Historial y Control de Cambios - ChileRemates

## 1. Rediseño del Modelo de Datos
* **Eliminación de redundancia en `PRODUCTO`:** Se retiró la columna `PRECIO_DESCUENTO` para mantener únicamente el precio oficial vigente (`PRECIO`) y evitar columnas con valores nulos innecesarios.
* **Nueva entidad de auditoría (`HISTORIAL_PRECIO_PRODUCTO`):** Se implementó una tabla dedicada para registrar la trazabilidad histórica de modificaciones de precios (`PRECIO_ANTERIOR`, `PRECIO_NUEVO`, `PORCENTAJE_VARIACION` y `FECHA_CAMBIO`).

## 2. Empaquetado y Lógica Modular (`PAQUETES/pkg_gestion_productos.sql`)
* **Modularidad (Cabecera y Cuerpo):** Se separó la especificación pública de la lógica interna para facilitar mantenciones sin invalidar dependencias.
* **Función `fn_calcular_variacion`:** Componente matemático reutilizable que calcula la variación porcentual (+ alza, - rebaja) y bloquea montos negativos.
* **Procedimiento `sp_actualizar_precio_producto`:** Valida la existencia del producto, bloquea operaciones redundantes si el precio no cambia y ejecuta la actualización del catálogo.

## 3. Automatización con Triggers (`TRIGGERS/trg_auditoria_precios.sql`)
* **Trigger a nivel de fila (`AFTER UPDATE OF PRECIO`):** Se activa automáticamente ante modificaciones reales en el precio de cualquier producto.
* **Integración con el paquete:** Invoca a `fn_calcular_variacion` y persiste el registro en `HISTORIAL_PRECIO_PRODUCTO` de forma 100% autónoma y transparente.

## 4. Pruebas y Validación (`BLOQUES PL SQL/04_ejecucion_paquete.sql`)
* **Orquestación en bloque anónimo:** Se probaron con éxito dos escenarios reales sobre el catálogo: una rebaja (descuento porcentual negativo) y un alza (incremento porcentual positivo), verificando la consistencia de la auditoría y confirmando con `COMMIT`.