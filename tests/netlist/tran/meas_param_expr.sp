* .meas PARAM= and par() as ngspice reads them. ngspice evaluates a PARAM=
* card with numparam after every other card, over the .param scope and the
* results so far (measure.c:407-498, nupa_eval): .func calls, built-ins,
* comparisons, logic and ?: all apply, and an earlier card's name reads its
* result. par('expr') is a B source's expression (manual 11.6), so `time`
* is the scale. ngspice-examples func_cap.sp and the gf180 cmcqa decks'
* `find par('... time / v(p) ...')` were dropped with a warning before.
* Expected results: meas_param_expr.expected.json
* Oracle (analytic): icap_calc(1,2,3,4) = 2*sqrt(24) = 4*sqrt(6), and one
* argument max(x) is MAX(x, 1) in numparam (xpressn.c:142-146, 921), so
* cap_val = 4*sqrt(6). A constant I = 10 uA into C = cap_val nF from
* v = 0 gives the exact ramp v(p) = I t / C (trap and BE integrate a
* constant current exactly; WHEN interpolates a line exactly). So
* t1 = 0.5 C / I, cv = (I t / v(p)) * 1e9 = C * 1e9 = cap_val,
* ratio = t1 / capac2 = 0.5e-9 / I = 5e-5, mix = icap_calc(1,1,1,1) t1 =
* 2 t1, fast = (t1 < 0.5m) = 1 as t1 = 0.4899m, slow = 0 and both = 1.
.func icap_calc(a,b,c,d) '2*a*sqrt(b*c*d)'
.param cap_val = 'max(icap_calc(1,2,3,4))'
ich 0 p dc 10u
cp p 0 'cap_val*1n'
.ic v(p)=0
.tran 1u 1m
.meas tran capacitance param='cap_val'
.meas tran capac2 param='max(icap_calc(1,2,3,4))'
.meas tran t1 when v(p)=0.5
.meas tran cv find par('(10u*time/v(p))*1e9') at=0.8m
.meas tran ratio param='t1/capac2'
.meas tran mix param='icap_calc(1,1,1,1)*t1'
.meas tran fast param='(t1 < 0.5m) ? 1 : 0'
.meas tran slow param='(t1 >= 0.5m) ? 1 : 0'
.meas tran both param='t1 > 0 && !(t1 > 1m)'
.end
