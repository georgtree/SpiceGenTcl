v {xschem version=3.4.6 file_version=1.2}
G {}
K {}
V {}
S {}
E {}
T {model=@model} 125 -70 2 1 0.15 0.15 {name=D1}
T {@name} 125 -80 2 1 0.15 0.15 {name=D1}
N 40 -100 110 -100 {lab=anode}
C {.sym_links/phys.elec.src/vdc.sym} 40 -70 0 0 {name=Va DC=0}
C {.sym_links/phys.elec.b_elem/diode_model.sym} 110 -70 1 0 {name=D1 model=diomod AREA=1 M=1
hide_texts=true}
C {.sym_links/phys.elec.ref/elec_ref.sym} 40 -40 0 0 {name=l1 lab=0}
C {.sym_links/phys.elec.ref/elec_ref.sym} 110 -40 0 0 {name=l2 lab=0}
C {lab_wire.sym} 110 -100 0 0 {name=p1 sig_type=std_logic lab=anode}
