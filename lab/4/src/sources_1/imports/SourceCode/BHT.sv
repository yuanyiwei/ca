`timescale 1ns / 1ps

`include "Parameters.v"
module BHT #(
    parameter BHT_BIT_LEN = 12
)(
    input clk,
    input rst,
    input [31:0] PC_F,
    input [31:0] PC_E,
    input branch_E,
    input [31:0] target_E,
    input [2:0] br_type_E,
    output predicted_valid
);

localparam BHT_LEN = 1 << BHT_BIT_LEN;

reg [31:0] branch_PC [BHT_LEN];
reg [1:0] state [BHT_LEN];
wire [BHT_BIT_LEN - 1:0] PC_F_pos = PC_F[BHT_BIT_LEN + 1:2];
wire [BHT_BIT_LEN - 1:0] PC_E_pos = PC_E[BHT_BIT_LEN + 1:2];

assign predicted_valid = ((branch_PC[PC_F_pos] == PC_F) & state[PC_F_pos][1]) ? 1'b1 : 1'b0;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (integer i = 0; i < BHT_LEN; i++) begin
            state[i] <= 2'b0;
            branch_PC[i] <= 32'b0;
        end
    end
    else begin
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
    end
end

endmodule
