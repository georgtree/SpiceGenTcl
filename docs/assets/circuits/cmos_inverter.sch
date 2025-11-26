v {xschem version=3.4.7RC file_version=1.2}
G {}
K {}
V {}
S {}
E {}
N 270 -180 270 -160 {lab=OUT}
N 230 -180 230 -130 {lab=IN}
N 230 -230 230 -180 {lab=IN}
N 270 -180 380 -180 {lab=OUT}
N 270 -200 270 -180 {lab=OUT}
N 270 -280 270 -260 {lab=VDD}
N 270 -100 270 -80 {lab=VSS}
N 150 -180 150 -160 {lab=IN}
N 150 -180 230 -180 {lab=IN}
N 150 -100 150 -80 {lab=VSS}
N 150 -80 270 -80 {lab=VSS}
N 380 -180 380 -160 {lab=OUT}
N 270 -80 380 -80 {lab=VSS}
N 380 -100 380 -80 {lab=VSS}
N 270 -230 280 -230 {lab=VDD}
N 280 -260 280 -230 {lab=VDD}
N 270 -260 280 -260 {lab=VDD}
N 270 -130 280 -130 {lab=VSS}
N 280 -130 280 -100 {lab=VSS}
N 270 -100 280 -100 {lab=VSS}
C {nmos4.sym} 250 -130 0 0 {name=MN model=NMOS w=\{WIDTH/3\} l=\{LENGTH\} del=0 m=1}
C {pmos4.sym} 250 -230 0 0 {name=MP model=PMOS w=\{WIDTH\} l=\{LENGTH\} del=0 m=1}
C {vsource.sym} 100 -260 0 0 {name=VDD value=\{VSUPPLY\} savecurrent=false}
C {vdd.sym} 270 -280 0 0 {name=l1 lab=VDD}
C {vdd.sym} 100 -290 0 0 {name=l2 lab=VDD}
C {vdd.sym} 270 -80 2 1 {name=l3 lab=VSS}
C {gnd.sym} 100 -230 0 0 {name=l4 lab=0}
C {vsource.sym} 40 -260 0 0 {name=VSS value=0 savecurrent=false}
C {vdd.sym} 40 -290 0 0 {name=l5 lab=VSS}
C {gnd.sym} 40 -230 0 0 {name=l6 lab=0}
C {vsource.sym} 150 -130 0 1 {name=V1 value="PULSE(\{VSUPPLY\} 0
+ \{INPPERIOD/2\}
+ \{INPPERIOD/1000\}
+ \{INPPERIOD/1000\}
+ \{INPPERIOD/2\}
+ \{INPPERIOD\})" savecurrent=false}
C {lab_wire.sym} 150 -180 0 0 {name=p1 sig_type=std_logic lab=IN}
C {capa.sym} 380 -130 0 0 {name=CL
m=1
value=3p
footprint=1206
device="ceramic capacitor"}
C {lab_wire.sym} 380 -180 0 1 {name=p2 sig_type=std_logic lab=OUT}
