insert into tarifarios (convenio,tipo,codigo_grupo,codigo_subgrupo,codigo_subgrupo_1,codigo_item,
descripcion_item,unidades)
select m.convenio,m.tipo,m.codigo_grupo,m.codigo_subgrupo,m.codigo_subgrupo_1,m.codigo_item,
m.descripcion_item,m.unidades from msp_anestesia m
/

insert into tarifarios(convenio, tipo, codigo_grupo, codigo_subgrupo, codigo_subgrupo_1, codigo_subgrupo_2, codigo_item, descripcion_item, prc, uvr,descripcion_especifica)
select ma.convenio, ma.tipo, ma.codigo_grupo, ma.codigo_subgrupo, ma.codigo_subgrupo_1, ma.codigo_subgrupo_2, ma.codigo_item, ma.descripcion_item,
ma.pcr,ma.uvr,ma.descripcion_especifica
from msp_servicio_ambulancias ma
/

insert into tarifarios(convenio, tipo, codigo_grupo, codigo_subgrupo, codigo_subgrupo_1, descripcion_especifica, codigo_item, descripcion_item, prc, uvr, nivel,Obsrvaciones)
select mb.convenio, mb.tipo, mb.codigo_grupo, mb.codigo_subgrupo, mb.codigo_subgrupo_1, mb.descripcion_especifica, mb.codigo_item, mb.descripcion_item, mb.pcr, mb.uvr, mb.nivel, mb.observacion
from msp_servicios_hoteleria mb
/

insert into tarifarios(convenio, tipo, codigo_grupo, codigo_subgrupo, codigo_item, descripcion_item, prc, uvr)
select mc.convenio, mc.tipo, mc.codigo_grupo, mc.codigo_subgrupo, mc.codigo_item, mc.descripcion_item, mc.pcr, mc.uvr
from msp_visitas_domiciliarias mc
/

insert into tarifarios(convenio, tipo, codigo_grupo, codigo_subgrupo, codigo_subgrupo_1, descripcion_especifica, codigo_item, descripcion_item, prc, uvr_h_med, anes,obsrvaciones)
select md.convenio, md.tipo, md.codigo_grupo, md.codigo_subgrupo, md.codigo_subgrupo_1, md.descripcion_especifica, md.codigo_item, md.descripcion_item, md.pcr, md.uvr_h_med, md.uvr_anes, md.observacion
from msp_componente_medicina md
/

insert into tarifarios(convenio, tipo, codigo_grupo, codigo_subgrupo_1, descripcion_especifica, codigo_item, descripcion_item, prc, uvr_h_med, anes, observaciones)
select me.convenio, me.tipo, me.codigo_grupo, me.codigo_subgrupo_1, me.descripcion_especifica, me.codigo_item, me.descripcion_item, me.pcr, me.uvr_h_med, me.uvr_anes, me.observacion
from msp_radiologia me
/

insert into tarifarios(convenio, tipo, codigo_grupo, codigo_subgrupo, codigo_subgrupo_1, codigo_item, descripcion_item, prc, uvr, observaciones)
select mf.convenio, mf.tipo, mf.codigo_grupo, mf.codigo_subgrupo, mf.codigo_subgrupo_1, mf.codigo_item, mf.descripcion_item, mf.pcr, mf.uvr, mf.observacion
from msp_evaluacion_y_manejo mf
/

insert into tarifarios(convenio, tipo, codigo_grupo, codigo_subgrupo, codigo_subgrupo_1, codigo_item, descripcion_item, prc, uvr1, uvr2, uvr3, observaciones)
select mh.convenio, mh.tipo, mh.codigo_grupo, mh.codigo_subgrupo, mh.codigo_subgrupo_1, mh.codigo_item, mh.descripcion_item, mh.pcr, mh.uvr1, mh.uvr2, mh.uvr3, mh.observacion
from msp_serv_dx_ex_proc mh
/

insert into tarifarios(convenio, tipo, codigo_grupo, codigo_subgrupo, codigo_subgrupo_1, codigo_item, descripcion_item, prc, uvr1, uvr2, uvr3)
select mi.convenio, mi.tipo, mi.codigo_grupo, mi.codigo_subgrupo, mi.codigo_subgrupo_1, mi.codigo_item, mi.descripcion_item, mi.pcr, mi.uvr1, mi.uvr2, mi.uvr3
from msp_servicios_odontologicos mi
/

insert into tarifarios (convenio, tipo, codigo_grupo, codigo_subgrupo, codigo_subgrupo_1, codigo_subgrupo_2, descripcion_especifica, codigo_item, descripcion_item, uvr_h_med, anes, uvr1, uvr2, uvr3, prc, prc1, prc2, prc3, observaciones)
select mj.convenio, mj.tipo, mj.codigo_grupo, mj.codigo_subgrupo, mj.codigo_subgrupo_1, mj.codigo_subgrupo_2, mj.descripcion_especifica, mj.codigo_item, mj.descripcion_item, mj.uvr_h_med, mj.anes, mj.uvr1, mj.uvr2, mj.uvr3, mj.prc, mj.prc1, mj.prc2, mj.prc3, mj.observaciones
from msp_cirugia mj
/

insert into tarifarios(CODIGO_GRUPO,CODIGO_SUBGRUPO,CODIGO_SUBGRUPO_1,DESCRIPCION_ESPECIFICA,
CODIGO_ITEM,DESCRIPCION_ITEM,PRC,UVR1,UVR3,TOTAL_TARIFA_INTEGRAL,TOTAL_TARIFA_INTEGRAL_III,obsErvaciones,
CONVENIO,TIPO)
select CODIGO_GRUPO,CODIGO_SUBGRUPO,CODIGO_SUBGRUPO_1,DESCRIPCION_ESPECIFICA,
CODIGO_ITEM,DESCRIPCION_ITEM,PCR,UVR1,UVR3,TOTAL_TARIFA_INTEGRAL,TOTAL_TARIFA_INTEGRAL_III,OBSERVACION,
CONVENIO,TIPO from MSP_PRESTACIONES_INTEGRALES
/