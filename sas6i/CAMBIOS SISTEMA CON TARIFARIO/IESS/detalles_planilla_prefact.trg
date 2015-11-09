-- \\Svr\Z\sas\guiones\CAMBIOS SISTEMA CON TARIFARIO\ICSC\detalles_planilla_prefact.trg
--
-- Generated for Oracle 10g on Wed Nov 02  11:34:15 2011 by Server Generator 6.5.96.5.6
 



PROMPT Creating Trigger 'PLABRRCNT'
CREATE OR REPLACE TRIGGER PLABRRCNT
 BEFORE DELETE
 ON DETALLES_PLANILLA_PREFACT
 FOR EACH ROW
-- trigger que anula una cuenta en el paciente cuando se crea el detalle de planilla, y a su vez inserta
-- una copia de esta cuenta en el paciente asociado a la promocion que tiene la planilla y el paciente
begin
declare
    codigo_PRM_iess varchar2(10):= null;   -- Código de la promoción utilizada para el IESS
BEGIN                                                                                                 
BEGIN
   SELECT PRMEMP.VALOR INTO CODIGO_PRM_IESS
   FROM PARAMETROS_EMPRESAS PRMEMP
   WHERE (PRMEMP.PRMAPL_NOMBRE LIKE '%CODIGO_PROMOCION_IESS%') and
         (PRMEMP.EMP_CODIGO='CSI');
EXCEPTION
WHEN OTHERS THEN
   CODIGO_PRM_IESS := 'NULL';
END;
QMS$ERRORS.Show_debug_info('El código de la promoción en variable global '||CODIGO_PRM_IESS);
QMS$ERRORS.Show_debug_info('El código de la promoción que se inserta es  '||:OLD.PLA_PROMOCION);
IF CODIGO_PRM_IESS =  :OLD.PLA_PROMOCION THEN    
update cuentas 
set  pcn_numero_hc = PCN_NUMERO_HC_MIGRADO,
     OBSERVACION = OBSERVACION || 'Eliminación cuenta planilla: '||TO_CHAR(PLA_NUMERO_PLANILLA)
WHERE
    :OLD.CNTS_DOCUMENTO = DOCUMENTO AND
    :OLD.CNTS_NUMERO = NUMERO AND        
    :OLD.CNTS_DETALLE = DETALLE AND
    :OLD.PCN_NUMERO_HC = PCN_NUMERO_HC; 
    :OLD.PLA_NUMERO_PLANILLA = PLA_NUMERO_PLANILLA;                
 IF SQL%ROWCOUNT <> 1 THEN 
	 QMS$ERROS.SHOW_MESSAGE('Error al actualizar Historia original . Comunique inmediatamente con Softcase');
 END IF;
END IF; 
EXCEPTION
   WHEN OTHERS THEN
      QMS$ERROS.SHOW_MESSAGE('No se pudo eliminar la cuenta de la planilla'||SQLERRM);
END;   
END;
/
SHOW ERROR


PROMPT Creating Trigger 'PLACPRCTNS'
CREATE OR REPLACE TRIGGER PLACPRCTNS
 AFTER INSERT
 ON DETALLES_PLANILLA_PREFACT
 FOR EACH ROW
-- trigger que anula una cuenta en el paciente cuando se crea el detalle de planilla, y a su vez inserta
-- una copia de esta cuenta en el paciente asociado a la promocion que tiene la planilla
begin
declare
    historia_promocion number := null; -- hc. de la entidad a la que se va a planillar
    --que_entidad varchar2(2);
    --entidad_de_planilla varchar2(3);
    codigo_PRM_iess varchar2(10):= null;   -- Código de la promoción utilizada para el IESS
    planilla varchar2(100):= null;
begin
--   select entidad into entidad_de_planilla from planilla where numero_planilla = :new.pla_numero_planilla;
--   select rv_high_value into que_entidad from cg_ref_codes where
--   rv_domain = 'ENTIDAD_PLANILLA' and rv_low_value = entidad_de_planilla;
/*
   que_promocion :=GNRL.DEVOLVER_ULTIMA_PROMOCION(:new.pcn_numero_hc);


   if (que_promocion <> que_entidad) then
      	RAISE_APPLICATION_ERROR(-20100,'La promoción actual del paciente es diferente a la Entidad de la Planilla');
   end if;
*/
BEGIN
   SELECT PRMEMP.VALOR INTO CODIGO_PRM_IESS
   FROM PARAMETROS_EMPRESAS PRMEMP
   WHERE (PRMEMP.PRMAPL_NOMBRE LIKE '%CODIGO_PROMOCION_IESS%') and
         (PRMEMP.EMP_CODIGO='CSI');
EXCEPTION
WHEN OTHERS THEN
   CODIGO_PRM_IESS := 'NULL';
