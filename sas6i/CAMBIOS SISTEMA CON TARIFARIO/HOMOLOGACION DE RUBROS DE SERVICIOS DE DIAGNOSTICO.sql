BEGIN
declare 
cargo varchar2(10):= null;
cursor cargos IS
SELECT C.CODIGO,C.TIPO FROM CARGOS C
WHERE C.GOBIERNO = 'V' AND
SUBSTR(C.CODIGO,1,1)<> 'C' AND
SUBSTR(C.CODIGO,1,1)<> 'H' AND
(C.TIPO,C.CODIGO) NOT IN (SELECT CE.CRG_TIPO,CE.CRG_CODIGO FROM CONVENIOS_EQUIVALENCIAS CE 
                          WHERE CE.CNVTRF_CONVENIO = 'MSPJUN2011');
begin
for rcargos in cargos loop
CARGO := RCARGOS.CODIGO;
BEGIN
INSERT INTO CONVENIOS_EQUIVALENCIAS (CRG_CODIGO,CRG_TIPO,CNVTRF_CONVENIO,CNVTRF_CODIGO,TIPO,PRIORIDAD_CARGO)
VALUES (rcargos.CODIGO,rcargos.TIPO,'MSPJUN2011',rcargos.CODIGO,'X','F'); 
EXCEPTION
WHEN OTHERS THEN
   DBMS_OUTPUT.put_line('No se pudo homologar el cargo '||cargo||sqlerrm );                          
END;   
END LOOP;   
END; 
end;                          
                          