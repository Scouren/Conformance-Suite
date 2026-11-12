* An O card takes no length: ngspice's LTRA instance has only v1, v2, i1, i2
* and ic (ltra.c LTRApTable), and ngspice 44.2 refuses this card with
* "unknown parameter (len)". A per-instance length would be a second model
* re-spelled, so ESPice refuses it by name (UnknownParameter) instead of
* reading it. The legal neighbour is op/device_lossy_tline_rg.sp: len=2 on
* the model.
Vin in 0 1
O1 in 0 out 0 line len=2
RL out 0 1
.model line LTRA r=1 g=1 len=1
.op
.end
