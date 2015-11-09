LOAD DATA
INFILE 'plncnt.txt'
BADFILE 'plncnt.bad'
INTO TABLE CUENTAS_A_SUBIR
FIELDS TERMINATED BY '{'
(cuenta,descripcion)
