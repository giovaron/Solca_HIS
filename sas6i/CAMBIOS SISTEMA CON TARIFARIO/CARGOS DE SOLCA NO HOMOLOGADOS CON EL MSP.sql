SELEct * from
cargos c
where c.codigo_iess is not null and
C.ESTADO_DE_DISPONIBILIDAD = 'D' AND
NVL(C.GOBIERNO,'F') = 'F' AND
NVL(C.IESS,'F') = 'F' AND 
c.codigo_iess  NOT in
(select T.CODIGO_ITEM from tarifarios t
where t.convenio = 'MSPJUN2011' )