* A diode's tunnelling currents (JTUN, JTUNSW) flow in reverse bias.
* Expected results: diode_tunnelling.expected.json (ngspice-44.2)
* Origin: gf180mcu sm141064.ngspice's np_3p3 card (jsa = 1), reduced to
* its DC keys at gf180's diode deck geometry. ngspice adds the bottom and
* sidewall tunnel currents, jtun scaled by area and jtunsw by pj
* (dioload.c:352-372). ESPice once dropped both keys with no word (6e-12 A
* at 6 V where ngspice draws 1.66e-5 A), then refused the card.
.options reltol=1e-6 abstol=1e-15 vntol=1e-9
v1 a 0 0
d1 0 a dnp area=100p pj=40u
.model dnp d level=3 tref=25 is=2.2959e-7 jsw=2.1207e-13 n=1.01 bv=11 ibv=1e-3
+ jtun=1.1223e-5 jtunsw=6.4125e-12 ntun=10 xtitun=-25
.dc v1 0 6 0.25
.end
