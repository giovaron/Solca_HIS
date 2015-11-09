-- Y:\sas\guiones\cambios_solca_quito\PAQUETE_CNTINT_NUEVO_6I.pkb
--
-- Generated for Oracle 10g on Tue Aug 15  10:31:37 2006 by Server Generator 6.5.96.5.6
 

PROMPT Creating Package Body 'CNTINT'
CREATE OR REPLACE PACKAGE BODY CNTINT IS

/* Crea un comprobante Contable por la Depreciación Mensual de Act. Fijos */
PROCEDURE CONTABILIZAR_DEPRECIACION_AF
 (NTIPOCAMBIO IN number
 ,NTIPOCAMBIOE IN NUMBER
 ,VMONEDALOCAL IN VARCHAR2
 ,CEMPCOD IN VARCHAR2
 ,CTPOCMP IN VARCHAR2
 ,DFECHACMP IN DATE
 ,NCLAVE OUT NUMBER
 ,NANIO IN NUMBER
 ,NMES IN NUMBER
 )
 IS

I NUMBER;
NCUADREH NUMBER(21, 6) := 0;
CNOMBRE_SEC VARCHAR2(40);
MES_DEPRECIADO VARCHAR2(10);
NNUMING NUMBER := 1;
VDESCING VARCHAR2(1000);
NCUADRED NUMBER(21, 6) := 0;
NDIFCUADRE NUMBER(21, 6) := 0;
--Este proceso crea un Comprobante Contable para la Depreciación de Activos Fijos
--desde el Sistema de Activos Fijos. Antes de proceder a contabilizar la 
--Depreciación, se valida que los datos necesarios para realizar el proceso estén
--correctos, esto lo hacemos en el proceso VALIDAR_CONTABILIZACION_AF
BEGIN
DECLARE
CURSOR cMesCerrado IS
  SELECT COUNT(*)
    FROM CIERRES_DE_MES
    WHERE TRUNC(MES,'MM')=TRUNC(dFechaCmp,'MM')
      AND  ESTADO='C';
CURSOR cGastosDepreciaciones IS --(Debe) Cursor de Gastos por Depreciaciones
SELECT EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,VALOR
FROM GASTOS_DEPRECIACIONES_AFJ
WHERE EMP_CODIGO = cEmpCod AND
      VALOR > 0 AND
      ANIO = NANIO AND
      MES = 'DPR'||DECODE (NMES,1,'ENE',
                                2,'FEB',
                                3,'MAR',
                                4,'ABR',
                                5,'MAY',
                                6,'JUN',
                                7,'JUL',
                                8,'AGO',
                                9,'SEP',
                               10,'OCT',
                               11,'NOV',
                               12,'DIC') ;
CURSOR cDepreciaciones IS --(Haber) Cursor de Depreciaciones
SELECT EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,VALOR
FROM DEPRECIACIONES_AFJ
WHERE EMP_CODIGO = cEmpCod AND
      ANIO = NANIO AND
      REFERENCIA = 0 AND
      VALOR>0 AND
      MES = 'DPR'||DECODE (NMES,1,'ENE',
                                2,'FEB',
                                3,'MAR',
                                4,'ABR',
                                5,'MAY',
                                6,'JUN',
                                7,'JUL',
                                8,'AGO',
                                9,'SEP',
                               10,'OCT',
                               11,'NOV',
                               12,'DIC') ;
TYPE tMovCnt  IS TABLE OF MOVIMIENTOS%ROWTYPE INDEX BY BINARY_INTEGER;
rMovCnt tMovCnt; -- Tabla en donde se guardan los datos antes de Contabilizar
nContMesCerrado NUMBER:=0;-- Devuelve 1 si el mes esta cerrado caso contrario 0
BEGIN
  SELECT DECODE (NMES,1,'Enero',
                      2,'Febrero',
                      3,'Marzo',
                      4,'Abril',
                      5,'Mayo',
                      6,'Junio',
                      7,'Julio',
                      8,'Agosto',
                      9,'Septiembre',
                     10,'Octubre',
                     11,'Noviembre',
                     12,'Diciembre') INTO MES_DEPRECIADO
  FROM DUAL;
  SELECT NOMBRE_SECUENCIA INTO cNOMBRE_SEC
  FROM TIPOS_COMPROBANTES_EMPRESAS
  WHERE EMP_CODIGO = cEmpCod AND
        TPOCMP_CODIGO = cTpoCmp;
  GNRL.ACTUALIZA_SECUENCIA(cNOMBRE_SEC,nClave);
-- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  OPEN cMesCerrado;
  FETCH cMesCerrado INTO nContMesCerrado;
  IF nContMesCerrado>0 THEN
-- Error no se puede contabilizar para un mes cerrado
      QMS$ERRORS.SHOW_MESSAGE('CNT-00046');-- No se puede crear un comprobante de un mes ya cerrado
  END IF;
  VALIDAR_CONTABILIZACION_AF(cEmpCod,'DPR',NANIO,NULL,NMES);   
  QMS$ERRORS.SHOW_DEBUG_INFO('Se validó la contabilizacion de Depreciaición');
  -- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  BEGIN
     vDescIng:='Depreciación de Activos Fijos Correspondiente a '||MES_DEPRECIADO||' de '||TO_CHAR(NANIO,'0009');
     INSERT INTO COMPROBANTES (TPOCMPEMP_EMP_CODIGO,TPOCMPEMP_TPOCMP_CODIGO,FECHA,CLAVE,
                               MAYORIZADO,ESTADO,TOTAL,MONEDA_LOCAL,TIPO_DE_CAMBIO,TIPO_DE_CAMBIOE,
                               CONCEPTO,CRRMES_MES,CONTABILIZADO_DESDE)
     VALUES (cEmpCod,cTpoCmp,dFechaCmp,nClave,'F','N',0,vMonedaLocal,nTipoCambio,nTipoCambioE,vDescIng,NULL,'ACF'); 
  EXCEPTION 
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo la inserción del Comprobante por error '||SQLERRM);  
  END;
  i:=1;
  nCuadreD:=0;
  FOR rGastosDepreciaciones IN cGastosDepreciaciones LOOP
    -- FIJAMOS EL DEBE
    rMovCnt(i).SECUENCIA:=101;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=ROUND(rGastosDepreciaciones.VALOR,2);
    rMovCnt(i).DEBEE:=ROUND(rGastosDepreciaciones.VALOR,2)*nTipoCambioE;
    rMovCnt(i).HABER:=0;
    rMovCnt(i).HABERE:=0;
    rMovCnt(i).FECHA:=dFechaCmp;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rGastosDepreciaciones.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rGastosDepreciaciones.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rGastosDepreciaciones.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rGastosDepreciaciones.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rGastosDepreciaciones.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rGastosDepreciaciones.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rGastosDepreciaciones.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rGastosDepreciaciones.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:='Depreciación de '||MES_DEPRECIADO||' de '||TO_CHAR(NANIO,'0009');
    rMovCnt(i).ASOCIACION:=NULL;
    nCuadreD:=nCuadreD+rMovCnt(i).DEBE;
    i:=i+1;
  END LOOP;
  ncuadreH:=0;
  FOR rDepreciaciones IN cDepreciaciones LOOP
   -- FIJAMOS EL HABER
    rMovCnt(i).SECUENCIA:=201;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=0;
    rMovCnt(i).DEBEE:=0;
    rMovCnt(i).HABER:=ROUND(rDepreciaciones.VALOR,2);
    rMovCnt(i).HABERE:=ROUND(rDepreciaciones.VALOR,2)*nTipoCambioE;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rDepreciaciones.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rDepreciaciones.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rDepreciaciones.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rDepreciaciones.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rDepreciaciones.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rDepreciaciones.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rDepreciaciones.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rDepreciaciones.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:= 'Depreciación de'||MES_DEPRECIADO||' de '||TO_CHAR(NANIO,'0009');
    rMovCnt(i).ASOCIACION:=NULL;
    nCuadreH:=nCuadreH+rMovCnt(i).HABER;
    i:=i+1;
  END LOOP;
  nDifCuadre:=nCuadreD-nCuadreH;
  IF nDifCuadre >.5 0 THEN  -- No debe existir diferencia
     QMS$ERRORS.SHOW_MESSAGE('CNT-01109');
  END IF;
-- AHORA SI NO HA HABIDO NINGUN ERROR CREAMOS LOS DETALLES DEL COMPROBANTE
  FOR I IN 1..rMovCnt.COUNT LOOP
    IF (rMovCnt(I).DEBE=0 AND rMovCnt(I).HABER=0) OR (rMovCnt(I).DEBE>0 AND rMovCnt(I).HABER>0) THEN
      QMS$ERRORS.SHOW_MESSAGE('ADM-00009',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||
                                          rMovCnt(I).SS_S_A_SC_CNT_CODIGO||rMovCnt(I).SS_S_A_SC_CODIGO||
                                          rMovCnt(I).SS_S_A_CODIGO||rMovCnt(I).SS_S_CODIGO||rMovCnt(I).SS_CODIGO||
                                          rMovCnt(I).S_CODIGO||' '||rMovCnt(I).DESCRIPCION||' ** DEBE ** '||
                                          rMovCnt(I).DEBE||' ** HABER **'||rMovCnt(I).HABER,'Comuniquese con Softcase');
    END IF;
    INSERT INTO MOVIMIENTOS (MVM_ID,CMP_TPOCMPEMP_EMP_CODIGO,CMP_TPOCMPEMP_TPOCMP_CODIGO,
  	    CMP_FECHA,CMP_CLAVE,FECHA,SECUENCIA,DEBE,HABER,DEBEE,HABERE,MONEDA,TIPO_DE_CAMBIO,MAYORIZADO,
  	    SS_S_A_SC_CNT_MYR_EMP_CODIGO,SS_S_A_SC_CNT_MYR_CODIGO,SS_S_A_SC_CNT_CODIGO,
  	    SS_S_A_SC_CODIGO,SS_S_A_CODIGO,SS_S_CODIGO,SS_CODIGO,S_CODIGO,
          DESCRIPCION,ASOCIACION,ESTADO_MOVIMIENTO,OBL_OBL_ID)
    VALUES (MVM_SEQ.NEXTVAL,cEmpCod,cTpoCmp,dFechaCmp,nClave,dFechaCmp,rMovCnt(I).SECUENCIA,
      	rMovCnt(I).DEBE,rMovCnt(I).HABER,rMovCnt(I).DEBEE,rMovCnt(I).HABERE,
            vMonedaLocal,nTipoCambio,'F',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO,
            rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO,rMovCnt(I).SS_S_A_SC_CNT_CODIGO,
  	      rMovCnt(I).SS_S_A_SC_CODIGO,rMovCnt(I).SS_S_A_CODIGO,rMovCnt(I).SS_S_CODIGO,
            rMovCnt(I).SS_CODIGO,rMovCnt(I).S_CODIGO,
  	      rMovCnt(I).DESCRIPCION,rMovCnt(I).ASOCIACION,'N',NULL);
            QMS$ERRORS.SHOW_DEBUG_INFO(rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||
                               rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||
                               rMovCnt(I).SS_S_A_SC_CNT_CODIGO||
                               rMovCnt(I).SS_S_A_SC_CODIGO||
                               rMovCnt(I).SS_S_A_CODIGO||
                               rMovCnt(I).SS_S_CODIGO||
                               rMovCnt(I).SS_CODIGO||
                               rMovCnt(I).S_CODIGO||
                               rMovCnt(I).DESCRIPCION||' '||
                               TO_CHAR(rMovCnt(I).DEBE)||' '||
                               TO_CHAR(rMovCnt(I).HABER)); 
  END LOOP;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
-- FALLA SI YA EXISTE UN COMPROBANTE IGUAL (CABECERA)
    QMS$ERRORS.SHOW_MESSAGE('CNT-01010',cTpoCmp||'-'||TO_CHAR(dFechaCmp,'DD/MM/YYYY')||'-'||TO_CHAR(nClave));
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo en el procedimiento CONTABILIZAR_DEPRECIACION_AF por error '||SQLERRM);
END;
END;
/* Crea un comprobante Contable por el Egreso de Act. Fijos */
PROCEDURE CONTABILIZAR_EGRESOS_AFJ
 (NTIPOCAMBIO IN number
 ,NTIPOCAMBIOE IN NUMBER
 ,VMONEDALOCAL IN VARCHAR2
 ,CEMPCOD IN VARCHAR2
 ,CTPOCMP IN VARCHAR2
 ,DFECHACMP IN DATE
 ,NCLAVE OUT NUMBER
 ,NNUMERO IN NUMBER
 )
 IS

I NUMBER;
NCUADREH NUMBER(21, 6) := 0;
NNUMING NUMBER := 1;
VDESCING VARCHAR2(1000);
CNOMBRE_SEC VARCHAR2(40);
NCUADRED NUMBER(21, 6) := 0;
NDIFCUADRE NUMBER(21, 6) := 0;
--Este proceso crea un Comprobante Contable para el Egreso de Activos Fijos
--desde el Sistema de Activos Fijos. Antes de proceder a contabilizar el 
--Egreso, se valida que los datos necesarios para realizar el proceso estén
--correctos, esto lo hacemos en el proceso VALIDAR_CONTABILIZACION_AF
BEGIN
DECLARE
CURSOR cMesCerrado IS
  SELECT COUNT(*)
    FROM CIERRES_DE_MES
    WHERE TRUNC(MES,'MM')=TRUNC(dFechaCmp,'MM')
      AND  ESTADO='C';
CURSOR cGastos_y_Depreciaciones IS --(Debe) Cursor de Gastos y Depreciaciones por Egresos
SELECT EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,DESCRIPCION,VALOR
FROM APP_Y_DPR_EGRESOS_AFJ
WHERE EMP_CODIGO = cEmpCod AND
      NUMERO = NNUMERO AND 
      VALOR > 0;
CURSOR cActivos_Fijos IS --(Haber) Cursor de Activos Fijos
SELECT EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,VALOR
FROM EGRESOS_AFJ
WHERE EMP_CODIGO = cEmpCod AND    
      NUMERO = NNUMERO AND
      VALOR > 0;
TYPE tMovCnt  IS TABLE OF MOVIMIENTOS%ROWTYPE INDEX BY BINARY_INTEGER;
rMovCnt tMovCnt; -- Tabla en donde se guardan los datos antes de Contabilizar
nContMesCerrado NUMBER:=0;-- Devuelve 1 si el mes esta cerrado caso contrario 0
BEGIN
BEGIN
  SELECT NOMBRE_SECUENCIA INTO cNOMBRE_SEC
  FROM TIPOS_COMPROBANTES_EMPRESAS
  WHERE EMP_CODIGO = cEmpCod AND
        TPOCMP_CODIGO = cTpoCmp;
  GNRL.ACTUALIZA_SECUENCIA(cNOMBRE_SEC,nClave);
-- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  OPEN cMesCerrado;
  FETCH cMesCerrado INTO nContMesCerrado;
  IF nContMesCerrado>0 THEN
-- Error no se puede contabilizar para un mes cerrado
      QMS$ERRORS.SHOW_MESSAGE('CNT-00046');-- No se puede crear un comprobante de un mes ya cerrado
  END IF;
  VALIDAR_CONTABILIZACION_AF(cEmpCod,'EGR',NNUMERO,'DAF',NULL);   
  VALIDAR_CONTABILIZACION_AF(cEmpCod,'EGR',NNUMERO,'CAF',NULL);   
  -- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  BEGIN
     vDescIng:='Contabilización de Egreso de Activos Fijos Número '||TO_CHAR(NNUMERO);
     INSERT INTO COMPROBANTES (TPOCMPEMP_EMP_CODIGO,TPOCMPEMP_TPOCMP_CODIGO,FECHA,CLAVE,
                               MAYORIZADO,ESTADO,TOTAL,MONEDA_LOCAL,TIPO_DE_CAMBIO,TIPO_DE_CAMBIOE,
                               CONCEPTO,CRRMES_MES,CONTABILIZADO_DESDE)
     VALUES (cEmpCod,cTpoCmp,dFechaCmp,nClave,'F','N',0,vMonedaLocal,nTipoCambio,nTipoCambioE,vDescIng,NULL,'ACF');
   EXCEPTION 
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo la inserción del Comprobante por error '||SQLERRM);  
  END;
  i:=1;
  nCuadreD:=0;
  FOR rGastos_y_Depreciaciones IN cGastos_y_Depreciaciones LOOP
    -- FIJAMOS EL DEBE
    rMovCnt(i).SECUENCIA:=101;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=ROUND(rGastos_y_Depreciaciones.VALOR,2);
    rMovCnt(i).DEBEE:=ROUND(rGastos_y_Depreciaciones.VALOR,2)*nTipoCambioE;
    rMovCnt(i).HABER:=0;
    rMovCnt(i).HABERE:=0;
    rMovCnt(i).FECHA:=dFechaCmp;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rGastos_y_Depreciaciones.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rGastos_y_Depreciaciones.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rGastos_y_Depreciaciones.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rGastos_y_Depreciaciones.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rGastos_y_Depreciaciones.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rGastos_y_Depreciaciones.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rGastos_y_Depreciaciones.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rGastos_y_Depreciaciones.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:=rGastos_y_Depreciaciones.DESCRIPCION;
    rMovCnt(i).ASOCIACION:=NULL;
    nCuadreD:=nCuadreD+rMovCnt(i).DEBE;
    i:=i+1;
  END LOOP;
  ncuadreH:=0;
  FOR rActivos_Fijos IN cActivos_Fijos LOOP
   -- FIJAMOS EL HABER
    rMovCnt(i).SECUENCIA:=201;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=0;
    rMovCnt(i).DEBEE:=0;
    rMovCnt(i).HABER:=ROUND(rActivos_Fijos.VALOR,2);
    rMovCnt(i).HABERE:=ROUND(rActivos_Fijos.VALOR,2)*nTipoCambioE;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rActivos_Fijos.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rActivos_Fijos.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rActivos_Fijos.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rActivos_Fijos.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rActivos_Fijos.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rActivos_Fijos.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rActivos_Fijos.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rActivos_Fijos.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:= 'Activos Fijos Egresados';
    rMovCnt(i).ASOCIACION:=NULL;
    nCuadreH:=nCuadreH+rMovCnt(i).HABER;
    i:=i+1;
  END LOOP;
  nDifCuadre:=nCuadreD-nCuadreH;
  IF nDifCuadre <> 0 THEN -- Si hay diferencia presenta un error
     QMS$ERRORS.SHOW_MESSAGE('CNT-01109');
  END IF;
-- AHORA SI NO HA HABIDO NINGUN ERROR CREAMOS LOS DETALLES DEL COMPROBANTE
  FOR I IN 1..rMovCnt.COUNT LOOP
    IF (rMovCnt(I).DEBE=0 AND rMovCnt(I).HABER=0) OR (rMovCnt(I).DEBE>0 AND rMovCnt(I).HABER>0) THEN
      QMS$ERRORS.SHOW_MESSAGE('ADM-00009',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||
                                          rMovCnt(I).SS_S_A_SC_CNT_CODIGO||rMovCnt(I).SS_S_A_SC_CODIGO||
                                          rMovCnt(I).SS_S_A_CODIGO||rMovCnt(I).SS_S_CODIGO||rMovCnt(I).SS_CODIGO||
                                          rMovCnt(I).S_CODIGO||' '||rMovCnt(I).DESCRIPCION||' ** DEBE ** '||
                                          rMovCnt(I).DEBE||' ** HABER **'||rMovCnt(I).HABER,'Comuniquese con Softcase');
    END IF;
    INSERT INTO MOVIMIENTOS (MVM_ID,CMP_TPOCMPEMP_EMP_CODIGO,CMP_TPOCMPEMP_TPOCMP_CODIGO,
  	    CMP_FECHA,CMP_CLAVE,FECHA,SECUENCIA,DEBE,HABER,DEBEE,HABERE,MONEDA,TIPO_DE_CAMBIO,MAYORIZADO,
  	    SS_S_A_SC_CNT_MYR_EMP_CODIGO,SS_S_A_SC_CNT_MYR_CODIGO,SS_S_A_SC_CNT_CODIGO,
  	    SS_S_A_SC_CODIGO,SS_S_A_CODIGO,SS_S_CODIGO,SS_CODIGO,S_CODIGO,
          DESCRIPCION,ASOCIACION,ESTADO_MOVIMIENTO,OBL_OBL_ID)
    VALUES (MVM_SEQ.NEXTVAL,cEmpCod,cTpoCmp,dFechaCmp,nClave,dFechaCmp,rMovCnt(I).SECUENCIA,
      	rMovCnt(I).DEBE,rMovCnt(I).HABER,rMovCnt(I).DEBEE,rMovCnt(I).HABERE,
            vMonedaLocal,nTipoCambio,'F',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO,
            rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO,rMovCnt(I).SS_S_A_SC_CNT_CODIGO,
  	      rMovCnt(I).SS_S_A_SC_CODIGO,rMovCnt(I).SS_S_A_CODIGO,rMovCnt(I).SS_S_CODIGO,
            rMovCnt(I).SS_CODIGO,rMovCnt(I).S_CODIGO,
  	      rMovCnt(I).DESCRIPCION,rMovCnt(I).ASOCIACION,'N',NULL);
  END LOOP;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
   -- FALLA SI NO ENCUENTRA LA SECUENCIA DEL COMPROBANTE
   QMS$ERRORS.SHOW_MESSAGE('CNT-01408',cTpoCmp);
END;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
-- FALLA SI YA EXISTE UN COMPROBANTE IGUAL (CABECERA)
    QMS$ERRORS.SHOW_MESSAGE('CNT-01010',cTpoCmp||'-'||TO_CHAR(dFechaCmp,'DD/MM/YYYY')||'-'||TO_CHAR(nClave));
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo en el procedimiento CONTABILIZAR_EGRESOS_AFJ por error '||SQLERRM);
END;
END;
/* Crea un comprobante Contable por los Ingresos de Act. Fijos o Suminis. */
PROCEDURE CONTABILIZAR_ASIGNACIONES_SMN
 (NTIPOCAMBIO IN number
 ,NTIPOCAMBIOE IN NUMBER
 ,VMONEDALOCAL IN VARCHAR2
 ,CEMPCOD IN VARCHAR2
 ,CTPOCMP IN VARCHAR2
 ,DFECHACMP IN DATE
 ,NCLAVE OUT NUMBER
 ,NNUMERO IN NUMBER
 )
 IS

I NUMBER;
NCUADREH NUMBER(21, 6) := 0;
NNUMING NUMBER := 1;
CNOMBRE_SEC VARCHAR2(40);
VDESCING VARCHAR2(1000);
NCUADRED NUMBER(21, 6) := 0;
NDIFCUADRE NUMBER(21, 6) := 0;
--Este proceso crea un Comprobante Contable para la asignacion de Suministros
--desde el Sistema de Activos Fijos. Antes de proceder a contabilizar el 
--Ingreso, se valida que los datos necesarios para realizar el proceso estén
--correctos, esto lo hacemos en el proceso VALIDAR_CONTABILIZACION_AF
BEGIN
DECLARE
CURSOR cMesCerrado IS
  SELECT COUNT(*)
    FROM CIERRES_DE_MES
    WHERE TRUNC(MES,'MM')=TRUNC(dFechaCmp,'MM')
      AND  ESTADO='C';
CURSOR cGastos_Suministros IS --(Debe) Cursor de Gastos por asignación de suministros
SELECT EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,VALOR
FROM GASTOS_SUMINISTROS_CONTROL
WHERE EMP_CODIGO = cEmpCod AND
      VALOR > 0 AND
      NUMERO = NNUMERO;
CURSOR cSuministros IS --(Haber) Parámetro de Integración 
  SELECT PRMINT.CUENTA_CONTABLE,
         PLNCNT.EMP_CODIGO EMP_CODIGO, PLNCNT.MYR_CODIGO
         MYR_CODIGO, PLNCNT.CNT_CODIGO CNT_CODIGO, PLNCNT.SCNT_CODIGO SCNT_CODIGO,
         PLNCNT.AXL_CODIGO AXL_CODIGO, PLNCNT.SAXL_CODIGO SAXL_CODIGO,
         PLNCNT.SAXL2_CODIGO SAXL2_CODIGO, PLNCNT.SAXL3_CODIGO SAXL3_CODIGO
  FROM PARAMETROS_INTEGRACION PRMINT,PLAN_DE_CUENTAS PLNCNT
  WHERE PRMINT.EMP_CODIGO=cEmpCod
    AND PRMINT.PARAMETRO='SMNCNT'
    AND PRMINT.TIPO='AFJ'
    AND PRMINT.CUENTA_CONTABLE=PLNCNT.CODIGO (+);

TYPE tMovCnt  IS TABLE OF MOVIMIENTOS%ROWTYPE INDEX BY BINARY_INTEGER;
rMovCnt tMovCnt; -- Tabla en donde se guardan los datos antes de Contabilizar
nContMesCerrado NUMBER:=0;-- Devuelve 1 si el mes esta cerrado caso contrario 0
BEGIN
BEGIN
  SELECT NOMBRE_SECUENCIA INTO cNOMBRE_SEC
  FROM TIPOS_COMPROBANTES_EMPRESAS
  WHERE EMP_CODIGO = cEmpCod AND
        TPOCMP_CODIGO = cTpoCmp;
  GNRL.ACTUALIZA_SECUENCIA(cNOMBRE_SEC,nClave);
  QMS$ERRORS.SHOW_DEBUG_INFO('La secuencia es: '||TO_CHAR(nClave));
  OPEN cMesCerrado;
  FETCH cMesCerrado INTO nContMesCerrado;
  IF nContMesCerrado>0 THEN
-- Error no se puede contabilizar para un mes cerrado
      QMS$ERRORS.SHOW_MESSAGE('CNT-00046');-- No se puede crear un comprobante de un mes ya cerrado
  END IF;
  VALIDAR_CONTABILIZACION_AF(cEmpCod,'ASG',NNUMERO,'GSC',NULL);   
  -- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  BEGIN
     vDescIng:='Contabilización de Asignación de Suministros Número '||TO_CHAR(NNUMERO);
     INSERT INTO COMPROBANTES (TPOCMPEMP_EMP_CODIGO,TPOCMPEMP_TPOCMP_CODIGO,FECHA,CLAVE,
                               MAYORIZADO,ESTADO,TOTAL,MONEDA_LOCAL,TIPO_DE_CAMBIO,TIPO_DE_CAMBIOE,
                               CONCEPTO,CRRMES_MES,CONTABILIZADO_DESDE)
     VALUES (cEmpCod,cTpoCmp,dFechaCmp,nClave,'F','N',0,vMonedaLocal,nTipoCambio,nTipoCambioE,vDescIng,NULL,'ACF'); 
  EXCEPTION 
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo la inserción del Comprobante por error '||SQLERRM);  
  END;
  i:=1;
  nCuadreD:=0;
  FOR rGastos_Suministros IN cGastos_Suministros LOOP
    -- FIJAMOS EL DEBE
    rMovCnt(i).SECUENCIA:=101;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=ROUND(rGastos_Suministros.VALOR,2);
    rMovCnt(i).DEBEE:=ROUND(rGastos_Suministros.VALOR,2)*nTipoCambioE;
    rMovCnt(i).HABER:=0;
    rMovCnt(i).HABERE:=0;
    rMovCnt(i).FECHA:=dFechaCmp;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rGastos_Suministros.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rGastos_Suministros.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rGastos_Suministros.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rGastos_Suministros.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rGastos_Suministros.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rGastos_Suministros.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rGastos_Suministros.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rGastos_Suministros.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:=NULL;
    rMovCnt(i).ASOCIACION:=NULL;
    nCuadreD:=nCuadreD+rMovCnt(i).DEBE;
    i:=i+1;
  END LOOP;
  ncuadreH:=0;
  -- Se fije el haber de una Donación 
  FOR rSuministros IN cSuministros LOOP
    rMovCnt(i).SECUENCIA:=201;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=0;
    rMovCnt(i).DEBEE:=0;
    rMovCnt(i).HABER:=ROUND(nCuadreD,2);
    rMovCnt(i).HABERE:=ROUND(nCuadreD,2)*nTipoCambioE;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rSuministros.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rSuministros.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rSuministros.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rSuministros.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rSuministros.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rSuministros.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rSuministros.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rSuministros.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:='Suministros de Control';
    rMovCnt(i).ASOCIACION:=NULL;   
  END LOOP;  
-- AHORA SI NO HA HABIDO NINGUN ERROR CREAMOS LOS DETALLES DEL COMPROBANTE
  FOR I IN 1..rMovCnt.COUNT LOOP
    IF (rMovCnt(I).DEBE=0 AND rMovCnt(I).HABER=0) OR (rMovCnt(I).DEBE>0 AND rMovCnt(I).HABER>0) THEN
      QMS$ERRORS.SHOW_MESSAGE('ADM-00009',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||
                                          rMovCnt(I).SS_S_A_SC_CNT_CODIGO||rMovCnt(I).SS_S_A_SC_CODIGO||
                                          rMovCnt(I).SS_S_A_CODIGO||rMovCnt(I).SS_S_CODIGO||rMovCnt(I).SS_CODIGO||
                                          rMovCnt(I).S_CODIGO||' '||rMovCnt(I).DESCRIPCION||' ** DEBE ** '||
                                          rMovCnt(I).DEBE||' ** HABER **'||rMovCnt(I).HABER,'Comuniquese con Softcase');
    END IF;
    INSERT INTO MOVIMIENTOS (MVM_ID,CMP_TPOCMPEMP_EMP_CODIGO,CMP_TPOCMPEMP_TPOCMP_CODIGO,
  	    CMP_FECHA,CMP_CLAVE,FECHA,SECUENCIA,DEBE,HABER,DEBEE,HABERE,MONEDA,TIPO_DE_CAMBIO,MAYORIZADO,
  	    SS_S_A_SC_CNT_MYR_EMP_CODIGO,SS_S_A_SC_CNT_MYR_CODIGO,SS_S_A_SC_CNT_CODIGO,
  	    SS_S_A_SC_CODIGO,SS_S_A_CODIGO,SS_S_CODIGO,SS_CODIGO,S_CODIGO,
          DESCRIPCION,ASOCIACION,ESTADO_MOVIMIENTO,OBL_OBL_ID)
    VALUES (MVM_SEQ.NEXTVAL,cEmpCod,cTpoCmp,dFechaCmp,nClave,dFechaCmp,rMovCnt(I).SECUENCIA,
      	rMovCnt(I).DEBE,rMovCnt(I).HABER,rMovCnt(I).DEBEE,rMovCnt(I).HABERE,
            vMonedaLocal,nTipoCambio,'F',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO,
            rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO,rMovCnt(I).SS_S_A_SC_CNT_CODIGO,
  	      rMovCnt(I).SS_S_A_SC_CODIGO,rMovCnt(I).SS_S_A_CODIGO,rMovCnt(I).SS_S_CODIGO,
            rMovCnt(I).SS_CODIGO,rMovCnt(I).S_CODIGO,
  	      rMovCnt(I).DESCRIPCION,rMovCnt(I).ASOCIACION,'N',NULL);
           QMS$ERRORS.SHOW_DEBUG_INFO(rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||
                               rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||
                               rMovCnt(I).SS_S_A_SC_CNT_CODIGO||
                               rMovCnt(I).SS_S_A_SC_CODIGO||
                               rMovCnt(I).SS_S_A_CODIGO||
                               rMovCnt(I).SS_S_CODIGO||
                               rMovCnt(I).SS_CODIGO||
                               rMovCnt(I).S_CODIGO||
                               rMovCnt(I).DESCRIPCION||' '||
                               TO_CHAR(rMovCnt(I).DEBE)||' '||
                               TO_CHAR(rMovCnt(I).HABER)); 
  END LOOP;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
   -- FALLA SI NO ENCUENTRA LA SECUENCIA DEL COMPROBANTE
   QMS$ERRORS.SHOW_MESSAGE('CNT-01408',cTpoCmp);
END;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
-- FALLA SI YA EXISTE UN COMPROBANTE IGUAL (CABECERA)
    QMS$ERRORS.SHOW_MESSAGE('CNT-01010',cTpoCmp||'-'||TO_CHAR(dFechaCmp,'DD/MM/YYYY')||'-'||TO_CHAR(nClave));
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo en el procedimiento CONTABILIZAR_ASIGNACIONES_SMN por error '||SQLERRM);
END;
END;
/* Crea un comprobante Contable por los Ingresos de Act. Fijos o Suminis. */
PROCEDURE CONTABILIZAR_INGRESOS_AFJ
 (NTIPOCAMBIO IN number
 ,NTIPOCAMBIOE IN NUMBER
 ,VMONEDALOCAL IN VARCHAR2
 ,CEMPCOD IN VARCHAR2
 ,CTPOCMP IN VARCHAR2
 ,DFECHACMP IN DATE
 ,NCLAVE OUT NUMBER
 ,NNUMERO IN NUMBER
 ,CTIPO IN VARCHAR2
 ,NPROVEEDOR IN NUMBER
 ,CBENEFICIARIO IN VARCHAR2
 ,CIDENTIFICACION IN VARCHAR2
 ,CTPOCOMPROBANTE IN VARCHAR2
 ,DFECHAEMISION IN DATE
 ,DFECHACADUCIDAD IN DATE
 ,NSERIEFACTURA IN VARCHAR2
 ,NFACTURA IN NUMBER
 ,NAUTORIZACIONSRI IN NUMBER
 ,CIDCREDITO IN VARCHAR2
 ,CIDRETENCION IN VARCHAR2
 ,NSUBTOTAL IN NUMBER
 ,NTOTALIVA IN NUMBER
 ,NIVA IN NUMBER
 ,NDIAS_PLAZO IN NUMBER
 ,CCNTPRS IN VARCHAR2
 )
 IS

I NUMBER;
NCUADREH NUMBER(21, 6) := 0;
NNUMING NUMBER := 1;
VDESCING VARCHAR2(1000);
NCUADRED NUMBER(21, 6) := 0;
CDOCUMENTO VARCHAR2(120);
NDIFCUADRE NUMBER(21, 6) := 0;
CNOMBRE_SEC VARCHAR2(40);
--Este proceso crea un Comprobante Contable para el Ingreso de Activos Fijos
--desde el Sistema de Activos Fijos. Antes de proceder a contabilizar el 
--Ingreso, se valida que los datos necesarios para realizar el proceso estén
--correctos, esto lo hacemos en el proceso VALIDAR_CONTABILIZACION_AF
BEGIN
DECLARE
nCodProv NUMBER;
CURSOR cMesCerrado IS
  SELECT COUNT(*)
    FROM CIERRES_DE_MES
    WHERE TRUNC(MES,'MM')=TRUNC(dFechaCmp,'MM')
      AND  ESTADO='C';
CURSOR cPrvAf IS
  SELECT DECODE(PROVEEDOR_VARIO,'V',0,CODIGO)
  FROM PROVEEDORES_ACTIVOS_FIJOS
  WHERE EMP_CODIGO=CEMPCOD AND CODIGO=nProveedor;
CURSOR cAsociaciones_Comprobantes IS
SELECT * FROM ASOCIACIONES_TIPO_DE_COMPROBAN
WHERE TPOCMP_CODIGO = cTpoCmp
ORDER BY SECUENCIA;
CURSOR cDebe_Ingresos_AFJ IS --(Debe) Cursor de Activos Fijos e IVA
SELECT DESCRIPCION,EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,VALOR
FROM INGRESOS_AFJ
WHERE EMP_CODIGO = cEmpCod AND
      VALOR > 0 AND
      NUMERO = NNUMERO
      ORDER BY DESCRIPCION;
