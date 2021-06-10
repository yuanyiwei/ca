`timescale 1ns / 1ps

`include "Parameters.v"
module BTB #(
    parameter BTB_BIT_LEN = 12
)(
    input clk,
    input rst,
    input [31:0] PC_F,
    input [31:0] PC_E,
    input branch_E,
    input [2:0] br_type_E,
    input [31:0] target_E,
    output [31:0] predicted_PC,
    output predicted_valid
);

localparam BTB_LEN = 1 << BTB_BIT_LEN;

reg [31:0] branch_PC [BTB_LEN];
reg [31:0] target_PC [BTB_LEN];
wire [BTB_BIT_LEN-1:0] PCF_Map = PC_F[BTB_BIT_LEN+1:2];
wire [BTB_BIT_LEN-1:0] PCE_Map = PC_E[BTB_BIT_LEN+1:2];

assign predicted_valid = (branch_PC[PCF_Map] == PC_F) ? 1'b1 : 1'b0;
assign predicted_PC = (predicted_valid) ? target_PC[PCF_Map] : 32'b0;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (integer i = 0; i < BTB_LEN; i++) begin
            branch_PC[i] <= 32'b0;
            target_PC[i] <= 32'b0;
        end
    end
    else begin
        if ((br_type_E != `NOBRANCH) & branch_E) begin
            branch_PC[PCE_Map] <= PC_E;
            target_PC[PCE_Map] <= target_E;
        end
    end
end

endmodule
