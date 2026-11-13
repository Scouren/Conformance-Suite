* VDMOS quasi-saturation: with RQ and VQ both given, the drain resistance
* grows with the external vds as rd0 + rq*vds/(vds + |vq|), forward mode
* only (vdmosset.c:217-218, vdmosload.c:416-432). rq scales by
* (T/TNOM)^TEXP1 (default 0.3) and 1/m; RD by (T/TNOM)^TEXP0 when TEXP0 is
* given, else by its TRD1/TRD2 polynomial; RS ignores TEXP1 (vdmostemp.c:
* 54-64). m4 carries TEXP0, TEXP1 and RS. The sweep starts in reverse
* mode, where RQ is off.
* Expected results: vdmos_quasi_saturation.expected.json (ngspice-44.2;
* ngspice 45 gives the same bytes, THETA = 0)
* vdmos.va's old law, a series RQ/(1 + |vds|/VQ), read m1 37% low at 0.5 V
* and 1.8% high at 20 V.
.options reltol=1e-6 abstol=1e-15 vntol=1e-9
vd d 0 0
vg g 0 5
va d d1 0
vb d d2 0
vc d d3 0
ve d d4 0
m1 d1 g 0 vq
m2 d2 g 0 vq m=2
m3 d3 g 0 vq temp=100
m4 d4 g 0 vt temp=100
.model vq vdmos vto=2 kp=1 lambda=0.01 rd=0.05 rq=0.5 vq=2 trd1=5m
.model vt vdmos vto=2 kp=1 lambda=0.01 rd=0.05 rs=0.02 rq=0.5 vq=2 trd1=5m texp0=1 texp1=0.5 trs1=2m
.dc vd -0.5 20 0.5
.end