CURSOR cDonacion IS --(Haber) Parámetro de Integración para el caso de Donaciones
  SELECT PRMINT.CUENTA_CONTABLE,
         PLNCNT.EMP_CODIGO EMP_CODIGO, PLNCNT.MYR_CODIGO
         MYR_CODIGO, PLNCNT.CNT_CODIGO CNT_CODIGO, PLNCNT.SCNT_CODIGO SCNT_CODIGO,
         PLNCNT.AXL_CODIGO AXL_CODIGO, PLNCNT.SAXL_CODIGO SAXL_CODIGO,
         PLNCNT.SAXL2_CODIGO SAXL2_CODIGO, PLNCNT.SAXL3_CODIGO SAXL3_CODIGO
  FROM PARAMETROS_INTEGRACION PRMINT,PLAN_DE_CUENTAS PLNCNT
  WHERE PRMINT.EMP_CODIGO=cEmpCod
    AND PRMINT.PARAMETRO='DNC'
    AND PRMINT.TIPO='AFJ'
    AND PRMINT.CUENTA_CONTABLE=PLNCNT.CODIGO (+);
CURSOR cRetenciones_AFJ IS --(Haber) Cursor de Retenciones por Ingreso de Act. Fijo
SELECT DESCRIPCION,EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,VALOR
FROM RETENCIONES_AFJ
WHERE EMP_CODIGO = cEmpCod AND
      NUMERO = NNUMERO AND
      VALOR >0 
      ORDER BY DESCRIPCION;
CURSOR cObligaciones_AFJ(nCodProv NUMBER) IS --(Haber) Cursor de Obligaciones a Proveedores
SELECT EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,DESCRIPCION
FROM  Obligaciones_AFJ
WHERE EMP_CODIGO = cEmpCod AND
      NUMERO = nCodProv;

TYPE tMovCnt  IS TABLE OF MOVIMIENTOS%ROWTYPE INDEX BY BINARY_INTEGER;
rMovCnt tMovCnt; -- Tabla en donde se guardan los datos antes de Contabilizar
nContMesCerrado NUMBER:=0;-- Devuelve 1 si el mes esta cerrado caso contrario 0
BEGIN
BEGIN
  SELECT NOMBRE_SECUENCIA INTO cNOMBRE_SEC
  FROM TIPOS_COMPROBANTES_EMPRESAS
  WHERE EMP_CODIGO = cEmpCod AND
        TPOCMP_CODIGO = cTpoCmp;
  GNRL.ACTUALIZA_SECUENCIA(cNOMBRE_SEC,nClave);
  OPEN cMesCerrado;
  FETCH cMesCerrado INTO nContMesCerrado;
  IF nContMesCerrado>0 THEN
-- Error no se puede contabilizar para un mes cerrado
      QMS$ERRORS.SHOW_MESSAGE('CNT-00046');-- No se puede crear un comprobante de un mes ya cerrado
  END IF;
  OPEN cPrvAF;
  FETCH cPrvAf INTO nCodProv;
  CLOSE cPrvAF;
  VALIDAR_CONTABILIZACION_AF(cEmpCod,'ING',NNUMERO,'CAF',NULL);   
  -- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  BEGIN
     vDescIng:=cBeneficiario||' Ingreso de Activos Fijos y Suministros con factura No. '||TO_CHAR(nfactura)||' del ingreso No.'||TO_CHAR(NNUMERO);
     INSERT INTO COMPROBANTES (TPOCMPEMP_EMP_CODIGO,TPOCMPEMP_TPOCMP_CODIGO,FECHA,CLAVE,
                               MAYORIZADO,ESTADO,TOTAL,MONEDA_LOCAL,TIPO_DE_CAMBIO,TIPO_DE_CAMBIOE,
                               CONCEPTO,CRRMES_MES,CONTABILIZADO_DESDE)
     VALUES (cEmpCod,cTpoCmp,dFechaCmp,nClave,'F','N',0,vMonedaLocal,nTipoCambio,nTipoCambioE,vDescIng,NULL,'ACF'); 
     IF cTipo = 'CMP' THEN        
        FOR rAsociaciones_Cmp IN cAsociaciones_Comprobantes LOOP
           IF rAsociaciones_Cmp.nombre = 'BENEFICIARIO' THEN
              cDocumento:=cBeneficiario;
           ELSIF rAsociaciones_Cmp.nombre = 'TIPO COMPROBANTE' THEN
              cDocumento:=cTpoComprobante;
           ELSIF rAsociaciones_Cmp.nombre = 'FACTURA/NO COMP.' THEN
              cDocumento:=TO_CHAR(nFactura);
           ELSIF rAsociaciones_Cmp.nombre = 'FECHA EMISION' THEN
              cDocumento:=TO_CHAR(dFechaEmision,'DD/MM/YYYY');    
           ELSIF rAsociaciones_Cmp.nombre = 'FECHA CADUCIDAD' THEN
              cDocumento:=TO_CHAR(dFechaCaducidad,'MM/YYYY');
           ELSIF rAsociaciones_Cmp.nombre = 'ID CREDITO/GASTO' THEN
              cDocumento:=cIDCredito;
           ELSIF rAsociaciones_Cmp.nombre = 'ID RETENCION FUENTE' THEN
              cDocumento:=cIDRetencion;
           ELSIF rAsociaciones_Cmp.nombre = 'IVA COMPRAS' THEN
              cDocumento:=TO_CHAR(nTotalIVA);
           ELSIF rAsociaciones_Cmp.nombre = 'NO. AUTORIZACION' THEN
              cDocumento:=TO_CHAR(nAutorizacionSRI);
           ELSIF rAsociaciones_Cmp.nombre = 'RUC/CED/PSP' THEN
              cDocumento:=cIdentificacion;
           ELSIF rAsociaciones_Cmp.nombre = 'SERIE COMPROBANTE' THEN
              cDocumento:=nSerieFactura;
           ELSIF rAsociaciones_Cmp.nombre = 'SUBTOTAL' THEN
              cDocumento:=TO_CHAR(nSubtotal);
           ELSIF rAsociaciones_Cmp.nombre = 'SUBTOTAL HONORARIOS' THEN
              cDocumento:='0';
           ELSIF rAsociaciones_Cmp.nombre = 'IVA SERVICIOS' THEN
              cDocumento:='0';
           ELSIF rAsociaciones_Cmp.nombre = 'ICE' THEN
              cDocumento:='0';
           ELSIF rAsociaciones_Cmp.nombre = 'DIAS VENCIMIENTO' THEN
              cDocumento:=TO_CHAR(nDias_Plazo);
           END IF;
           IF cDocumento IS NOT NULL THEN
              INSERT INTO ASOCIACIONES_COMPROBANTE (CMP_TPOCMPEMP_EMP_CODIGO,ASCTPOCMP_TPOCMP_CODIGO,CMP_FECHA,
                                                    CMP_CLAVE,ASCTPOCMP_NOMBRE,DOCUMENTO,SECUENCIA)                     
              VALUES(cEmpCod,rAsociaciones_Cmp.TPOCMP_CODIGO,dFechaCmp,nClave,rAsociaciones_Cmp.nombre,
                     cDocumento,rAsociaciones_Cmp.SECUENCIA);
           ELSE
              QMS$ERRORS.SHOW_MESSAGE('CNT-01414',rAsociaciones_Cmp.nombre);
           END IF;  
        END LOOP;
     END IF;
  EXCEPTION 
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo la inserción del Comprobante por error '||SQLERRM);  
  END;
  i:=1;
  nCuadreD:=0;
  FOR rDebe_Ingresos_AFJ IN cDebe_Ingresos_AFJ LOOP
    -- FIJAMOS EL DEBE
    rMovCnt(i).SECUENCIA:=101;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=ROUND(rDebe_Ingresos_AFJ.VALOR,2);
    rMovCnt(i).DEBEE:=ROUND(rDebe_Ingresos_AFJ.VALOR,2)*nTipoCambioE;
    rMovCnt(i).HABER:=0;
    rMovCnt(i).HABERE:=0;
    rMovCnt(i).FECHA:=dFechaCmp;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rDebe_Ingresos_AFJ.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rDebe_Ingresos_AFJ.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rDebe_Ingresos_AFJ.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rDebe_Ingresos_AFJ.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rDebe_Ingresos_AFJ.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rDebe_Ingresos_AFJ.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rDebe_Ingresos_AFJ.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rDebe_Ingresos_AFJ.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:=cbeneficiario||' '||'Factura Nro. '||TO_CHAR(nFactura);
    rMovCnt(i).ASOCIACION:=NULL;
    nCuadreD:=nCuadreD+rMovCnt(i).DEBE;
    i:=i+1;
  END LOOP;
  ncuadreH:=0;
  IF cTipo = 'DNC' THEN
     -- Se fije el haber de una Donación 
     FOR rDonacion IN cDonacion LOOP
       rMovCnt(i).SECUENCIA:=201;
       rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(i).CMP_FECHA:=dFechaCmp;
       rMovCnt(i).CMP_CLAVE:=nClave;
       rMovCnt(i).DEBE:=0;
       rMovCnt(i).DEBEE:=0;
       rMovCnt(i).HABER:=ROUND(nCuadreD,2);
       rMovCnt(i).HABERE:=ROUND(nCuadreD,2)*nTipoCambioE;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rDonacion.EMP_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rDonacion.MYR_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rDonacion.CNT_CODIGO;
       rMovCnt(i).SS_S_A_SC_CODIGO:=rDonacion.SCNT_CODIGO;
       rMovCnt(i).SS_S_A_CODIGO:=rDonacion.AXL_CODIGO;
       rMovCnt(i).SS_S_CODIGO:=rDonacion.SAXL_CODIGO;
       rMovCnt(i).SS_CODIGO:=rDonacion.SAXL2_CODIGO;
       rMovCnt(i).S_CODIGO:=rDonacion.SAXL3_CODIGO;
       rMovCnt(i).DESCRIPCION:='Donaciones de' ||cbeneficiario;
       rMovCnt(i).ASOCIACION:=NULL;   
     END LOOP;
  ELSIF cTipo = 'CMP' THEN
     FOR rRetenciones_AFJ IN cRetenciones_AFJ LOOP
       -- FIJAMOS EL HABER
       rMovCnt(i).SECUENCIA:=201;
       rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(i).CMP_FECHA:=dFechaCmp;
       rMovCnt(i).CMP_CLAVE:=nClave;
       rMovCnt(i).DEBE:=0;
       rMovCnt(i).DEBEE:=0;
       rMovCnt(i).HABER:=ROUND(rRetenciones_AFJ.VALOR,2);
       rMovCnt(i).HABERE:=ROUND(rRetenciones_AFJ.VALOR,2)*nTipoCambioE;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rRetenciones_AFJ.EMP_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rRetenciones_AFJ.MYR_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rRetenciones_AFJ.CNT_CODIGO;
       rMovCnt(i).SS_S_A_SC_CODIGO:=rRetenciones_AFJ.SCNT_CODIGO;
       rMovCnt(i).SS_S_A_CODIGO:=rRetenciones_AFJ.AXL_CODIGO;
       rMovCnt(i).SS_S_CODIGO:=rRetenciones_AFJ.SAXL_CODIGO;
       rMovCnt(i).SS_CODIGO:=rRetenciones_AFJ.SAXL2_CODIGO;
       rMovCnt(i).S_CODIGO:=rRetenciones_AFJ.SAXL3_CODIGO;
       rMovCnt(i).DESCRIPCION:=cbeneficiario||' '||'Factura Nro. '||TO_CHAR(nFactura);
       rMovCnt(i).ASOCIACION:=NULL;
       nCuadreH:=nCuadreH+rMovCnt(i).HABER;
       i:=i+1;
     END LOOP;
     nDifCuadre:=nCuadreD-nCuadreH;
     IF nDifCuadre > 0 THEN 
        FOR rObligaciones_AFJ IN cObligaciones_AFJ(ncodProv) LOOP
          -- FIJAMOS EL HABER PARA LA OBLIGACIÓN
          rMovCnt(i).SECUENCIA:=201;
          rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
          rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
          rMovCnt(i).CMP_FECHA:=dFechaCmp;
          rMovCnt(i).CMP_CLAVE:=nClave;
          rMovCnt(i).DEBE:=0;
          rMovCnt(i).DEBEE:=0;
          rMovCnt(i).HABER:=ROUND(nDifCuadre,2);
          rMovCnt(i).HABERE:=ROUND(nDifCuadre,2)*nTipoCambioE;
          rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rObligaciones_AFJ.EMP_CODIGO;
          rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rObligaciones_AFJ.MYR_CODIGO;
          rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rObligaciones_AFJ.CNT_CODIGO;
          rMovCnt(i).SS_S_A_SC_CODIGO:=rObligaciones_AFJ.SCNT_CODIGO;
          rMovCnt(i).SS_S_A_CODIGO:=rObligaciones_AFJ.AXL_CODIGO;
          rMovCnt(i).SS_S_CODIGO:=rObligaciones_AFJ.SAXL_CODIGO;
          rMovCnt(i).SS_CODIGO:=rObligaciones_AFJ.SAXL2_CODIGO;
          rMovCnt(i).S_CODIGO:=rObligaciones_AFJ.SAXL3_CODIGO;
          rMovCnt(i).DESCRIPCION:='Factura Nro. '||TO_CHAR(nFactura);
          rMovCnt(i).ASOCIACION:=TO_CHAR(nFactura);         
          i:=i+1;
        END LOOP;
     ELSE -- Si es negatiovopresenta un error
        QMS$ERRORS.SHOW_MESSAGE('CNT-01107');
     END IF;
  END IF;
-- AHORA SI NO HA HABIDO NINGUN ERROR CREAMOS LOS DETALLES DEL COMPROBANTE
  FOR I IN 1..rMovCnt.COUNT LOOP
    IF (rMovCnt(I).DEBE=0 AND rMovCnt(I).HABER=0) OR (rMovCnt(I).DEBE>0 AND rMovCnt(I).HABER>0) THEN
      QMS$ERRORS.SHOW_MESSAGE('ADM-00009',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||
                                          rMovCnt(I).SS_S_A_SC_CNT_CODIGO||rMovCnt(I).SS_S_A_SC_CODIGO||
                                          rMovCnt(I).SS_S_A_CODIGO||rMovCnt(I).SS_S_CODIGO||rMovCnt(I).SS_CODIGO||
                                          rMovCnt(I).S_CODIGO||' '||rMovCnt(I).DESCRIPCION||' ** DEBE ** '||
                                          rMovCnt(I).DEBE||' ** HABER **'||rMovCnt(I).HABER,'Comuniquese con Softcase');
    END IF;
    INSERT INTO MOVIMIENTOS (MVM_ID,CMP_TPOCMPEMP_EMP_CODIGO,CMP_TPOCMPEMP_TPOCMP_CODIGO,
  	    CMP_FECHA,CMP_CLAVE,FECHA,SECUENCIA,DEBE,HABER,DEBEE,HABERE,MONEDA,TIPO_DE_CAMBIO,MAYORIZADO,
  	    SS_S_A_SC_CNT_MYR_EMP_CODIGO,SS_S_A_SC_CNT_MYR_CODIGO,SS_S_A_SC_CNT_CODIGO,
  	    SS_S_A_SC_CODIGO,SS_S_A_CODIGO,SS_S_CODIGO,SS_CODIGO,S_CODIGO,
          DESCRIPCION,ASOCIACION,ESTADO_MOVIMIENTO,OBL_OBL_ID)
    VALUES (MVM_SEQ.NEXTVAL,cEmpCod,cTpoCmp,dFechaCmp,nClave,dFechaCmp,rMovCnt(I).SECUENCIA,
      	rMovCnt(I).DEBE,rMovCnt(I).HABER,rMovCnt(I).DEBEE,rMovCnt(I).HABERE,
            vMonedaLocal,nTipoCambio,'F',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO,
            rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO,rMovCnt(I).SS_S_A_SC_CNT_CODIGO,
  	      rMovCnt(I).SS_S_A_SC_CODIGO,rMovCnt(I).SS_S_A_CODIGO,rMovCnt(I).SS_S_CODIGO,
            rMovCnt(I).SS_CODIGO,rMovCnt(I).S_CODIGO,
  	      rMovCnt(I).DESCRIPCION,rMovCnt(I).ASOCIACION,'N',NULL);
           QMS$ERRORS.SHOW_DEBUG_INFO(rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||
                               rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||
                               rMovCnt(I).SS_S_A_SC_CNT_CODIGO||
                               rMovCnt(I).SS_S_A_SC_CODIGO||
                               rMovCnt(I).SS_S_A_CODIGO||
                               rMovCnt(I).SS_S_CODIGO||
                               rMovCnt(I).SS_CODIGO||
                               rMovCnt(I).S_CODIGO||
                               rMovCnt(I).DESCRIPCION||' '||
                               TO_CHAR(rMovCnt(I).DEBE)||' '||
                               TO_CHAR(rMovCnt(I).HABER)); 
  END LOOP;
  -- Una vez generado el comprobante de Ingreso por compra, se genera la Retención 
  IF cTipo = 'CMP' THEN
     CNT.Validacion_SRI('TL',dFechaCmp,cIdentificacion,cTpoComprobante,dFechaEmision,
                        nSerieFactura,NULL,NULL,nFactura,nAutorizacionSRI,cIDCredito,
                        cIDRetencion); 
     IF NOT CNT.Crear_Retenciones(cEmpCod,cTpoCmp,dFechaCmp,nClave,nIVA,vMonedaLocal,
                                  cTpoComprobante,cIDRetencion,cIDCredito,'PAF') THEN
        QMS$ERRORS.SHOW_MESSAGE('No se pudo crear la Retención'); 
     END IF;   
  END IF;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
   -- FALLA SI NO ENCUENTRA LA SECUENCIA DEL COMPROBANTE
   QMS$ERRORS.SHOW_MESSAGE('CNT-01408',cTpoCmp);
END;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
-- FALLA SI YA EXISTE UN COMPROBANTE IGUAL (CABECERA)
    QMS$ERRORS.SHOW_MESSAGE('CNT-01010',cTpoCmp||'-'||TO_CHAR(dFechaCmp,'DD/MM/YYYY')||'-'||TO_CHAR(nClave));
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo en el procedimiento CONTABILIZAR_INGRESOS_AFJ por error '||SQLERRM);
END;
END;
/* Contabilizar los ingresos de caja medica */
PROCEDURE CONTABILIZAR_INGRESOS_CM
 (NCNTINGCMID NUMBER
 ,NTIPOCAMBIO NUMBER
 ,NTIPOCAMBIOE NUMBER
 ,VMONEDALOCAL VARCHAR2
 ,CEMPCOD VARCHAR2
 ,CTPOCMP VARCHAR2
 ,DFECHACMP DATE
 ,NCLAVE NUMBER
 ,DFECHADESDE DATE
 ,DFECHAHASTA DATE
 )
 IS
DECLARE
-- Debe ser llamada desde EL POST-update
-- errores CNT-01204 PARAMETRO NO DEFINIDO
--         CNT-01205 MODO DE PAGO NO DEFINIDO
--         CNT-01206 Existen Pagos a Caja medica no contabilizados
--         CNT-01207 El modo de pago no tiene cuenta contable asociada
--         CNT-01208 El Medico/Beneficiario no tiene cuenta contable asociada
--         CNT-01209 Tasa de Servicio sin cuenta asociada
--         CNT-01210 Valor de Tasa de servicio difiere del detalle de contabilizacion con el valor de caja medica
--         CNT-01211 Tasa de Servicio borrada o anulada
--         CNT-01212 Diferencia entre el detalle prorateado de los ingresos de medicos y el ingreso

-- **********************************************
-- ESTA PENDIENTE LOS DESCUENTOS Y LAS OBLIGACIONES
-- **********************************************
CURSOR cDdsCMCnt IS -- INGRESOS POR PLANILLAS (DEBE) 1a Etapa
  SELECT * FROM Deudas_CM_Cnt
  WHERE CNTINGCM_ID=nCntIngCMId AND ROUND(VALOR,2)>0  
  ORDER BY CJA_CODIGO,PLNHNRMDC_NUMERO;
CURSOR cPagosCMnoContabilizados IS -- Vemos cuales pagos de honorarios no estan contabilizados por caja medica
  SELECT PGSCM.PLNHNRMDC_NUMERO,DDSCMCNT.NUMERO,DDSCMCNT.MDOPGO_DESCRIPCION
  FROM PAGOS_CM PGSCM,DEUDAS_CM_CNT DDSCMCNT
  WHERE PGSCM.NUMERO=DDSCMCNT.NUMERO
    AND DDSCMCNT.CNTINGCM_ID=nCntIngCMId
    AND DDSCMCNT.TIPO='PGSHNR'
    AND PGSCM.ESTADO NOT IN ('EJC','PRE')
    AND PGSCM.FECHA_CONTABILIZACION IS NULL;

  vPagosNoConta VARCHAR2(2000):='';

/* INGRESOS A Medicos 1a Etapa */
CURSOR cIngMdcCM (nPlnHnrMdc NUMBER,nPgoCm NUMBER) IS -- INGRESOS A ESAS FACTURAS (HABER)
  SELECT CUENTA,EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,BENEFICIARIO||'-'||ID BENEFICIARIO,SUM (VALOR) VALOR
  FROM DETALLES_INGRESOS_CM
  WHERE PLNHNRMDC_NUMERO=nPlnHnrMdc
    AND PGS_CM_NUMERO=nPgoCm
  GROUP BY CUENTA,EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,
        AXL_CODIGO,SAXL_CODIGO,SAXL2_CODIGO,SAXL3_CODIGO,BENEFICIARIO||'-'||ID
  ORDER BY 10 ASC;

CURSOR cBanco IS
  SELECT PRMINT.CUENTA_CONTABLE,
         PLNCNT.EMP_CODIGO EMP_CODIGO, PLNCNT.MYR_CODIGO
         MYR_CODIGO, PLNCNT.CNT_CODIGO CNT_CODIGO, PLNCNT.SCNT_CODIGO SCNT_CODIGO,
         PLNCNT.AXL_CODIGO AXL_CODIGO, PLNCNT.SAXL_CODIGO SAXL_CODIGO,
         PLNCNT.SAXL2_CODIGO SAXL2_CODIGO, PLNCNT.SAXL3_CODIGO SAXL3_CODIGO
  FROM PARAMETROS_INTEGRACION PRMINT,PLAN_DE_CUENTAS PLNCNT
  WHERE PRMINT.EMP_CODIGO=cEmpCod
    AND PRMINT.PARAMETRO='CJMDPS'
    AND PRMINT.TIPO='CJM'
    AND PRMINT.CUENTA_CONTABLE=PLNCNT.CODIGO (+);

/* TASA DE SERVICION 2a ETAPA */

CURSOR cTS(nID NUMBER,nPlnHnrMdc NUMBER,nPgoCm NUMBER) IS
  SELECT *
  FROM TASA_SERVICIOS_CM_CNT
  WHERE CNTINGCM_ID=nID AND PLNHNRMDC_NUMERO=nPlnHnrMdc AND NUMERO=nPgoCm;


/* Los detalles en los que se procesara la Segunda Etapa solo para
   Devoluciones, Notas de Credito, Tasa Servicios y Retenciones en la Fuente */
CURSOR cDtlCnt2Etapa IS
  SELECT *
  FROM DETALLES_CONTABILIZACION_CM
  WHERE CNTINGCM_CNTINGCM_ID=nCntIngCMId AND TIPO IN ('DSCTSR')
  ORDER BY ORDEN,CJA_CODIGO,NUMERO;

CURSOR cMesCerrado IS
  SELECT COUNT(*)
    FROM CIERRES_DE_MES
    WHERE TRUNC(MES,'MM')=TRUNC(dFechaCmp,'MM')
      AND  ESTADO='C';
  nContMesCerrado NUMBER:=0;-- Devuelve 1 si el mes esta cerrado caso contrario 0
TYPE tMovCnt  IS TABLE OF MOVIMIENTOS%ROWTYPE INDEX BY BINARY_INTEGER;
  vCtaBanco PARAMETROS_INTEGRACION.CUENTA_CONTABLE%TYPE;
  rMovCnt tMovCnt; -- Tabla donde guardaremos los datos antes de contabilizar
  I NUMBER:=1;
  nNumIng NUMBER:=1; -- Secuencia de la 1a Etapa
  nNum2 NUMBER:=1; -- Secuencia de la 2a Etapa
  nNumSec2 NUMBER:=2000; -- Secuencia de la 2a Etapa
  nNumSec2TS NUMBER:=2100; -- Secuencia de la 2a Etapa Tasa Servicio
  nNumSec2Pagos NUMBER:=2200; -- Secuencia de la 2a Etapa Pagos a caja medica
  nTempVerificador NUMBER:=0; -- Contador que verifica que entro en un bucle
  nTotalDep NUMBER:=0;  -- El total del deposito
  nTamAso NUMBER:=20;
  vDescIng VARCHAR2(4000);
  vTipoAnt VARCHAR2(30):='';
  vDesc VARCHAR2(4000);
-- nCuadreH -> Guarda los totales parciales del haber para ver que cuadren con el debe
-- de nCuadreD si no cuadra resta o suma la diferencia al ultimo movimiento del haber
  nCuadreH NUMBER:=0;
  nCuadreD NUMBER:=0;
  nDifCuadre NUMBER:=0;
  nTemp NUMBER:=0; -- contador temporal
-- Los parametros que vienen a continuacion son para el manejo de errores
  nTempCmp NUMBER;
  nContErrores NUMBER:=0;
  ERRORES_CONTABILIZA EXCEPTION;
  PRAGMA EXCEPTION_INIT(ERRORES_CONTABILIZA,-20200);
BEGIN
-- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  OPEN cMesCerrado;
  FETCH cMesCerrado INTO nContMesCerrado;
  IF nContMesCerrado>0 THEN
-- Error no se puede contabilizar para un mes cerrado
      QMS$ERRORS.SHOW_MESSAGE('CNT-00046');-- No se puede crear un comprobante de un mes ya cerrado
  END IF;
  vDescIng:='Ingresos de Caja Medica de '||TO_CHAR(dFECHADESDE,'DD/MM/YYYY HH24:MI')||' hasta '||
         TO_CHAR(dFECHAHASTA,'DD/MM/YYYY HH24:MI');

  SELECT COUNT(*) 
    INTO nTempCmp
    FROM COMPROBANTES
    WHERE TPOCMPEMP_EMP_CODIGO=cEmpCod AND
        TPOCMPEMP_TPOCMP_CODIGO=cTpoCmp AND
        FECHA=dFechaCmp AND
        CLAVE=nClave;
  IF nTempCmp>0 THEN
-- Ya existe el comprobante
     RAISE DUP_VAL_ON_INDEX;
  END IF;

/* Antes de procesar cualquier cosa vemos que todos los pagos este contabilizar en caja medica */
  nTemp:=0;
  vPagosNoConta:='';
  FOR rPagosCMnoContabilizados IN cPagosCMnoContabilizados LOOP
    vPagosNoConta:=vPagosNoConta||' Planilla # '||rPagosCMnoContabilizados.PLNHNRMDC_NUMERO;
    vPagosNoConta:=vPagosNoConta||' Pago CM # '||rPagosCMnoContabilizados.NUMERO||' '||rPagosCMnoContabilizados.MDOPGO_DESCRIPCION;
    nTemp:=nTemp+1;
    IF LENGTH (vPagosNoConta)>=200 THEN
      vPagosNoConta:=vPagosNoConta||' y otros.';
      exit;
    END IF;
  END LOOP;
  IF nTemp>0 THEN
-- Solo muestra hasta 250 caracteres
    QMS$ERRORS.SHOW_MESSAGE('CNT-01206',SUBSTR(vPagosNoConta,1,250));
  END IF;
-- Enceramos la tabla de errores para la sesion actual
  GNRL.ESCRIBIR_ERRORES('000000');
/* PRIMERA ETAPA*/
-- Primero creamos los movimientos para los INGRESOS (Cuotas canceladas) de Caja Medica
-- Para la primera etapa la secuencia sera 1000+ el Numero del ingreso
  nTotalDep:=0;
  nNumIng:=1;
  FOR rDdsCMCnt IN cDDsCMCnt LOOP
  	-- FIJAMOS EL DEBE
    QMS$ERRORS.SHOW_DEBUG_INFO('Pago '||rDdsCMCnt.DESCRIPCION||' HC:'||LTRIM(TO_CHAR(rDdsCMCnt.NUMERO_HC)));
    QMS$ERRORS.SHOW_DEBUG_INFO('VALOR '||to_char(ROUND(rDdsCMCnt.VALOR,2)));
    rMovCnt(i).SECUENCIA:=1000+nNumIng;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=ROUND(rDdsCMCnt.VALOR,2);
    rMovCnt(i).DEBEE:=ROUND(rDdsCMCnt.VALOR,2)*nTipoCambioE;
    rMovCnt(i).HABER:=0;
    rMovCnt(i).HABERE:=0;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rDdsCMCnt.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rDdsCMCnt.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rDdsCMCnt.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rDdsCMCnt.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rDdsCMCnt.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rDdsCMCnt.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rDdsCMCnt.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rDdsCMCnt.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:=SUBSTR(rDdsCMCnt.DESCRIPCION||' HC:'||LTRIM(TO_CHAR(rDdsCMCnt.NUMERO_HC)),1,120);
    rMovCnt(i).ASOCIACION:=SUBSTR(rDdsCMCnt.ASOCIACION,1,nTamAso);
    nTotalDep:=nTotalDep+rDdsCMCnt.VALOR;
    ncuadreH:=0;
    nCuadreD:=rMovCnt(i).DEBE;
    i:=i+1;
    IF rDdsCMCnt.CUENTA IS NOT NULL THEN
      UPDATE PAGOS_CM
      SET CONTABILIZADO=DECODE (ESTADO,'CNC','V','P')
      WHERE NUMERO=rDdsCMCnt.NUMERO
            AND PLNHNRMDC_NUMERO=rDdsCMCnt.PLNHNRMDC_NUMERO AND ESTADO!='ANL'
            AND ABS(VALOR-rDdsCMCnt.VALOR)<0.02;
      IF SQL%ROWCOUNT!=1 THEN
-- Si no actualizo un registro, significa que hubo un error y la cuota estaba anulada o no existe
        nContErrores:=nContErrores+1;
        GNRL.ESCRIBIR_ERRORES('CNT-01205',rDdsCMCnt.NUMERO,rDdsCMCnt.PLNHNRMDC_NUMERO);
--        QMS$ERRORS.SHOW_MESSAGE('CNT-01205',rDdsCMCnt.NUMERO,rDdsCMCnt.PLNHNRMDC_NUMERO);
      END IF;
    ELSE
        nContErrores:=nContErrores+1;
        GNRL.ESCRIBIR_ERRORES('CNT-01207',rDdsCMCnt.MDOPGO_DESCRIPCION,rDdsCMCnt.PLNHNRMDC_NUMERO,rDdsCMCnt.NUMERO_HC); -- El modo de pago no tiene cuenta asociada
--        QMS$ERRORS.SHOW_MESSAGE('CNT-01207',rDdsCMCnt.MDOPGO_DESCRIPCION,rDdsCMCnt.PLNHNRMDC_NUMERO,rDdsCMCnt.NUMERO_HC); -- El modo de pago no tiene cuenta asociada
    END IF;

    FOR rIngMdcCM IN cIngMdcCM(rDdsCMCnt.PLNHNRMDC_NUMERO,rDdsCMCnt.NUMERO) LOOP
        IF rIngMdcCM .CUENTA IS NULL THEN
          nContErrores:=nContErrores+1;
          GNRL.ESCRIBIR_ERRORES('CNT-01208',rIngMdcCM.BENEFICIARIO);-- El medico no tiene cuenta asociada
--          QMS$ERRORS.SHOW_MESSAGE('CNT-01208',rIngMdcCM.BENEFICIARIO);-- El medico no tiene cuenta asociada
        END IF;
        QMS$ERRORS.SHOW_DEBUG_INFO('Beneficiario '||rIngMdcCM.BENEFICIARIO);
        QMS$ERRORS.SHOW_DEBUG_INFO('VALOR '||to_char(ROUND(rIngMdcCM.VALOR,2)));
        rMovCnt(i).SECUENCIA:=1000+nNumIng;
        rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
        rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
        rMovCnt(i).CMP_FECHA:=dFechaCmp;
        rMovCnt(i).CMP_CLAVE:=nClave;
        rMovCnt(i).DEBE:=0;
        rMovCnt(i).DEBEE:=0;
        rMovCnt(i).HABER:=ROUND(rIngMdcCM.VALOR,2);
        rMovCnt(i).HABERE:=ROUND(rIngMdcCM.VALOR,2)*nTipoCambioE;
        rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rIngMdcCM.EMP_CODIGO;
        rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rIngMdcCM.MYR_CODIGO;
        rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rIngMdcCM.CNT_CODIGO;
        rMovCnt(i).SS_S_A_SC_CODIGO:=rIngMdcCM.SCNT_CODIGO;
        rMovCnt(i).SS_S_A_CODIGO:=rIngMdcCM.AXL_CODIGO;
        rMovCnt(i).SS_S_CODIGO:=rIngMdcCM.SAXL_CODIGO;
        rMovCnt(i).SS_CODIGO:=rIngMdcCM.SAXL2_CODIGO;
        rMovCnt(i).S_CODIGO:=rIngMdcCM.SAXL3_CODIGO;
        rMovCnt(i).DESCRIPCION:=SUBSTR(rDdsCMCnt.DESCRIPCION||' HC:'||LTRIM(TO_CHAR(rDdsCMCnt.NUMERO_HC)||' Planilla # '||rDdsCMCnt.PLNHNRMDC_NUMERO),1,120);
        rMovCnt(i).ASOCIACION:=NULL;
        nCuadreH:=nCuadreH+rMovCnt(i).HABER;
        i:=i+1;
      END LOOP;
      nDifCuadre:=nCuadreD-nCuadreH;
      IF nDifCuadre!=0 THEN
        IF ABS(nDifCuadre)<=0.05 THEN
          rMovCnt(i-1).HABER:=rMovCnt(i-1).HABER+nDifCuadre;
          rMovCnt(i-1).HABERE:=rMovCnt(i-1).HABERE+(nDifCuadre*nTipoCambioE);
        ELSE
          nContErrores:=nContErrores+1;
          GNRL.ESCRIBIR_ERRORES('CNT-01212',rDdsCMCnt.NUMERO_HC,rDdsCMCnt.PLNHNRMDC_NUMERO,nDifCuadre);
--          QMS$ERRORS.SHOW_MESSAGE('CNT-01212',rDdsCMCnt.NUMERO_HC,rDdsCMCnt.PLNHNRMDC_NUMERO,nDifCuadre);
        END IF;
      END IF;
    nNumIng:=nNumIng+1;
  END LOOP;
/* SEGUNDA ETAPA */
-- La secuencia ira aumentando de acuerdo a:
--                                  Deposito            => 2000
--                                  Tasa de Servicios   => 2100
--                                  cobros realizados   => 2200, etc
  nNum2:=1;
/******************* DESCUENTOS DE LA SEGUNDA ETAPA *******************************/
-- AHORA PROCESAMOS Los descuentos de la tercera etapa en orden
  vTipoAnt:='';
  FOR rDtlCnt2Etapa IN cDtlCnt2Etapa LOOP
     QMS$ERRORS.SHOW_DEBUG_INFO('TIPO '||rDtlCnt2Etapa.TIPO);
     QMS$ERRORS.SHOW_DEBUG_INFO('NUMERO '||rDtlCnt2Etapa.NUMERO);
     IF NVL(vTipoAnt,'$$$$$$')!=rDtlCnt2Etapa.TIPO THEN
