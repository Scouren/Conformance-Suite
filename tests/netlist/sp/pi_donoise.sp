* Matched 6.0206 dB pi attenuator: ngspice .sp donoise=1 noise correlation and NF
* Expected results: pi_donoise.expected.json
Vp1 a 0 0 AC 1 portnum 1 z0 50
R1 a 0 150
R2 a b 37.5
R3 b 0 150
Vp2 b 0 0 portnum 2 z0 50
.sp dec 3 1k 1meg 1
.end
