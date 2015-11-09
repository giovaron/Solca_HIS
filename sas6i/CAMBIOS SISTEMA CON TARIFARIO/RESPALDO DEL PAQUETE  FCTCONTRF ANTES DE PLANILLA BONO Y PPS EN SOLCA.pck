CREATE OR REPLACE PACKAGE "FCTCONTRF" IS
-- Sub-Program Unit Declarations
------------------------------ FUNCIONES AÑADIDAS POR RINA PARA RECATEGORIZAR CUENTAS  ---------------
FUNCTION DEVUELVE_PORCENTAJE_PRM
 (VTIPOCRG IN VARCHAR2
 ,VCODCRG IN VARCHAR2
 ,VPCN_NUMERO_HC IN NUMBER
 ,vPrmPcn VARCHAR2
 )
 RETURN NUMBER;
 
FUNCTION DEVUELVE_PORCENTAJE_PRM_MSP
-- Recupera el porcentaje promoción de acuerdo a la recategorización
-- se revisa la información en convenios equivalencias
 (VTIPOCRG IN VARCHAR2
 ,VCODCRG IN VARCHAR2
 ,VPCN_NUMERO_HC IN NUMBER
 ,vPrmPcn VARCHAR2 
 ,FECHA IN DATE
 )
 RETURN NUMBER; 
 
PROCEDURE RECATEGORIZAR_CUENTA_POR_HC
(VPCN_NUMERO_HC IN NUMBER);

 
PROCEDURE RECATEGORIZAR_CUENTA
(VPCN_NUMERO_HC IN NUMBER,FECHA_INICIAL IN DATE, FECHA_FINAL IN DATE,PROMO IN VARCHAR);

PROCEDURE RECATEGORIZAR_CUENTA_MSP
-- Recategoriza la cuenta de un paciente teniendo como parámetro un periodo de recategorzación.
-- en base a convenios equivalencias más no al valor fijado para generar el archivo plano
(VPCN_NUMERO_HC IN NUMBER,FECHA_INICIAL IN DATE, FECHA_FINAL IN DATE,PROMO IN VARCHAR);

PROCEDURE RECATEGORIZAR_CUENTA_PRD
(FECHA_INICIAL IN DATE,FECHA_FINAL IN DATE);

PROCEDURE RECATEGORIZAR_PCN_MSP
(FECHA_INICIAL IN DATE,FECHA_FINAL IN DATE,VPCN_NUMERO_HC IN NUMBER);


------------------------------ FUNCIONES AÑADIDAS POR RINA PARA RECATEGORIZAR CUENTAS  ---------------
FUNCTION DEVUELVE_CONVENIO
 (NNUMEROHC NUMBER
 ,DFECHA DATE
  ,PRM_CODIGO IN OUT VARCHAR
 )
 RETURN VARCHAR2;
 
 
PROCEDURE CARGAR_CUENTA_TRF 
(PCN_NUMERO_HC IN NUMBER,
P_DPR_ARA_CODIGO IN CHAR,
P_DPR_CODIGO IN CHAR,
P_EMP_CODIGO IN CHAR,
P_DOCUMENTO IN CHAR,
P_NUMERO IN CHAR,
P_DETALLE IN CHAR);
  
PROCEDURE CARGAR_HONORARIO_TRF
 (P_NUMERO IN CUENTAS.NUMERO%TYPE
 ,P_BENEFICIARIO IN PERSONAL.CODIGO%TYPE
 ,P_ID IN CUENTAS.DETALLE%TYPE
 ,P_CANTIDAD IN CUENTAS.CANTIDAD%TYPE
 ,P_DOCUMENTO IN CUENTAS.DOCUMENTO%TYPE
 ,P_PCN_NUMERO_HC IN CUENTAS.PCN_NUMERO_HC%TYPE
 ,P_INS_OR_DEL IN VARCHAR2
 ,P_FECHA IN DATE := NULL
 ,P_TIPO_REMUNERACION IN VARCHAR2 := 'HNR'
 ,P_EVLCLN IN HOJAS_DE_EVOLUCION.NUMERO%TYPE
 ,P_PRCHSP_CODIGO IN PROCEDIMIENTOS_HOSPITALARIOS.CODIGO%TYPE
 ,P_LATERALIDAD IN PROCEDIMIENTOS_REALIZADOS.LATERALIDAD%TYPE
 ,P_CASO IN NUMBER := 4
 ,P_CONDICION IN NUMBER  := 1
 ,P_DIVISOR IN NUMBER := 1
 ,P_POOL IN NUMBER := 0
 ,P_DURACION IN NUMBER:=0
 ,P_AREA IN VARCHAR2
 ,P_DEPARTAMENTO IN VARCHAR2
 ,P_EMP_CODIGO IN CHAR
 ); 
 /* Genera los honorarios médicos de acuerdo a los proceidmientos realizad */
PROCEDURE CARGAR_HONORARIO_POR_PROC_TRF
 (P_NUMPARTE IN NUMBER
 ,P_DOCUMENTO IN CUENTAS.DOCUMENTO%TYPE
 ,P_PCN_NUMERO_HC IN CUENTAS.PCN_NUMERO_HC%TYPE
 ,P_BENEFICIARIO IN PERSONAL.CODIGO%TYPE := NULL 
 ,P_FECHA IN DATE := NULL
 ,P_TIPO_REMUNERACION IN VARCHAR2 := 'HNR'
 ,P_EVLCLN IN HOJAS_DE_EVOLUCION.NUMERO%TYPE
 ,P_INS_OR_DEL IN VARCHAR2
 ,P_POOL IN NUMBER := 0
 ,P_DURACION IN NUMBER :=0 
 ,P_AREA IN VARCHAR2
 ,P_DEPARTAMENTO IN VARCHAR2 
 ,P_EMP_CODIGO IN CHAR
 );
 PROCEDURE CARGAR_DERECHO_QUIROFANO
 ( VTARIFARIO IN VARCHAR2
  ,DFECHA DATE
  ,vOpr IN VARCHAR2  
  ,nPrtOpr IN NUMBER 
  ,nHC IN NUMBER
  ,vlateralidad IN VARCHAR2
  ,nduracion IN NUMBER
  ,varea IN VARCHAR2
  ,vdepartamento IN VARCHAR2);
END FCTCONTRF;
/
CREATE OR REPLACE PACKAGE BODY "FCTCONTRF" IS
------------------------------ FUNCIONES AÑADIDAS POR RINA PARA RECATEGORIZAR CUENTAS  ---------------
FUNCTION DEVUELVE_PORCENTAJE_PRM
 (VTIPOCRG IN VARCHAR2
 ,VCODCRG IN VARCHAR2
 ,VPCN_NUMERO_HC IN NUMBER
 ,vPrmPcn VARCHAR2 
 )
 RETURN NUMBER IS
  CURSOR cCrg IS
    SELECT DPR_ARA_CODIGO,DPR_CODIGO,COSTO
    FROM CARGOS
    WHERE TIPO=vTipoCrg AND CODIGO=vCodCrg;
  nValor NUMBER:=0;
  nPorcentaje_promocion NUMBER;
  nValor_fijo NUMBER;
  nPrecio_de_venta NUMBER;
  vArea CARGOS.DPR_ARA_CODIGO%TYPE;
  vDept CARGOS.DPR_CODIGO%TYPE;
-- cursor que devuelve la ultima promoción de un paciente
-- cursor que devuelve el porcentaje promoción del departamento según la promoción
  CURSOR cDetPrm (vPromocion PROMOCIONES.CODIGO%TYPE,
                  vArea AREAS.CODIGO%TYPE,
                  vDept DEPARTAMENTOS.CODIGO%TYPE) IS
    SELECT PORCENTAJE_PROMOCION
    FROM DETALLES_PROMOCIONES
    WHERE prm_codigo=vPromocion
    AND DPR_ARA_CODIGO=vArea
    AND DPR_CODIGO=vDept;
-- cursor que devuelve el porcentaje promoción del cargo según la promoción
  CURSOR cPrmExc (vPromocion PROMOCIONES.CODIGO%TYPE,
                  vArea AREAS.CODIGO%TYPE,
                  vDept DEPARTAMENTOS.CODIGO%TYPE,
                  vCargo CARGOS.CODIGO%TYPE) IS
    SELECT PORCENTAJE_PROMOCION,VALOR_FIJADO
    FROM PROMOCIONES_EXCEPCIONES
    WHERE PRM_CODIGO=vPromocion
    AND DPR_ARA_CODIGO=vArea
    AND DPR_CODIGO=vDept
    AND CRG_TIPO=vTipoCrg
    AND CRG_CODIGO=vCargo;
BEGIN
  QMS$ERRORS.SHOW_DEBUG_INFO('Devuelve_Promocion');
  QMS$ERRORS.SHOW_DEBUG_INFO('Codigo del cargo '||vTipoCrg||vCodCrg);
  QMS$ERRORS.SHOW_DEBUG_INFO('Codigo Promocion '||vPrmPcn);
  nValor:=1;
  IF  VPCN_NUMERO_HC IS NULL THEN
    RETURN 0;
  END IF;
  IF vTipoCrg IS NOT NULL THEN
  QMS$ERRORS.SHOW_DEBUG_INFO('va a revisar la promocion');
    nValor:=1;
    nPORCENTAJE_PROMOCION := 1;
    IF vTipoCrg IN ('P','S') THEN
-- si son procedimientos o servicios vemos de que area son
      OPEN cCrg;
      FETCH cCrg INTO vArea,vDept,nPrecio_de_venta;
      IF cCRg%NOTFOUND THEN
-- aqui nunca deberia entrar
        CLOSE cCrg;
        qms$errors.show_message('ADM-00011','Cargo no existe');
      END IF;
      CLOSE cCrg;
    ELSE
-- si son medicamentos o insumos siempre es farmacia
      vArea:='A';
      vDept:='F';
    END IF;
    BEGIN
      OPEN CDetPrm (vPrmPcn,vArea,vDept);
      FETCH CDetPrm INTO nPORCENTAJE_PROMOCION;
    -- Si el area y departamento tienen una promocion, vemos si es una excepcion
      OPEN CPrmExc (vPrmPcn,vArea,vDept,vCodCrg);
      FETCH CPrmExc INTO nPorcentaje_Promocion,nValor_Fijo;
      IF nvl(nValor_Fijo,0) > 0 THEN
        nPorcentaje_Promocion := nValor_Fijo/nPRECIO_DE_VENTA;
      END IF;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
        NULL; -- El area y el departamento ni la excepcion no tienen ninguna promocion
    END;
    QMS$ERRORS.SHOW_DEBUG_INFO('Porcentaje Promocion '||nPORCENTAJE_PROMOCION );
    nValor:=nPORCENTAJE_PROMOCION;
  ELSE
    nValor:=1;
  END IF;
  QMS$ERRORS.SHOW_DEBUG_INFO('Valor de la promocion es '||nValor);
  RETURN NVL(nValor,1);
END DEVUELVE_PORCENTAJE_PRM;

FUNCTION DEVUELVE_PORCENTAJE_PRM_MSP
-- Recupera el porcentaje promoción de acuerdo a la recategorización
-- se revisa la información en convenios equivalencias
 (VTIPOCRG IN VARCHAR2
 ,VCODCRG IN VARCHAR2
 ,VPCN_NUMERO_HC IN NUMBER
 ,vPrmPcn VARCHAR2 
 ,FECHA IN DATE
 )
 RETURN NUMBER IS
  CURSOR cCrg IS
    SELECT DPR_ARA_CODIGO,DPR_CODIGO,COSTO
    FROM CARGOS
    WHERE TIPO=vTipoCrg AND CODIGO=vCodCrg;
  nValor NUMBER:=0;
  vpromocion VARCHAR2(20):= NULL;
  VENTIDAD VARCHAR2(20):= NULL;
  vAnestesia VARCHAR2(1);
  nPorcentaje_promocion NUMBER;
  nValor_fijo NUMBER;
  nPrecio_de_venta NUMBER;
  vArea CARGOS.DPR_ARA_CODIGO%TYPE;
  vDept CARGOS.DPR_CODIGO%TYPE;
  vcodigo_iess CARGOS.Codigo_Iess%TYPE;
  vtrf_iess VARCHAR2(20):= NULL;
  VPRM_IESS VARCHAR2(20):= NULL;
  vuvr number := null;
  vprecio number := null;
-- cursor que devuelve la ultima promoción de un paciente
-- cursor que devuelve el porcentaje promoción del departamento según la promoción
  CURSOR cDetPrm (vPromocion PROMOCIONES.CODIGO%TYPE,
                  vArea AREAS.CODIGO%TYPE,
                  vDept DEPARTAMENTOS.CODIGO%TYPE) IS
    SELECT PORCENTAJE_PROMOCION
    FROM DETALLES_PROMOCIONES
    WHERE prm_codigo=vPromocion
    AND DPR_ARA_CODIGO=vArea
    AND DPR_CODIGO=vDept;
-- cursor que devuelve el porcentaje promoción del cargo según la promoción
  CURSOR cPrmExc (vPromocion PROMOCIONES.CODIGO%TYPE,
                  vArea AREAS.CODIGO%TYPE,
                  vDept DEPARTAMENTOS.CODIGO%TYPE,
                  vCargo CARGOS.CODIGO%TYPE) IS
    SELECT PORCENTAJE_PROMOCION 
    FROM PROMOCIONES_EXCEPCIONES
    WHERE PRM_CODIGO=vPromocion
    AND DPR_ARA_CODIGO=vArea
    AND DPR_CODIGO=vDept
    AND CRG_TIPO=vTipoCrg
    AND CRG_CODIGO=vCargo;
BEGIN
  QMS$ERRORS.SHOW_DEBUG_INFO('Devuelve_Promocion');
  QMS$ERRORS.SHOW_DEBUG_INFO('Codigo del cargo '||vTipoCrg||vCodCrg);
  QMS$ERRORS.SHOW_DEBUG_INFO('Codigo Promocion '||vPrmPcn);
  nValor:=1;
  DBMS_OUTPUT.put_line('Entra al proceso de recuperar promoción');  
  BEGIN
     SELECT CG.RV_LOW_VALUE INTO VENTIDAD  
     FROM CG_REF_CODES CG
     WHERE CG.RV_HIGH_VALUE = vPrmPcn;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN 
      VENTIDAD:= NULL;  
  END;
  BEGIN       
   vtrf_iess:= DEVUELVE_CONVENIO(VPCN_NUMERO_HC,FECHA,vpromocion);
  EXCEPTION
  WHEN OTHERS THEN  
    qms$errors.show_message('ADM-00011','No se encontrado un tarifario para la hc. '||to_char(VPCN_NUMERO_HC));     
    DBMS_OUTPUT.put_line('No hay Tarifario del iess');
  END; 
  BEGIN
     VPRM_IESS := vPrmPcn;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN  
    qms$errors.show_message('ADM-00011','No se ha creado el parámetro CODIGO_PROMOCION_IESS para la empresa.');     
    DBMS_OUTPUT.put_line('No hay promocion del iess');    
  END;
  DBMS_OUTPUT.put_line('Tarifario '||VTRF_IESS||' Promción Iess '||VPRM_IESS);
  IF  VPCN_NUMERO_HC IS NULL THEN
    RETURN 0;
  END IF;
  IF vTipoCrg IS NOT NULL THEN
  QMS$ERRORS.SHOW_DEBUG_INFO('va a revisar la promocion');
    nValor:=1;
    nPORCENTAJE_PROMOCION := 1;
    IF vTipoCrg IN ('P','S') THEN
-- si son procedimientos o servicios vemos de que area son
      OPEN cCrg;
      FETCH cCrg INTO vArea,vDept,nPrecio_de_venta;
      IF cCRg%NOTFOUND THEN
-- aqui nunca deberia entrar
        CLOSE cCrg;
        qms$errors.show_message('ADM-00011','Cargo no existe');
      END IF;
      CLOSE cCrg;
    ELSE
-- si son medicamentos o insumos siempre es farmacia
      vArea:='A';
      vDept:='F';
    END IF;
    BEGIN
      OPEN CDetPrm (vPrmPcn,vArea,vDept);
      FETCH CDetPrm INTO nPORCENTAJE_PROMOCION;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
        NULL; -- El area y el departamento ni la excepcion no tienen ninguna promocion
    END;
    IF VCODCRG = '0208157' THEN
       DBMS_OUTPUT.put_line('Antes de buscar el ítem en convenios equivalencias '||VCODCRG||' es '||nPORCENTAJE_PROMOCION);
       DBMS_OUTPUT.put_line('Es un cargo de anestesia'||vanestesia);       
    END IF;   
    -- Si el cargo está en convenios equivalencias, devuelve el porcentaje promcción
    -- de acuerdo al valor resultante del UVR * PRECIO.
    IF vPrmPcn = VPRM_IESS then
       IF VCODCRG = 'X0007' THEN
         DBMS_OUTPUT.put_line('Busca el ítem en convenios equivalencias '||VCODCRG||' es '||nPORCENTAJE_PROMOCION);
       END IF;   
       vuvr:= null;
       vprecio := null;
       BEGIN       
          SELECT  T.UVR,T.PRC INTO vuvr,vprecio
          FROM CONVENIOS_EQUIVALENCIAS C,CONVENIOS_TARIFARIOS T
          WHERE T.TIPO = C.TIPO AND
                T.CONVENIO = C.CNVTRF_CONVENIO AND
                T.CODIGO = C.CNVTRF_CODIGO AND
                C.CRG_TIPO = VTIPOCRG AND
                C.CRG_CODIGO = VCODCRG AND 
                T.CONVENIO = vtrf_iess AND
                C.PRIORIDAD_CARGO = 'F';-- AND
--                T.CODIGO_ITEM = vcodigo_iess;    
          if (NVL(vuvr,0)*NVL(vprecio,0)) > 0 then
             nValor_fijo := (NVL(vuvr,0)*NVL(vprecio,0));
          elsif vuvr is null or vprecio is null then
             qms$errors.show_message('ADM-00011','No se puede recategorizar, el cargo '||VCODCRG||' no tiene un valor en Convenios Equivalencias');               
          elsif  (NVL(vuvr,0)*NVL(vprecio,0))  = 0 then
               nValor_fijo :=  null;       
          end if; 
       EXCEPTION
       WHEN NO_DATA_FOUND  THEN
         NULL;         
       END;
     END IF;
       IF nValor_Fijo is not null and  nValor_Fijo > 0 THEN
           nPorcentaje_Promocion := nValor_Fijo/nPRECIO_DE_VENTA;
       END IF;       
       IF VCODCRG = 'X0007' THEN
         DBMS_OUTPUT.put_line('Luego de buscar el ítem en convenios equivalencias '||VCODCRG||' es '||nPORCENTAJE_PROMOCION);
         DBMS_OUTPUT.put_line('El valor del ítem  es  '||nvl(nValor_Fijo,0));                  
       END IF;          
       BEGIN
           -- Si el area y departamento tienen una promocion, vemos si es una excepcion
         OPEN CPrmExc (vPrmPcn,vArea,vDept,vCodCrg);
         FETCH CPrmExc INTO nPorcentaje_Promocion;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
          NULL; -- El area y el departamento ni la excepcion no tienen ninguna promocion
       END;
    QMS$ERRORS.SHOW_DEBUG_INFO('Porcentaje Promocion '||nPORCENTAJE_PROMOCION );
    nValor:=nPORCENTAJE_PROMOCION;
  ELSE
    nValor:=1;
  END IF;
  QMS$ERRORS.SHOW_DEBUG_INFO('Valor de la promocion es '||nValor);