-- Enceramos el contador para que empieze en 1 cuando cambia el TIPO cambia
        vTipoAnt:=rDtlCnt2Etapa.TIPO;
        nNum2:=1;
     END IF;
     QMS$ERRORS.SHOW_DEBUG_INFO('nNum2 '||to_char(nNum2));
     QMS$ERRORS.SHOW_DEBUG_INFO('vTipoant '||NVL(vTipoAnt,'NULO'));
     IF rDtlCnt2Etapa.TIPO='DSCTSR' THEN
/**************************** LLENAMOS LA TASA DE SERVICIOS *****************************/
       nTempVerificador:=0;
       FOR rTS IN cTS(rDtlCnt2Etapa.CNTINGCM_CNTINGCM_ID,rDtlCnt2Etapa.PLNHNRMDC_NUMERO,rDtlCnt2Etapa.NUMERO) LOOP
-- Aqui solo va a entrar una sola vez si la nota que creo la tasa de servicio no esta anulada
         IF rTS.CUENTA IS NULL THEN
           nContErrores:=nContErrores+1;
           GNRL.ESCRIBIR_ERRORES('CNT-01209',rTS.MDOPGO_DESCRIPCION,rDtlCnt2Etapa.PLNHNRMDC_NUMERO);-- La tasa de Servicio no tiene vinculada una cuenta contable
--           QMS$ERRORS.SHOW_MESSAGE('CNT-01209',rTS.MDOPGO_DESCRIPCION,rDtlCnt2Etapa.PLNHNRMDC_NUMERO);-- La tasa de Servicio no tiene vinculada una cuenta contable
         END IF;
         IF ABS(rDtlCnt2Etapa.VALOR-rTS.VALOR)>=0.01 THEN
-- Si el valor de la tasa de servicio difiere del guardado en el detalle de la contabilizacion
-- damos un error indicando ello
           nContErrores:=nContErrores+1;
           GNRL.ESCRIBIR_ERRORES('CNT-01210',rTS.MDOPGO_DESCRIPCION,rDtlCnt2Etapa.PLNHNRMDC_NUMERO,ROUND(rTS.VALOR,2),ROUND(rDtlCnt2Etapa.VALOR,2));-- La tasa de Servicio no tiene vinculada una cuenta contable
--           QMS$ERRORS.SHOW_MESSAGE('CNT-01210',rTS.MDOPGO_DESCRIPCION,rDtlCnt2Etapa.PLNHNRMDC_NUMERO,ROUND(rTS.VALOR,2),ROUND(rDtlCnt2Etapa.VALOR,2));-- La tasa de Servicio no tiene vinculada una cuenta contable
         END IF;
         rMovCnt(i).SECUENCIA:=nNumSec2TS+nNum2;
         rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
         rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
         rMovCnt(i).CMP_FECHA:=dFechaCmp;
         rMovCnt(i).CMP_CLAVE:=nClave;
         rMovCnt(i).DEBE:=ROUND(rTS.VALOR,2);
         rMovCnt(i).DEBEE:=ROUND(rTS.VALOR,2)*nTipoCambioE;
         nTotalDep:=nTotalDep-ROUND(rTS.VALOR,2); -- Restamos la cantidad a Depositar
         rMovCnt(i).HABER:=0;
         rMovCnt(i).HABERE:=0;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rTS.EMP_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rTS.MYR_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rTS.CNT_CODIGO;
         rMovCnt(i).SS_S_A_SC_CODIGO:=rTS.SCNT_CODIGO;
         rMovCnt(i).SS_S_A_CODIGO:=rTS.AXL_CODIGO;
         rMovCnt(i).SS_S_CODIGO:=rTS.SAXL_CODIGO;
         rMovCnt(i).SS_CODIGO:=rTS.SAXL2_CODIGO;
         rMovCnt(i).S_CODIGO:=rTS.SAXL3_CODIGO;
         rMovCnt(i).DESCRIPCION:=SUBSTR('Tasa de Servicio '||rTS.MDOPGO_DESCRIPCION||' Pago CM #'||rTS.NUMERO||' '||rTS.DESCRIPCION,1,120);
         rMovCnt(i).ASOCIACION:=NULL;
         i:=i+1;
         nTempVerificador:=nTempVerificador+1;
       END LOOP;
       IF nTempVerificador=0 THEN
         nContErrores:=nContErrores+1;
         GNRL.ESCRIBIR_ERRORES('CNT-01211',rDtlCnt2Etapa.NUMERO,rDtlCnt2Etapa.PLNHNRMDC_NUMERO);
--         QMS$ERRORS.SHOW_MESSAGE('CNT-01211',rDtlCnt2Etapa.NUMERO,rDtlCnt2Etapa.PLNHNRMDC_NUMERO);
       ELSIF nTempVerificador>1 THEN
-- Si es mayor que 1 hay un error en la vista
         nContErrores:=nContErrores+1;
         GNRL.ESCRIBIR_ERRORES('ADM-00011','Error en la vista TASA_SERVICIOS_CM_CNT para la CUENTA POR COBRAR #'||rDtlCnt2Etapa.PLNHNRMDC_NUMERO||' Comuniquese con Softcase C Ltda');
--         QMS$ERRORS.SHOW_MESSAGE('ADM-00011','Error en la vista TASA_SERVICIOS_CM_CNT para la CUENTA POR COBRAR #'||rDtlCnt2Etapa.PLNHNRMDC_NUMERO||' Comuniquese con Softcase C Ltda');
       END IF;
       nNum2:=nNum2+1;-- Subimos la Secuencia para los siguientes DESCUENTOS TERCERA ETAPA
/********************************** FIN TASA DE SERVICIOS **********************************/
     END IF;
  END LOOP;
/******************* FIN DESCUENTOS DE LA SEGUNDA ETAPA *******************************/
  nNum2:=1;
  FOR rBanco IN cBanco LOOP
-- Primero hacemos el depósito de bancos
    IF ROUND(nTotalDep,2)>0  THEN
-- Solo cuando hay deposito genera el movimiento en la cuenta de banco
-- caso contrario no. Para evitar que genere un movimiento con debe=0 y haber=0
      rMovCnt(i).SECUENCIA:=nNumSec2;
      rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
      rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
      rMovCnt(i).CMP_FECHA:=dFechaCmp;
      rMovCnt(i).CMP_CLAVE:=nClave;
      rMovCnt(i).DEBE:=ROUND(nTotalDep,2);
      rMovCnt(i).DEBEE:=ROUND(nTotalDep,2)*nTipoCambioE;
      rMovCnt(i).HABER:=0;
      rMovCnt(i).HABERE:=0;
      rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rBanco.EMP_CODIGO;
      rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rBanco.MYR_CODIGO;
      rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rBanco.CNT_CODIGO;
      rMovCnt(i).SS_S_A_SC_CODIGO:=rBanco.SCNT_CODIGO;
      rMovCnt(i).SS_S_A_CODIGO:=rBanco.AXL_CODIGO;
      rMovCnt(i).SS_S_CODIGO:=rBanco.SAXL_CODIGO;
      rMovCnt(i).SS_CODIGO:=rBanco.SAXL2_CODIGO;
      rMovCnt(i).S_CODIGO:=rBanco.SAXL3_CODIGO;
      rMovCnt(i).DESCRIPCION:=SUBSTR('Deposito de Caja Medica '||vDescIng,1,120);
      rMovCnt(i).ASOCIACION:=NULL;
      i:=i+1;
   END IF;
   nNum2:=nNum2+1;
  END LOOP;
  IF nNum2=1 THEN
-- No existe el parametro de bancos porque el nNumDep sale sin sumar uno, no entro al bucle anterior
    nContErrores:=nContErrores+1;
    GNRL.ESCRIBIR_ERRORES('CNT-01204','Deposito de Caja Medica');-- El parametro de la cuenta contable del Banco no fijado
--    QMS$ERRORS.SHOW_MESSAGE('CNT-01204','Deposito de Caja Medica');-- El parametro de la cuenta contable del Banco no fijado
  END IF;
  nNum2:=1;
  FOR rDDsCMCnt IN cDDsCMCnt LOOP
-- Las deudas CM van ahora al haber para el deposito
    -- FIJAMOS EL HABER
    rMovCnt(i).SECUENCIA:=nNumSec2Pagos+nNum2;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=0;
    rMovCnt(i).DEBEE:=0;
    rMovCnt(i).HABER:=ROUND(rDdsCMCnt.VALOR,2);
    rMovCnt(i).HABERE:=ROUND(rDdsCMCnt.VALOR,2)*nTipoCambioE;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rDdsCMCnt.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rDdsCMCnt.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rDdsCMCnt.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rDdsCMCnt.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rDdsCMCnt.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rDdsCMCnt.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rDdsCMCnt.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rDdsCMCnt.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:=SUBSTR(rDdsCMCnt.DESCRIPCION||' HC:'||LTRIM(TO_CHAR(rDdsCMCnt.NUMERO_HC)),1,120);
    rMovCnt(i).ASOCIACION:=SUBSTR(rDdsCMCnt.ASOCIACION,1,nTamAso);
    i:=i+1;
    nNum2:=nNum2+1;
  END LOOP;
-- AHORA SI NO HA HABIDO NINGUN ERROR CREAMOS LOS DETALLES DEL COMPROBANTE
  IF nContErrores=0 THEN

    INSERT INTO COMPROBANTES (TPOCMPEMP_EMP_CODIGO,TPOCMPEMP_TPOCMP_CODIGO,FECHA,CLAVE,
         MAYORIZADO,ESTADO,TOTAL,MONEDA_LOCAL,TIPO_DE_CAMBIO,TIPO_DE_CAMBIOE,
         CONCEPTO,CRRMES_MES,CONTABILIZADO_DESDE)
     VALUES (cEmpCod,cTpoCmp,dFechaCmp,nClave,'F','N',0,vMonedaLocal,nTipoCambio,nTipoCambioE,vDescIng,NULL,'CJM');


    FOR I IN 1..rMovCnt.COUNT LOOP
      IF (rMovCnt(I).DEBE=0 AND rMovCnt(I).HABER=0) OR (rMovCnt(I).DEBE>0 AND rMovCnt(I).HABER>0) THEN
        QMS$ERRORS.SHOW_MESSAGE('ADM-00011',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||
            rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||rMovCnt(I).SS_S_A_SC_CNT_CODIGO||
  	    rMovCnt(I).SS_S_A_SC_CODIGO||rMovCnt(I).SS_S_A_CODIGO||rMovCnt(I).SS_S_CODIGO||
            rMovCnt(I).SS_CODIGO||rMovCnt(I).S_CODIGO||' '||rMovCnt(I).DESCRIPCION||' ** DEBE ** '||rMovCnt(I).DEBE||' ** HABER **'||rMovCnt(I).HABER,'Comuniquese con Softcase');
      END IF;
      INSERT INTO MOVIMIENTOS (MVM_ID,CMP_TPOCMPEMP_EMP_CODIGO,CMP_TPOCMPEMP_TPOCMP_CODIGO,
  	    CMP_FECHA,CMP_CLAVE,FECHA,SECUENCIA,DEBE,HABER,DEBEE,HABERE,MONEDA,TIPO_DE_CAMBIO,MAYORIZADO,
  	    SS_S_A_SC_CNT_MYR_EMP_CODIGO,SS_S_A_SC_CNT_MYR_CODIGO,SS_S_A_SC_CNT_CODIGO,
  	    SS_S_A_SC_CODIGO,SS_S_A_CODIGO,SS_S_CODIGO,SS_CODIGO,S_CODIGO,
            DESCRIPCION,ASOCIACION,ESTADO_MOVIMIENTO,OBL_OBL_ID)
        VALUES (MVM_SEQ.NEXTVAL,cEmpCod,cTpoCmp,dFechaCmp,nClave,dFechaCmp,rMovCnt(I).SECUENCIA,
  	    rMovCnt(I).DEBE,rMovCnt(I).HABER,rMovCnt(I).DEBEE,rMovCnt(I).HABERE,
            vMonedaLocal,nTipoCambio,'F',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO,
            rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO,rMovCnt(I).SS_S_A_SC_CNT_CODIGO,
  	    rMovCnt(I).SS_S_A_SC_CODIGO,rMovCnt(I).SS_S_A_CODIGO,rMovCnt(I).SS_S_CODIGO,
            rMovCnt(I).SS_CODIGO,rMovCnt(I).S_CODIGO,
  	    rMovCnt(I).DESCRIPCION,rMovCnt(I).ASOCIACION,'N',NULL);
    END LOOP;
  ELSE
    COMMIT; -- grabamos los errores
    RAISE ERRORES_CONTABILIZA; --Disparamos el error
  END IF;

--    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo en el procedimiento CONTABILIZAR_INGRESOS_FCT por error '|| SQLERRM);
-- Marcamos la fechas como contabilizadas
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
-- FALLA SI YA EXISTE UN COMPROBANTE IGUAL (CABECERA)
    QMS$ERRORS.SHOW_MESSAGE('CNT-01203',cTpoCmp||'-'||TO_CHAR(dFechaCmp,'DD/MM/YYYY')||'-'||TO_CHAR(nClave));
  WHEN ERRORES_CONTABILIZA THEN
-- Errores contabilizando
     RAISE;
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo en el procedimiento CONTABILIZAR_INGRESOS_CM por error '||SQLERRM);
END;
/* Contabiliza los ingresos de la facturacion */
PROCEDURE CONTABILIZAR_INGRESOS_FCT
 (NCNTINGID NUMBER
 ,NTIPOCAMBIO NUMBER
 ,NTIPOCAMBIOE NUMBER
 ,VMONEDALOCAL VARCHAR2
 ,CEMPCOD VARCHAR2
 ,CTPOCMP VARCHAR2
 ,DFECHACMP DATE
 ,NCLAVE NUMBER
 ,DFECHADESDE DATE
 ,DFECHAHASTA DATE
 ,BCNTPRS BOOLEAN := NULL
 )
 IS
DECLARE
-- Debe ser llamada desde EL POST-update
-- errores CNT-01004 PARAMETRO NO DEFINIDO
--         CNT-01005 MODO DE PAGO NO DEFINIDO
--         CNT-01006 CARGO SIN CUENTA ASOCIADA
--         CNT-01007 CAJA SIN CUENTA ASOCIADA
--         CNT-01012 CARGO CON DESCUENTO/DEVOLUCION SIN CUENTA ASOCIADA
--         CNT-01013 Tasa de Servicio no asociada a ninguna cuenta para ese agrupador contable
--         CNT-01014 La nota de la tasa de servicio ya no existe o esta anulada
--         CNT-01015 El valor de la nota (TS) con el detalle de contabilizacion no coinciden
--         CNT-01016 Retencion en la fuente no asociada a ninguna cuenta
--         CNT-01017 La nota de la Retencion ya no existe o esta anulada
--         CNT-01018 El valor de la nota con (RF) el detalle de contabilizacion no coinciden
--         CNT-01019 El valor de la cuota o es estado de la cuota y el detalle de contabilizacion no coinciden
--         CNT-01020 Devolucion o Nota de Credito no puede tener agrupador general.
--         CNT-01021 La Nc de Credito ha sido anulada
--         CNT-01022 La nota de la Retencion ya no existe o esta anulada
--         CNT-01023 El valor de la nota con (Ret del IVA) el detalle de contabilizacion no coinciden
-- **********************************************
-- ESTA PENDIENTE LOS DESCUENTOS Y LAS OBLIGACIONES
-- **********************************************
-- 23/jul/2004	Juan Carlos Cabrera
--			Se añade Retenciones del IVA
-- 06/dic/2005	Juan Carlos Cabrera
--			Se añade el control de Contabilizado a Facturas que no estaba
CURSOR cDdsCntAnt IS -- INGRESOS POR ANTICIPOS (DEBE) 1a Etapa
  SELECT * FROM Deudas_Cnt
  WHERE CNTING_ID=nCntIngId
  AND CTACBR_NUMERO IS NULL AND ROUND(VALOR,2)>0
  ORDER BY CJA_CODIGO,NUMERO;
CURSOR cDdsCnt IS -- INGRESOS POR FACTURAS (DEBE) 2a Etapa
  SELECT * FROM Deudas_Cnt
  WHERE CNTING_ID=nCntIngId AND CTACBR_NUMERO IS NOT NULL
  ORDER BY CTACBR_NUMERO,CUENTA;
CURSOR cNumDdsCnt(nCtaCbr NUMBER) IS -- INGRESOS POR FACTURAS (DEBE)
  SELECT DTLCNTING.POR_ANTICIPOS,DTLCNTING.DESCUENTOS,DTLCNTING.CTACBR_TOTAL,COUNT (DISTINCT DDSCNT.NUMERO) NUMCUOTAS
  FROM DEUDAS_CNT DDSCNT,DETALLES_CONTABILIZACION_ING DTLCNTING
  WHERE DDSCNT.CNTING_ID=nCntIngId AND DDSCNT.CTACBR_NUMERO=nCtaCbr
    AND DTLCNTING.CNTING_CNTING_ID=DDSCNT.CNTING_ID
    AND DTLCNTING.CTACBR_NUMERO=DDSCNT.CTACBR_NUMERO
    AND DTLCNTING.TIPO='INGFCT'
  GROUP BY DTLCNTING.POR_ANTICIPOS,DTLCNTING.DESCUENTOS,DTLCNTING.CTACBR_TOTAL;
/* INGRESOS A FACTURAS 1a Etapa */
CURSOR cFctIng (nCtaCbr NUMBER,vAgrCnt VARCHAR2) IS -- INGRESOS A ESAS FACTURAS (HABER)
  SELECT CUENTA,EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,SUM (VALOR) VALOR
  FROM DETALLES_FACTURAS_INGRESOS
  WHERE CTACBR_NUMERO=nCtaCbr
    AND AGRUPADOR_CONTABLE=vAgrCnt
  GROUP BY CUENTA,EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,
        AXL_CODIGO,SAXL_CODIGO,SAXL2_CODIGO,SAXL3_CODIGO
  ORDER BY 10 ASC;
CURSOR cIngCntIVA (nCtaCbr NUMBER) IS -- INGRESOS POR IVA (HABER) 1a Etapa
  SELECT * FROM INGRESOS_CNT
  WHERE CNTING_ID=nCntIngId AND CTACBR_NUMERO=nCtaCbr
        AND ROUND(VALOR,2)>0;
CURSOR cIngCntAnt (nAnt NUMBER) IS -- INGRESOS POR ANTICIPOS (HABER) 1a Etapa
  SELECT * FROM INGRESOS_CNT
  WHERE CNTING_ID=nCntIngId AND CTACBR_NUMERO IS NULL AND NUMERO=nAnt;
-- Ahora definimos la tabla que guardara los movimientos anter de crearlos en la base de datos
CURSOR cDetFctSinCnt (nCtaCbr NUMBER,vAgrCnt VARCHAR2) IS -- DETALLES DE FACTURAS SIN CUENTA CONTABLE
SELECT DISTINCT ITMCRG.DESCRIPCION
  FROM DETALLES_FACTURAS_INGRESOS DTLFCTING,ITEM_CARGOS ITMCRG
  WHERE DTLFCTING.CTACBR_NUMERO=nCtaCbr AND DTLFCTING.AGRUPADOR_CONTABLE=vAgrCnt AND DTLFCTING.CUENTA IS NULL
    AND DECODE (NVL(ITMCRG.CRG_TIPO,'@#$%&'),'@#$%&',ITMCRG.ITM_TIPO,ITMCRG.CRG_TIPO)=DTLFCTING.CRG_TIPO
    AND DECODE (NVL(ITMCRG.CRG_TIPO,'@#$%&'),'@#$%&',
    ITMCRG.ITM_SBS_SCC_CODIGO||ITMCRG.ITM_SBS_CODIGO||TO_CHAR(ITMCRG.ITM_CODIGO),
    ITMCRG.CRG_CODIGO)=DTLFCTING.CRG_CODIGO;
/* DESCUENTOS A FACTURAS 1a Etapa*/
CURSOR cFctDsc (nCtaCbr NUMBER,vAgrCnt VARCHAR2) IS -- DESCUENTOS A ESAS FACTURAS (DEBE)
  SELECT CUENTA,EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,SUM (VALOR) VALOR
  FROM DETALLES_FACTURAS_DESCUENTOS
  WHERE CTACBR_NUMERO=nCtaCbr
    AND AGRUPADOR_CONTABLE=vAgrCnt
  GROUP BY CUENTA,EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,
        AXL_CODIGO,SAXL_CODIGO,SAXL2_CODIGO,SAXL3_CODIGO
  ORDER BY 10 ASC;
CURSOR cDetDscSinCnt (nCtaCbr NUMBER,vAgrCnt VARCHAR2) IS -- DETALLES DE DESCUENTOS SIN CUENTA CONTABLE
SELECT DISTINCT ITMCRG.DESCRIPCION
  FROM DETALLES_FACTURAS_DESCUENTOS DTLFCTDSC,ITEM_CARGOS ITMCRG
  WHERE DTLFCTDSC.CTACBR_NUMERO=nCtaCbr AND DTLFCTDSC.AGRUPADOR_CONTABLE=vAgrCnt AND DTLFCTDSC.CUENTA IS NULL
    AND DECODE (NVL(ITMCRG.CRG_TIPO,'@#$%&'),'@#$%&',ITMCRG.ITM_TIPO,ITMCRG.CRG_TIPO)=DTLFCTDSC.CRG_TIPO
    AND DECODE (NVL(ITMCRG.CRG_TIPO,'@#$%&'),'@#$%&',
    ITMCRG.ITM_SBS_SCC_CODIGO||ITMCRG.ITM_SBS_CODIGO||TO_CHAR(ITMCRG.ITM_CODIGO),
    ITMCRG.CRG_CODIGO)=DTLFCTDSC.CRG_CODIGO;
/* DEVOLUCIONES A FACTURAS 3a Etapa*/
CURSOR cFctDvl (nDvlNum NUMBER,vAgrCnt VARCHAR2) IS -- DEVOLUCIONES A FACTURAS (DEBE)
  SELECT CUENTA,EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,SUM (VALOR) VALOR
  FROM DETALLES_FACTURAS_DEVOLUCIONES
  WHERE DVL_NUMERO=nDvlNum
    AND AGRUPADOR_CONTABLE=vAgrCnt
  GROUP BY CUENTA,EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,
        AXL_CODIGO,SAXL_CODIGO,SAXL2_CODIGO,SAXL3_CODIGO
  ORDER BY 10 ASC;
CURSOR cDetDvlSinCnt (nDvlNum NUMBER,vAgrCnt VARCHAR2) IS -- DETALLES DE DEVOLUCIONES SIN CUENTA CONTABLE
  SELECT DISTINCT ITMCRG.DESCRIPCION
  FROM DETALLES_FACTURAS_DEVOLUCIONES DTLFCTDVL,ITEM_CARGOS ITMCRG
  WHERE DTLFCTDVL.DVL_NUMERO=nDvlNum AND DTLFCTDVL.AGRUPADOR_CONTABLE=vAgrCnt AND DTLFCTDVL.CUENTA IS NULL
    AND DECODE (NVL(ITMCRG.CRG_TIPO,'@#$%&'),'@#$%&',ITMCRG.ITM_TIPO,ITMCRG.CRG_TIPO)=DTLFCTDVL.CRG_TIPO
    AND DECODE (NVL(ITMCRG.CRG_TIPO,'@#$%&'),'@#$%&',
    ITMCRG.ITM_SBS_SCC_CODIGO||ITMCRG.ITM_SBS_CODIGO||TO_CHAR(ITMCRG.ITM_CODIGO),
    ITMCRG.CRG_CODIGO)=DTLFCTDVL.CRG_CODIGO;
CURSOR cFctDvlIVA (nDvlNum NUMBER) IS -- DEVOLUCIONES A FACTURAS (IVA)
-- Devolucion del iva en facturas
-- Se asume que la cuenta de PARAMETROS_INTEGRACION esta fijada
  SELECT DISTINCT DVL_NUMERO,
    PLNCNT.EMP_CODIGO, PLNCNT.MYR_CODIGO, PLNCNT.CNT_CODIGO ,
    PLNCNT.SCNT_CODIGO , PLNCNT.AXL_CODIGO ,
    PLNCNT.SAXL_CODIGO , PLNCNT.SAXL2_CODIGO ,
    PLNCNT.SAXL3_CODIGO,
    DTLDVLAGR.VALOR_IVA VALOR_IVA
  FROM DETALLES_DEVOLUCIONES_AGRUPADA DTLDVLAGR,
    PARAMETROS_INTEGRACION PRMINT,PLAN_DE_CUENTAS PLNCNT
  WHERE PRMINT.CUENTA_CONTABLE=PLNCNT.CODIGO
    AND PRMINT.EMP_CODIGO=PLNCNT.EMP_CODIGO
    AND PRMINT.PARAMETRO='IVA'
    AND PRMINT.TIPO ='ING'
    AND DTLDVLAGR.VALOR_IVA>0
    AND DVL_NUMERO=nDvlNum;
/* NOTAS DE CREDITOS A FACTURAS */
/* NO HAY IVA Y TODO APLICA TARIFA CERO */
CURSOR cNCDvl (nNC NUMBER,vAgrCnt VARCHAR2) IS -- NOTAS DE CREDITO A FACTURAS (DEBE)
  SELECT CUENTA,EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,SUM (VALOR) VALOR
  FROM DETALLES_FACTURAS_NC
  WHERE NC_NUMERO=nNC
    AND AGRUPADOR_CONTABLE=vAgrCnt
  GROUP BY CUENTA,EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,
        AXL_CODIGO,SAXL_CODIGO,SAXL2_CODIGO,SAXL3_CODIGO
  ORDER BY 10 ASC;
CURSOR cDetNCSinCnt (nNC NUMBER,vAgrCnt VARCHAR2) IS -- DETALLES DE DEVOLUCIONES SIN CUENTA CONTABLE
  SELECT DISTINCT ITMCRG.DESCRIPCION
  FROM DETALLES_FACTURAS_NC DTLFCTDVL,ITEM_CARGOS ITMCRG
  WHERE DTLFCTDVL.NC_NUMERO=nNC AND DTLFCTDVL.AGRUPADOR_CONTABLE=vAgrCnt AND DTLFCTDVL.CUENTA IS NULL
    AND DECODE (NVL(ITMCRG.CRG_TIPO,'@#$%&'),'@#$%&',ITMCRG.ITM_TIPO,ITMCRG.CRG_TIPO)=DTLFCTDVL.CRG_TIPO
    AND DECODE (NVL(ITMCRG.CRG_TIPO,'@#$%&'),'@#$%&',
    ITMCRG.ITM_SBS_SCC_CODIGO||ITMCRG.ITM_SBS_CODIGO||TO_CHAR(ITMCRG.ITM_CODIGO),
    ITMCRG.CRG_CODIGO)=DTLFCTDVL.CRG_CODIGO;
CURSOR cCajas IS
  SELECT *
  FROM CAJAS_CNT
  WHERE CNTING_ID=nCntIngId
  ORDER BY CJA_CODIGO;
CURSOR cCajasCbr(vCjaCod VARCHAR2) IS
  SELECT *
  FROM INGRESOS_CAJAS_CNT
  WHERE CNTING_ID=nCntIngId
    AND CJA_CODIGO=vCjaCod
  ORDER BY ORDEN,CTACBR_NUMERO,NUMERO;
CURSOR cBanco IS
  SELECT PRMINT.CUENTA_CONTABLE,
         PLNCNT.EMP_CODIGO EMP_CODIGO, PLNCNT.MYR_CODIGO
         MYR_CODIGO, PLNCNT.CNT_CODIGO CNT_CODIGO, PLNCNT.SCNT_CODIGO SCNT_CODIGO,
         PLNCNT.AXL_CODIGO AXL_CODIGO, PLNCNT.SAXL_CODIGO SAXL_CODIGO,
         PLNCNT.SAXL2_CODIGO SAXL2_CODIGO, PLNCNT.SAXL3_CODIGO SAXL3_CODIGO
  FROM PARAMETROS_INTEGRACION PRMINT,PLAN_DE_CUENTAS PLNCNT
  WHERE PRMINT.EMP_CODIGO=cEmpCod
    AND PRMINT.PARAMETRO='BNC'
    AND PRMINT.TIPO='ING'
    AND PRMINT.CUENTA_CONTABLE=PLNCNT.CODIGO (+);
/*  ANTICIPOS VINCULADOS 3a ETAPA */
CURSOR cAntVnc IS
  SELECT *
  FROM ANTICIPOS_VINCULADOS_CNT
  WHERE CNTING_ID=nCntIngId
  ORDER BY CJA_CODIGO;
/*  DEVOLUCION ANTICIPOS 3a ETAPA */
CURSOR cDvlAnt IS
  SELECT *
  FROM DEVOLUCION_ANTICIPOS_CNT
  WHERE CNTING_ID=nCntIngId
  ORDER BY CJA_CODIGO;
/* TASA DE SERVICION 3a ETAPA */
CURSOR cTS(nID NUMBER,nCtaCbr NUMBER,nCotCbr NUMBER) IS
  SELECT *
  FROM TASA_SERVICIOS_CNT
  WHERE CNTING_ID=nID AND CTACBR_NUMERO=nCtaCbr AND NUMERO=nCotCbr AND ROUND(VALOR,2)>0;
/* RETENCION EN LA FUENTE 3a ETAPA */
CURSOR cRF(nID NUMBER,nCtaCbr NUMBER,nCotCbr NUMBER) IS
  SELECT *
  FROM RETENCION_EN_LA_FUENTE_CNT
  WHERE CNTING_ID=nID AND CTACBR_NUMERO=nCtaCbr AND NUMERO=nCotCbr AND ROUND(VALOR,2)>0;
/* RETENCION DEL IVA 3a ETAPA */
CURSOR cRIVA(nID NUMBER,nCtaCbr NUMBER,nCotCbr NUMBER) IS
  SELECT *
  FROM RETENCION_DEL_IVA_CNT
  WHERE CNTING_ID=nID AND CTACBR_NUMERO=nCtaCbr AND NUMERO=nCotCbr AND ROUND(VALOR,2)>0;
/* Los detalles en los que se procesara la Tercera Etapa solo para
   Devoluciones, Notas de Credito, Tasa Servicios y Retenciones en la Fuente */
CURSOR cDtlCnt3Etapa IS
  SELECT *
  FROM DETALLES_CONTABILIZACION_ING
  WHERE CNTING_CNTING_ID=nCntIngId AND TIPO IN ('DSCTSI','DSCTSR','DSCDVL','DSCOTR','DSCRTI') AND ROUND(VALOR,2)>0
  ORDER BY ORDEN,CJA_CODIGO,NUMERO;
CURSOR cMesCerrado IS
  SELECT COUNT(*)
    FROM CIERRES_DE_MES
    WHERE TRUNC(MES,'MM')=TRUNC(dFechaCmp,'MM')
      AND  ESTADO='C';
  nContMesCerrado NUMBER:=0;-- Devuelve 1 si el mes esta cerrado caso contrario 0
TYPE tMovCnt  IS TABLE OF MOVIMIENTOS%ROWTYPE INDEX BY BINARY_INTEGER;
  vCtaBanco PARAMETROS_INTEGRACION.CUENTA_CONTABLE%TYPE;
  rMovCnt tMovCnt; -- Tabla donde guardaremos los datos antes de contabilizar
TYPE tIndiceCajas IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  rIndiceCajas tIndiceCajas; -- Cual es el valor de ingreso de cada caja
  I NUMBER:=1;
  nNumIng NUMBER:=1; -- Secuencia de la 1a Etapa
  nNumCbr NUMBER:=1; -- Secuencia de la 2a Etapa
  nNum3 NUMBER:=1; -- Secuencia de la 3a Etapa
  nNumSec3 NUMBER:=3000; -- Secuencia de la 3a Etapa
  nNumSec3Ant NUMBER:=3100; -- Secuencia de la 3a Etapa Anticipos Vinculados
  nNumSec3DvlAnt NUMBER:=3200; -- Secuencia de la 3a Etapa Devolucion Anticipos
  nNumSec3Dvl NUMBER:=3300; -- Secuencia de la 3a Etapa Devolucion a Facturas
  nNumSec3NC NUMBER:=3400; -- Secuencia de la 3a Etapa Notas de Credito
  nNumSec3RIva NUMBER:=3450; -- Secuencia de la 3a Etapa Retencion del IVA
  nNumSec3TS NUMBER:=3500; -- Secuencia de la 3a Etapa Tasa Servicio
  nNumSec3RF NUMBER:=3700; -- Secuencia de la 3a Etapa Retencion Fuente
  nNumSec3Cajas NUMBER:=3900; -- Secuencia de la 3a Etapa Cajas
  nTempVerificador NUMBER:=0; -- Contador que verifica que entro en un bucle
  nTotalDep NUMBER:=0;  -- El total del deposito
  nTamAso NUMBER:=20;
  vDescIng VARCHAR2(4000);
  vTipoAnt VARCHAR2(30):='';
  vDesc VARCHAR2(4000);
  nCtaCbrAnt NUMBER:=0;
  nNumCotCbr NUMBER:=0;-- Cuantas cuotas a cobrar tiene una cuenta por cobrar
  nPorAnticipos NUMBER:=0; -- Cuanto de una cuenta por cobrar se aplica en anticipos
  nTotalCtaCbr NUMBER:=0; -- El total de la cuenta por cobrar
  nPorDescuentos NUMBER:=0;
-- nCuadreH -> Guarda los totales parciales del haber para ver que cuadren con el debe
-- de nCuadreD si no cuadra resta o suma la diferencia al ultimo movimiento del haber
  nCuadreH NUMBER:=0;
  nCuadreD NUMBER:=0;
  nDifCuadre NUMBER:=0;
  Etapa2i NUMBER:=0; -- Almacena el subindice de la caja 2 etapa para verificar el cuadre
  nCaja NUMBER:=1; -- el numero de caja
-- Los parametros que vienen a continuacion son para el manejo de errores
  nTemp NUMBER;
  nContErrores NUMBER:=0;
  ERRORES_CONTABILIZA EXCEPTION;
  PRAGMA EXCEPTION_INIT(ERRORES_CONTABILIZA,-20200);
BEGIN
-- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  OPEN cMesCerrado;
  FETCH cMesCerrado INTO nContMesCerrado;
  IF nContMesCerrado>0 THEN
-- Error no se puede contabilizar para un mes cerrado
      QMS$ERRORS.SHOW_MESSAGE('CNT-00046');-- No se puede crear un comprobante de un mes ya cerrado
  END IF;
  vDescIng:='Ingresos de '||TO_CHAR(dFECHADESDE,'DD/MM/YYYY HH24:MI')||' hasta '||
         TO_CHAR(dFECHAHASTA,'DD/MM/YYYY HH24:MI');
  SELECT COUNT(*) 
    INTO nTemp
    FROM COMPROBANTES
    WHERE TPOCMPEMP_EMP_CODIGO=cEmpCod AND
        TPOCMPEMP_TPOCMP_CODIGO=cTpoCmp AND
        FECHA=dFechaCmp AND
        CLAVE=nClave;
  IF nTemp>0 THEN
-- Ya existe el comprobante
     RAISE DUP_VAL_ON_INDEX;
  END IF;
-- Enceramos la tabla de errores para la sesion actual
  GNRL.ESCRIBIR_ERRORES('000000');
  
/* PRIMERA ETAPA*/
-- Primero creamos los movimientos para los anticipos
-- Para la primera etapa la secuencia sera 100+ el Numero del ingreso
  FOR rDdsCntAnt IN cDDsCntAnt LOOP
    IF rDdsCntAnt.CUENTA IS NULL THEN
      nContErrores:=nContErrores+1;
      GNRL.ESCRIBIR_ERRORES('CNT-01005',rDdsCntAnt.MDOPGO_DESCRIPCION,rDdsCntAnt.NUMERO,rDdsCntAnt.NUMERO_HC);-- El parametro de la cuenta contable para modo de pago efectivo no fijado
