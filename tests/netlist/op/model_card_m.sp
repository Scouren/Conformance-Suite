A .model card's m is never the instance multiplier
* Expected results: model_card_m.expected.json
* ngspice sets a .model card key through the device's model table first.
* There `m` is a shape: the diode's grading coefficient (dio.c:71), the
* HFET and MESA knee (hfet.c:59, hfet2.c:68, mesa.c:72). Every other
* device here has `m` only in its instance table, as the multiplier, and
* inpgmod.c:140-145 reads a .model card's `m` and drops it. So each
* multiplier device carries m=3 on its .model card and still gives one
* device's current; the shape devices carry m away from its default.
* One device per drain source, every terminal pinned.
vg g 0 1.5
vb b 0 0.75
vgj gj 0 -0.5
vgz gz 0 0
v1 d1 0 2
m1 d1 g 0 0 c1 w=10u l=2u
.model c1 nmos level=1 vto=0.7 kp=1e-4 m=3
v2 d2 0 2
m2 d2 g 0 0 c2 w=10u l=2u
.model c2 nmos level=2 vto=0.7 kp=1e-4 m=3
v3 d3 0 2
m3 d3 g 0 0 c3 w=10u l=2u
.model c3 nmos level=3 vto=0.7 kp=1e-4 m=3
v4 d4 0 2
m4 d4 g 0 0 c4 w=10u l=2u
.model c4 nmos level=4 vfb=-0.3 phi=0.65 k1=0.5 k2=-0.1 eta=0.02 muz=600 u0=0.05 u1=0.01 tox=40n dl=0 dw=0 x2mz=0 x2u0=0 x2u1=0 x3u1=0 m=3
v5 d5 0 2
m5 d5 g 0 0 c5 w=10u l=2u
.model c5 nmos level=5 m=3
v6 d6 0 2
m6 d6 g 0 0 c6 w=10u l=2u
.model c6 nmos level=6 vto=0.7 kv=2 nv=0.5 kc=5e-5 nc=1 m=3
v8 d8 0 2
m8 d8 g 0 0 c8 w=10u l=2u
.model c8 nmos level=8 m=3
v9 d9 0 2
m9 d9 g 0 0 c9 w=10u l=2u
.model c9 nmos level=9 vto=0.7 kp=1e-4 m=3
v55 d55 0 1.8
m55 d55 g 0 0 c55 w=10u l=0.18u
.model c55 nmos level=55 version=2 tnom=27 tox=4.1e-9 vth0=0.35 k1=0.53 k2=-0.06 kb1=1 vsat=1.5e5 u0=280 rdsw=200 m=3
v56 d56 0 1.8
m56 d56 g 0 0 c56 w=10u l=0.18u
.model c56 nmos level=56 version=2 tnom=27 tox=4.1e-9 vth0=0.35 k1=0.53 k2=-0.06 kb1=1 vsat=1.5e5 u0=280 rdsw=200 m=3
vq dq 0 2
q1 dq b 0 cq
.model cq npn is=1e-16 bf=100 m=3
vj1 dj1 0 2
j1 dj1 gj 0 cj1
.model cj1 njf level=1 vto=-1.5 beta=1e-3 m=3
vj2 dj2 0 2
j2 dj2 gj 0 cj2
.model cj2 njf level=2 vto=-1.5 beta=1e-3 m=3
vz1 dz1 0 2
z1 dz1 gz 0 cz1
.model cz1 nmf level=1 vto=-1.5 beta=2m alpha=2 lambda=5m m=3
vz2 dz2 0 2
z2 dz2 gz 0 cz2
.model cz2 nmf level=2 vto=-1.5 beta=2m alpha=2 lambda=5m rd=10 rs=10 m=2
vz5 dz5 0 2
z5 dz5 gz 0 cz5
.model cz5 nhfet level=5 vto=0.15 lambda=0.15 mu=0.4 di=4e-8 delta=3 vs=1.5e5 eta=1.28 m=2 sigma0=0.057
vz6 dz6 0 2
z6 dz6 gz 0 cz6
.model cz6 nhfet level=6 vto=0.15 lambda=0.15 mu=0.4 di=4e-8 delta=3 vs=1.5e5 eta=1.28 m=2 sigma0=0.057
vd dd 0 0.65
d1 dd 0 cd
.model cd d is=1e-14 rs=10 cjo=1p m=0.3
.op
.end
