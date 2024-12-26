v {xschem version=3.4.6 file_version=1.2}
G {}
K {}
V {}
S {}
E {}
T {@name} 330 -390 0 0 0.15 0.15 {name=Rc1}
T {R=@R } 330 -360 0 0 0.1 0.1 {name=Rc1}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
TCE=@TCE} 337.5 -350 3 0 0.1 0.1 {hide=true
name=Rc1}
T {@name} 450 -390 0 0 0.15 0.15 {name=Rc2}
T {R=@R } 450 -360 0 0 0.1 0.1 {name=Rc2}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
TCE=@TCE} 457.5 -350 3 0 0.1 0.1 {hide=true
name=Rc2}
T {@name} 690 -390 0 0 0.15 0.15 {name=Rbias}
T {R=@R } 690 -360 0 0 0.1 0.1 {name=Rbias}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
TCE=@TCE} 697.5 -350 3 0 0.1 0.1 {hide=true
name=Rbias}
N 320 -340 320 -310 {lab=4}
N 440 -340 440 -310 {lab=5}
N 480 -280 500 -280 {lab=3}
N 260 -280 280 -280 {lab=2}
N 380 -250 440 -250 {lab=6}
N 380 -250 380 -180 {lab=6}
N 320 -250 380 -250 {lab=6}
N 620 -150 640 -150 {lab=7}
N 380 -120 380 -100 {lab=9}
N 680 -120 680 -100 {lab=9}
N 560 -280 600 -280 {lab=1}
N 160 -280 200 -280 {lab=11}
N 160 -200 560 -200 {lab=1}
N 560 -280 560 -200 {lab=1}
N 160 -210 160 -200 {lab=1}
N 160 -280 160 -270 {lab=11}
N 680 -200 680 -180 {lab=7}
N 60 -370 80 -370 {lab=0}
N 80 -380 80 -370 {lab=0}
N 80 -370 80 -360 {lab=0}
N 620 -200 620 -150 {lab=7}
N 420 -150 620 -150 {lab=7}
N 620 -200 680 -200 {lab=7}
N 680 -340 680 -200 {lab=7}
N 380 -100 680 -100 {lab=9}
N 80 -100 380 -100 {lab=9}
N 80 -300 80 -100 {lab=9}
N 80 -480 80 -440 {lab=8}
N 380 -480 680 -480 {lab=8}
N 680 -480 680 -400 {lab=8}
N 380 -400 440 -400 {lab=8}
N 380 -480 380 -400 {lab=8}
N 80 -480 380 -480 {lab=8}
N 320 -400 380 -400 {lab=8}
C {.sym_links/phys.elec.src/vac.sym} 160 -240 0 0 {name=Vdm AC=1}
C {.sym_links/phys.elec.b_elem/resistor.sym} 230 -280 0 0 {name=Rs1 R=1e3 M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 TCE=0}
C {.sym_links/phys.elec.b_elem/resistor.sym} 530 -280 0 0 {name=Rs2 R=1e3 M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 TCE=0}
C {npn.sym} 300 -280 0 0 {name=Q1
model=qnr
device=qnr
footprint=SOT23
area=1
m=1}
C {npn.sym} 460 -280 0 1 {name=Q2
model=qnl
device=qnl
footprint=SOT23
area=1
m=1}
C {.sym_links/phys.elec.b_elem/resistor.sym} 320 -370 3 0 {name=Rc1 R=10e3 M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 TCE=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/resistor.sym} 440 -370 3 0 {name=Rc2 R=10e3 M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 TCE=0
hide_texts=true}
C {npn.sym} 400 -150 0 1 {name=Q4
model=qnr
device=qnr
footprint=SOT23
area=1
m=1}
C {npn.sym} 660 -150 0 0 {name=Q3
model=qnl
device=qnl
footprint=SOT23
area=1
m=1}
C {.sym_links/phys.elec.src/vac.sym} 600 -250 0 0 {name=Vcm AC=1}
C {.sym_links/phys.elec.ref/elec_ref.sym} 600 -220 0 0 {name=l3 lab=0}
C {.sym_links/phys.elec.b_elem/resistor.sym} 680 -370 3 0 {name=Rbias R=20e3 M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 TCE=0
hide_texts=true}
C {.sym_links/phys.elec.src/vdc.sym} 80 -330 2 1 {name=Vee DC=-12}
C {.sym_links/phys.elec.src/vdc.sym} 80 -410 0 0 {name=Vcc DC=12}
C {.sym_links/phys.elec.ref/elec_ref.sym} 60 -370 0 0 {name=l4 lab=0}
C {lab_wire.sym} 380 -480 0 0 {name=p1 sig_type=std_logic lab=8}
C {lab_wire.sym} 380 -100 2 0 {name=p2 sig_type=std_logic lab=9}
C {lab_wire.sym} 380 -250 0 0 {name=p3 sig_type=std_logic lab=6}
C {lab_wire.sym} 270 -280 0 0 {name=p4 sig_type=std_logic lab=2}
C {lab_wire.sym} 490 -280 0 0 {name=p5 sig_type=std_logic lab=3}
C {lab_wire.sym} 580 -280 0 0 {name=p6 sig_type=std_logic lab=1}
C {lab_wire.sym} 160 -280 0 0 {name=p7 sig_type=std_logic lab=11}
C {lab_wire.sym} 320 -320 0 0 {name=p8 sig_type=std_logic lab=4}
C {lab_wire.sym} 440 -320 0 0 {name=p9 sig_type=std_logic lab=5}
C {lab_wire.sym} 620 -170 0 0 {name=p10 sig_type=std_logic lab=7}
