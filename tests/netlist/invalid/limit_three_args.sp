* A three-argument limit(x, a, b) is PSPICE's clamp, which only ngspice's
* PSPICE mode defines (inpcompat.c:692-695); plain ngspice's numparam
* limit(nom, var) takes two arguments (xpressn.c:81-85). ESPice refuses
* the card by name (UnsupportedCard) and asks for the deck in ngspice's
* dialect (SpiceRack translates it). Measured: ngspice-44.2 prints
* v(p) = -0.75 here, nom - var with var the last argument, and the ESPice
* binary of 2026-11-10 read v(p) = 0 with no diagnostic.
* Expected results: limit_three_args.expected.json
.param p={limit(0.25, 0, 1)}
vp p 0 {p}
rp p 0 1
.op
.end
