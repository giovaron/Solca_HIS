-- Y:\sas\guiones\cambios_solca_quito\empleados_roles.trg
--
-- Generated for Oracle 9i on Mon Aug 07  09:22:27 2006 by Server Generator 6.5.96.5.6
 



PROMPT Creating Trigger 'ROLINGFCH'
CREATE OR REPLACE TRIGGER ROLINGFCH
 AFTER UPDATE OF FECHA_DE_SALIDA
 ON EMPLEADOS_ROLES
 FOR EACH ROW
 WHEN (new.fecha_de_salida <> old.fecha_de_salida 
and old.fecha_de_salida is not null)
BEGIN
   INSERT INTO INGRESOS_SALIDAS_EMPLEADOS
   VALUES (:OLD.EMP_CODIGO,:OLD.CODIGO,INGSAL_SEQ.NEXTVAL,:OLD.FECHA_DE_INGRESO,:NEW.FECHA_DE_SALIDA,INGSAL_SEQ.NEXTVAL);   
EXCEPTION
   WHEN OTHERS THEN
   QMS$ERRORS.UNHANDLED_EXCEPTION('Error en trigger ROLINGFCH');
END;
/
SHOW ERROR















