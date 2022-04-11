/* TODO: INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);
  assign cout[0] = gin[0] | (pin[0] & cin);
  genvar i;
  generate
    for (i = 1; i < 3; i = i+1) begin
      assign cout[i] = gin[i] | (pin[i] & cout[i-1]);
    end

  endgenerate

  assign gout = gin[0] & pin[1] & pin[2] & pin[3] | gin[1] & pin[2] & pin[3] | gin[2] & pin[3] | gin[3];
  assign pout = pin[0] & pin[1] & pin[2] & pin[3];

endmodule

/**
 * 16-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);
  wire [15:0] g, p;
  wire [3:0] gout,pout;
  wire [16:0] c;
  assign c[0] = cin;
  genvar i;
  generate
    for (i = 0; i < 16; i = i+1) begin
      gp1 h0(.a(a[i]),.b(b[i]),.g(g[i]),.p(p[i]));
    end
    for (i = 0; i <4; i= i+1) begin
      gp4 h1(.gin(g[4*i+3:4*i]), .pin(p[4*i+3:4*i]),.cin(c[4*i]),.gout(gout[i]),.pout(pout[i]),.cout(c[4*i + 3: 4*i + 1]));
      assign c[(i+1)*4] = gout[i] | (pout[i] & c[i*4]);

    end
    for (i = 0; i < 16; i = i +1) begin
      assign sum[i] = a[i] ^ b[i] ^ c[i];
    end
  endgenerate
endmodule


/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module empty.
 */
module gpn
  #(parameter N = 4)
  (input wire [N-1:0] gin, pin,
   input wire  cin,
   output wire gout, pout,
   output wire [N-2:0] cout);
 
endmodule
