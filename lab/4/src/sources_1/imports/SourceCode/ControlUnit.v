`timescale 1ns / 1ps
// TODO
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
    output wire [1:0] MemToRegD, // CSR
    output reg [3:0] MemWriteD,
    output wire LoadNpcD,
    output reg [1:0] RegReadD,
    output reg [2:0] BranchTypeD,
    output reg [3:0] AluContrlD,
    output wire [1:0] AluSrc2D,
    output wire [1:0] AluSrc1D, // CSR
    output reg [2:0] ImmType,

    input [4:0] Rs1E, // CSR
    output reg CSRwrenD, // CSR
    output reg CSRReadD // CSR
    );

    // 请补全此处代码
    assign JalD = (Op == 7'b1101111);
    assign JalrD = (Op == 7'b1100111);
    assign MemToRegD = (Op == 7'b0000011) ? 2'b01 : ((Op == 7'b1110011) ? 2'b10 : 2'b00); //load
    assign LoadNpcD = (Op == 7'b1101111 || Op == 7'b1100111); //save pc for J
    assign AluSrc1D = ((Op == 7'b1110011) && Fn3[2]==1)?2'b10:((Op == 7'b0010111) ? 2'b01 : 2'b00);
    assign AluSrc2D = (Op == 7'b0010011) && ((Fn3 == 3'b001) || (Fn3 == 3'b101)) ? 2'b01 : ((Op == 7'b0110011 || Op == 7'b1100011) ? 2'b00 : ((Op == 7'b1110011) ? 2'b11 : 2'b10));

    always@(*)
    begin
        case(ImmType)
        `RTYPE,`STYPE,`BTYPE: RegReadD = 2'b11;
        `UTYPE,`JTYPE:RegReadD = 2'b00;
        `ITYPE: RegReadD = 2'b10;
        default: RegReadD = 2'b00;
        endcase
    end

    //Branch
    always@(*)
    begin
        if(Op == 7'b1100011)
        begin
            case(Fn3)
            3'b000:BranchTypeD<=`BEQ;
            3'b001:BranchTypeD<=`BNE;
            3'b100:BranchTypeD<=`BLT;
            3'b101:BranchTypeD<=`BGE;
            3'b110:BranchTypeD<=`BLTU;
            default:BranchTypeD<=`BGEU;
            endcase
        end
        else BranchTypeD <= `NOBRANCH;
    end

    //CSRRead and CSRwrite enable
    always @(*)
    begin
        if (Op == 7'b1110011)
        begin
            CSRReadD <= 1;
            CSRwrenD <= 1;
        end
        else
        begin
            CSRReadD <= 0;
            CSRwrenD <= 0;
        end
    end

    //MemWrite,RegWrite and AluControl
    always@(*)
    begin //set default values
    MemWriteD <= 0;
    RegWriteD <=`NOREGWRITE;
    AluContrlD <=`ADD;
    case(Op)
        7'b1110011:
        begin
            ImmType<=`ITYPE;
            RegWriteD<=`LW;
            case (Fn3)
                3'b001:AluContrlD<=`REG1;
                3'b010:AluContrlD<=`OR;
                3'b011:AluContrlD<=`CLR;
                3'b101:AluContrlD<=`REG1;
                3'b110:AluContrlD<=`OR;
                default: AluContrlD<=`CLR;
            endcase
        end
        7'b1100011: ImmType<=`BTYPE;
        7'b0010011:
        begin
            RegWriteD<=`LW;
            ImmType<=`ITYPE;
            case(Fn3)
                3'b000:AluContrlD<=`ADD;
                3'b001:AluContrlD<=`SLL;
                3'b010:AluContrlD<=`SLT;
                3'b011:AluContrlD<=`SLTU;
                3'b101:begin
                    if(Fn7[5])
                        AluContrlD<=`SRA;
                    else
                        AluContrlD<=`SRL;
                        end
                3'b100:AluContrlD<=`XOR;
                3'b110:AluContrlD<=`OR;
                default:AluContrlD<=`AND;
                endcase
        end
        7'b0110011:
        begin
            RegWriteD<=`LW;
            ImmType<=`RTYPE;
            case(Fn3)
                3'b000:begin
                    if(Fn7[5])
                        AluContrlD<=`SUB;
                    else
                        AluContrlD<=`ADD;
                end
                3'b001:AluContrlD<=`SLL;
                3'b010:AluContrlD<=`SLT;
                3'b011:AluContrlD<=`SLTU;
                3'b100:AluContrlD<=`XOR;
                3'b101:begin
                    if(Fn7[5])
                        AluContrlD<=`SRA;
                    else
                        AluContrlD<=`SRL;
                end
                3'b110:AluContrlD<=`OR;
                default:AluContrlD<=`AND;
            endcase
        end
        7'b0110111:
        begin    //LUI
            RegWriteD<=`LW;
            AluContrlD<=`LUI;
            ImmType<=`UTYPE;
        end
        7'b0010111:
        begin    //AUIPC
            RegWriteD<=`LW;
            ImmType<=`UTYPE;
        end
        7'b1101111:
        begin    //Normal jal
            RegWriteD<=`LW;
            ImmType<=`JTYPE;
        end
        7'b1100111:
        begin    //Jalr
            RegWriteD<=`LW;
            ImmType<=`ITYPE;     // Check the manul for detailed information
        end
        7'b0000011:
        begin    //load
            ImmType<=`ITYPE;
            case(Fn3)
                3'b000:RegWriteD<=`LB;    //byte
                3'b001:RegWriteD<=`LH;    //half word
                3'b010:RegWriteD<=`LW;    //word
                3'b100:RegWriteD<=`LBU;    //unsigned byte
                default:RegWriteD<=`LHU;    //unsigned half word
            endcase
        end
        7'b0100011:
        begin    //store
            ImmType<=`STYPE;
            case(Fn3)
                3'b000:MemWriteD<=4'b0001;    //byte
                3'b001:MemWriteD<=4'b0011;    //half word
                default:MemWriteD<=4'b1111;   //word
            endcase
        end
        default: ImmType<=`ITYPE;
    endcase
    end

    // always@(*)
    // begin
    //     case (Op)
    //         7'b0110011: begin //R
    //             RegWriteD = `LW;
    //             ImmType = `RTYPE;
    //             MemWriteD = 4'b0000;
    //             RegReadD = 2'b11;
    //             BranchTypeD = `NOBRANCH;
    //             case (Fn3) //funct3
    //                 3'b000: begin //ADD/SUB
    //                     case (Fn7) //funct7, like -0000000- src2 src1 ADD/SLT/SLTU dest opcode
    //                         7'b0000000: begin
    //                             AluContrlD = `ADD;
    //                         end
    //                         7'b0100000: begin
    //                             AluContrlD = `SUB;
    //                         end
    //                         default: begin //illegal
    //                             AluContrlD = 4'bxxxx;
    //                         end
    //                     endcase
    //                 end
    //                 3'b001: begin
    //                     AluContrlD = `SLL;
    //                 end
    //                 3'b010: begin
    //                     AluContrlD = `SLT;
    //                 end
    //                 3'b011: begin
    //                     AluContrlD = `SLTU;
    //                 end
    //                 3'b100: begin
    //                     AluContrlD = `XOR;
    //                 end
    //                 3'b101: begin //SRL&SRA
    //                     case (Fn7)
    //                         7'b0000000: begin
    //                             AluContrlD = `SRL;
    //                         end
    //                         7'b0100000: begin
    //                             AluContrlD = `SRA;
    //                         end
    //                         default: begin //illegal
    //                             AluContrlD = 4'bxxxx;
    //                         end
    //                     endcase
    //                 end
    //                 3'b110: begin
    //                     AluContrlD = `OR;
    //                 end
    //                 3'b111: begin
    //                     AluContrlD = `AND;
    //                 end
    //                 default: begin //illegal
    //                     AluContrlD = 4'bxxxx;
    //                 end
    //             endcase
    //         end
    //         7'b0010011: begin //I
    //             RegWriteD = `LW;
    //             ImmType = `ITYPE;
    //             MemWriteD = 4'b0000;
    //             RegReadD = 2'b10;
    //             BranchTypeD = `NOBRANCH;
    //             case (Fn3) //funct3
    //                 3'b000: begin //ADDI
    //                     AluContrlD = `ADD;
    //                 end
    //                 3'b001: begin //SLLI
    //                     AluContrlD = `SLL;
    //                 end
    //                 3'b010: begin //SLTI
    //                     AluContrlD = `SLT;
    //                 end
    //                 3'b011: begin //SLTIU
    //                     AluContrlD = `SLTU;
    //                 end
    //                 3'b100: begin //XORI
    //                     AluContrlD = `XOR;
    //                 end
    //                 3'b101: begin //SRL&SRA
    //                     case (Fn7)
    //                         7'b0000000: begin //SRLI
    //                             AluContrlD = `SRL;
    //                         end
    //                         7'b0100000: begin //SRAI
    //                             AluContrlD = `SRA;
    //                         end
    //                         default: begin //illegal
    //                             AluContrlD = 4'bxxxx;
    //                         end
    //                     endcase
    //                 end
    //                 3'b110: begin //ORI
    //                     AluContrlD = `OR;
    //                 end
    //                 3'b111: begin //ANDI
    //                     AluContrlD = `AND;
    //                 end
    //                 default: begin //illegal
    //                     AluContrlD = 4'bxxxx;
    //                 end
    //             endcase
    //         end
    //         7'b0110111: begin //LUI
    //             RegWriteD = `LW;
    //             ImmType = `UTYPE;
    //             MemWriteD = 4'b0000;
    //             RegReadD = 2'b00;
    //             AluContrlD = `LUI;
    //             BranchTypeD = `NOBRANCH;
    //         end
    //         7'b0010111: begin //AUIPC
    //             RegWriteD = `LW;
    //             ImmType = `UTYPE;
    //             MemWriteD = 4'b0000;
    //             RegReadD = 2'b00;
    //             AluContrlD = `ADD;
    //             BranchTypeD = `NOBRANCH;
    //         end
    //         7'b1100111: begin //JALR
    //             RegWriteD = `LW;
    //             ImmType = `ITYPE;
    //             MemWriteD = 4'b0000;
    //             RegReadD = 2'b10;
    //             AluContrlD = `ADD;
    //             BranchTypeD = `NOBRANCH;
    //         end
    //         7'b1101111: begin //JAL
    //             RegWriteD = `LW;
    //             ImmType = `JTYPE;
    //             MemWriteD = 4'b0000;
    //             RegReadD = 2'b00;
    //             AluContrlD = `ADD; //ALU加
    //             BranchTypeD = `NOBRANCH;
    //         end
    //         7'b1100011: begin //B
    //             ImmType = `BTYPE;
    //             RegWriteD = `NOREGWRITE;
    //             MemWriteD = 4'b0000;
    //             RegReadD = 2'b11;
    //             AluContrlD = `ADD; //nouse
    //             case (Fn3)
    //                 3'b000: begin
    //                     BranchTypeD = `BEQ;
    //                 end
    //                 3'b001: begin
    //                     BranchTypeD = `BNE;
    //                 end
    //                 3'b100: begin
    //                     BranchTypeD = `BLT;
    //                 end
    //                 3'b101: begin
    //                     BranchTypeD = `BGE;
    //                 end
    //                 3'b110: begin
    //                     BranchTypeD = `BLTU;
    //                 end
    //                 3'b111: begin
    //                     BranchTypeD = `BGEU;
    //                 end
    //                 default: begin //illegal
    //                     BranchTypeD = 3'bxxx;
    //                 end
    //             endcase
    //         end
    //         7'b0000011: begin //LOAD
    //             ImmType = `ITYPE;
    //             MemWriteD = 4'b0000;
    //             RegReadD = 2'b10;
    //             MemWriteD = 4'b0000;
    //             BranchTypeD = `NOBRANCH;
    //             AluContrlD = `ADD;
    //             case (Fn3)
    //                 3'b000: begin
    //                     RegWriteD = `LB;
    //                 end
    //                 3'b001: begin
    //                     RegWriteD = `LH;
    //                 end
    //                 3'b010: begin
    //                     RegWriteD = `LW;
    //                 end
    //                 3'b100: begin
    //                     RegWriteD = `LBU;
    //                 end
    //                 3'b101: begin
    //                     RegWriteD = `LHU;
    //                 end
    //                 default: begin //illegal
    //                     RegWriteD = 3'bxxx;
    //                 end
    //             endcase
    //         end
    //         7'b0100011: begin //STORE
    //             ImmType = `STYPE;
    //             RegWriteD = `NOREGWRITE;
    //             RegReadD = 2'b11;
    //             AluContrlD = `ADD;
    //             BranchTypeD = `NOBRANCH;
    //             case (Fn3)
    //                 3'b000: begin //SB
    //                     MemWriteD = 4'b0001;
    //                 end
    //                 3'b001: begin //SH
    //                     MemWriteD = 4'b0011;
    //                 end
    //                 3'b010: begin //SW
    //                     MemWriteD = 4'b1111;
    //                 end
    //                 default: begin //illegal
    //                     MemWriteD = 4'bxxxx;
    //                 end
    //             endcase
    //         end
    //         //TBC
    //         default: begin //illegal
    //             RegWriteD = 3'bxxx;
    //             MemWriteD = 4'bxxxx;
    //             RegReadD = 2'bxx;
    //             BranchTypeD = 3'bxxx;
    //             AluContrlD = 4'bxxxx;
    //             ImmType = 3'bxxx;
    //         end
    //     endcase
    // end
    // 请补全此处代码

endmodule
