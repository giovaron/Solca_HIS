UPDATE CARGOS C
SET C.COSTO = ROUND(NVL((SELECT T.ANES*T.PRC_ANES FROM TARIFARIOS  T, CONVENIOS_EQUIVALENCIAS CE
               WHERE T.CONVENIO = 'TRFIESS' AND
                     T.CODIGO_ITEM = CE.CNVTRF_CODIGO AND
                     T.TIPO = CE.TIPO AND
                     CE.CRG_CODIGO = C.CODIGO AND
                     CE.CRG_TIPO = C.TIPO),0),2)                     
WHERE C.IESS = 'V' AND
      NVL(C.ANESTESIA_IESS,'F') = 'V'
      
SELECT * FROM CARGOS C 
WHERE C.IESS = 'V' AND
      NVL(C.ANESTESIA_IESS,'F') = 'F'       
      
      
UPDATE CARGOS C
SET C.COSTO = NVL((SELECT T.UVR*T.PRC FROM TARIFARIOS_EMPRESA T , CONVENIOS_EQUIVALENCIAS CE
               WHERE T.CONVENIO = 'MSPJUN2011' AND
                     T.TIPO = CE.TIPO AND
                     T.codigo = CE.CNVTRF_CODIGO AND                     
                     CE.CRG_CODIGO = C.CODIGO AND
                     CE.CRG_TIPO = C.TIPO),100000)
WHERE C.GOBIERNO = 'V'      
