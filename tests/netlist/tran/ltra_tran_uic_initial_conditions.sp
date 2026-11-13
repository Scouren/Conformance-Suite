* KNOWN GAP: LTRA v1/v2/i1/i2 under .tran uic need the UIC flag in the model (#266)
* Expected results: ltra_tran_uic_initial_conditions.expected.json
* Under uic ngspice keeps an O card's v1, v2, i1 and i2 (ic= is their
* vector, in that order: v1, i1, v2, i2) as the line's state at t <= 0
* (ltraload.c:289-300; without uic the operating point overwrites them),
* and every convolution reads them for the history before t = 0. ESPice's
* ltra.va and tline.va cannot tell a uic start from the transient's .op
* (both evaluate with kind .ic), so ESPice refuses these cards under uic
* (UnsupportedCard); the build before that ran them as zero.
* Three lines, each 50 ohm and 5 ns (l=250n, c=100p, len=1), between 50 ohm
* ends with no source, so only the initial conditions move anything:
*   LC (O1, tline.va): for t < 5 ns port 2 sees port 1's wave from before
*     t = 0, v1 + Z0 i1 = 1 + 50*0.01 = 1.5 V, so v(lo) = 1.5/2 = 0.75 V;
*     after 5 ns it sees port 1's own wave from t >= 0, which is 0. The
*     near end reads 0 throughout (v2 = i2 = 0).
*   RLC (O2, r=0.5) and RC (O3, l=0, r=50): ngspice's convolution values.
O1 li 0 lo 0 lclin v1=1 i1=0.01
R1i li 0 50
R1o lo 0 50
O2 ri 0 ro 0 rlclin ic=1,0.01
R2i ri 0 50
R2o ro 0 50
O3 ci 0 co 0 rclin v1=1 i1=0.01
R3i ci 0 50
R3o co 0 50
.model lclin ltra r=0 l=250n g=0 c=100p len=1
.model rlclin ltra r=0.5 l=250n g=0 c=100p len=1
.model rclin ltra r=50 l=0 g=0 c=100p len=1
.tran 0.1n 20n uic
.meas tran lo_1 find v(lo) at=1n
.meas tran lo_3 find v(lo) at=3n
.meas tran lo_7 find v(lo) at=7n
.meas tran li_3 find v(li) at=3n
.meas tran ri_1 find v(ri) at=1n
.meas tran ro_1 find v(ro) at=1n
.meas tran ro_7 find v(ro) at=7n
.meas tran ri_12 find v(ri) at=12n
.meas tran ci_1 find v(ci) at=1n
.meas tran co_1 find v(co) at=1n
.meas tran co_7 find v(co) at=7n
.meas tran ci_12 find v(ci) at=12n
.end
