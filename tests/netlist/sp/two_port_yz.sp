* ngspice's .sp columns on a two-port with unequal z0: the probes of the last port's
* drive, S, Y and Z, in that order; no donoise, so the
* sweep is the one a GPU lane precomputes.
* Expected results: two_port_yz.expected.json
V1 p1 0 dc 0 portnum 1 z0 50
V2 p2 0 dc 0 portnum 2 z0 75
R1 p1 x 20
R2 x 0 100
C3 x p2 2e-09
R4 p2 0 200
.sp dec 2 1e+06 1e+08
.end
