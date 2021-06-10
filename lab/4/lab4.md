---
# documentclass: ctexart # for linux
title: 体系结构实验四
author: PB18000221 袁一玮
# date: 5 月 11 日
# CJKmainfont: "Microsoft YaHei" # for win
CJKmainfont: "KaiTi" # for win
---

## 实验目标

- 实现 BTB（Branch Target Buffer）
- 实现 BHT（Branch History Table）

## 实验环境

Vivado 2019，Windows 10，VS Code，Python3

## 实验内容

### BTB

Branch Target Buffer 包含了跳转指令的 PC、目标 PC 和有效位

```verilog
assign predicted_valid = (branch_PC[PC_F_pos] == PC_F) ? 1'b1 : 1'b0;
assign predicted_PC = (predicted_valid) ? target_PC[PC_F_pos] : 32'b0;
```

如果 `PC_F_pos` 对应的 PC 记录与 IF 的相同，那么就预测跳转，输出跳转的值

在 EX 段冲突的时候更新 Buffer 里的记录

```verilog
if (rst) begin
    for (integer i = 0; i < BTB_LEN; i++) begin
        branch_PC[i] <= 32'b0;
        target_PC[i] <= 32'b0;
    end
end
else begin
    if ((br_type_E != `NOBRANCH) & branch_E) begin
        branch_PC[PC_E_pos] <= PC_E;
        target_PC[PC_E_pos] <= target_E;
    end
end
```

同时，EX 段需要更新，ID 段也需要去传递是否跳转(`branch_E`)、跳转目标(`target_PC`)的信号

在 Predictor.sv 中，如果预测成功，`predicted_valid_IF` 即为 1，NPC 即为预测的跳转到的 PC；若预测失败：

```verilog
assign predicted_EX_error = (branch_E & ~predicted_valid_EX) | (branch_E & predicted_valid_EX & (target_E != predicted_PC_EX)) | (~branch_E & predicted_valid_EX);
```

实际跳转、预测不跳转，实际不跳转、预测跳转，实际、预测都跳转、但跳转的地址不一致，即会出现预测失败，`predicted_EX_error` 为 1，需要在 HarzardUnit.v 中刷新流水线 `if (predicted_EX_error) {FlushD, FlushE} <= 2'b11;`

之后要在 NPC 中修改：如果跳转且预测，NPC 就取跳转 PC，否则就是 PC_EX

```verilog
if (BranchE & predicted_EX_error) PC_In <= BranchTarget;
else if (~BranchE & predicted_EX_error) PC_In <= PC_EX;
```

### BHT

类似 BTB，加入了 2bit 的 State 和 FSM，但是不需要记录 `target_PC`

```verilog
if (br_type_E != `NOBRANCH) begin
    branch_PC[PC_E_pos] <= PC_E;
    if (branch_E) begin
        case(state[PC_E_pos])
            2'b00: state[PC_E_pos] <= 2'b01;
            2'b01: state[PC_E_pos] <= 2'b10;
            2'b10: state[PC_E_pos] <= 2'b11;
            2'b11: state[PC_E_pos] <= 2'b11;
        endcase
    end
    else begin
        case(state[PC_E_pos])
            2'b00: state[PC_E_pos] <= 2'b00;
            2'b01: state[PC_E_pos] <= 2'b00;
            2'b10: state[PC_E_pos] <= 2'b01;
            2'b11: state[PC_E_pos] <= 2'b10;
        endcase
    end
end
```

## 实验结果

TODO:

使用 BHT 预测快速排序的

### 运行结果

TODO:

分析分支收益和分支代价

统计未使用分支预测和使用分支预测的总周期数及差值

统计分支指令数目、动态分支预测正确次数和错误次数

对比不同策略并分析以上几点的关系

## 实验总结

TODO:
