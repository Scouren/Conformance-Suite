* Three-port resistive star with a shunt capacitor: ngspice .sp donoise=1 Cy over three ports
* Expected results: star3_donoise.expected.json
Vp1 p1 0 0 AC 1 portnum 1 z0 50
Vp2 p2 0 0 portnum 2 z0 50
Vp3 p3 0 0 portnum 3 z0 75
R1 p1 c 50
R2 p2 c 100
R3 p3 c 25
C1 c 0 10n
.sp lin 3 1meg 2meg 1
.end
