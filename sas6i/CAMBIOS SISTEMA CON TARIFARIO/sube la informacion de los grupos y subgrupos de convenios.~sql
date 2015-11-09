insert into grupos_tarifario(convenio,tipo,codigo,descripcion)
select distinct t.convenio,t.tipo,t.codigo_grupo,t.descripcion_grupo
from tarifarios_con_grupos t
/

insert into subgrupos_tarifario(convenio,tipo,grptrf_codigo,codigo,descripcion)
select distinct t.convenio,t.tipo,t.codigo_grupo,t.codigo_subgrupo,t.descripcion_subgrupo
from tarifarios_con_grupos t 
WHERE T.codigo_subgrupo IS NOT NULL 
ORDER BY T.tipo,T.codigo_grupo,T.codigo_subgrupo
/

insert into subgrupos_1_tarifario(convenio,tipo,sbgtrf_grptrf_codigo,sbgtrf_codigo,codigo,descripcion)
select distinct t.convenio,t.tipo,t.codigo_grupo,t.codigo_subgrupo,t.codigo_sbgrupo_1,t.descripcion_subgrupo_1
from tarifarios_con_grupos t 
WHERE T.codigo_sbgrupo_1 IS NOT NULL  
ORDER BY T.tipo,T.codigo_grupo,T.codigo_subgrupo
/

insert into subgrupos_2_tarifario(convenio,tipo,sbg1trf_grptrf_codigo,sbg1trf_sbgtrf_codigo,sbg1trf_codigo,codigo,descripcion)
select distinct t.convenio,t.tipo,t.codigo_grupo,t.codigo_subgrupo,t.codigo_sbgrupo_1,T.codigo_subgrupo_2,t.descripcion_subgrupo_2
from tarifarios_con_grupos t 
WHERE T.codigo_subgrupo_2 IS NOT NULL  
ORDER BY T.tipo,T.codigo_grupo,T.codigo_subgrupo,T.codigo_sbgrupo_1,T.codigo_subgrupo_2
/