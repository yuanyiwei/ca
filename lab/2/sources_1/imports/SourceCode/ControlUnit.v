`timescale 1ns / 1ps
// OK
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Wu Yuzhang
//
// Design Name: RISCV-Pipline CPU
// Module Name: ControlUnit
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: RISC-V Instruction Decoder
//////////////////////////////////////////////////////////////////////////////////
//功能和接口说明
    //ControlUnit       是本CPU的指令译码器，组合逻辑电路
//输入
    // Op               是指令的操作码部分
    // Fn3              是指令的func3部分
    // Fn7              是指令的func7部分
//输出
    // JalD==1          表示Jal指令到达ID译码阶段
    // JalrD==1         表示Jalr指令到达ID译码阶段
    // RegWriteD        表示ID阶段的指令对应的寄存器写入模式
    // MemToRegD==1     表示ID阶段的指令需要将data memory读取的值写入寄存器,
    // MemWriteD        共4bit，为1的部分表示有效，对于data memory的32bit字按byte进行写入,MemWriteD=0001表示只写入最低1个byte，和xilinx bram的接口类似
    // LoadNpcD==1      表示将NextPC输出到ResultM
    // RegReadD         表示A1和A2对应的寄存器值是否被使用到了，用于forward的处理
    // BranchTypeD      表示不同的分支类型，所有类型定义在Parameters.v中
    // AluContrlD       表示不同的ALU计算功能，所有类型定义在Parameters.v中
    // AluSrc2D         表示Alu输入源2的选择
    // AluSrc1D         表示Alu输入源1的选择
    // ImmType          表示指令的立即数格式
//实验要求
    //补全模块

`include "Parameters.v"
module ControlUnit(
    input wire [6:0] Op,
    input wire [2:0] Fn3,
    input wire [6:0] Fn7,
    output wire JalD,
    output wire JalrD,
    output reg [2:0] RegWriteD,
    output wire [1:0] MemToRegD,     // CSR
    output reg [3:0] MemWriteD,
    output wire LoadNpcD,
    output reg [1:0] RegReadD,
    output reg [2:0] BranchTypeD,
    output reg [3:0] AluContrlD,
    output wire [1:0] AluSrc2D,
    output wire [1:0] AluSrc1D,      // CSR
    output reg [2:0] ImmType,

    input [4:0] Rs1E,                // CSR
    output reg CSRwrenD,             // CSR
    output reg CSRReadD              // CSR
    );

    // 请补全此处代码
    assign JalD = (Op == 7'b1101111);
    assign JalrD = (Op == 7'b1100111);
    assign MemToRegD = (Op == 7'b0000011) ? 2'b01 : ((Op == 7'b1110011) ? 2'b10 : 2'b00); //load
    assign LoadNpcD = (Op == 7'b1101111 || Op == 7'b1100111); //save pc for J
    // Rs2E->branch&arthm->CSR
    assign AluSrc1D = ((Op == 7'b1110011) && Fn3[2]==1)?2'b10:((Op == 7'b0010111) ? 2'b01 : 2'b00);
    assign AluSrc2D = (Op == 7'b0010011) && ((Fn3 == 3'b001) || (Fn3 == 3'b101)) ? 2'b01 : ((Op == 7'b0110011 || Op == 7'b1100011) ? 2'b00 : ((Op == 7'b1110011) ? 2'b11 : 2'b10));

    always @(*) begin
        case (ImmType)
            `RTYPE,`STYPE,`BTYPE: RegReadD = 2'b11;
            `UTYPE,`JTYPE: RegReadD = 2'b00;
            `ITYPE: RegReadD = 2'b10;
            default: RegReadD = 2'b00;
        endcase
    end

    //Branch
    always @(*) begin
        if (Op == 7'b1100011) begin
            case (Fn3)
                3'b000: BranchTypeD <= `BEQ;
                3'b001: BranchTypeD <= `BNE;
                3'b100: BranchTypeD <= `BLT;
                3'b101: BranchTypeD <= `BGE;
                3'b110: BranchTypeD <= `BLTU;
                default: BranchTypeD <= `BGEU;
            endcase
        end
        else BranchTypeD <= `NOBRANCH;
    end

    //CSR
    always @(*) begin
        if (Op == 7'b1110011) begin
            CSRReadD <= 1;
            CSRwrenD <= 1;
        end
        else begin
            CSRReadD <= 0;
            CSRwrenD <= 0;
        end
    end

    //Alu
    always@(*) begin
    MemWriteD <= 0;
    RegWriteD <= `NOREGWRITE;
    AluContrlD <= `ADD;
    case (Op)
        7'b1110011: begin
            RegWriteD <= `LW;
            ImmType <= `ITYPE;
            case (Fn3)
                3'b001: AluContrlD <= `REG1;
                3'b010: AluContrlD <= `OR;
                3'b011: AluContrlD <= `CLR;
                3'b101: AluContrlD <= `REG1;
                3'b110: AluContrlD <= `OR;
                default: AluContrlD <= `CLR;
            endcase
        end
        7'b1100011: begin
            ImmType <= `BTYPE;
        end
        7'b0010011: begin
            RegWriteD <= `LW;
            ImmType <= `ITYPE;
            case (Fn3)
                3'b000: AluContrlD <= `ADD;
                3'b001: AluContrlD <= `SLL;
                3'b010: AluContrlD <= `SLT;
                3'b011: AluContrlD <= `SLTU;
                3'b100: AluContrlD <= `XOR;
                3'b101: begin
                    if (Fn7[5])
                        AluContrlD <= `SRA;
                    else
                        AluContrlD <= `SRL;
                end
                3'b110: AluContrlD <= `OR;
                3'b111: AluContrlD <= `AND;
                default: AluContrlD <= 4'bxxxx; //illegal
            endcase
        end
        7'b0110011: begin
            RegWriteD <= `LW;
            ImmType <= `RTYPE;
            case (Fn3)
                3'b000: begin
                    if (Fn7[5])
                        AluContrlD <= `SUB;
                    else
                        AluContrlD <= `ADD;
                end
                3'b001: AluContrlD <= `SLL;
                3'b010: AluContrlD <= `SLT;
                3'b011: AluContrlD <= `SLTU;
                3'b100: AluContrlD <= `XOR;
                3'b101: begin
                    if (Fn7[5])
                        AluContrlD <= `SRA;
                    else
                        AluContrlD <= `SRL;
                end
                3'b110: AluContrlD <= `OR;
                default: AluContrlD <= `AND;
            endcase
        end
        7'b0110111: begin //LUI
            RegWriteD <= `LW;
            ImmType <= `UTYPE;
            AluContrlD <= `LUI;
        end
        7'b0010111: begin //AUIPC
            RegWriteD <= `LW;
            ImmType <= `UTYPE;
        end
        7'b1101111: begin //Jal
            RegWriteD <= `LW;
            ImmType <= `JTYPE;
        end
        7'b1100111: begin //Jalr
            RegWriteD <= `LW;
            ImmType <= `ITYPE;
        end
        7'b0000011: begin //load
            ImmType <= `ITYPE;
            case (Fn3)
                3'b000: RegWriteD <= `LB;     //byte
                3'b001: RegWriteD <= `LH;     //half word
                3'b010: RegWriteD <= `LW;     //word
                3'b100: RegWriteD <= `LBU;    //unsigned byte
                3'b101: RegWriteD <= `LHU;    //unsigned half word
                default: RegWriteD <= 3'bxxx; //illegal
            endcase
        end
        7'b0100011: begin //store
            ImmType <= `STYPE;
            case (Fn3)
                3'b000: MemWriteD <= 4'b0001;    //byte
                3'b001: MemWriteD <= 4'b0011;    //half word
                3'b010: MemWriteD <= 4'b1111;    //word
                default: MemWriteD <= 4'bxxxx;   //illegal
            endcase
        end
        default: ImmType <= `ITYPE;
    endcase
    end
    // 请补全此处代码

endmodule