--  DBMS_OUTPUT.put_line('EL Porcentaje promocion para el item '||VCODCRG||' es '||nValor);
  RETURN NVL(nValor,1);
EXCEPTION
WHEN OTHERS THEN
   DBMS_OUTPUT.put_line('Se generó un error '||sqlerrm);
   RETURN 1;   
END DEVUELVE_PORCENTAJE_PRM_MSP;


PROCEDURE RECATEGORIZAR_CUENTA_POR_HC
-- Proceso para recategorizar la cuenta de un paciente basándose en la última promoción.
-- es el mismo proceso que realiza el módulo de Recategorización de cuentas pendientes.
(VPCN_NUMERO_HC IN NUMBER) IS
nULTRGS NUMBER;
nANT NUMBER;
nCONT NUMBER;
nprcprm NUMBER;
i NUMBER;
bSeguir BOOLEAN;
PROMO VARCHAR2(2):= NULL;
PORCENTAJE NUMBER:= NULL;
descuento number;
CURSOR CNTS (PACIENTE NUMBER ) IS
SELECT * FROM CUENTAS CNT
where  CNT.PCN_NUMERO_HC = PACIENTE AND ((((CNT.ESTADO='PND') OR 
                                            (CNT.ESTADO='PRE')) AND 
                                            (CNT.CANTIDAD>0)));
BEGIN
QMS$ERRORS.SHOW_DEBUG_INFO('Iniciando Recategorizar_Pacientes ');

   --PROMO:=FCTCONTRF.DEVOLVER_COD_ULTIMA_PROMOCION(VPCN_NUMERO_HC);
   PROMO := '01';
   FOR RCNTS IN CNTS(VPCN_NUMERO_HC) LOOP
   BEGIN
      PORCENTAJE:= FCTCONTRF.Devuelve_porcentaje_prm(RCNTS.CRG_TIPO,RCNTS.CRG_CODIGO,VPCN_NUMERO_HC,promo);
      IF porcentaje > 1 THEN
         descuento := 0;
      ELSE
          descuento := (RCNTS.CANTIDAD * RCNTS.VALOR)-(RCNTS.CANTIDAD * RCNTS.VALOR * PORCENTAJE);
      END IF;
      UPDATE CUENTAS C             
      SET C.PORCENTAJE_PROMOCION = PORCENTAJE,
          C.DESCUENTO_OTORGADO = DESCUENTO,
          C.PRM_CODIGO = promo
      WHERE 
       C.PCN_NUMERO_HC= VPCN_NUMERO_HC AND
       C.DOCUMENTO = RCNTS.DOCUMENTO AND
       C.NUMERO = RCNTS.NUMERO AND
       C.DETALLE = RCNTS.DETALLE AND
       C.CRG_TIPO =   RCNTS.CRG_TIPO AND
       C.CRG_CODIGO = RCNTS.CRG_CODIGO AND
       C.CANTIDAD = RCNTS.CANTIDAD AND
       C.ESTADO = RCNTS.ESTADO;
QMS$ERRORS.SHOW_DEBUG_INFO('Porcentaje Promocion despues '||TO_CHAR(promo));
QMS$ERRORS.SHOW_DEBUG_INFO('Porcentaje Promocion despues '||TO_CHAR(descuento));
          i := i +1;
    EXCEPTION
    WHEN OTHERS THEN
       NULL;      
    END;         
    END LOOP ;
QMS$ERRORS.SHOW_DEBUG_INFO('NO SE PROCESAN LOS MEDICAMENTOS, NO ES NECESARIO');
   IF i = 0 THEN
    qms$errors.show_message('FCT-00100','No se Recategorizar_Pacientes a ningún item.  Esta seguro de haber chequeado como seleccionados las cuentas?','Revise que esten seleccionadas las cuentas.');
   END IF;
END RECATEGORIZAR_CUENTA_POR_HC;

PROCEDURE RECATEGORIZAR_CUENTA
-- Recategoriza la cuenta de un paciente teniendo como parámetro un periodo de recategorzación.
-- en base al valor fijado 
(VPCN_NUMERO_HC IN NUMBER,FECHA_INICIAL IN DATE, FECHA_FINAL IN DATE,PROMO IN VARCHAR) IS
nULTRGS NUMBER;
nANT NUMBER;
nCONT NUMBER;
nprcprm NUMBER;
i NUMBER;
bSeguir BOOLEAN;
PORCENTAJE NUMBER:= NULL;
descuento number;
CURSOR CNTS (PACIENTE NUMBER,FECHA_INICIAL DATE, FECHA_FINAL DATE) IS
SELECT * FROM CUENTAS CNT
where  CNT.PCN_NUMERO_HC = PACIENTE AND ((((CNT.ESTADO='PND') OR 
                                            (CNT.ESTADO='PRE')) AND 
                                            (CNT.CANTIDAD>0))) AND
       CNT.FECHA BETWEEN FECHA_INICIAL AND FECHA_FINAL;
BEGIN
QMS$ERRORS.SHOW_DEBUG_INFO('Iniciando Recategorizar_Pacientes_por fecha ');

   FOR RCNTS IN CNTS(VPCN_NUMERO_HC,FECHA_INICIAL,FECHA_FINAL) LOOP
   BEGIN
      PORCENTAJE:= FCTCONTRF.Devuelve_porcentaje_prm(RCNTS.CRG_TIPO,RCNTS.CRG_CODIGO,VPCN_NUMERO_HC,promo);
      IF porcentaje > 1 THEN
         descuento := 0;
      ELSE
         descuento := (RCNTS.CANTIDAD * RCNTS.VALOR)-(RCNTS.CANTIDAD * RCNTS.VALOR * PORCENTAJE);
      END IF;
      UPDATE CUENTAS C             
      SET C.PORCENTAJE_PROMOCION = PORCENTAJE,
          C.DESCUENTO_OTORGADO = DESCUENTO,
          C.PRM_CODIGO = PROMO          
      WHERE 
       C.PCN_NUMERO_HC= VPCN_NUMERO_HC AND
       C.DOCUMENTO = RCNTS.DOCUMENTO AND
       C.NUMERO = RCNTS.NUMERO AND
       C.DETALLE = RCNTS.DETALLE AND
       C.CRG_TIPO =   RCNTS.CRG_TIPO AND
       C.CRG_CODIGO = RCNTS.CRG_CODIGO AND
       C.CANTIDAD = RCNTS.CANTIDAD AND
       C.ESTADO = RCNTS.ESTADO;
QMS$ERRORS.SHOW_DEBUG_INFO('Porcentaje Promocion despues '||TO_CHAR(promo));
QMS$ERRORS.SHOW_DEBUG_INFO('Porcentaje Promocion despues '||TO_CHAR(descuento));
          i := i +1;
    EXCEPTION
    WHEN OTHERS THEN
       NULL;      
    END;         
    END LOOP ;
QMS$ERRORS.SHOW_DEBUG_INFO('NO SE PROCESAN LOS MEDICAMENTOS, NO ES NECESARIO');
   IF i = 0 THEN
    qms$errors.show_message('FCT-00100','No se Recategorizar_Pacientes a ningún item.  Esta seguro de haber chequeado como seleccionados las cuentas?','Revise que esten seleccionadas las cuentas.');
   END IF;
END RECATEGORIZAR_CUENTA;

PROCEDURE RECATEGORIZAR_CUENTA_MSP
-- Recategoriza la cuenta de un paciente teniendo como parámetro un periodo de recategorzación.
-- en base a convenios equivalencias más no al valor fijado para planillar cuentas con el tarifario MSP
(VPCN_NUMERO_HC IN NUMBER,FECHA_INICIAL IN DATE, FECHA_FINAL IN DATE,PROMO IN VARCHAR) IS
nULTRGS NUMBER;
nANT NUMBER;
nCONT NUMBER;
nprcprm NUMBER;
i NUMBER;
bSeguir BOOLEAN;
PORCENTAJE NUMBER:= NULL;
descuento number;
CURSOR CNTS (PACIENTE NUMBER,FECHA_INICIAL DATE, FECHA_FINAL DATE) IS
SELECT * FROM CUENTAS CNT
where CNT.PLA_NUMERO_PLANILLA IS NULL AND 
      CNT.PCN_NUMERO_HC = PACIENTE AND ((((CNT.ESTADO='PND') OR 
                                            (CNT.ESTADO='PRE')) AND 
                                            (CNT.CANTIDAD>0))) AND                                            
       CNT.FECHA BETWEEN FECHA_INICIAL AND FECHA_FINAL ;
BEGIN
QMS$ERRORS.SHOW_DEBUG_INFO('Iniciando Recategorizar_Pacientes_por fecha ');
--   DBMS_OUTPUT.put_line('Entra al proceso de recategorización');   
   FOR RCNTS IN CNTS(VPCN_NUMERO_HC,FECHA_INICIAL,FECHA_FINAL) LOOP
   BEGIN
--      DBMS_OUTPUT.put_line('Va a recuperar el porcentaje promocion');   
      PORCENTAJE:= FCTCONTRF.Devuelve_porcentaje_prm_MSP(RCNTS.CRG_TIPO,RCNTS.CRG_CODIGO,VPCN_NUMERO_HC,promo,RCNTS.FECHA);
--      DBMS_OUTPUT.put_line('EL Porcentaje promocion para el item '||RCNTS.CRG_CODIGO||' es '||PORCENTAJE);
      IF porcentaje > 1 THEN
         descuento := 0;
      ELSE
         descuento := (RCNTS.CANTIDAD * RCNTS.VALOR)-(RCNTS.CANTIDAD * RCNTS.VALOR * PORCENTAJE);
      END IF;
QMS$ERRORS.SHOW_DEBUG_INFO('Cargo recategorizado '||RCNTS.DOCUMENTO||TO_CHAR(RCNTS.NUMERO)||TO_CHAR(RCNTS.DETALLE));       
QMS$ERRORS.SHOW_DEBUG_INFO('Porcentaje Promocion '||TO_CHAR(PORCENTAJE));
QMS$ERRORS.SHOW_DEBUG_INFO('Promocion '||TO_CHAR(promo));
      UPDATE CUENTAS C             
      SET C.PORCENTAJE_PROMOCION = PORCENTAJE,
          C.DESCUENTO_OTORGADO = DESCUENTO,
          C.PRM_CODIGO = PROMO,
          C.RECATEGORIZADA = 'V'
      WHERE 
       C.PCN_NUMERO_HC= VPCN_NUMERO_HC AND
       C.DOCUMENTO = RCNTS.DOCUMENTO AND
       C.NUMERO = RCNTS.NUMERO AND
       C.DETALLE = RCNTS.DETALLE AND
       C.CRG_TIPO =   RCNTS.CRG_TIPO AND
       C.CRG_CODIGO = RCNTS.CRG_CODIGO AND
       C.CANTIDAD = RCNTS.CANTIDAD AND
       C.ESTADO = RCNTS.ESTADO;
QMS$ERRORS.SHOW_DEBUG_INFO('Descuento '||TO_CHAR(descuento));             
          i := i +1;          
    EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line('No se recuperó el porcentaje promocion '||sqlerrm);
       qms$errors.show_message('FCT-00100','No se recuperó el porcentaje promocion '||sqlerrm);
    END;         
    END LOOP ;
QMS$ERRORS.SHOW_DEBUG_INFO('NO SE PROCESAN LOS MEDICAMENTOS, NO ES NECESARIO');
   IF i = 0 THEN
    qms$errors.show_message('FCT-00100','No se Recategorizar_Pacientes a ningún item.  Esta seguro de haber chequeado como seleccionados las cuentas?','Revise que esten seleccionadas las cuentas.');
   END IF;
END RECATEGORIZAR_CUENTA_MSP;


PROCEDURE RECATEGORIZAR_CUENTA_PRD
(FECHA_INICIAL IN DATE,FECHA_FINAL IN DATE) IS
-- Este proceso recategoriza las cuentas de todos los pacientes que tengan valores pendientes de facturar
-- dentro del periodo indicado en los parámetros fecha_ini y fecha_fin.
CURSOR PCNREC (FECHA_INI DATE,FECHA_FIN DATE) IS
SELECT C.PCN_NUMERO_HC NUMERO_HC FROM CUENTAS C
WHERE C.FECHA BETWEEN FECHA_INI-0.001 AND FECHA_FIN
AND C.ESTADO = 'PND' AND C.PCN_NUMERO_HC IN (85649)
GROUP BY C.PCN_NUMERO_HC;
I NUMBER :=0;
J NUMBER:=0;
FECHA_DESDE DATE;
FECHA_HASTA DATE;
FECHA_INICIAL_COMPLETA DATE;
FECHA_FINAL_COMPLETA DATE;
--NCNTPRM NUMBER:=0;
vPromocion varchar2(2):= NULL;

CURSOR PRMPCN(HC_PACIENTE NUMBER, FECHA_INI DATE, FECHA_FIN DATE) IS
SELECT P.FECHA,P.PCN_NUMERO_HC,P.PRM_CODIGO
FROM PROMOCIONES_PACIENTES P
WHERE P.PCN_NUMERO_HC = HC_PACIENTE AND
      P.FECHA BETWEEN FECHA_INI AND FECHA_FIN
ORDER BY P.FECHA;
 
