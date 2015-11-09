CREATE OR REPLACE VIEW CONVENIOS_TARIFARIOS
(convenio, discriminador_hoja, codigo, descripcion, descripcion_completa, observacion, uvr, uvr_anes, prc, tipo)
AS
SELECT CONVENIO CONVENIO,
          'SERVICIO DE AMBULANCIAS' DISCRIMINADOR_HOJA,
          MA.CODIGO_ITEM,
          MA.DESCRIPCION_ESPECIFICA DESCRIPCION,
          MA.CODIGO_GRUPO||' '||MA.DESCRIPCION_GRUPO||
          CHR (13) || CHR (10) || CHR (9) ||
          MA.CODIGO_SUBGRUPO_1||' '||MA.DESCRIPCION_SUBGRUPO_1||
          DECODE(NVL(MA.CODIGO_SUBGRUPO_2,'NULO'),
                'NULO',CHR (13) || CHR (10) || CHR (9)|| CHR (9),
                CHR (13) || CHR (10) || CHR (9)||  CHR (9) ||
                MA.CODIGO_SUBGRUPO_2 ||' '|| ma.descripcion_subgrupo_2||CHR (13) || CHR (10) || CHR (9)|| CHR (9)|| CHR (9))||
          MA.CODIGO_ITEM||' '||MA.DESCRIPCION_ESPECIFICA,
          MA.DESCRIPCION_ITEM,
          MA.UVR,
          NULL UVR_ANES,
          NULL,
          TIPO
     FROM MSP_SERVICIO_AMBULANCIAS MA
