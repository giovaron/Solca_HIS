BEGIN
DECLARE CURSOR CCARGOS IS 
SELECT * FROM CARGOS C
WHERE (NVL(C.GOBIERNO,'F') = 'F' AND C.CODIGO_IESS IS NOT NULL) OR 
      (NVL(C.IESS,'F') = 'V' AND C.CODIGO_IESS IS NOT NULL) and
      c.estado_de_disponibilidad = 'D';
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