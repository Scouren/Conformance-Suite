* AM with an output offset VO, V and I sources, against ngspice 44.2.
* Expected results: source_am_offset.expected.json
* ngspice's AM(VO VMO VMA FM FC TD PHASEM PHASEC) is 0 while t' = t - TD
* <= 0, VO included, then VO + (VMO + VMA sin(2 pi FM t' + PHASEM))
* sin(2 pi FC t' + PHASEC) (ngspice-45 vsrcload.c:307-313,
* isrcload.c:280-286): va 1.507971 at t' = 1 ns, 1.198601 at 130 ns.
* Vc and Ic have VMA = 0: -0.2 + 0.5 sin(2 pi 1meg t' + 30deg) past 100 ns.
* espice refused a nonzero VO before (UnsupportedCard).
Va va 0 AM(0.3 0.5 1 200k 1meg 0 45 90)
Vb vb 0 AM(0.3 0.5 1 200k 1meg 250n 45 90)
Vc vc 0 AM(-0.2 0.5 0 200k 1meg 100n 45 30)
Ia 0 ia AM(0.3 0.5 1 200k 1meg 0 45 90)
Ib 0 ib AM(0.3 0.5 1 200k 1meg 250n 45 90)
Ic 0 ic AM(-0.2 0.5 0 200k 1meg 100n 45 30)
Rva va 0 1
Rvb vb 0 1
Rvc vc 0 1
Ria ia 0 1
Rib ib 0 1
Ric ic 0 1
.tran 0.1n 260n 0 0.1n
.meas tran va_t0 find v(va) at=0
.meas tran va_td find v(va) at=1n
.meas tran va_mid find v(va) at=130n
.meas tran vb_t0 find v(vb) at=0
.meas tran vb_pre find v(vb) at=100n
.meas tran vb_td find v(vb) at=251n
.meas tran vc_t0 find v(vc) at=0
.meas tran vc_td find v(vc) at=101n
.meas tran vc_mid find v(vc) at=230n
.meas tran ia_t0 find v(ia) at=0
.meas tran ia_td find v(ia) at=1n
.meas tran ia_mid find v(ia) at=130n
.meas tran ib_t0 find v(ib) at=0
.meas tran ib_pre find v(ib) at=100n
.meas tran ib_td find v(ib) at=251n
.meas tran ic_t0 find v(ic) at=0
.meas tran ic_td find v(ic) at=101n
.meas tran ic_mid find v(ic) at=230n
.end
