-- Habilita la creaciÃ³n de usuarios en Oracle 12c/19c/21c/23c
ALTER SESSION SET "_ORACLE_SCRIPT"=TRUE;

-- Crear el usuario
CREATE USER usuarioProyectoSemestral IDENTIFIED BY "123456"
DEFAULT TABLESPACE "USERS"
TEMPORARY TABLESPACE "TEMP";

-- Asignar cuota y permisos bÃ¡sicos
ALTER USER usuarioProyectoSemestral QUOTA UNLIMITED ON USERS;
GRANT CREATE SESSION TO usuarioProyectoSemestral;
GRANT "RESOURCE" TO usuarioProyectoSemestral;
ALTER USER usuarioProyectoSemestral DEFAULT ROLE "RESOURCE";