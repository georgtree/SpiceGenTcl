v {xschem version=3.4.6 file_version=1.2}
G {}
K {}
V {}
S {}
E {}
T {model=@model} 155 -150 2 1 0.15 0.15 {name=D1}
T {@name} 155 -160 2 1 0.15 0.15 {name=D1}
N 70 -180 140 -180 {lab=c}
N 70 -120 70 -110 {lab=c}
N 70 -50 140 -50 {lab=0}
N 140 -120 140 -50 {lab=0}
C {.sym_links/phys.elec.src/vdc.sym} 70 -150 0 0 {name=Va DC=0}
C {.sym_links/phys.elec.b_elem/diode_model.sym} 140 -150 3 0 {name=D1 model=diomod AREA=1 M=1
hide_texts=true}
C {.sym_links/phys.elec.ref/elec_ref.sym} 70 -50 0 0 {name=l1 lab=0}
C {lab_wire.sym} 140 -180 0 0 {name=p1 sig_type=std_logic lab=c}
C {.sym_links/phys.elec.src/vac.sym} 70 -80 0 0 {name=Vac1 AC=1}
C {lab_wire.sym} 70 -110 0 0 {name=p2 sig_type=std_logic lab=in}
