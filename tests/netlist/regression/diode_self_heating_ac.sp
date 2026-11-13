* A self-heated diode's junction rise in AC is one thermal pole.
* Expected results: diode_self_heating_ac.expected.json (analytic)
* Oracle: analytic, not an ngspice golden. ngspice 44.2 and 45 stamp the
* thermal capacitance in AC as the capacitor's current times omega
* (dioacld.c at e1bd97d8, lines 61-62), zero after an operating point, so
* they print vm(tj) = 131.79097510 flat from 1 mHz to 1 kHz. With cjo = tt
* = 0 the thermal capacitance is the only storage, so
* v(tj) = H0 / (1 + j*2*pi*f*cth0*R), H0 = dT/dv1 and R = dT/dP_tj, both
* central differences of ngspice 44.2 DC solutions (reltol=1e-12;
* derivation in the .expected.json). Corner 0.673 Hz.
.temp 27
.options reltol=1e-9 abstol=1e-16 vntol=1e-12
v1 1 0 dc 0.75 ac 1
dsh 1 0 tj dmod thermal
.model dmod d (is=1e-14 rs=0.5 rth0=200 cth0=1e-3 tnom=27 trs=2e-3)
.ac dec 2 1m 1k
.end
