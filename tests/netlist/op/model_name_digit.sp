* A model name that reads as a number names the model. ngspice looks the
* word after a D, J, Q or M card's nodes up as a model before anything
* reads it as a number (inp2d.c:47-51, inp2j.c:47-49, inp2q.c:56-60,
* inp2m.c:76-84). ESPice read 1N4148 as 1e-9, 2SK170 as 2: a D card ran a
* default diode (v(b) 0.6294 instead of 0.5482) and a J, Q or M card was
* refused as UnsupportedDevice (ngspice-examples F5TurboV2-Probe.sp).
* Each model differs from its device's defaults, so a dropped one shows.
* Expected results: model_name_digit.expected.json
v1 a 0 1
r1 a b 1k
d1 b 0 1N4148
vd d 0 5
vg g 0 -0.2
rj d dj 100
j1 dj g 0 2SK170
vc c 0 5
rc c cq 1k
rb c bq 1meg
q1 cq bq 0 2N2222
vm dm 0 5
vgm gm 0 3
rm dm dmm 1k
m1 dmm gm 0 0 2N7000
.model 1N4148 D(is=2.52n n=1.752)
.model 2SK170 NJF(beta=59.86m vto=-0.5024)
.model 2N2222 NPN(is=1e-14 bf=100)
.model 2N7000 NMOS(level=1 vto=1 kp=1m)
.op
.end
