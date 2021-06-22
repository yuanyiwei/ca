---
documentclass: ctexart # for linux
title: 体系结构实验五实验报告
author: PB18000221 袁一玮
# date: 5 月 11 日
# CJKmainfont: "Microsoft YaHei" # for win
# CJKmainfont: "KaiTi" # for win
# cmd: pandoc --pdf-engine=xelatex .\lab4.md -o .\lab4.pdf -N --shift-heading-level-by=-1
---

## 实验目标

- 掌握 Tomasulo 算法在指令流出、执行、写结果各阶段对浮点操作指令以及 load 和 store 指令进行什么处理
- 给定被执行代码片段，对于具体某个时钟周期，能够写出保留站、指令状态表以及浮点寄存器状态表内容的变化情况
- 理解监听法和目录法的基本思想

## 实验环境

Arch Linux，Windows 10 (vmware-workstation)，VS Code

## Tomasulo

```assembly
L.D     F6, 21（R2）
L.D     F2, 0（R3）
MUL.D   F0, F2, F4
SUB.D   F8, F6, F2
DIV.D   F10, F0, F6
ADD.D   F6, F8, F2
```

1. 周期 2 截图:

   周期 3 截图:

   在周期 2 时，第一条 L.D 指令开始执行，Load1 部件得到了第一条 L.D 指令需要读取的内存地址。第二条 L.D 指令发射，占用 Load2 部件。

   在周期 3 时，第一条 L.D 指令 (Load1) 得到了内存中需要读取的值（但是结果还没有写回），Load2 部件得到了第二条 L.D 指令需要读取的内存地址。

2. MUL.D 刚开始执行截图：

   变动：

   - MUL.D 与 SUB.D 开始执行，ADD.D 被发射
   - 保留站中由于 ADD.D 发射，Add2 部件被其占用，读取了运算符 (ADD.D)，两运算数（F8 对应 Add1 部件的结果 (Qj)，F2 对应浮点寄存器中 F2 的值 (Vk)）。此外 MUL.D 和 SUB.D 进入执行，对应的 Time 记录了距离执行完成需要的时间
   - 寄存器中，由于 ADD.D 目标寄存器为 F6，修改 F6 的目标值获取地址 (Qi) 为 Add2
   - Load 部件无变化

3. RAW 相关使得 MUL.D 流出后没有立即执行。
   因为 MUL.D 依赖于 F2 寄存器的结果，而 F2 寄存器仍然在 Load2 部件中被读取。待 Load2 读取完成并且写结果后 MUL.D 才能够执行。

4. 15 周期截图:

   16 周期截图:

   变化：

   - 15 周期:

     - MULT.D 执行到最后一个周期。
     - 保留站中 MULT.D 对应 (Mult1) 的 Time 清零。
     - 其他部件无变化。

   - 16 周期:

     - MULT.D 写回结果 (M5)。
     - 保留站中原先占用的 Mult1 释放。Mult2 的 Qj 因为得到了结果，变为了 Vj = M5。
     - 寄存器中 F0 的值变为 M5。
     - Load 部件无变化。

5. 最后一条指令执行完成为 57 周期，截图：

## 多 cache 一致性算法-监听法

1. 填表。（传块优化关闭。「替换」不将替换无效块计入。）

   | 所进行的访问     | 替换？ | 写回？ | 监听协议的操作与块状态的改变                                                                                                 |
   | ---------------- | ------ | ------ | ---------------------------------------------------------------------------------------------------------------------------- |
   | CPU A 读第 5 块  | N      | N      | 向总线发送「读不命中」，Cache A 第 1 块从存储器获得 M[5] 值，标记为共享。                                                    |
   | CPU B 读第 5 块  | N      | N      | 向总线发送「读不命中」，Cache B 第 1 块从存储器获得 M[5] 值，标记为共享。                                                    |
   | CPU C 读第 5 块  | N      | N      | 向总线发送「读不命中」，Cache C 第 1 块从存储器获得 M[5] 值，标记为共享。                                                    |
   | CPU B 写第 5 块  | N      | N      | 向总线发送「作废」，Cache B 第 1 块标记为独占。Cache A, C 中第一块作废（标记为无效）。之后 Cache B 第 1 块被写入。           |
   | CPU D 读第 5 块  | N      | Y      | 向总线发送「读不命中」，Cache B 第 1 块写回存储器，标记为共享。之后 Cache D 第 1 块从存储器获得 M[5] 值，标记为共享。        |
   | CPU B 写第 21 块 | Y      | N      | 向总线发送「写不命中」，Cache B 第 1 块被从存储器获得的 M[21] 替换，之后标记为独占，被写入。                                 |
   | CPU A 写第 23 块 | N      | N      | 向总线发送「写不命中」，Cache A 第 3 块从存储器获得 M[23] 值，之后标记为独占，被写入。                                       |
   | CPU C 写第 23 块 | N      | Y      | 向总线发送「写不命中」，Cache A 第 3 块写回存储器，作废。之后 Cache C 第 3 块从存储器获得 M[23] 值，之后标记为独占，被写入。 |
   | CPU B 读第 29 块 | Y      | Y      | 向总线发送「读不命中」，Cache B 第 1 块写回存储器，作废。之后 Cache B 第 1 块从存储器获得 M[29] 值，标记为共享。             |
   | CPU B 写第 5 块  | Y      | N      | 向总线发送「写不命中」，之后 Cache B 第 1 块被替换为从存储器获得 M[5] 值，标记为独占。Cache D 中第 1 块失效。                |

