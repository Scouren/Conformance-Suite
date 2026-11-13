* PPV phase noise of a Van der Pol LC oscillator
* Expected results: lc_oscillator.expected.json
* Respelled from `.hbosc v(t) 1meg 7`, same job.
L1 t 0 25.330296u
C1 t 0 1n
R1 t 0 10k
Bneg t 0 I=-7e-4*V(t)+8e-4*V(t)*V(t)*V(t)
.hb v(t) 1meg 7
.phasenoise v(t) dec 2 1k 1meg
.end