--      QMS$ERRORS.SHOW_MESSAGE('CNT-01005',rDdsCntAnt.MDOPGO_DESCRIPCION,rDdsCntAnt.NUMERO,rDdsCntAnt.NUMERO_HC);-- El parametro de la cuenta contable para modo de pago efectivo no fijado
    END IF;
    -- FIJAMOS EL DEBE
    rMovCnt(i).SECUENCIA:=1000+nNumIng;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=ROUND(rDdsCntAnt.VALOR,2);
    rMovCnt(i).DEBEE:=ROUND(rDdsCntAnt.VALOR,2)*nTipoCambioE;
    rMovCnt(i).HABER:=0;
    rMovCnt(i).HABERE:=0;
    rMovCnt(i).FECHA:=dFechaCmp;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rDdsCntAnt.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rDdsCntAnt.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rDdsCntAnt.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rDdsCntAnt.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rDdsCntAnt.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rDdsCntAnt.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rDdsCntAnt.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rDdsCntAnt.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:=SUBSTR(rDdsCntAnt.DESCRIPCION||' HC:'||LTRIM(TO_CHAR(rDdsCntAnt.NUMERO_HC)),1,120);
    rMovCnt(i).ASOCIACION:=NULL;
    nCuadreD:=rMovCnt(i).DEBE;
    ncuadreH:=0;
    i:=i+1;
    FOR rIngCntAnt IN cIngCntAnt(rDdsCntAnt.NUMERO) LOOP
      IF rIngCntAnt.CUENTA IS NULL THEN
        nContErrores:=nContErrores+1;
        GNRL.ESCRIBIR_ERRORES('CNT-01004','Anticipos');-- El parametro de la cuenta contable de los anticipos no fijado
--        QMS$ERRORS.SHOW_MESSAGE('CNT-01004','Anticipos');-- El parametro de la cuenta contable de los anticipos no fijado
      END IF;
      -- FIJAMOS EL HABER
      rMovCnt(i).SECUENCIA:=1000+nNumIng;
      rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
      rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
      rMovCnt(i).CMP_FECHA:=dFechaCmp;
      rMovCnt(i).CMP_CLAVE:=nClave;
      rMovCnt(i).DEBE:=0;
      rMovCnt(i).DEBEE:=0;
      rMovCnt(i).HABER:=ROUND(rIngCntAnt.VALOR,2);
      rMovCnt(i).HABERE:=ROUND(rIngCntAnt.VALOR,2)*nTipoCambioE;
      rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rIngCntAnt.EMP_CODIGO;
      rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rIngCntAnt.MYR_CODIGO;
      rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rIngCntAnt.CNT_CODIGO;
      rMovCnt(i).SS_S_A_SC_CODIGO:=rIngCntAnt.SCNT_CODIGO;
      rMovCnt(i).SS_S_A_CODIGO:=rIngCntAnt.AXL_CODIGO;
      rMovCnt(i).SS_S_CODIGO:=rIngCntAnt.SAXL_CODIGO;
      rMovCnt(i).SS_CODIGO:=rIngCntAnt.SAXL2_CODIGO;
      rMovCnt(i).S_CODIGO:=rIngCntAnt.SAXL3_CODIGO;
      rMovCnt(i).DESCRIPCION:=SUBSTR(rDdsCntAnt.DESCRIPCION||' HC:'||LTRIM(TO_CHAR(rDdsCntAnt.NUMERO_HC)),1,120);
      rMovCnt(i).ASOCIACION:=NULL;
      nCuadreH:=nCuadreH+rMovCnt(i).HABER;
      i:=i+1;
    END LOOP;
    nDifCuadre:=nCuadreD-nCuadreH;
    IF nDifCuadre!=0 THEN
-- si la diferencia es menor a 5 centavos ajustamos el cuadre
      rMovCnt(i-1).HABER:=rMovCnt(i-1).HABER+nDifCuadre;
      rMovCnt(i-1).HABERE:=rMovCnt(i-1).HABERE+(nDifCuadre*nTipoCambioE);
    END IF;
    nNumIng:=nNumIng+1;
  END LOOP;
-- Ahora generamos los ingresos como tales
  nNumIng:=nNumIng-1;
  FOR rDdsCnt IN cDDsCnt LOOP
    IF rDdsCnt.CUENTA IS NULL THEN
      OPEN cNumDdsCnt(rDdsCnt.CTACBR_NUMERO);
      FETCH cNumDdsCnt INTO nPorAnticipos,nPorDescuentos,nTotalCtacbr,nNumCotCbr;
      CLOSE cNumDdsCnt;
QMS$ERRORS.SHOW_DEBUG_INFO('Total Ctacbr '||TO_CHAR(ntotalCtaCbr));
QMS$ERRORS.SHOW_DEBUG_INFO('Por Anticipos '||TO_CHAR(nPorAnticipos));
QMS$ERRORS.SHOW_DEBUG_INFO('Por Descuentos '||TO_CHAR(nPorDescuentos));
      IF ROUND(ntotalCtaCbr-nPorDescuentos,1)<=0 AND ROUND(nPorAnticipos,2)=0 THEN
-- Aqui solo cuando los descuentos pagan toda la deuda (DESCUENTO DEL 100%)
-- continuamos con el proceso de registrar solo los descuentos cuando la cuenta por cobrar es cero
QMS$ERRORS.SHOW_DEBUG_INFO('Solo generando descuentos porque la cuenta por cobrar es cero ');
        nNumIng:=nNumIng+1;
        nNumCotCbr:=1; -- hacemos como si solo tuviera 1 couta por cobrar
        ncuadreH:=0;
-- El total de debe se calcula sumando los anticipos si los hay para obtener el valor correcto para el cuadre
        nCuadreD:=0;
        nCtaCbrAnt:=rDdsCnt.CTACBR_NUMERO; -- FIJAMOS LA CTA X COBRAR ULTIMA GENERADA PARA NO REPETIRLA
        GOTO Continuar_SOLODSCTO; 
      END IF;
      IF ROUND(ntotalCtaCbr-nPorAnticipos,1)>0  THEN
-- Solo cuando lo pagado por anticipos no cubre el total de la deuda
-- y la cuota por pagar no se ha creado damos un error de que falta la cuota
        nContErrores:=nContErrores+1;
        GNRL.ESCRIBIR_ERRORES('CNT-01005',REPLACE(rDdsCnt.MDOPGO_DESCRIPCION,'Cuota no Creada',''),rDdsCnt.CTACBR_NUMERO,rDdsCnt.NUMERO_HC);-- El parametro de la cuenta contable para modo de pago no fijado
--        QMS$ERRORS.SHOW_MESSAGE('CNT-01005',REPLACE(rDdsCnt.MDOPGO_DESCRIPCION,'Cuota no Creada',''),rDdsCnt.CTACBR_NUMERO,rDdsCnt.NUMERO_HC);-- El parametro de la cuenta contable para modo de pago no fijado
      ELSIF ROUND(ntotalCtaCbr-nPorAnticipos,1)<0 THEN
-- Aqui en teoria jamas debería entrar porque nunca los anticipos vinculados pueden ser mayores que la deuda
        nContErrores:=nContErrores+1;
        GNRL.ESCRIBIR_ERRORES('ADM-00011','El pago por anticipos para la cuenta por cobrar No.'||rDdsCnt.CTACBR_NUMERO||' de '||rDdscnt.Descripcion||' es menor que los anticipos','Comuniquese con SoftCase');
--        QMS$ERRORS.SHOW_MESSAGE('ADM-00011','El pago por anticipos para la cuenta por cobrar No.'||rDdsCnt.CTACBR_NUMERO||' de '||rDdscnt.Descripcion||' es menor que los anticipos','Comuniquese con SoftCase');
      END IF;
      GOTO Continuar_Etapa1;
    END IF;
  	-- FIJAMOS EL DEBE
    IF nCtaCbrAnt!=rDdsCnt.CTACBR_NUMERO THEN
      nNumIng:=nNumIng+1;
    END IF;
    rMovCnt(i).SECUENCIA:=1000+nNumIng;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=ROUND(rDdsCnt.VALOR,2);
    rMovCnt(i).DEBEE:=ROUND(rDdsCnt.VALOR,2)*nTipoCambioE;
    rMovCnt(i).HABER:=0;
    rMovCnt(i).HABERE:=0;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rDdsCnt.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rDdsCnt.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rDdsCnt.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rDdsCnt.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rDdsCnt.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rDdsCnt.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rDdsCnt.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rDdsCnt.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:=SUBSTR(rDdsCnt.DESCRIPCION||' HC:'||LTRIM(TO_CHAR(rDdsCnt.NUMERO_HC)),1,120);
    rMovCnt(i).ASOCIACION:=SUBSTR(rDdsCnt.ASOCIACION,1,nTamAso);
    IF nCtaCbrAnt!=rDdsCnt.CTACBR_NUMERO THEN
-- solo cuando la cuenta por cobrar es diferente enceramos los verificadores
      OPEN cNumDdsCnt(rDdsCnt.CTACBR_NUMERO);
      FETCH cNumDdsCnt INTO nPorAnticipos,nPorDescuentos,nTotalCtacbr,nNumCotCbr;
      CLOSE cNumDdsCnt;
      ncuadreH:=0;
-- El total de debe se calcula sumando los anticipos si los hay para obtener el valor correcto para el cuadre
      nCuadreD:=rMovCnt(i).DEBE/*+ROUND(nPorAnticipos,2)+(ROUND(nPorDescuentos,2))*/;
      nCtaCbrAnt:=rDdsCnt.CTACBR_NUMERO; -- FIJAMOS LA CTA X COBRAR ULTIMA GENERADA PARA NO REPETIRLA
    ELSE
-- Caso contrario acumulamos los verificadores y restamos el numero de cuotas a cobrar por llenar
      nNumCotCbr:=nNumCotCbr-1;
      nCuadreD:=nCuadreD+rMovCnt(i).DEBE;
      nCtaCbrAnt:=rDdsCnt.CTACBR_NUMERO; -- FIJAMOS LA CTA X COBRAR ULTIMA GENERADA PARA NO REPETIRLA
    END IF;
    i:=i+1;
    IF rDdsCnt.CUENTA IS NOT NULL THEN
-- AÑADIDO EL 6 DIC 2005
      UPDATE FACTURAS
      SET CONTABILIZADO='V'
      WHERE CTACBR_NUMERO=rDdsCnt.CTACBR_NUMERO AND ESTADO!='ANL' AND CONTABILIZADO='F';
-- 6 DIC 2005
      UPDATE CUOTAS_A_COBRAR
      SET CONTABILIZADO=DECODE (ESTADO,'CNC','V','P')
      WHERE NUMERO=rDdsCnt.NUMERO
            AND CTACBR_NUMERO=rDdsCnt.CTACBR_NUMERO AND ESTADO!='ANL'
            AND ABS(VALOR-rDdsCnt.VALOR)<0.02;
      IF SQL%ROWCOUNT!=1 AND rDdsCnt.MDOPGO_DESCRIPCION!='Pago por anticipo' THEN
-- Si no actualizo un registro, significa que hubo un error y la cuota estaba anulada o no existe
-- *** NO DEBE ACTUALIZARSE CUANDO SE PAGA LA FACTURA POR UN ANTICIPO (MDOPGO_DESCRIPCION='Pago por anticipo') ***
        nContErrores:=nContErrores+1;
        GNRL.ESCRIBIR_ERRORES('CNT-01019',rDdsCnt.NUMERO,rDdsCnt.CTACBR_NUMERO,LTRIM(TO_CHAR(rDdsCnt.NUMERO_HC)));
--        QMS$ERRORS.SHOW_MESSAGE('CNT-01019',rDdsCnt.NUMERO,rDdsCnt.CTACBR_NUMERO,LTRIM(TO_CHAR(rDdsCnt.NUMERO_HC)));
      END IF;
    END IF;
<<Continuar_SOLODSCTO>> -- Aqui solo viene para evitar hacer todo el procesamiento cuando no
    IF nNumCotCbr=1 THEN
-- Se llenan los ingresos y descuentos una sola vez para toda la cuenta por cobrar
-- solo ingresar para la ultima o unica cuota por cobrar
/**************************** PRIMERO LLENAMOS LOS DESCUENTOS *****************************/
     FOR rFctDsc IN cFctDsc(rDdsCnt.CTACBR_NUMERO,rDdsCnt.AGRUPADOR_CONTABLE) LOOP
        IF rFctDsc.CUENTA IS NULL THEN
          vDesc:=NULL;
       	  FOR rDetDscSinCnt IN cDetDscSinCnt(rDdsCnt.CTACBR_NUMERO,rDdsCnt.AGRUPADOR_CONTABLE) LOOP
      		-- Llenamos la cargos que no tienen asociacion
      	    vDesc:=vDesc||rDetDscSinCnt.DESCRIPCION||', ';
      	  END LOOP;
      	  vDesc:=SUBSTR(vDesc,1,LENGTH(vDesc)-2)||'.';
          nContErrores:=nContErrores+1;
          GNRL.ESCRIBIR_ERRORES('CNT-01012',vDesc,'Cuenta por Cobrar No.'||rDdsCnt.CTACBR_NUMERO);-- El parametro de la cuenta contable del IVA no fijado
--          QMS$ERRORS.SHOW_MESSAGE('CNT-01012',vDesc,'Cuenta por Cobrar No.'||rDdsCnt.CTACBR_NUMERO);-- El parametro de la cuenta contable del IVA no fijado
        END IF;
        rMovCnt(i).SECUENCIA:=1000+nNumIng;
        rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
        rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
        rMovCnt(i).CMP_FECHA:=dFechaCmp;
        rMovCnt(i).CMP_CLAVE:=nClave;
        rMovCnt(i).DEBE:=ROUND(rFctDsc.VALOR,2);
        rMovCnt(i).DEBEE:=ROUND(rFctDsc.VALOR,2)*nTipoCambioE;
        rMovCnt(i).HABER:=0;
        rMovCnt(i).HABERE:=0;
        rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rFctDsc.EMP_CODIGO;
        rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rFctDsc.MYR_CODIGO;
        rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rFctDsc.CNT_CODIGO;
        rMovCnt(i).SS_S_A_SC_CODIGO:=rFctDsc.SCNT_CODIGO;
        rMovCnt(i).SS_S_A_CODIGO:=rFctDsc.AXL_CODIGO;
        rMovCnt(i).SS_S_CODIGO:=rFctDsc.SAXL_CODIGO;
        rMovCnt(i).SS_CODIGO:=rFctDsc.SAXL2_CODIGO;
        rMovCnt(i).S_CODIGO:=rFctDsc.SAXL3_CODIGO;
        rMovCnt(i).DESCRIPCION:=SUBSTR(rDdsCnt.DESCRIPCION||' HC:'||LTRIM(TO_CHAR(rDdsCnt.NUMERO_HC)||' Descuentos a Fct '||rDdsCnt.ASOCIACION),1,120);
        rMovCnt(i).ASOCIACION:=NULL;
        nCuadreD:=nCuadreD+rMovCnt(i).DEBE;
        i:=i+1;
      END LOOP;
/************************************* FIN DESCUENTOS **************************************/
/**************************** CONTABILIZAMOS EL IVA ****************************/
      FOR rIngCntIVA IN cIngCntIVA(rDdsCnt.CTACBR_NUMERO) LOOP
-- Vemos el IVA solo de la ultima deuda porque sino duplica el valor del IVA
        IF rIngCntIVA.CUENTA IS NULL THEN
          nContErrores:=nContErrores+1;
          GNRL.ESCRIBIR_ERRORES('CNT-01004','IVA');-- El parametro de la cuenta contable del IVA no fijado
--          QMS$ERRORS.SHOW_MESSAGE('CNT-01004','IVA');-- El parametro de la cuenta contable del IVA no fijado
        END IF;
        rMovCnt(i).SECUENCIA:=1000+nNumIng;
        rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
        rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
        rMovCnt(i).CMP_FECHA:=dFechaCmp;
        rMovCnt(i).CMP_CLAVE:=nClave;
        rMovCnt(i).DEBE:=0;
        rMovCnt(i).DEBEE:=0;
        rMovCnt(i).HABER:=ROUND(rIngCntIVA.VALOR,2);
        rMovCnt(i).HABERE:=ROUND(rIngCntIVA.VALOR,2)*nTipoCambioE;
        rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rIngCntIVA.EMP_CODIGO;
        rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rIngCntIVA.MYR_CODIGO;
        rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rIngCntIVA.CNT_CODIGO;
        rMovCnt(i).SS_S_A_SC_CODIGO:=rIngCntIVA.SCNT_CODIGO;
        rMovCnt(i).SS_S_A_CODIGO:=rIngCntIVA.AXL_CODIGO;
        rMovCnt(i).SS_S_CODIGO:=rIngCntIVA.SAXL_CODIGO;
        rMovCnt(i).SS_CODIGO:=rIngCntIVA.SAXL2_CODIGO;
        rMovCnt(i).S_CODIGO:=rIngCntIVA.SAXL3_CODIGO;
        rMovCnt(i).DESCRIPCION:=SUBSTR(rDdsCnt.DESCRIPCION||' HC:'||LTRIM(TO_CHAR(rDdsCnt.NUMERO_HC)||' Fct '||rDdsCnt.ASOCIACION),1,120);
        rMovCnt(i).ASOCIACION:=SUBSTR(rDdsCnt.ASOCIACION,1,ntamAso);
        nCuadreH:=nCuadreH+rMovCnt(i).HABER;
        i:=i+1;
        EXIT; -- solo hacemos una vez
      END LOOP;
      FOR rFctIng IN cFctIng(rDdsCnt.CTACBR_NUMERO,rDdsCnt.AGRUPADOR_CONTABLE) LOOP
        IF rFctIng.CUENTA IS NULL THEN
          vDesc:=NULL;
       	  FOR rDetFctSinCnt IN cDetFctSinCnt(rDdsCnt.CTACBR_NUMERO,rDdsCnt.AGRUPADOR_CONTABLE) LOOP
      		-- Llenamos la cargos que no tienen asociacion
      	    vDesc:=vDesc||rDetFctSinCnt.DESCRIPCION||', ';
      	  END LOOP;
      	  vDesc:=SUBSTR(vDesc,1,LENGTH(vDesc)-2)||'.';
          nContErrores:=nContErrores+1;
          GNRL.ESCRIBIR_ERRORES('CNT-01006',vDesc,rDdsCnt.CTACBR_NUMERO);-- El parametro de la cuenta contable del IVA no fijado
--          QMS$ERRORS.SHOW_MESSAGE('CNT-01006',vDesc,rDdsCnt.CTACBR_NUMERO);-- El parametro de la cuenta contable del IVA no fijado
        END IF;
        rMovCnt(i).SECUENCIA:=1000+nNumIng;
        rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
        rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
        rMovCnt(i).CMP_FECHA:=dFechaCmp;
        rMovCnt(i).CMP_CLAVE:=nClave;
        rMovCnt(i).DEBE:=0;
        rMovCnt(i).DEBEE:=0;
        rMovCnt(i).HABER:=ROUND(rFctIng.VALOR,2);
        rMovCnt(i).HABERE:=ROUND(rFctIng.VALOR,2)*nTipoCambioE;
        rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rFctIng.EMP_CODIGO;
        rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rFctIng.MYR_CODIGO;
        rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rFctIng.CNT_CODIGO;
        rMovCnt(i).SS_S_A_SC_CODIGO:=rFctIng.SCNT_CODIGO;
        rMovCnt(i).SS_S_A_CODIGO:=rFctIng.AXL_CODIGO;
        rMovCnt(i).SS_S_CODIGO:=rFctIng.SAXL_CODIGO;
        rMovCnt(i).SS_CODIGO:=rFctIng.SAXL2_CODIGO;
        rMovCnt(i).S_CODIGO:=rFctIng.SAXL3_CODIGO;
        rMovCnt(i).DESCRIPCION:=SUBSTR(rDdsCnt.DESCRIPCION||' HC:'||LTRIM(TO_CHAR(rDdsCnt.NUMERO_HC)||' Fct '||rDdsCnt.ASOCIACION),1,120);
        rMovCnt(i).ASOCIACION:=NULL;
        nCuadreH:=nCuadreH+rMovCnt(i).HABER;
        i:=i+1;
      END LOOP;
      nDifCuadre:=nCuadreD-nCuadreH;
      IF nDifCuadre!=0 THEN
        IF ABS(nDifCuadre)<=0.05 THEN
          rMovCnt(i-1).HABER:=rMovCnt(i-1).HABER+nDifCuadre;
          rMovCnt(i-1).HABERE:=rMovCnt(i-1).HABERE+(nDifCuadre*nTipoCambioE);
        ELSE
          nContErrores:=nContErrores+1;
          GNRL.ESCRIBIR_ERRORES('CNT-01011',rDdsCnt.NUMERO_HC,rDdsCnt.CTACBR_NUMERO,nDifCuadre);
--          QMS$ERRORS.SHOW_MESSAGE('CNT-01011',rDdsCnt.NUMERO_HC,nCtaCbrAnt,nDifCuadre);
        END IF;
      END IF;
    END IF;
<<Continuar_Etapa1>> -- Aqui solo viene para evitar hacer todo el procesamiento cuando no
-- tiene un modo de pago asociado porque a una cuenta por cobrar todo se pago por anticipos
  NULL;
  END LOOP;
/* SEGUNDA ETAPA */
  nNumCbr:=1;
  FOR rCajas IN cCajas LOOP
    IF rCajas.Cuenta IS NULL THEN
      nContErrores:=nContErrores+1;
      GNRL.ESCRIBIR_ERRORES('CNT-01007',rCajas.CJA_CODIGO); -- no se ha definido la cuenta de la caja
--      QMS$ERRORS.SHOW_MESSAGE('CNT-01007',rCajas.CJA_CODIGO); -- no se ha definido la cuenta de la caja
    END IF;
    -- FIJAMOS EL DEBE
    rMovCnt(i).SECUENCIA:=2000+nNumCbr;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=ROUND(rCajas.VALOR,2);
    rMovCnt(i).DEBEE:=ROUND(rCajas.VALOR,2)*nTipoCambioE;
    rMovCnt(i).HABER:=0;
    rMovCnt(i).HABERE:=0;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rCajas.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rCajas.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rCajas.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rCajas.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rCajas.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rCajas.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rCajas.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rCajas.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:=SUBSTR(vDescIng,1,120);
    rMovCnt(i).ASOCIACION:=NULL;
    nTotalDep:=nTotalDep+ROUND(rCajas.VALOR,2);
    nCuadreD:=rMovCnt(i).DEBE;
    nCuadreH:=0;
    Etapa2i:=i;
    rIndiceCajas(nCaja):=i;
    nCaja:=nCaja+1;
    i:=i+1;
    FOR rCajasCbr IN cCajasCbr(rCajas.CJA_CODIGO) LOOP
      IF rCajasCbr.CUENTA IS NULL THEN
        nContErrores:=nContErrores+1;
        GNRL.ESCRIBIR_ERRORES('CNT-01005',REPLACE(rCajasCbr.MDOPGO_DESCRIPCION,'Cuota no Creada',''),rCajasCbr.CTACBR_NUMERO,rCajasCbr.NUMERO_HC);-- El parametro de la cuenta contable para modo de pago no fijado
--        QMS$ERRORS.SHOW_MESSAGE('CNT-01005',REPLACE(rCajasCbr.MDOPGO_DESCRIPCION,'Cuota no Creada',''),rCajasCbr.CTACBR_NUMERO,rCajasCbr.NUMERO_HC);-- El parametro de la cuenta contable para modo de pago no fijado
      END IF;
  	-- FIJAMOS EL HABER
      rMovCnt(i).SECUENCIA:=2000+nNumCbr;
      rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
      rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
      rMovCnt(i).CMP_FECHA:=dFechaCmp;
      rMovCnt(i).CMP_CLAVE:=nClave;
      rMovCnt(i).DEBE:=0;
      rMovCnt(i).DEBEE:=0;
      rMovCnt(i).HABER:=ROUND(rCajasCbr.VALOR,2);
      rMovCnt(i).HABERE:=ROUND(rCajasCbr.VALOR,2)*nTipoCambioE;
      rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rCajasCbr.EMP_CODIGO;
      rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rCajasCbr.MYR_CODIGO;
      rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rCajasCbr.CNT_CODIGO;
      rMovCnt(i).SS_S_A_SC_CODIGO:=rCajasCbr.SCNT_CODIGO;
      rMovCnt(i).SS_S_A_CODIGO:=rCajasCbr.AXL_CODIGO;
      rMovCnt(i).SS_S_CODIGO:=rCajasCbr.SAXL_CODIGO;
      rMovCnt(i).SS_CODIGO:=rCajasCbr.SAXL2_CODIGO;
      rMovCnt(i).S_CODIGO:=rCajasCbr.SAXL3_CODIGO;
      rMovCnt(i).DESCRIPCION:=SUBSTR(rCajasCbr.DESCRIPCION||' HC:'||LTRIM(TO_CHAR(rCajasCbr.NUMERO_HC)),1,120);
      rMovCnt(i).ASOCIACION:=SUBSTR(rCajasCbr.ASOCIACION,1,nTamAso);
      nCuadreH:=nCuadreH+rMovCnt(i).HABER;
      i:=i+1;
    END LOOP;
    nDifCuadre:=nCuadreH-nCuadreD;
    IF nDifCuadre!=0 THEN
-- Corregimos el desfase si hay diferencia sumando las ingresos por cajas y las totales por cajas
      rMovCnt(Etapa2i).DEBE:=rMovCnt(Etapa2i).DEBE+nDifCuadre;
      rMovCnt(Etapa2i).DEBEE:=rMovCnt(Etapa2i).DEBEE+(nDifCuadre*nTipoCambioE);
      nTotalDep:=nTotalDep+nDifCuadre;
    END IF;
    nNumCbr:=nNumCbr+1;
  END LOOP;
/* TERCERA ETAPA */
-- La secuencia ira aumentando de acuerdo a:
--                                  Deposito            => 3000
--                                  Anticipo Vinculados => 3001
--                                  Devoluciones        => 3002
--                                  Tasa de Servicios   => 3003
--                                  Retenciones Fuente  => 3004, etc
  nNum3:=1;
/********************************* ANTICIPOS VINCULADOS *********************************/
  FOR rAntVnc IN cAntVnc LOOP
-- Primero indicamos los anticipos vinculados
    IF rAntVnc.CUENTA IS NULL THEN
      nContErrores:=nContErrores+1;
      GNRL.ESCRIBIR_ERRORES('CNT-01004','Anticipos');-- El parametro de la cuenta contable de los anticipos no fijado
--      QMS$ERRORS.SHOW_MESSAGE('CNT-01004','Anticipos');-- El parametro de la cuenta contable de los anticipos no fijado
    END IF;
    rMovCnt(i).SECUENCIA:=nNumSec3Ant+nNum3;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=ROUND(rAntVnc.VALOR,2);
    rMovCnt(i).DEBEE:=ROUND(rAntVnc.VALOR,2)*nTipoCambioE;
    nTotalDep:=nTotalDep-ROUND(rAntVnc.VALOR,2); -- Restamos la cantidad a Depositar
    rMovCnt(i).HABER:=0;
    rMovCnt(i).HABERE:=0;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rAntVnc.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rAntVnc.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rAntVnc.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rAntVnc.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rAntVnc.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rAntVnc.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rAntVnc.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rAntVnc.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:=rAntVnc.DESCRIPCION;
    rMovCnt(i).ASOCIACION:=SUBSTR(rAntVnc.ASOCIACION,1,nTamAso);
    i:=i+1;
    nNum3:=nNum3+1;
  END LOOP;
  nNum3:=1;
/********************************* FIN ANTICIPOS VINCULADOS *********************************/
  nNum3:=1;
/********************************* DEVOLUCION ANTICIPOS *********************************/
  FOR rDvlAnt IN cDvlAnt LOOP
-- Primero indicamos los anticipos vinculados
    IF rDvlAnt.CUENTA IS NULL THEN
      nContErrores:=nContErrores+1;
      GNRL.ESCRIBIR_ERRORES('CNT-01004','Anticipos');-- El parametro de la cuenta contable de los anticipos no fijado
--      QMS$ERRORS.SHOW_MESSAGE('CNT-01004','Anticipos');-- El parametro de la cuenta contable de los anticipos no fijado
    END IF;
    rMovCnt(i).SECUENCIA:=nNumSec3DvlAnt+nNum3;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=ROUND(rDvlAnt.VALOR,2);
    rMovCnt(i).DEBEE:=ROUND(rDvlAnt.VALOR,2)*nTipoCambioE;
    nTotalDep:=nTotalDep-ROUND(rDvlAnt.VALOR,2); -- Restamos la cantidad a Depositar
    rMovCnt(i).HABER:=0;
    rMovCnt(i).HABERE:=0;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rDvlAnt.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rDvlAnt.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rDvlAnt.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rDvlAnt.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rDvlAnt.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rDvlAnt.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rDvlAnt.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rDvlAnt.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:=rDvlAnt.DESCRIPCION;
    rMovCnt(i).ASOCIACION:='';
    i:=i+1;
    nNum3:=nNum3+1;
  END LOOP;
  nNum3:=1;
/********************************* FIN DEVOLUCION ANTICIPOS *********************************/
/******************* DESCUENTOS DE LA TERCERA ETAPA *******************************/
-- AHORA PROCESAMOS Los descuentos de la tercera etapa en orden
  vTipoAnt:='';
  FOR rDtlCnt3Etapa IN cDtlCnt3Etapa LOOP
     QMS$ERRORS.SHOW_DEBUG_INFO('TIPO '||rDtlCnt3Etapa.TIPO);
     QMS$ERRORS.SHOW_DEBUG_INFO('NUMERO '||rDtlCnt3Etapa.NUMERO);
     IF NVL(vTipoAnt,'$$$$$$')!=rDtlCnt3Etapa.TIPO THEN
-- Enceramos el contador para que empieze en 1 cuando cambia el TIPO cambia
        vTipoAnt:=rDtlCnt3Etapa.TIPO;
        nNum3:=1;
     END IF;
     QMS$ERRORS.SHOW_DEBUG_INFO('nNum3 '||TO_CHAR(nNum3));
     QMS$ERRORS.SHOW_DEBUG_INFO('vTipoant '||NVL(vTipoAnt,'NULO'));
     IF rDtlCnt3Etapa.TIPO IN ('DSCDVL','DSCOTR') AND rDtlCnt3Etapa.AGRUPADOR_CONTABLE='%' THEN
        nContErrores:=nContErrores+1;
        IF rDtlCnt3Etapa.TIPO='DSCDVL' THEN
          GNRL.ESCRIBIR_ERRORES('CNT-01020',vDesc,'Devolución No '||rDtlCnt3Etapa.NUMERO);-- El parametro de la cuenta contable del IVA no fijado
        ELSE
          GNRL.ESCRIBIR_ERRORES('CNT-01020',vDesc,'NC No '||rDtlCnt3Etapa.NUMERO);-- El parametro de la cuenta contable del IVA no fijado
        END IF;
     END IF;
     IF rDtlCnt3Etapa.TIPO='DSCDVL' THEN
/**************************** PRIMERO LLENAMOS LAS DEVOLUCIONES *****************************/
       FOR rFctDvl IN cFctDvl(rDtlCnt3Etapa.NUMERO,rDtlCnt3Etapa.AGRUPADOR_CONTABLE) LOOP
         IF rFctDvl.CUENTA IS NULL THEN
           vDesc:=NULL;
        	  FOR rDetDvlSinCnt IN cDetDvlSinCnt(rDtlCnt3Etapa.NUMERO,rDtlCnt3Etapa.AGRUPADOR_CONTABLE) LOOP
      		-- Llenamos la cargos que no tienen asociacion
      	    vDesc:=vDesc||rDetDvlSinCnt.DESCRIPCION||', ';
      	  END LOOP;
          vDesc:=SUBSTR(vDesc,1,LENGTH(vDesc)-2)||'.';
          nContErrores:=nContErrores+1;
          GNRL.ESCRIBIR_ERRORES('CNT-01012',vDesc,'Devolucion No '||rDtlCnt3Etapa.NUMERO);-- El parametro de la cuenta contable del IVA no fijado
--          QMS$ERRORS.SHOW_MESSAGE('CNT-01012',vDesc,'Devolucion No '||rDtlCnt3Etapa.NUMERO);-- El parametro de la cuenta contable del IVA no fijado
         END IF;
         rMovCnt(i).SECUENCIA:=nNumSec3dVL+nNum3;
         rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
         rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
         rMovCnt(i).CMP_FECHA:=dFechaCmp;
         rMovCnt(i).CMP_CLAVE:=nClave;
         rMovCnt(i).DEBE:=ROUND(rFctDvl.VALOR,2);
         rMovCnt(i).DEBEE:=ROUND(rFctDvl.VALOR,2)*nTipoCambioE;
         nTotalDep:=nTotalDep-ROUND(rFctDvl.VALOR,2); -- Restamos la cantidad a Depositar
         rMovCnt(i).HABER:=0;
         rMovCnt(i).HABERE:=0;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rFctDvl.EMP_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rFctDvl.MYR_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rFctDvl.CNT_CODIGO;
         rMovCnt(i).SS_S_A_SC_CODIGO:=rFctDvl.SCNT_CODIGO;
         rMovCnt(i).SS_S_A_CODIGO:=rFctDvl.AXL_CODIGO;
         rMovCnt(i).SS_S_CODIGO:=rFctDvl.SAXL_CODIGO;
         rMovCnt(i).SS_CODIGO:=rFctDvl.SAXL2_CODIGO;
         rMovCnt(i).S_CODIGO:=rFctDvl.SAXL3_CODIGO;
         rMovCnt(i).DESCRIPCION:=SUBSTR('DEVOLUCION #'||rDtlCnt3Etapa.NUMERO||' Fct '||rDtlCnt3Etapa.FACTURAS||' HC:'||LTRIM(rDtlCnt3Etapa.NUMERO_HC)||rDtlCnt3Etapa.APELLIDO_PATERNO||' '||rDtlCnt3Etapa.APELLIDO_MATERNO||' '||rDtlCnt3Etapa.PRIMER_NOMBRE||' '||rDtlCnt3Etapa.SEGUNDO_NOMBRE ,1,120);
         rMovCnt(i).ASOCIACION:=NULL;
         i:=i+1;
       END LOOP;
-- AHORA DEVOLUCIONES DEL IVA
       FOR rFctDvl IN cFctDvlIVA(rDtlCnt3Etapa.NUMERO) LOOP
-- Se asume que la cuenta de INTEGRACION IVA fue ya verificad que existia antes
         rMovCnt(i).SECUENCIA:=nNumSec3dVL+nNum3;
         rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
         rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
         rMovCnt(i).CMP_FECHA:=dFechaCmp;
         rMovCnt(i).CMP_CLAVE:=nClave;
         rMovCnt(i).DEBE:=ROUND(rFctDvl.VALOR_IVA,2);
         rMovCnt(i).DEBEE:=ROUND(rFctDvl.VALOR_IVA,2)*nTipoCambioE;
         nTotalDep:=nTotalDep-ROUND(rFctDvl.VALOR_IVA,2); -- Restamos la cantidad a Depositar
         rMovCnt(i).HABER:=0;
         rMovCnt(i).HABERE:=0;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rFctDvl.EMP_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rFctDvl.MYR_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rFctDvl.CNT_CODIGO;
         rMovCnt(i).SS_S_A_SC_CODIGO:=rFctDvl.SCNT_CODIGO;
         rMovCnt(i).SS_S_A_CODIGO:=rFctDvl.AXL_CODIGO;
         rMovCnt(i).SS_S_CODIGO:=rFctDvl.SAXL_CODIGO;
         rMovCnt(i).SS_CODIGO:=rFctDvl.SAXL2_CODIGO;
         rMovCnt(i).S_CODIGO:=rFctDvl.SAXL3_CODIGO;
         rMovCnt(i).DESCRIPCION:=SUBSTR('DEVOLUCION #'||rDtlCnt3Etapa.NUMERO||' Fct '||rDtlCnt3Etapa.FACTURAS||' HC:'||LTRIM(rDtlCnt3Etapa.NUMERO_HC)||rDtlCnt3Etapa.APELLIDO_PATERNO||' '||rDtlCnt3Etapa.APELLIDO_MATERNO||' '||rDtlCnt3Etapa.PRIMER_NOMBRE||' '||rDtlCnt3Etapa.SEGUNDO_NOMBRE ,1,120);
         rMovCnt(i).ASOCIACION:=NULL;
         i:=i+1;
       END LOOP;
       nNum3:=nNum3+1;-- Subimos la Secuencia para los siguientes DESCUENTOS TERCERA ETAPA
