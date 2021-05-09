.section .text;
.align 6;
.globl _start;

_start:
nop;nop;nop;nop;nop;
AUIPC x19,0     #x19=20 0x14
nop;nop;nop;nop;
add x1,x0,x0    #x1=0 0x0
nop;nop;nop;nop;
xori x2,x1,2    #x2=2 0x2
nop;nop;nop;nop;
slli x3,x2,3    #x3=16 0x10
nop;nop;nop;nop;
sll x4,x3,x2    #x4=64 0x40
nop;nop;nop;nop;
sub x5,x2,x3    #x5=-14 0xfffffff2
nop;nop;nop;nop;
srli x6,x5,1
nop;nop;nop;nop;
srai x7,x5,1
nop;nop;nop;nop;
srl x6,x6,x2    #x6=0x1ffffffe
nop;nop;nop;nop;
sra x7,x7,x2    #x7=-2 0xfffffffe
nop;nop;nop;nop;
addi x8,x4,-11  #x8=53 0x35
nop;nop;nop;nop;
ori x9,x8,7     #x9=55 0x37
nop;nop;nop;nop;
or x10,x3,x4    #x10=80 0x50
nop;nop;nop;nop;
and x11,x9,x5   #x11=50 0x32
nop;nop;nop;nop;
andi x12,x11,27 #x12=18 0x12
nop;nop;nop;nop;
xor x13,x9,x12  #x13=37 0x25
nop;nop;nop;nop;
SLT x14,x5,x3   #x14=1 0x1
nop;nop;nop;nop;
SLTU x15,x5,x3  #x14=0 0x0
nop;nop;nop;nop;
slti x16,x2,-5  #x16=0 0x0
nop;nop;nop;nop;
sltiu x17,x2,-5 #x17=1 0x1
nop;nop;nop;nop;
lui x18,3       #x18=0x3000
nop;nop;nop;nop;