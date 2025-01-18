v {xschem version=3.4.6 file_version=1.2}
G {}
K {}
V {}
S {}
E {}
B 4 100 -220 470 -30 {fill=0
dash=5
lock=1}
B 4 740 -220 1110 -30 {fill=0
dash=5
lock=1}
B 4 620 -220 720 -30 {fill=0
dash=5
lock=1}
B 4 490 -220 590 -30 {fill=0
dash=5
lock=1}
T {Lowpass Chebyshev} 110 -220 0 0 0.2 0.2 {}
T {Lowpass
m-derived} 490 -220 0 0 0.15 0.15 {}
T {Highpass Chebyshev} 850 -220 0 1 0.2 0.2 {}
T {Highpass 
m-derived} 660 -220 0 1 0.15 0.15 {}
T {@name} 210 -130 2 1 0.15 0.15 {name=C2}
T {C=@C } 210 -120 2 1 0.15 0.15 {name=C2}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 172.5 -140 1 0 0.1 0.1 {hide=true
name=C2}
T {@name} 310 -130 2 1 0.15 0.15 {name=C4}
T {C=@C } 310 -120 2 1 0.15 0.15 {name=C4}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 272.5 -140 1 0 0.1 0.1 {hide=true
name=C4}
T {@name} 410 -130 2 1 0.15 0.15 {name=C6}
T {C=@C } 410 -120 2 1 0.15 0.15 {name=C6}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 372.5 -140 1 0 0.1 0.1 {hide=true
name=C6}
T {@name} 830 -130 2 1 0.15 0.15 {name=L2}
T {L=@L } 830 -120 2 1 0.15 0.15 {name=L2}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 802.5 -140 1 0 0.1 0.1 {hide=true
name=L2}
T {@name} 930 -130 2 1 0.15 0.15 {name=L4}
T {L=@L } 930 -120 2 1 0.15 0.15 {name=L4}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 902.5 -140 1 0 0.1 0.1 {hide=true
name=L4}
T {@name} 1030 -130 2 1 0.15 0.15 {name=L6}
T {L=@L } 1030 -120 2 1 0.15 0.15 {name=L6}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 1002.5 -140 1 0 0.1 0.1 {hide=true
name=L6}
T {@name} 20 -150 0 0 0.15 0.15 {name=Vport1}
T {@name} 1170 -150 0 0 0.15 0.15 {name=Vport2}
T {Z0=50} 1170 -140 0 0 0.15 0.15 {}
T {Z0=50} 20 -140 0 0 0.15 0.15 {}
T {@name} 120 -200 0 0 0.15 0.15 {name=L1}
T {L=@L } 120 -170 0 0 0.15 0.15 {name=L1}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 120 -162.5 0 0 0.1 0.1 {hide=true
name=L1}
T {@name} 220 -200 0 0 0.15 0.15 {name=L3}
T {L=@L } 220 -170 0 0 0.15 0.15 {name=L3}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 220 -162.5 0 0 0.1 0.1 {hide=true
name=L3}
T {@name} 320 -200 0 0 0.15 0.15 {name=L5}
T {L=@L } 320 -170 0 0 0.15 0.15 {name=L5}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 320 -162.5 0 0 0.1 0.1 {hide=true
name=L5}
T {@name} 420 -200 0 0 0.15 0.15 {name=L7}
T {L=@L } 420 -170 0 0 0.15 0.15 {name=L6}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 420 -162.5 0 0 0.1 0.1 {hide=true
name=L6}
T {@name} 500 -200 0 0 0.15 0.15 {name=La}
T {L=@L } 500 -170 0 0 0.15 0.15 {name=La}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 500 -162.5 0 0 0.1 0.1 {hide=true
name=La}
T {@name} 670 -200 0 0 0.15 0.15 {name=Ca}
T {C=@C } 670 -170 0 0 0.15 0.15 {name=Ca}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 670 -162.5 0 0 0.1 0.1 {hide=true
name=Ca}
T {@name} 750 -200 0 0 0.15 0.15 {name=C1}
T {C=@C } 750 -170 0 0 0.15 0.15 {name=C1}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 750 -162.5 0 0 0.1 0.1 {hide=true
name=C1}
T {@name} 850 -200 0 0 0.15 0.15 {name=C3}
T {C=@C } 850 -170 0 0 0.15 0.15 {name=C3}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 850 -162.5 0 0 0.1 0.1 {hide=true
name=C3}
T {@name} 950 -200 0 0 0.15 0.15 {name=C5}
T {C=@C } 950 -170 0 0 0.15 0.15 {name=C5}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 950 -162.5 0 0 0.1 0.1 {hide=true
name=C5}
T {@name} 1050 -200 0 0 0.15 0.15 {name=C7}
T {C=@C } 1050 -170 0 0 0.15 0.15 {name=C7}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 1050 -162.5 0 0 0.1 0.1 {hide=true
name=C7}
T {@name} 560 -140 2 0 0.15 0.15 {name=Lb}
T {L=@L } 560 -130 2 0 0.15 0.15 {name=Lb}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 552.5 -170 1 0 0.1 0.1 {hide=true
name=Lb}
T {@name} 650 -140 2 1 0.15 0.15 {name=Lc}
T {L=@L } 650 -130 2 1 0.15 0.15 {name=Lc}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 622.5 -170 1 0 0.1 0.1 {hide=true
name=Lc}
T {@name} 530 -100 2 1 0.15 0.15 {name=Cb}
T {C=@C } 530 -90 2 1 0.15 0.15 {name=Cb}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 507.5 -100 3 1 0.1 0.1 {hide=true
name=Cb}
T {@name} 650 -100 2 1 0.15 0.15 {name=Cc}
T {C=@C } 650 -90 2 1 0.15 0.15 {name=Cc}
T {M=@M 
SCALE=@SCALE 
DTEMP=@DTEMP 
TC1=@TC1 
TC2=@TC2 
IC=@IC} 622.5 -100 1 0 0.1 0.1 {hide=true
name=Cc}
N 190 -180 210 -180 {lab=2}
N 290 -180 310 -180 {lab=3}
N 390 -180 410 -180 {lab=4}
N 470 -180 490 -180 {lab=5}
N 550 -180 660 -180 {lab=6}
N 720 -180 740 -180 {lab=7}
N 820 -180 840 -180 {lab=8}
N 920 -180 940 -180 {lab=9}
N 1020 -180 1040 -180 {lab=10}
N 570 -120 570 -110 {lab=a}
N 640 -120 640 -110 {lab=b}
N 1020 -50 1150 -50 {lab=GND}
N 60 -90 60 -50 {lab=GND}
N 1150 -90 1150 -50 {lab=GND}
N 820 -90 820 -50 {lab=GND}
N 390 -50 820 -50 {lab=GND}
N 920 -90 920 -50 {lab=GND}
N 820 -50 920 -50 {lab=GND}
N 1020 -90 1020 -50 {lab=GND}
N 920 -50 1020 -50 {lab=GND}
N 390 -90 390 -50 {lab=GND}
N 290 -50 390 -50 {lab=GND}
N 290 -90 290 -50 {lab=GND}
N 190 -50 290 -50 {lab=GND}
N 190 -180 190 -150 {lab=2}
N 170 -180 190 -180 {lab=2}
N 190 -90 190 -50 {lab=GND}
N 60 -50 190 -50 {lab=GND}
N 290 -180 290 -150 {lab=3}
N 270 -180 290 -180 {lab=3}
N 390 -180 390 -150 {lab=4}
N 370 -180 390 -180 {lab=4}
N 820 -180 820 -150 {lab=8}
N 800 -180 820 -180 {lab=8}
N 920 -180 920 -150 {lab=9}
N 900 -180 920 -180 {lab=9}
N 1020 -180 1020 -150 {lab=10}
N 1000 -180 1020 -180 {lab=10}
N 60 -180 60 -150 {lab=1}
N 60 -180 110 -180 {lab=1}
N 1100 -180 1150 -180 {lab=out}
N 1150 -180 1150 -150 {lab=out}
N 560 -110 570 -110 {lab=a}
N 640 -110 650 -110 {lab=b}
C {.sym_links/phys.elec.src/vsin.sym} 60 -120 0 1 {name=Vport1 VO=0 VA=1 FREQ=50 TD=0 THETA=0 PHASE=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/inductor.sym} 140 -180 0 0 {name=L1 L=0.058u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/inductor.sym} 240 -180 0 0 {name=L3 L=0.128u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 190 -120 1 0 {name=C2 C=40.84p M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 290 -120 1 0 {name=C4 C=47.91p M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/inductor.sym} 340 -180 0 0 {name=L5 L=0.128u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 390 -120 1 0 {name=C6 C=40.84p M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/inductor.sym} 440 -180 0 0 {name=L7 L=0.058u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/inductor.sym} 520 -180 0 0 {name=La L=0.044u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/inductor.sym} 570 -150 1 0 {name=Lb L=0.078u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 690 -180 0 0 {name=Ca C=60.6p M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 770 -180 0 0 {name=C1 C=45.64p M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/inductor.sym} 820 -120 1 0 {name=L2 L=0.0653u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0 hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 870 -180 0 0 {name=C3 C=20.8p M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/inductor.sym} 920 -120 1 0 {name=L4 L=0.055u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 970 -180 0 0 {name=C5 C=20.8p M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/inductor.sym} 1020 -120 1 0 {name=L6 L=0.0653u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 1070 -180 0 0 {name=C7 C=45.64p M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.src/vsin.sym} 1150 -120 0 0 {name=Vport2 VO=0 VA=1 FREQ=50 TD=0 THETA=0 PHASE=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/inductor.sym} 640 -150 1 0 {name=Lc L=0.151u M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 570 -80 1 0 {name=Cb C=17.61p M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {.sym_links/phys.elec.b_elem/capacitor.sym} 640 -80 1 0 {name=Cc C=34.12p M=1 SCALE=1 DTEMP=0 TC1=0 TC2=0 IC=0
hide_texts=true}
C {lab_wire.sym} 60 -180 0 0 {name=p1 sig_type=std_logic lab=1}
C {lab_wire.sym} 190 -180 0 0 {name=p2 sig_type=std_logic lab=2}
C {lab_wire.sym} 290 -180 0 0 {name=p3 sig_type=std_logic lab=3}
C {lab_wire.sym} 390 -180 0 0 {name=p4 sig_type=std_logic lab=4}
C {lab_wire.sym} 490 -180 0 0 {name=p5 sig_type=std_logic lab=5}
C {lab_wire.sym} 610 -180 0 0 {name=p6 sig_type=std_logic lab=6}
C {lab_wire.sym} 560 -110 0 0 {name=p7 sig_type=std_logic lab=a}
C {lab_wire.sym} 650 -110 0 1 {name=p8 sig_type=std_logic lab=b}
C {lab_wire.sym} 740 -180 0 0 {name=p9 sig_type=std_logic lab=7}
C {lab_wire.sym} 820 -180 0 0 {name=p10 sig_type=std_logic lab=8}
C {lab_wire.sym} 920 -180 0 0 {name=p11 sig_type=std_logic lab=9}
C {lab_wire.sym} 1020 -180 0 0 {name=p12 sig_type=std_logic lab=10}
C {lab_wire.sym} 1150 -180 0 1 {name=p13 sig_type=std_logic lab=out}
C {gnd.sym} 60 -50 0 0 {name=l8 lab=0}
