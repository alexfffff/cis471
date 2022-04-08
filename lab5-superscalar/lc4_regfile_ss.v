`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */ 
module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

   /*** TODO: Your Code Here ***/
   // two cases either its the same or its different
   wire [n-1:0] r0v, r1v,r2v,r3v,r4v,r5v,r6v,r7v, data0,data1,data2,data3,data4,data5,data6,data7;  
   wire we_0,we_1,we_2,we_3,we_4,we_5,we_6,we_7; 
   assign data0 = ((i_rd_B == 3'd0) & i_rd_we_B) ? i_wdata_B: (i_rd_A == 3'd0) ? i_wdata_A: 16'd0;
   assign we_0 = ((i_rd_B == 3'd0) & i_rd_we_B) ? i_rd_we_B: (i_rd_A == 3'd0) ? i_rd_we_A: 0;
   assign data1 = ((i_rd_B == 3'd1) & i_rd_we_B)  ? i_wdata_B: (i_rd_A == 3'd1) ? i_wdata_A: 16'd0;
   assign we_1 = ((i_rd_B == 3'd1) & i_rd_we_B) ? i_rd_we_B: (i_rd_A == 3'd1) ? i_rd_we_A: 0;
   assign data2 = ((i_rd_B == 3'd2) & i_rd_we_B)  ? i_wdata_B: (i_rd_A == 3'd2) ? i_wdata_A: 16'd0;
   assign we_2 = ((i_rd_B == 3'd2) & i_rd_we_B) ? i_rd_we_B: (i_rd_A == 3'd2) ? i_rd_we_A: 0;
   assign data3 = ((i_rd_B == 3'd3) & i_rd_we_B)  ? i_wdata_B: (i_rd_A == 3'd3) ? i_wdata_A: 16'd0;
   assign we_3 = ((i_rd_B == 3'd3) & i_rd_we_B) ? i_rd_we_B: (i_rd_A == 3'd3) ? i_rd_we_A: 0;
   assign data4 = ((i_rd_B == 3'd4) & i_rd_we_B)  ? i_wdata_B: (i_rd_A == 3'd4) ? i_wdata_A: 16'd0;
   assign we_4 = ((i_rd_B == 3'd4) & i_rd_we_B) ? i_rd_we_B: (i_rd_A == 3'd4) ? i_rd_we_A: 0;
   assign data5 = ((i_rd_B == 3'd5) & i_rd_we_B)  ? i_wdata_B: (i_rd_A == 3'd5) ? i_wdata_A: 16'd0;
   assign we_5 = ((i_rd_B == 3'd5) & i_rd_we_B) ? i_rd_we_B: (i_rd_A == 3'd5) ? i_rd_we_A: 0;
   assign data6 = ((i_rd_B == 3'd6) & i_rd_we_B)  ? i_wdata_B: (i_rd_A == 3'd6) ? i_wdata_A: 16'd0;
   assign we_6 = ((i_rd_B == 3'd6) & i_rd_we_B) ? i_rd_we_B: (i_rd_A == 3'd6) ? i_rd_we_A: 0;
   assign data7 = ((i_rd_B == 3'd7) & i_rd_we_B)  ? i_wdata_B: (i_rd_A == 3'd7) ? i_wdata_A: 16'd0;
   assign we_7 =((i_rd_B == 3'd7) & i_rd_we_B) ? i_rd_we_B: (i_rd_A == 3'd7) ? i_rd_we_A: 0;
   
   Nbit_reg #(n) r0(.in(data0), .out(r0v), .clk(clk),.gwe(gwe),.rst(rst),.we(we_0));
   Nbit_reg #(n) r1(.in(data1), .out(r1v), .clk(clk),.gwe(gwe),.rst(rst),.we(we_1));
   Nbit_reg #(n) r2(.in(data2), .out(r2v), .clk(clk),.gwe(gwe),.rst(rst),.we(we_2));
   Nbit_reg #(n) r3(.in(data3), .out(r3v), .clk(clk),.gwe(gwe),.rst(rst),.we(we_3));
   Nbit_reg #(n) r4(.in(data4), .out(r4v), .clk(clk),.gwe(gwe),.rst(rst),.we(we_4));
   Nbit_reg #(n) r5(.in(data5), .out(r5v), .clk(clk),.gwe(gwe),.rst(rst),.we(we_5));
   Nbit_reg #(n) r6(.in(data6), .out(r6v), .clk(clk),.gwe(gwe),.rst(rst),.we(we_6));
   Nbit_reg #(n) r7(.in(data7), .out(r7v), .clk(clk),.gwe(gwe),.rst(rst),.we(we_7));

   assign o_rs_data_A = ((i_rs_A == i_rd_B) & i_rd_we_B) ? i_wdata_B : ((i_rs_A == i_rd_A) & i_rd_we_A) ? i_wdata_A :
                        (i_rs_A == 3'd0) ? r0v:
                        (i_rs_A == 3'd1) ? r1v:
                        (i_rs_A == 3'd2) ? r2v:
                        (i_rs_A == 3'd3) ? r3v:
                        (i_rs_A == 3'd4) ? r4v:
                        (i_rs_A == 3'd5) ? r5v:
                        (i_rs_A == 3'd6) ? r6v:
                        (i_rs_A == 3'd7) ? r7v:
                        r0v;

   assign o_rt_data_A = ((i_rt_A == i_rd_B) & i_rd_we_B) ? i_wdata_B : ((i_rt_A == i_rd_A) & i_rd_we_A) ? i_wdata_A :
                        (i_rt_A == 3'd0) ? r0v:
                        (i_rt_A == 3'd1) ? r1v:
                        (i_rt_A == 3'd2) ? r2v:
                        (i_rt_A == 3'd3) ? r3v:
                        (i_rt_A == 3'd4) ? r4v:
                        (i_rt_A == 3'd5) ? r5v:
                        (i_rt_A == 3'd6) ? r6v:
                        (i_rt_A == 3'd7) ? r7v:
                        r0v;

   assign o_rs_data_B = ((i_rs_B == i_rd_B) & i_rd_we_B) ? i_wdata_B : ((i_rs_B == i_rd_A) & i_rd_we_A) ? i_wdata_A :
                        (i_rs_B == 3'd0) ? r0v:
                        (i_rs_B == 3'd1) ? r1v:
                        (i_rs_B == 3'd2) ? r2v:
                        (i_rs_B == 3'd3) ? r3v:
                        (i_rs_B == 3'd4) ? r4v:
                        (i_rs_B == 3'd5) ? r5v:
                        (i_rs_B == 3'd6) ? r6v:
                        (i_rs_B == 3'd7) ? r7v:
                        r0v;

   assign o_rt_data_B = ((i_rt_B == i_rd_B) & i_rd_we_B) ? i_wdata_B : ((i_rt_B == i_rd_A) & i_rd_we_A) ? i_wdata_A :
                        (i_rt_B == 3'd0) ? r0v:
                        (i_rt_B == 3'd1) ? r1v:
                        (i_rt_B == 3'd2) ? r2v:
                        (i_rt_B == 3'd3) ? r3v:
                        (i_rt_B == 3'd4) ? r4v:
                        (i_rt_B == 3'd5) ? r5v:
                        (i_rt_B == 3'd6) ? r6v:
                        (i_rt_B == 3'd7) ? r7v:
                        r0v;
endmodule