2. 截图

## 多 cache 一致性算法-目录法

1. 填表。（传块优化关闭）

   | 所进行的访问     | 监听协议的操作与块状态的改变                                                                                                                                                                                                      |
   | ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | CPU A 读第 6 块  | 发送「读不命中」到存储 A，Cache A 第 2 块从存储 A 得到 M[6]，Cache 块与存储器均标记为共享。M[6] 共享集合为 {A}。                                                                                                                  |
   | CPU B 读第 6 块  | 发送「读不命中」到存储 A，Cache B 第 2 块从存储 A 得到 M[6]，对应 Cache 块标记为共享。M[6] 共享集合为 {A, B}。                                                                                                                    |
   | CPU D 读第 6 块  | 发送「读不命中」到存储 A，Cache D 第 2 块从存储 A 得到 M[6]，对应 Cache 块标记为共享。M[6] 共享集合为 {A, B, D}。                                                                                                                 |
   | CPU B 写第 6 块  | 发送「写命中」到存储 A（宿主结点），其向 A, D 发送「作废」消息，对应 Cache 块作废，共享集合变为 {B}。Cache B 第 2 块与存储器对应块状态均标记为独占。Cache 对应块被写入。                                                          |
   | CPU C 读第 6 块  | 发送「读不命中」到存储 A，宿主结点向 B 发送读取消息，B 传送修改后的第 6 块到存储 A，状态改为共享。之后 Cache C 第 2 块从存储 A 得到 M[6]，对应 Cache 块标记为共享。存储器对应块状态亦标记为共享，共享集合 {B, C}。                |
   | CPU D 写第 20 块 | 发送「写不命中」到存储 C，宿主结点向 Cache D 传送第 20 块的内容，而后 Cache D 第 0 块标记为独占，写入。存储器对应块状态亦标记为独占，共享集合 {D}。                                                                               |
   | CPU A 写第 20 块 | 发送「写不命中」到存储 C，宿主结点向 D 发送读取并作废消息，D 传送修改后的第 20 块到存储 C，并作废对应 Cache 块。而后宿主结点将块内容传输到 Cache A 第 0 块，Cache 块与存储器均标记为独占，Cache 对应块被写入。共享集合 {A}。      |
   | CPU D 写第 6 块  | 发送「写不命中」到存储 A，宿主结点向 B, C 发送作废消息，对应块作废。而后将数据传输给 Cache D 第 2 块，对应块标记为独占并被写入。存储器对应块亦为独占。共享集合 {D}。                                                              |
   | CPU A 读第 12 块 | 向存储 C 发送「写回并修改共享集合」的消息，Cache A 中被修改的第 20 块的数据被写回存储 C，对应共享集合为空。之后向存储 B 发送「读不命中」，存储 B 将数据传输给 Cache A 第 0 块，标记为共享。对应存储块亦标记为共享。共享集合 {A}。 |

2. 截图:

## 综合问答

1. 目录法和监听法分别是集中式和基于总线，两者优劣是什么？

   - 监听法不需要设置跟踪缓存状态的集中式的结构，这样可以降低成本；但是监听法的可伸缩性不足，由于每次缓存缺失都需要与所有缓存通信，在分布式的情况下需要的总线带宽会大到无法承受。
   - 目录法通过存储状态，减少了一致性通信流量的大小，降低了对带宽的要求；但是其实现比较复杂，存储目录也需要一定的成本。

2. Tomasulo 算法相比 Score Board 算法有什么异同？

   - Score Board 用 stall 的方式处理相关，而 Tomasulo 用寄存器重命名的方法处理 WAR 和 WAW 相关。此外，Tomasulo 可以拓展处理推测，减小控制相关的影响。
   - Score Board 是集中式的（指令状态等都在记分牌中），Tomasulo 是分布式的（控制和缓存分布在各个部件中）。

3. Tomasulo 算法是如何解决结构、RAW、WAR 和 WAW 相关的？
   - 结构相关：出现结构冲突（保留站 busy）时不发射。
   - RAW 相关：在操作数未准备好时，推迟指令执行。
   - WAR 相关：寄存器重命名。（指令中的寄存器在保留站中用寄存器值或指向保留站的指针代替）
   - WAW 相关：寄存器重命名。