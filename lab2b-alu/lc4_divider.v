/* TODO: adong9 */

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);
    wire [15:0] tmp_q, tmp_r;
    wire [271:0] inter_q , inter_r , inter_dd ;
    assign tmp_q = 16'd0;
    assign tmp_r = 16'd0;
    

    assign inter_q [271:256] = tmp_q;
    assign inter_r[271:256] = tmp_r[15:0];
    assign inter_dd[271:256] = i_dividend[15:0];

    genvar i;
    generate
        for (i = 0; i < 16; i = i+1) begin
            lc4_divider_one_iter h0(.i_dividend(inter_dd[271-(i*16):271-(i*16) - 15]),
            .i_remainder(inter_r[271-(i*16):271-(i*16) - 15]),
            .i_quotient(inter_q[271-(i*16):271-(i*16) - 15]),
            .i_divisor(i_divisor[15:0]),
            .o_dividend(inter_dd[271-((i+1)*16) :271-((i+1)*16) - 15]),
            .o_remainder(inter_r[271-((i+1)*16) :271-((i+1)*16) - 15]),
            .o_quotient(inter_q[271-((i+1)*16)  :271-((i+1)*16) - 15])
            );
        end
    endgenerate
    assign o_remainder = i_divisor == 16'd0 ? tmp_r:inter_r[15:0];
    assign o_quotient = i_divisor == 16'd0 ? tmp_q:inter_q[15:0];
          

endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);
    wire [15:0] tmp_r;
    assign tmp_r = (i_remainder << 1) | (i_dividend>> 15) & 1'b1;
    assign o_quotient = tmp_r < i_divisor ? i_quotient << 1 : i_quotient << 1 | 1'b1;
    assign o_remainder = tmp_r < i_divisor ? tmp_r : tmp_r - i_divisor;
    assign o_dividend = i_dividend << 1;
endmodule

