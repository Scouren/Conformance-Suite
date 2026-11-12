* A Y card's length= is not its length: inp2y.c reads only `len` after the
* model name, so ngspice 44.2 runs this line with its model's length=1 and
* ignores the card's length=2. ESPice reads only len= too and warns once
* ("length= is ignored on a Y card, as ngspice ignores it; use len=").
* R/L = 4e4 < 5e5 and G = 0 make ReadTxL's lossless line (txlsetup.c), so
* r enters only the DC row, whose operating point is zero.
* Z0 = sqrt(250n/100p) = 50 ohm, sqrt(L C) = 5 ns/m, matched 50 ohm ends:
* the far end is the near end's 0.5 V delayed by 5 ns (1 m), not 10 ns (2 m).
*   t = 3 ns: v(o) = 0      t = 8 ns: v(o) = 0.5 (2 m would read 0)
*   t = 12 ns: v(o) = 0.5
* ngspice's 0.1 gmin port stamp (txlload.c:62-73) leaves -1.25e-12 V before
* the wave arrives.
* Expected results: txl_tran_card_length_ignored.expected.json
V1 s 0 PULSE(0 1 0 0.1n 0.1n 100n 200n)
Rs s i 50
Y1 i 0 o 0 ymod length=2
RL o 0 50
.model ymod txl r=0.01 l=250n g=0 c=100p length=1
.tran 0.1n 15n 0 0.1n
.meas tran o_3 find v(o) at=3n
.meas tran o_8 find v(o) at=8n
.meas tran o_12 find v(o) at=12n
.end
