* CPL (P card): the card's LEN= is the line's length, over the model's
* length= (ngspice-45 manual 6.4.2, "len will override the model parameter
* length for the specific instance only"; inp2p.c reads `length` or `len`,
* cplsetup.c:483-485 takes the instance's). SpiceRack P8-049: ESPice read
* LEN= and kept the model's 1 m.
* A symmetric lossless pair, 50 ohm at all four ends, a 1 V step into line 1:
* half the step rides the odd mode (L11-L12, C11-C12), half the even mode
* (L11+L12, C11+C12). Mode m travels sqrt(L C) per metre in Z = sqrt(L/C)
* and arrives at a far end as 50 Z/(50+Z)^2:
*   odd : 5.519181 ns/m, 0.2495310 V     even: 6.169803 ns/m, 0.2396393 V
* LEN=10: odd at 55.19 ns, even at 61.70 ns, first reflection at three odd
* delays (165.6 ns). Far ends: 0 before 55.19 ns; v(b1) = -v(b2) = 0.2495310
* between the arrivals; v(b1) = 0.4891703 and v(b2) = -0.0098917 after.
* The model's 1 m would put both arrivals before 7 ns.
* Expected results: cpl_tran_card_len.expected.json
V1 s 0 PULSE(0 1 0 0.1n 0.1n 1 2)
Rs1 s a1 50
Rs2 a2 0 50
P1 a1 a2 0 b1 b2 0 pmod LEN=10
RL1 b1 0 50
RL2 b2 0 50
.model pmod cpl r=0 0 0 l=3.83572e-7 8.26253e-8 3.83572e-7 g=0 0 0 c=9.143579e-11 -9.78265e-12 9.143579e-11 length=1
.tran 0.1n 80n 0 0.1n
.meas tran b1_50 find v(b1) at=50n
.meas tran b2_50 find v(b2) at=50n
.meas tran b1_58 find v(b1) at=58.4n
.meas tran b2_58 find v(b2) at=58.4n
.meas tran b1_70 find v(b1) at=70n
.meas tran b2_70 find v(b2) at=70n
.end
