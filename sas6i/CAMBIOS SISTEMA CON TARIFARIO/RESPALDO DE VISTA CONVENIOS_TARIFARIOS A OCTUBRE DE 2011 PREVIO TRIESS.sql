CREATE OR REPLACE VIEW CONVENIOS_TARIFARIOS
(convenio, discriminador_hoja, codigo, descripcion, descripcion_completa, observacion, uvr, uvr_anes, prc, prc_anes, tipo, no_aplica_tiempo)
AS
SELECT SH.CONVENIO CONVENIO,
          C.RV_MEANING  DISCRIMINADOR_HOJA,
          SH.CODIGO_ITEM,
          UPPER(SH.DESCRIPCION_ITEM) DESCRIPCION,
          SH.CODIGO_GRUPO||' '||GT.DESCRIPCION||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(SH.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                SH.CODIGO_SUBGRUPO||' '||ST.DESCRIPCION||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(SH.CODIGO_SUBGRUPO_1,'NULO'),
                 'NULO','',
                 SH.CODIGO_SUBGRUPO_1|| ' '||S1T.DESCRIPCION||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
         SH.CODIGO_ITEM|| ' ' ||SH.DESCRIPCION_ITEM
                          ,
          SH.OBSERVACIONES,
          SH.UVR,
          NULL UVR_ANES,
          SH.PRC,
          NULL PRC_ANES,
          SH.TIPO,
          SH.NO_APLICA_TIEMPO
     FROM TARIFARIOS SH,CG_REF_CODES C,GRUPOS_TARIFARIO GT,SUBGRUPOS_TARIFARIO ST,SUBGRUPOS_1_TARIFARIO S1T
     WHERE SH.NIVEL LIKE '%3%' AND
           C.RV_DOMAIN =  'TIPO_TARIFARIO' AND
           C.RV_LOW_VALUE = SH.TIPO AND
           SH.CONVENIO = GT.CONVENIO(+) AND
           SH.TIPO = GT.TIPO(+) AND
           GT.CODIGO(+) = SH.CODIGO_GRUPO AND
           SH.CONVENIO = ST.CONVENIO(+) AND
           SH.TIPO = ST.TIPO(+) AND
           ST.CODIGO(+) = SH.CODIGO_SUBGRUPO AND
           SH.CONVENIO = S1T.CONVENIO (+)AND
           SH.TIPO= S1T.TIPO(+) AND
           S1T.CODIGO (+)= SH.CODIGO_SUBGRUPO_1 AND
           SH.TIPO = 'H'
 UNION ALL
 SELECT A.CONVENIO CONVENIO,
          C.RV_MEANING  DISCRIMINADOR_HOJA,
          A.CODIGO_ITEM,
          UPPER(A.DESCRIPCION_ITEM) DESCRIPCION,
          A.CODIGO_GRUPO||' '||GT.DESCRIPCION||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(A.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                A.CODIGO_SUBGRUPO||' '||ST.DESCRIPCION||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(A.CODIGO_SUBGRUPO_1,'NULO'),
                 'NULO','',
                 A.CODIGO_SUBGRUPO_1|| ' '||S1T.DESCRIPCION||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
         A.CODIGO_ITEM|| ' ' ||A.DESCRIPCION_ITEM
                          ,
          A.OBSERVACIONES,
          A.UNIDADES,
          NULL UVR_ANES,
          A.PRC,
          A.PRC_ANES,
          A.TIPO,
          A.NO_APLICA_TIEMPO
     FROM TARIFARIOS A,CG_REF_CODES C,GRUPOS_TARIFARIO GT,SUBGRUPOS_TARIFARIO ST,SUBGRUPOS_1_TARIFARIO S1T
     WHERE C.RV_DOMAIN =  'TIPO_TARIFARIO' AND
           C.RV_LOW_VALUE = A.TIPO AND
           A.CONVENIO = GT.CONVENIO AND
           A.TIPO = GT.TIPO AND
           GT.CODIGO = A.CODIGO_GRUPO AND
           A.CONVENIO = ST.CONVENIO AND
           A.TIPO = ST.TIPO AND
           ST.CODIGO = A.CODIGO_SUBGRUPO AND
           A.CONVENIO = S1T.CONVENIO AND
           A.TIPO= S1T.TIPO AND
           S1T.CODIGO = A.CODIGO_SUBGRUPO_1 AND
           A.TIPO = 'A'
 UNION ALL
   SELECT PI.CONVENIO CONVENIO,
          C.RV_MEANING  DISCRIMINADOR_HOJA,
          PI.CODIGO_ITEM,
          UPPER(PI.DESCRIPCION_ITEM) DESCRIPCION,
          PI.CODIGO_GRUPO||' '||GT.DESCRIPCION||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(PI.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                PI.CODIGO_SUBGRUPO||' '||ST.DESCRIPCION||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(PI.CODIGO_SUBGRUPO_1,'NULO'),
                 'NULO','',
                 PI.CODIGO_SUBGRUPO_1|| ' '||S1T.DESCRIPCION||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
         PI.CODIGO_ITEM|| ' ' ||PI.DESCRIPCION_ITEM,
          PI.OBSERVACIONES,
          PI.UVR,
          NULL UVR_ANES,
          PI.PRC,
          NULL PRC_ANES,
          PI.TIPO,
          PI.NO_APLICA_TIEMPO
     FROM TARIFARIOS PI,CG_REF_CODES C,GRUPOS_TARIFARIO GT,SUBGRUPOS_TARIFARIO ST,SUBGRUPOS_1_TARIFARIO S1T
     WHERE C.RV_DOMAIN =  'TIPO_TARIFARIO' AND
           C.RV_LOW_VALUE = PI.TIPO AND
           PI.CONVENIO = GT.CONVENIO AND
           PI.TIPO = GT.TIPO AND
           GT.CODIGO = PI.CODIGO_GRUPO AND
           PI.CONVENIO = ST.CONVENIO AND
           PI.TIPO = ST.TIPO AND
           ST.CODIGO = PI.CODIGO_SUBGRUPO AND
           PI.CONVENIO = S1T.CONVENIO(+) AND
           PI.TIPO= S1T.TIPO(+) AND
           S1T.CODIGO(+) = PI.CODIGO_SUBGRUPO_1 AND
           PI.TIPO = 'P'  AND
           PI.UVR3 IS NOT NULL
 UNION ALL
   SELECT T.CONVENIO CONVENIO,
          C.RV_MEANING  DISCRIMINADOR_HOJA,
          T.CODIGO_ITEM,
          UPPER(T.DESCRIPCION_ITEM) DESCRIPCION,
          T.CODIGO_GRUPO||' '||GT.DESCRIPCION||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(T.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                T.CODIGO_SUBGRUPO||' '||ST.DESCRIPCION||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(T.CODIGO_SUBGRUPO_1,'NULO'),
                 'NULO','',
                 T.CODIGO_SUBGRUPO_1||' '||S1T.DESCRIPCION||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(T.CODIGO_SUBGRUPO_2,'NULO'),
                 'NULO','',
                 T.CODIGO_SUBGRUPO_2|| ' '||S2T.DESCRIPCION||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
         T.CODIGO_ITEM|| ' ' ||T.DESCRIPCION_ITEM,
          T.OBSERVACIONES,
          NVL(T.UVR_H_MED,T.UVR),
          T.ANES UVR_ANES,
          T.PRC,
          T.PRC_ANES,
          T.TIPO,
          T.NO_APLICA_TIEMPO
     FROM TARIFARIOS T,CG_REF_CODES C,GRUPOS_TARIFARIO GT,SUBGRUPOS_TARIFARIO ST,
          SUBGRUPOS_1_TARIFARIO S1T,SUBGRUPOS_2_TARIFARIO S2T
     WHERE C.RV_DOMAIN =  'TIPO_TARIFARIO' AND
           C.RV_LOW_VALUE = T.TIPO AND
           T.CONVENIO = GT.CONVENIO AND
           T.TIPO = GT.TIPO AND
           GT.CODIGO = T.CODIGO_GRUPO AND
           T.CONVENIO = ST.CONVENIO (+)AND
           T.TIPO = ST.TIPO(+) AND
           ST.CODIGO(+) = T.CODIGO_SUBGRUPO AND
           T.CONVENIO = S1T.CONVENIO(+) AND
           T.TIPO= S1T.TIPO(+) AND
           S1T.CODIGO(+) = T.CODIGO_SUBGRUPO_1 AND
           T.CONVENIO = S2T.CONVENIO(+) AND
           T.TIPO= S2T.TIPO(+) AND
           S2T.CODIGO(+) = T.CODIGO_SUBGRUPO_2 AND
           T.TIPO <> 'P'  AND
      	   T.TIPO <> 'H' AND
       	   T.TIPO <> 'C' AND
           T.TIPO <> 'S' AND
           T.TIPO <> 'A' AND
           T.TIPO <> 'X'
UNION ALL
   SELECT DISTINCT T.CONVENIO CONVENIO,
          C.RV_MEANING  DISCRIMINADOR_HOJA,
          T.CODIGO_ITEM,
          UPPER(T.DESCRIPCION_ITEM) DESCRIPCION,
          T.CODIGO_GRUPO||' '||GT.DESCRIPCION||
          CHR (13) || CHR (10) || CHR (9) ||
          DECODE(NVL(T.CODIGO_SUBGRUPO,'NULO'),
                'NULO','',
                T.CODIGO_SUBGRUPO||' '||ST.DESCRIPCION||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(T.CODIGO_SUBGRUPO_1,'NULO'),
                 'NULO','',
                 T.CODIGO_SUBGRUPO_1||' '||S1T.DESCRIPCION||CHR (13) || CHR (10) || CHR (9) ||CHR (9) )||
          DECODE (NVL(T.CODIGO_SUBGRUPO_2,'NULO'),
                 'NULO','',
                 T.CODIGO_SUBGRUPO_2|| ' '||S2T.DESCRIPCION||CHR (13) || CHR (10) || CHR (9) ||CHR (9)||CHR (9)) ||
         T.CODIGO_ITEM|| ' ' ||T.DESCRIPCION_ITEM,
          T.OBSERVACIONES,
          NVL(T.UVR_H_MED,T.UVR3),
          T.ANES UVR_ANES,
          T.PRC3,
          T.PRC_ANES,
          T.TIPO,
          T.NO_APLICA_TIEMPO
     FROM TARIFARIOS T,CG_REF_CODES C,GRUPOS_TARIFARIO GT,SUBGRUPOS_TARIFARIO ST,
          SUBGRUPOS_1_TARIFARIO S1T,SUBGRUPOS_2_TARIFARIO S2T
     WHERE C.RV_DOMAIN =  'TIPO_TARIFARIO' AND
           C.RV_LOW_VALUE = T.TIPO AND
           T.CONVENIO = GT.CONVENIO AND
           T.TIPO = GT.TIPO AND
           GT.CODIGO = T.CODIGO_GRUPO AND
           T.CONVENIO = ST.CONVENIO AND
           T.TIPO = ST.TIPO AND
           ST.CODIGO = T.CODIGO_SUBGRUPO AND
           T.CONVENIO = S1T.CONVENIO(+) AND
           T.TIPO= S1T.TIPO(+) AND
           S1T.CODIGO(+) = T.CODIGO_SUBGRUPO_1 AND
           T.CONVENIO = S2T.CONVENIO(+) AND
           T.TIPO= S2T.TIPO(+) AND
           S2T.CODIGO(+) = T.CODIGO_SUBGRUPO_2 AND
           (T.TIPO =  'C' OR T.TIPO =  'S' OR T.TIPO =  'X')