/************************************* FIN DEVOLUCIONES **************************************/
     ELSIF rDtlCnt3Etapa.TIPO='DSCOTR' THEN
-- contablizacion de notas de credito
       nTempVerificador:=0;
       FOR rNCDvl IN cNCDvl(rDtlCnt3Etapa.NUMERO,rDtlCnt3Etapa.AGRUPADOR_CONTABLE) LOOP
         IF rNCDvl.CUENTA IS NULL THEN
           vDesc:=NULL;
        	  FOR rDetNCSinCnt IN cDetNCSinCnt(rDtlCnt3Etapa.NUMERO,rDtlCnt3Etapa.AGRUPADOR_CONTABLE) LOOP
      		-- Llenamos la cargos que no tienen asociacion
      	    vDesc:=vDesc||rDetNCSinCnt.DESCRIPCION||', ';
      	  END LOOP;
          vDesc:=SUBSTR(vDesc,1,LENGTH(vDesc)-2)||'.';
          nContErrores:=nContErrores+1;
          GNRL.ESCRIBIR_ERRORES('CNT-01012',vDesc,'Devolucion No '||rDtlCnt3Etapa.NUMERO);-- El parametro de la cuenta contable del IVA no fijado
--          QMS$ERRORS.SHOW_MESSAGE('CNT-01012',vDesc,'Nota No '||rDtlCnt3Etapa.NUMERO);-- El parametro de la cuenta contable del IVA no fijado
         END IF;
         rMovCnt(i).SECUENCIA:=nNumSec3NC+nNum3;
         rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
         rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
         rMovCnt(i).CMP_FECHA:=dFechaCmp;
         rMovCnt(i).CMP_CLAVE:=nClave;
         rMovCnt(i).DEBE:=ROUND(rNCDvl.VALOR,2);
         rMovCnt(i).DEBEE:=ROUND(rNCDvl.VALOR,2)*nTipoCambioE;
         nTotalDep:=nTotalDep-ROUND(rNCDvl.VALOR,2); -- Restamos la cantidad a Depositar
         rMovCnt(i).HABER:=0;
         rMovCnt(i).HABERE:=0;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rNCDvl.EMP_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rNCDvl.MYR_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rNCDvl.CNT_CODIGO;
         rMovCnt(i).SS_S_A_SC_CODIGO:=rNCDvl.SCNT_CODIGO;
         rMovCnt(i).SS_S_A_CODIGO:=rNCDvl.AXL_CODIGO;
         rMovCnt(i).SS_S_CODIGO:=rNCDvl.SAXL_CODIGO;
         rMovCnt(i).SS_CODIGO:=rNCDvl.SAXL2_CODIGO;
         rMovCnt(i).S_CODIGO:=rNCDvl.SAXL3_CODIGO;
         rMovCnt(i).DESCRIPCION:=SUBSTR('NC #'||rDtlCnt3Etapa.NUMERO||' Fct '||rDtlCnt3Etapa.FACTURAS||' HC:'||LTRIM(rDtlCnt3Etapa.NUMERO_HC)||rDtlCnt3Etapa.APELLIDO_PATERNO||' '||rDtlCnt3Etapa.APELLIDO_MATERNO||' '||rDtlCnt3Etapa.PRIMER_NOMBRE||' '||rDtlCnt3Etapa.SEGUNDO_NOMBRE ,1,120);
         rMovCnt(i).ASOCIACION:=NULL;
         i:=i+1;
         nTempVerificador:=nTempVerificador+1;
       END LOOP;
       IF nTempVerificador=0 THEN
         nContErrores:=nContErrores+1;
         GNRL.ESCRIBIR_ERRORES('CNT-01021',rDtlCnt3Etapa.NUMERO,rDtlCnt3Etapa.CTACBR_NUMERO);
       END IF;
       nNum3:=nNum3+1;-- Subimos la Secuencia para los siguientes DESCUENTOS TERCERA ETAPA
     ELSIF rDtlCnt3Etapa.TIPO='DSCTSR' THEN
/**************************** LLENAMOS LA TASA DE SERVICIOS *****************************/
       nTempVerificador:=0;
       FOR rTS IN cTS(rDtlCnt3Etapa.CNTING_CNTING_ID,rDtlCnt3Etapa.CTACBR_NUMERO,rDtlCnt3Etapa.NUMERO) LOOP
-- Aqui solo va a entrar una sola vez si la nota que creo la tasa de servicio no esta anulada
         IF rTS.CUENTA IS NULL THEN
           nContErrores:=nContErrores+1;
           GNRL.ESCRIBIR_ERRORES('CNT-01013',rTS.MDOPGO_DESCRIPCION,rDtlCnt3Etapa.CTACBR_NUMERO);-- La tasa de Servicio no tiene vinculada una cuenta contable
--           QMS$ERRORS.SHOW_MESSAGE('CNT-01013',rTS.MDOPGO_DESCRIPCION,rDtlCnt3Etapa.CTACBR_NUMERO);-- La tasa de Servicio no tiene vinculada una cuenta contable
         END IF;
         IF ABS(rDtlCnt3Etapa.VALOR-rTS.VALOR)>=0.01 THEN
-- Si el valor de la tasa de servicio difiere del guardado en el detalle de la contabilizacion
-- damos un error indicando ello
           nContErrores:=nContErrores+1;
           GNRL.ESCRIBIR_ERRORES('CNT-01015',rTS.MDOPGO_DESCRIPCION,rDtlCnt3Etapa.CTACBR_NUMERO,ROUND(rTS.VALOR,2),ROUND(rDtlCnt3Etapa.VALOR,2));-- La tasa de Servicio no tiene vinculada una cuenta contable
--           QMS$ERRORS.SHOW_MESSAGE('CNT-01015',rTS.MDOPGO_DESCRIPCION,rDtlCnt3Etapa.CTACBR_NUMERO,ROUND(rTS.VALOR,2),ROUND(rDtlCnt3Etapa.VALOR,2));-- La tasa de Servicio no tiene vinculada una cuenta contable
         END IF;
         rMovCnt(i).SECUENCIA:=nNumSec3TS+nNum3;
         rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
         rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
         rMovCnt(i).CMP_FECHA:=dFechaCmp;
         rMovCnt(i).CMP_CLAVE:=nClave;
         rMovCnt(i).DEBE:=ROUND(rTS.VALOR,2);
         rMovCnt(i).DEBEE:=ROUND(rTS.VALOR,2)*nTipoCambioE;
         nTotalDep:=nTotalDep-ROUND(rTS.VALOR,2); -- Restamos la cantidad a Depositar
         rMovCnt(i).HABER:=0;
         rMovCnt(i).HABERE:=0;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rTS.EMP_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rTS.MYR_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rTS.CNT_CODIGO;
         rMovCnt(i).SS_S_A_SC_CODIGO:=rTS.SCNT_CODIGO;
         rMovCnt(i).SS_S_A_CODIGO:=rTS.AXL_CODIGO;
         rMovCnt(i).SS_S_CODIGO:=rTS.SAXL_CODIGO;
         rMovCnt(i).SS_CODIGO:=rTS.SAXL2_CODIGO;
         rMovCnt(i).S_CODIGO:=rTS.SAXL3_CODIGO;
         rMovCnt(i).DESCRIPCION:=SUBSTR('Tasa de Servicio '||rTS.MDOPGO_DESCRIPCION||' Couta #'||rTS.NUMERO||' '||rTS.DESCRIPCION,1,120);
         rMovCnt(i).ASOCIACION:=NULL;
         i:=i+1;
         nTempVerificador:=nTempVerificador+1;
       END LOOP;
       IF nTempVerificador=0 THEN
         nContErrores:=nContErrores+1;
         GNRL.ESCRIBIR_ERRORES('CNT-01014',rDtlCnt3Etapa.NUMERO,rDtlCnt3Etapa.CTACBR_NUMERO);
--         QMS$ERRORS.SHOW_MESSAGE('CNT-01014',rDtlCnt3Etapa.NUMERO,rDtlCnt3Etapa.CTACBR_NUMERO);
       ELSIF nTempVerificador>1 THEN
-- Si es mayor que 1 hay un error en la vista
         nContErrores:=nContErrores+1;
         GNRL.ESCRIBIR_ERRORES('ADM-00011','Error en la vista TASA_SERVICIOS_CNT para la CUENTA POR COBRAR #'||rDtlCnt3Etapa.CTACBR_NUMERO||' Comuniquese con Softcase C Ltda');
--         QMS$ERRORS.SHOW_MESSAGE('ADM-00011','Error en la vista TASA_SERVICIOS_CNT para la CUENTA POR COBRAR #'||rDtlCnt3Etapa.CTACBR_NUMERO||' Comuniquese con Softcase C Ltda');
       END IF;
       nNum3:=nNum3+1;-- Subimos la Secuencia para los siguientes DESCUENTOS TERCERA ETAPA
/********************************** FIN TASA DE SERVICIOS **********************************/
     ELSIF rDtlCnt3Etapa.TIPO='DSCTSI' THEN
/**************************** LLENAMOS LA RETENCION EN LA FUENTE *****************************/
       nTempVerificador:=0;
       FOR rRF IN cRF(rDtlCnt3Etapa.CNTING_CNTING_ID,rDtlCnt3Etapa.CTACBR_NUMERO,rDtlCnt3Etapa.NUMERO) LOOP
-- Aqui solo va a entrar una sola vez si la nota que creo la tasa de servicio no esta anulada
         IF rRF.CUENTA IS NULL THEN
           nContErrores:=nContErrores+1;
           GNRL.ESCRIBIR_ERRORES('CNT-01016',rRF.MDOPGO_DESCRIPCION,rDtlCnt3Etapa.CTACBR_NUMERO);-- La tasa de Servicio no tiene vinculada una cuenta contable
--          QMS$ERRORS.SHOW_MESSAGE('CNT-01016',rRF.MDOPGO_DESCRIPCION,rDtlCnt3Etapa.CTACBR_NUMERO);-- La tasa de Servicio no tiene vinculada una cuenta contable
         END IF;
         IF ABS(rDtlCnt3Etapa.VALOR-rRF.VALOR)>=0.01 THEN
-- Si el valor de la retencion en la fuente difiere del guardado en el detalle de la contabilizacion
-- damos un error indicando ello
           nContErrores:=nContErrores+1;
           GNRL.ESCRIBIR_ERRORES('CNT-01018',rRF.MDOPGO_DESCRIPCION,rDtlCnt3Etapa.CTACBR_NUMERO,ROUND(rRF.VALOR,2),ROUND(rDtlCnt3Etapa.VALOR,2));-- La tasa de Servicio no tiene vinculada una cuenta contable
--           QMS$ERRORS.SHOW_MESSAGE('CNT-01018',rRF.MDOPGO_DESCRIPCION,rDtlCnt3Etapa.CTACBR_NUMERO,ROUND(rRF.VALOR,2),ROUND(rDtlCnt3Etapa.VALOR,2));-- La tasa de Servicio no tiene vinculada una cuenta contable
         END IF;
         rMovCnt(i).SECUENCIA:=nNumSec3RF+nNum3;
         rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
         rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
         rMovCnt(i).CMP_FECHA:=dFechaCmp;
         rMovCnt(i).CMP_CLAVE:=nClave;
         rMovCnt(i).DEBE:=ROUND(rRF.VALOR,2);
         rMovCnt(i).DEBEE:=ROUND(rRF.VALOR,2)*nTipoCambioE;
         nTotalDep:=nTotalDep-ROUND(rRF.VALOR,2); -- Restamos la cantidad a Depositar
         rMovCnt(i).HABER:=0;
         rMovCnt(i).HABERE:=0;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rRF.EMP_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rRF.MYR_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rRF.CNT_CODIGO;
         rMovCnt(i).SS_S_A_SC_CODIGO:=rRF.SCNT_CODIGO;
         rMovCnt(i).SS_S_A_CODIGO:=rRF.AXL_CODIGO;
         rMovCnt(i).SS_S_CODIGO:=rRF.SAXL_CODIGO;
         rMovCnt(i).SS_CODIGO:=rRF.SAXL2_CODIGO;
         rMovCnt(i).S_CODIGO:=rRF.SAXL3_CODIGO;
         rMovCnt(i).DESCRIPCION:=SUBSTR('Ret Fuente de '||rRF.MDOPGO_DESCRIPCION||' Couta #'||rRF.NUMERO||' '||rRF.DESCRIPCION,1,120);
         rMovCnt(i).ASOCIACION:=NULL;
         i:=i+1;
         nTempVerificador:=nTempVerificador+1;
       END LOOP;
       IF nTempVerificador=0 THEN
         nContErrores:=nContErrores+1;
         GNRL.ESCRIBIR_ERRORES('CNT-01017',rDtlCnt3Etapa.NUMERO,rDtlCnt3Etapa.CTACBR_NUMERO);
--         QMS$ERRORS.SHOW_MESSAGE('CNT-01017',rDtlCnt3Etapa.NUMERO,rDtlCnt3Etapa.CTACBR_NUMERO);
       ELSIF nTempVerificador>1 THEN
-- Si es mayor que 1 hay un error en la vista
         nContErrores:=nContErrores+1;
         GNRL.ESCRIBIR_ERRORES('ADM-00011','Error en la vista TASA_SERVICIOS_CNT para la CUENTA POR COBRAR #'||rDtlCnt3Etapa.CTACBR_NUMERO||' Comuniquese con Softcase C Ltda');
--         QMS$ERRORS.SHOW_MESSAGE('ADM-00011','Error en la vista RETENCION_EN_LA_FUENTE_CNT para la CUENTA POR COBRAR #'||rDtlCnt3Etapa.CTACBR_NUMERO||' Comuniquese con Softcase C Ltda');
       END IF;
       nNum3:=nNum3+1;-- Subimos la Secuencia para los siguientes DESCUENTOS TERCERA ETAPA
/********************************** FIN RETENCION EN LA FUENTE **********************************/
     ELSIF rDtlCnt3Etapa.TIPO='DSCRTI' THEN
/**************************** LLENAMOS LA RETENCION DEL IVA *****************************/
       nTempVerificador:=0;
       FOR rRIva IN cRIva(rDtlCnt3Etapa.CNTING_CNTING_ID,rDtlCnt3Etapa.CTACBR_NUMERO,rDtlCnt3Etapa.NUMERO) LOOP
-- Aqui solo va a entrar una sola vez si la nota que creo la tasa de servicio no esta anulada
         IF rRIva.CUENTA IS NULL THEN
           nContErrores:=nContErrores+1;
           GNRL.ESCRIBIR_ERRORES('CNT-01004','Retencion del IVA');-- El parametro del IVA no esta declarado
         END IF;
         IF ABS(rDtlCnt3Etapa.VALOR-rRIva.VALOR)>=0.01 THEN
-- Si el valor de la retencion en la fuente difiere del guardado en el detalle de la contabilizacion
-- damos un error indicando ello
           nContErrores:=nContErrores+1;
           GNRL.ESCRIBIR_ERRORES('CNT-01023',rRIva.MDOPGO_DESCRIPCION,rDtlCnt3Etapa.CTACBR_NUMERO,ROUND(rRIva.VALOR,2),ROUND(rDtlCnt3Etapa.VALOR,2));-- La Retencion del Iva no tiene vinculada una cuenta contable
         END IF;
         rMovCnt(i).SECUENCIA:=nNumSec3RIva+nNum3;
         rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
         rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
         rMovCnt(i).CMP_FECHA:=dFechaCmp;
         rMovCnt(i).CMP_CLAVE:=nClave;
         rMovCnt(i).DEBE:=ROUND(rRIva.VALOR,2);
         rMovCnt(i).DEBEE:=ROUND(rRIva.VALOR,2)*nTipoCambioE;
         nTotalDep:=nTotalDep-ROUND(rRIva.VALOR,2); -- Restamos la cantidad a Depositar
         rMovCnt(i).HABER:=0;
         rMovCnt(i).HABERE:=0;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rRIva.EMP_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rRIva.MYR_CODIGO;
         rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rRIva.CNT_CODIGO;
         rMovCnt(i).SS_S_A_SC_CODIGO:=rRIva.SCNT_CODIGO;
         rMovCnt(i).SS_S_A_CODIGO:=rRIva.AXL_CODIGO;
         rMovCnt(i).SS_S_CODIGO:=rRIva.SAXL_CODIGO;
         rMovCnt(i).SS_CODIGO:=rRIva.SAXL2_CODIGO;
         rMovCnt(i).S_CODIGO:=rRIva.SAXL3_CODIGO;
         rMovCnt(i).DESCRIPCION:=SUBSTR('Ret del Iva de '||rRIva.MDOPGO_DESCRIPCION||' Couta #'||rRIva.NUMERO||' '||rRIva.DESCRIPCION,1,120);
         rMovCnt(i).ASOCIACION:=NULL;
         i:=i+1;
         nTempVerificador:=nTempVerificador+1;
       END LOOP;
       IF nTempVerificador=0 THEN
         nContErrores:=nContErrores+1;
         GNRL.ESCRIBIR_ERRORES('CNT-01022',rDtlCnt3Etapa.NUMERO,rDtlCnt3Etapa.CTACBR_NUMERO);
       ELSIF nTempVerificador>1 THEN
-- Si es mayor que 1 hay un error en la vista
         nContErrores:=nContErrores+1;
         GNRL.ESCRIBIR_ERRORES('ADM-00011','Error en la vista RETENCION_DEL_IVA_CNT para la CUENTA POR COBRAR #'||rDtlCnt3Etapa.CTACBR_NUMERO||' Comuniquese con Softcase C Ltda');
       END IF;
       nNum3:=nNum3+1;-- Subimos la Secuencia para los siguientes DESCUENTOS TERCERA ETAPA
/********************************** FIN RETENCION DEL IVA **********************************/
     END IF;
  END LOOP;
/******************* FIN DESCUENTOS DE LA TERCERA ETAPA *******************************/
  FOR rBanco IN cBanco LOOP
-- Primero hacemos el depósito de bancos
    IF ROUND(nTotalDep,2)>0  THEN
-- Solo cuando hay deposito genera el movimiento en la cuenta de banco
-- caso contrario no. Para evitar que genere un movimiento con debe=0 y haber=0
      rMovCnt(i).SECUENCIA:=nNumSec3;
      rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
      rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
      rMovCnt(i).CMP_FECHA:=dFechaCmp;
      rMovCnt(i).CMP_CLAVE:=nClave;
      rMovCnt(i).DEBE:=ROUND(nTotalDep,2);
      rMovCnt(i).DEBEE:=ROUND(nTotalDep,2)*nTipoCambioE;
      rMovCnt(i).HABER:=0;
      rMovCnt(i).HABERE:=0;
      rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rBanco.EMP_CODIGO;
      rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rBanco.MYR_CODIGO;
      rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rBanco.CNT_CODIGO;
      rMovCnt(i).SS_S_A_SC_CODIGO:=rBanco.SCNT_CODIGO;
      rMovCnt(i).SS_S_A_CODIGO:=rBanco.AXL_CODIGO;
      rMovCnt(i).SS_S_CODIGO:=rBanco.SAXL_CODIGO;
      rMovCnt(i).SS_CODIGO:=rBanco.SAXL2_CODIGO;
      rMovCnt(i).S_CODIGO:=rBanco.SAXL3_CODIGO;
      rMovCnt(i).DESCRIPCION:=SUBSTR('Deposito de '||vDescIng,1,120);
      rMovCnt(i).ASOCIACION:=NULL;
      i:=i+1;
   END IF;
   nNum3:=nNum3+1;
  END LOOP;
  IF nNum3=1 THEN
-- No existe el parametro de bancos porque el nNumDep sale sin sumar uno, no entro al bucle anterior
    nContErrores:=nContErrores+1;
    GNRL.ESCRIBIR_ERRORES('CNT-01004','Banco');-- El parametro de la cuenta contable del Banco no fijado
--    QMS$ERRORS.SHOW_MESSAGE('CNT-01004','Banco');-- El parametro de la cuenta contable del Banco no fijado
  END IF;
  nCaja:=1;
  nNum3:=1;
  FOR rCajas IN cCajas LOOP
    IF rCajas.Cuenta IS NULL THEN
      nContErrores:=nContErrores+1;
      GNRL.ESCRIBIR_ERRORES('CNT-01007',rCajas.CJA_CODIGO); -- no se ha definido la cuenta de la caja
--      QMS$ERRORS.SHOW_MESSAGE('CNT-01007',rCajas.CJA_CODIGO); -- no se ha definido la cuenta de la caja
    END IF;
    -- FIJAMOS EL DEBE
    rMovCnt(i).SECUENCIA:=nNumSec3Cajas+nNum3;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=0;
    rMovCnt(i).DEBEE:=0;
-- Como la caja viene en orden el indice almacenado en rIndiceCaja
-- apunta al Movimiento correcto del HABER
-- y guarda lo mismo en las cajas del DEBE como del HABER
    rMovCnt(i).HABER:=rMovCnt(rIndiceCajas(nCaja)).DEBE;
    rMovCnt(i).HABERE:=rMovCnt(rIndiceCajas(nCaja)).DEBEE;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rCajas.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rCajas.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rCajas.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rCajas.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rCajas.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rCajas.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rCajas.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rCajas.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:=SUBSTR(vDescIng,1,120);
    rMovCnt(i).ASOCIACION:=NULL;
    nCaja:=nCaja+1;
    i:=i+1;
    nNum3:=nNum3+1;
  END LOOP;
-- AHORA SI NO HA HABIDO NINGUN ERROR CREAMOS LOS DETALLES DEL COMPROBANTE
  IF nContErrores=0 THEN

    INSERT INTO COMPROBANTES (TPOCMPEMP_EMP_CODIGO,TPOCMPEMP_TPOCMP_CODIGO,FECHA,CLAVE,
         MAYORIZADO,ESTADO,TOTAL,MONEDA_LOCAL,TIPO_DE_CAMBIO,TIPO_DE_CAMBIOE,
         CONCEPTO,CRRMES_MES,CONTABILIZADO_DESDE)
     VALUES (cEmpCod,cTpoCmp,dFechaCmp,nClave,'F','N',0,vMonedaLocal,nTipoCambio,nTipoCambioE,vDescIng,NULL,'FCT');
    FOR I IN 1..rMovCnt.COUNT LOOP
        QMS$ERRORS.SHOW_DEBUG_INFO(rMovCnt(I).SECUENCIA||' '||rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||
            rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||rMovCnt(I).SS_S_A_SC_CNT_CODIGO||
  	    rMovCnt(I).SS_S_A_SC_CODIGO||rMovCnt(I).SS_S_A_CODIGO||rMovCnt(I).SS_S_CODIGO||
            rMovCnt(I).SS_CODIGO||rMovCnt(I).S_CODIGO||' '||rMovCnt(I).DESCRIPCION||' ** DEBE ** '||rMovCnt(I).DEBE||' ** HABER **'||rMovCnt(I).HABER,'Comuniquese con Softcase');
      IF (rMovCnt(I).DEBE<=0 AND rMovCnt(I).HABER<=0) OR (rMovCnt(I).DEBE>0 AND rMovCnt(I).HABER>0) THEN
        QMS$ERRORS.SHOW_MESSAGE('ADM-00011',rMovCnt(I).SECUENCIA||' '||rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||
            rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||rMovCnt(I).SS_S_A_SC_CNT_CODIGO||
  	    rMovCnt(I).SS_S_A_SC_CODIGO||rMovCnt(I).SS_S_A_CODIGO||rMovCnt(I).SS_S_CODIGO||
            rMovCnt(I).SS_CODIGO||rMovCnt(I).S_CODIGO||' '||rMovCnt(I).DESCRIPCION||' ** DEBE ** '||rMovCnt(I).DEBE||' ** HABER **'||rMovCnt(I).HABER,'Comuniquese con Softcase');
      END IF;
      INSERT INTO MOVIMIENTOS (MVM_ID,CMP_TPOCMPEMP_EMP_CODIGO,CMP_TPOCMPEMP_TPOCMP_CODIGO,
   	    CMP_FECHA,CMP_CLAVE,FECHA,SECUENCIA,DEBE,HABER,DEBEE,HABERE,MONEDA,TIPO_DE_CAMBIO,MAYORIZADO,
  	    SS_S_A_SC_CNT_MYR_EMP_CODIGO,SS_S_A_SC_CNT_MYR_CODIGO,SS_S_A_SC_CNT_CODIGO,
  	    SS_S_A_SC_CODIGO,SS_S_A_CODIGO,SS_S_CODIGO,SS_CODIGO,S_CODIGO,
            DESCRIPCION,ASOCIACION,ESTADO_MOVIMIENTO,OBL_OBL_ID)
        VALUES (MVM_SEQ.NEXTVAL,cEmpCod,cTpoCmp,dFechaCmp,nClave,dFechaCmp,rMovCnt(I).SECUENCIA,
  	    rMovCnt(I).DEBE,rMovCnt(I).HABER,rMovCnt(I).DEBEE,rMovCnt(I).HABERE,
            vMonedaLocal,nTipoCambio,'F',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO,
            rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO,rMovCnt(I).SS_S_A_SC_CNT_CODIGO,
  	    rMovCnt(I).SS_S_A_SC_CODIGO,rMovCnt(I).SS_S_A_CODIGO,rMovCnt(I).SS_S_CODIGO,
            rMovCnt(I).SS_CODIGO,rMovCnt(I).S_CODIGO,
  	    rMovCnt(I).DESCRIPCION,rMovCnt(I).ASOCIACION,'N',NULL);
    END LOOP;
  ELSE
    COMMIT; -- grabamos los errores
    RAISE ERRORES_CONTABILIZA; --Disparamos el error
  END IF;
-- Marcamos la fechas como contabilizadas
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
-- FALLA SI YA EXISTE UN COMPROBANTE IGUAL (CABECERA)
    QMS$ERRORS.SHOW_MESSAGE('CNT-01010',cTpoCmp||'-'||TO_CHAR(dFechaCmp,'DD/MM/YYYY')||'-'||TO_CHAR(nClave));
  WHEN ERRORES_CONTABILIZA THEN
-- Errores contabilizando
     RAISE;
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo en el procedimiento CONTABILIZAR_INGRESOS_FCT por error '||SQLERRM);
END;
/* Crea un comprobante Contable por el Rol de Pagos de Pagos Especiales */
PROCEDURE CONTABILIZAR_PAGO_ESPECIAL
 (NTIPOCAMBIO IN number
 ,NTIPOCAMBIOE IN NUMBER
 ,VMONEDALOCAL IN VARCHAR2
 ,CEMPCOD IN VARCHAR2
 ,CTPOCMP IN VARCHAR2
 ,DFECHACMP IN DATE
 ,NCLAVE IN OUT NUMBER
 ,NNUMERO IN NUMBER
 ,DFECHADESDE IN DATE
 ,DFECHAHASTA IN DATE
 ,CPARAMETRO IN VARCHAR2
 ,CPRMNOMBRE IN VARCHAR2
 ,CCNTPRS IN VARCHAR2
 )
 IS

NDIFCUADRE NUMBER := 0;
I NUMBER;
NCUADREH NUMBER(21, 6) := 0;
VDESCING VARCHAR2(1000);
CNOMBRE_SEC VARCHAR2(100);
NNUMING NUMBER := 0;
NDIFERENCIAPAGO NUMBER(21, 6) := 0;
NCUADRED NUMBER(21, 6) := 0;
--Este proceso crea un Comprobante Contable por un Pago Especial realizado
--desde el Sistema de Rol de Pagos. 
--Los errores que pueden presentarse al realizar este proceso son:
BEGIN
DECLARE
CURSOR cMesCerrado IS
  SELECT COUNT(*)
    FROM CIERRES_DE_MES
    WHERE TRUNC(MES,'MM')=TRUNC(dFechaCmp,'MM')
      AND  ESTADO='C';
CURSOR cGastosRoles IS --(Debe) Cursor de Gastos por Roles de Pagos
SELECT EMP_CODIGO,SUBSTR(RV_MEANING,1,20) DESCRIPCION,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,VALOR
FROM GASTOS_PAGOS_ESPECIALES ,CG_REF_CODES
WHERE EMP_CODIGO = cEmpCod AND
      CODIGO = cParametro AND
      NUMERO = nNumero AND
      (FECHA BETWEEN dFechaDesde AND dFechaHasta) AND
      RV_DOMAIN = 'AGRUPADOR COSTOS GENERAL' AND
      AGRUPADOR_TIPO = RV_LOW_VALUE; 
TYPE tMovCnt  IS TABLE OF MOVIMIENTOS%ROWTYPE INDEX BY BINARY_INTEGER;
rMovCnt tMovCnt; -- Tabla en donde se guardan los datos antes de Contabilizar
nContMesCerrado NUMBER:=0;-- Devuelve 1 si el mes esta cerrado caso contrario 0

CURSOR cSueldosxPagar IS
  SELECT PRMINT.CUENTA_CONTABLE,
         PLNCNT.EMP_CODIGO EMP_CODIGO, PLNCNT.MYR_CODIGO
         MYR_CODIGO, PLNCNT.CNT_CODIGO CNT_CODIGO, PLNCNT.SCNT_CODIGO SCNT_CODIGO,
         PLNCNT.AXL_CODIGO AXL_CODIGO, PLNCNT.SAXL_CODIGO SAXL_CODIGO,
         PLNCNT.SAXL2_CODIGO SAXL2_CODIGO, PLNCNT.SAXL3_CODIGO SAXL3_CODIGO
  FROM PARAMETROS_INTEGRACION PRMINT,PLAN_DE_CUENTAS PLNCNT
  WHERE PRMINT.EMP_CODIGO=cEmpCod
    AND PRMINT.PARAMETRO='RDPSPP'
    AND PRMINT.TIPO='RDP'
    AND PRMINT.CUENTA_CONTABLE=PLNCNT.CODIGO (+);

CURSOR cGasto_Presupuesto IS --(Debe) Cursor de cuentas de Gasto Presupuestario
SELECT EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
       SAXL2_CODIGO,SAXL3_CODIGO,PRM_NOMBRE,DEBE
FROM AFECTACION_PRESUPUESTO_PAGOE 
WHERE EMP_CODIGO = cEmpCod AND
      NUMERO = nNumero AND      
      PRM_CODIGO = cParametro AND 
     (FECHA BETWEEN dFechaDesde AND dFechaHasta) ;
BEGIN
-- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  SELECT NOMBRE_SECUENCIA INTO cNOMBRE_SEC
  FROM TIPOS_COMPROBANTES_EMPRESAS
  WHERE EMP_CODIGO = cEmpCod AND
        TPOCMP_CODIGO = cTpoCmp;
  GNRL.ACTUALIZA_SECUENCIA(cNOMBRE_SEC,nClave);
  OPEN cMesCerrado;
  FETCH cMesCerrado INTO nContMesCerrado;
  IF nContMesCerrado>0 THEN
-- Error no se puede contabilizar para un mes cerrado
      QMS$ERRORS.SHOW_MESSAGE('CNT-00046');-- No se puede crear un comprobante de un mes ya cerrado
  END IF;
  VALIDAR_CONTABILIZACION_ROL(cEmpCod,nNumero,dFechaDesde,dFechaHasta);   
  -- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  BEGIN
     vDescIng:='PAGO DE '||cPrmNombre ||' CORRESPONDE A '||TO_CHAR(dFechaHasta,'MONTH/YYYY');
     INSERT INTO COMPROBANTES (TPOCMPEMP_EMP_CODIGO,TPOCMPEMP_TPOCMP_CODIGO,FECHA,CLAVE,
                               MAYORIZADO,ESTADO,TOTAL,MONEDA_LOCAL,TIPO_DE_CAMBIO,TIPO_DE_CAMBIOE,
                               CONCEPTO,CRRMES_MES,CONTABILIZADO_DESDE)
     VALUES (cEmpCod,cTpoCmp,dFechaCmp,nClave,'F','N',0,vMonedaLocal,nTipoCambio,nTipoCambioE,vDescIng,NULL,'RDP'); 
  EXCEPTION 
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo la inserción del Comprobante por error '||SQLERRM);  
  END;
  i:=1;
  nCuadreD:=0;
  FOR rGastosRoles IN cGastosRoles LOOP
    -- FIJAMOS EL DEBE
    IF i>1 THEN
       IF rMovCnt(i-1).DESCRIPCION <> rGastosRoles.Descripcion THEN
          nNumIng:= nNumIng+1;
       END IF;
    END IF;
    rMovCnt(i).SECUENCIA:=100+nNumIng;
    rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
    rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
    rMovCnt(i).CMP_FECHA:=dFechaCmp;
    rMovCnt(i).CMP_CLAVE:=nClave;
    rMovCnt(i).DEBE:=ROUND(rGastosRoles.VALOR,2);
    rMovCnt(i).DEBEE:=ROUND(rGastosRoles.VALOR,2)*nTipoCambioE;
    rMovCnt(i).HABER:=0;
    rMovCnt(i).HABERE:=0;
    rMovCnt(i).FECHA:=dFechaCmp;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rGastosRoles.EMP_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rGastosRoles.MYR_CODIGO;
    rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rGastosRoles.CNT_CODIGO;
    rMovCnt(i).SS_S_A_SC_CODIGO:=rGastosRoles.SCNT_CODIGO;
    rMovCnt(i).SS_S_A_CODIGO:=rGastosRoles.AXL_CODIGO;
    rMovCnt(i).SS_S_CODIGO:=rGastosRoles.SAXL_CODIGO;
    rMovCnt(i).SS_CODIGO:=rGastosRoles.SAXL2_CODIGO;
    rMovCnt(i).S_CODIGO:=rGastosRoles.SAXL3_CODIGO;
    rMovCnt(i).DESCRIPCION:=rGastosRoles.DESCRIPCION||' corresponde a '||TO_CHAR(dFechaHasta,'MONTH/YYYY');
    rMovCnt(i).ASOCIACION:=NULL;
    rMovCnt(i).COMPROMISO:= 'F';
    rMovCnt(i).OBLIGACION:='F';
    rMovCnt(i).PAGO := 'F';  
    rMovCnt(i).AJUSTE_PRESUPUESTARIO := 'F';
    nCuadreD:=nCuadreD+rMovCnt(i).DEBE;
    i:=i+1;
  END LOOP;
  nCuadreH:=0;
  nDifCuadre:=nCuadreD-nCuadreH;
  IF nDifCuadre>0 THEN -- La diferencia se carga a la cuenta Sueldo Por Pagar o Bancos
     FOR rSueldosxPagar IN cSueldosxPagar LOOP
       rMovCnt(i).SECUENCIA:=201;
       rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(i).CMP_FECHA:=dFechaCmp;
       rMovCnt(i).CMP_CLAVE:=nClave;
       rMovCnt(i).DEBE:=0;
       rMovCnt(i).DEBEE:=0;
       rMovCnt(i).HABER:=ROUND(nDifCuadre,2);
       rMovCnt(i).HABERE:=ROUND(nDifCuadre,2)*nTipoCambioE;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rSueldosxPagar.EMP_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rSueldosxPagar.MYR_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rSueldosxPagar.CNT_CODIGO;
       rMovCnt(i).SS_S_A_SC_CODIGO:=rSueldosxPagar.SCNT_CODIGO;
       rMovCnt(i).SS_S_A_CODIGO:=rSueldosxPagar.AXL_CODIGO;
       rMovCnt(i).SS_S_CODIGO:=rSueldosxPagar.SAXL_CODIGO;
       rMovCnt(i).SS_CODIGO:=rSueldosxPagar.SAXL2_CODIGO;
       rMovCnt(i).S_CODIGO:=rSueldosxPagar.SAXL3_CODIGO;
       rMovCnt(i).DESCRIPCION:='PAGO DE '||cPrmNombre ||' CORRESPONDE A '||TO_CHAR(dFechaHasta,'MONTH/YYYY');
       rMovCnt(i).ASOCIACION:=NULL;   
       rMovCnt(i).COMPROMISO:= 'F';
       rMovCnt(i).OBLIGACION:='F';
       rMovCnt(i).PAGO := 'F';  
       rMovCnt(i).AJUSTE_PRESUPUESTARIO := 'F';
       i:=i+1; 
     END LOOP;
  ELSE
     QMS$ERRORS.SHOW_MESSAGE('CNT-01107');
  END IF;
  IF cCntPrs = 'V' THEN
     FOR rGasto_Presupuesto IN cGasto_Presupuesto LOOP
      -- FIJAMOS EL DEBE DE LA AFECTACION PRESUPUESTARIA
       rMovCnt(i).SECUENCIA:=301;
       rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(i).CMP_FECHA:=dFechaCmp;
       rMovCnt(i).CMP_CLAVE:=nClave;
       rMovCnt(i).DEBE:=ROUND(rGasto_Presupuesto.DEBE,2);
       rMovCnt(i).DEBEE:=ROUND(rGasto_Presupuesto.DEBE,2)*nTipoCambioE;
       rMovCnt(i).HABER:=0;
       rMovCnt(i).HABERE:=0;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rGasto_Presupuesto.EMP_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rGasto_Presupuesto.MYR_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rGasto_Presupuesto.CNT_CODIGO;
       rMovCnt(i).SS_S_A_SC_CODIGO:=rGasto_Presupuesto.SCNT_CODIGO;
       rMovCnt(i).SS_S_A_CODIGO:=rGasto_Presupuesto.AXL_CODIGO;
       rMovCnt(i).SS_S_CODIGO:=rGasto_Presupuesto.SAXL_CODIGO;
       rMovCnt(i).SS_CODIGO:=rGasto_Presupuesto.SAXL2_CODIGO;
       rMovCnt(i).S_CODIGO:=rGasto_Presupuesto.SAXL3_CODIGO;
       rMovCnt(i).DESCRIPCION:= 'PAGO DE '||rGasto_Presupuesto.PRM_NOMBRE||' DE '||TO_CHAR(dFechaHasta,'MONTH/YYYY');
       rMovCnt(i).ASOCIACION:=NULL;
       rMovCnt(i).COMPROMISO:= 'V';
       rMovCnt(i).OBLIGACION:='V';
       rMovCnt(i).PAGO := 'V'; 
       rMovCnt(i).AJUSTE_PRESUPUESTARIO := 'F';          
       i:=i+1;
     END LOOP;
  END IF;
