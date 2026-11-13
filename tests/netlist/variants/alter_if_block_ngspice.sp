* HSPICE .alter runs re-select .if blocks: each run's condition reads the
* ngspice twin of variants/alter_if_block.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* .param an .alter block appended, a parameter's last definition (UG
* E-2010.12 p. 84, p. 110). VACASK test/test_cblock.sim in HSPICE form
* (SpiceRack #9, hcb.sp); the blocks accumulate.
* Oracle: analytic, i(v1) = -10 V/R for the resistors each state keeps:
*   a=1: R1 1k; a=2 b=0: R1 2k; a=3: R1a || R1b = 500; a=4: R1 4k;
*   a=2 b=1: R1 2k || R1a 2k || R1b 1k || R1c 500 = 250; a=2 b=0: 2k.
* Expected results: alter_if_block_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
.param a=1
.param b=0
V1 1 0 10
.if (a==1)
R1 1 0 1k
.elseif (a==2)
R1 1 0 2k
.if (b==1)
R1a 1 0 2k
R1b 1 0 1k
R1c 1 0 500
.endif
.elseif (a==3)
R1a 1 0 1k
R1b 1 0 1k
.else
R1 1 0 4k
.endif
.op
.alter
.param a=2 b=0
.alter
.param a=3 b=0
.alter
.param a=4 b=0
.alter
.param a=2 b=1
.alter
.param a=2 b=0
.end
