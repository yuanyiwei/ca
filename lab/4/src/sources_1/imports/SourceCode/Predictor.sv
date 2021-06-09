`timescale 1ns / 1ps

`include "Parameters.v"
module Predictor(
    input clk,
    input rst,
    input [31:0] PC_F,
    input [31:0] PC_E,
    input branch_E,
    input [31:0] target_E,
    input [2:0] br_type_E,
    output [31:0] predicted_PC_IF,
    output predicted_valid_IF,
    input [31:0] predicted_PC_EX,
    input  predicted_valid_EX,
    output predicted_EX_error
);

wire valid_btb, valid_bht;
assign predicted_EX_error = (branch_E & ~predicted_valid_EX)
                            | (branch_E & predicted_valid_EX & (target_E != predicted_PC_EX))
                            | (~branch_E & predicted_valid_EX);

integer failure_count, success_count, total_count;
reg [31:0] PC_E_old = 32'b0;

always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        failure_count <= 0;
        success_count <= 0;
        total_count <= 0;
    end
    else
    begin
        if ((br_type_E != `NOBRANCH) & (PC_E != PC_E_old))
        begin
            if (predicted_EX_error)
                failure_count <= failure_count + 1;
            else
                success_count <= success_count + 1;
            total_count <= total_count + 1;
        end
    end
end

always @(posedge clk)
    PC_E_old <= PC_E;

BTB BTB1 (
    .clk(clk),
    .rst(rst),
    .PC_F(PC_F),
    .PC_E(PC_E),
    .br_type_E(br_type_E),
    .branch_E(branch_E),
    .target_E(target_E),
    .predicted_PC(predicted_PC_IF),
    .predicted_valid(valid_btb)
);

BHT BHT1 (
    .clk(clk),
    .rst(rst),
    .PC_F(PC_F),
    .PC_E(PC_E),
    .br_type_E(br_type_E),
    .branch_E(branch_E),
    .target_E(target_E),
    .predicted_valid(valid_bht)
);

assign predicted_valid_IF = valid_btb & valid_bht;

endmodule