TYPE PRMPCNTABTYP IS TABLE OF PRMPCN%ROWTYPE INDEX BY BINARY_INTEGER;
PRMPCN_TAB PRMPCNTABTYP;
BEGIN
   FECHA_INICIAL_COMPLETA:= TO_DATE(TO_CHAR(FECHA_INICIAL,'DD/MM/YYYY')||' 00:00:00','DD/MM/YYYY HH24:MI:SS');
   FECHA_FINAL_COMPLETA:= TO_DATE(TO_CHAR(FECHA_FINAL,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS');   
--   DBMS_OUTPUT.put_line('La fecha inicial es: ' ||to_char(FECHA_INICIAL_COMPLETA,'DD/MM/YYYY HH24:MI:SS'));
--   DBMS_OUTPUT.put_line('La fecha final es: ' ||to_char(FECHA_FINAL_COMPLETA,'DD/MM/YYYY HH24:MI:SS'));   
   FOR RPCNREC IN PCNREC(FECHA_INICIAL_COMPLETA,FECHA_FINAL_COMPLETA) LOOP
-- En primer lugar subo a la tabla todas las promociones del paciente
   I:= 0;
   J:=0;
   OPEN PRMPCN(RPCNREC.NUMERO_HC,FECHA_INICIAL_COMPLETA,FECHA_FINAL_COMPLETA);
   LOOP
      I:= I + 1;
      FETCH PRMPCN INTO PRMPCN_TAB(I);
         EXIT WHEN PRMPCN%NOTFOUND;
   END LOOP;
   CLOSE PRMPCN;
   i:= i-1;
   IF I >= 1 THEN   
   BEGIN  --Una vez obtenidas las promociones del paciente, se procede a recategorizar.
      BEGIN
         SELECT PRM.PRM_CODIGO  INTO vPromocion
         FROM PROMOCIONES_PACIENTES PRM
         WHERE PRM.PCN_NUMERO_HC=RPCNREC.NUMERO_HC AND 
               PRM.FECHA=(SELECT MAX(FECHA)
                             FROM PROMOCIONES_PACIENTES P
                             WHERE P.PCN_NUMERO_HC=RPCNREC.NUMERO_HC AND 
                                   P.fecha<PRMPCN_TAB(1).FECHA) ;
      EXCEPTION                           
      WHEN OTHERS THEN
         vPromocion:= PRMPCN_TAB(1).PRM_CODIGO;
      END;             
      DBMS_OUTPUT.put_line('Primera categorización');
      FECHA_DESDE := FECHA_INICIAL_COMPLETA;
      FECHA_HASTA := PRMPCN_TAB(1).FECHA;     
      RECATEGORIZAR_CUENTA(RPCNREC.NUMERO_HC,FECHA_DESDE,FECHA_HASTA,vPromocion);
  --    DBMS_OUTPUT.put_line('Primera promoción '||vPromocion);
  --    DBMS_OUTPUT.put_line('La fecha inicial es: ' ||to_char(FECHA_DESDE,'DD/MM/YYYY HH24:MI:SS'));
  --    DBMS_OUTPUT.put_line('La fecha final es: ' ||to_char(FECHA_HASTA,'DD/MM/YYYY HH24:MI:SS'));   
      IF I> 1 THEN
         QMS$ERRORS.Show_debug_info('Tiene más de una promoción ');
      FOR J IN 1..I-1 LOOP
         FECHA_DESDE := PRMPCN_TAB(J).FECHA;
         FECHA_HASTA := PRMPCN_TAB(J+1).FECHA;       
         RECATEGORIZAR_CUENTA(RPCNREC.NUMERO_HC,FECHA_DESDE,FECHA_HASTA,PRMPCN_TAB(J).PRM_CODIGO);
--         DBMS_OUTPUT.put_line('Promoción '||to_Char(j)||' '||PRMPCN_TAB(J).PRM_CODIGO);
--         DBMS_OUTPUT.put_line('La fecha inicial es: ' ||to_char(FECHA_DESDE,'DD/MM/YYYY HH24:MI:SS'));
--         DBMS_OUTPUT.put_line('La fecha final es: ' ||to_char(FECHA_HASTA,'DD/MM/YYYY HH24:MI:SS'));            
      END LOOP;
      END IF;   
      FECHA_DESDE := FECHA_HASTA;
      FECHA_HASTA := FECHA_FINAL_COMPLETA;
      RECATEGORIZAR_CUENTA(RPCNREC.NUMERO_HC,FECHA_DESDE,FECHA_HASTA,PRMPCN_TAB(I).PRM_CODIGO);    
--      DBMS_OUTPUT.put_line('Ultima promoción '||PRMPCN_TAB(I).PRM_CODIGO);
--      DBMS_OUTPUT.put_line('La fecha inicial es: ' ||to_char(FECHA_DESDE,'DD/MM/YYYY HH24:MI:SS'));
--      DBMS_OUTPUT.put_line('La fecha final es: ' ||to_char(FECHA_HASTA,'DD/MM/YYYY HH24:MI:SS'));   
   END;   
   ELSE
   BEGIN 
      SELECT PRM.PRM_CODIGO  INTO vPromocion
      FROM PROMOCIONES_PACIENTES PRM
      WHERE PRM.PCN_NUMERO_HC=RPCNREC.NUMERO_HC AND 
            PRM.FECHA=(SELECT MAX(FECHA)
                       FROM PROMOCIONES_PACIENTES P
                       WHERE P.PCN_NUMERO_HC=RPCNREC.NUMERO_HC AND
                             P.FECHA <= FECHA_INICIAL_COMPLETA);   
      DBMS_OUTPUT.put_line('Categorización Unica menor');                       
      RECATEGORIZAR_CUENTA(RPCNREC.NUMERO_HC,FECHA_INICIAL_COMPLETA, FECHA_FINAL_COMPLETA,vPromocion);
      DBMS_OUTPUT.put_line('Unica Promocion '||vPromocion);
      DBMS_OUTPUT.put_line('La fecha inicial es: ' ||to_char(FECHA_DESDE,'DD/MM/YYYY HH24:MI:SS'));
      DBMS_OUTPUT.put_line('La fecha final es: ' ||to_char(FECHA_HASTA,'DD/MM/YYYY HH24:MI:SS'));   
   EXCEPTION
   WHEN OTHERS THEN
      BEGIN 
         SELECT PRM.PRM_CODIGO  INTO vPromocion
         FROM PROMOCIONES_PACIENTES PRM
         WHERE PRM.PCN_NUMERO_HC=RPCNREC.NUMERO_HC AND 
               PRM.FECHA=(SELECT MIN(FECHA)
                       FROM PROMOCIONES_PACIENTES P
                       WHERE P.PCN_NUMERO_HC=RPCNREC.NUMERO_HC AND
                             P.FECHA > FECHA_FINAL_COMPLETA);   
         DBMS_OUTPUT.put_line('Categorización Unica mayor');                       
         RECATEGORIZAR_CUENTA(RPCNREC.NUMERO_HC,FECHA_INICIAL_COMPLETA, FECHA_FINAL_COMPLETA,vPromocion);
         DBMS_OUTPUT.put_line('Unica Promocion '||vPromocion);
         DBMS_OUTPUT.put_line('La fecha inicial es: ' ||to_char(FECHA_DESDE,'DD/MM/YYYY HH24:MI:SS'));
         DBMS_OUTPUT.put_line('La fecha final es: ' ||to_char(FECHA_HASTA,'DD/MM/YYYY HH24:MI:SS'));   
      EXCEPTION
      WHEN OTHERS THEN
         RAISE_APPLICATION_ERROR(-20210,'El paciente '||RPCNREC.NUMERO_HC||' no tiene promoción asociada '||SQLERRM);      
      END;   
   END;
   END IF;
   END LOOP;   
END RECATEGORIZAR_CUENTA_PRD;

PROCEDURE RECATEGORIZAR_PCN_MSP (FECHA_INICIAL IN DATE,FECHA_FINAL IN DATE,VPCN_NUMERO_HC IN NUMBER) IS
-- Procedimiento para recategorizar la cuenta del paciente IESSen base a las excepciones 
-- y a convenios equivalencias dentro del periodo indicado en los parámetros fecha_ini y fecha_fin.
I NUMBER :=0;
J NUMBER:=0;
FECHA_DESDE DATE;
FECHA_HASTA DATE;
FECHA_INICIAL_COMPLETA DATE;
FECHA_FINAL_COMPLETA DATE;
--NCNTPRM NUMBER:=0;
vPromocion varchar2(2):= NULL;

CURSOR PRMPCN(HC_PACIENTE NUMBER, FECHA_INI DATE, FECHA_FIN DATE) IS
SELECT P.FECHA,P.PCN_NUMERO_HC,P.PRM_CODIGO
FROM PROMOCIONES_PACIENTES P
WHERE P.PCN_NUMERO_HC = HC_PACIENTE AND
      P.FECHA BETWEEN FECHA_INI AND FECHA_FIN
ORDER BY P.FECHA;
 
TYPE PRMPCNTABTYP IS TABLE OF PRMPCN%ROWTYPE INDEX BY BINARY_INTEGER;
PRMPCN_TAB PRMPCNTABTYP;
BEGIN
   FECHA_INICIAL_COMPLETA:= TO_DATE(TO_CHAR(FECHA_INICIAL,'DD/MM/YYYY')||' 00:00:00','DD/MM/YYYY HH24:MI:SS');
   FECHA_FINAL_COMPLETA:= TO_DATE(TO_CHAR(FECHA_FINAL,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS');   
--   DBMS_OUTPUT.put_line('La fecha inicial es: ' ||to_char(FECHA_INICIAL_COMPLETA,'DD/MM/YYYY HH24:MI:SS'));
--   DBMS_OUTPUT.put_line('La fecha final es: ' ||to_char(FECHA_FINAL_COMPLETA,'DD/MM/YYYY HH24:MI:SS'));   
   I:= 0;
   J:=0;
   OPEN PRMPCN(VPCN_NUMERO_HC,FECHA_INICIAL_COMPLETA,FECHA_FINAL_COMPLETA);
   LOOP
      I:= I + 1;
      FETCH PRMPCN INTO PRMPCN_TAB(I);
         EXIT WHEN PRMPCN%NOTFOUND;
   END LOOP;
   CLOSE PRMPCN;
   i:= i-1;
   IF I >= 1 THEN   
   BEGIN  --Una vez obtenidas las promociones del paciente, se procede a recategorizar.
      BEGIN
         SELECT PRM.PRM_CODIGO  INTO vPromocion
         FROM PROMOCIONES_PACIENTES PRM
         WHERE PRM.PCN_NUMERO_HC=VPCN_NUMERO_HC AND 
               PRM.FECHA=(SELECT MAX(FECHA)
                             FROM PROMOCIONES_PACIENTES P
                             WHERE P.PCN_NUMERO_HC=VPCN_NUMERO_HC AND 
                                   P.fecha<PRMPCN_TAB(1).FECHA) ;
      EXCEPTION                           
      WHEN OTHERS THEN
         vPromocion:= PRMPCN_TAB(1).PRM_CODIGO;
      END;             
      DBMS_OUTPUT.put_line('Primera categorización');
      QMS$ERRORS.SHOW_DEBUG_INFO('Primera categorización');
      FECHA_DESDE := FECHA_INICIAL_COMPLETA;
      FECHA_HASTA := PRMPCN_TAB(1).FECHA;     
      RECATEGORIZAR_CUENTA_MSP(VPCN_NUMERO_HC,FECHA_DESDE,FECHA_HASTA,vPromocion);
      DBMS_OUTPUT.put_line('Primera promoción '||vPromocion);
      DBMS_OUTPUT.put_line('La fecha inicial es: ' ||to_char(FECHA_DESDE,'DD/MM/YYYY HH24:MI:SS'));
      DBMS_OUTPUT.put_line('La fecha final es: ' ||to_char(FECHA_HASTA,'DD/MM/YYYY HH24:MI:SS'));   
      IF I> 1 THEN
         QMS$ERRORS.Show_debug_info('Tiene más de una promoción ');
      FOR J IN 1..I-1 LOOP
         FECHA_DESDE := PRMPCN_TAB(J).FECHA;
         FECHA_HASTA := PRMPCN_TAB(J+1).FECHA;       
         RECATEGORIZAR_CUENTA_MSP(VPCN_NUMERO_HC,FECHA_DESDE,FECHA_HASTA,PRMPCN_TAB(J).PRM_CODIGO);
--         DBMS_OUTPUT.put_line('Promoción '||to_Char(j)||' '||PRMPCN_TAB(J).PRM_CODIGO);
--         DBMS_OUTPUT.put_line('La fecha inicial es: ' ||to_char(FECHA_DESDE,'DD/MM/YYYY HH24:MI:SS'));
--         DBMS_OUTPUT.put_line('La fecha final es: ' ||to_char(FECHA_HASTA,'DD/MM/YYYY HH24:MI:SS'));            
      END LOOP;
      END IF;   
      FECHA_DESDE := FECHA_HASTA;
      FECHA_HASTA := FECHA_FINAL_COMPLETA;
      RECATEGORIZAR_CUENTA_MSP(VPCN_NUMERO_HC,FECHA_DESDE,FECHA_HASTA,PRMPCN_TAB(I).PRM_CODIGO);    
--      DBMS_OUTPUT.put_line('Ultima promoción '||PRMPCN_TAB(I).PRM_CODIGO);
--      DBMS_OUTPUT.put_line('La fecha inicial es: ' ||to_char(FECHA_DESDE,'DD/MM/YYYY HH24:MI:SS'));
--      DBMS_OUTPUT.put_line('La fecha final es: ' ||to_char(FECHA_HASTA,'DD/MM/YYYY HH24:MI:SS'));   
   END;   
   ELSE
   BEGIN 
      SELECT PRM.PRM_CODIGO  INTO vPromocion
      FROM PROMOCIONES_PACIENTES PRM
      WHERE PRM.PCN_NUMERO_HC=VPCN_NUMERO_HC AND 
            PRM.FECHA=(SELECT MAX(FECHA)
                       FROM PROMOCIONES_PACIENTES P
                       WHERE P.PCN_NUMERO_HC=VPCN_NUMERO_HC AND
                             P.FECHA <= FECHA_INICIAL_COMPLETA);   
      DBMS_OUTPUT.put_line('Categorización Unica menor');                       
      RECATEGORIZAR_CUENTA_MSP(VPCN_NUMERO_HC,FECHA_INICIAL_COMPLETA, FECHA_FINAL_COMPLETA,vPromocion);
--      DBMS_OUTPUT.put_line('Unica Promocion '||vPromocion);
--      DBMS_OUTPUT.put_line('La fecha inicial es: ' ||to_char(FECHA_DESDE,'DD/MM/YYYY HH24:MI:SS'));
--     DBMS_OUTPUT.put_line('La fecha final es: ' ||to_char(FECHA_HASTA,'DD/MM/YYYY HH24:MI:SS'));   
   EXCEPTION
   WHEN OTHERS THEN
      BEGIN 
         SELECT PRM.PRM_CODIGO  INTO vPromocion
         FROM PROMOCIONES_PACIENTES PRM
         WHERE PRM.PCN_NUMERO_HC=VPCN_NUMERO_HC AND 
               PRM.FECHA=(SELECT MIN(FECHA)
                       FROM PROMOCIONES_PACIENTES P
                       WHERE P.PCN_NUMERO_HC=VPCN_NUMERO_HC AND
                             P.FECHA > FECHA_FINAL_COMPLETA);   
         DBMS_OUTPUT.put_line('Categorización Unica mayor');                       
         RECATEGORIZAR_CUENTA_MSP(VPCN_NUMERO_HC,FECHA_INICIAL_COMPLETA, FECHA_FINAL_COMPLETA,vPromocion);
 --        DBMS_OUTPUT.put_line('Unica Promocion '||vPromocion);
 --        DBMS_OUTPUT.put_line('La fecha inicial es: ' ||to_char(FECHA_DESDE,'DD/MM/YYYY HH24:MI:SS'));
 --        DBMS_OUTPUT.put_line('La fecha final es: ' ||to_char(FECHA_HASTA,'DD/MM/YYYY HH24:MI:SS'));   
      EXCEPTION
      WHEN OTHERS THEN
         RAISE_APPLICATION_ERROR(-20210,'El paciente '||VPCN_NUMERO_HC||' no tiene promoción asociada '||SQLERRM);      
      END;   
   END;
   END IF;
END RECATEGORIZAR_PCN_MSP;

------------------------------ FUNCIONES AÑADIDAS POR RINA PARA RECATEGORIZAR CUENTAS  ---------------
FUNCTION DEVUELVE_CONVENIO
 (NNUMEROHC IN NUMBER
 ,DFECHA IN DATE
 ,PRM_CODIGO IN OUT VARCHAR
 )
 RETURN VARCHAR2
 IS
 CURSOR PRMPCN(HC_PACIENTE NUMBER,FECHA_INICIAL DATE, FECHA_FINAL DATE)IS
 SELECT P.FECHA,P.PCN_NUMERO_HC,P.PRM_CODIGO
 FROM PROMOCIONES_PACIENTES P
 WHERE P.PCN_NUMERO_HC = HC_PACIENTE AND
       P.FECHA BETWEEN FECHA_INICIAL AND FECHA_FINAL
 ORDER BY P.FECHA;  
 
 CURSOR CNVPRM(PROMOCION VARCHAR2) IS
 SELECT CP.CNV_CONVENIO,CP.FECHA_INICIO,CP.FECHA_FIN
 FROM CONVENIOS_PROMOCIONES CP
 WHERE CP.PRM_CODIGO like PROMOCION AND
       CP.ESTADO_DE_DISPONIBILIDAD = 'D'
 ORDER BY CP.FECHA_INICIO;
 
 TYPE PRMPCNTABTYP IS TABLE OF PRMPCN%ROWTYPE INDEX BY BINARY_INTEGER;
 TYPE CNVPRMTABTYP IS TABLE OF CNVPRM%ROWTYPE INDEX BY BINARY_INTEGER;
 PRMPCN_TAB PRMPCNTABTYP;
 CNVPRM_TAB CNVPRMTABTYP;
 FECHA_INICIAL_COMPLETA DATE;
 FECHA_FINAL_COMPLETA DATE;
 I NUMBER:=0;
 J NUMBER :=1;
 K NUMBER := 0;
 L NUMBER := 0;
 VPROMOCION PROMOCIONES.CODIGO%TYPE:= NULL;
 VCONVENIO CONVENIOS.CONVENIO%TYPE:= NULL;
 FECHA_PROMOCION DATE;
 BEGIN
   FECHA_INICIAL_COMPLETA:= TO_DATE('01/01/0001 00:00:00','DD/MM/YYYY HH24:MI:SS');
   FECHA_FINAL_COMPLETA:= TO_DATE('31/12/3000 00:00:00','DD/MM/YYYY HH24:MI:SS');   
-- En primer lugar subo a la tabla todas las promociones del paciente
   I:= 0;
   OPEN PRMPCN(NNUMEROHC,FECHA_INICIAL_COMPLETA,FECHA_FINAL_COMPLETA);
   LOOP
      I:= I + 1;
      FETCH PRMPCN INTO PRMPCN_TAB(I);
         EXIT WHEN PRMPCN%NOTFOUND;
   END LOOP;
   CLOSE PRMPCN;
   i:= i-1;
   IF I >= 1 THEN   
   --Una vez obtenidas las promociones del paciente
   -- se procede a verificar la promocion de acuerdo
   -- a la fecha de procedimiento.
   BEGIN  
      DBMS_OUTPUT.put_line('La fecha es  '||to_char(dfecha,'dd/mm/yyyy HH24:MI:SS'));
      DBMS_OUTPUT.put_line('La primera fecha es  '||to_char(PRMPCN_TAB(1).FECHA,'dd/mm/yyyy HH24:MI:SS'));
      DBMS_OUTPUT.put_line('El valor de i es  '||to_char(i));      
      IF DFECHA < PRMPCN_TAB(1).FECHA THEN
         DBMS_OUTPUT.put_line('La fecha menor a la primera fecha');      
         VPROMOCION := PRMPCN_TAB(1).PRM_CODIGO;
         FECHA_PROMOCION := PRMPCN_TAB(1).FECHA;            
      ELSE
      IF I > 1 THEN
      FOR J IN 1..I-1 LOOP
         IF DFECHA>= PRMPCN_TAB(J).FECHA AND DFECHA<PRMPCN_TAB(J+1).FECHA THEN
            VPROMOCION := PRMPCN_TAB(J).PRM_CODIGO;
            FECHA_PROMOCION := PRMPCN_TAB(J).FECHA;            
            EXIT;
         ELSIF DFECHA = PRMPCN_TAB(J+1).FECHA THEN   
            VPROMOCION := PRMPCN_TAB(J+1).PRM_CODIGO;
            FECHA_PROMOCION := PRMPCN_TAB(J+1).FECHA;
            EXIT;
         END IF;
      END LOOP;
      END IF;
      DBMS_OUTPUT.put_line('La fecha de la última promoción es: '||to_char(PRMPCN_TAB(I).FECHA,'dd/mm/yyyy HH24:MI'));
      IF DFECHA > PRMPCN_TAB(I).FECHA THEN
         VPROMOCION := PRMPCN_TAB(I).PRM_CODIGO;
         FECHA_PROMOCION := PRMPCN_TAB(I).FECHA;         
      END IF;
      END IF;
   END;
   ELSE
      VPROMOCION := PRMPCN_TAB(I).PRM_CODIGO;
      FECHA_PROMOCION := PRMPCN_TAB(I).FECHA;            
   END IF;
   DBMS_OUTPUT.put_line('El valor de j es '||to_char(j));    
   DBMS_OUTPUT.put_line('La promocion es '||VPROMOCION ||' Buscamos el convenio de esta promocion');       
 -- Una vez obtenida la promocion en VPROMOCION procedo a ver el convenio o tarifario
    K:=0;
   OPEN CNVPRM(VPROMOCION);
   LOOP
      K:= K + 1;
      FETCH CNVPRM INTO CNVPRM_TAB(K);
      EXIT WHEN CNVPRM%NOTFOUND;
   END LOOP;
   CLOSE CNVPRM;   
   K:= K-1; 
   FOR L IN 1..K LOOP
      IF FECHA_PROMOCION BETWEEN TO_DATE(TO_CHAR(CNVPRM_TAB(L).FECHA_INICIO,'DD/MM/YYYY')||' 00:00:00','DD/MM/YYYY HH24:MI:SS') AND TO_DATE(TO_CHAR(NVL(CNVPRM_TAB(L).FECHA_FIN,SYSDATE),'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS') THEN   
          VCONVENIO := CNVPRM_TAB(L).CNV_CONVENIO;
         EXIT;
      END IF;   
   END LOOP;
   IF VCONVENIO IS NULL THEN
      VCONVENIO := 'SIN CONVENIO';
   END IF;
   DBMS_OUTPUT.put_line('El valor de I  y la promocion es '||to_char(I)||' '||VPROMOCION||' El convenio es '||VCONVENIO);
   PRM_CODIGO := VPROMOCION;
   RETURN VCONVENIO;
 END; 
 
 
-- CARGAR AUTOMÁTICAMENTE LOS HONORARIOS MEDICOS A LA CUENTA DEL PACIENTE. 
-- SE CREA AUTOMÁTICAMENTE LAS PLANILLAS DE HONORARIOS MEDICOS PARA  LA CAJA MEDICA
PROCEDURE CARGAR_CUENTA_TRF
(PCN_NUMERO_HC IN NUMBER,
P_DPR_ARA_CODIGO IN CHAR,
P_DPR_CODIGO IN CHAR,
P_EMP_CODIGO IN CHAR,
P_DOCUMENTO IN CHAR,
P_NUMERO IN CHAR,
P_DETALLE IN CHAR
) 
IS
CURSOR HONMED IS           -- consulta para conformar el detalle de la planilla
select H.ENTBNF_MSTBNF_CODIGO,H.ENTBNF_CODIGO,H.ENTBNF_MSTBNF_GRUPAL,H.ENTBNF_CODIGO_GRUPAL,H.TIPO_HONORARIO,
       H.DOCUMENTO,H.NUMERO,H.ID,H.PRM_CODIGO,H.CREADO_POR,H.PUNTOS_AUDITORIA,H.UVR,H.PORCENTAJE_AUDITORIA,
       H.CANTIDAD,H.PORCENTAJE_PROMOCION,H.PLNHNR_NUMERO,H.CRG_TIPO,H.CRG_CODIGO,H.PRCHSP_CODIGO,H.PUNTOS,
       H.VALOR,H.VALOR_AUDITORIA,C.RV_MEANING HONORARIO,H.FECHA
from honorarios_medicos h,cg_ref_codes c
WHERE H.ESTADO_AUDITORIA = 'A' AND
      H.ESTADO = 'PLN' AND
      H.PCN_NUMERO_HC = PCN_NUMERO_HC AND
      H.DOCUMENTO = P_DOCUMENTO AND
      H.NUMERO = P_NUMERO AND
      H.ID =P_DETALLE AND
      H.TIPO_HONORARIO = C.RV_LOW_VALUE AND
      C.RV_DOMAIN = 'TIPO REMUNERACION'
ORDER BY 6 DESC;

VNUM_PLANILLA NUMBER:=0;       -- secuencia de la planilla
VNUM_DET_PLANILLA NUMBER := 0; -- secuencia del detalle de la planilla
VTOTAL NUMBER :=0;             -- total de la planilla
VASIGNADO VARCHAR2(1) := 'F';  -- es médico asignado por la clínica
VTRATANTE VARCHAR2(1) := 'F';  -- es medico tratante
CONT NUMBER:= 0;
CONTADOR NUMBER := 0;
vDPR_ARA_CDG_PRT_A VARCHAR2(1):= NULL;   -- area a la que pertenece el cargo
vDPR_CDG_PRT_A  VARCHAR2(1):= NULL;      -- departamento al que pertenece el cargo
vbeneficiario varchar2(80) := NULL;      -- beneficiario del honorario
vprocedimiento varchar2(165) := NULL;    -- procedimiento que generó el honorario.
FECHA_HOY DATE := NULL;
PERSONA varchar2(10);
VDESC_CARGO VARCHAR2(120);
VAUDITA VARCHAR2(1) := 'F';
GENERA_PLANILLA VARCHAR2(1) := 'F';
BEGIN
  FOR RHONMED IN  HONMED LOOP
  BEGIN
    SELECT P.REQUIERE_AUDITORIA INTO VAUDITA 
    FROM PROMOCIONES P
    WHERE P.CODIGO =  RHONMED.PRM_CODIGO;
  EXCEPTION
  WHEN OTHERS THEN
     VAUDITA:= 'V';
  END;   
  QMS$ERRORS.show_DEBUG_INFO('ENTRA AL PROCESO DE INSERCION DE HONORARIOS AUTOMÁTICO POR TARIFARIO MSP');
  IF  VAUDITA = 'F' THEN
    QMS$ERRORS.show_DEBUG_INFO('Se cumple la condición');
  BEGIN
     BEGIN -- VERIFICA SI LA EMPRESA GENERA O NO PLANILLAS PARA LOS HONORARIOS DEL MSP
     SELECT P.VALOR INTO GENERA_PLANILLA 
     FROM PARAMETROS_EMPRESAS P
     WHERE P.PRMAPL_NOMBRE = 'EMITIR_PLANILLAS_CAJA_MEDICA' 
     AND P.EMP_CODIGO = P_EMP_CODIGO;
     EXCEPTION     
     WHEN OTHERS THEN
       GENERA_PLANILLA := 'F';
     END;
     IF  RHONMED.NUMERO IS NOT NULL THEN     -- sólo si hay permanencia crea la planilla
        IF GENERA_PLANILLA = 'V' THEN
        SELECT CODIGO INTO PERSONA
        FROM PERSONAL P
        WHERE P.USUARIO = RHONMED.CREADO_POR;
        QMS$ERRORS.show_DEBUG_INFO('La persona es '||persona);
        BEGIN
            QMS$ERRORS.SHOW_DEBUG_INFO('Va a recuperar los datos para generar la planilla');
            VTOTAL:=RHONMED.PUNTOS_AUDITORIA*RHONMED.UVR*RHONMED.PORCENTAJE_AUDITORIA/100*RHONMED.CANTIDAD * RHONMED.PORCENTAJE_PROMOCION;
            --GNRL.ACTUALIZA_SECUENCIA('PLNHNRMDC_SEQ',VNUM_PLANILLA);
            QMS$ERRORS.SHOW_DEBUG_INFO('Recupera los datos para generar la planilla');
            INSERT INTO PLANILLAS_HONORARIOS_MDC(NUMERO,CJA_CODIGO,FECHA,TOTAL,SALDO,ESTADO,EMERGENCIA,
                                              ABIERTA,A_CONTABILIZARSE,PRMATN_NUMERO,PRMATN_PCN_NUMERO_HC,
                                              OBSERVACION,PRS_CODIGO,CONTABILIZADO,FECHA_CREACION)
            VALUES(RHONMED.PLNHNR_NUMERO,'CJA',SYSDATE,VTOTAL,VTOTAL,'PND','F','F','V', RHONMED.NUMERO,
                   PCN_NUMERO_HC ,'GENERADO AUTOMÁTICAMENTE CON TARIFARIO',PERSONA,'F',SYSDATE);
            QMS$ERRORS.SHOW_DEBUG_INFO('Insertó la planilla');
            QMS$ERRORS.SHOW_DEBUG_INFO('Va a generar el detalle de la planilla');
            BEGIN
               IF RHONMED.ENTBNF_MSTBNF_GRUPAL IS NOT NULL THEN
                  VASIGNADO := 'V';
               ELSE
                  VASIGNADO := 'F';
               END IF;
               IF RHONMED.TIPO_HONORARIO = 'HOT' THEN
                  VTRATANTE := 'V';
               ELSE
                  VTRATANTE := 'F';
               END IF;
               GNRL.ACTUALIZA_SECUENCIA('DTLHNRMDC_SEQ',VNUM_DET_PLANILLA);
               QMS$ERRORS.SHOW_DEBUG_INFO('Los valores a ingresar son: '||to_char(vnum_Det_planilla)||' '||vasignado||' '||vtratante||' '||to_char(VTOTAL));
               INSERT INTO DETALLES_HONORARIOS_MEDICOS(NUMERO,PLNHNRMDC_NUMERO,ENTBNF_MSTBNF_CODIGO,ENTBNF_CODIGO,
                                                       VALOR,ESTADO,REMUNERACION_POR,MEDICO_TRATANTE,INGRESADO_DESPUES_CONTABILIZAR,
                                                       ASIGNADO_POR_LA_CLINICA,OBSERVACION)
               VALUES(VNUM_DET_PLANILLA,RHONMED.PLNHNR_NUMERO,NVL(RHONMED.ENTBNF_MSTBNF_GRUPAL,RHONMED.ENTBNF_MSTBNF_CODIGO),
                      NVL(RHONMED.ENTBNF_CODIGO_GRUPAL,RHONMED.ENTBNF_CODIGO),VTOTAL,'NRM',
                      RHONMED.TIPO_HONORARIO,VTRATANTE,'F',VASIGNADO,RHONMED.DOCUMENTO||to_Char(RHONMED.NUMERO)||to_char(RHONMED.ID));
            EXCEPTION
            WHEN OTHERS THEN
               QMS$ERRORS.SHOW_MESSAGE('CJM-00025', RHONMED.TIPO_HONORARIO||sqlerrm);
            END;
            CONTADOR:= CONTADOR+1;
            QMS$ERRORS.SHOW_DEBUG_INFO('Se insertó '||to_char(CONTADOR)||'líneas en el detalle de la planilla');
      EXCEPTION
        WHEN OTHERS THEN
           QMS$ERRORS.SHOW_MESSAGE('CJM-00026');
      END;
      END IF;
      BEGIN
         BEGIN
           SELECT DPR_ARA_CODIGO,DPR_CODIGO,DESCRIPCION
           INTO vDPR_ARA_CDG_PRT_A,vDPR_CDG_PRT_A,VDESC_CARGO
           FROM CARGOS
           WHERE TIPO = RHONMED.CRG_TIPO AND
                 CODIGO = RHONMED.CRG_Codigo;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           QMS$ERRORS.SHOW_MESSAGE('CJM-00028',RHONMED.CRG_TIPO||RHONMED.CRG_Codigo);
         WHEN OTHERS THEN
           QMS$ERRORS.SHOW_MESSAGE('CJM-00028',RHONMED.CRG_TIPO||RHONMED.CRG_Codigo);
         END;
   --               CONT:= CONT+1;
         BEGIN
           SELECT DESCRIPCION INTO VBENEFICIARIO
           FROM ENTIDADES_BENEFICIARIAS
           WHERE MSTBNF_CODIGO = RHONMED.ENTBNF_MSTBNF_CODIGO AND
                 CODIGO = RHONMED.ENTBNF_CODIGO;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
            QMS$ERRORS.SHOW_MESSAGE('CJM-00029',RHONMED.ENTBNF_MSTBNF_CODIGO||RHONMED.ENTBNF_CODIGO);
         END;
         BEGIN
           SELECT SUBSTR(DESCRIPCION,1,165) INTO vprocedimiento
           FROM PROCEDIMIENTOS_HOSPITALARIOS
           WHERE CODIGO = RHONMED.PRCHSP_CODIGO;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            QMS$ERRORS.SHOW_MESSAGE('CJM-00030',RHONMED.PRCHSP_CODIGO);
         END;
         SELECT SYSDATE INTO FECHA_HOY FROM DUAL;
         BEGIN
           INSERT INTO cuentas
             (documento,numero,DETALLE,ESTADO,fecha,cantidad,
              valor,crg_tipo,crg_codigo,porcentaje_promocion,
              iva,creado_por,dpr_ara_codigo,dpr_codigo,pcn_numero_hc,
              dpr_ara_codigo_perteneciente_a,dpr_codigo_perteneciente_a,
              prm_codigo,observacion,uvr,prc)
           VALUES
              (RHONMED.DOCUMENTO,RHONMED.NUMERO,RHONMED.ID,'PND',
               RHONMED.FECHA,RHONMED.CANTIDAD,NVL(RHONMED.VALOR_AUDITORIA,RHONMED.VALOR),
               RHONMED.CRG_TIPO,RHONMED.CRG_CODIGO,RHONMED.PORCENTAJE_PROMOCION,
               0,RHONMED.creado_por,P_DPR_ARA_CODIGO,P_DPR_CODIGO,PCN_NUMERO_HC,
               vDPR_ARA_CDG_PRT_A,vDPR_CDG_PRT_A,RHONMED.PRM_CODIGO,VBENEFICIARIO||' '||RHONMED.HONORARIO,
               NVL(RHONMED.PUNTOS_AUDITORIA,RHONMED.puntos),RHONMED.uvr);
         EXCEPTION
         WHEN OTHERS  THEN
            QMS$ERRORS.SHOW_MESSAGE('CJM-00025', RHONMED.TIPO_HONORARIO||SQLERRM);
         END;
         CONTADOR := CONTADOR + 1;
         QMS$ERRORS.SHOW_DEBUG_INFO('Se insertó '||to_char(CONTADOR)||'líneas en la cuenta del paciente');
      END;
   ELSE
      QMS$ERRORS.SHOW_MESSAGE('CJM-00024',TO_CHAR(PCN_NUMERO_HC));
   END IF;
  EXCEPTION
  WHEN OTHERS THEN
     QMS$ERRORS.unhandled_exception('FCTCONTRF.CARGAR_CUENTA_TRF');
  END;
  END IF;
END LOOP;  
END;
 
-- Carga honorarios de acuerdo al tarifario del MSP 
PROCEDURE CARGAR_HONORARIO_TRF
 (P_NUMERO IN CUENTAS.NUMERO%TYPE
 ,P_BENEFICIARIO IN PERSONAL.CODIGO%TYPE
 ,P_ID IN CUENTAS.DETALLE%TYPE
 ,P_CANTIDAD IN CUENTAS.CANTIDAD%TYPE
 ,P_DOCUMENTO IN CUENTAS.DOCUMENTO%TYPE
 ,P_PCN_NUMERO_HC IN CUENTAS.PCN_NUMERO_HC%TYPE
 ,P_INS_OR_DEL IN VARCHAR2
 ,P_FECHA IN DATE
 ,P_TIPO_REMUNERACION IN VARCHAR2 := 'HNR'
 ,P_EVLCLN IN HOJAS_DE_EVOLUCION.NUMERO%TYPE
 ,P_PRCHSP_CODIGO IN PROCEDIMIENTOS_HOSPITALARIOS.CODIGO%TYPE
 ,P_LATERALIDAD IN PROCEDIMIENTOS_REALIZADOS.LATERALIDAD%TYPE
 ,P_CASO IN NUMBER := 4
 ,P_CONDICION IN NUMBER  := 1
 ,P_DIVISOR IN NUMBER := 1
 ,P_POOL IN NUMBER := 0
 ,P_DURACION IN NUMBER:=0
 ,P_AREA IN VARCHAR2
 ,P_DEPARTAMENTO IN VARCHAR2
 ,P_EMP_CODIGO IN CHAR 
 )
 IS

VPRMPCN PROMOCIONES.CODIGO%TYPE;
DFECHA DATE;
VESTADO_AUDITORIA VARCHAR2(1);
VESTADO_CUENTA VARCHAR2(3);
VESTADO_GENERAR VARCHAR2(3);
VESTADO_AUDITORIA_I VARCHAR2(1);
VESTADO_GENERAR_I VARCHAR2(3);
VDPR_ARA_CDG_PRT_A AREAS.CODIGO%TYPE;
VDPR_CDG_PRT_A DEPARTAMENTOS.CODIGO%TYPE;
VMSTBNF_CODIGO ENTIDADES_BENEFICIARIAS.MSTBNF_CODIGO%TYPE;
VUVR PROCEDIMIENTOS_HOSPITALARIOS.UVR%TYPE;
VPUNTOS PROCEDIMIENTOS_HOSPITALARIOS.PUNTOS%TYPE;
VPUNTOS_TIEMPO PROCEDIMIENTOS_HOSPITALARIOS.PUNTOS%TYPE:=0;
VPUNTOS_CONDICION PROCEDIMIENTOS_HOSPITALARIOS.PUNTOS%TYPE:=0;
VPUNTOS_EDAD PROCEDIMIENTOS_HOSPITALARIOS.PUNTOS%TYPE:=0;
VNOAPLICA_TIEMPO VARCHAR2(1):= NULL;
VCONDICION_CLINICA VARCHAR2(2):= NULL;
VCONDICION_EDAD VARCHAR2(2):= NULL;
VCRG_TIPO CARGOS.TIPO%TYPE;
VCRG_CODIGO CARGOS.CODIGO%TYPE;
VVALOR_HONORARIO NUMBER := 0;
VPORCENTAJE_HONORARIO NUMBER :=0;
VPORCENTAJE_CALCULADO NUMBER := 0;
VENTBNF_CODIGO ENTIDADES_BENEFICIARIAS.CODIGO%TYPE;
NPORCENTAJE_PROMOCION DETALLES_PROMOCIONES.PORCENTAJE_PROMOCION%TYPE:=1;
VINC_LATERALIDAD NUMBER := 0;
NPLANILLA PLANILLAS_HONORARIOS_MDC.NUMERO%TYPE := NULL;
NVALOR_PLANILLA NUMBER:=0;
VCONVENIO CONVENIOS.CONVENIO%TYPE;
VCODIGO_ITEM TARIFARIOS.CODIGO_ITEM%TYPE;
VTIPO TARIFARIOS.TIPO%TYPE;
VAUDITA VARCHAR2(1) := NULL;
GENERA_PLANILLA  VARCHAR2(1) := 'F';
VBENEFICIARIO VARCHAR2(5):= NULL;
VVALOR_TIEMPO NUMBER := 0;


  --DOCUMENTO:
  -- 0 es para procedimientos quirúrgicos
  -- G es para procedimiento menor
  -- M es para visita médica
  -- R es para interconsultas
  -- Y es para atención en emeregencia y para sedaciones en imagen, se generan automaticamente en el rio
  -- V es para Valoracióne s cardiológicas
  -- # es para honorarios manuales
  
  
-- cursor que devuelve el porcentaje promoción del departamento según la promoción
  CURSOR cDetPrm (vPromocion PROMOCIONES.CODIGO%TYPE,
                  vArea AREAS.CODIGO%TYPE,
                  vDept DEPARTAMENTOS.CODIGO%TYPE) IS
    SELECT PORCENTAJE_PROMOCION
    FROM DETALLES_PROMOCIONES
    WHERE prm_codigo=vPromocion
    AND DPR_ARA_CODIGO=vArea
    AND DPR_CODIGO=vDept;
-- cursor que devuelve el porcentaje promoción del cargo según la promoción
  CURSOR cPrmExc (vPromocion PROMOCIONES.CODIGO%TYPE,
                  vArea AREAS.CODIGO%TYPE,
                  vDept DEPARTAMENTOS.CODIGO%TYPE,
                  vTipo CARGOS.TIPO%TYPE,
                  vCargo CARGOS.CODIGO%TYPE) IS
    SELECT PORCENTAJE_PROMOCION
    FROM PROMOCIONES_EXCEPCIONES
    WHERE PRM_CODIGO=vPromocion
    AND DPR_ARA_CODIGO=vArea
    AND DPR_CODIGO=vDept
    AND CRG_TIPO=vTipo
    AND CRG_CODIGO=vCargo;  
  PACIENTE_SIN_PROMOCION EXCEPTION;
  CARGO_NO_EXISTENTE EXCEPTION;
  YA_FACTURADO EXCEPTION;  
  SIN_PROCEDIMIENTO EXCEPTION;     
  SIN_TIPO_REMUNERACION EXCEPTION;
  SIN_BENEFICIARIO EXCEPTION;
  HONORARIO_NO_EXISTENTE EXCEPTION;
  ERROR_HONORARIOS EXCEPTION;
  HONORARIO_SIN_PUNTOS EXCEPTION;
  ERROR_CREAR_HONORARIO EXCEPTION;
  EXISTE_PLANILLA EXCEPTION;
  HONORARIO_NO_GENERADO EXCEPTION;       

BEGIN  
   QMS$ERRORS.SHOW_DEBUG_INFO('La fecah para cargar los honorarios es '||to_char(P_FECHA,'DD/MM/YYYY'));
   VCONVENIO:=DEVUELVE_CONVENIO(P_PCN_NUMERO_HC,NVL(P_FECHA,SYSDATE),VPRMPCN);
   dbms_output.put_line('El convenio es '||VCONVENIO);
   dbms_output.put_line('La promocion devuelta es '||vPrmPcn);   
   DBMS_OUTPUT.put_line('El caso es :'||to_char(P_CASO)); 
   DBMS_OUTPUT.put_line('La condicion es  :'||to_char(P_CONDICION));
   DBMS_OUTPUT.put_line('El código del procedimiento es   :'||P_PRCHSP_CODIGO);   
   QMS$ERRORS.SHOW_DEBUG_INFO('***************************************************');                                               
   QMS$ERRORS.SHOW_DEBUG_INFO('Entra al proceso de generación de honorarios');                                            
   QMS$ERRORS.SHOW_DEBUG_INFO('El caso es :'||to_char(P_CASO)); 
   QMS$ERRORS.SHOW_DEBUG_INFO('La condicion es  :'||to_char(P_CONDICION));   
   QMS$ERRORS.SHOW_DEBUG_INFO('El divisor es  :'||to_char(P_DIVISOR));      
   QMS$ERRORS.SHOW_DEBUG_INFO('El tipo de remuneración es '||p_tipo_remuneracion);                                         
   QMS$ERRORS.SHOW_DEBUG_INFO('El código del procedimiento es   :'||P_PRCHSP_CODIGO);
   BEGIN
   -- Recupera convenio, codigo_item y tipo del rubro del tarifario correspondiente al procedimiento realizado
        SELECT P.CODIGO_TARIFARIO, P.TRF_TIPO,P.CONVENIO INTO VCODIGO_ITEM,VTIPO,VCONVENIO
        FROM PROCEDIMIENTOS_HOSPITALARIOS p
        WHERE CODIGO = P_PRCHSP_CODIGO;
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
        RAISE SIN_PROCEDIMIENTO;
   END;
   BEGIN -- RECUPERA EL VALOR POR TIEMPO DE ANESTESIÓLOGOS FIJADO POR EL MSP
           SELECT P.VALOR INTO VVALOR_TIEMPO
           FROM PARAMETROS_EMPRESAS P
           WHERE P.PRMAPL_NOMBRE = 'VALOR_TIEMPO_ANESTESIA' 
        AND P.EMP_CODIGO = P_EMP_CODIGO;
   EXCEPTION     
        WHEN OTHERS THEN
           VVALOR_TIEMPO := 0;
   END;
   BEGIN -- VERIFICA SI LA EMPRESA GENERA O NO PLANILLAS PARA LOS HONORARIOS DEL MSP
           SELECT P.VALOR INTO GENERA_PLANILLA 
           FROM PARAMETROS_EMPRESAS P
           WHERE P.PRMAPL_NOMBRE = 'EMITIR_PLANILLAS_CAJA_MEDICA' 
        AND P.EMP_CODIGO = P_EMP_CODIGO;
   EXCEPTION     
        WHEN OTHERS THEN
           GENERA_PLANILLA := 'F';
   END;
   IF NVL(GENERA_PLANILLA,'F') = 'F'  THEN
   BEGIN
      SELECT P.VALOR INTO VBENEFICIARIO
      FROM PARAMETROS_EMPRESAS P
      WHERE P.EMP_CODIGO = P_EMP_CODIGO AND
            P.PRMAPL_NOMBRE = 'BENEFICIARIO_IESS';
   EXCEPTION 
   WHEN NO_DATA_FOUND  THEN    
      VBENEFICIARIO := P_BENEFICIARIO;    
   END;
   END IF;
   dbms_output.put_line('El codigo recuperado es '||VCODIGO_ITEM||' '||VTIPO||' '||VCONVENIO);                                            
   QMS$ERRORS.SHOW_DEBUG_INFO('El codigo recuperado es '||VCODIGO_ITEM||' '||VTIPO||' '||VCONVENIO);                                               
   IF p_tipo_remuneracion is not null THEN  --con el tipo de remuneración se puede obtener el cargo para los honorarios   
      BEGIN
         SELECT P.REQUIERE_AUDITORIA INTO VAUDITA 
         FROM PROMOCIONES P
         WHERE P.CODIGO = VPRMPCN;
      EXCEPTION
      WHEN OTHERS THEN
         VAUDITA:= 'V';
      END;   
      IF P_DOCUMENTO  = 'Y' OR VAUDITA = 'F' THEN
        VESTADO_AUDITORIA_I := 'A';
        VESTADO_GENERAR_I:= 'PLN';
        IF GENERA_PLANILLA = 'V' THEN
           GNRL.ACTUALIZA_SECUENCIA('PLNHNRMDC_SEQ',NPLANILLA);
        ELSE
           NPLANILLA:= NULL;
        END IF;   
      END IF;   
   BEGIN    
     SELECT C.CRG_TIPO,C.CRG_CODIGO INTO VCRG_TIPO,VCRG_CODIGO
     FROM CONVENIOS_EQUIVALENCIAS C
     WHERE C.CNVTRF_CONVENIO = VCONVENIO AND
           C.CNVTRF_CODIGO = VCODIGO_ITEM AND
           C.TIPO  = VTIPO; 
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
        RAISE CARGO_NO_EXISTENTE; 
     WHEN OTHERS THEN       -- si no encuentra un cargo asociado es porque no se va a cargar a  la cuenta del paciente  
        RAISE ERROR_HONORARIOS;
        --NULL;
   END;  
   qms$errors.show_debug_info('Cargo '||vcrg_tipo||vcrg_codigo);
   dbms_output.put_line('Cargo '||vcrg_tipo||vcrg_codigo);
   END IF;
   IF VCRG_TIPO  IS NOT NULL AND VCRG_TIPO NOT IN ('M','I','U') THEN
   BEGIN    
     SELECT DPR_ARA_CODIGO,DPR_CODIGO
     INTO vDPR_ARA_CDG_PRT_A,vDPR_CDG_PRT_A
     FROM CARGOS
     WHERE TIPO =VCRG_TIPO 
     AND CODIGO = VCRG_Codigo;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RAISE CARGO_NO_EXISTENTE;
      WHEN OTHERS THEN
        RAISE ERROR_HONORARIOS;
   END;
   END IF;   
  qms$errors.show_debug_info('Area y Dep '||vDPR_ARA_CDG_PRT_A||vDPR_CDG_PRT_A);
  qms$errors.show_debug_info('PROMOCION PACIENTE '||vPrmPcn);    
  IF vDPR_ARA_CDG_PRT_A IS NOT NULL AND vDPR_CDG_PRT_A IS NOT NULL AND VCRG_TIPO IS NOT NULL AND VCRG_CODIGO IS NOT NULL THEN
  BEGIN     
    OPEN CDetPrm (vPrmPcn,vDPR_ARA_CDG_PRT_A,vDPR_CDG_PRT_A);
    FETCH CDetPrm INTO nPORCENTAJE_PROMOCION;
    -- Si el area y departamento tienen una promocion, vemos si es una excepcion
    OPEN CPrmExc (vPrmPcn,vDPR_ARA_CDG_PRT_A,vDPR_CDG_PRT_A,VCRG_TIPO,VCRG_CODIGO);
    FETCH CPrmExc INTO nPorcentaje_Promocion;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
      NULL; -- El area y el departamento ni la excepcion no tienen ninguna promocion
  END;
  END IF;
  QMS$ERRORS.SHOW_DEBUG_INFO('*****************************************************');  
  QMS$ERRORS.SHOW_DEBUG_INFO('La fecha con la que se llama al procedimiento es '||TO_CHAR(P_Fecha,'DD/MM/YYYY'));
  QMS$ERRORS.SHOW_DEBUG_INFO('*****************************************************');    
  IF P_Fecha IS NULL THEN
-- Si viene sin fecha, ingresamos la fecha del dia de hoy
    dFecha:=SYSDATE;
  ELSE
    dFecha:=p_Fecha;
  END IF;     
  qms$errors.show_debug_info('FECHAR '||TO_CHAR(DFECHA,'DD/MM/YYYY HH24:MI'));    
  -- obtienen el porcentaje según el tipo de remuneración
  BEGIN    
  IF p_tipo_remuneracion is not null  then
     BEGIN
/*        select to_number(RV_HIGH_VALUE) into vporcentaje_honorario
        from cg_ref_codes
        where rv_domain =  'TIPO REMUNERACION' and
              rv_low_value = p_tipo_remuneracion;   */
        IF p_tipo_remuneracion = 'HOT' THEN
           vporcentaje_honorario := 100;
        ELSIF p_tipo_remuneracion = 'HOY' THEN
           vporcentaje_honorario := 20;
        ELSIF p_tipo_remuneracion = 'HOI' THEN
           vporcentaje_honorario := 0;
        ELSE        
        vporcentaje_honorario := 100;
        END IF;                    
        VINC_LATERALIDAD := 0;
        IF NVL(P_LATERALIDAD,'X') = 'U' THEN   -- si el procedimiento es unilateral la remuneración se mantiente
           VINC_LATERALIDAD := 0;    
        ELSE                          -- si el procedimiento es bilateral la remuneración se incrementa en el 75%
--           VINC_LATERALIDAD := 0.75;              
        VINC_LATERALIDAD := 0;
        END IF;    
        IF P_CASO = 1 THEN   
        -- Si existe más de un  procedimiento y la via de acceso es la misma  y es realizado
        -- por el mismo especialista la remuneración del procedimiento màs costoso se mantiene
        -- y la remuenración de los otros procedimientos se paga  el 50% y 25%  del costo
           IF P_CONDICION = 1 THEN
              VPORCENTAJE_CALCULADO := vporcentaje_honorario + (vporcentaje_honorario*VINC_LATERALIDAD)/100;              
           ELSIF P_CONDICION = 2 THEN
              VPORCENTAJE_CALCULADO := (vporcentaje_honorario*(50 + VINC_LATERALIDAD))/100;              
           ELSE   
              VPORCENTAJE_CALCULADO := (vporcentaje_honorario*(25 + VINC_LATERALIDAD))/100;                         
           END IF;       
        ELSIF P_CASO = 2 THEN      
        -- Si existe más de un  procedimiento y la via de acceso es diferente  y es realizado
        -- por el mismo especialista la remuneración de los procedimiento  se mantiene con el
        -- 100% del costo.
              VPORCENTAJE_CALCULADO := vporcentaje_honorario;
        ELSIF P_CASO = 3 THEN
        -- Si existe más de un  procedimiento y es realizado por más de un  especialista,
        -- con via de acceso es la misma, la remuneración del procedimiento màs costoso se mantiene
        -- pero se cobra el 150% para que sea repartido en partes iguales por los especialistas
        -- y la remuenración de los otros procedimientos se paga  el 50% y 25% del 150%  del costo
           vporcentaje_honorario :=150;        
           IF P_CONDICION = 1 THEN
              VPORCENTAJE_CALCULADO := vporcentaje_honorario / p_divisor;              
           ELSIF P_CONDICION = 2 THEN
              vporcentaje_honorario:= 75; 
              VPORCENTAJE_CALCULADO :=vporcentaje_honorario / p_divisor;
           ELSE   
              vporcentaje_honorario:= 37.5;                         
              VPORCENTAJE_CALCULADO :=vporcentaje_honorario / p_divisor;
          END IF;       
        ELSIF P_CASO = 9 THEN
        -- Si existe más de un  procedimiento y es realizado por más de un  especialista,
        -- con via de acceso es diferente, la remuneración de todos los procedimientos se 
        -- mantienen pero se cobra el 150% del costo de cada uno y se divide para el número
        -- de beneficiarios en partes iguales.
              vporcentaje_honorario :=150;        
              VPORCENTAJE_CALCULADO := vporcentaje_honorario / p_divisor;              
         ELSIF P_CASO = 5 THEN                                                                          
        -- Si el caso es 5 entonces es Pediatría
           VPORCENTAJE_CALCULADO := 1000;
        ELSIF P_CASO = 4 THEN                                                                           
        -- Si no es ninguno de los casos anteriores simplemente se considera la remuneraciòn del procedimiento
        -- tomando en cuenta la lateralidad (VINC_LATERALIDAD) y el número de profesionales que interviene (p_divisor)    
           IF p_divisor > 1 then
--              VPORCENTAJE_CALCULADO := (vporcentaje_honorario + VINC_LATERALIDAD)/p_divisor;    
              VPORCENTAJE_CALCULADO := (vporcentaje_honorario + (vporcentaje_honorario*(VINC_LATERALIDAD+vporcentaje_honorario/p_divisor))/100)/p_divisor;
           else
--              VPORCENTAJE_CALCULADO := (vporcentaje_honorario + VINC_LATERALIDAD)/p_divisor;    
              VPORCENTAJE_CALCULADO := vporcentaje_honorario + (vporcentaje_honorario*VINC_LATERALIDAD)/100;
           end if;              
        ELSIF P_CASO = 8 THEN                                                                                      
        -- Si existe más de un  procedimiento y es realizado por más de un  especialista,
        -- sin importar la via de acceso, la remuneración del procedimiento màs costos se mantiene para cada especialista
        -- y la remuenración de los otros procedimientos se paga  el 50 y el 25% del costo
           vporcentaje_honorario:=10; -- para las demás ayudantías se reconocerá el 10%
           IF P_CONDICION = 1 THEN
              VPORCENTAJE_CALCULADO := 10 ;              
           ELSIF P_CONDICION = 2 THEN
              vporcentaje_honorario:= (vporcentaje_honorario*50)/100; 
              VPORCENTAJE_CALCULADO :=((vporcentaje_honorario*(vporcentaje_honorario/p_divisor))/vporcentaje_honorario)/ p_divisor;
           ELSE   
              vporcentaje_honorario:= (vporcentaje_honorario*(25 + VINC_LATERALIDAD))/100;                         
              VPORCENTAJE_CALCULADO := ((vporcentaje_honorario*(vporcentaje_honorario/p_divisor))/vporcentaje_honorario)/ p_divisor;
          END IF;       
        ELSIF P_CASO = 10 THEN                                                                                      
        -- Si existe más de un  procedimiento y es realizado por más de un  especialista,
        -- sin importar la via de acceso, la remuneración del procedimiento màs costos se mantiene para cada especialista
        -- y la remuenración de los otros procedimientos se paga  el 50 y el 25% del costo
           vporcentaje_honorario:=20; -- para las demás ayudantías se reconocerá el 10%
           IF P_CONDICION = 1 THEN
              VPORCENTAJE_CALCULADO := 20 ;              
           ELSIF P_CONDICION = 2 THEN
              vporcentaje_honorario:= (vporcentaje_honorario*50)/100; 
              VPORCENTAJE_CALCULADO :=((vporcentaje_honorario*(vporcentaje_honorario/p_divisor))/vporcentaje_honorario)/ p_divisor;
           ELSE   
              vporcentaje_honorario:= (vporcentaje_honorario*(25 + VINC_LATERALIDAD))/100;                         
              VPORCENTAJE_CALCULADO := ((vporcentaje_honorario*(vporcentaje_honorario/p_divisor))/vporcentaje_honorario)/ p_divisor;
          END IF;                 
        END IF;                                                                  
     EXCEPTION
     WHEN OTHERS THEN
        RAISE SIN_TIPO_REMUNERACION;
     END;
     qms$errors.show_debug_info('El porcentaje de honorario es '||TO_CHAR(vporcentaje_honorario));    
     qms$errors.show_debug_info('El procedimiento hospitalario es '||P_PRCHSP_CODIGO);         
     DBMS_OUTPUT.put_line('El porcentaje de honorario es '||TO_CHAR(vporcentaje_honorario));    
     DBMS_OUTPUT.put_line('El procedimiento hospitalario es '||P_PRCHSP_CODIGO);              
     if VPORCENTAJE_CALCULADO = 1000 THEN
        BEGIN
        VPORCENTAJE_CALCULADO:=100;
        SELECT PUNTOS,UVR INTO vpuntos,vuvr
        FROM PROCEDIMIENTOS_HOSPITALARIOS
        WHERE CODIGO = '090285';
        IF  VPUNTOS>0 AND VUVR >0 THEN
        --redondeamos a 2 decimales hecho por JUAN CABRERA
           VVALOR_HONORARIO := round(vpuntos*vuvr,2);    
        ELSIF VPUNTOS<= 0 THEN
           RAISE HONORARIO_SIN_PUNTOS;  
        END IF;        
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
           VVALOR_HONORARIO :=0;  
   --        WHEN OTHERS THEN
   --        RAISE SIN_PROCEDIMIENTO;
        END;      
     ELSE
     BEGIN
        IF P_TIPO_REMUNERACION <> 'HOA' THEN
           BEGIN
              SELECT CT.uvr,CT.prc INTO vpuntos,vuvr
              FROM CONVENIOS_TARIFARIOS CT
              WHERE CT.codigo = VCODIGO_ITEM AND
                    CT.tipo = VTIPO AND
                    CT.convenio = VCONVENIO;                 
              IF VPORCENTAJE_CALCULADO > 0  AND VPUNTOS>0 AND VUVR >0 THEN
              --redondeamos a 2 decimales hecho por JUAN CABRERA
                 VVALOR_HONORARIO := round(vpuntos*vuvr*VPORCENTAJE_CALCULADO/100,2);    
              ELSIF VPUNTOS<= 0 THEN
                 RAISE HONORARIO_SIN_PUNTOS;  
              END IF;        
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
               RAISE HONORARIO_SIN_PUNTOS;  
           WHEN OTHERS THEN 
              RAISE HONORARIO_SIN_PUNTOS;  
           END;
        ELSE -- Si son honorarios de anestesiologos toma el UVR de anestesiologia,
             -- el precio de anestesiología  y revisa las variantes del mismo
            BEGIN
              VPORCENTAJE_CALCULADO := vporcentaje_honorario;
              BEGIN
              SELECT CTA.uvr_anes,CTA.prc_anes,CTA.no_aplica_tiempo INTO vpuntos,vuvr,VNOAPLICA_TIEMPO
              FROM CONVENIOS_TARIFARIOS CTA
              WHERE CTA.codigo = VCODIGO_ITEM AND
                    CTA.tipo = VTIPO AND
                    CTA.convenio = VCONVENIO; 
              EXCEPTION
              WHEN OTHERS THEN 
                 RAISE HONORARIO_SIN_PUNTOS;      
              END;       
              IF P_CASO = 7 THEN
                 VPUNTOS := 5;
              END IF;
              IF VNOAPLICA_TIEMPO = 'F' THEN
                 qms$errors.show_debug_info('El tiempo de duración es : '||to_char(P_DURACION));                                   
                 VPUNTOS_TIEMPO:= TRUNC(P_DURACION/15);
                 IF  P_DURACION/15 - VPUNTOS_TIEMPO >= 0.4 THEN
                    VPUNTOS_TIEMPO := VPUNTOS_TIEMPO +1;
                 END IF;                      
              ELSE   
                 VPUNTOS_TIEMPO:=0;
              END IF;   
                 qms$errors.show_debug_info('El total de puntos por anestesiología es: '||to_char(VPUNTOS_TIEMPO));                                                 IF P_DOCUMENTO = 'O' THEN -- SI ES CIRUGIA CONSIDERA LAS CONDICIONES DE REGISTRO OPERATORIO
              BEGIN
                 SELECT R.CONDICION_CLINICA,R.CIRCUNSTANCIA_CALIFICANTE INTO VCONDICION_CLINICA,VCONDICION_EDAD
                 FROM REGISTROS_OPERATORIOS R
                 WHERE R.PRTOPRSLC_NUMERO = P_NUMERO;   
              EXCEPTION
              WHEN NO_DATA_FOUND THEN 
                 VPUNTOS_CONDICION :=0;
                 VPUNTOS_EDAD :=0;   
              END;        
              ELSE --CONSIDERA LAS CONDICIONES DEL PROCEDIMIENTO MENOR
              BEGIN
                 SELECT DISTINCT I.CONDICION_CLINICA,I.CIRCUNSTANCIA_CALIFICANTE INTO VCONDICION_CLINICA,VCONDICION_EDAD
                 FROM INTERCONSULTAS I,PROCEDIMIENTOS_REALIZADOS PR
                 WHERE I.NUMERO = PR.NUMERO AND
                       PR.NUMERO = P_NUMERO;  -- REVISAR EN PANTALLA DE INTERCONSULTAS DE BETO
              EXCEPTION
              WHEN NO_DATA_FOUND THEN 
                  VPUNTOS_CONDICION :=0;
                  VPUNTOS_EDAD :=0;   
              END;
              END IF;
              IF VCONDICION_CLINICA IS NOT NULL THEN
                 SELECT TO_NUMBER(C.RV_HIGH_VALUE) INTO VPUNTOS_CONDICION
                 FROM CG_REF_CODES C
                 WHERE C.RV_DOMAIN = 'CONDICION_CLINICA' AND
                       C.RV_LOW_VALUE = VCONDICION_CLINICA ;
              END IF;
              IF VCONDICION_EDAD IS NOT NULL THEN
                 SELECT TO_NUMBER(C.RV_HIGH_VALUE) INTO VPUNTOS_EDAD
                 FROM CG_REF_CODES C
                 WHERE C.RV_DOMAIN = 'CIRCUNSTANCIA_CALIFICANTE' AND
                       C.RV_LOW_VALUE = VCONDICION_EDAD;
              END IF;
              IF VPORCENTAJE_CALCULADO > 0  AND VPUNTOS>0 AND VUVR >0 THEN
              --redondeamos a 2 decimales hecho por JUAN CABRERA
              VPUNTOS:=vpuntos+VPUNTOS_CONDICION+VPUNTOS_EDAD;
              VVALOR_HONORARIO := (VPUNTOS_TIEMPO*vvalor_tiempo)+round(VPUNTOS*vuvr*VPORCENTAJE_CALCULADO/100,2);    
              ELSIF vpuntos <= 0 THEN
                 RAISE HONORARIO_SIN_PUNTOS;  
              END IF;
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
               RAISE HONORARIO_SIN_PUNTOS;  
           WHEN OTHERS THEN 
              RAISE HONORARIO_SIN_PUNTOS;  
           END;      
        END IF;
     END;   
     END IF;
     qms$errors.show_debug_info('Los puntos y UVR  y el valor del honorario es:'||TO_CHAR(vpuntos)||to_char(vuvr)||to_char(vvalor_honorario));              
     dbms_output.put_line('Los puntos y UVR  y el valor del honorario es:'||TO_CHAR(vpuntos)||to_char(vuvr)||to_char(vvalor_honorario));                   
  end if;                
  END;                 
  BEGIN  -- Se obtiene el beneficiario del honorario.
     IF VBENEFICIARIO IS NOT NULL THEN
     qms$errors.show_debug_info('El beneficiario inicial es: '||P_BENEFICIARIO);                                   
     BEGIN   
        SELECT MSTBNF_CODIGO,CODIGO INTO VMSTBNF_CODIGO,VENTBNF_CODIGO        
        FROM ENTIDADES_BENEFICIARIAS
        WHERE PRS_CODIGO = VBENEFICIARIO;
     EXCEPTION   
     WHEN NO_DATA_FOUND THEN
        RAISE SIN_BENEFICIARIO;         
     WHEN OTHERS THEN
        RAISE SIN_BENEFICIARIO;   
     END;  
     END IF;
  END;      
qms$errors.show_debug_info('El beneficiario es :'||VMSTBNF_CODIGO||to_char(VENTBNF_CODIGO));                                   
qms$errors.show_debug_info('p_ins_or_upd '||p_ins_or_del);
qms$errors.show_debug_info('HC/doc/num/detalle '||p_PCN_NUMERO_HC||' '||p_DOCUMENTO||' '||p_NUMERO||' '||p_ID);
qms$errors.show_debug_info('Tipo rem/porcentaje '||p_tipo_remuneracion||' '||to_char(vporcentaje_honorario));
qms$errors.show_debug_info('crg '||vcrg_tipo||vcrg_codigo);
qms$errors.show_debug_info('CANTIDAD '||TO_CHAR(P_cANTIDAD));
qms$errors.show_debug_info('PORCENTAJE PROMOCION '||TO_CHAR(nPorcentaje_Promocion));  
QMS$ERRORS.SHOW_DEBUG_INFO('VPORCENTAJE_CALCULADO '||TO_CHAR(VPORCENTAJE_CALCULADO));
QMS$ERRORS.SHOW_DEBUG_INFO('nPorcentaje_Promocion '||TO_CHAR(nPorcentaje_Promocion));
--DBMS_OUTPUT.put_line('El caso es :'||to_char(P_CASO)); 
--DBMS_OUTPUT.put_line('La condicion es  :'||to_char(P_CONDICION));                                                                     
DBMS_OUTPUT.put_line('El beneficiario es :'||VMSTBNF_CODIGO||to_char(VENTBNF_CODIGO));                                   
DBMS_OUTPUT.put_line('p_ins_or_upd '||p_ins_or_del);
DBMS_OUTPUT.put_line('HC/doc/num/detalle '||p_PCN_NUMERO_HC||' '||p_DOCUMENTO||' '||p_NUMERO||' '||p_ID);
DBMS_OUTPUT.put_line('Tipo rem/porcentaje '||p_tipo_remuneracion||' '||to_char(vporcentaje_honorario));
DBMS_OUTPUT.put_line('crg '||vcrg_tipo||vcrg_codigo);
DBMS_OUTPUT.put_line('CANTIDAD '||TO_CHAR(P_cANTIDAD));
DBMS_OUTPUT.put_line('PORCENTAJE PROMOCION '||TO_CHAR(nPorcentaje_Promocion));  
DBMS_OUTPUT.put_line('VPORCENTAJE_CALCULADO '||TO_CHAR(VPORCENTAJE_CALCULADO));
DBMS_OUTPUT.put_line('nPorcentaje_Promocion '||TO_CHAR(nPorcentaje_Promocion));
DBMS_OUTPUT.put_line('Promocion '||vPrmPcn);
DBMS_OUTPUT.put_line('Puntos '||TO_CHAR(vpuntos));
DBMS_OUTPUT.put_line('UVR'||TO_CHAR(vuvr));

  IF p_ins_or_DEL = 'I'  THEN  
--     BEGIN
     IF NVL(P_POOL,0) = 0 THEN 
       INSERT INTO HONORARIOS_MEDICOS 
       (NUMERO,DOCUMENTO,ID,HJAEVL_NUMERO,TIPO_HONORARIO,CRG_TIPO,CRG_CODIGO,
       PRCHSP_CODIGO,CANTIDAD,FECHA,PUNTOS,PUNTOS_AUDITORIA,UVR,PORCENTAJE,PORCENTAJE_AUDITORIA,
       PORCENTAJE_CALCULADO,PORCENTAJE_PROMOCION,VALOR,VALOR_AUDITORIA,ESTADO,ESTADO_AUDITORIA,PLNHNR_NUMERO,
       ENTBNF_CODIGO,ENTBNF_MSTBNF_CODIGO,PCN_NUMERO_HC,PRM_CODIGO,CREADO_POR,DPR_ARA_CODIGO,DPR_CODIGO)
       VALUES
         (p_NUMERO,p_DOCUMENTO,p_ID,P_EVLCLN,P_TIPO_REMUNERACION,
          VCRG_TIPO,VCRG_CODIGO,P_PRCHSP_CODIGO,P_CANTIDAD,dFECHA,vpuntos,vpuntos,vuvr,
          vporcentaje_honorario,VPORCENTAJE_CALCULADO,VPORCENTAJE_CALCULADO,
          nPorcentaje_Promocion,VVALOR_HONORARIO,VVALOR_HONORARIO,NVL(VESTADO_GENERAR_I,'PND'),
          NVL(VESTADO_AUDITORIA_I,'N'),NPLANILLA,VENTBNF_CODIGO,VMSTBNF_CODIGO,P_PCN_NUMERO_HC,
          vPrmPcn,USER,P_AREA,P_DEPARTAMENTO);
     ELSE
       INSERT INTO HONORARIOS_MEDICOS 
       (NUMERO,DOCUMENTO,ID,HJAEVL_NUMERO,TIPO_HONORARIO,CRG_TIPO,CRG_CODIGO,
       PRCHSP_CODIGO,CANTIDAD,FECHA,PUNTOS,PUNTOS_AUDITORIA,UVR,PORCENTAJE,PORCENTAJE_AUDITORIA,
       PORCENTAJE_CALCULADO,PORCENTAJE_PROMOCION,VALOR,VALOR_AUDITORIA,ESTADO,ESTADO_AUDITORIA,PLNHNR_NUMERO,
       ENTBNF_CODIGO,ENTBNF_MSTBNF_CODIGO,PCN_NUMERO_HC,PRM_CODIGO,CREADO_POR,
       ENTBNF_CODIGO_GRUPAL,ENTBNF_MSTBNF_GRUPAL,DPR_ARA_CODIGO,DPR_CODIGO)
       VALUES
         (p_NUMERO,p_DOCUMENTO,p_ID,P_EVLCLN,P_TIPO_REMUNERACION,
          VCRG_TIPO,VCRG_CODIGO,P_PRCHSP_CODIGO,P_CANTIDAD,dFECHA,vpuntos,vpuntos,vuvr,
          vporcentaje_honorario,VPORCENTAJE_CALCULADO,VPORCENTAJE_CALCULADO,
          nPorcentaje_Promocion,VVALOR_HONORARIO,VVALOR_HONORARIO,NVL(VESTADO_GENERAR_I,'PND'),
          NVL(VESTADO_AUDITORIA_I,'N'),NPLANILLA,VENTBNF_CODIGO,VMSTBNF_CODIGO,P_PCN_NUMERO_HC,
          vPrmPcn,USER,P_POOL,'POO',P_AREA,P_DEPARTAMENTO);     
     END IF;          
       CARGAR_CUENTA_TRF(P_PCN_NUMERO_HC,P_AREA,P_DEPARTAMENTO,P_EMP_CODIGO,P_DOCUMENTO,P_NUMERO,P_ID); 
  --   EXCEPTION
  --   WHEN OTHERS THEN
  --      RAISE ERROR_CREAR_HONORARIO;                         
  --   END;                  
  ELSIF p_ins_or_DEL = 'D' THEN
-- Si se elimina el procedimiento que generó el honorario, se elimina tambien el honorario médico generado
-- y si el honorario ya fue planillado se elimina también de la cuenta y de la planilla.        
  QMS$ERRORS.SHOW_DEBUG_INFO('Entra a reversar los honorarios médicos con id'||to_Char(p_ID));
  QMS$ERRORS.SHOW_DEBUG_INFO('El tipo de honorario es '||P_TIPO_REMUNERACION);    
  BEGIN
    SELECT HM.ESTADO, HM.ESTADO_AUDITORIA, HM.PLNHNR_NUMERO,HM.CRG_TIPO,HM.CRG_CODIGO INTO VESTADO_GENERAR,VESTADO_AUDITORIA,
           NPLANILLA,VCRG_TIPO,VCRG_CODIGO
    FROM HONORARIOS_MEDICOS HM
    WHERE documento=p_Documento AND numero=p_Numero AND ID=p_ID AND ESTADO <> 'ANL' AND
          TIPO_HONORARIO = P_TIPO_REMUNERACION AND
          PCN_NUMERO_HC = P_PCN_NUMERO_HC;                                  
    QMS$ERRORS.SHOW_DEBUG_INFO('Obtuvo los datos para  reversar los honorarios médicos ');           
    IF  NPLANILLA IS NULL  OR  (NPLANILLA IS NOT NULL AND NVL(GENERA_PLANILLA,'F') = 'F') THEN    
       IF VESTADO_GENERAR IN ('PLN','PND')  THEN    
       BEGIN
       DELETE FROM HONORARIOS_MEDICOS H
       WHERE H.documento=p_Documento AND 
             H.numero=p_Numero AND 
             H.ID=p_ID AND
             H.PCN_NUMERO_HC = P_PCN_NUMERO_HC;             
       EXCEPTION
       WHEN OTHERS THEN
           RAISE HONORARIO_NO_GENERADO;      
       END;      
       BEGIN     
       IF VCRG_TIPO IS NOT NULL AND VCRG_CODIGO IS NOT NULL  AND VESTADO_AUDITORIA = 'A' THEN -- si se cargó a la cuenta se anula de la cuenta.
          BEGIN      
          SELECT DISTINCT C.ESTADO INTO VESTADO_CUENTA
          FROM CUENTAS C
          WHERE C.documento=p_Documento AND C.numero=p_Numero AND C.detalle=p_ID AND
                C.PCN_NUMERO_HC = P_PCN_NUMERO_HC;
          IF VESTADO_CUENTA = 'PND' THEN
             DELETE FROM  CUENTAS
             WHERE documento=p_Documento AND 
                   numero=p_Numero AND 
                   detalle=p_ID AND 
                   PCN_NUMERO_HC = P_PCN_NUMERO_HC AND
                   estado = 'PND';         
          ELSE         
             RAISE YA_FACTURADO; 
          END IF;         
          EXCEPTION
          WHEN OTHERS THEN
             NULL;
          END;
       END IF;
       END;
       END IF;
    ELSIF  NPLANILLA IS NOT NULL AND GENERA_PLANILLA = 'V'  THEN       
       RAISE EXISTE_PLANILLA; 
    END IF;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
      RAISE HONORARIO_NO_GENERADO;
  END;    
  END IF;
EXCEPTION
  WHEN PACIENTE_SIN_PROMOCION THEN
     RAISE_APPLICATION_ERROR(-20210,'Honorario no insertada/anulado. El paciente '||p_PCN_NUMERO_HC||' no tiene promoción asociada ');
  WHEN CARGO_NO_EXISTENTE THEN
     RAISE_APPLICATION_ERROR(-20211,'Honorario no insertada/anulado. El cargo con codigo '||vcrg_Codigo||' no existe ');
  WHEN YA_FACTURADO THEN
     RAISE_APPLICATION_ERROR(-20212,'No se puede eliminar si el honorario ya fue facturado o fue anulado ');
  WHEN SIN_PROCEDIMIENTO THEN                                                          
     RAISE_APPLICATION_ERROR(-20213,'No se puede registrar honorarios si no hay un procedimiento hospitalario ');
  WHEN SIN_TIPO_REMUNERACION THEN                                                     
     RAISE_APPLICATION_ERROR(-20214,'No se puede registrar honorarios sin un tipo de remuneración ');
  WHEN SIN_BENEFICIARIO THEN                                                          
     RAISE_APPLICATION_ERROR(-20215,'No se puede registrar honorarios sin un beneficiario en Caja Médica, cominicarse con Auditoría Médica ');
  WHEN HONORARIO_NO_EXISTENTE THEN                                                          
     RAISE_APPLICATION_ERROR(-20216,'El honorario que se quiere eliminar no existe ');      
  WHEN ERROR_HONORARIOS THEN
     RAISE_APPLICATION_ERROR(-20217,'Existe más de un cargo creado con el tipo HNR Honorarios Médicos '||VCRG_TIPO||VCRG_CODIGO||' '||VCODIGO_ITEM);           
  WHEN HONORARIO_SIN_PUNTOS THEN
     RAISE_APPLICATION_ERROR(-20218,'El procedimiento realizado no tiene fijado un valor por honorarios');    
  WHEN ERROR_CREAR_HONORARIO THEN
   RAISE_APPLICATION_ERROR(-20219,'El honorario no pudo ser insertado en la cuenta del paciente '||sqlerrm);        
  WHEN HONORARIO_NO_GENERADO THEN  
     RAISE_APPLICATION_ERROR(-20220,'No se pudo revertir ya que el honorario no está generado');      
  WHEN EXISTE_PLANILLA THEN  
     RAISE_APPLICATION_ERROR(-20221,'No se puede revertir el honorario si existe una cuenta\planilla generada en Caja Médica');           
  WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20222,'El honorario no pudo ser insertado/actualizado por el error '||P_POOL||' '||SQLERRM);
END;
/* Genera los honorarios médicos de acuerdo a los proceidmientos realizad */
PROCEDURE CARGAR_HONORARIO_POR_PROC_TRF
 (P_NUMPARTE IN NUMBER
 ,P_DOCUMENTO IN CUENTAS.DOCUMENTO%TYPE
 ,P_PCN_NUMERO_HC IN CUENTAS.PCN_NUMERO_HC%TYPE
 ,P_BENEFICIARIO IN PERSONAL.CODIGO%TYPE := NULL
 ,P_FECHA IN DATE 
 ,P_TIPO_REMUNERACION IN VARCHAR2 := 'HNR'
 ,P_EVLCLN IN HOJAS_DE_EVOLUCION.NUMERO%TYPE
 ,P_INS_OR_DEL IN VARCHAR2
 ,P_POOL IN NUMBER := 0
 ,P_DURACION IN NUMBER:=0
 ,P_AREA IN VARCHAR2
 ,P_DEPARTAMENTO IN VARCHAR2
 ,P_EMP_CODIGO IN CHAR  
 )
 IS

NCONT NUMBER(3) := 0;
NPROCED NUMBER := 1;
VTIPO_REM VARCHAR2(240);
NDIVISOR NUMBER(2);
VFUNCION VARCHAR2(2);
NCASO NUMBER := 4;
GENERA_PLANILLA CHAR;
--CASO via de acceso 
--1 igual via de acceso un profesional
--2  diferente via de acceso un profesional
--3 más de un profesional en varios procedimientos misma via de acceso
--4 mas de un profesional en un solo procedimiento
--5 recepción del recien nacido
--6 Honorarios un Anestesiólogo 
--7 Honorarios más de un Anestesiólogo
--8 Honoarios de más de un ayudante
--9 más de un profesional en varios procedimientos diferente via de acceso

--CONDICION  más de un procedimiento 

-- 1 el procedimiento principal con puntaje mayor;
-- 2 el segundo procedimiento principal  puntaje menor;
-- 3 el tercer procedimiento  con puntaje menor

cursor proc is  -- Procedimientos que se ha realizado al paciente;
select PR.PRCHSP_CODIGO prchsp_codigo,C.uvr PUNTOS,C.uvr_anes PUNTOS_ANE,
       PR.NUMERO_DE_VECES cantidad,PR.LATERALIDAD LATERALIDAD,
       PR.VIA_DE_ACCESO VIA_ACCESO,0 CASO,0 CONDICION
from PROCEDIMIENTOS_REALIZADOS PR,PROCEDIMIENTOS_HOSPITALARIOS PH,CONVENIOS_TARIFARIOS C 
WHERE PH.CODIGO = PR.PRCHSP_CODIGO AND 
      EPC_PRMATN_PCN_NUMERO_HC = P_PCN_NUMERO_HC AND
      ((PRTOPRSLC_NUMERO = P_NUMPARTE AND P_DOCUMENTO = 'O') OR 
       (PRCMNR_NUMERO = P_NUMPARTE AND P_DOCUMENTO = 'G') OR 
       (INTCNS_NUMERO = P_NUMPARTE AND P_DOCUMENTO = 'R')) AND 
      PH.CODIGO_TARIFARIO = C.codigo AND
      PH.CONVENIO = C.convenio AND
      PH.TRF_TIPO = C.tipo
ORDER BY C.uvr DESC,PR.VIA_DE_ACCESO;
TYPE PROCTABTYP IS TABLE OF PROC%ROWTYPE INDEX BY BINARY_INTEGER;
PROC_TAB PROCTABTYP;
i BINARY_INTEGER := 0;                   
J BINARY_INTEGER := 0;
k BINARY_INTEGER := 0;    
L BINARY_INTEGER := 0;           
CURSOR equipo (VGENERA_PLANILLA CHAR) is  -- Equipo operatorio que ha realizado el o los proceidmientos quirúrgicos 
  select e.prs_codigo,e.funcion,e.pool
  from equipos_operatorios e
  where e.prtoprslc_pcn_numero_hc = P_PCN_NUMERO_HC and  
        e.prtoprslc_numero = P_NUMPARTE AND
        (e.pagar = 'V' OR (e.pagar = 'V' AND VGENERA_PLANILLA = 'V') OR ((e.pagar = 'F' AND VGENERA_PLANILLA = 'F'))) AND        
        P_DOCUMENTO = 'O' AND
        E.FUNCION IN ('CJ','AN','AY')
  order by e.funcion DESC; 
CURSOR equipo1(VGENERA_PLANILLA CHAR)  is  -- Equipo operatorio que ha realizado el o los proceidmientos quirúrgicos 
  select e.prs_codigo,e.funcion,e.pool
  from equipos_operatorios e
  where e.prtoprslc_pcn_numero_hc = P_PCN_NUMERO_HC and  
        e.prtoprslc_numero = P_NUMPARTE AND
        (e.pagar = 'V' OR (e.pagar = 'V' AND VGENERA_PLANILLA = 'V') OR ((e.pagar = 'F' AND VGENERA_PLANILLA = 'F'))) AND        
        P_DOCUMENTO = 'O' AND
        E.FUNCION IN ('CJ','AN','AY')        
  order by e.funcion DESC;   
  TYPE EQUIPOTABTYP IS TABLE OF EQUIPO%ROWTYPE INDEX BY BINARY_INTEGER;  
  EQUIPO_TAB EQUIPOTABTYP;
  SIN_PROCEDIMIENTO EXCEPTION;    
  SIN_TIPO_REMUNERACION EXCEPTION;
BEGIN
-- Primero verifico si es un solo procedimiento o varios.
   QMS$ERRORS.SHOW_DEBUG_INFO('El parte es: '|| to_Char(P_NUMPARTE));   
   QMS$ERRORS.SHOW_DEBUG_INFO('La fecha del parte es ' ||to_char(P_FECHA,'DD/MM/YYYY')); 
--   DBMS_OUTPUT.put_line('La fecha del parte es ' ||to_char(P_FECHA,'DD/MM/YYYY'));
   BEGIN -- VERIFICA SI LA EMPRESA GENERA O NO PLANILLAS PARA LOS HONORARIOS DEL MSP
     SELECT P.VALOR INTO GENERA_PLANILLA 
     FROM PARAMETROS_EMPRESAS P
     WHERE P.PRMAPL_NOMBRE = 'EMITIR_PLANILLAS_CAJA_MEDICA' 
           AND P.EMP_CODIGO = P_EMP_CODIGO;
   EXCEPTION     
   WHEN OTHERS THEN
     GENERA_PLANILLA := 'F';
   END;   
   BEGIN
      SELECT COUNT(*) INTO nproced
      FROM PROCEDIMIENTOS_REALIZADOS
      WHERE EPC_PRMATN_PCN_NUMERO_HC = P_PCN_NUMERO_HC AND
            ((PRTOPRSLC_NUMERO = P_NUMPARTE AND P_DOCUMENTO = 'O') OR 
              (PRCMNR_NUMERO = P_NUMPARTE AND P_DOCUMENTO = 'G') OR 
              (INTCNS_NUMERO = P_NUMPARTE AND P_DOCUMENTO = 'R')); 
      EXCEPTION 
      WHEN OTHERS THEN
      RAISE SIN_PROCEDIMIENTO;
   END;     
   QMS$ERRORS.SHOW_DEBUG_INFO('*******************************************************************');
   QMS$ERRORS.SHOW_DEBUG_INFO('Está en el proceso para generar honorarios con los siguientes parámetros');
   QMS$ERRORS.SHOW_DEBUG_INFO('Número de procedimiento, documento '||to_char(P_NUMPARTE)||P_DOCUMENTO);
   QMS$ERRORS.SHOW_DEBUG_INFO('Historia clínica '||to_char(P_PCN_NUMERO_HC));
   QMS$ERRORS.SHOW_DEBUG_INFO('Beneficiario '||P_BENEFICIARIO);
   QMS$ERRORS.SHOW_DEBUG_INFO('Fecha '||P_FECHA);
   QMS$ERRORS.SHOW_DEBUG_INFO('Tipo rem.'||P_TIPO_REMUNERACION);
   QMS$ERRORS.SHOW_DEBUG_INFO('Evolución '||to_char(P_EVLCLN));
   NCONT := 1;  
   QMS$ERRORS.SHOW_DEBUG_INFO('El número de procedimientos es :' ||to_char(nproced)||'*************');
   -- Si se trata de varios procedimientos, se verifica si es son procedimietos quirúrgicos o procedimientos menores   
   --DBMS_OUTPUT.PUT_LINE('VA A COMPARAR EL NÚMERO DE PROCEDIMIENTOS');
   QMS$ERRORS.SHOW_DEBUG_INFO('El tipo de Remuneración es '||NVL(VTIPO_REM,'HNR'));   
   VTIPO_REM := NVL(P_TIPO_REMUNERACION,'HNR');
   QMS$ERRORS.SHOW_DEBUG_INFO('El tipo de Remuneración es '||VTIPO_REM);   
   IF nproced > 1 then   -- Se trata de varios procedimientos        
      QMS$ERRORS.SHOW_DEBUG_INFO('Existe más de un procedimiento');   
      DBMS_OUTPUT.PUT_LINE('Existe más de un procedimiento');
      OPEN PROC; 
      LOOP
         i := i + 1;
         FETCH PROC INTO PROC_TAB(i);
         EXIT WHEN PROC%NOTFOUND;         
      END LOOP;   
      i:= i-1;                 
      CLOSE PROC;
      PROC_TAB(1).CASO := 2;        -- incia siempre como si fuera diferente via de acceso un solo profesional
      PROC_TAB(1).CONDICION := 1;   -- incia siempre como si fuera el procedimiento principal con puntaje mayor;
      QMS$ERRORS.SHOW_DEBUG_INFO('Carga el proceso '||to_Char(1)||' con valores iniciales');   
      QMS$ERRORS.SHOW_DEBUG_INFO('El valor total de i es  '||to_Char(i));                     
      FOR L IN 2..I LOOP
            QMS$ERRORS.SHOW_DEBUG_INFO('Revisa los procedimientos para poner el caso');            
            IF PROC_TAB(L).PRCHSP_CODIGO <> PROC_TAB(L-1).PRCHSP_CODIGO THEN
               IF NVL(PROC_TAB(L).VIA_ACCESO,'OTRA') = NVL(PROC_TAB(1).VIA_ACCESO,'OTRA') THEN
                  PROC_TAB(L).CASO := 1;  -- Tiene la misma via de acceso el cobro es en proporción
                  PROC_TAB(L-1).CASO := 1;
               IF PROC_TAB(L).PUNTOS <= PROC_TAB(L-1).PUNTOS  AND L=2 THEN
                  PROC_TAB(L).CONDICION := 2;  -- El procedimiento tiene puntaje menor al procedimiento principal y cobra el 50% 
               ELSIF PROC_TAB(L).PUNTOS <= PROC_TAB(L-1).PUNTOS  AND L>2 THEN
                  PROC_TAB(L).CONDICION := 3;  -- El procedimiento tiene puntaje menor al procedimiento principal y cobra el 25%                  
               END IF;                                                   
               ELSE   
                  PROC_TAB(L).CASO := 2;  -- Tiene diferente via de acceso el cobro es el 100%
                  PROC_TAB(L).CONDICION := 1;
               END IF;                                             
               QMS$ERRORS.SHOW_DEBUG_INFO('Cargado el proceso '||to_Char(l)||' con caso y condicion');                              
            END IF;                                                            
      END LOOP;   
      FOR J IN 1..I LOOP  
      --Una vez fijado el caso y la condicion de los  procedimientos
      --se generan los honorarios de acuerdo al beneficiario.          
         IF P_DOCUMENTO = 'O' THEN -- Se carga honorarios por procedimientos quirúrgicos                                    
            OPEN EQUIPO(GENERA_PLANILLA); 
            LOOP
               k:=k + 1;           
               QMS$ERRORS.SHOW_DEBUG_INFO('***REVISION  DEL  EQUIPO OPERATORIO ****  '||TO_CHAR(K));                                                                                
               FETCH EQUIPO INTO EQUIPO_TAB(k);
               EXIT WHEN EQUIPO%NOTFOUND;   
               IF EQUIPO_TAB(k).PRS_CODIGO IS NOT NULL AND EQUIPO_TAB(k).FUNCION IS NOT NULL THEN
                  FOR REQUIPO IN EQUIPO1(GENERA_PLANILLA) LOOP
                  NDIVISOR:=1;
                     IF REQUIPO.PRS_CODIGO <> EQUIPO_TAB(k).PRS_CODIGO THEN
     --                   DBMS_OUTPUT.PUT_LINE('ES UNA PERSONA DIFERENTE'||' '||REQUIPO.PRS_CODIGO||' '||EQUIPO_TAB(k).PRS_CODIGO);
                        IF EQUIPO_TAB(k).FUNCION = REQUIPO.FUNCION  THEN
                           IF EQUIPO_TAB(k).FUNCION = 'AY' THEN
     --                         DBMS_OUTPUT.PUT_LINE('El valor de K es '||to_Char(k)||' '||'El tipo de honoriario es '||EQUIPO_TAB(k).FUNCION);
                              QMS$ERRORS.Show_debug_info('El valor de K es '||to_Char(k)||' '||'El tipo de honoriario es '||EQUIPO_TAB(k).FUNCION);
                              IF K>1 AND EQUIPO_TAB(k-1).FUNCION = EQUIPO_TAB(k).FUNCION THEN
                                 PROC_TAB(j).CASO := 8;  
     --                            DBMS_OUTPUT.PUT_LINE('ES AYUDANTIA Y SEGUNDO AYUDANTE');
                                 EXIT; 
                              ELSE
                                 PROC_TAB(j).CASO := 10;
                                 EXIT;
                              END IF;                           
                           ELSIF EQUIPO_TAB(k).FUNCION <> 'AN' AND  EQUIPO_TAB(k).FUNCION <> 'AY' THEN 
                        -- si se trata de más de un profesional en el mismo procedimiento se convierte
                        -- se convierte en caso 3 si es la misma via de acceso o en caso 9 si es otra via de acceso                                                      
                              IF PROC_TAB(J).CASO = 1 THEN
                                  PROC_TAB(j).CASO := 3;
                              ELSIF PROC_TAB(J).CASO = 2 THEN
                                  PROC_TAB(j).CASO := 9;                              
                              END IF;    
                              NDIVISOR:= NDIVISOR+1;                          
     --                         DBMS_OUTPUT.PUT_LINE('NO ES AYUDANTIA NI ANESTESIA PERO ES MAS DE UN PROFESIONAL');                              
     --                         DBMS_OUTPUT.PUT_LINE('Va a salir y continuar con el incremento de K');                                                            
                              EXIT;
                           ELSIF  EQUIPO_TAB(k).FUNCION = 'AN' THEN   
                              IF K>1 AND EQUIPO_TAB(k-1).FUNCION = 'AN' THEN                          
                                 PROC_TAB(j).CASO := 7; --se trata de mas de un anestesiologo                                                   
                                 DBMS_OUTPUT.PUT_LINE('ES ANESTESIA Y SE TRATA DE MAS DE UNO');                                                               
                                 EXIT;
                              END IF;  
                           END IF; 
                        ELSIF EQUIPO_TAB(k).FUNCION <> REQUIPO.FUNCION
                          AND EQUIPO_TAB(k).FUNCION = 'AN' THEN                             
                            PROC_TAB(j).CASO := 6;   -- UN SOLO ANESTESIOLOGO
      --                      DBMS_OUTPUT.PUT_LINE('ES ANESTESIA Y ES UN SOLO ANESTESIOLOGO');                                                                                              
                            EXIT;
                        END IF;    
                     END IF;                                             
                  END LOOP;                                                      
                  BEGIN                                        
                     vfuncion := EQUIPO_TAB(k).FUNCION;
                     QMS$ERRORS.SHOW_DEBUG_INFO('Va a buscar el tipo de remuneración para '||vfuncion);                                           
                     SELECT RV_ABBREVIATION INTO VTIPO_REM
                     FROM CG_REF_CODES
                     WHERE RV_DOMAIN = 'EQUIPOS_OPERATORIOS.FUNCION' AND
                           RV_LOW_VALUE = EQUIPO_TAB(k).FUNCION;               
                     QMS$ERRORS.SHOW_DEBUG_INFO('El tipo de remuneración es '||VTIPO_REM);                                                                 
                     DBMS_OUTPUT.put_line('EL TIPO DE REMUNERACION/CASO EN MAS DE UN PROCEDI. ES '||VTIPO_REM||' '||PROC_TAB(j).CASO);                                         
                     IF VTIPO_REM <> 'HOR' THEN
                        IF VTIPO_REM <> 'HOA' THEN
                           FCTCONTRF.CARGAR_HONORARIO_TRF(P_NUMPARTE,EQUIPO_TAB(k).PRS_CODIGO,NCONT,PROC_TAB(j).CANTIDAD,
                                                 P_DOCUMENTO,P_PCN_NUMERO_HC,P_INS_OR_DEL,P_FECHA,Vtipo_rem,P_EVLCLN,PROC_TAB(j).PRCHSP_CODIGO,
                                                 PROC_TAB(j).LATERALIDAD,PROC_TAB(j).CASO,PROC_TAB(j).CONDICION,NDIVISOR,EQUIPO_TAB(k).POOL,
                                                 P_DURACION,P_AREA,P_DEPARTAMENTO,P_EMP_CODIGO);
                           QMS$ERRORS.SHOW_DEBUG_INFO('Ingresó el honorario '||Vtipo_rem);                                           
                           NCONT:= NCONT+1;                       
                           QMS$ERRORS.SHOW_DEBUG_INFO('El contador es '||to_char(ncont));                                           
                        ELSIF VTIPO_REM = 'HOA' AND J = 1 THEN
                           FCTCONTRF.CARGAR_HONORARIO_TRF(P_NUMPARTE,EQUIPO_TAB(k).PRS_CODIGO,NCONT,PROC_TAB(j).CANTIDAD,
                                                 P_DOCUMENTO,P_PCN_NUMERO_HC,P_INS_OR_DEL,P_FECHA,Vtipo_rem,P_EVLCLN,PROC_TAB(j).PRCHSP_CODIGO,
                                                 PROC_TAB(J).LATERALIDAD,PROC_TAB(J).CASO,PROC_TAB(J).CONDICION,NDIVISOR,EQUIPO_TAB(k).POOL,
                                                 P_DURACION,P_AREA,P_DEPARTAMENTO,P_EMP_CODIGO);
                           QMS$ERRORS.SHOW_DEBUG_INFO('Ingresó el honorario '||Vtipo_rem);                                           
                           NCONT:= NCONT+1;                       
                           QMS$ERRORS.SHOW_DEBUG_INFO('El contador es '||to_char(ncont));                                                                   
                        END IF;   
                     ELSE
                        FCTCONTRF.CARGAR_HONORARIO_TRF(P_NUMPARTE,EQUIPO_TAB(k).PRS_CODIGO,NCONT,PROC_TAB(j).CANTIDAD,
                                              P_DOCUMENTO,P_PCN_NUMERO_HC,P_INS_OR_DEL,P_FECHA,Vtipo_rem,P_EVLCLN,
                                              PROC_TAB(j).PRCHSP_CODIGO,PROC_TAB(j).LATERALIDAD,5,1,1,EQUIPO_TAB(k).POOL,
                                              P_DURACION,P_AREA,P_DEPARTAMENTO,P_EMP_CODIGO);
                        NCONT:= NCONT+1;                       
                        QMS$ERRORS.SHOW_DEBUG_INFO('El contador es '||to_char(ncont));                                           
                        QMS$ERRORS.SHOW_DEBUG_INFO('Ingresó el honorario '||Vtipo_rem);                                                                                           
                        QMS$ERRORS.SHOW_DEBUG_INFO('-----------------------------------------------');  
                     END IF;   
                  EXCEPTION    
                  WHEN NO_DATA_FOUND THEN                
                     RAISE SIN_TIPO_REMUNERACION;                        
                  WHEN OTHERS THEN
                     RAISE_APPLICATION_ERROR(-20216,'No se pudor insertar/borrar el honorario del procedimiento quirúrgico'||SQLERRM);
                  END;                                        
               END IF;    
            END LOOP;
            CLOSE EQUIPO;
            QMS$ERRORS.SHOW_DEBUG_INFO('Se ha insertado el procedimiento '||to_char(j));                                                                
            k:=0;
         ELSE  -- Se carga honorarios por procedimientos menores o interconsultas     
            BEGIN   
               IF P_TIPO_REMUNERACION <> 'HOA' THEN
               QMS$ERRORS.Show_debug_info('***** Va a cargar**** '||to_char(P_NUMPARTE)||to_char(ncont)||P_DOCUMENTO);
               FCTCONTRF.CARGAR_HONORARIO_TRF(P_NUMPARTE,P_BENEFICIARIO,NCONT,PROC_TAB(j).CANTIDAD,
                                     P_DOCUMENTO,P_PCN_NUMERO_HC,P_INS_OR_DEL,P_FECHA,P_TIPO_REMUNERACION,P_EVLCLN,
                                     PROC_TAB(j).PRCHSP_CODIGO,PROC_TAB(j).LATERALIDAD,PROC_TAB(j).CASO,
                                     PROC_TAB(j).CONDICION,1,P_POOL,P_DURACION,P_AREA,P_DEPARTAMENTO,P_EMP_CODIGO);
               NCONT:= NCONT+1; 
               ELSIF P_TIPO_REMUNERACION = 'HOA'  AND J = 1 THEN
               QMS$ERRORS.Show_debug_info('***** Va a cargar**** '||to_char(P_NUMPARTE)||to_char(ncont)||P_DOCUMENTO);
               FCTCONTRF.CARGAR_HONORARIO_TRF(P_NUMPARTE,P_BENEFICIARIO,NCONT,PROC_TAB(j).CANTIDAD,
                                     P_DOCUMENTO,P_PCN_NUMERO_HC,P_INS_OR_DEL,P_FECHA,P_TIPO_REMUNERACION,P_EVLCLN,
                                     PROC_TAB(j).PRCHSP_CODIGO,PROC_TAB(j).LATERALIDAD,6,PROC_TAB(j).CONDICION,
                                     1,P_POOL,P_DURACION,P_AREA,P_DEPARTAMENTO,P_EMP_CODIGO);
               NCONT:= NCONT+1;                
               END IF;
           EXCEPTION                                                                            
            WHEN OTHERS THEN
               RAISE_APPLICATION_ERROR(-20216,'No se pudor insertar/borrar el honorario del procedimiento menor o interconsulta '||SQLERRM);
            END;
         END IF;
      END LOOP;   
   ELSIF nproced = 1 THEN   -- Un sólo procedimiento
--   DBMS_OUTPUT.PUT_LINE('UN SOLO PROCEDIMIENTO');
   QMS$ERRORS.Show_debug_info('UN SOLO PROCEDIMIENTO');
   FOR RPROC IN PROC LOOP      
      IF P_DOCUMENTO = 'O' THEN -- Se carga honorarios por procedimiento quirúrgico         OPEN EQUIPO;                                     
         OPEN EQUIPO(GENERA_PLANILLA);       
         LOOP
            k:=k + 1;    
            --DBMS_OUTPUT.put_line('EL VALOR DE K ES '||TO_CHAR(K));       
            QMS$ERRORS.Show_debug_info('EL VALOR DE K ES '||TO_CHAR(K));       
            FETCH EQUIPO INTO EQUIPO_TAB(k);
            EXIT WHEN EQUIPO%NOTFOUND;   
            IF EQUIPO_TAB(k).PRS_CODIGO IS NOT NULL AND EQUIPO_TAB(k).FUNCION IS NOT NULL THEN
               NDIVISOR:=1; 
               FOR REQUIPO IN EQUIPO1(GENERA_PLANILLA) LOOP
                 NCASO:=4;
                  IF REQUIPO.PRS_CODIGO <> EQUIPO_TAB(k).PRS_CODIGO THEN                  
--                        DBMS_OUTPUT.PUT_LINE('ES UNA PERSONA DIFERENTE'||' '||REQUIPO.PRS_CODIGO||' '||EQUIPO_TAB(k).PRS_CODIGO);
                        QMS$ERRORS.Show_debug_info ('ES UNA PERSONA DIFERENTE'||' '||REQUIPO.PRS_CODIGO||' '||EQUIPO_TAB(k).PRS_CODIGO);
                        IF EQUIPO_TAB(k).FUNCION = REQUIPO.FUNCION  THEN
                        -- si se trata de más de un profesional en el mismo procedimiento se convierte en caso 3                            
                           IF EQUIPO_TAB(k).FUNCION = 'AY' THEN
                              IF K>1 AND EQUIPO_TAB(k-1).FUNCION = EQUIPO_TAB(k).FUNCION THEN
                                 NCASO := 8;  
                                 --DBMS_OUTPUT.PUT_LINE('ES AYUDANTIA Y SEGUNDO AYUDANTE');
                                 QMS$ERRORS.Show_debug_info ('ES AYUDANTIA Y SEGUNDO AYUDANTE');
                                 EXIT; 
                              ELSE
                                NCASO:=10;
                              END IF;
                           ELSIF EQUIPO_TAB(k).FUNCION <> 'AN' AND  EQUIPO_TAB(k).FUNCION <> 'AY' THEN 
                              NCASO := 9;
                              NDIVISOR:= NDIVISOR+1;                          
                              DBMS_OUTPUT.PUT_LINE('NO ES AYUDANTIA NI ANESTESIA PERO ES MAS DE UN PROFESIONAL');                              
                              EXIT;
                           ELSIF  EQUIPO_TAB(k).FUNCION = 'AN' THEN   
                              IF K>1 AND EQUIPO_TAB(k-1).FUNCION = 'AN' THEN                          
                                 NCASO := 7; --se trata de mas de un anestesiologo                                                   
                                 DBMS_OUTPUT.PUT_LINE('ES ANESTESIA Y SE TRATA DE MAS DE UNO');                                                               
                                 EXIT;
                              END IF;  
                           END IF; 
                        ELSIF EQUIPO_TAB(k).FUNCION <> REQUIPO.FUNCION
                          AND EQUIPO_TAB(k).FUNCION = 'AN' THEN                             
                            NCASO := 6;   -- UN SOLO ANESTESIOLOGO
                            DBMS_OUTPUT.PUT_LINE('ES ANESTESIA Y ES UN SOLO ANESTESIOLOGO');                                                                                              
                            EXIT;
                        END IF;    
                  END IF;                                             
               END LOOP;                                                      
               BEGIN                                        
                  vfuncion := EQUIPO_TAB(k).FUNCION;                  
                  SELECT RV_ABBREVIATION INTO VTIPO_REM
                  FROM CG_REF_CODES
                  WHERE RV_DOMAIN = 'EQUIPOS_OPERATORIOS.FUNCION' AND
                        RV_LOW_VALUE = EQUIPO_TAB(k).FUNCION;             
                  QMS$ERRORS.SHOW_DEBUG_INFO('Va a cargar un procedimiento quirurgico');                          
                  QMS$ERRORS.SHOW_DEBUG_INFO('Se va a cargar el honorario/caso '||VTIPO_REM||to_char(ncaso));                                            
                  DBMS_OUTPUT.put_line('EL TIPO DE REMUNERACION/CASO ES '||VTIPO_REM||' '||TO_CHAR(NCASO));                    
                  IF VTIPO_REM <> 'HOR' THEN
                     IF VTIPO_REM <> 'HOA' THEN
                        FCTCONTRF.CARGAR_HONORARIO_TRF(P_NUMPARTE,EQUIPO_TAB(k).PRS_CODIGO,NCONT,RPROC.CANTIDAD,
                                              P_DOCUMENTO,P_PCN_NUMERO_HC,P_INS_OR_DEL,P_FECHA,Vtipo_rem,
                                              P_EVLCLN,RPROC.PRCHSP_CODIGO,RPROC.LATERALIDAD,NCASO,1,NDIVISOR,
                                              EQUIPO_TAB(k).POOL,P_DURACION,P_AREA,P_DEPARTAMENTO,P_EMP_CODIGO);
                        NCONT:= NCONT+1;                       
                     ELSIF VTIPO_REM = 'HOA' THEN
                        FCTCONTRF.CARGAR_HONORARIO_TRF(P_NUMPARTE,EQUIPO_TAB(k).PRS_CODIGO,NCONT,RPROC.CANTIDAD,
                                              P_DOCUMENTO,P_PCN_NUMERO_HC,P_INS_OR_DEL,P_FECHA,Vtipo_rem,
                                              P_EVLCLN,RPROC.PRCHSP_CODIGO,RPROC.LATERALIDAD,NCASO,1,1,
                                              EQUIPO_TAB(k).POOL,P_DURACION,P_AREA,P_DEPARTAMENTO,P_EMP_CODIGO);
                        NCONT:= NCONT+1;         
                     END IF;   
                  ELSE
                     FCTCONTRF.CARGAR_HONORARIO_TRF(P_NUMPARTE,EQUIPO_TAB(k).PRS_CODIGO,NCONT,RPROC.CANTIDAD,
                                           P_DOCUMENTO,P_PCN_NUMERO_HC,P_INS_OR_DEL,P_FECHA,Vtipo_rem,
                                           P_EVLCLN,RPROC.PRCHSP_CODIGO,RPROC.LATERALIDAD,5,1,1,
                                           EQUIPO_TAB(k).POOL,P_DURACION,P_AREA,P_DEPARTAMENTO,P_EMP_CODIGO);
                     NCONT:= NCONT+1;                       
                  END IF;   
                  EXCEPTION    
                  WHEN NO_DATA_FOUND THEN                
                     RAISE SIN_TIPO_REMUNERACION;                        
--                  WHEN OTHERS THEN
--                     RAISE_APPLICATION_ERROR(-20216,'No se pudor insertar/borrar el honorario del procedimiento quirúrgico'||SQLERRM);
                  END;                                        
            END IF;    
         END LOOP;
         CLOSE EQUIPO;
         k:=0;
      ELSE      -- Se carga honorarios por procedimiento menor o interconsulta             
         QMS$ERRORS.SHOW_DEBUG_INFO('Va a cargar el procedimiento menor');
         QMS$ERRORS.Show_debug_info('***** Va a cargar**** '||to_char(P_NUMPARTE)||to_char(ncont)||P_DOCUMENTO);
         DBMS_OUTPUT.PUT_LINE('SE VA A CARGAR PROCEDIMIENTO MENOR');
         DBMS_OUTPUT.PUT_LINE('EL HONORARIO ES ' ||VTIPO_REM);
         IF P_DOCUMENTO = 'R' THEN
            NCONT:= NCONT+1;   
         END IF;
         IF VTIPO_REM <> 'HOA' THEN         
            DBMS_OUTPUT.PUT_LINE('EL HONORARIO ES ' ||VTIPO_REM);
            FCTCONTRF.CARGAR_HONORARIO_TRF(P_NUMPARTE,P_BENEFICIARIO,NCONT,RPROC.CANTIDAD,
                                  P_DOCUMENTO,P_PCN_NUMERO_HC,P_INS_OR_DEL,P_FECHA,
                                  P_TIPO_REMUNERACION,P_EVLCLN,RPROC.PRCHSP_CODIGO,
                                  RPROC.LATERALIDAD,4,1,1,P_POOL,P_DURACION,P_AREA,
                                  P_DEPARTAMENTO,P_EMP_CODIGO);                                                                    
             NCONT:= NCONT+1;                                   
             DBMS_OUTPUT.PUT_LINE('INSERTÓ EL HONORARIO');
         ELSIF  VTIPO_REM = 'HOA' THEN
            FCTCONTRF.CARGAR_HONORARIO_TRF(P_NUMPARTE,P_BENEFICIARIO,NCONT,RPROC.CANTIDAD,
                                  P_DOCUMENTO,P_PCN_NUMERO_HC,P_INS_OR_DEL,P_FECHA,
                                  P_TIPO_REMUNERACION,P_EVLCLN,RPROC.PRCHSP_CODIGO,
                                  RPROC.LATERALIDAD,6,1,1,P_POOL,P_DURACION,P_AREA,
                                  P_DEPARTAMENTO,P_EMP_CODIGO);                                  
         NCONT:= NCONT+1;                                            
         END IF;
      END IF;     
   END LOOP;   
   ELSE
      RAISE SIN_PROCEDIMIENTO;
   END IF ;
EXCEPTION
WHEN SIN_PROCEDIMIENTO THEN                                                          
   RAISE_APPLICATION_ERROR(-20213,'No se puede registrar honorarios si no hay un procedimiento hospitalario ');
WHEN SIN_TIPO_REMUNERACION THEN                                                                               
   RAISE_APPLICATION_ERROR(-20214,'No se puede registrar honorarios si no hay un tipo de remuneracion para la funcion '||vfuncion);
WHEN OTHERS THEN
   QMS$ERRORS.UNHANDLED_EXCEPTION('FCTCONTRF.CARGAR_HONORARIO_POR_PROC_TRF');
END;
PROCEDURE CARGAR_DERECHO_QUIROFANO
-- De acuerdo al tiempo de duración, lateralidad y la fecha, se 
(vtarifario IN VARCHAR2,
DFECHA IN DATE,
vOpr IN VARCHAR2,
nPrtOpr IN NUMBER,
nHC IN NUMBER,
vlateralidad IN VARCHAR2,
nduracion IN NUMBER,
varea IN VARCHAR2,
vdepartamento IN VARCHAR2) IS 
-- Para crear o borrar la cuenta del paciente
-- no se puede hacer en un trigger de base de datos porque muta la tabla   
  CURSOR cCuentas IS
    SELECT NVL(MAX(DETALLE),0)
    FROM CUENTAS
    WHERE DOCUMENTO='Q' AND NUMERO=nPrtOpr AND PCN_NUMERO_HC=nHC;
-- Cursor que recupera si el parte operatorio tiene otras operaciones

cursor pro(P_nHC NUMBER,P_NPRTOPR NUMBER) is  -- Procedimientos que se ha realizado al paciente;
select PR.PRCHSP_CODIGO prchsp_codigo,PR.NUMERO_DE_VECES cantidad,PR.LATERALIDAD LATERALIDAD,      
       PR.VIA_DE_ACCESO VIA_ACCESO,PR.DURACION DURACION
from PROCEDIMIENTOS_REALIZADOS PR
WHERE PR.EPC_PRMATN_PCN_NUMERO_HC = P_nHC AND
      PR.PRTOPRSLC_NUMERO = P_nPrtOpr
ORDER BY PR.DURACION DESC;    
I NUMBER:=0;
nDetalle CUENTAS.DETALLE%TYPE;
nporcentaje number :=1; 
CASO NUMBER :=1;
VUVR NUMBER :=0;
VPRECIO NUMBER :=0; 
VCODIGO_ITEM VARCHAR2(30);
VCRG_TIPO VARCHAR2(1);
VCRG_CODIGO VARCHAR2(10);
CARGO_NO_EXISTENTE EXCEPTION;
SIN_CODIGO_TARIFARIO EXCEPTION;
NO_INSERTO EXCEPTION;
vDPR_ARA_CDG_PRT_A VARCHAR2(1);
vDPR_CDG_PRT_A VARCHAR2(1);
VDESC_CARGO VARCHAR2(120);
VVALOR NUMBER;
BEGIN
  OPEN cCuentas;
  FETCH cCuentas INTO nDetalle;
  CLOSE cCuentas;      
  IF vOpr = 'INS' OR VoPR = 'DEL' THEN
     QMS$ERRORS.SHOW_DEBUG_INFO('Los datos son parte : '||nprtopr||' hc '||to_Char(nHc));  
     BEGIN     
   --Siempre borro de la cuenta todo lo que se haya insertado con respecto al parte 
      DELETE FROM DETALLES_PLANILLA_PREFACT D
      WHERE (D.CNTS_DOCUMENTO,D.CNTS_NUMERO,D.CNTS_DETALLE,D.PCN_NUMERO_HC) IN
            (SELECT C.DOCUMENTO,C.NUMERO,C.DETALLE,C.PCN_NUMERO_HC
            FROM  CUENTAS C
            WHERE C.DOCUMENTO='Q' AND C.NUMERO=nPrtOpr AND C.PCN_NUMERO_HC=nHc AND C.ESTADO = 'PND');
      DELETE CUENTAS
      WHERE DOCUMENTO='Q' AND NUMERO=nPrtOpr AND PCN_NUMERO_HC=nHc AND ESTADO = 'PND';
      QMS$ERRORS.SHOW_DEBUG_INFO('Se borró los cargos de la tabla cuentas ');
     EXCEPTION 
     WHEN OTHERS THEN
       QMS$ERRORS.SHOW_DEBUG_INFO('No Se borró los cargos de la tabla cuentas ' ||sqlerrm);    
     END;
     FOR RPRO IN PRO(nHC,NPRTOPR) LOOP 
         NPORCENTAJE := 1;
         i := i + 1;
         QMS$ERRORS.SHOW_DEBUG_INFO('El valor de I es '|| to_char(i));
         IF I = 1 THEN
           CASO:=1;
         BEGIN
           SELECT T.CODIGO_ITEM,NVL(T.UVR,0),NVL(T.PRC,0) INTO VCODIGO_ITEM,VUVR,VPRECIO
           FROM TARIFARIOS T
           WHERE T.CONVENIO = VTARIFARIO AND
                 T.TIPO = 'H' AND
                 T.NIVEL = 3 AND 
                 T.CODIGO_GRUPO= '8' AND 
                 RPRO.duracion BETWEEN T.TIEMPO_DESDE AND T.TIEMPO_HASTA;
           IF  VCODIGO_ITEM IS NOT NULL THEN
           BEGIN    
              SELECT C.CRG_TIPO,C.CRG_CODIGO INTO VCRG_TIPO,VCRG_CODIGO
              FROM CONVENIOS_EQUIVALENCIAS C
              WHERE C.CNVTRF_CONVENIO = VTARIFARIO AND
                    C.CNVTRF_CODIGO = VCODIGO_ITEM AND
                    C.TIPO  = 'H'; 
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 RAISE CARGO_NO_EXISTENTE; 
              WHEN OTHERS THEN       
                 RAISE CARGO_NO_EXISTENTE; 
           END;
           BEGIN
              SELECT DPR_ARA_CODIGO,DPR_CODIGO,DESCRIPCION
              INTO vDPR_ARA_CDG_PRT_A,vDPR_CDG_PRT_A,VDESC_CARGO
              FROM CARGOS
              WHERE TIPO = VCRG_TIPO AND
                    CODIGO = VCRG_CODIGO;
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
              RAISE CARGO_NO_EXISTENTE;  
           END; 
           VVALOR := ROUND(VUVR*VPRECIO,2);
           QMS$ERRORS.SHOW_DEBUG_INFO('El valor de materiales a insertar es '|| to_char(vvalor));
           BEGIN
             GNRL.CARGAR_CUENTA(nPrtOpr,100, vDPR_ARA_CDG_PRT_A,vDPR_CDG_PRT_A,1, 
                VCRG_TIPO,VCRG_CODIGO, 'Q', nHC,'I',VVALOR,DFECHA);
             UPDATE CUENTAS C
             SET C.UVR= VUVR,
                 C.PRC = VPRECIO
             WHERE C.DOCUMENTO= 'Q' AND
                   C.NUMERO = nPrtOpr AND
                   C.DETALLE = 100 AND
                   C.CRG_TIPO = VCRG_TIPO AND
                   C.CRG_CODIGO = VCRG_CODIGO AND
                   C.PCN_NUMERO_HC = nHC;
             QMS$ERRORS.SHOW_DEBUG_INFO('Se cargo a la cuenta del paciente' );     
           EXCEPTION
           WHEN OTHERS  THEN
              RAISE NO_INSERTO;
           END; 
        ELSE     
          RAISE SIN_CODIGO_TARIFARIO;              
        END IF;   
     EXCEPTION   
     WHEN OTHERS THEN
        RAISE SIN_CODIGO_TARIFARIO;         
     END;          
         ELSIF I = 2 THEN
           CASO := 2;
         ELSE
           CASO := 3;   
         END IF;
         IF  vlateralidad = 'B' then
            NPORCENTAJE := 1.5;
         ELSE
            NPORCENTAJE := 1;
         END IF;
         IF CASO = 1 THEN
            NPORCENTAJE:= NPORCENTAJE;
         ELSIF CASO = 2 THEN
            NPORCENTAJE:= NPORCENTAJE/2;
         ELSE 
            NPORCENTAJE:= NPORCENTAJE/4;
         END IF;
         BEGIN
           QMS$ERRORS.SHOW_DEBUG_INFO('Va a obtener el valor del derecho de sala de quirofano ');
           SELECT T.CODIGO_ITEM,NVL(T.UVR,0),NVL(T.PRC,0) INTO VCODIGO_ITEM,VUVR,VPRECIO
           FROM TARIFARIOS T
           WHERE T.CONVENIO = VTARIFARIO AND
                 T.TIPO = 'H' AND
                 T.NIVEL = 3 AND 
                 T.CODIGO_GRUPO= '5' AND 
                 RPRO.duracion BETWEEN T.TIEMPO_DESDE AND T.TIEMPO_HASTA;
           QMS$ERRORS.SHOW_DEBUG_INFO('El código del ítem es: '||VCODIGO_ITEM);                 
           IF  VCODIGO_ITEM IS NOT NULL THEN
           BEGIN    
              SELECT C.CRG_TIPO,C.CRG_CODIGO INTO VCRG_TIPO,VCRG_CODIGO
              FROM CONVENIOS_EQUIVALENCIAS C
              WHERE C.CNVTRF_CONVENIO = VTARIFARIO AND
                    C.CNVTRF_CODIGO = VCODIGO_ITEM AND
                    C.TIPO  = 'H'; 
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 RAISE CARGO_NO_EXISTENTE; 
              WHEN OTHERS THEN       
                 RAISE CARGO_NO_EXISTENTE; 
           END;
           BEGIN
              SELECT DPR_ARA_CODIGO,DPR_CODIGO,DESCRIPCION
              INTO vDPR_ARA_CDG_PRT_A,vDPR_CDG_PRT_A,VDESC_CARGO
              FROM CARGOS
              WHERE TIPO = VCRG_TIPO AND
                    CODIGO = VCRG_CODIGO;
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
              RAISE CARGO_NO_EXISTENTE;  
           END; 
           VVALOR := ROUND(VUVR*VPRECIO*nporcentaje,2);
           QMS$ERRORS.SHOW_DEBUG_INFO('El valor del derecho a insertar es '|| to_char(vvalor));
           BEGIN
             GNRL.CARGAR_CUENTA(nPrtOpr,I, vDPR_ARA_CDG_PRT_A,vDPR_CDG_PRT_A,1, 
                VCRG_TIPO,VCRG_CODIGO, 'Q', nHC,'I',VVALOR,DFECHA);
             UPDATE CUENTAS C
             SET C.UVR= VUVR,
                 C.PRC = VPRECIO
             WHERE C.DOCUMENTO= 'Q' AND
                   C.NUMERO = nPrtOpr AND
                   C.DETALLE = I AND
                   C.CRG_TIPO = VCRG_TIPO AND
                   C.CRG_CODIGO = VCRG_CODIGO AND
                   C.PCN_NUMERO_HC = nHC;
             QMS$ERRORS.SHOW_DEBUG_INFO('Se cargo a la cuenta del paciente' );     
           EXCEPTION
           WHEN OTHERS  THEN
              RAISE NO_INSERTO;
           END;
        ELSE
          RAISE SIN_CODIGO_TARIFARIO;                
        END IF;   
     EXCEPTION   
     WHEN OTHERS THEN
        RAISE SIN_CODIGO_TARIFARIO;         
     END; 
     END LOOP;     
  END IF;
EXCEPTION  
  WHEN CARGO_NO_EXISTENTE THEN  
     QMS$ERRORS.show_message(-20211,'Honorario no insertada/anulado. El cargo con codigo '||vcrg_Codigo||' no existe ');
  WHEN SIN_CODIGO_TARIFARIO THEN  
      QMS$ERRORS.show_message(-20212,'No existe el codigo en el tarifario ');           
  WHEN NO_INSERTO THEN  
      QMS$ERRORS.show_message(-20212,'No se pudo insertar el valor del derecho de sala de Quirófano ');           
  WHEN OTHERS THEN
      QMS$ERRORS.unhandled_exception('FCTCONTRF.CARGAR_DERECHO_QUIROFANO');      
END;     
END FCTCONTRF;
/
