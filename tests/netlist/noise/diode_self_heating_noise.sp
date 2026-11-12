* A self-heated diode's noise below its thermal corner.
* Expected results: diode_self_heating_noise.expected.json (ngspice-44.2)
* RS thermal noise takes the heated conductance at the instance ambient
* (dionoise.c:88-95), shot noise the heated current, and the junction
* rise (2.45 K) feeds back through the thermal row. CTH0 = 1e-9 puts the
* thermal corner near 0.8 MHz, so up to 1 kHz the pole ngspice 44.2 leaves
* out of AC and noise moves the answer by under 1e-5.
.temp 27
.options reltol=1e-9 abstol=1e-16 vntol=1e-12
v1 in 0 dc 0.9 ac 1
rsrc in 1 10
dsh 1 0 tj dmod thermal
.model dmod d (is=1e-14 rs=0.5 rth0=200 cth0=1e-9 tnom=27 trs=2e-3)
.noise v(1) v1 dec 3 1 1k
.end
