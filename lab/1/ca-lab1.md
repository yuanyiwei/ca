# Lab1_RV32I 思考题

## 1：描述执行一条 XOR 指令的过程（数据通路、控制信号等）

1. 取指令、译码
2. 从 Register File 读取 RD1、RD2
3. 在 EX 段 `Forward1E=00`、`Forward2E=00` 和 `AluSrc1E=1`、`AluSrc2E=00` 输入选择两个寄存器，`AluContrlE` 让 ALU 在 XOR 状态计算，`LoadNPC=1` 使用 ALU 的输出 `ResultW=AluOutM`
4. 在 MEM 段 `MemToReg=1`，`RegWriteW=1`，将 `ResultW` 输入 `RdW`

## 2：描述执行一条 BEQ 指令的过程（数据通路、控制信号等）

1. 取指令、译码
2. 从 Register File 读取 RD1、RD2，`ImmTypeD` 解码出立即数 `ImmD`，计算 `JalNPC`
3. 在 EX 段 `Forward1E=00`、`Forward2E=00` 和 `AluSrc1E=1`、`AluSrc2E=00` 输入选择两个寄存器，`BrType` 对应 `BEQ`，`BrT` 对应 `BrNPC`；Branch Decision 判断是否分支，分支则 `BrE=1`

## 3：描述执行一条 LHU 指令的过程（数据通路、控制信号等）

LHU 指令读取一个 16 位无符号数值，零扩展到 32 位

1. 取指令、译码、得到立即数
2. EX 有 `Forward1E=00`、`AluSrc1E=1`、`AluSrc2E=10`，ALU 计算加法
3. MEM 有 `MemWriteM=0`，读出 `AluOutM` 处的 32 位字
4. WB 有 `MemToRegW=0` 拿到 16 位无符号数；`RegWriteW=1`，把 `DM_RD` 写回到 `RdW`

## 4：如果要实现 CSR 指令（csrrw，csrrs，csrrc，csrrwi，csrrsi，csrrci），设计图中还需要增加什么部件和数据通路？给出详细说明

要增加 CSR 读写信号、AluSrc 数据源信号、立即数扩展中的 CSR 扩展信号

- ID：加 CSR 寄存器，在立即数扩展模块上加入 CSR
- EX：AluSrc 可以导入 CSR 的寄存器
- WB：写回 CSR 寄存器

也可以在 CPU 外部加异常处理部分，如对于 csrrw 指令，可以用外部硬件来写入，保证输入输出满足需求，设计比较方便

## 5：Verilog 如何实现立即数的扩展？

Verilog 用 {} 实现立即数拼接扩展，可以用 \$signed() 和 \$unsigned() 实现高位符号扩展

## 6：如何实现 Data Memory 的非字对齐的 Load 和 Store？

若非字对齐的 Load 和 Store 跨越 32 bit，可以通过两次字对齐的 Data Memory 扩展得到
若非字对齐的 Load 和 Store 在 32 bit 内，则是 16 bit 或者 8 bit 对齐的，即对读出的数进行 mask

## 7：ALU 模块中，默认 wire 变量是有符号数还是无符号数？

wire 是无符号的

## 8：简述 BranchE 信号的作用

BranchE 在需要分支转跳的时候变成高电平，让 NPC 在分支目标命令和邻接命令中选择正确的命令，即 `PC_in` 等于 `BrT`

## 9：NPC Generator 中对于不同跳转 target 的选择有没有优先级？

有，Jal 会在 ID 段结束转跳，Branch（BEQ、BNE、BLT、BGE、BLTU、BGEU）或 Jalr 则需要使用 EX

## 10：Harzard 模块中，有哪几类冲突需要插入气泡，分别使流水线停顿几个周期？

- Jal ID 转跳，停顿两个周期
- 遇到 Branch（BEQ、BNE、BLT、BGE、BLTU、BGEU）或 Jalr EX 转跳，停顿一个周期
- Load 和算术指令数据依赖冲突，要插入气泡，停顿一个周期

## 11：Harzard 模块中采用静态分支预测器，即默认不跳转，遇到 branch 指令时，如何控制 flush 和 stall 信号？

branch 指令默认不跳转：若不发生分支，则无需 flush 或 stall；若发生分支，则需要置 `FlushD=1` 且 `FlushE=1`，清空后面两句的结果，不需要 stall

## 12：0 号寄存器值始终为 0，是否会对 forward 的处理产生影响？

若 0 号寄存器为目的寄存器，则 Harzard 时无需转发结果，而是转发 0
