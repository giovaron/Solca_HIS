-- \\Svr\Z\sas\guiones\CAMBIOS SISTEMA CON TARIFARIO\ICSC\CUENTAS.trg
--
-- Generated for Oracle 9i on Mon Oct 31  12:14:26 2011 by Server Generator 6.5.96.5.6
 









PROMPT Creating Trigger 'CNTANLCRG'
CREATE OR REPLACE TRIGGER CNTANLCRG
 AFTER UPDATE OF ESTADO
 ON CUENTAS
 FOR EACH ROW
 WHEN (NEW.ESTADO = 'ANL')
BEGIN
   IF GNRL.ROL_HABILITADO('ANULAR_CARGOS') OR :NEW.CREADO_POR=USER THEN
   BEGIN
-- si el rol es anular_cargos o el usuario que modifica es el mismo que creo
-- permitimos anular el item de los consumos generales.
      IF :OLD.DOCUMENTO IN ('X','S','F') THEN
         UPDATE DETALLES_DESCARGOS_GENERAL
         SET ESTADO = 'ANL'
         WHERE DSCGNR_NUMERO = TO_CHAR(:OLD.OBSERVACION) AND
               TRN_TIPO = :OLD.DOCUMENTO AND
               TRN_NUMERO = :OLD.NUMERO AND
               DSG_TIPO =  :OLD.CRG_TIPO AND
               DSG_CODIGO = :OLD.CRG_CODIGO;
      END IF;
   EXCEPTION
   WHEN OTHERS THEN
      NULL;
   END;
   ELSE
      RAISE_APPLICATION_ERROR(-20214,'Usuario no autorizado para Anular Cargo.');
   END IF;
END;
/
SHOW ERROR









