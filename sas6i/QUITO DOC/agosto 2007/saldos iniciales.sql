SELECT p.codigo,p.nombre,s.debe,s.haber
FROM PLAN_DE_CUENTAS_COMPLETO P, SALDOS S
WHERE P.emp_codigo=S.SS_S_A_SC_CNT_MYR_EMP_CODIGO
and p.myr_codigo=s.ss_s_a_sc_cnt_myr_codigo
and p.cnt_codigo=s.ss_s_a_sc_cnt_codigo
and p.scnt_codigo=s.ss_s_a_sc_codigo
and p.axl_codigo=s.ss_s_a_codigo
and p.saxl_codigo=s.ss_s_codigo
and p.saxl2_codigo=s.ss_codigo
and p.saxl3_codigo=s.s_codigo
and s.fecha=to_date('01/01/2007','dd/mm/yyyy')
and s.estado='I'
order by codigo