* An E card's VALUE={...} SCALE= is HSPICE's and is refused: plain ngspice-44.2
* stops on it ("Undefined parameter [scale]"), and SpiceRack writes the ngspice
* form, value={3*(2*v(a))} (hspice/value_modifier.sp runs that route).
* Expected results: value_scale.expected.json
va a 0 0.5
e1 o1 0 value={2*v(a)} scale=3
r1 o1 0 1k
.op
.end
