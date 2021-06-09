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
reg valid [BTB_LEN];

wire [BTB_BIT_LEN - 1:0] PC_F_pos = PC_F[BTB_BIT_LEN + 1:2];
wire [BTB_BIT_LEN - 1:0] PC_E_pos = PC_E[BTB_BIT_LEN + 1:2];

assign predicted_valid = ((branch_PC[PC_F_pos] == PC_F)) ? 1'b1 : 1'b0;
assign predicted_PC = ((branch_PC[PC_F_pos] == PC_F)) ? target_PC[PC_F_pos] : 32'b0;

wire is_PCE_branch = (br_type_E != `NOBRANCH);

always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        for (integer i = 0; i < BTB_LEN; i++)
        begin
            valid[i] <= 1'b0;
            branch_PC[i] <= 32'b0;
            target_PC[i] <= 32'b0;
        end
    end
    else
    begin
        if (is_PCE_branch & branch_E)
        begin
            branch_PC[PC_E_pos] <= PC_E;
            target_PC[PC_E_pos] <= target_E;
        end
    end
end

endmodule