/*SERVICIOS HOTELERIA Y OTROS*/
UNION
   SELECT CONVENIO CONVENIO,
          'SERVICIO DE HOTELERIA Y OTROS' DISCRIMINADOR_HOJA,
          SH.CODIGO_ITEM,
          SH.DESCRIPCION_ITEM DESCRIPCION,
          SH.CODIGO_GRUPO||' '||SH.DESCRIPCION_GRUPO||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(SH.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                SH.CODIGO_SUBGRUPO||' '||SH.DESCRIPCION_SUBGRUPO||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(SH.CODIGO_SUBGRUPO_1,'NULO'),
                 'NULO','',
                 SH.CODIGO_SUBGRUPO_1|| ' '||SH.DESCRIPCION_SUBGRUPO_1||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
         SH.CODIGO_ITEM|| ' ' ||SH.DESCRIPCION_ITEM
                          ,
          SH.OBSERVACION,
          SH.UVR,
          NULL UVR_ANES,
          NULL,
          TIPO
     FROM MSP_SERVICIOS_HOTELERIA SH
     WHERE SH.NIVEL LIKE '%3%'
/*MSP_VISITAS_DOMICILIARIAS*/
UNION
   SELECT CONVENIO CONVENIO,
          'VISITAS DOMICILIARIAS' DISCRIMINADOR_HOJA,
          VD.CODIGO_ITEM,
          VD.DESCRIPCION_ITEM DESCRIPCION,
          VD.CODIGO_GRUPO||' '||VD.DESCRIPCION_GRUPO||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(VD.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                VD.CODIGO_SUBGRUPO||' '||VD.DESCRIPCION_SUBGRUPO||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
         VD.CODIGO_ITEM|| ' ' ||VD.DESCRIPCION_ITEM,
          NULL,
          VD.UVR,
          NULL UVR_ANES,
          NULL,
          TIPO
     FROM MSP_VISITAS_DOMICILIARIAS VD
/* SERVICIOS DE DIAGNOSTICO, EXAMENES Y PROCEDIMIENTOS
MSP_SERV_DX_EX_PROC*/
UNION
   SELECT CONVENIO CONVENIO,
          'SERVICIO DE DIAGNOSTICO, EXAMENES Y PROCEDIMIENTOS' DISCRIMINADOR_HOJA,
          SD.CODIGO_ITEM,
          SD.DESCRIPCION_ITEM DESCRIPCION,
          SD.CODIGO_GRUPO||' '||SD.DESCRIPCION_GRUPO||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(SD.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                SD.CODIGO_SUBGRUPO||' '||SD.DESCRIPCION_SUBGRUPO||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(SD.CODIGO_SUBGRUPO_1,'NULO'),
                 'NULO','',
                 SD.CODIGO_SUBGRUPO_1|| ' '||SD.DESCRIPCION_SUBGRUPO_1||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
         SD.CODIGO_ITEM|| ' ' ||SD.DESCRIPCION_ITEM
                          ,
          SD.OBSERVACION,
          SD.UVR3,
          NULL UVR_ANES,
          NULL,
          TIPO
     FROM MSP_SERV_DX_EX_PROC SD
 /*MSP_SERVICIOS_ODONTOLOGICOS*/
 UNION
   SELECT CONVENIO CONVENIO,
          'SERVICIOS ODONTOLOGICOS' DISCRIMINADOR_HOJA,
          SO.CODIGO_ITEM,
          SO.DESCRIPCION_ITEM DESCRIPCION,
          SO.CODIGO_GRUPO||' '||SO.DESCRIPCION_GRUPO||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(SO.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                SO.CODIGO_SUBGRUPO||' '||SO.DESCRIPCION_SUBGRUPO||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(SO.CODIGO_SUBGRUPO_1,'NULO'),
                 'NULO','',
                 SO.CODIGO_SUBGRUPO_1|| ' '||SO.DESCRIPCION_SUBGRUPO_1||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
         SO.CODIGO_ITEM|| ' ' ||SO.DESCRIPCION_ITEM
                          ,
          NULL,
          SO.UVR3,
          NULL UVR_ANES,
          NULL,
          TIPO
     FROM MSP_SERVICIOS_ODONTOLOGICOS SO
 /*MSP_COMPONENTE_MEDICINA*/
 UNION
   SELECT CONVENIO CONVENIO,
          'COMPONENTE MEDICINA' DISCRIMINADOR_HOJA,
          CM.CODIGO_ITEM,
          CM.DESCRIPCION_ITEM DESCRIPCION,
          CM.CODIGO_GRUPO||' '||CM.DESCRIPCION_GRUPO||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(CM.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                CM.CODIGO_SUBGRUPO||' '||CM.DESCRIPCION_SUBGRUPO||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(CM.CODIGO_SUBGRUPO_1,'NULO'),
                 'NULO','',
                 CM.CODIGO_SUBGRUPO_1|| ' '||CM.DESCRIPCION_SUBGRUPO_1||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
          DECODE (NVL(CM.DESCRIPCION_ESPECIFICA,'NULO'),
                 'NULO','',
                 CM.DESCRIPCION_ESPECIFICA||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)||CHR (9)) ||
         CM.CODIGO_ITEM|| ' ' ||CM.DESCRIPCION_ITEM
                          ,
          CM.OBSERVACION,
          NVL(CM.UVR_H_MED,0) UVR,
          NVL(CM.UVR_ANES,0) UVR_ANES,
          NULL,
          TIPO
     FROM MSP_COMPONENTE_MEDICINA CM
 /*MSP_RADIOLOGIA*/
 UNION
   SELECT CONVENIO CONVENIO,
          'RADIOLOGIA' DISCRIMINADOR_HOJA,
          MR.CODIGO_ITEM,
          MR.DESCRIPCION_ITEM DESCRIPCION,
          MR.CODIGO_GRUPO||' '||MR.DESCRIPCION_GRUPO||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(MR.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                MR.CODIGO_SUBGRUPO||' '||MR.DESCRIPCION_SUBGRUPO||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(MR.CODIGO_SUBGRUPO_1,'NULO'),
                 'NULO','',
                 MR.CODIGO_SUBGRUPO_1|| ' '||MR.DESCRIPCION_SUBGRUPO_1||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
          DECODE (NVL(MR.DESCRIPCION_ESPECIFICA,'NULO'),
                 'NULO','',
                 MR.DESCRIPCION_ESPECIFICA||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)||CHR (9)) ||
         MR.CODIGO_ITEM|| ' ' ||MR.DESCRIPCION_ITEM
                          ,
          MR.OBSERVACION,
          NVL(MR.UVR_H_MED,0) UVR,
          NVL(MR.UVR_ANES,0) UVR_ANES,
          NULL,
          TIPO
     FROM MSP_COMPONENTE_MEDICINA MR
 /*MSP_EVALUACION_Y_MANEJO*/
 UNION
   SELECT CONVENIO CONVENIO,
          'EVALUACION Y MANEJO' DISCRIMINADOR_HOJA,
          EM.CODIGO_ITEM,
          EM.DESCRIPCION_ITEM DESCRIPCION,
          EM.CODIGO_GRUPO||' '||EM.DESCRIPCION_GRUPO||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(EM.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                EM.CODIGO_SUBGRUPO||' '||EM.DESCRIPCION_SUBGRUPO||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(EM.CODIGO_SUBGRUPO_1,'NULO'),
                 'NULO','',
                 EM.CODIGO_SUBGRUPO_1|| ' '||EM.DESCRIPCION_SUBGRUPO_1||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
         EM.CODIGO_ITEM|| ' ' ||EM.DESCRIPCION_ITEM
                          ,
          EM.OBSERVACION,
          EM.UVR UVR,
          NULL,
          NULL,
          TIPO
     FROM MSP_EVALUACION_Y_MANEJO EM
 /*MSP_ANESTESIA*/
 UNION
   SELECT CONVENIO CONVENIO,
          'ANESTESIA' DISCRIMINADOR_HOJA,
          A.CODIGO_ITEM,
          A.DESCRIPCION_ITEM DESCRIPCION,
          A.CODIGO_GRUPO||' '||A.DESCRIPCION_GRUPO||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(A.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                A.CODIGO_SUBGRUPO||' '||A.DESCRIPCION_SUBGRUPO||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(A.CODIGO_SUBGRUPO_1,'NULO'),
                 'NULO','',
                 A.CODIGO_SUBGRUPO_1|| ' '||A.DESCRIPCION_SUBGRUPO_1||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
         A.CODIGO_ITEM|| ' ' ||A.DESCRIPCION_ITEM
                          ,
          NULL,
          A.UNIDADES UVR,
          NULL,
          NULL,
          TIPO
     FROM MSP_ANESTESIA A
 /*MSP_PRESTACIONES_INTEGRALES*/
 UNION
   SELECT CONVENIO CONVENIO,
          'PRESTACIONES INTEGRALES' DISCRIMINADOR_HOJA,
          PI.CODIGO_ITEM,
          PI.DESCRIPCION_ITEM DESCRIPCION,
          PI.CODIGO_GRUPO||' '||PI.DESCRIPCION_SUBGRUPO||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(PI.CODIGO_SUBGRUPO_1,'NULO'),
                'NULO','',
                PI.CODIGO_SUBGRUPO_1||' '||PI.DESCRIPCION_SUBGRUPO_1||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(PI.CODIGO_SUBGRUPO_2,'NULO'),
                 'NULO','',
                 PI.CODIGO_SUBGRUPO_2|| ' '||PI.DESCRIPCION_SUBGRUPO_2||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
         PI.CODIGO_ITEM|| ' ' ||PI.DESCRIPCION_ITEM
                          ,
          PI.OBSERVACION,
          PI.UVR3 UVR,
          NULL,
          NULL,
          TIPO
     FROM MSP_PRESTACIONES_INTEGRALES PI
     WHERE PI.UVR3 IS NOT NULL
 UNION
   SELECT CONVENIO CONVENIO,
          'CIRUGIA' DISCRIMINADOR_HOJA,
          MSC.CODIGO_ITEM,
          MSC.DESCRIPCION_ITEM DESCRIPCION,
          MSC.CODIGO_GRUPO||' '||MSC.DESCRIPCION_SUBGRUPO||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(MSC.CODIGO_SUBGRUPO_1,'NULO'),
                'NULO','',
                MSC.CODIGO_SUBGRUPO_1||' '||MSC.DESCRIPCION_SUBGRUPO_1||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(MSC.CODIGO_SUBGRUPO_2,'NULO'),
                 'NULO','',
                 MSC.CODIGO_SUBGRUPO_2|| ' '||MSC.DESCRIPCION_SUBGRUPO_2||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
         MSC.CODIGO_ITEM|| ' ' ||MSC.DESCRIPCION_ITEM,
          MSC.OBSERVACIONES,
         TO_NUMBER(MSC.UVR_H_MED) UVR_H_MED,
          MSC.ANES UVR_ANES,
          NVL(MSC.PRC3,0),
          TIPO
   FROM MSP_CIRUGIA MSC

