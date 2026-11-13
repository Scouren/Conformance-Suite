* An ngspice .probe of a device current is refused naming the card. ngspice
* inserts a 0 V source per probed terminal and writes i(r1)
* (inpc_probe.c:728-870). ESPice builds no such source, and it used to drop
* the card, which lost the vector (ngspice-examples probe/*.sp,
* F5TurboV2-Probe.sp). Legal neighbour: `.probe v(a)` (tests/cards.zig).
v1 a 0 1
r1 a 0 1k
.probe i(r1)
.op
.end
