* Autonomous HB (`.hb v(osc) f K`) finds a ring oscillator's frequency
* Expected results: ring_oscillator.expected.json
* Respelled from `.hbosc v(c1) 300k 15`, same job.
R1 x1 c1 1k
C1 c1 0 1n
R2 x2 c2 1k
C2 c2 0 1n
R3 x3 c3 1k
C3 c3 0 1n
B1 x1 0 V=-tanh(3*V(c3))
B2 x2 0 V=-tanh(3*V(c1))
B3 x3 0 V=-tanh(3*V(c2))
.hb v(c1) 300k 15
.end
