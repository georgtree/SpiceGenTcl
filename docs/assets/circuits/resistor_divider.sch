v {xschem version=3.4.6 file_version=1.2}
G {}
K {}
V {}
S {}
E {}
T {@name} 140 -170 2 1 0.15 0.15 {name=R1}
T {R=@R } 140 -160 2 1 0.1 0.1 {name=R1}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
TCE=@TCE} 112.5 -180 1 0 0.1 0.1 {hide=true
name=R1}
T {@name} 140 -90 2 1 0.15 0.15 {name=R1}
T {R=@R } 140 -80 2 1 0.1 0.1 {name=R1}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
TCE=@TCE} 112.5 -100 1 0 0.1 0.1 {hide=true
name=R1}
N 40 -40 130 -40 {lab=0}
N 130 -50 130 -40 {lab=0}
N 40 -80 40 -40 {lab=0}
N 40 -200 40 -140 {lab=in}
N 40 -200 130 -200 {lab=in}
N 130 -200 130 -190 {lab=in}
N 130 -130 130 -110 {lab=out}
C {.sym_links/phys.elec.b_elem/resistor.sym} 130 -160 1 0 {name=R1 R=1e3 M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 TCE=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/resistor.sym} 130 -80 1 0 {name=R1 R=2e3 M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 TCE=0
hide_texts=true}
C {.sym_links/phys.elec.src/vdc.sym} 40 -110 0 0 {name=V1 DC=0}
C {.sym_links/phys.elec.ref/elec_ref.sym} 40 -40 0 0 {name=l1 lab=0}
C {lab_wire.sym} 40 -200 0 0 {name=p1 sig_type=std_logic lab=in}
C {lab_wire.sym} 130 -120 0 1 {name=p1 sig_type=std_logic lab=out}
