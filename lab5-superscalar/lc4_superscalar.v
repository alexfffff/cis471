`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_processor(input wire         clk,             // main clock
                     input wire         rst,             // global reset
                     input wire         gwe,             // global we for single-step clock

                     output wire [15:0] o_cur_pc,        // address to read from instruction memory
                     input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
                     input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)

                     output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
                     input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
                     output wire        o_dmem_we,       // data memory write enable
                     output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set

                     // testbench signals (always emitted from the WB stage)
                     output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
                     output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

                     output wire [15:0] test_cur_pc_A,       // program counter
                     output wire [15:0] test_cur_pc_B,
                     output wire [15:0] test_cur_insn_A,     // instruction bits
                     output wire [15:0] test_cur_insn_B,
                     output wire        test_regfile_we_A,   // register file write-enable
                     output wire        test_regfile_we_B,
                     output wire [ 2:0] test_regfile_wsel_A, // which register to write
                     output wire [ 2:0] test_regfile_wsel_B,
                     output wire [15:0] test_regfile_data_A, // data to write to register file
                     output wire [15:0] test_regfile_data_B,
                     output wire        test_nzp_we_A,       // nzp register write enable
                     output wire        test_nzp_we_B,
                     output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
                     output wire [ 2:0] test_nzp_new_bits_B,
                     output wire        test_dmem_we_A,      // data memory write enable
                     output wire        test_dmem_we_B,
                     output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
                     output wire [15:0] test_dmem_addr_B,
                     output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
                     output wire [15:0] test_dmem_data_B,

                     // zedboard switches/display/leds (ignore if you don't want to control these)
                     input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
                     output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
                     );

   /***  YOUR CODE HERE ***/
   //PC ////////////////////////////////////////////////////////////////////
   wire [15:0] pc_pc, t_pc_pc_A,t_pc_cur_insn_A;
   wire [15:0] t_pc_pc_B,t_pc_cur_insn_B;      
   wire [15:0] pc_next_pc,pc_plus_one,pc_plus_two; 

   Nbit_reg #(16, 16'h8200) pc_reg (.in(pc_next_pc), .out(pc_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   

   assign o_cur_pc = (should_branch) ? 16'd3 : pc_pc;
   
   cla16 h3 (.a(o_cur_pc),.b(16'd2),.cin(1'd0),.sum(pc_plus_two));
   cla16 h4 (.a(o_cur_pc),.b(16'd1),.cin(1'd0),.sum(pc_plus_one));

   // assign pc_next_pc = (should_branch) ? x_alu_result_A: (d_should_stall) ? pc_pc: pc_plus_two;   
   assign pc_next_pc = (d_should_stall_A & d_should_stall_B) ? pc_pc: (d_should_stall_A || d_should_stall_B) ? pc_plus_one : pc_plus_two;   

   assign t_pc_pc_A = (d_should_stall_A) ? d_pc_A: o_cur_pc;
   assign t_pc_cur_insn_A = (should_branch) ? 16'd3: (d_should_stall_A) ? d_cur_insn_A: i_cur_insn_A;

   assign t_pc_pc_B = (d_should_stall_A) ? d_pc_B: pc_plus_one;
   assign t_pc_cur_insn_B = (should_branch) ? 16'd3: (d_should_stall_B) ? d_cur_insn_B: i_cur_insn_B;
   
   Nbit_reg #(16,16'd0) pcd_pc_B(.in(t_pc_pc_B), .out(d_pc_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) pcd_insn_B(.in(t_pc_cur_insn_B), .out(d_cur_insn_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));

// D ////////////////////////////////////////////////////////////////////////
   wire [15:0] d_pc_A, d_cur_insn_A;
   wire [15:0] d_pc_B, d_cur_insn_B;

   wire [15:0] d_rs_data_A, d_rt_data_A;
   wire [15:0] d_rs_data_B, d_rt_data_B;
   wire [2:0] d_r1sel_A,d_r2sel_A,d_wsel_A;
   wire [2:0] d_r1sel_B,d_r2sel_B,d_wsel_B;
   wire d_r1re_A,d_r2re_A,d_regfile_we_A,d_nzp_we_A,d_select_pc_plus_one_A,d_is_load_A,d_is_store_A,d_is_branch_A,d_is_control_insn_A,
        d_r1re_B,d_r2re_B,d_regfile_we_B,d_nzp_we_B,d_select_pc_plus_one_B,d_is_load_B,d_is_store_B,d_is_branch_B,d_is_control_insn_B;

   wire [15:0] t_d_pc_A, t_d_cur_insn_A, d_pc_plus_one_A, t_d_rs_data_A, t_d_rt_data_A,
               t_d_pc_B, t_d_cur_insn_B, d_pc_plus_one_B, t_d_rs_data_B, t_d_rt_data_B;
   
   assign t_d_pc_A = (should_branch) ? 16'd3 : d_pc_A;
   assign t_d_cur_insn_A = (should_branch) ? 16'd3: d_cur_insn_A;
   
   assign t_d_pc_B = (should_branch) ? 16'd3 : d_pc_B;
   assign t_d_cur_insn_B = (should_branch) ? 16'd3: d_cur_insn_B;

   cla16 h6 (.a(t_d_pc_A),.b(16'd1),.cin(1'd0),.sum(d_pc_plus_one_A));
   lc4_decoder h0(.insn(t_d_cur_insn_A), .r1sel(d_r1sel_A),.r2sel(d_r2sel_A),.wsel(d_wsel_A),.r1re(d_r1re_A),.r2re(d_r2re_A),
   .regfile_we(d_regfile_we_A),.nzp_we(d_nzp_we_A),.select_pc_plus_one(d_select_pc_plus_one_A),
   .is_load(d_is_load_A),.is_store(d_is_store_A),.is_branch(d_is_branch_A),.is_control_insn(d_is_control_insn_A));

   cla16 h6_B (.a(t_d_pc_B),.b(16'd1),.cin(1'd0),.sum(d_pc_plus_one_B));
   lc4_decoder h0_B(.insn(t_d_cur_insn_B), .r1sel(d_r1sel_B),.r2sel(d_r2sel_B),.wsel(d_wsel_B),.r1re(d_r1re_B),.r2re(d_r2re_B),
   .regfile_we(d_regfile_we_B),.nzp_we(d_nzp_we_B),.select_pc_plus_one(d_select_pc_plus_one_B),
   .is_load(d_is_load_B),.is_store(d_is_store_B),.is_branch(d_is_branch_B),.is_control_insn(d_is_control_insn_B));

   lc4_regfile_ss h1(.clk(clk), .gwe(gwe), .rst(rst), .i_rs_A(d_r1sel_A), .o_rs_data_A(d_rs_data_A), .i_rt_A(d_r2sel_A), .o_rt_data_A(d_rt_data_A),
                     .i_rs_B(d_r1sel_B), .o_rs_data_B(d_rs_data_B), .i_rt_B(d_r2sel_B), .o_rt_data_B(d_rt_data_B), .i_rd_A(w_wsel_A), .i_wdata_A(w_rd_data_A),
                     .i_rd_we_A(w_regfile_we_A), .i_rd_B(w_wsel_B), .i_wdata_B(w_rd_data_B), .i_rd_we_B(w_regfile_we_B));

   // bypass logic already handled by regfile
   // assign t_d_rs_data = ((w_wsel == d_r1sel) && w_regfile_we) ? w_rd_data: d_rs_data;
   // assign t_d_rt_data = ((w_wsel == d_r2sel) && w_regfile_we)? w_rd_data: d_rt_data; 

   wire [15:0] in_d_pc_A, in_d_cur_insn_A;
   wire [15:0] in_d_pc_B, in_d_cur_insn_B;

   assign in_d_pc_A = (d_should_stall_A) ? 16'd1: t_d_pc_A;
   assign in_d_cur_insn_A = (d_should_stall_A) ? 16'd1: t_d_cur_insn_A;

   assign in_d_pc_B = (d_should_stall_B) ? 16'd1: t_d_pc_B;
   assign in_d_cur_insn_B = (d_should_stall_B) ? 16'd1: t_d_cur_insn_B;
   
   wire d_should_stall_A, d_should_stall_B;
   //assign d_should_stall = (x_is_load && t_x_cur_insn > 16'd4) && ((((d_r1sel == x_wsel) && d_r1re) || ((d_r2sel == x_wsel) && d_r2re) && (d_is_store == 0)) || (d_is_branch));
   assign d_should_stall_A = 1'd0;
   assign d_should_stall_B = 1'd0;
   
   Nbit_reg #(16,16'd0) dx_pc_A(.in(in_d_pc_A), .out(x_pc_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) dx_insn_A(.in(in_d_cur_insn_A), .out(x_cur_insn_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) dx_rs_data_A(.in(t_d_rs_data_A), .out(x_rs_data_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) dx_rt_data_A(.in(t_d_rt_data_A), .out(x_rt_data_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) dx_r1sel_A(.in(d_r1sel_A), .out(x_r1sel_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) dx_r2sel_A(.in(d_r2sel_A), .out(x_r2sel_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) dx_wsel_A(.in(d_wsel_A), .out(x_wsel_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_r1re_A(.in(d_r1re_A), .out(x_r1re_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_r2re_A(.in(d_r2re_A), .out(x_r2re_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_regfile_we_A(.in(d_regfile_we_A), .out(x_regfile_we_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_nzp_we_A(.in(d_nzp_we_A), .out(x_nzp_we_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_select_pc_plus_one_A(.in(d_select_pc_plus_one_A), .out(x_select_pc_plus_one_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_is_load_A(.in(d_is_load_A), .out(x_is_load_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_is_store_A(.in(d_is_store_A), .out(x_is_store_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_is_branch_A(.in(d_is_branch_A), .out(x_is_branch_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_is_control_insn_A(.in(d_is_control_insn_A), .out(x_is_control_insn_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_should_stall_A(.in(d_should_stall_A), .out(x_should_stall_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));

   Nbit_reg #(16,16'd0) dx_pc_B(.in(in_d_pc_B), .out(x_pc_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) dx_insn_B(.in(in_d_cur_insn_B), .out(x_cur_insn_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) dx_rs_data_B(.in(t_d_rs_data_B), .out(x_rs_data_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) dx_rt_data_B(.in(t_d_rt_data_B), .out(x_rt_data_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) dx_r1sel_B(.in(d_r1sel_B), .out(x_r1sel_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) dx_r2sel_B(.in(d_r2sel_B), .out(x_r2sel_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) dx_wsel_B(.in(d_wsel_B), .out(x_wsel_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_r1re_B(.in(d_r1re_B), .out(x_r1re_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_r2re_B(.in(d_r2re_B), .out(x_r2re_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_regfile_we_B(.in(d_regfile_we_B), .out(x_regfile_we_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_nzp_we_B(.in(d_nzp_we_B), .out(x_nzp_we_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_select_pc_plus_one_B(.in(d_select_pc_plus_one_B), .out(x_select_pc_plus_one_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_is_load_B(.in(d_is_load_B), .out(x_is_load_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_is_store_B(.in(d_is_store_B), .out(x_is_store_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_is_branch_B(.in(d_is_branch_B), .out(x_is_branch_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_is_control_insn_B(.in(d_is_control_insn_B), .out(x_is_control_insn_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_should_stall_B(.in(d_should_stall_B), .out(x_should_stall_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
// X ///////////////////////////////////////////////////////////////////////
   wire [15:0] x_pc_A,x_cur_insn_A, x_rs_data_A, x_rt_data_A, 
               x_pc_B,x_cur_insn_B, x_rs_data_B, x_rt_data_B;
   wire [2:0] x_r1sel_A,x_r2sel_A,x_wsel_A, 
              x_r1sel_B,x_r2sel_B,x_wsel_B;
   wire x_r1re_A,x_r2re_A,x_regfile_we_A,x_nzp_we_A,x_select_pc_plus_one_A,x_is_load_A,x_is_store_A,x_is_branch_A,x_is_control_insn_A,x_should_stall_A,
        x_r1re_B,x_r2re_B,x_regfile_we_B,x_nzp_we_B,x_select_pc_plus_one_B,x_is_load_B,x_is_store_B,x_is_branch_B,x_is_control_insn_B,x_should_stall_B;
   
   wire [15:0] x_alu_result_A, 
               x_alu_result_B;
   //
   wire [15:0] t_x_pc_A, t_x_cur_insn_A, t_x_cur_dmem_A,
               t_x_pc_B, t_x_cur_insn_B, t_x_cur_dmem_B;
   
   assign t_x_pc_A =  x_pc_A;
   assign t_x_cur_insn_A =  x_cur_insn_A;


   assign t_x_pc_B =  x_pc_B;
   assign t_x_cur_insn_B =  x_cur_insn_B;

   
   wire [15:0] t_x_rs_data_A, t_x_rt_data_A, x_nzp_check_A,
               t_x_rs_data_B, t_x_rt_data_B, x_nzp_check_B;

   wire [2:0] x_last_nzp_bit_A, x_new_nzp_bit_A,
              x_last_nzp_bit_B, x_new_nzp_bit_B;
   wire x_nzp_result_A;
   wire x_nzp_result_B;
   
   //mx and wx bypass logic that goes in to X 
   // assign t_x_rs_data = ((m_wsel == x_r1sel && x_r1re) && m_regfile_we && m_cur_insn > 16'd4) ? m_rd_data : ((w_wsel == x_r1sel && x_r1re) && w_regfile_we)? w_rd_data: x_rs_data;
   // assign t_x_rt_data = ((m_wsel == x_r2sel && x_r2re) && m_regfile_we && m_cur_insn > 16'd4) ? m_rd_data : ((w_wsel == x_r2sel && x_r2re) && w_regfile_we)? w_rd_data: x_rt_data;
   assign t_x_rs_data_A = x_rs_data_A;
   assign t_x_rt_data_A = x_rt_data_A;
   assign t_x_rs_data_B = x_rs_data_B;
   assign t_x_rt_data_B = x_rt_data_B;


   lc4_alu h2(.i_insn(t_x_cur_insn_A),.i_pc(t_x_pc_A),.i_r1data(t_x_rs_data_A),.i_r2data(t_x_rt_data_A),.o_result(x_alu_result_A));
   lc4_alu h2_B(.i_insn(t_x_cur_insn_A),.i_pc(t_x_pc_A),.i_r1data(t_x_rs_data_A),.i_r2data(t_x_rt_data_A),.o_result(x_alu_result_A));

   // assign x_nzp_check_A = ((m_is_load_A && m_cur_insn > 16'd4) && (x_nzp_we == 0)) ? i_cur_dmem_data : (x_is_control_insn & x_select_pc_plus_one) ? 16'd1: (x_is_control_insn & x_regfile_we) ? x_alu_result: (x_is_control_insn) ? 16'd1: x_alu_result;

   // assign x_new_nzp_bit = (d_should_stall && t_x_cur_insn > 16'd4 && x_nzp_we == 0) ? x_last_nzp_bit: (x_nzp_check == 16'd0) ? 3'b010 :  ($signed(x_nzp_check) > $signed(16'd0)) ? 3'b001 : 3'b100;
   Nbit_reg #(3, 3'b000) nzp_reg (.in(x_new_nzp_bit_B), .out(x_last_nzp_bit_A), .clk(clk), .we(x_nzp_we_B), .gwe(gwe), .rst(rst)); 
   // assign x_nzp_result = (t_x_cur_insn[11:9] & x_last_nzp_bit) > 3'd0;
   
   wire should_branch;
   // assign should_branch = ((x_is_branch && t_x_cur_insn > 16'd4) && x_nzp_result) || (x_is_control_insn && t_x_cur_insn > 16'd4) ;
   assign should_branch = 1'b0;

   assign x_new_nzp_bit_A = 3'd0;
   assign x_last_nzp_bit_B = x_new_nzp_bit_A;
   assign x_new_nzp_bit_B = 3'd0;
   assign x_nzp_result_A = 0;
   assign x_nzp_result_B = 0;
   
   Nbit_reg #(16,16'd0) xm_pc_A(.in(t_x_pc_A), .out(m_pc_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_insn_A(.in(t_x_cur_insn_A), .out(m_cur_insn_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_alu_result_A(.in(x_alu_result_A), .out(m_alu_result_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_rs_data_A(.in(t_x_rs_data_A), .out(m_rs_data_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_rt_data_A(.in(t_x_rt_data_A), .out(m_rt_data_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) xm_r1sel_A(.in(x_r1sel_A), .out(m_r1sel_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) xm_r2sel_A(.in(x_r2sel_A), .out(m_r2sel_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) xm_wsel_A(.in(x_wsel_A), .out(m_wsel_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_r1re_A(.in(x_r1re_A), .out(m_r1re_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_r2re_A(.in(x_r2re_A), .out(m_r2re_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_regfile_we(.in(x_regfile_we_A), .out(m_regfile_we_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_nzp_we_A(.in(x_nzp_we_A), .out(m_nzp_we_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_select_pc_plus_one_A(.in(x_select_pc_plus_one_A), .out(m_select_pc_plus_one_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_is_load_A(.in(x_is_load_A), .out(m_is_load_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_is_store_A(.in(x_is_store_A), .out(m_is_store_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_is_branch_A(.in(x_is_branch_A), .out(m_is_branch_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_is_control_insn_A(.in(x_is_control_insn_A), .out(m_is_control_insn_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_should_stall_A(.in(x_should_stall_A), .out(m_should_stall_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) xm_new_nzp_bit_A(.in(x_new_nzp_bit_A), .out(m_new_nzp_bit_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));

   Nbit_reg #(16,16'd0) xm_pc_B(.in(t_x_pc_B), .out(m_pc_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_insn_B(.in(t_x_cur_insn_B), .out(m_cur_insn_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_alu_result_B(.in(x_alu_result_B), .out(m_alu_result_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_rs_data_B(.in(t_x_rs_data_B), .out(m_rs_data_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_rt_data_B(.in(t_x_rt_data_B), .out(m_rt_data_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) xm_r1sel_B(.in(x_r1sel_B), .out(m_r1sel_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) xm_r2sel_B(.in(x_r2sel_B), .out(m_r2sel_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) xm_wsel_B(.in(x_wsel_B), .out(m_wsel_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_r1re_B(.in(x_r1re_B), .out(m_r1re_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_r2re_B(.in(x_r2re_B), .out(m_r2re_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_regfile_we_B(.in(x_regfile_we_B), .out(m_regfile_we_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_nzp_we_B(.in(x_nzp_we_B), .out(m_nzp_we_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_select_pc_plus_one_B(.in(x_select_pc_plus_one_B), .out(m_select_pc_plus_one_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_is_load_B(.in(x_is_load_B), .out(m_is_load_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_is_store_B(.in(x_is_store_B), .out(m_is_store_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_is_branch_B(.in(x_is_branch_B), .out(m_is_branch_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_is_control_insn_B(.in(x_is_control_insn_B), .out(m_is_control_insn_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_should_stall_B(.in(x_should_stall_B), .out(m_should_stall_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) xm_new_nzp_bit_B(.in(x_new_nzp_bit_B), .out(m_new_nzp_bit_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
// M /////////////////////////////////////////////////////////////////////////
   wire [15:0] m_pc_A,m_cur_insn_A,m_cur_dmem_A,m_alu_result_A, m_rs_data_A, m_rt_data_A, m_rd_data_A,
               m_pc_B,m_cur_insn_B,m_cur_dmem_B,m_alu_result_B, m_rs_data_B, m_rt_data_B, m_rd_data_B;
   wire [2:0] m_r1sel_A,m_r2sel_A,m_wsel_A, m_new_nzp_bit_A,
              m_r1sel_B,m_r2sel_B,m_wsel_B, m_new_nzp_bit_B;
   wire m_r1re_A,m_r2re_A,m_regfile_we_A,m_nzp_we_A,m_select_pc_plus_one_A,m_is_load_A,m_is_store_A,m_is_branch_A,m_is_control_insn_A, m_should_stall_A,
        m_r1re_B,m_r2re_B,m_regfile_we_B,m_nzp_we_B,m_select_pc_plus_one_B,m_is_load_B,m_is_store_B,m_is_branch_B,m_is_control_insn_B, m_should_stall_B;
   
   wire [15:0] m_dmem_addr_A,
               m_dmem_addr_B; 
   wire m_dmem_we_A, 
        m_dmem_we_B;
   
   // WM bypass
   wire [2:0] t_m_new_nzp_bit_A, t_m_nzp_check_A, t_m_nzp_check2_A,
              t_m_new_nzp_bit_B, t_m_nzp_check_B, t_m_nzp_check2_B;
   wire [15:0] m_dmem_towrite_A,m_pc_plus_one_A,t_m_cur_dmem_A,
               m_dmem_towrite_B,m_pc_plus_one_B,t_m_cur_dmem_B;

   assign t_m_cur_dmem_A = (m_is_load_A) ? i_cur_dmem_data: m_cur_dmem_A;
   assign t_m_cur_dmem_B = (m_is_load_B) ? i_cur_dmem_data: m_cur_dmem_B;

   cla16 h7 (.a(m_pc_B),.b(16'd1),.cin(1'd0),.sum(m_pc_plus_one_A));
   cla16 h7_B (.a(m_pc_B),.b(16'd1),.cin(1'd0),.sum(m_pc_plus_one_B));
   
   assign m_dmem_we_A = m_is_store_A;
   assign m_dmem_towrite_A = (w_is_load_A & m_is_store_A & (m_r2sel_A == w_wsel_A)) ? w_rd_data_A: (m_is_store_A) ? m_rt_data_A : 16'd0;
   assign m_dmem_addr_A = (m_is_store_A || m_is_load_A) ? m_alu_result_A : 16'd0;
   
   assign m_dmem_we_B = m_is_store_B;
   assign m_dmem_towrite_B = (w_is_load_B & m_is_store_B & (m_r2sel_B == w_wsel_B)) ? w_rd_data_B: (m_is_store_B) ? m_rt_data_B : 16'd0;
   assign m_dmem_addr_B = (m_is_store_B || m_is_load_B) ? m_alu_result_B : 16'd0;

   // assign o_dmem_addr = m_dmem_addr;
   // assign o_dmem_we = m_dmem_we;
   // assign o_dmem_towrite = m_dmem_towrite;
   
   assign o_dmem_addr =16'd0;
   assign o_dmem_we = 0;
   assign o_dmem_towrite = 16'd0;

   assign m_rd_data_A = (m_is_load_A) ?  i_cur_dmem_data : (m_select_pc_plus_one_A) ? m_pc_plus_one_A : (m_regfile_we_A) ? m_alu_result_A : 16'd0;
   assign m_rd_data_B = (m_is_load_B) ?  i_cur_dmem_data : (m_select_pc_plus_one_B) ? m_pc_plus_one_B : (m_regfile_we_B) ? m_alu_result_B : 16'd0;

   // assign t_m_nzp_check_A = (i_cur_dmem_data == 16'd0) ? 3'b010 :  ($signed(i_cur_dmem_data) > $signed(16'd0)) ? 3'b001: 3'b100;
   // assign t_m_nzp_check2_A = (m_dmem_towrite == 16'd0) ? 3'b010 :  ($signed(m_dmem_towrite) > $signed(16'd0)) ? 3'b001: 3'b100;

   assign t_m_nzp_check_A = 3'd0;
   assign t_m_nzp_check2_A = 3'd0;
   assign t_m_nzp_check_B = 3'd0;
   assign t_m_nzp_check2_B = 3'd0;

   assign t_m_new_nzp_bit_A = (m_is_load_A) ? t_m_nzp_check_A:(m_is_store_A)? t_m_nzp_check2_A: m_new_nzp_bit_A;
   assign t_m_new_nzp_bit_B = (m_is_load_B) ? t_m_nzp_check_B:(m_is_store_B)? t_m_nzp_check2_B: m_new_nzp_bit_B;

   Nbit_reg #(16,16'd0) mw_pc_A(.in(m_pc_A), .out(w_pc_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_insn_A(.in(m_cur_insn_A), .out(w_cur_insn_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_alu_result_A(.in(m_alu_result_A), .out(w_alu_result_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_rs_data_A(.in(m_rs_data_A), .out(w_rs_data_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_rt_data_A(.in(m_rt_data_A), .out(w_rt_data_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_rd_data_A(.in(m_rd_data_A), .out(w_rd_data_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_dmem_addr_A(.in(m_dmem_addr_A), .out(w_dmem_addr_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_dmem_towrite_A(.in(m_dmem_towrite_A), .out(w_dmem_towrite_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_cur_dmem_A(.in(t_m_cur_dmem_A), .out(w_cur_dmem_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) mw_r1sel_A(.in(m_r1sel_A), .out(w_r1sel_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) mw_r2sel_A(.in(m_r2sel_A), .out(w_r2sel_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) mw_wsel_A(.in(m_wsel_A), .out(w_wsel_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) mw_new_nzp_bit_A(.in(t_m_new_nzp_bit_A), .out(w_new_nzp_bit_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_r1re_A(.in(m_r1re_A), .out(w_r1re_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_r2re_A(.in(m_r2re_A), .out(w_r2re_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_regfile_we_A(.in(m_regfile_we_A), .out(w_regfile_we_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_nzp_we_A(.in(m_nzp_we_A), .out(w_nzp_we_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_select_pc_plus_one_A(.in(m_select_pc_plus_one_A), .out(w_select_pc_plus_one_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_is_load_A(.in(m_is_load_A), .out(w_is_load_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_is_store_A(.in(m_is_store_A), .out(w_is_store_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_is_branch_A(.in(m_is_branch_A), .out(w_is_branch_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_is_control_insn_A(.in(m_is_control_insn_A), .out(w_is_control_insn_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_dmem_we_A(.in(m_dmem_we_A), .out(w_dmem_we_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_should_stall_A(.in(m_should_stall_A), .out(w_should_stall_A), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));

   Nbit_reg #(16,16'd0) mw_pc_B(.in(m_pc_B), .out(w_pc_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_insn_B(.in(m_cur_insn_B), .out(w_cur_insn_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_alu_result_B(.in(m_alu_result_B), .out(w_alu_result_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_rs_data_B(.in(m_rs_data_B), .out(w_rs_data_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_rt_data_B(.in(m_rt_data_B), .out(w_rt_data_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_rd_data_B(.in(m_rd_data_B), .out(w_rd_data_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_dmem_addr_B(.in(m_dmem_addr_B), .out(w_dmem_addr_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_dmem_towrite_B(.in(m_dmem_towrite_B), .out(w_dmem_towrite_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_cur_dmem_B(.in(t_m_cur_dmem_B), .out(w_cur_dmem_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) mw_r1sel_B(.in(m_r1sel_B), .out(w_r1sel_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) mw_r2sel_B(.in(m_r2sel_B), .out(w_r2sel_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) mw_wsel_B(.in(m_wsel_B), .out(w_wsel_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) mw_new_nzp_bit_B(.in(t_m_new_nzp_bit_B), .out(w_new_nzp_bit_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_r1re_B(.in(m_r1re_B), .out(w_r1re_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_r2re_B(.in(m_r2re_B), .out(w_r2re_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_regfile_we_B(.in(m_regfile_we_B), .out(w_regfile_we_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_nzp_we_B(.in(m_nzp_we_B), .out(w_nzp_we_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_select_pc_plus_one_B(.in(m_select_pc_plus_one_B), .out(w_select_pc_plus_one_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_is_load_B(.in(m_is_load_B), .out(w_is_load_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_is_store_B(.in(m_is_store_B), .out(w_is_store_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_is_branch_B(.in(m_is_branch_B), .out(w_is_branch_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_is_control_insn_B(.in(m_is_control_insn_B), .out(w_is_control_insn_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_dmem_we_B(.in(m_dmem_we_B), .out(w_dmem_we_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_should_stall_B(.in(m_should_stall_B), .out(w_should_stall_B), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
// W ///////////////////////////////////////////////////////////////////////////
   wire [15:0] w_pc_A,w_cur_insn_A,w_alu_result_A, w_rs_data_A, w_rt_data_A, w_rd_data_A,w_dmem_addr_A,w_dmem_towrite_A,w_cur_dmem_A,
               w_pc_B,w_cur_insn_B,w_alu_result_B, w_rs_data_B, w_rt_data_B, w_rd_data_B,w_dmem_addr_B,w_dmem_towrite_B,w_cur_dmem_B;
   wire [2:0] w_r1sel_A,w_r2sel_A,w_wsel_A, w_new_nzp_bit_A,
              w_r1sel_B,w_r2sel_B,w_wsel_B, w_new_nzp_bit_B;
   wire w_r1re_A,w_r2re_A,w_regfile_we_A,w_nzp_we_A,w_select_pc_plus_one_A,w_is_load_A,w_is_store_A,w_is_branch_A,w_is_control_insn_A,w_dmem_we_A, w_should_stall_A,
        w_r1re_B,w_r2re_B,w_regfile_we_B,w_nzp_we_B,w_select_pc_plus_one_B,w_is_load_B,w_is_store_B,w_is_branch_B,w_is_control_insn_B,w_dmem_we_B, w_should_stall_B;

   wire [1:0] stall_value_A,
              stall_value_B;
   assign stall_value_A = (w_should_stall_A) ? 2'd3 : (w_cur_insn_A < 16'd4) ? 2'd2  :2'd0;
   assign stall_value_B = (w_should_stall_B) ? 2'd3 : (w_cur_insn_A < 16'd4) ? 2'd2 : 2'd0;
   
   assign test_stall_A = stall_value_A;
   assign test_cur_pc_A = w_pc_A;
   assign test_cur_insn_A = w_cur_insn_A;
   assign test_regfile_we_A = w_regfile_we_A;
   assign test_regfile_wsel_A = w_wsel_A;
   assign test_regfile_data_A = w_rd_data_A;
   assign test_nzp_we_A = w_nzp_we_A;
   assign test_nzp_new_bits_A = w_new_nzp_bit_A;
   assign test_dmem_we_A = w_dmem_we_A;
   assign test_dmem_addr_A = w_dmem_addr_A;
   assign test_dmem_data_A =  (w_is_store_A) ? w_dmem_towrite_A : (w_is_load_A) ? w_cur_dmem_A: 16'd0;

   assign test_stall_B = stall_value_B;
   assign test_cur_pc_B = w_pc_B;
   assign test_cur_insn_B = w_cur_insn_B;
   assign test_regfile_we_B = w_regfile_we_B;
   assign test_regfile_wsel_B = w_wsel_B;
   assign test_regfile_data_B = w_rd_data_B;
   assign test_nzp_we_B = w_nzp_we_B;
   assign test_nzp_new_bits_B = w_new_nzp_bit_B;
   assign test_dmem_we_B = w_dmem_we_B;
   assign test_dmem_addr_B = w_dmem_addr_B;
   assign test_dmem_data_B =  (w_is_store_B) ? w_dmem_towrite_B : (w_is_load_B) ? w_cur_dmem_B: 16'd0;
   
   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // $display("%d %h %h %h %h %h %h", $time, pc_pc, d_pc, x_pc, m_pc, w_pc, test_cur_pc);
      // $display("x_pc: %h, insn: %b, nzp_check: %h, new_nzp_bit: %d , last_nzp_bit: %d, rs_data: %b, nzp_we: %d, alu_result: %h",t_x_pc, t_x_cur_insn, x_nzp_check, x_new_nzp_bit, x_last_nzp_bit, x_rs_data, x_nzp_we, x_alu_result);

      // if (w_wsel == 3'd3 && w_regfile_we)
      //    $display("insn: %b, nzp_check: %h, new_nzp_bit: %d , last_nzp_bit: %d, rs_data: %b, nzp_we: %d, alu_result: %h, rd_data: %b",x_cur_insn, x_nzp_check, x_new_nzp_bit, x_last_nzp_bit, x_rs_data, x_nzp_we, x_alu_result, w_rd_data);

      // if(should_stall)
      //    $display("x_pc: %h, insn: %b, nzp_check: %h, new_nzp_bit: %d , last_nzp_bit: %d, rs_data: %b, rd_data: %b, nzp_we: %d, alu_result: %h,stall:%d",t_x_pc, t_x_cur_insn, x_nzp_check, x_new_nzp_bit, x_last_nzp_bit, x_rs_data, x_rd_data, x_nzp_we, x_alu_result, should_stall);
      // if (x_pc == 16'h820a)
      //    $display("x_pc: %h, insn: %b, nzp_check: %h, new_nzp_bit: %d , last_nzp_bit: %d, rs_data: %b, rd_data: %b, nzp_we: %d, alu_result: %h,stall:%d",t_x_pc, t_x_cur_insn, x_nzp_check, x_new_nzp_bit, x_last_nzp_bit, x_rs_data, x_rd_data, x_nzp_we, x_alu_result, should_stall);
      // if (x_pc == 16'h820d)
      //       $display("x_pc: %h, insn: %b, nzp_check: %h, new_nzp_bit: %d , last_nzp_bit: %d, rd_data: %b, nzp_we: %d, alu_result: %h,stall:%d",t_x_pc, t_x_cur_insn, x_nzp_check, x_new_nzp_bit, x_last_nzp_bit, x_rd_data, x_nzp_we, x_alu_result, should_stall);
      //$display("m_pc: %h, m_dmem_addr:%h,m_isstore: %d,m_dmem_towrite: %h,should_stall: %d",m_pc,m_dmem_addr,m_is_store,m_dmem_towrite,should_stall);

      //$display("w_pc: %h, w_rd_data: %h, w_rd_sel: %d,w_alu_result: %h, m_dmem_addr:%h ,m_alu_result: %h, w_dmem_towrite: %h, w_cur_dmem: %h", w_pc, w_rd_data,w_wsel, w_alu_result,m_dmem_addr, m_alu_result,w_dmem_towrite, w_cur_dmem);
      // if ($time < 6000 && $time > 2000)
      //    $display("x_pc: %h,w_pc: %h, nzp_check: %h, new_nzp_bit: %d , last_nzp_bit: %d, i_dmem_data: %h, x_alu_result: %h",t_x_pc , w_pc, x_nzp_check, x_new_nzp_bit, x_last_nzp_bit, i_cur_dmem_data, x_alu_result);
      
      // if ($time < 800000&& $time > 780000)
      //    //$display("d_pc: %h, x_pc : %h,m_pc: %h, w_pc: %h, w_cur_insn: %h, w_rd_data: %h,in_d_cur_insn: %h, x_alu_result: %h, ss %d%d%d%d%d",t_d_pc,t_x_pc,m_pc, w_pc,w_cur_insn, w_rd_data,in_d_cur_insn, x_alu_result, d_should_stall, x_should_stall, m_should_stall, w_should_stall, should_branch);
      //    $display("x_pc: %h,w_pc: %h, nzp_check: %h, new_nzp_bit: %d , last_nzp_bit: %d, i_dmem_data: %h, x_alu_result: %h",t_x_pc , w_pc, x_nzp_check, x_new_nzp_bit, x_last_nzp_bit, i_cur_dmem_data, x_alu_result);

      
      
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display(); 
   end
`endif
endmodule
