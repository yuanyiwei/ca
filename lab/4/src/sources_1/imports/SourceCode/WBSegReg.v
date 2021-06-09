`timescale 1ns / 1ps
// OK
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Wu Yuzhang
//
// Design Name: RISCV-Pipline CPU
// Module Name: WBSegReg
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Write Back Segment Register
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //WBSegReg是Write Back段寄存器，
    //类似于IDSegReg.V中对Bram的调用和拓展，它同时包含了一个同步读写的Bram
    //（此处你可以调用我们提供的InstructionRam，它将会自动综合为block memory，你也可以替代性的调用xilinx的bram ip核）。
    //同步读memory 相当于 异步读memory 的输出外接D触发器，需要时钟上升沿才能读取数据。
    //此时如果再通过段寄存器缓存，那么需要两个时钟上升沿才能将数据传递到Ex段
    //因此在段寄存器模块中调用该同步memory，直接将输出传递到WB段组合逻辑
    //调用mem模块后输出为RD_raw，通过assign RD = stall_ff ? RD_old : (clear_ff ? 32'b0 : RD_raw );
    //从而实现RD段寄存器stall和clear功能
//实验要求
    //你需要补全WBSegReg模块，需补全的片段截取如下
    //DataRam DataRamInst (
    //    .clk    (???),                      //请完善代码
    //    .wea    (???),                      //请完善代码
    //    .addra  (???),                      //请完善代码
    //    .dina   (???),                      //请完善代码
    //    .douta  ( RD_raw         ),
    //    .web    ( WE2            ),
    //    .addrb  ( A2[31:2]       ),
    //    .dinb   ( WD2            ),
    //    .doutb  ( RD2            )
    //);
//注意事项
    //输入到DataRam的addra是字地址，一个字32bit
    //请配合DataExt模块实现非字对齐字节load
    //请通过补全代码实现非字对齐store

`include "../CacheSrcCode/cache_param.v"

module WBSegReg(
    input wire clk,
    input wire en,
    input wire clear,
    //Data Memory Access
    input wire [31:0] A,
    input wire [31:0] WD,
    input wire [3:0] WE,
    output wire [31:0] RD,
    output reg [1:0] LoadedBytesSelect,
    //Data Memory Debug
    input wire [31:0] A2,
    input wire [31:0] WD2,
    input wire [3:0] WE2,
    output wire [31:0] RD2,
    //input control signals
    input wire [31:0] ResultM,
    output reg [31:0] ResultW,
    input wire [4:0] RdM,
    output reg [4:0] RdW,
    //output constrol signals
    input wire [2:0] RegWriteM,
    output reg [2:0] RegWriteW,
    input wire [1:0] MemToRegM,
    output reg [1:0] MemToRegW,
    //CSR signals
    input wire [11:0] CSRaddrM,
    output reg [11:0] CSRaddrW,
    input wire [31:0] CSROutM,
    output reg [31:0] CSROutW,
    input wire CSRwrenM,
    output reg CSRwrenW,
    input wire MemReadM,
    output wire miss
    );

    initial begin
        LoadedBytesSelect = 2'b00;
        RegWriteW         =  1'b0;
        MemToRegW         =  1'b0;
        ResultW           =     0;
        RdW               =  5'b0;
        CSRaddrW          =     0;
        CSROutW           =     0;
        CSRwrenW          =     0;
    end
    always@(posedge clk)
        if(en) begin
            LoadedBytesSelect <= clear ? 2'b00 : A[1:0];
            RegWriteW         <= clear ?  1'b0 : RegWriteM;
            MemToRegW         <= clear ?  1'b0 : MemToRegM;
            ResultW           <= clear ?     0 : ResultM;
            RdW               <= clear ?  5'b0 : RdM;
            CSRaddrW          <= clear ?  5'b0 : CSRaddrM;
            CSROutW           <= clear ?  5'b0 : CSROutM;
            CSRwrenW          <= clear ?  5'b0 : CSRwrenM;
        end

    wire [31:0] RD_raw;
    wire wr_req;
    assign wr_req=|WE;
    cache #(
        .LINE_ADDR_LEN  (`C_LINE_ADDR_LEN),
        .SET_ADDR_LEN   (`C_SET_ADDR_LEN ),
        .TAG_ADDR_LEN   (`C_TAG_ADDR_LEN ),
        .WAY_CNT        (`C_WAY_CNT      )
        )  CacheInst (
        .clk    (clk     ),
        .rst    (rst     ),
        .miss   (miss    ),
        .addr   (A[31:0] ),
        .rd_req (MemReadM),
        .rd_data(RD_raw  ),
        .wr_req (wr_req  ),
        .wr_data(wd_shift)
    );
    // 以下部分无需修改
    reg stall_ff= 1'b0;
    reg clear_ff= 1'b0;
    reg [31:0] RD_old=32'b0;
    always @ (posedge clk)
    begin
        stall_ff<=~en;
        clear_ff<=clear;
        RD_old<=RD_raw;
    end
    assign RD = stall_ff ? RD_old : (clear_ff ? 32'b0 : RD_raw);

    wire rd_request;
    reg dmiss, drd_request, dwr_req;
    wire missen, rd_reqen, wr_reqen;
    reg [31:0] miss_count, req_count;
    assign rd_request = MemReadM;
    assign missen = (miss==1)&(dmiss==0);
    assign rd_reqen = (rd_request==1)&(drd_request==0);
    assign wr_reqen = (wr_req==1)&(dwr_req==0);

    always @(posedge clk) begin
        if (miss) dmiss <= 1;
        else dmiss <= 0;

        if (rd_request) drd_request <= 1;
        else drd_request <= 0;

        if (wr_req) dwr_req<=1;
        else dwr_req<=0;
    end

    always @(posedge clk) begin
        if (rst) begin
            miss_count <= 0;
            req_count <= 0;
        end
        else begin
            if (missen)
                miss_count <= miss_count+1;
            if (rd_reqen|wr_reqen)
                req_count <= req_count+1;
        end
    end
endmodule
