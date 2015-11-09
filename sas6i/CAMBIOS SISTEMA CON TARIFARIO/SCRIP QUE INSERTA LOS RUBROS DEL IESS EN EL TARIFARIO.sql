INSERT INTO TARIFARIOS T (CONVENIO,TIPO,CODIGO_GRUPO,CODIGO_SUBGRUPO,CODIGO_ITEM,DESCRIPCION_ITEM,UVR,ANES,PRC,PRC_ANES)
SELECT 'TRFIESS','X','1','1.11',TI.CODIGO_ITEM,TI.DESCRIPCION_ITEM,TI.UVR,TI.UVR_ANES,TI.PRC,TI.PRC_ANES 
       FROM TARIFARIO_IESS TI
       WHERE TI.CODIGO_GRUPO = 'LBR' AND TI.CODIGO_ITEM NOT IN (SELECT TF.CODIGO_ITEM FROM TARIFARIOS TF
                                                              WHERE TF.CONVENIO = 'TRFIESS')
                                                              
SELECT * FROM TARIFARIO_IESS_FALTANTE TI ORDER BY TI.CODIGO_GRUPO,TI.CODIGO_ITEM FOR UPDATE                                                              
                                                              
--BEGIN                                                              
INSERT INTO TARIFARIOS TI (CONVENIO,TIPO,CODIGO_GRUPO,CODIGO_SUBGRUPO,CODIGO_SUBGRUPO_1,CODIGO_ITEM,DESCRIPCION_ITEM,UVR,ANES,PRC,PRC_ANES)
SELECT 'TRFIESS',TIF.TIPO,TIF.CODIGO_GRUPO,TIF.CODIGO_SUBGRUPO,TIF.CODIGO_SUBGRUPO_1,TIF.CODIGO_ITEM,TIF.DESCRIPCION_ITEM,TIF.UVR,TIF.UVR_ANES,TIF.PRC,TIF.PRC_ANES 
FROM TARIFARIO_IESS_FALTANTE TIF 
WHERE TIF.CODIGO_GRUPO = '1' AND TIF.CODIGO_ITEM NOT IN (SELECT TF.CODIGO_ITEM FROM TARIFARIOS TF
                                                              WHERE TF.CONVENIO = 'TRFIESS')   
AND TIF.TIPO = 'P'                                                              
--EXCEPTION
--WHEN OTHERS THEN
--  DBMS_OUTPUT.put_line('No se pudo insertar el ítem ')                                                              
--END;                                                              
                                                              
                                                              
INSERT INTO CARGOS C (TIPO,CODIGO,DESCRIPCION,COSTO,IVA,ESTADO_DE_DISPONIBILIDAD,
                      COSTO_MODIFICABLE,DPR_CODIGO,DPR_ARA_CODIGO,EQUIPO_ESPECIAL,
                      AGRCNT_TIPO,TIEMPO,FACTOR,RANGO_MINIMO,RANGO_MAXIMO,
                      OPERADOR,CANTIDAD_MINIMA,EMP_CODIGO,NOMBRE_IESS,CODIGO_IESS,GOBIERNO,IESS)
SELECT 'S','I'||SUBSTR(T.CODIGO_ITEM,1,6),SUBSTR(T.DESCRIPCION_ITEM,1,120),T.UVR*T.PRC,0,'D',
       'F','I','I','F','2','F',1,0,999999,'N',1,'CSI',SUBSTR(T.DESCRIPCION_ITEM,1,250),
       T.CODIGO_ITEM,'F','V'
FROM TARIFARIOS T
WHERE T.CONVENIO= 'TRFIESS' AND
      T.TIPO = 'P' AND 
      T.CODIGO_ITEM NOT IN (SELECT CE.CNVTRF_CODIGO FROM CONVENIOS_EQUIVALENCIAS CE
                            WHERE CE.CNVTRF_CONVENIO = 'TRFIESS')     
                            
                            
BEGIN
DECLARE CURSOR CCARGOS IS 
SELECT * FROM CARGOS C
WHERE C.IESS = 'V' AND C.CODIGO_IESS IS NOT NULL and
      c.estado_de_disponibilidad = 'D' AND
      (C.TIPO,C.CODIGO) NOT IN (SELECT CE.CRG_TIPO,CE.CRG_CODIGO FROM CONVENIOS_EQUIVALENCIAS CE
                                 WHERE CE.CNVTRF_CONVENIO = 'TRFIESS');
VTIPO  CHAR:= NULL;      
BEGIN
  FOR RCARGOS IN CCARGOS LOOP
  BEGIN
     SELECT DISTINCT T.TIPO INTO VTIPO
     FROM TARIFARIOS T
     WHERE T.CONVENIO = 'TRFIESS' AND
           T.CODIGO_ITEM = RCARGOS.CODIGO_IESS;
  EXCEPTION
  WHEN OTHERS THEN
     DBMS_OUTPUT.put_line('No se encontró un cargo para el código iess '||RCARGOS.CODIGO_IESS);
  END;   
  IF VTIPO IS NOT NULL THEN
  BEGIN
     INSERT INTO CONVENIOS_EQUIVALENCIAS C(crg_codigo,crg_tipo,cnvtrf_convenio,cnvtrf_codigo,tipo)
     VALUES(RCARGOS.CODIGO,RCARGOS.TIPO,'TRFIESS',rcargos.codigo_iess,vtipo);
  EXCEPTION
  WHEN OTHERS THEN
     DBMS_OUTPUT.put_line('No se pudo insertar el cargo '||RCARGOS.CODIGO||sqlerrm);     
  END;   
  END IF;
  VTIPO := NULL;
  END LOOP;
END;      
END;                                                                                                                                                         