-- AHORA SI NO HA HABIDO NINGUN ERROR CREAMOS LOS DETALLES DEL COMPROBANTE
  FOR I IN 1..rMovCnt.COUNT LOOP
    IF (rMovCnt(I).DEBE=0 AND rMovCnt(I).HABER=0) OR (rMovCnt(I).DEBE>0 AND rMovCnt(I).HABER>0) THEN
      QMS$ERRORS.SHOW_MESSAGE('ADM-00009',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||
                                          rMovCnt(I).SS_S_A_SC_CNT_CODIGO||rMovCnt(I).SS_S_A_SC_CODIGO||
                                          rMovCnt(I).SS_S_A_CODIGO||rMovCnt(I).SS_S_CODIGO||rMovCnt(I).SS_CODIGO||
                                          rMovCnt(I).S_CODIGO||' '||rMovCnt(I).DESCRIPCION||' ** DEBE ** '||
                                          rMovCnt(I).DEBE||' ** HABER **'||rMovCnt(I).HABER,'Comuniquese con Softcase');
    END IF;
    INSERT INTO MOVIMIENTOS (MVM_ID,CMP_TPOCMPEMP_EMP_CODIGO,CMP_TPOCMPEMP_TPOCMP_CODIGO,
  	    CMP_FECHA,CMP_CLAVE,FECHA,SECUENCIA,DEBE,HABER,DEBEE,HABERE,MONEDA,TIPO_DE_CAMBIO,MAYORIZADO,
          COMPROMISO,OBLIGACION,PAGO,AJUSTE_PRESUPUESTARIO,
  	    SS_S_A_SC_CNT_MYR_EMP_CODIGO,SS_S_A_SC_CNT_MYR_CODIGO,SS_S_A_SC_CNT_CODIGO,
  	    SS_S_A_SC_CODIGO,SS_S_A_CODIGO,SS_S_CODIGO,SS_CODIGO,S_CODIGO,
          DESCRIPCION,ASOCIACION,ESTADO_MOVIMIENTO,OBL_OBL_ID)
    VALUES (MVM_SEQ.NEXTVAL,cEmpCod,cTpoCmp,dFechaCmp,nClave,dFechaCmp,rMovCnt(I).SECUENCIA,
      	rMovCnt(I).DEBE,rMovCnt(I).HABER,rMovCnt(I).DEBEE,rMovCnt(I).HABERE,
            vMonedaLocal,nTipoCambio,'F',rMovCnt(i).COMPROMISO,rMovCnt(i).OBLIGACION,
            rMovCnt(i).PAGO,rMovCnt(i).AJUSTE_PRESUPUESTARIO,rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO,
            rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO,rMovCnt(I).SS_S_A_SC_CNT_CODIGO,
  	      rMovCnt(I).SS_S_A_SC_CODIGO,rMovCnt(I).SS_S_A_CODIGO,rMovCnt(I).SS_S_CODIGO,
            rMovCnt(I).SS_CODIGO,rMovCnt(I).S_CODIGO,
  	      rMovCnt(I).DESCRIPCION,rMovCnt(I).ASOCIACION,'N',NULL);
  END LOOP;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
-- FALLA SI YA EXISTE UN COMPROBANTE IGUAL (CABECERA)
    QMS$ERRORS.SHOW_MESSAGE('CNT-01010',cTpoCmp||'-'||TO_CHAR(dFechaCmp,'DD/MM/YYYY')||'-'||TO_CHAR(nClave));
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo en el procedimiento CONTABILIZAR_PAGO_ESPECIAL por error '||SQLERRM);
END;
END;
/* Permite validar los datos  para Contabilizar el Rol de Pagos */
PROCEDURE VALIDAR_CONTABILIZACION_ROL
 (CEMPCOD IN VARCHAR2
 ,NNUMERO IN NUMBER
 ,DFECHADESDE IN DATE
 ,DFECHAHASTA IN DATE
 )
 IS

VMENSAJEERROR VARCHAR2(1000);
VCUENTA VARCHAR2(40);
VDATO VARCHAR2(66);
VPARAM VARCHAR(3);
VTER VARCHAR2(3);
--En primer lugar validamos que todos los empleados pertenezcan a un centro de costo
--Además, se valida que el porcentaje de distribución de gastos por empleado entre
--los diferentes centros de costos,no sobrepase ni sea inferior al 100%
--Por último se valida que tanto los parámetros de gastos como de pasivos, estén 
--asociados a una cuenta contable.
-- Errores CNT-01101 EMPLEADO NO ASIGNADO A UN CENTRO DE COSTO
--         CNT-01102 LA DISTRIBUCIÓN DE INGRESOS DEL EMPLEADO SUPERA EL 100%
--         CNT-01103 LA DISTRIBUCIÓN DE INGRESOS DEL EMPLEADO NO LLEGA AL 100% 
--         CNT-01104 PARÁMETROS DE GASTOS NO TIENEN CUENTA ASOCIADA
--         CNT-01106 PARÁMETROS DE PASIVOS NO TIENE CUENTA ASOCIADA
--         CNT-01105 PARÁMETROS DE INTEGRACION NO TIENE CUENTA ASOCIADA
DECLARE
CURSOR EMPLEADOS_NO_ASIGNADOS IS
SELECT DISTINCT TO_CHAR(CODIGO)||' '||APELLIDOS||' '||NOMBRES 
FROM EMPLEADOS_ROLES,MOVIMIENTOS_TOTALES 
WHERE EMP_CODIGO = cEmpCod AND
      EMP_CODIGO = EMPROL_EMP_CODIGO  AND
      EMP_CODIGO = PRMROL_EMP_CODIGO  AND
      CODIGO = EMPROL_CODIGO AND
      NUMERO = nNumero AND
      (FECHA BETWEEN dFechaDesde AND dFechaHasta) AND  
      CODIGO NOT IN (SELECT EMPROL_CODIGO FROM EMPLEADOS_CENTROS_DE_COSTOS
                     WHERE EMPROL_EMP_CODIGO = EMP_CODIGO AND
                           CNTCST_EMP_CODIGO = EMP_CODIGO);
CURSOR PORCENTAJE_MAYOR IS 
SELECT TO_CHAR(CODIGO)||' '||APELLIDOS||' '||NOMBRES FROM EMPLEADOS_ROLES
WHERE EMP_CODIGO = cEmpCod AND
      100 <(SELECT SUM(PORCENTAJE) FROM EMPLEADOS_CENTROS_DE_COSTOS
            WHERE EMPROL_EMP_CODIGO = EMP_CODIGO AND
                  CNTCST_EMP_CODIGO = EMP_CODIGO AND
                  EMPROL_CODIGO = CODIGO);
CURSOR PORCENTAJE_MENOR IS 
SELECT TO_CHAR(CODIGO)||' '||APELLIDOS||' '||NOMBRES FROM EMPLEADOS_ROLES
WHERE EMP_CODIGO = cEmpCod AND
      100 >(SELECT SUM(PORCENTAJE) FROM EMPLEADOS_CENTROS_DE_COSTOS
            WHERE EMPROL_EMP_CODIGO = EMP_CODIGO AND
                  CNTCST_EMP_CODIGO = EMP_CODIGO AND
                  EMPROL_CODIGO = CODIGO);

CURSOR PARAMETROS_GASTOS_SIN_CUENTA IS
SELECT SUBSTR(PRMROL.CODIGO||' '||SUBSTR(PRMROL.NOMBRE,1,25)||' Asociar con '||SUBSTR(CNTCST.DESCRIPCION,1,25),1,65) PARAMETROS
FROM PARAMETROS_ROLES  PRMROL,MOVIMIENTOS_TOTALES MVMTOT,
     EMPLEADOS_CENTROS_DE_COSTOS EMPCNTCST,
     CENTROS_DE_COSTOS CNTCST
WHERE PRMROL.EMP_CODIGO = cEmpCod AND
      PRMROL.TIPO NOT IN ('E','B') AND
      PRMROL.TIPO_CONTABILIZACION = 'G' AND
      PRMROL.EMP_CODIGO = MVMTOT.PRMROL_EMP_CODIGO AND
      PRMROL.EMP_CODIGO = MVMTOT.EMPROL_EMP_CODIGO AND
      PRMROL.CODIGO = MVMTOT.PRMROL_CODIGO AND          
      MVMTOT.NUMERO = nNumero AND
      (MVMTOT.FECHA BETWEEN dFechaDesde AND dFechaHasta) AND
      MVMTOT.EMPROL_EMP_CODIGO = EMPCNTCST.EMPROL_EMP_CODIGO AND
      MVMTOT.EMPROL_EMP_CODIGO = EMPCNTCST.CNTCST_EMP_CODIGO AND
      MVMTOT.EMPROL_CODIGO = EMPCNTCST.EMPROL_CODIGO AND
      MVMTOT.EMPROL_EMP_CODIGO = CNTCST.EMP_CODIGO AND
      MVMTOT.PRMROL_EMP_CODIGO = CNTCST.EMP_CODIGO AND
      MVMTOT.DEBE > 0 AND
      EMPCNTCST.EMPROL_EMP_CODIGO = CNTCST.EMP_CODIGO AND
      EMPCNTCST.CNTCST_EMP_CODIGO = CNTCST.EMP_CODIGO AND
      EMPCNTCST.CNTCST_TIPO=CNTCST.TIPO AND
      EMPCNTCST.CNTCST_AGRUPADOR = CNTCST.AGRUPADOR  AND
      CNTCST.TIPO||CNTCST.AGRUPADOR||PRMROL.CODIGO NOT IN ( SELECT AGRCNT_TIPO||AGRCNT_CODIGO||SUBSTR(CLAVE_RELACIONADA,1,5) 
                                                            FROM CUENTAS_ASOCIADAS CNTASC
                                                            WHERE CNTASC.TIPO_DE_CUENTA = 'RDP' AND
                                                                  CNTASC.TIPO_DE_ASOCIACION ='GRP' AND
                                                                  CNTASC.EMP_CODIGO = cEmpCod)
GROUP BY SUBSTR(PRMROL.CODIGO||' '||SUBSTR(PRMROL.NOMBRE,1,25)||' Asociar con '||SUBSTR(CNTCST.DESCRIPCION,1,25),1,65);

CURSOR PASIVOS_SIN_CUENTA_GNR IS
SELECT DISTINCT (PRMROL.CODIGO||' '||PRMROL.NOMBRE)
FROM MOVIMIENTOS_TOTALES MVMTOT,PARAMETROS_ROLES PRMROL
WHERE PRMROL.EMP_CODIGO = cEmpCod AND
      (((PRMROL.PROPIETARIO = 'P' OR PRMROL.PROVISION = 'V') AND PRMROL.TIPO_MOVIMIENTO = 'D') OR PRMROL.TIPO_MOVIMIENTO = 'C') AND
       MVMTOT.NUMERO = nNumero AND
      (MVMTOT.FECHA BETWEEN dFechaDesde AND dFechaHasta) AND
      PRMROL.TIPO_CONTABILIZACION = 'G' AND
      PRMROL.TIPO <> 'E' AND PRMROL.TIPO <> 'B' AND
      MVMTOT.PRMROL_EMP_CODIGO = PRMROL.EMP_CODIGO AND
      MVMTOT.EMPROL_EMP_CODIGO = PRMROL.EMP_CODIGO AND
      MVMTOT.PRMROL_CODIGO = PRMROL.CODIGO AND
      PRMROL.CODIGO NOT IN (SELECT CLAVE_RELACIONADA
                            FROM CUENTAS_ASOCIADAS
                            WHERE EMP_CODIGO = cEmpCod AND
                                  TIPO_DE_CUENTA = 'RDP' AND
                                  TIPO_DE_ASOCIACION = 'PRP');

CURSOR PASIVOS_SIN_CUENTA_IND IS
SELECT DISTINCT (PRMROL.CODIGO||' '||PRMROL.NOMBRE||' DEL EMPLEADO '||TO_CHAR(MVMTOT.EMPROL_CODIGO))
FROM MOVIMIENTOS_TOTALES MVMTOT,PARAMETROS_ROLES PRMROL , EMPLEADOS_CUENTAS_INDIVIDUALES EMPCNTIND
WHERE PRMROL.EMP_CODIGO = cEmpCod AND
      (((PRMROL.PROPIETARIO = 'P' OR PRMROL.PROVISION = 'V') AND PRMROL.TIPO_MOVIMIENTO = 'D') OR PRMROL.TIPO_MOVIMIENTO = 'C') AND
      MVMTOT.NUMERO = nNumero AND
      (MVMTOT.FECHA BETWEEN dFechaDesde AND dFechaHasta) AND
      PRMROL.TIPO_CONTABILIZACION = 'I' AND
      PRMROL.TIPO <> 'E' AND PRMROL.TIPO <> 'B' AND
      MVMTOT.PRMROL_EMP_CODIGO = PRMROL.EMP_CODIGO AND
      MVMTOT.PRMROL_CODIGO = PRMROL.CODIGO AND
      MVMTOT.EMPROL_EMP_CODIGO = PRMROL.EMP_CODIGO AND
      NVL(MVMTOT.DEBE,MVMTOT.HABER) > 0 AND
      ((MVMTOT.EMPROL_CODIGO NOT IN (SELECT CNTIND.EMPROL_CODIGO 
                                   FROM EMPLEADOS_CUENTAS_INDIVIDUALES CNTIND
                                   WHERE CNTIND.EMPROL_EMP_CODIGO = MVMTOT.EMPROL_EMP_CODIGO)) OR
      (MVMTOT.EMPROL_EMP_CODIGO = EMPCNTIND.EMPROL_EMP_CODIGO AND
      MVMTOT.EMPROL_CODIGO = EMPCNTIND.EMPROL_CODIGO AND
      PRMROL.EMP_CODIGO = EMPCNTIND.EMPROL_EMP_CODIGO AND
      PRMROL.CODIGO||EMPCNTIND.CUENTA_CONTABLE NOT IN (SELECT CLAVE_RELACIONADA||CUENTA
                            FROM CUENTAS_ASOCIADAS
                            WHERE EMP_CODIGO = cEmpCod AND
                                  TIPO_DE_CUENTA = 'RDP' AND
                                  TIPO_DE_ASOCIACION = 'PRP')));

  CURSOR CTERCERIZADORA IS
  SELECT DISTINCT TERCERIZADORA,SUBSTR(CG.RV_MEANING,1,50) EMPRESA
  FROM EMPLEADOS_rOLES EMPROL,CG_REF_CODES CG
  WHERE CG.RV_DOMAIN = 'TERCERIZADORA' AND
        EMPROL.TERCERIZADORA = CG.RV_LOW_VALUE;
BEGIN
   -- Valida que no existan empleados sin Centro de Costo Asociado
   vMensajeError:=NULL;
   OPEN EMPLEADOS_NO_ASIGNADOS;
   LOOP
      FETCH EMPLEADOS_NO_ASIGNADOS INTO vDato;
      EXIT WHEN EMPLEADOS_NO_ASIGNADOS%NOTFOUND;
      vMensajeError:=vMensajeError||' '||vDato;
   END LOOP;
   CLOSE EMPLEADOS_NO_ASIGNADOS;
   IF vMensajeError IS NOT NULL THEN
      QMS$ERRORS.SHOW_MESSAGE('CNT-01101',vMensajeError);    
   END IF;

-- Valida que el porcentaje de distribución de gastos por empleado no sea mayor al 100%
   vMensajeError:=NULL;
   OPEN PORCENTAJE_MAYOR;
   LOOP
      FETCH PORCENTAJE_MAYOR INTO vDato;
      EXIT WHEN PORCENTAJE_MAYOR%NOTFOUND;
      vMensajeError:=vMensajeError||' '||vDato;
   END LOOP;
   CLOSE PORCENTAJE_MAYOR;
   IF vMensajeError IS NOT NULL THEN
      QMS$ERRORS.SHOW_MESSAGE('CNT-01102',vMensajeError);    
   END IF;   

-- Valida que el porcentaje de distribución de gastos por empleado no sea menor al 100%
   vMensajeError:=NULL;
   OPEN PORCENTAJE_MENOR;
   LOOP
      FETCH PORCENTAJE_MENOR INTO vDato;
      EXIT WHEN PORCENTAJE_MENOR%NOTFOUND;
      vMensajeError:=vMensajeError||' '||vDato;
   END LOOP;
   CLOSE PORCENTAJE_MENOR;
   IF vMensajeError IS NOT NULL THEN
      QMS$ERRORS.SHOW_MESSAGE('CNT-01103',vMensajeError);    
   END IF;   

-- Valida que no existan parámetros que generan Gastos sin una cuenta de Gastos asociada
   vMensajeError:=NULL;
   OPEN PARAMETROS_GASTOS_SIN_CUENTA ;
   LOOP
      FETCH PARAMETROS_GASTOS_SIN_CUENTA  INTO vDato;
      EXIT WHEN PARAMETROS_GASTOS_SIN_CUENTA %NOTFOUND OR LENGTH(vMensajeError) >980;
      IF vMensajeError IS NULL OR LENGTH (vMensajeError) <= 920 THEN
         vMensajeError:=vMensajeError||' '||vDato;
      END IF;
      IF LENGTH(vMensajeError) > 980 THEN 
         vMensajeError := vMensajeError||' y Otros más' ;
      END IF; 
   END LOOP;
   CLOSE PARAMETROS_GASTOS_SIN_CUENTA;
   IF vMensajeError IS NOT NULL THEN
      QMS$ERRORS.SHOW_MESSAGE('CNT-01104',vMensajeError);    
   END IF;  

-- Valida que no existan parámetros generales que generan Deudas sin una cuenta de Pasivos asociada
   vMensajeError:=NULL;
   OPEN PASIVOS_SIN_CUENTA_GNR ;
   LOOP
      FETCH PASIVOS_SIN_CUENTA_GNR  INTO vDato;
      EXIT WHEN PASIVOS_SIN_CUENTA_GNR %NOTFOUND;
      vMensajeError:=vMensajeError||' '||vDato;
   END LOOP;
   CLOSE PASIVOS_SIN_CUENTA_GNR;
   IF vMensajeError IS NOT NULL THEN
      QMS$ERRORS.SHOW_MESSAGE('CNT-01106',vMensajeError);    
   END IF; 

-- Valida que no existan parámetros individuales que generan Deudas sin una cuenta de Pasivos asociada
   vMensajeError:=NULL;
   OPEN PASIVOS_SIN_CUENTA_IND ;
   LOOP
      FETCH PASIVOS_SIN_CUENTA_IND  INTO vDato;
      EXIT WHEN PASIVOS_SIN_CUENTA_IND %NOTFOUND;
      vMensajeError:=vMensajeError||' '||vDato;
   END LOOP;
   CLOSE PASIVOS_SIN_CUENTA_IND;
   IF vMensajeError IS NOT NULL THEN
      QMS$ERRORS.SHOW_MESSAGE('CNT-01106',vMensajeError);    
   END IF; 

-- Valida que no existen parametros de integración 
   vMensajeError:=NULL;
   OPEN CTERCERIZADORA;
   LOOP
      FETCH CTERCERIZADORA INTO vParam,vDato;
      BEGIN
         SELECT SUBSTR(PRMINT.PARAMETRO,4,3) INTO vTer
         FROM PARAMETROS_INTEGRACION PRMINT
         WHERE SUBSTR(PRMINT.PARAMETRO,4,3) = vParam AND
               TIPO = 'RDP';
      EXCEPTION
      WHEN OTHERS THEN
         vMensajeError:=vMensajeError||' '||vDato;
      END;
      EXIT WHEN CTERCERIZADORA %NOTFOUND;         
   END LOOP;
   CLOSE CTERCERIZADORA;
   IF vMensajeError IS NOT NULL THEN
       QMS$ERRORS.SHOW_MESSAGE('CNT-01105',vMensajeError);    
   END IF;
EXCEPTION
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo en el procedimiento VALIDAR_CONTABILIZAR_ROL por error '||SQLERRM);
END;
/* Devuelve los descuentos de Caja_medica */
FUNCTION DESCONTADO_EN_CAJA_MEDICA
 (NPLNHNR PLANILLAS_HONORARIOS_MDC.NUMERO%TYPE
 )
 RETURN NUMBER
 IS
DECLARE
-- Devuelve la suma de valores descontados a planillas de honorarios medicos
  CURSOR cDscCM IS
    SELECT SUM(VALOR) VALOR
    FROM DESCUENTOS_CM
    WHERE ESTADO='NRM'
    AND PLNHNRMDC_NUMERO=nPlnHnr;
  nSum NUMBER:=0;
BEGIN
  OPEN cDscCM;
  FETCH cDscCM INTO nSum;
  CLOSE cDscCM;
  RETURN NVL(nSum,0);
END;
/* Permite validar los datos  para Contabilizar el Rol de Pagos */
PROCEDURE VALIDAR_CONTABILIZACION_AF
 (CEMPCOD IN VARCHAR2
 ,CMOVIMIENTO IN VARCHAR2
 ,NNUMERO IN NUMBER
 ,CTIPOASOCIACION IN VARCHAR2
 ,NMES IN NUMBER
 )
 IS

VMENSAJEERROR VARCHAR2(1000);
VTIPOINGRESO VARCHAR2(3);
VCUENTA VARCHAR2(40);
VDATO VARCHAR2(66);
--En primer lugar validamos que todos los subgrupos de activos fijos estén enlazados
--con una cuenta contable

-- Errores CNT-01301 SUBGRUPO NO TIENE CUENTA ASIGANADA
-- Errores CNT-01302 SUBGRUPO NO TIENE CUENTA DE DEPRECIACION ASOCIADA
-- Errores CNT-01303 SUBGRUPO NO TIENE CUENTA DE GASTO POR DEPRECIACION ASOCIADA
-- Errores CNT-01304 PARÁMETROS DE INTEGRACION NO TIENE CUENTA ASOCIADA
-- Errores CNT-01305 PROVEEDOR NO TIENE CUENTA DE OBLIGACIÓN ASOCIADA
-- Errores CNT-01306 SUMINISTRO DE CONTROL  NO TIENE CUENTA DE GASTO ASOCIADA
-- Errores CNT-01307 LA DISTRIBUCIÓN DE DEPARTAMENTO POR CENTRO DE COSTO SUPERA EL 100%
-- Errores CNT-01308 LA DISTRIBUCIÓN DE DEPARTAMENTO POR CENTRO DE COSTO  NO LLEGA AL 100% 
-- Errores CNT-01309 EL DEPARTAMENTO NO ESTÁ ASOCIADO A UN CENTRO DE COSTO
DECLARE
--*****Cursores para validar la contabilización de Depreciaciones de Activos Fijos*********
CURSOR DPR_SIN_CUENTA IS  -- Cursor de departamentos que no se asocian a un centro de costo
SELECT DISTINCT AREA||DEPARTAMENTO CODIGO,DPR.NOMBRE NOMBRE FROM ACTIVOS_FIJOS_ASIGNADOS, DEPARTAMENTOS DPR
WHERE AREA||DEPARTAMENTO NOT IN (SELECT DISTINCT C.DPR_ara_CODIGO||C.DPR_CODIGO
                                         FROM DEPARTAMENTOS_cENTROS_COSTOS C) AND
      AREA||DEPARTAMENTO = DPR.ARA_CODIGO||DPR.CODIGO ;
CURSOR SBG_DEPRECIACIONES IS --Cursor de Activos Fijos sin cuenta de Depreciaciones
SELECT DISTINCT TO_CHAR(GRP.CODIGO)||' '||SUBSTR(GRP.DESCRIPCION,1,40)
FROM GRUPOS_ACTIVOS_FIJOS GRP,
     DETALLES_DEPRECIACIONES DTLDPR
WHERE GRP.EMP_CODIGO = cEmpCod AND
      GRP.EMP_CODIGO = DTLDPR.SBGACTFJO_GRPACTFJO_EMP_CODIGO AND
      GRP.CODIGO = DTLDPR.ACTFSBGACTFJO_GRPACTFJO_CODIGO AND
      GRP.ESTADO_DE_DISPONIBILIDAD = 'D' AND
      TO_CHAR(DTLDPR.ACTFSBGACTFJO_GRPACTFJO_CODIGO) NOT IN (SELECT CLAVE_RELACIONADA
                                                             FROM CUENTAS_ASOCIADAS
                                                             WHERE EMP_CODIGO = cEmpCod AND
                                                             TIPO_DE_CUENTA = 'AFJ' AND
                                                             TIPO_DE_ASOCIACION = 'DAF') AND
      DTLDPR.DPRACF_ANIO = nNumero AND
      DTLDPR.DPRACF_MES = nMes;

CURSOR SBG_GASTOS_DPR IS --Cursor de Activos Fijos sin cuenta de Gastos por Depreciaciones
SELECT DISTINCT TO_CHAR(GRP.CODIGO)||' '||SUBSTR(GRP.DESCRIPCION,1,40)
FROM GRUPOS_ACTIVOS_FIJOS GRP,
     DETALLES_DEPRECIACIONES DTLDPR
WHERE GRP.EMP_CODIGO = cEmpCod AND
      GRP.EMP_CODIGO = DTLDPR.SBGACTFJO_GRPACTFJO_EMP_CODIGO AND
      GRP.CODIGO = DTLDPR.ACTFSBGACTFJO_GRPACTFJO_CODIGO AND
      GRP.ESTADO_DE_DISPONIBILIDAD = 'D' AND
      TO_CHAR(DTLDPR.ACTFSBGACTFJO_GRPACTFJO_CODIGO) NOT IN (SELECT CLAVE_RELACIONADA
                                                             FROM CUENTAS_ASOCIADAS
                                                             WHERE EMP_CODIGO = cEmpCod AND
                                                             TIPO_DE_CUENTA = 'AFJ' AND
                                                             TIPO_DE_ASOCIACION = 'GDP') AND
      DTLDPR.DPRACF_ANIO = nNumero AND
      DTLDPR.DPRACF_MES = nMes;

--*****Cursor para validar la contabilización de Egresos de Activos Fijos*********
CURSOR SIN_CUENTA_AFJGSTDEP IS --Cursor de Activos Fijos sin cuenta Depreciaciones o de Activos Fijos
SELECT TO_CHAR(SBGAFJ.CODIGO)||' '||SUBSTR(SBGAFJ.DESCRIPCION,1,40)
FROM GRUPOS_ACTIVOS_FIJOS SBGAFJ,DETALLES_EGRESOS_ACTIVOS DTLEGRAFJ,
     ACTIVOS_FIJOS_ESPECIFICOS AFJESP
WHERE SBGAFJ.EMP_CODIGO = cEmpCod AND
      SBGAFJ.EMP_CODIGO = DTLEGRAFJ.EGRACTFJO_EMP_CODIGO AND
      SBGAFJ.CODIGO = DTLEGRAFJ.ACTFSBGACTFJO_GRPACTFJO_CODIGO AND 
      DTLEGRAFJ.EGRACTFJO_NUMERO = NNUMERO AND            
      DTLEGRAFJ.SBGACTFJO_GRPACTFJO_EMP_CODIGO = AFJESP.SBGACTFJO_GRPACTFJO_EMP_CODIGO AND
      DTLEGRAFJ.ACTFSBGACTFJO_GRPACTFJO_CODIGO = AFJESP.ACTFSBGACTFJO_GRPACTFJO_CODIGO AND
      DTLEGRAFJ.ACTFACTFJOGNR_SBGACTFJO_CODIGO = AFJESP.ACTFJOGNR_SBGACTFJO_CODIGO AND
      DTLEGRAFJ.ACTFJOESP_ACTFJOGNR_CODIGO     = AFJESP.ACTFJOGNR_CODIGO AND
      DTLEGRAFJ.ACTFJOESP_CODIGO               = AFJESP.CODIGO AND
      AFJESP.TIPO = 'A' AND
      TO_CHAR(SBGAFJ.CODIGO) NOT IN (SELECT CLAVE_RELACIONADA
                                     FROM CUENTAS_ASOCIADAS
                                     WHERE EMP_CODIGO = cEmpCod AND
                                     TIPO_DE_CUENTA = 'AFJ' AND
                                     TIPO_DE_ASOCIACION = cTipoAsociacion);

--*****Cursores para validar la contabilización de Regulaciones de Activos Fijos*********
CURSOR SIN_CUENTA_AFJDEP IS --Cursor de Activos Fijos sin cuenta de Activos Fijos y Depreciaciones
SELECT TO_CHAR(SBGAFJ.CODIGO)||' '||SUBSTR(SBGAFJ.DESCRIPCION,1,40)
FROM GRUPOS_ACTIVOS_FIJOS SBGAFJ,DETALLES_REGULACIONES_ACTIVOS DTLRGLAFJ,
     ACTIVOS_FIJOS_ESPECIFICOS AFJESP
WHERE SBGAFJ.EMP_CODIGO = cEmpCod AND
      SBGAFJ.EMP_CODIGO = DTLRGLAFJ.RGLACTFJO_EMP_CODIGO AND
      SBGAFJ.CODIGO = DTLRGLAFJ.ACTFSBGACTFJO_GRPACTFJO_CODIGO AND 
      DTLRGLAFJ.RGLACTFJO_NUMERO = NNUMERO AND            
      DTLRGLAFJ.SBGACTFJO_GRPACTFJO_EMP_CODIGO = AFJESP.SBGACTFJO_GRPACTFJO_EMP_CODIGO AND
      DTLRGLAFJ.ACTFSBGACTFJO_GRPACTFJO_CODIGO = AFJESP.ACTFSBGACTFJO_GRPACTFJO_CODIGO AND
      DTLRGLAFJ.ACTFACTFJOGNR_SBGACTFJO_CODIGO = AFJESP.ACTFJOGNR_SBGACTFJO_CODIGO AND
      DTLRGLAFJ.ACTFJOESP_ACTFJOGNR_CODIGO     = AFJESP.ACTFJOGNR_CODIGO AND
      DTLRGLAFJ.ACTFJOESP_CODIGO               = AFJESP.CODIGO AND
      AFJESP.TIPO = 'A' AND
      TO_CHAR(SBGAFJ.CODIGO) NOT IN (SELECT CLAVE_RELACIONADA
                                     FROM CUENTAS_ASOCIADAS
                                     WHERE EMP_CODIGO = cEmpCod AND
                                           TIPO_DE_CUENTA = 'AFJ' AND
                                           TIPO_DE_ASOCIACION = cTipoAsociacion);

--*****Cursores para validar la contabilización de Ingresos de Activos Fijos*********
CURSOR SIN_CUENTA_AFJ IS --Cursor de Activos Fijos sin cuenta de Activos Fijos 
SELECT TO_CHAR(SBGAFJ.CODIGO)||' '||SUBSTR(SBGAFJ.DESCRIPCION,1,40)
FROM GRUPOS_ACTIVOS_FIJOS SBGAFJ,
     DETALLES_INGRESOS_ACTIVOS DTLINGAFJ,
     ACTIVOS_FIJOS_GENERALES AFJGNR
WHERE SBGAFJ.EMP_CODIGO = cEmpCod AND
      DTLINGAFJ.INGACTFJO_EMP_CODIGO = SBGAFJ.EMP_CODIGO   AND
      DTLINGAFJ.ACTFSBGACTFJO_GRPACTFJO_CODIGO = SBGAFJ.CODIGO  AND
      DTLINGAFJ.INGACTFJO_NUMERO = NNUMERO AND            
      DTLINGAFJ.SBGACTFJO_GRPACTFJO_EMP_CODIGO = AFJGNR.SBGACTFJO_GRPACTFJO_EMP_CODIGO AND
      DTLINGAFJ.ACTFSBGACTFJO_GRPACTFJO_CODIGO = AFJGNR.SBGACTFJO_GRPACTFJO_CODIGO AND
      DTLINGAFJ.ACTFJOGNR_SBGACTFJO_CODIGO = AFJGNR.SBGACTFJO_CODIGO AND
      DTLINGAFJ.ACTFJOGNR_CODIGO     = AFJGNR.CODIGO AND
      AFJGNR.TIPO = 'A' AND
      TO_CHAR(SBGAFJ.CODIGO) NOT IN (SELECT CLAVE_RELACIONADA
                                     FROM CUENTAS_ASOCIADAS
                                     WHERE EMP_CODIGO = cEmpCod AND
                                     TIPO_DE_CUENTA = 'AFJ' AND
                                     TIPO_DE_ASOCIACION = cTipoAsociacion);