END;
QMS$ERRORS.Show_debug_info('El código de la promoción en variable global '||CODIGO_PRM_IESS);
QMS$ERRORS.Show_debug_info('El código de la promoción que se inserta es  '||:NEW.PLA_PROMOCION);
IF CODIGO_PRM_IESS =  :NEW.PLA_PROMOCION THEN
BEGIN
   QMS$ERRORS.Show_debug_info('El registro es el detalle de una planilla para el IESS '||CODIGO_PRM_IESS);
   BEGIN
      select prm_pcn_numero_hc into historia_promocion
      from promociones
      where codigo = :NEW.PLA_PROMOCION;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      QMS$ERRORS.SHOW_MESSAGE('La promocion '||:NEW.PLA_PROMOCION||' no tiene asociada una HC.');
   END;
--        IF SQL%ROWCOUNT <> 1 or historia_promocion is null THEN
--        RAISE_APPLICATION_ERROR(-20100,'Fallo al recuperar Historia Asociada');
--        END IF;
   QMS$ERRORS.Show_debug_info('El historia de la promcion es   '||historia_promocion);
   if historia_promocion is not null then
   QMS$ERRORS.Show_debug_info('Va a actualizar la cuenta ');
   /*begin
    select c.documento||' '||c.numero||' '||c.detalle||' '||c.pla_numero_planilla into planilla
    from cuentas c
    WHERE :NEW.CNTS_DOCUMENTO = DOCUMENTO AND
            :NEW.CNTS_NUMERO = NUMERO AND
            :NEW.CNTS_DETALLE = DETALLE AND
            :NEW.PCN_NUMERO_HC = PCN_NUMERO_HC AND
            :NEW.PLA_NUMERO_PLANILLA = PLA_NUMERO_PLANILLA;
   QMS$ERRORS.Show_debug_info('La planilla es '||planilla);                       
   exception
   when no_data_found then
       QMS$ERRORS.Show_debug_info('La cuenta aún no ha sido actualizada con la planilla ');               
   end;*/   
   begin
      update cuentas
      set PCN_NUMERO_HC_MIGRADO = pcn_numero_hc,
          pcn_numero_hc = historia_promocion ,
          OBSERVACION = OBSERVACION || '  MIGRADA POR PLANILLA : '||TO_CHAR(PLA_NUMERO_PLANILLA)
      WHERE :NEW.CNTS_DOCUMENTO = DOCUMENTO AND
            :NEW.CNTS_NUMERO = NUMERO AND
            :NEW.CNTS_DETALLE = DETALLE AND
            :NEW.PCN_NUMERO_HC = PCN_NUMERO_HC AND
            :NEW.PLA_NUMERO_PLANILLA = PLA_NUMERO_PLANILLA;
      QMS$ERRORS.Show_debug_info('Se actualizó la cuenta ');      
   exception
   when others then
      QMS$ERRORS.SHOW_MESSAGE('Error al actualizar Historia para cuenta migrada. Comuniquese con Softcase inmediatamente');
   END;
   END IF;
-- IF SQL%ROWCOUNT <> 1 THEN
--     QMS$ERRORS.SHOW_MESSAGE('No se pudo actualizar la cuenta ');
-- END IF;
 EXCEPTION
 WHEN OTHERS THEN
     QMS$ERRORS.SHOW_MESSAGE('No se pudo pasar la planilla a la entidad correspondiente');
END;
ELSE
   QMS$ERRORS.Show_debug_info('El registro NO es el detalle de una planilla para el IESS '||CODIGO_PRM_IESS);
END IF;
end;
END;
/
SHOW ERROR


ALTER TRIGGER PLACPRCTNS DISABLE
/

PROMPT Creating Trigger 'DTLPLNPRFLLNJN'
CREATE OR REPLACE TRIGGER DTLPLNPRFLLNJN
 AFTER DELETE
 ON DETALLES_PLANILLA_PREFACT
 FOR EACH ROW
DECLARE

VOPR VARCHAR2(3);
BEGIN
  INSERT INTO DETALLES_PLANILLA_PREFACT_JN
    (JN_OPERATION,JN_ORACLE_USER,JN_DATETIME,JN_NOTES,JN_APPLN,JN_SESSION,
     CNTS_DOCUMENTO, CNTS_DETALLE, CNTS_NUMERO, PCN_NUMERO_HC,PLA_NUMERO_PLANILLA,PLA_PROMOCION)
     VALUES('DEL',USER,SYSDATE,NULL,NULL,NULL,
     :OLD.CNTS_DOCUMENTO, :OLD.CNTS_DETALLE, :OLD.CNTS_NUMERO, :OLD.PCN_NUMERO_HC
     , :OLD.PLA_NUMERO_PLANILLA, :OLD.PLA_PROMOCION);
END;
/
SHOW ERROR













