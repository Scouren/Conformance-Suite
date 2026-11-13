* A diode given a thermal node, the thermal flag and rth0 heats itself.
* Expected results: diode_self_heating.expected.json (ngspice-44.2)
* Origin: reduced from ngspice examples/soa/diode-soa-simple.sp
* (ngspice-35): its Dth1 with the SOA limits left off. ngspice heats a
* diode given a thermal node, the `thermal` flag and rth0 (dioload.c:77);
* v(tj) is the junction's rise over the 100 degC ambient (dioload.c:331),
* held toward the 27 V node tamb through rtj. ESPice builds the card as
* diode_t, diode.va under SELFHEATING.
.temp 100
.options reltol=1e-6 abstol=1e-15 vntol=1e-9

vtamb tamb 0 27
v1 1 0 0.7
r1 1 0 100
dth1 1 0 tj dmod1 thermal
rtj tj tamb 100
.model dmod1 d (rs=200m bv=21 rth0=1e6 tnom=25)

.dc v1 0.02 0.9 0.02
.end