CURSOR SIN_OBLIGACION IS -- Cursor de Activos Fijos sin cuenta de Obligacion asociada
SELECT TO_CHAR(PRVACF.CODIGO)||' '||PRVACF.NOMBRE
FROM PROVEEDORES_ACTIVOS_FIJOS PRVACF,
     INGRESOS_ACTIVOS_FIJOS INGACTFJO
WHERE PRVACF.EMP_CODIGO  = cEmpCod AND
      PRVACF.CODIGO = INGACTFJO.PRVACTFJO_CODIGO AND
      INGACTFJO.EMP_CODIGO = cEmpCod AND
      INGACTFJO.NUMERO = NNUMERO AND
      INGACTFJO.MOTIVO_INGRESO = 'CMP' AND
      DECODE(PROVEEDOR_VARIO,'V','0',TO_CHAR(PRVACF.CODIGO)) NOT IN (SELECT CLAVE_RELACIONADA 
                                     FROM CUENTAS_ASOCIADAS 
                                     WHERE EMP_CODIGO = cEmpCod AND
                                           TIPO_DE_CUENTA = 'PAF' AND
                                           TIPO_DE_ASOCIACION = 'OBL');
--*****Cursores para validar la contabilización de Asiganciaciones de Suministros de Control*******
CURSOR SIN_CUENTA_SMN IS --Cursor de Suministros de Control sin cuenta asociada
SELECT TO_CHAR(GRPACT.CODIGO)||' '||SUBSTR(GRPACT.DESCRIPCION,1,40)
FROM GRUPOS_ACTIVOS_FIJOS GRPACT,
     DETALLES_aSIGNACIONES_REINGRES DTLASGRING,
     ACTIVOS_FIJOS_ESPECIFICOS AFJESP,
     ASIGNACIONES_REINGRESOS_ACTIVO ASGAFJ
WHERE GRPACT.EMP_CODIGO = cEmpCod AND      
      DTLASGRING.ASGRINACT_EMP_CODIGO = GRPACT.EMP_CODIGO AND
      DTLASGRING.ACTFSBGACTFJO_GRPACTFJO_CODIGO = GRPACT.CODIGO AND
      DTLASGRING.ASGRINACT_NUMERO = NNUMERO AND            
      DTLASGRING.ASGRINACT_TIPO_MOVIMIENTO = 'A' AND
      DTLASGRING.SBGACTFJO_GRPACTFJO_EMP_CODIGO = AFJESP.SBGACTFJO_GRPACTFJO_EMP_CODIGO AND
      DTLASGRING.ACTFSBGACTFJO_GRPACTFJO_CODIGO = AFJESP.ACTFSBGACTFJO_GRPACTFJO_CODIGO AND
      DTLASGRING.ACTFACTFJOGNR_SBGACTFJO_CODIGO = AFJESP.ACTFJOGNR_SBGACTFJO_CODIGO AND
      DTLASGRING.ACTFJOESP_ACTFJOGNR_CODIGO     = AFJESP.ACTFJOGNR_CODIGO AND
      DTLASGRING.ACTFJOESP_CODIGO               = AFJESP.CODIGO AND
      AFJESP.TIPO = 'S' AND
      AFJESP.CONTABILIZADO = 'F' AND 
      ASGAFJ.EMP_CODIGO = cEmpCod AND
      ASGAFJ.TIPO_MOVIMIENTO = DTLASGRING.ASGRINACT_TIPO_MOVIMIENTO AND
      ASGAFJ.NUMERO = DTLASGRING.ASGRINACT_NUMERO AND
      TO_CHAR(GRPACT.CODIGO)NOT IN (SELECT CLAVE_RELACIONADA
                                 FROM CUENTAS_ASOCIADAS
                                 WHERE EMP_CODIGO = cEmpCod AND
                                 TIPO_DE_CUENTA = 'AFJ' AND
                                 TIPO_DE_ASOCIACION = cTipoAsociacion);
--Cursor Para validar los porcentajes de distribución de los departamentos a los
-- diferentes Centros de Costos
CURSOR PORCENTAJE_MAYOR IS 
SELECT ARA_CODIGO||' '||CODIGO||' '||NOMBRE FROM DEPARTAMENTOS
WHERE 100 <(SELECT SUM(PORCENTAJE) 
            FROM DEPARTAMENTOS_CENTROS_COSTOS
            WHERE CNTCST_EMP_CODIGO = cEmpCod AND
                  DPR_ARA_CODIGO = ARA_CODIGO AND
                  DPR_CODIGO     = CODIGO);

CURSOR PORCENTAJE_MENOR IS 
SELECT ARA_CODIGO||' '||CODIGO||' '||NOMBRE FROM DEPARTAMENTOS
WHERE 100 >(SELECT SUM(PORCENTAJE) 
            FROM DEPARTAMENTOS_CENTROS_COSTOS
            WHERE CNTCST_EMP_CODIGO = cEmpCod AND
                  DPR_ARA_CODIGO = ARA_CODIGO AND
                  DPR_CODIGO     = CODIGO);

BEGIN
   vMensajeError:=NULL;
   IF cMovimiento = 'DPR' THEN    
-- Valida que todos los departamentos a los que se ha asignado un activo fijo,
-- esté asociado a un cetro de costo.
   vMensajeError:=NULL;
   FOR RDPR_SIN_CUENTA IN DPR_SIN_CUENTA LOOP
      vMensajeError := RDPR_SIN_CUENTA.CODIGO||' '||RDPR_SIN_CUENTA.NOMBRE||' ';
   END LOOP;   
   IF vMensajeError IS NOT NULL THEN
      QMS$ERRORS.SHOW_MESSAGE('CNT-01309',vMensajeError);    
   END IF;   
-- Valida que el porcentaje de distribución de gastos por departamento no sea mayor al 100%
      vMensajeError:=NULL;
      OPEN PORCENTAJE_MAYOR;
      LOOP
         FETCH PORCENTAJE_MAYOR INTO vDato;
         EXIT WHEN PORCENTAJE_MAYOR%NOTFOUND;
         vMensajeError:=vMensajeError||' '||vDato;
      END LOOP;
      CLOSE PORCENTAJE_MAYOR;
      IF vMensajeError IS NOT NULL THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01307',vMensajeError);    
      END IF;   
-- Valida que el porcentaje de distribución de gastos por departamento no sea menor al 100%
      vMensajeError:=NULL;
      OPEN PORCENTAJE_MENOR;
      LOOP
         FETCH PORCENTAJE_MENOR INTO vDato;
         EXIT WHEN PORCENTAJE_MENOR%NOTFOUND;
         vMensajeError:=vMensajeError||' '||vDato;
      END LOOP;
      CLOSE PORCENTAJE_MENOR;
      IF vMensajeError IS NOT NULL THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01308',vMensajeError);    
      END IF;   
   -- Valida que no existan grupos de Activos Fijos sin Cuenta de Depreciación Asociada
      OPEN SBG_DEPRECIACIONES;
      LOOP
         FETCH SBG_DEPRECIACIONES INTO vDato;
         EXIT WHEN SBG_DEPRECIACIONES%NOTFOUND;
         vMensajeError:=vMensajeError||' '||vDato;
      END LOOP;
      CLOSE SBG_DEPRECIACIONES;
      IF vMensajeError IS NOT NULL THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01302',vMensajeError);    
      END IF;
   -- Valida que no existan grupos de Activos Fijos sin Cuenta de Gastos
   -- por Depreciación Asociada
      vMensajeError:=NULL; 
      OPEN SBG_GASTOS_DPR;
      LOOP
         FETCH SBG_GASTOS_DPR INTO vDato;
         EXIT WHEN SBG_GASTOS_DPR%NOTFOUND;
         vMensajeError:=vMensajeError||' '||vDato;
      END LOOP;
      CLOSE SBG_GASTOS_DPR;
      IF vMensajeError IS NOT NULL THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01303',vMensajeError);    
      END IF;
   ELSIF cMovimiento = 'EGR' THEN    
   -- Valida que no existan subgrupos de Activos Fijos sin Cuenta de Gastos
   -- o Depreciaciones o de Activos Fijos
      vMensajeError:=NULL; 
      OPEN SIN_CUENTA_AFJGSTDEP;
      LOOP
         FETCH SIN_CUENTA_AFJGSTDEP INTO vDato;
         EXIT WHEN SIN_CUENTA_AFJGSTDEP%NOTFOUND;
         vMensajeError:=vMensajeError||' '||vDato;
      END LOOP;
      CLOSE SIN_CUENTA_AFJGSTDEP;
      IF vMensajeError IS NOT NULL THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01301',vMensajeError);    
      END IF;
      BEGIN
         SELECT CUENTA_CONTABLE INTO vCuenta
         FROM PARAMETROS_INTEGRACION 
         WHERE EMP_CODIGO=cEmpCod AND
               PARAMETRO='BJA' AND 
               TIPO='AFJ';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01304','Aporte Patrimonial o Gasto por Bajas');    
      END;  
   ELSIF cMovimiento = 'RGL' THEN
   -- Valida que no existan subgrupos de Activos Fijos sin Cuenta de
   -- Activos Fijos o Depreciaciones
      vMensajeError:=NULL; 
      OPEN SIN_CUENTA_AFJDEP;
      LOOP
         FETCH SIN_CUENTA_AFJDEP INTO vDato;
         EXIT WHEN SIN_CUENTA_AFJDEP%NOTFOUND;
         vMensajeError:=vMensajeError||' '||vDato;
      END LOOP;
      CLOSE SIN_CUENTA_AFJDEP;
      IF vMensajeError IS NOT NULL THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01301',vMensajeError);    
      END IF;
      BEGIN
         SELECT CUENTA_CONTABLE INTO vCuenta
         FROM PARAMETROS_INTEGRACION 
         WHERE EMP_CODIGO=cEmpCod AND
               PARAMETRO='REVPAT' AND 
               TIPO='AFJ';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01304','Revalorización de Patrimonio');    
      END;  
   ELSIF cMovimiento = 'ING' THEN    
      SELECT MOTIVO_INGRESO INTO vTipoIngreso 
      FROM INGRESOS_ACTIVOS_FIJOS
      WHERE NUMERO = NNUMERO;
      vMensajeError:=NULL; 
      BEGIN
         SELECT CUENTA_CONTABLE INTO vCuenta
         FROM PARAMETROS_INTEGRACION 
         WHERE EMP_CODIGO=cEmpCod AND
               PARAMETRO='SMNCNT' AND 
               TIPO='AFJ';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01304','Suministros');    
      END;
      OPEN SIN_CUENTA_AFJ;
      -- Valida que no existan subgrupos de Activos Fijos sin Cuenta de Activo Fijo
      LOOP
         FETCH SIN_CUENTA_AFJ INTO vDato;
         EXIT WHEN SIN_CUENTA_AFJ%NOTFOUND;
         vMensajeError:=vMensajeError||' '||vDato;
      END LOOP;
      CLOSE SIN_CUENTA_AFJ;
      IF vMensajeError IS NOT NULL THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01301',vMensajeError);    
      END IF;      
      IF vTipoIngreso IS NOT NULL AND vTipoIngreso = 'CMP' THEN
         OPEN SIN_OBLIGACION;
         -- Valida que el proveedor del ingreso de Activos Fijos tenga asociada una obligación 
         LOOP
            FETCH SIN_OBLIGACION INTO vDato;
            EXIT WHEN SIN_OBLIGACION%NOTFOUND;
            vMensajeError:=vMensajeError||' '||vDato;
         END LOOP;
         CLOSE SIN_OBLIGACION;
         IF vMensajeError IS NOT NULL THEN
            QMS$ERRORS.SHOW_MESSAGE('CNT-01305',vMensajeError);    
         END IF;   
      BEGIN
        SELECT PRMINT.CUENTA_CONTABLE INTO vCuenta
        FROM parametros_integracion prmint,cuentas_asociadas cntasc,VISTA_TIPOS_RETENCIONES vsttportn
        WHERE PRMINT.EMP_CODIGO = cEmpCod
        AND PRMINT.EMP_CODIGO = CNTASC.EMP_CODIGO 
        AND PRMINT.CUENTA_CONTABLE = CNTASC.CUENTA
        AND CNTASC.CLAVE_RELACIONADA=CNTASC.EMP_CODIGO||TO_CHAR(TPORTN_CODIGO)
        AND PRMINT.TIPO='PAF' 
        AND PRMINT.PARAMETRO='RET1'; 
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01403','Retención en la Fuente');    
      END;   
      BEGIN
        SELECT PRMINT.CUENTA_CONTABLE INTO vCuenta
        FROM parametros_integracion prmint,cuentas_asociadas cntasc,VISTA_TIPOS_RETENCIONES vsttportn
        WHERE PRMINT.EMP_CODIGO = cEmpCod
        AND PRMINT.EMP_CODIGO = CNTASC.EMP_CODIGO
        AND PRMINT.CUENTA_CONTABLE = CNTASC.CUENTA
        AND CNTASC.CLAVE_RELACIONADA=CNTASC.EMP_CODIGO||TO_CHAR(TPORTN_CODIGO)
        AND PRMINT.TIPO='PAF'
        AND PRMINT.PARAMETRO='IVA30'; 
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01403','Retención del I.V.A');    
      END;     
      END IF;
   ELSIF cMovimiento = 'ASG' THEN    
   -- Valida que en el ingreso no existan suministros de Control sin
   -- cuenta de gastos asociada
-- Valida que el porcentaje de distribución de gastos por departamento no sea mayor al 100%
      vMensajeError:=NULL;
      OPEN PORCENTAJE_MAYOR;
      LOOP
         FETCH PORCENTAJE_MAYOR INTO vDato;
         EXIT WHEN PORCENTAJE_MAYOR%NOTFOUND;
         vMensajeError:=vMensajeError||' '||vDato;
      END LOOP;
      CLOSE PORCENTAJE_MAYOR;
      IF vMensajeError IS NOT NULL THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01307',vMensajeError);    
      END IF;   
-- Valida que el porcentaje de distribución de gastos por departamento no sea menor al 100%
      vMensajeError:=NULL;
      OPEN PORCENTAJE_MENOR;
      LOOP
         FETCH PORCENTAJE_MENOR INTO vDato;
         EXIT WHEN PORCENTAJE_MENOR%NOTFOUND;
         vMensajeError:=vMensajeError||' '||vDato;
      END LOOP;
      CLOSE PORCENTAJE_MENOR;
      IF vMensajeError IS NOT NULL THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01308',vMensajeError);    
      END IF;   
      vMensajeError:=NULL; 
      OPEN SIN_CUENTA_SMN;
      LOOP
         FETCH SIN_CUENTA_SMN INTO vDato;
         EXIT WHEN SIN_CUENTA_SMN%NOTFOUND;
         vMensajeError:=vMensajeError||' '||vDato;
      END LOOP;
      CLOSE SIN_CUENTA_SMN;
      IF vMensajeError IS NOT NULL THEN
         QMS$ERRORS.SHOW_MESSAGE('CNT-01306',vMensajeError);    
      END IF;
   END IF;
EXCEPTION
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo en el procedimiento VALIDAR_CONTABILIZAR_AF por error '||SQLERRM);
END;
/* Crea un comprobante Contable por la Regulación de Act. Fijos */
PROCEDURE CONTABILIZAR_REGULACION_AFJ
 (NTIPOCAMBIO IN number
 ,NTIPOCAMBIOE IN NUMBER
 ,VMONEDALOCAL IN VARCHAR2
 ,CEMPCOD IN VARCHAR2
 ,CTPOCMP IN VARCHAR2
 ,DFECHACMP IN DATE
 ,NCLAVE OUT NUMBER
 ,NNUMERO IN NUMBER
 ,CTIPO IN VARCHAR2
 )
 IS

I NUMBER;
J NUMBER;
NCUADREH NUMBER(21, 6) := 0;
MES_DEPRECIADO VARCHAR2(10);
NNUMING NUMBER := 1;
CNOMBRE_SEC VARCHAR2(40);
VDESCING VARCHAR2(1000);
NCUADRED NUMBER(21, 6) := 0;
NDIFCUADRE NUMBER(21, 6) := 0;
--Este proceso crea un Comprobante Contable para una Regulación de Activos
--Fijos. Antes de proceder a contabilizar se valida que los datos necesarios para 
--realizar el proceso estén correctos, esto lo hacemos en el proceso VALIDAR_CONTABILIZACION_AFJ
BEGIN
DECLARE
CURSOR cMesCerrado IS
  SELECT COUNT(*)
    FROM CIERRES_DE_MES
    WHERE TRUNC(MES,'MM')=TRUNC(dFechaCmp,'MM')
      AND  ESTADO='C';
CURSOR cActivos_Fijos IS --(Debe o Haber segun el caso) Cursor de Activos Fijos
SELECT EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,VALOR
FROM REGULACIONES_AFJ
WHERE EMP_CODIGO = cEmpCod AND
      NUMERO = NNUMERO AND
      VALOR >0;
CURSOR cDepreciaciones IS --(Debe o Haber segun el caso) Cursor de Depreciaciones
SELECT EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
    SAXL2_CODIGO,SAXL3_CODIGO,VALOR
FROM DEPRECIACIONES_AFJ
WHERE EMP_CODIGO = cEmpCod AND      
      REFERENCIA = NNUMERO AND
      VALOR > 0;
CURSOR cReval_Patrimonio IS --(Debe o Haber según el caso) Parámetro de Integración
  SELECT PRMINT.CUENTA_CONTABLE,
         PLNCNT.EMP_CODIGO EMP_CODIGO, PLNCNT.MYR_CODIGO
         MYR_CODIGO, PLNCNT.CNT_CODIGO CNT_CODIGO, PLNCNT.SCNT_CODIGO SCNT_CODIGO,
         PLNCNT.AXL_CODIGO AXL_CODIGO, PLNCNT.SAXL_CODIGO SAXL_CODIGO,
         PLNCNT.SAXL2_CODIGO SAXL2_CODIGO, PLNCNT.SAXL3_CODIGO SAXL3_CODIGO
  FROM PARAMETROS_INTEGRACION PRMINT,PLAN_DE_CUENTAS PLNCNT
  WHERE PRMINT.EMP_CODIGO=cEmpCod
    AND PRMINT.PARAMETRO='REVPAT'
    AND PRMINT.TIPO='AFJ'
    AND PRMINT.CUENTA_CONTABLE=PLNCNT.CODIGO (+);
TYPE tMovCnt  IS TABLE OF MOVIMIENTOS%ROWTYPE INDEX BY BINARY_INTEGER;
rMovCnt tMovCnt; -- Tabla en donde se guardan los datos antes de Contabilizar
nContMesCerrado NUMBER:=0;-- Devuelve 1 si el mes esta cerrado caso contrario 0
BEGIN
BEGIN
  SELECT NOMBRE_SECUENCIA INTO cNOMBRE_SEC
  FROM TIPOS_COMPROBANTES_EMPRESAS
  WHERE EMP_CODIGO = cEmpCod AND
        TPOCMP_CODIGO = cTpoCmp;
  GNRL.ACTUALIZA_SECUENCIA(cNOMBRE_SEC,nClave);
-- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  OPEN cMesCerrado;
  FETCH cMesCerrado INTO nContMesCerrado;
  IF nContMesCerrado>0 THEN
-- Error no se puede contabilizar para un mes cerrado
      QMS$ERRORS.SHOW_MESSAGE('CNT-00046');-- No se puede crear un comprobante de un mes ya cerrado
  END IF;
  VALIDAR_CONTABILIZACION_AF(cEmpCod,'RGL',NNUMERO,'DAF',NULL);   
  VALIDAR_CONTABILIZACION_AF(cEmpCod,'RGL',NNUMERO,'CAF',NULL);   
  -- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  BEGIN
     vDescIng:='Contabilización de Regulación de Activos Fijos Número '||TO_CHAR(NNUMERO);
     INSERT INTO COMPROBANTES (TPOCMPEMP_EMP_CODIGO,TPOCMPEMP_TPOCMP_CODIGO,FECHA,CLAVE,
                               MAYORIZADO,ESTADO,TOTAL,MONEDA_LOCAL,TIPO_DE_CAMBIO,TIPO_DE_CAMBIOE,
                               CONCEPTO,CRRMES_MES,CONTABILIZADO_DESDE)
     VALUES (cEmpCod,cTpoCmp,dFechaCmp,nClave,'F','N',0,vMonedaLocal,nTipoCambio,nTipoCambioE,vDescIng,NULL,'ACF'); 
  EXCEPTION 
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo la inserción del Comprobante por error '||SQLERRM);  
  END;
  i:=1;
  j:=0; 
  nCuadreD:=0;
  -- Dependiendo del tipo de Regulación de Activos Fijos Fijamos el Debe
  IF cTipo = 'REV' THEN
     FOR rActivos_Fijos IN cActivos_Fijos LOOP    
       rMovCnt(i).SECUENCIA:=101;
       rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(i).CMP_FECHA:=dFechaCmp;
       rMovCnt(i).CMP_CLAVE:=nClave;
       rMovCnt(i).DEBE:=ROUND(rActivos_Fijos.VALOR,2);
       rMovCnt(i).DEBEE:=ROUND(rActivos_Fijos.VALOR,2)*nTipoCambioE;
       rMovCnt(i).HABER:=0;
       rMovCnt(i).HABERE:=0;
       rMovCnt(i).FECHA:=dFechaCmp;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rActivos_Fijos.EMP_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rActivos_Fijos.MYR_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rActivos_Fijos.CNT_CODIGO;
       rMovCnt(i).SS_S_A_SC_CODIGO:=rActivos_Fijos.SCNT_CODIGO;
       rMovCnt(i).SS_S_A_CODIGO:=rActivos_Fijos.AXL_CODIGO;
       rMovCnt(i).SS_S_CODIGO:=rActivos_Fijos.SAXL_CODIGO;
       rMovCnt(i).SS_CODIGO:=rActivos_Fijos.SAXL2_CODIGO;
       rMovCnt(i).S_CODIGO:=rActivos_Fijos.SAXL3_CODIGO;
       rMovCnt(i).DESCRIPCION:='Activo Fijo Regulado';
       rMovCnt(i).ASOCIACION:=NULL;
       nCuadreD:=nCuadreD+rMovCnt(i).DEBE;
       i:=i+1;
     END LOOP;
  ELSIF cTipo = 'DEV' THEN
     FOR rDepreciaciones IN cDepreciaciones LOOP    
       rMovCnt(i).SECUENCIA:=101;
       rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(i).CMP_FECHA:=dFechaCmp;
       rMovCnt(i).CMP_CLAVE:=nClave;
       rMovCnt(i).DEBE:=ROUND(rDepreciaciones.VALOR,2);
       rMovCnt(i).DEBEE:=ROUND(rDepreciaciones.VALOR,2)*nTipoCambioE;
       rMovCnt(i).HABER:=0;
       rMovCnt(i).HABERE:=0;
       rMovCnt(i).FECHA:=dFechaCmp;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rDepreciaciones.EMP_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rDepreciaciones.MYR_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rDepreciaciones.CNT_CODIGO;
       rMovCnt(i).SS_S_A_SC_CODIGO:=rDepreciaciones.SCNT_CODIGO;
       rMovCnt(i).SS_S_A_CODIGO:=rDepreciaciones.AXL_CODIGO;
       rMovCnt(i).SS_S_CODIGO:=rDepreciaciones.SAXL_CODIGO;
       rMovCnt(i).SS_CODIGO:=rDepreciaciones.SAXL2_CODIGO;
       rMovCnt(i).S_CODIGO:=rDepreciaciones.SAXL3_CODIGO;
       rMovCnt(i).DESCRIPCION:='Depreciación Acumulada del activo fijo regulado';
       rMovCnt(i).ASOCIACION:=NULL;
       nCuadreD:=nCuadreD+rMovCnt(i).DEBE;
       i:=i+1;
     END LOOP;
     j:= i;
  END IF;  
-- Dependiendo del tipo de Regulación de Activos Fijos Fijamos el Haber
  ncuadreH:=0;
  IF cTipo = 'REV' THEN
     FOR rDepreciaciones IN cDepreciaciones LOOP    
       rMovCnt(i).SECUENCIA:=201;
       rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(i).CMP_FECHA:=dFechaCmp;
       rMovCnt(i).CMP_CLAVE:=nClave;
       rMovCnt(i).DEBE:=0;
       rMovCnt(i).DEBEE:=0;
       rMovCnt(i).HABER:=ROUND(rDepreciaciones.VALOR,2);
       rMovCnt(i).HABERE:=ROUND(rDepreciaciones.VALOR,2)*nTipoCambioE;
       rMovCnt(i).FECHA:=dFechaCmp;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rDepreciaciones.EMP_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rDepreciaciones.MYR_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rDepreciaciones.CNT_CODIGO;
       rMovCnt(i).SS_S_A_SC_CODIGO:=rDepreciaciones.SCNT_CODIGO;
       rMovCnt(i).SS_S_A_CODIGO:=rDepreciaciones.AXL_CODIGO;
       rMovCnt(i).SS_S_CODIGO:=rDepreciaciones.SAXL_CODIGO;
       rMovCnt(i).SS_CODIGO:=rDepreciaciones.SAXL2_CODIGO;
       rMovCnt(i).S_CODIGO:=rDepreciaciones.SAXL3_CODIGO;
       rMovCnt(i).DESCRIPCION:='Depreciación Acumulada del activo fijo regulado';
       rMovCnt(i).ASOCIACION:=NULL;
       nCuadreH:=nCuadreH+rMovCnt(i).HABER;
       i:=i+1;
     END LOOP;
  ELSIF cTipo = 'DEV' THEN
     i:=i+1;
     FOR rActivos_Fijos IN cActivos_Fijos LOOP    
       rMovCnt(i).SECUENCIA:=201;
       rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(i).CMP_FECHA:=dFechaCmp;
       rMovCnt(i).CMP_CLAVE:=nClave;
       rMovCnt(i).DEBE:=0;
       rMovCnt(i).DEBEE:=0;
       rMovCnt(i).HABER:=ROUND(rActivos_Fijos.VALOR,2);
       rMovCnt(i).HABERE:=ROUND(rActivos_Fijos.VALOR,2)*nTipoCambioE;
       rMovCnt(i).FECHA:=dFechaCmp;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rActivos_Fijos.EMP_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rActivos_Fijos.MYR_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rActivos_Fijos.CNT_CODIGO;
       rMovCnt(i).SS_S_A_SC_CODIGO:=rActivos_Fijos.SCNT_CODIGO;
       rMovCnt(i).SS_S_A_CODIGO:=rActivos_Fijos.AXL_CODIGO;
       rMovCnt(i).SS_S_CODIGO:=rActivos_Fijos.SAXL_CODIGO;
       rMovCnt(i).SS_CODIGO:=rActivos_Fijos.SAXL2_CODIGO;
       rMovCnt(i).S_CODIGO:=rActivos_Fijos.SAXL3_CODIGO;
       rMovCnt(i).DESCRIPCION:='Activo Fijo Regulado';
       rMovCnt(i).ASOCIACION:=NULL;
       nCuadreH:=nCuadreH+rMovCnt(i).HABER;
       i:=i+1;
     END LOOP;
  END IF;
  IF cTipo = 'REV' THEN
     nDifCuadre:=nCuadreD-nCuadreH;
  ELSIF cTipo = 'DEV'THEN
     nDifCuadre:=nCuadreH-nCuadreD;
  END IF;   
  IF nDifCuadre > 0 THEN -- Si hay diferencia presenta un error
     IF cTipo = 'REV' THEN
        FOR rReval_Patrimonio IN cReval_Patrimonio LOOP
          rMovCnt(i).SECUENCIA:=202;
          rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
          rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
          rMovCnt(i).CMP_FECHA:=dFechaCmp;
          rMovCnt(i).CMP_CLAVE:=nClave;
          rMovCnt(i).DEBE:=0;
          rMovCnt(i).DEBEE:=0;
          rMovCnt(i).HABER:=ROUND(nDifCuadre,2);
          rMovCnt(i).HABERE:=ROUND(nDifCuadre,2)*nTipoCambioE;
          rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rReval_Patrimonio.EMP_CODIGO;
          rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rReval_Patrimonio.MYR_CODIGO;
          rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rReval_Patrimonio.CNT_CODIGO;
          rMovCnt(i).SS_S_A_SC_CODIGO:=rReval_Patrimonio.SCNT_CODIGO;
          rMovCnt(i).SS_S_A_CODIGO:=rReval_Patrimonio.AXL_CODIGO;
          rMovCnt(i).SS_S_CODIGO:=rReval_Patrimonio.SAXL_CODIGO;
          rMovCnt(i).SS_CODIGO:=rReval_Patrimonio.SAXL2_CODIGO;
          rMovCnt(i).S_CODIGO:=rReval_Patrimonio.SAXL3_CODIGO;
          rMovCnt(i).DESCRIPCION:='Revalorización de Patrimonio';
          rMovCnt(i).ASOCIACION:=NULL;         
        END LOOP;
     ELSIF cTipo = 'DEV' THEN
        FOR rReval_Patrimonio IN cReval_Patrimonio LOOP
          rMovCnt(j).SECUENCIA:=102;
          rMovCnt(j).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
          rMovCnt(j).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
          rMovCnt(j).CMP_FECHA:=dFechaCmp;
          rMovCnt(j).CMP_CLAVE:=nClave;
          rMovCnt(j).DEBE:=ROUND(nDifCuadre,2);
          rMovCnt(j).DEBEE:=ROUND(nDifCuadre,2)*nTipoCambioE;
          rMovCnt(j).HABER:=0;
          rMovCnt(j).HABERE:=0;
          rMovCnt(j).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rReval_Patrimonio.EMP_CODIGO;
          rMovCnt(j).SS_S_A_SC_CNT_MYR_CODIGO:=rReval_Patrimonio.MYR_CODIGO;
          rMovCnt(j).SS_S_A_SC_CNT_CODIGO:=rReval_Patrimonio.CNT_CODIGO;
          rMovCnt(j).SS_S_A_SC_CODIGO:=rReval_Patrimonio.SCNT_CODIGO;
          rMovCnt(j).SS_S_A_CODIGO:=rReval_Patrimonio.AXL_CODIGO;
          rMovCnt(j).SS_S_CODIGO:=rReval_Patrimonio.SAXL_CODIGO;
          rMovCnt(j).SS_CODIGO:=rReval_Patrimonio.SAXL2_CODIGO;
          rMovCnt(j).S_CODIGO:=rReval_Patrimonio.SAXL3_CODIGO;
          rMovCnt(j).DESCRIPCION:='Revalorización de Patrimonio';
          rMovCnt(j).ASOCIACION:=NULL;   
        END LOOP;
    END IF;
  ELSE
     QMS$ERRORS.SHOW_MESSAGE('CNT-01107');
  END IF;
-- AHORA SI NO HA HABIDO NINGUN ERROR CREAMOS LOS DETALLES DEL COMPROBANTE
  FOR I IN 1..rMovCnt.COUNT LOOP
    IF (rMovCnt(I).DEBE=0 AND rMovCnt(I).HABER=0) OR (rMovCnt(I).DEBE>0 AND rMovCnt(I).HABER>0) THEN
      QMS$ERRORS.SHOW_MESSAGE('ADM-00009',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||
                                          rMovCnt(I).SS_S_A_SC_CNT_CODIGO||rMovCnt(I).SS_S_A_SC_CODIGO||
                                          rMovCnt(I).SS_S_A_CODIGO||rMovCnt(I).SS_S_CODIGO||rMovCnt(I).SS_CODIGO||
                                          rMovCnt(I).S_CODIGO||' '||rMovCnt(I).DESCRIPCION||' ** DEBE ** '||
                                          rMovCnt(I).DEBE||' ** HABER **'||rMovCnt(I).HABER,'Comuniquese con Softcase');
    END IF;
    INSERT INTO MOVIMIENTOS (MVM_ID,CMP_TPOCMPEMP_EMP_CODIGO,CMP_TPOCMPEMP_TPOCMP_CODIGO,
  	    CMP_FECHA,CMP_CLAVE,FECHA,SECUENCIA,DEBE,HABER,DEBEE,HABERE,MONEDA,TIPO_DE_CAMBIO,MAYORIZADO,
  	    SS_S_A_SC_CNT_MYR_EMP_CODIGO,SS_S_A_SC_CNT_MYR_CODIGO,SS_S_A_SC_CNT_CODIGO,
  	    SS_S_A_SC_CODIGO,SS_S_A_CODIGO,SS_S_CODIGO,SS_CODIGO,S_CODIGO,
          DESCRIPCION,ASOCIACION,ESTADO_MOVIMIENTO,OBL_OBL_ID)
    VALUES (MVM_SEQ.NEXTVAL,cEmpCod,cTpoCmp,dFechaCmp,nClave,dFechaCmp,rMovCnt(I).SECUENCIA,
      	rMovCnt(I).DEBE,rMovCnt(I).HABER,rMovCnt(I).DEBEE,rMovCnt(I).HABERE,
            vMonedaLocal,nTipoCambio,'F',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO,
            rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO,rMovCnt(I).SS_S_A_SC_CNT_CODIGO,
  	      rMovCnt(I).SS_S_A_SC_CODIGO,rMovCnt(I).SS_S_A_CODIGO,rMovCnt(I).SS_S_CODIGO,
            rMovCnt(I).SS_CODIGO,rMovCnt(I).S_CODIGO,
  	      rMovCnt(I).DESCRIPCION,rMovCnt(I).ASOCIACION,'N',NULL);
           QMS$ERRORS.SHOW_DEBUG_INFO(rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||
                               rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||
                               rMovCnt(I).SS_S_A_SC_CNT_CODIGO||
                               rMovCnt(I).SS_S_A_SC_CODIGO||
                               rMovCnt(I).SS_S_A_CODIGO||
                               rMovCnt(I).SS_S_CODIGO||
                               rMovCnt(I).SS_CODIGO||
                               rMovCnt(I).S_CODIGO||
                               rMovCnt(I).DESCRIPCION||' '||
                               TO_CHAR(rMovCnt(I).DEBE)||' '||
                               TO_CHAR(rMovCnt(I).HABER)); 
  END LOOP;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
   -- FALLA SI NO ENCUENTRA LA SECUENCIA DEL COMPROBANTE
   QMS$ERRORS.SHOW_MESSAGE('CNT-01408',cTpoCmp);
END;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
-- FALLA SI YA EXISTE UN COMPROBANTE IGUAL (CABECERA)
    QMS$ERRORS.SHOW_MESSAGE('CNT-01010',cTpoCmp||'-'||TO_CHAR(dFechaCmp,'DD/MM/YYYY')||'-'||TO_CHAR(nClave));
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo en el procedimiento CONTABILIZAR_REGULACION_AFJ por error '||SQLERRM);
END;
END;
/* Crea un comprobante Contable por el Rol de Pagos */
PROCEDURE CONTABILIZAR_ROL_DE_PAGOS
 (NTIPOCAMBIO IN number
 ,NTIPOCAMBIOE IN NUMBER
 ,VMONEDALOCAL IN VARCHAR2
 ,CEMPCOD IN VARCHAR2
 ,CTPOCMP IN VARCHAR2
 ,DFECHACMP IN DATE
 ,NCLAVE IN OUT NUMBER
 ,NNUMERO IN NUMBER
 ,DFECHADESDE IN DATE
 ,DFECHAHASTA IN DATE
 ,CCNTPRS IN VARCHAR2 := 'F'
 )
 IS

