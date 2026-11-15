* HSPICE's unary `!`: its manual's operator table (UG08 pp. 279-283) lists
* `!=` but no logical not, yet HSPICE reads it: `.param rv='1k*(!0)'` loads
* and evaluates `!0` to 1 (measured on HSPICE Y-2026.03-SP2-1 with a
* SPRack-written deck, 2026-11-15). So the deck runs: 1 V across 1k.
* Expected results: hspice_unary_not.expected.json
v1 a 0 1
r1 a 0 '1k*(!0)'
.op
.end
