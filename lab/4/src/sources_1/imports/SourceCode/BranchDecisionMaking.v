`timescale 1ns / 1ps
// OK
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Wu Yuzhang
//
// Design Name: RISCV-Pipline CPU
// Module Name: BranchDecisionMaking
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Decide whether to branch
//////////////////////////////////////////////////////////////////////////////////
//功能和接口说明
    //BranchDecisionMaking接受两个操作数，根据BranchTypeE的不同，进行不同的判断，当分支应该taken时，令BranchE=1'b1
    //BranchTypeE的类型定义在Parameters.v中
//推荐格式：
    //case()
    //    `BEQ: ???
    //      .......
    //    default:                            BranchE<=1'b0;  //NOBRANCH
    //endcase
//实验要求
    //补全模块

`include "Parameters.v"
module BranchDecisionMaking(
    input wire [2:0] BranchTypeE,
    input wire [31:0] Operand1,Operand2,
    output reg BranchE
    );

    // 请补全此处代码
    always @(*) begin
        case(BranchTypeE)
            `BEQ: BranchE = ( $signed(Operand1) == $signed(Operand2) ) ? 1'b1 : 1'b0;
            `BNE: BranchE = ( $signed(Operand1) == $signed(Operand2) ) ? 1'b0 : 1'b1;
            `BLT: BranchE = ( $signed(Operand1) < $signed(Operand2) ) ? 1'b1 : 1'b0;
            `BLTU: BranchE = ( Operand1 < Operand2 ) ? 1'b1 : 1'b0;
            `BGE: BranchE = ( $signed(Operand1) < $signed(Operand2) ) ? 1'b0 : 1'b1;
            `BGEU: BranchE = ( Operand1 < Operand2 ) ? 1'b0 : 1'b1;
            `NOBRANCH: BranchE = 1'b0;
            default: BranchE = 1'b0; //NOBRANCH
        endcase
    end
    // 请补全此处代码

endmodule