VCTASUELDOSXPAGAR PARAMETROS_INTEGRACION.CUENTA_CONTABLE%TYPE;
I NUMBER;
NCUADREH NUMBER(21, 6) := 0;
J NUMBER := 0;
K NUMBER := 0;
NNUMING NUMBER := 1;
VDESCING VARCHAR2(1000);
CNOMBRE_SEQ VARCHAR2(100);
NCUADRED NUMBER(21, 6) := 0;
NDIFCUADRE NUMBER(21, 6) := 0;
--Este proceso crea un Comprobante Contable para el Rol de Pagos emitido
--desde el Sistema de Rol de Pagos. Antes de proceder a contabilizar el 
--Rol, se valida que los datos necesarios para realizar el proceso estén
--correctos, esto lo hacemos en el proceso VALIDAR_CONTABILIZACION_ROL
BEGIN
DECLARE
CURSOR cMesCerrado IS
  SELECT COUNT(*)
    FROM CIERRES_DE_MES
    WHERE TRUNC(MES,'MM')=TRUNC(dFechaCmp,'MM')
      AND  ESTADO='C';
CURSOR cSueldosxPagar IS
SELECT CG.RV_MEANING EMPRESA,
       SUBSTR(PRMINT.PARAMETRO,4,3) PARAMETRO,
       PRMINT.CUENTA_CONTABLE,
       PLNCNT.EMP_CODIGO EMP_CODIGO, PLNCNT.MYR_CODIGO
       MYR_CODIGO, PLNCNT.CNT_CODIGO CNT_CODIGO, PLNCNT.SCNT_CODIGO SCNT_CODIGO,
       PLNCNT.AXL_CODIGO AXL_CODIGO, PLNCNT.SAXL_CODIGO SAXL_CODIGO,
       PLNCNT.SAXL2_CODIGO SAXL2_CODIGO, PLNCNT.SAXL3_CODIGO SAXL3_CODIGO
FROM CG_REF_CODES CG,PARAMETROS_INTEGRACION PRMINT,
     PLAN_DE_CUENTAS PLNCNT
WHERE CG.RV_LOW_VALUE = SUBSTR(PRMINT.PARAMETRO,4,3) 
  AND CG.RV_DOMAIN = 'TERCERIZADORA' 
  AND PRMINT.EMP_CODIGO=cEmpCod 
  AND PRMINT.TIPO='RDP'
  AND PRMINT.CUENTA_CONTABLE=PLNCNT.CODIGO (+)
ORDER BY 1,2;

TYPE tMovCnt  IS TABLE OF MOVIMIENTOS%ROWTYPE INDEX BY BINARY_INTEGER;
rMovCnt tMovCnt; -- Tabla en donde se guardan los datos antes de Contabilizar
nContMesCerrado NUMBER:=0;-- Devuelve 1 si el mes esta cerrado caso contrario 0

CURSOR cGasto_Presupuesto IS --(Debe) Cursor de cuentas de Gasto Presupuestario
SELECT EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
       SAXL2_CODIGO,SAXL3_CODIGO,PRM_NOMBRE,DEBE
FROM AFECTACION_PRESUPUESTO_ROL 
WHERE EMP_CODIGO = cEmpCod AND      
      NUMERO = nNumero AND  
     (FECHA BETWEEN dFechaDesde AND dFechaHasta) ;
     
CURSOR cIngreso_Presupuesto IS --(Haber) Cursor de cuentas de Gasto Presupuestario
SELECT EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
       SAXL2_CODIGO,SAXL3_CODIGO,PRM_NOMBRE,HABER
FROM AFECTACION_PRESUPUESTO_ROL 
WHERE EMP_CODIGO = cEmpCod AND 
      NUMERO = nNumero AND
      (FECHA BETWEEN dFechaDesde AND dFechaHasta);
BEGIN
  OPEN cMesCerrado;
  FETCH cMesCerrado INTO nContMesCerrado;
  IF nContMesCerrado>0 THEN
-- Error no se puede contabilizar para un mes cerrado
      QMS$ERRORS.SHOW_MESSAGE('CNT-00046');-- No se puede crear un comprobante de un mes ya cerrado
  END IF;
  IF nClave IS NULL THEN
     SELECT NOMBRE_SECUENCIA INTO cNOMBRE_SEC
     FROM TIPOS_COMPROBANTES_EMPRESAS
     WHERE EMP_CODIGO = cEmpCod AND
           TPOCMP_CODIGO = cTpoCmp;
     GNRL.ACTUALIZA_SECUENCIA(cNOMBRE_SEC,nClave);
  END IF;
  VALIDAR_CONTABILIZACION_ROL(cEmpCod,nNumero,dFechaDesde,dFechaHasta);   
  -- PRIMERO CREAMOS LA CABECERA PARA VER QUE NO EXISTE UN COMPROBANTE IGUAL
  BEGIN
     vDescIng:='Pago de Sueldos desde '||TO_CHAR(dFechaDesde,'DD/MM/YYYY HH24:MI')||' hasta '||
               TO_CHAR(dFechaHasta,'DD/MM/YYYY HH24:MI');

     INSERT INTO COMPROBANTES (TPOCMPEMP_EMP_CODIGO,TPOCMPEMP_TPOCMP_CODIGO,FECHA,CLAVE,
                               MAYORIZADO,ESTADO,TOTAL,MONEDA_LOCAL,TIPO_DE_CAMBIO,TIPO_DE_CAMBIOE,
                               CONCEPTO,CRRMES_MES,CONTABILIZADO_DESDE)
     VALUES (cEmpCod,cTpoCmp,dFechaCmp,nClave,'F','N',0,vMonedaLocal,nTipoCambio,nTipoCambioE,vDescIng,NULL,'RDP'); 
  EXCEPTION 
  WHEN OTHERS THEN
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo la inserción del Comprobante por error '||SQLERRM);  
  END;
  i:=1; -- indice de movimientos contables para gasto y pasivo
  j:=0; -- indice para sueldos por pagar
  k:=0; -- secuencia de los movimientos
  FOR rSueldosxPagar IN cSueldosxPagar LOOP
  k:= k+1;
  nCuadreD:=0;
  nCuadreH:=0;
  BEGIN
     DECLARE CURSOR cGastosRoles IS --(Debe) Cursor de Gastos por Roles de Pagos
             SELECT EMP_CODIGO,SUBSTR(RV_MEANING,1,20) DESCRIPCION,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,AXL_CODIGO,SAXL_CODIGO,
             SAXL2_CODIGO,SAXL3_CODIGO,VALOR
             FROM GASTOS_ROLES_DE_PAGOS ,CG_REF_CODES
             WHERE EMP_CODIGO = cEmpCod AND
                  NUMERO = nNumero AND
                  (FECHA BETWEEN dFechaDesde AND dFechaHasta) AND
                  RV_DOMAIN = 'AGRUPADOR COSTOS GENERAL' AND
                  AGRUPADOR_TIPO = RV_LOW_VALUE AND
                  TERCERIZADORA = rSueldosxPagar.PARAMETRO
             ORDER BY 1; 
             CURSOR cPasivosRoles IS --(Haber) Cursor de Pasivos por Roles de Pagos
             SELECT EMP_CODIGO,MYR_CODIGO,CNT_CODIGO,SCNT_CODIGO,
                    AXL_CODIGO,SAXL_CODIGO,SAXL2_CODIGO,SAXL3_CODIGO,PRMROL_NOMBRE,VALOR
             FROM PASIVOS_ROLES_DE_PAGOS 
             WHERE EMP_CODIGO = cEmpCod AND
                   NUMERO = nNumero AND               
                   PRMROL_TIPO <> 'E' AND
                   TERCERIZADORA = rSueldosxPagar.PARAMETRO AND
                   (FECHA BETWEEN dFechaDesde AND dFechaHasta);
     BEGIN
     FOR rGastosRoles IN cGastosRoles LOOP -- Por cada tercerizadora crear movimientos de gasto,pasivo y sueldo por pagar
       -- FIJAMOS EL DEBE
--       IF i>1 THEN
--          IF rMovCnt(i-1).DESCRIPCION <> rGastosRoles.DESCRIPCION||'de '||TO_CHAR(dFechaHasta,'MONTH/YYYY')||rSueldosxPagar.EMPRESA THEN
--             nNumIng:= nNumIng+1;
--          END IF;
--       END IF;
--       rMovCnt(i).SECUENCIA:=100+nNumIng;
       rMovCnt(i).SECUENCIA:=k;
       rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(i).CMP_FECHA:=dFechaCmp;
       rMovCnt(i).CMP_CLAVE:=nClave;
       rMovCnt(i).DEBE:=ROUND(rGastosRoles.VALOR,2);
       rMovCnt(i).DEBEE:=ROUND(rGastosRoles.VALOR,2)*nTipoCambioE;
       rMovCnt(i).HABER:=0;
       rMovCnt(i).HABERE:=0;
       rMovCnt(i).FECHA:=dFechaCmp;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rGastosRoles.EMP_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rGastosRoles.MYR_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rGastosRoles.CNT_CODIGO;
       rMovCnt(i).SS_S_A_SC_CODIGO:=rGastosRoles.SCNT_CODIGO;
       rMovCnt(i).SS_S_A_CODIGO:=rGastosRoles.AXL_CODIGO;
       rMovCnt(i).SS_S_CODIGO:=rGastosRoles.SAXL_CODIGO;
       rMovCnt(i).SS_CODIGO:=rGastosRoles.SAXL2_CODIGO;
       rMovCnt(i).S_CODIGO:=rGastosRoles.SAXL3_CODIGO;
       rMovCnt(i).DESCRIPCION:=rGastosRoles.DESCRIPCION||'de '||TO_CHAR(dFechaHasta,'MONTH/YYYY')||rSueldosxPagar.EMPRESA;
       rMovCnt(i).ASOCIACION:=NULL;
       rMovCnt(i).COMPROMISO:= 'F';
       rMovCnt(i).OBLIGACION:='F';
       rMovCnt(i).PAGO := 'F';  
       rMovCnt(i).AJUSTE_PRESUPUESTARIO := 'F';
       nCuadreD:=nCuadreD+rMovCnt(i).DEBE;
       i:=i+1;
     END LOOP;
     IF nCuadreD > 0 THEN
        j:= i; --Posición para crear el movimiento por la diferencia del Debe y Haber
        i:= i+1;
     END IF;
     ncuadreH:=0;
     FOR rPasivosRoles IN cPasivosRoles LOOP
     -- FIJAMOS EL HABER
       rMovCnt(i).SECUENCIA:=k;
       rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(i).CMP_FECHA:=dFechaCmp;
       rMovCnt(i).CMP_CLAVE:=nClave;
       rMovCnt(i).DEBE:=0;
       rMovCnt(i).DEBEE:=0;
       rMovCnt(i).HABER:=ROUND(rPasivosRoles.VALOR,2);
       rMovCnt(i).HABERE:=ROUND(rPasivosRoles.VALOR,2)*nTipoCambioE;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rPasivosRoles.EMP_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rPasivosRoles.MYR_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rPasivosRoles.CNT_CODIGO;
       rMovCnt(i).SS_S_A_SC_CODIGO:=rPasivosRoles.SCNT_CODIGO;
       rMovCnt(i).SS_S_A_CODIGO:=rPasivosRoles.AXL_CODIGO;
       rMovCnt(i).SS_S_CODIGO:=rPasivosRoles.SAXL_CODIGO;
       rMovCnt(i).SS_CODIGO:=rPasivosRoles.SAXL2_CODIGO;
       rMovCnt(i).S_CODIGO:=rPasivosRoles.SAXL3_CODIGO;
       rMovCnt(i).DESCRIPCION:= rPasivosRoles.PRMROL_NOMBRE||'DESCUENTOS DE' ||TO_CHAR(dFechaHasta,'MONTH/YYYY');
       rMovCnt(i).ASOCIACION:=NULL;
       rMovCnt(i).COMPROMISO:= 'F';
       rMovCnt(i).OBLIGACION:='F';
       rMovCnt(i).PAGO := 'F';  
       rMovCnt(i).AJUSTE_PRESUPUESTARIO := 'F';
       nCuadreH:=nCuadreH+rMovCnt(i).HABER;
       i:=i+1;
     END LOOP;
     nDifCuadre:=nCuadreD-nCuadreH; -- Valor de sueldos por Pagar
     IF nDifCuadre>0 THEN -- La diferencia se carga a la cuenta Sueldo Por Pagar
       rMovCnt(j).SECUENCIA:=k;
       rMovCnt(j).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(j).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(j).CMP_FECHA:=dFechaCmp;
       rMovCnt(j).CMP_CLAVE:=nClave;
       rMovCnt(j).DEBE:=0;
       rMovCnt(j).DEBEE:=0;
       rMovCnt(j).HABER:=ROUND(nDifCuadre,2);
       rMovCnt(j).HABERE:=ROUND(nDifCuadre,2)*nTipoCambioE;
       rMovCnt(j).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rSueldosxPagar.EMP_CODIGO;
       rMovCnt(j).SS_S_A_SC_CNT_MYR_CODIGO:=rSueldosxPagar.MYR_CODIGO;
       rMovCnt(j).SS_S_A_SC_CNT_CODIGO:=rSueldosxPagar.CNT_CODIGO;
       rMovCnt(j).SS_S_A_SC_CODIGO:=rSueldosxPagar.SCNT_CODIGO;
       rMovCnt(j).SS_S_A_CODIGO:=rSueldosxPagar.AXL_CODIGO;
       rMovCnt(j).SS_S_CODIGO:=rSueldosxPagar.SAXL_CODIGO;
       rMovCnt(j).SS_CODIGO:=rSueldosxPagar.SAXL2_CODIGO;
       rMovCnt(j).S_CODIGO:=rSueldosxPagar.SAXL3_CODIGO;
       rMovCnt(j).DESCRIPCION:=rSueldosxPagar.EMPRESA ||'DE '|| TO_CHAR(dFechaHasta,'MONTH/YYYY');
       rMovCnt(j).ASOCIACION:=NULL;   
       rMovCnt(j).COMPROMISO:= 'F';
       rMovCnt(j).OBLIGACION:='F';
       rMovCnt(j).PAGO := 'F';  
       rMovCnt(j).AJUSTE_PRESUPUESTARIO := 'F';     
     ELSIF nDifCuadre<0 THEN
      QMS$ERRORS.SHOW_MESSAGE('CNT-01107');
     END IF;  
     END;
  END;
  END LOOP;
  k:= k+1;
  IF cCntPrs = 'V' THEN 
-- Si se trata de una Contabilidad Presupuestaria creamos los movimientos con las ctas. presupuestarias
     FOR rGasto_Presupuesto IN cGasto_Presupuesto LOOP
      -- FIJAMOS EL DEBE DE LA AFECTACION PRESUPUESTARIA
       rMovCnt(i).SECUENCIA:=k;
       rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(i).CMP_FECHA:=dFechaCmp;
       rMovCnt(i).CMP_CLAVE:=nClave;
       rMovCnt(i).DEBE:=ROUND(rGasto_Presupuesto.DEBE,2);
       rMovCnt(i).DEBEE:=ROUND(rGasto_Presupuesto.DEBE,2)*nTipoCambioE;
       rMovCnt(i).HABER:=0;
       rMovCnt(i).HABERE:=0;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rGasto_Presupuesto.EMP_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rGasto_Presupuesto.MYR_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rGasto_Presupuesto.CNT_CODIGO;
       rMovCnt(i).SS_S_A_SC_CODIGO:=rGasto_Presupuesto.SCNT_CODIGO;
       rMovCnt(i).SS_S_A_CODIGO:=rGasto_Presupuesto.AXL_CODIGO;
       rMovCnt(i).SS_S_CODIGO:=rGasto_Presupuesto.SAXL_CODIGO;
       rMovCnt(i).SS_CODIGO:=rGasto_Presupuesto.SAXL2_CODIGO;
       rMovCnt(i).S_CODIGO:=rGasto_Presupuesto.SAXL3_CODIGO;
       rMovCnt(i).DESCRIPCION:= rGasto_Presupuesto.PRM_NOMBRE||' SUELDOS DE '||TO_CHAR(dFechaHasta,'MONTH/YYYY');
       rMovCnt(i).ASOCIACION:=NULL;
       rMovCnt(i).COMPROMISO:= 'V';
       rMovCnt(i).OBLIGACION:='V';
       rMovCnt(i).PAGO := 'V'; 
       rMovCnt(i).AJUSTE_PRESUPUESTARIO := 'F';          
       i:=i+1;
     END LOOP;
     FOR rIngreso_Presupuesto IN cIngreso_Presupuesto LOOP
      -- FIJAMOS EL DEBE DE LA AFECTACION PRESUPUESTARIA
       rMovCnt(i).SECUENCIA:=k;
       rMovCnt(i).CMP_TPOCMPEMP_EMP_CODIGO:=cEmpCod;
       rMovCnt(i).CMP_TPOCMPEMP_TPOCMP_CODIGO:=cTpoCmp;
       rMovCnt(i).CMP_FECHA:=dFechaCmp;
       rMovCnt(i).CMP_CLAVE:=nClave;
       rMovCnt(i).DEBE:=0;
       rMovCnt(i).DEBEE:=0;
       rMovCnt(i).HABER:=ROUND(rIngreso_Presupuesto.HABER,2);
       rMovCnt(i).HABERE:=ROUND(rIngreso_Presupuesto.HABER,2)*nTipoCambioE;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_EMP_CODIGO:=rIngreso_Presupuesto.EMP_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_MYR_CODIGO:=rIngreso_Presupuesto.MYR_CODIGO;
       rMovCnt(i).SS_S_A_SC_CNT_CODIGO:=rIngreso_Presupuesto.CNT_CODIGO;
       rMovCnt(i).SS_S_A_SC_CODIGO:=rIngreso_Presupuesto.SCNT_CODIGO;
       rMovCnt(i).SS_S_A_CODIGO:=rIngreso_Presupuesto.AXL_CODIGO;
       rMovCnt(i).SS_S_CODIGO:=rIngreso_Presupuesto.SAXL_CODIGO;
       rMovCnt(i).SS_CODIGO:=rIngreso_Presupuesto.SAXL2_CODIGO;
       rMovCnt(i).S_CODIGO:=rIngreso_Presupuesto.SAXL3_CODIGO;
       rMovCnt(i).DESCRIPCION:= rIngreso_Presupuesto.PRM_NOMBRE||' '||TO_CHAR(dFechaHasta,'MONTH/YYYY');
       rMovCnt(i).ASOCIACION:=NULL;
       rMovCnt(i).COMPROMISO:= 'F';
       rMovCnt(i).OBLIGACION:='F';
       rMovCnt(i).PAGO := 'F';  
       rMovCnt(i).AJUSTE_PRESUPUESTARIO := 'F';
       i:=i+1;
     END LOOP;
  END IF;  
-- AHORA SI NO HA HABIDO NINGUN ERROR CREAMOS LOS DETALLES DEL COMPROBANTE
  FOR I IN 1..rMovCnt.COUNT LOOP
    IF (rMovCnt(I).DEBE=0 AND rMovCnt(I).HABER=0) OR (rMovCnt(I).DEBE>0 AND rMovCnt(I).HABER>0) THEN
      QMS$ERRORS.SHOW_MESSAGE('ADM-00009',rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO||rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO||
                                          rMovCnt(I).SS_S_A_SC_CNT_CODIGO||rMovCnt(I).SS_S_A_SC_CODIGO||
                                          rMovCnt(I).SS_S_A_CODIGO||rMovCnt(I).SS_S_CODIGO||rMovCnt(I).SS_CODIGO||
                                          rMovCnt(I).S_CODIGO||' '||rMovCnt(I).DESCRIPCION||' ** DEBE ** '||
                                          rMovCnt(I).DEBE||' ** HABER **'||rMovCnt(I).HABER,'Comuniquese con Softcase');
    END IF;
    INSERT INTO MOVIMIENTOS (MVM_ID,CMP_TPOCMPEMP_EMP_CODIGO,CMP_TPOCMPEMP_TPOCMP_CODIGO,
  	    CMP_FECHA,CMP_CLAVE,FECHA,SECUENCIA,DEBE,HABER,DEBEE,HABERE,MONEDA,TIPO_DE_CAMBIO,MAYORIZADO,
          COMPROMISO,OBLIGACION,PAGO,AJUSTE_PRESUPUESTARIO,
          SS_S_A_SC_CNT_MYR_EMP_CODIGO,SS_S_A_SC_CNT_MYR_CODIGO,SS_S_A_SC_CNT_CODIGO,
  	    SS_S_A_SC_CODIGO,SS_S_A_CODIGO,SS_S_CODIGO,SS_CODIGO,S_CODIGO,
          DESCRIPCION,ASOCIACION,ESTADO_MOVIMIENTO,OBL_OBL_ID)
    VALUES (MVM_SEQ.NEXTVAL,cEmpCod,cTpoCmp,dFechaCmp,nClave,dFechaCmp,rMovCnt(I).SECUENCIA,
      	rMovCnt(I).DEBE,rMovCnt(I).HABER,rMovCnt(I).DEBEE,rMovCnt(I).HABERE,
            vMonedaLocal,nTipoCambio,'F',rMovCnt(i).COMPROMISO,rMovCnt(i).OBLIGACION,
            rMovCnt(i).PAGO,rMovCnt(i).AJUSTE_PRESUPUESTARIO,rMovCnt(I).SS_S_A_SC_CNT_MYR_EMP_CODIGO,
            rMovCnt(I).SS_S_A_SC_CNT_MYR_CODIGO,rMovCnt(I).SS_S_A_SC_CNT_CODIGO,
  	      rMovCnt(I).SS_S_A_SC_CODIGO,rMovCnt(I).SS_S_A_CODIGO,rMovCnt(I).SS_S_CODIGO,
            rMovCnt(I).SS_CODIGO,rMovCnt(I).S_CODIGO,
  	      rMovCnt(I).DESCRIPCION,rMovCnt(I).ASOCIACION,'N',NULL);
  END LOOP;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
-- FALLA SI YA EXISTE UN COMPROBANTE IGUAL (CABECERA)
    QMS$ERRORS.SHOW_MESSAGE('CNT-01010',cTpoCmp||'-'||TO_CHAR(dFechaCmp,'DD/MM/YYYY')||'-'||TO_CHAR(nClave));
  WHEN OTHERS THEN
-- FALLA SI SE HA DADO ALGÚN PROBLEMA PARA LA INSERCIÓN DE LOS MOVIMIENTOS
    QMS$ERRORS.UNHANDLED_EXCEPTION ('Fallo en el procedimiento CONTABILIZAR_ROL por error '||SQLERRM);
END;
END;
/* Devuelve cuanto se paga por anticipos de una cuenta por cobrar */
FUNCTION PAGADO_POR_ANTICIPOS
 (VCAJA VARCHAR2
 ,NCTACBR NUMBER
 ,NANTNUM NUMBER := NULL
 )
 RETURN NUMBER
 IS

NANT ANTICIPOS.NUMERO%TYPE;
NVALOR NOTAS.VALOR%TYPE;
DECLARE
-- Devuelve la suma de valores pagados por el anticipo a esta cuenta por cobrar
-- unicamente de las notas no anuladas
  CURSOR cAntFct IS
    SELECT NTA.ANT_NUMERO ANT_VALOR,SUM(NTA.VALOR) VALOR
    FROM NOTAS NTA,FACTURAS FCT
    WHERE NTA.FCT_CAJA=vCaja
    AND NTA.FCT_NUMERO=FCT.NUMERO
    AND ((nAntNum IS NULL AND FCT.CTACBR_NUMERO=nCtaCbr)
       OR (nAntNum IS NOT NULL AND NTA.ANT_NUMERO=nAntNum
           AND FCT.CTACBR_NUMERO=nCtaCbr))
    AND NTA.NTA_TYPE='CRD' AND NTA.ESTADO='NRM'
    AND NTA.CTACBR_NUMERO IS NULL
    AND NTA.ANT_NUMERO IS NOT NULL
    GROUP BY NTA.ANT_NUMERO;
BEGIN
  nValor:=0;
  FOR rAntFct IN cAntFct LOOP
    nValor:=nValor+rAntFct.Valor;
  END LOOP;
  RETURN NVL(nValor,0);
END;
/* Devuelve cuanto se descuenta en una cuenta por cobrar */
FUNCTION DESCONTADO_EN_FACTURAS
 (VCAJA VARCHAR2
 ,NCTACBR NUMBER
 ,NDSCNUM NUMBER := NULL
 )
 RETURN NUMBER
 IS

NDSC DESCUENTOS_GENERADOS.NUMERO%TYPE;
NVALOR NOTAS.VALOR%TYPE;
DECLARE
-- Devuelve la suma de valores pagados por el anticipo a esta cuenta por cobrar
-- unicamente de las notas no anuladas
  CURSOR cDscFct IS
    SELECT NTA.DSCGNR_NUMERO,SUM(NTA.VALOR) VALOR
    FROM NOTAS NTA,FACTURAS FCT
    WHERE NTA.FCT_CAJA=vCaja
    AND NTA.FCT_NUMERO=FCT.NUMERO
    AND ((nDscNum IS NULL AND FCT.CTACBR_NUMERO=nCtaCbr)
       OR (nDscNum IS NOT NULL AND NTA.DSCGNR_NUMERO=nDscNum
           AND FCT.CTACBR_NUMERO=nCtaCbr))
    AND NTA.NTA_TYPE='CRD' AND NTA.ESTADO='NRM'
    AND NTA.CTACBR_NUMERO IS NULL
    AND NTA.DSCGNR_NUMERO IS NOT NULL
    GROUP BY NTA.DSCGNR_NUMERO;
  nSum NUMBER:=0;
BEGIN
  FOR rDscFct IN cDscFct LOOP
-- Acumulamos el total descontado de la cuenta por cobrar
    nSum:=nSum+NVL(rDscFct.VALOR,0);
  END LOOP;
/*  OPEN cDscFct;
  FETCH cDscFct INTO nDsc,nValor;
  CLOSE cDscFct;*/
  RETURN NVL(nSum,0);
/*  OPEN cDscFct;
  FETCH cDscFct INTO nDsc,nValor;
  CLOSE cDscFct;*/
END;
/* Devuelve el número de impresión de facturas asociadas a una cta x cbr */
FUNCTION NUMERO_DE_FACTURAS
 (VCAJA VARCHAR2
 ,NCTACBR CUENTAS_POR_COBRAR.NUMERO%TYPE
 ,BDISPARAREXC BOOLEAN := FALSE
 )
 RETURN VARCHAR2
 IS

VFACTURAS VARCHAR2(4000) := NULL;
BFALLO BOOLEAN := FALSE;
VFACTURASERROR VARCHAR2(4000) := NULL;
NTEMP NUMBER := 0;
/* Devulve el numero de impresion de facturas de las facturas asociadas
 con las cuota a cobrar
 Si hay un error devuelve:
         -1 -> Cuenta por cobrar si facturas asociadas
         -2 -> Facturas sin un numero de impresion 'CNT-01002'
*/
DECLARE

  CURSOR cFctCtaCbr IS
    SELECT NUMERO_IMPRESION,CAJA,NUMERO
    FROM FACTURAS
    WHERE CTACBR_NUMERO=nCtaCbr AND CAJA=vCaja AND ESTADO!='ANL';
BEGIN
  FOR rFctCtaCbr IN cFctCtaCbr LOOP
    IF rFctCtaCbr.NUMERO_IMPRESION IS NOT NULL THEN
      vFacturas:=vFacturas||'-'||rFctCtaCbr.NUMERO_IMPRESION;
    ELSE
      vFacturasError:=vFacturasError||'-'||'S/N impresion '||rFctCtaCbr.CAJA||'-'||LTRIM(RTRIM(TO_CHAR(rFctCtaCbr.NUMERO)));
      bFallo:=TRUE;
    END IF;
    nTemp:=nTemp+1;
  END LOOP;
  IF nTemp=0 THEN
    RETURN '-1';
  END IF;
  IF bFallo AND bDispararExc THEN
    RETURN '-2';
  END IF;
  RETURN vFacturasError||vFacturas;
END;
/* Devuelve el agrupador contable */
FUNCTION AGRUPADOR_CONTABLE
 (NHC NUMBER
 ,NPRMATN NUMBER
 ,VEMPCOD VARCHAR2 := NULL
 )
 RETURN VARCHAR2
 IS
BEGIN
IF NVL(vEmpCod,'CSI')='CSI' THEN
-- PARA LA CLINICA SANTA INES
  DECLARE
    CPENSION CONSTANT VARCHAR2(10) := '2';
    CSOCIO CONSTANT VARCHAR2(10) := '8';
    VCLSF VARCHAR2(3);
    CMEDIAPENSION CONSTANT VARCHAR2(10) := '3';
    CEMPLEADO CONSTANT VARCHAR2(10) := '9';
    CHOSPITALDIA CONSTANT VARCHAR2(10) := '4';
    VSRVPRM VARCHAR2(3) := 'PE1';
    VTIPOPRM CHAR(3) := 'EMR';
    CEMERGENCIA CONSTANT VARCHAR2(10) := '5';
    CSUITE CONSTANT VARCHAR2(10) := '1';
    CRX CONSTANT VARCHAR2(10) := '6';
    CCONSULTAEXTERNA CONSTANT VARCHAR2(10) := '7';
-- Devuelve el agrupador contable del paciente y permanencia de acuerdo al dominio
-- AGRUPADOR CONTABLE ESPECIFICO

--  1 -> Suite
--  2 -> Pensión
--  3 -> Media Pensión
--  4 -> Hospital del Día (Quirofano del día)
--  5 -> Emergencia
--  6 -> Rayos X
--  7 -> Consulta Externa
--  8 -> Socios
--  9 -> Empleados
 
--  Si devuelve numeros negativos hubo errores 
--     1 -> Paciente no existente cnt-01000
--     2 -> Turno cama no existente cnt-01001

    CURSOR cPcn IS
      SELECT CLASIFICACION
      FROM PACIENTES
      WHERE NUMERO_HC=nHC;
    CURSOR cPrmAtn IS
      SELECT TIPO
      FROM PERMANENCIAS_Y_ATENCIONES
      WHERE NUMERO=nPrmAtn
      AND PCN_NUMERO_HC=nHc;
    CURSOR cTrnCma IS
      SELECT NVL(TC.ENCARGADO,CH.SERVICIO)
      FROM TURNOS_CAMAS TC,CAMAS_HOSPITALIZACION CH
      WHERE PRM_NUMERO=nPrmAtn
      AND CMAHSP_SALA=CH.SALA
      AND CMAHSP_CAMA=CH.CAMA
      AND FECHA=(SELECT MAX(FECHA)
               FROM TURNOS_CAMAS TC2,CAMAS_HOSPITALIZACION CM
               WHERE TC2.PRM_NUMERO=nPrmAtn
               AND CM.SERVICIO NOT IN ('UCI','NEO','RIA'));
  BEGIN
    IF nPrmAtn IS NULL THEN
-- Si el numero de permanencia es nulo es una venta de botica
      OPEN cPcn;
      FETCH cPcn INTO vClsf;
      IF cPcn%NOTFOUND THEN
        CLOSE cPcn;
        RETURN '-1';
--      QMS$ERRORS.SHOW_MESSAGE('CNT-01000',RTRIM(LTRIM(TO_CHAR(nPrmAtn)))); -- Paciente no existente
      END IF;
      CLOSE cPcn;
      IF vClsf='SOC' THEN
        RETURN cSocio;
      ELSIF vClsf='EMP' THEN
        RETURN cEmpleado;
      ELSE
        RETURN cConsultaExterna;
      END IF;
    ELSE
      OPEN cPrmAtn;
      FETCH  cPrmAtn INTO vTipoPrm;
      IF cPrmAtn%NOTFOUND THEN
        CLOSE cPrmAtn;
        RETURN '-1';
--      QMS$ERRORS.SHOW_MESSAGE('CNT-01000',RTRIM(LTRIM(TO_CHAR(nPrmAtn)))); -- Paciente no existente
      END IF;
      CLOSE cPrmAtn;
      IF vTipoPrm='HSP' THEN
-- Si estan hospitalizados, vemos si pertenece a suit, pension o media pensión
        OPEN cTrnCma;
        FETCH cTrnCma INTO vSrvPrm;
        IF cTrnCma%NOTFOUND THEN
          CLOSE cTrnCma;
          RETURN '-2';
--        QMS$ERRORS.SHOW_MESSAGE('CNT-01001',RTRIM(LTRIM(TO_CHAR(nPrmAtn)))); -- Paciente no existente
        END IF;
        CLOSE cTrnCma;
        IF vSrvPrm IN ('UCI','NEO','RIA') THEN
-- Si el servicio es UCI,NEOnatologia o RIñon Artificial consideramos como SUITE
           vSrvPrm:='SU4';
        END IF;
        IF vSrvPrm='PE1' THEN
           RETURN cMediaPension;
        ELSIF vSrvPrm IN ('PE2','PE3') THEN
           RETURN cPension;
        ELSIF vSrvPrm IN ('SU1','SU4') THEN
           RETURN cSuite;
        END IF;
      ELSIF vTipoPrm='EMR' THEN
        RETURN cEmergencia;
      ELSIF vTipoPrm='RYX' THEN
        RETURN cRX;
      ELSIF vTipoPrm='QRF' THEN
        RETURN cHospitalDia;
      END IF;
    END IF;
  END;
ELSIF vEmpCod='HMS' THEN
-- PARA EL HOSPITAL MONTE SINAI
  DECLARE
  CFARMACIA CONSTANT VARCHAR2(10) := '1';
  CHOSPITALIZACION CONSTANT VARCHAR2(10) := '2';
  CQUIROFANO CONSTANT VARCHAR2(10) := '3';
  CEMERGENCIA CONSTANT VARCHAR2(10) := '4';
  CHONORARIOS CONSTANT VARCHAR2(10) := '5';
  CVARIOS CONSTANT VARCHAR2(10) := '6';
  VCLSF VARCHAR2(3);
  VSRVPRM VARCHAR2(3) := 'PE1';
  VTIPOPRM CHAR(3) := 'EMR';
-- PL/SQL Block
-- Devuelve el agrupador contable del paciente y permanencia de acuerdo al dominio
-- AGRUPADOR CONTABLE ESPECIFICO
/*
  1 -> Farmacia
  2 -> Hospitalizacion
  3 -> Quirofano
  4 -> Emergencia
  5 -> Honorarios
  6 -> Varios
  Si devuelve numeros negativos hubo errores
     1 -> Paciente no existente cnt-01000
     2 -> Turno cama no existente cnt-01001
*/
    CURSOR cPrmAtn IS
      SELECT TIPO
      FROM PERMANENCIAS_Y_ATENCIONES
      WHERE NUMERO=nPrmAtn
      AND PCN_NUMERO_HC=nHc;

  BEGIN
    IF nPrmAtn IS NULL THEN
-- Si el numero de permanencia es nulo es una venta de botica
      RETURN CFARMACIA;
    ELSE
      OPEN cPrmAtn;
      FETCH  cPrmAtn INTO vTipoPrm;
      IF cPrmAtn%NOTFOUND THEN
        CLOSE cPrmAtn;
        RETURN '-1';
--      QMS$ERRORS.SHOW_MESSAGE('CNT-01000',RTRIM(LTRIM(TO_CHAR(nPrmAtn)))); -- Paciente no existente
      END IF;
      CLOSE cPrmAtn;
      IF vTipoPrm='HSP' THEN
-- Si estan hospitalizados, vemos si pertenece a suit, pension o media pensión
        RETURN CHOSPITALIZACION;
      ELSIF vTipoPrm='EMR' THEN
        RETURN cEmergencia;
      ELSIF vTipoPrm='QRF' THEN
        RETURN cQuirofano;
      END IF;
    END IF;
  END;
END IF;
END;

END CNTINT;
/
SHOW ERROR

