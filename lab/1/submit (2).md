---
documentclass: ctexart
title: 实验一
author: 吴雨飞
date: 2020年4月12日
---

XOR指令的执行过程
================

1. 取指令
2. 从Register File读取两个操作数
3. `Forward1E=00`，`Forward2E=00`，`AluSrc1E=1`，`AluSrc2E=00`，`AluContrlE`使ALU计算异或。
4. `LoadNPC=1`使得`ResultW=AluOutM`
5. `MemToReg=1`，`RegWriteW=1`，将`ResultW`写回`RdW`

BEQ指令的执行过程
================

1. 取指令
2. 从Register File读取两个操作数，`ImmTypeD`对应B-type，解码出立即数`ImmD`，计算`JalNPC`。
3. `Forward1E=00`，`Forward2E=00`，`AluSrc1E=1`，`AluSrc2E=00`，`BrType`对应BEQ。
NPC Generator的`BrT=BrNPC`。Branch Decision判断是否分支，若分支，`BrE=1`。

LHU指令的执行过程
=================

1. 取指令
2. 从Register File读取寄存器，`ImmTypeD`对应I-type，解码出立即数`ImmD`。
3. `Forward1E=00`，`AluSrc1E=1`，`AluSrc2E=10`，`AluContrlE`计算加法。
4. `MemWriteM=0`，读出地址为`AluOutM`的半字所在的字。
5. `RegWriteW=1`，`LoadedBytesSelect`选择半字的位置，`MemToRegW=0`，
将无符号扩展的`DM_RD`写回到`RdW`处。

实现CSR指令
==========

1. 需要在ID阶段添加Control Status Register，
根据译码得到的csr字段读相应的Control Status Register，对csrrc和csrrci，将rs1和imm取反。
2. 在EX寄存器添加csr寄存器的值，在AluSrc1E和AluSrc2E多路选择器添加csr作为输入。
对csrrw和csrrwi，无需ALU；对csrrs、csrrsi、csrrc和csrrci生成与的控制信号；
3. 在MEM寄存器添加csr寄存器的值。
4. 在WB寄存器添加csr寄存器的值，将csr字段的值写入rd字段，将ResultW写入csr寄存器

Verilog实现立即数扩展
=====================

1. 符号扩展，将多个符号位与指令的立即数字段拼接，以I型为例，`{20{imm[11]}, imm[11:0]}`
2. 无符号扩展，将多个零与指令的立即数字段拼接，以I型为例，`{20{0}, imm[11:0]}`

实现非字对齐的内存访问
=====================

将AluOutM的低两位置零后作为Data Memory的输入，读出对应的字。
使用AluOutM的低两位和opcode生成LoadedBytesSelect选择对应半字或字节，
符号扩展后写回Register File。

ALU中wire变量
============

ALU中wire变量默认是无符号的。

BranchE信号的作用
=================

BranchE信号用于指示分支是否发生，在分支发生时，`PC_in`等于`BrT`，也就是分支目标地址。

NPC Generator优先级
===================

Branch和Jalr的优先级相同，高于Jal。
因为Branch和Jalr在EX段判断分支是否发生，而Jal在ID段即可判断。
前一条分支是否发生需要优先判断。

Harzard 插入气泡
===============

1. Load和算术指令，使流水线停顿一个周期
2. Branch或Jal指令，使流水线停顿两个周期
3. Jalr指令，使流水线停顿一个周期

静态分支预测
============

遇到branch指令时，若不发生分支，则无需flush或stall，若发生分支，则`FlushD=1`且`FlushE=1`

0号寄存器对转发的影响
=====================

对以0号寄存器为目的寄存器的指令，发生Harzard时无需对结果进行转发。
