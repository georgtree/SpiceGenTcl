v {xschem version=3.4.6 file_version=1.2}
G {}
K {}
V {}
S {}
E {}
T {@name} 200 -160 2 1 0.15 0.15 {name=L2}
T {L=@L } 200 -155 2 1 0.1 0.1 {name=L2}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 212.5 -170 1 0 0.1 0.1 {hide=true
name=L2}
T {@name} 295 -160 2 1 0.15 0.15 {name=C2}
T {C=@C } 295 -155 2 1 0.1 0.1 {name=C2}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 262.5 -170 1 0 0.1 0.1 {hide=true
name=C2}
T {@name} 310 -220 0 0 0.15 0.15 {name=L3}
T {L=@L } 310 -190 0 0 0.1 0.1 {name=L3}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 310 -182.5 0 0 0.1 0.1 {hide=true
name=L3}
T {@name} 455 -175 0 0 0.15 0.15 {name=L1}
T {L=@L } 455 -165 0 0 0.1 0.1 {name=L1}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 462.5 -170 1 0 0.1 0.1 {hide=true
name=L1}
T {@name} 540 -175 0 0 0.15 0.15 {name=C1}
T {C=@C } 540 -165 0 0 0.1 0.1 {name=C1}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 512.5 -170 1 0 0.1 0.1 {hide=true
name=C1}
T {@name} 595 -165 2 1 0.15 0.15 {name=R1}
T {R=@R } 595 -160 2 1 0.1 0.1 {name=R1}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
TCE=@TCE} 562.5 -170 1 0 0.1 0.1 {hide=true
name=R1}
N 120 -200 120 -180 {lab=n001}
N 120 -200 150 -200 {lab=n001}
N 255 -200 300 -200 {lab=n002}
N 360 -200 390 -200 {lab=n003}
N 505 -200 580 -200 {lab=out}
N 505 -180 530 -180 {lab=out}
N 505 -120 530 -120 {lab=0}
N 255 -180 280 -180 {lab=n002}
N 580 -200 580 -180 {lab=out}
N 505 -200 505 -180 {lab=out}
N 450 -200 505 -200 {lab=out}
N 480 -180 505 -180 {lab=out}
N 255 -200 255 -180 {lab=n002}
N 210 -200 255 -200 {lab=n002}
N 230 -180 255 -180 {lab=n002}
N 120 -120 120 -100 {lab=0}
N 505 -100 580 -100 {lab=0}
N 580 -120 580 -100 {lab=0}
N 255 -120 280 -120 {lab=0}
N 505 -120 505 -100 {lab=0}
N 480 -120 505 -120 {lab=0}
N 255 -100 505 -100 {lab=0}
N 255 -120 255 -100 {lab=0}
N 230 -120 255 -120 {lab=0}
N 120 -100 255 -100 {lab=0}
C {.sym_links/phys.elec.src/vac.sym} 120 -150 0 0 {name=V1 AC=1}
C {.sym_links/phys.elec.b_elem/resistor.sym} 180 -200 0 0 {name=R1 R=141 M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 TCE=0}
C {.sym_links/phys.elec.b_elem/inductor.sym} 230 -150 1 0 {name=L2 L=10u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 280 -150 1 0 {name=C2 C=1n M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/inductor.sym} 330 -200 0 0 {name=L3 L=40u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 420 -200 0 0 {name=C3 C=250p M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0}
C {.sym_links/phys.elec.b_elem/inductor.sym} 480 -150 1 0 {name=L1 L=10u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 530 -150 1 0 {name=C1 C=1n M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/resistor.sym} 580 -150 1 0 {name=R1 R=141 M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 TCE=0
hide_texts=true}
C {.sym_links/phys.elec.ref/elec_ref.sym} 120 -100 0 0 {name=l1 lab=0}
C {lab_wire.sym} 580 -200 0 0 {name=p1 sig_type=std_logic lab=out}
C {lab_wire.sym} 390 -200 0 0 {name=p1 sig_type=std_logic lab=n003}
C {lab_wire.sym} 255 -200 0 0 {name=p1 sig_type=std_logic lab=n002}
C {lab_wire.sym} 120 -200 0 0 {name=p1 sig_type=std_logic lab=n001}
