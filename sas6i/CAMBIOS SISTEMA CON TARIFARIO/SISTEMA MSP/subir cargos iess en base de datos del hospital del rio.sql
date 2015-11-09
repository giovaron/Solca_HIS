begin
declare
cargo varchar2(20):= null;
 cursor cargos 
is select c.tipo,c.codigo,c.descripcion,c.costo,c.iva,c.estado_de_disponibilidad,
   c.costo_modificable,c.dpr_codigo,c.dpr_ara_codigo,c.equipo_especial,
   c.agrupador_contable,c.agrcnt_codigo,c.agrcnt_tipo,c.tiempo,c.factor,
   c.rango_minimo,c.RANGO_MAXIMO,c.OPERADOR,c.CANTIDAD_MINIMA,c.EMP_CODIGO,
   c.TIPO_HONORARIO,c.MAXIMO_DESCUENTO,c.NOMBRE_IESS,c.CODIGO_IESS,c.GOBIERNO,
   c.ANESTESIA_IESS,c.IESS from cargos_iess c;
begin
for c in cargos loop
cargo := null;
begin
insert into cargos(tipo,codigo,descripcion,costo,iva,estado_de_disponibilidad,
   costo_modificable,dpr_codigo,dpr_ara_codigo,equipo_especial,
   agrupador_contable,agrcnt_codigo,agrcnt_tipo,tiempo,factor,
   rango_minimo,RANGO_MAXIMO,OPERADOR,CANTIDAD_MINIMA,EMP_CODIGO,
   TIPO_HONORARIO,MAXIMO_DESCUENTO,NOMBRE_IESS,CODIGO_IESS,GOBIERNO,
   ANESTESIA_IESS,IESS) 
values( c.tipo,c.codigo,c.descripcion,c.costo,c.iva,c.estado_de_disponibilidad,
   c.costo_modificable,c.dpr_codigo,c.dpr_ara_codigo,c.equipo_especial,
   c.agrupador_contable,c.agrcnt_codigo,c.agrcnt_tipo,c.tiempo,c.factor,
   c.rango_minimo,c.RANGO_MAXIMO,c.OPERADOR,c.CANTIDAD_MINIMA,c.EMP_CODIGO,
   c.TIPO_HONORARIO,c.MAXIMO_DESCUENTO,c.NOMBRE_IESS,c.CODIGO_IESS,c.GOBIERNO,
   c.ANESTESIA_IESS,c.IESS);
exception
when others then
  dbms_output.put_line('No se puede crear el cargo '||c.codigo||sqlerrm) ;
end; 
end loop;  
end;   
end;
   
   