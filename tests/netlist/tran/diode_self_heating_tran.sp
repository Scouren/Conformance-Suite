* A self-heated diode's junction heats through its thermal RC.
* Expected results: diode_self_heating_tran.expected.json (ngspice-44.2)
* A 20 mA step at 1 ms; v(tj) rises over rth0*cth0 = 0.2 s toward
* rth0 times the power, which falls as the junction heats. The thermal
* charge stays out of the LTE (diotrunc.c:23). cjo = tt = 0, so the
* charging heat dioload.c:708 adds is zero here.
.temp 27
.options reltol=1e-6 abstol=1e-14 vntol=1e-9 method=gear
i1 0 1 pwl(0 0 1m 0 1.001m 20m)
dsh 1 0 tj dmod thermal
.model dmod d (is=1e-14 n=1 rs=0.5 rth0=200 cth0=1e-3 tnom=27)
.save v(1) v(tj)
.tran 1m 1 0 1m
.end
