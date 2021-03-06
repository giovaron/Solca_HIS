-- C:\tmp\evolucion_clinica1.trg
--
-- Generated for Oracle 9i on Thu Jun 09  10:29:16 2011 by Server Generator 6.5.96.5.6


PROMPT Altering Table 'HOJAS_DE_EVOLUCION' 
ALTER TABLE HOJAS_DE_EVOLUCION 
 ADD (COMPLEJIDAD VARCHAR2(3) 
 )
/

PROMPT Altering Table 'HOJAS_DE_EVOLUCION_JN' 
ALTER TABLE HOJAS_DE_EVOLUCION_JN 
 ADD (COMPLEJIDAD VARCHAR2(3)
 )
/


PROMPT Creating Trigger 'HJSEVLLLNJN'
CREATE OR REPLACE TRIGGER HJSEVLLLNJN
 AFTER DELETE OR UPDATE
 ON HOJAS_DE_EVOLUCION
 FOR EACH ROW
DECLARE

VOPR VARCHAR2(240);
BEGIN
  IF Updating THEN
    vOpr:='UPD';
  ELSE
    vOpr:='DEL';
  END IF;
  INSERT INTO HOJAS_DE_EVOLUCION_JN
  (JN_OPERATION,JN_ORACLE_USER,JN_DATETIME,JN_NOTES,JN_APPLN,JN_SESSION
     ,NUMERO,PRS_CODIGO,PCN_NUMERO_HC,FECHA,SERVICIO_CEX           
     ,MOTIVO,DESCRIPCION,RESULTADO_EXAMEN_FISICO,DPR_CODIGO             
     ,DPR_ARA_CODIGO,TIPO_EVOLUCION,INTCNS_NUMERO,POOL,DGNPCN_ID,COMPLEJIDAD)
   VALUES(vOpr,USER,SYSDATE,NULL,NULL,NULL 
     ,:OLD.NUMERO,:OLD.PRS_CODIGO,:OLD.PCN_NUMERO_HC,:OLD.FECHA,:OLD.SERVICIO_CEX           
     ,:OLD.MOTIVO,:OLD.DESCRIPCION,:OLD.RESULTADO_EXAMEN_FISICO,:OLD.DPR_CODIGO             
     ,:OLD.DPR_ARA_CODIGO,:OLD.TIPO_EVOLUCION,:OLD.INTCNS_NUMERO,:OLD.POOL,:OLD.DGNPCN_ID,:OLD.COMPLEJIDAD);
END;
/
SHOW ERROR













