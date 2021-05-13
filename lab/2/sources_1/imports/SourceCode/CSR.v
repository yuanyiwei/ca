`timescale 1ns / 1ps
// OK
/////////////////////////////////////////////

module CSR(
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [11:0] addr, wb_addr,
    input wire [31:0] wb_data,
    output wire [31:0] rd_reg
    );

    reg [31:0] reg_file[31:0];
    integer i;
    initial begin
        for(i = 0; i < 32; i = i + 1)
            reg_file[i][31:0] <= 32'b1;
    end
    always@(negedge clk or posedge rst) begin
        if (rst)
            for (i = 0; i < 32; i = i + 1)
                reg_file[i][31:0] <= 32'b0;
        else if (write_en)
            reg_file[wb_addr] <= wb_data;
    end
    assign rd_reg = reg_file[addr];

endmodule
