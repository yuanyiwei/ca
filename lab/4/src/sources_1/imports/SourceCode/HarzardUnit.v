`timescale 1ns / 1ps
// OK
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Wu Yuzhang
//
// Design Name: RISCV-Pipline CPU
// Module Name: HarzardUnit
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Deal with harzards in pipline
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //HarzardUnit用来处理流水线冲突，通过插入气泡，forward以及冲刷流水段解决数据相关和控制相关，组合逻辑电路
    //可以最后实现。前期测试CPU正确性时，可以在每两条指令间插入四条空指令，然后直接把本模块输出定为，不forward，不stall，不flush
//输入
    //CpuRst                                    外部信号，用来初始化CPU，当CpuRst==1时CPU全局复位清零（所有段寄存器flush），Cpu_Rst==0时cpu开始执行指令
    //ICacheMiss, DCacheMiss                    为后续实验预留信号，暂时可以无视，用来处理cache miss
    //BranchE, JalrE, JalD                      用来处理控制相关
    //Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW     用来处理数据相关，分别表示源寄存器1号码，源寄存器2号码，目标寄存器号码
    //RegReadE RegReadD[1]==1                   表示A1对应的寄存器值被使用到了，RegReadD[0]==1表示A2对应的寄存器值被使用到了，用于forward的处理
    //RegWriteM, RegWriteW                      用来处理数据相关，RegWrite!=3'b0说明对目标寄存器有写入操作
    //MemToRegE                                 表示Ex段当前指令 从Data Memory中加载数据到寄存器中
//输出
    //StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW    控制五个段寄存器进行stall（维持状态不变）和flush（清零）
    //Forward1E, Forward2E                                                              控制forward
//实验要求
    //补全模块


module HarzardUnit(
    input wire CpuRst, ICacheMiss, DCacheMiss,
    input wire BranchE, JalrE, JalD,
    input wire [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
    input wire [1:0] RegReadE,
    input wire MemToRegE,
    input wire [2:0] RegWriteM, RegWriteW,
    output reg StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW,
    output reg [1:0] Forward1E, Forward2E,
    input wire miss,
    //CSR
    input wire CSRRead, CSRWriteM, CSRWriteW,
    input wire [11:0] CSRSrcE, CSRSrcM, CSRSrcW,
    output reg [1:0] Forward3E,
    input wire predicted_EX_error
    );

    // 请补全此处代码
    always @(*) begin
        if (RegWriteM && RegReadE[1] && RdM==Rs1E && RdM)
            Forward1E <= 2'b10;
        else if (RegWriteW && RegReadE[1] && RdW==Rs1E && RdW)
            Forward1E <= 2'b01;
        else
            Forward1E <= 2'b00;
    end

    always @(*) begin
        if (RegWriteM && RegReadE[0] && RdM==Rs2E && RdM)
            Forward2E <= 2'b10;
        else if (RegWriteW && RegReadE[0] && RdW==Rs2E && RdW)
            Forward2E <= 2'b01;
        else
            Forward2E <= 2'b00;
    end

    //CSR
    always @(*) begin
        if (CSRWriteM && CSRRead && CSRSrcM==CSRSrcE)
            Forward3E <= 2'b10;
        else if (CSRWriteW && CSRRead && CSRSrcW==CSRSrcE)
            Forward3E <= 2'b01;
        else
            Forward3E <= 2'b00;
    end

    always @(*) begin
        {StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW} <= 0;
        if (CpuRst)
            {FlushF, FlushD, FlushE, FlushM, FlushW} <= 5'b11111;
        else if (miss)
            {StallF, StallD, StallE, StallM, StallW} <= 5'b11111;
        else if (BranchE) begin
            if (predicted_EX_error)
                {FlushD, FlushE} <= 2'b11;
            else
                {FlushD, FlushE} <= 2'b00;
        end
        else if (JalrE)
            {FlushD, FlushE} <= 2'b11;
        else if (MemToRegE & ((RdE==Rs1D)||(RdE==Rs2D)))
            {StallF, StallD, FlushE} <= 3'b111;
        else if (JalD)
            FlushD <= 1;
        else if (predicted_EX_error)
            {FlushD, FlushE} <= 2'b11;
    end
    // 请补全此处代码

endmodule
