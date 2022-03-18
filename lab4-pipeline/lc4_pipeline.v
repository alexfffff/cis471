/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none
 
module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire [15:0]  i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input wire [7:0]   switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
   
   /*** YOUR CODE HERE ***/
   //PC 
   wire [15:0] pc_pc;      // Current program counter (read out from pc_reg)
   wire [15:0] pc_next_pc,pc_plus_one; // next_pc might be a differnt pc

   Nbit_reg #(16, 16'h8200) pc_reg (.in(pc_next_pc), .out(pc_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   cla16 h3 (.a(pc_pc),.b(16'd1),.cin(1'd0),.sum(pc_plus_one));
   assign pc_next_pc = (should_stall) ? pc_pc: pc_plus_one;
   assign o_cur_pc = pc_pc;
   
   Nbit_reg #(16,16'd0) pcd_pc(.in(pc_pc), .out(d_pc), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) pcd_insn(.in(i_cur_insn), .out(d_cur_insn), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) pcd_dmem(.in(i_cur_dmem_data),.out(d_cur_dmem), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   // D
   wire [15:0] d_pc, d_cur_insn, d_cur_dmem;

   wire [15:0] d_rs_data, d_rt_data;
   wire [2:0] d_r1sel,d_r2sel,d_wsel;
   wire d_r1re,d_r2re,d_regfile_we,d_nzp_we,d_select_pc_plus_one,d_is_load,d_is_store,d_is_branch,d_is_control_insn;
   //
   wire [15:0] t_d_pc, t_d_cur_insn, t_d_cur_dmem, d_pc_plus_one;

   assign t_d_pc = (should_stall) ? x_pc: d_pc;
   assign t_d_cur_insn = (should_stall) ? x_cur_insn: d_cur_insn;
   assign t_d_cur_dmem = (should_stall) ? x_cur_dmem: d_cur_dmem;
   
   cla16 h6 (.a(t_d_pc),.b(16'd1),.cin(1'd0),.sum(d_pc_plus_one));
   lc4_decoder h0(.insn(t_d_cur_insn), .r1sel(d_r1sel),.r2sel(d_r2sel),.wsel(d_wsel),.r1re(d_r1re),.r2re(d_r2re),
   .regfile_we(d_regfile_we),.nzp_we(d_nzp_we),.select_pc_plus_one(d_select_pc_plus_one),
   .is_load(d_is_load),.is_store(d_is_store),.is_branch(d_is_branch),.is_control_insn(d_is_control_insn));

   lc4_regfile h1(.clk(clk), .gwe(gwe), .rst(rst), .o_rs_data(d_rs_data), .i_rs(d_r1sel), .i_rt(d_r2sel), .o_rt_data(d_rt_data), .i_rd(w_wsel), .i_wdata(w_rd_data), .i_rd_we(w_regfile_we));
   

   Nbit_reg #(16,16'd0) dx_pc(.in(t_d_pc), .out(x_pc), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) dx_insn(.in(t_d_cur_insn), .out(x_cur_insn), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) dx_dmem(.in(t_d_cur_dmem),.out(x_cur_dmem), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) dx_rs_data(.in(d_rs_data), .out(x_rs_data), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) dx_rt_data(.in(d_rt_data), .out(x_rt_data), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) dx_r1sel(.in(d_r1sel), .out(x_r1sel), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) dx_r2sel(.in(d_r2sel), .out(x_r2sel), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) dx_wsel(.in(d_wsel), .out(x_wsel), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_r1re(.in(d_r1re), .out(x_r1re), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_r2re(.in(d_r2re), .out(x_r2re), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_regfile_we(.in(d_regfile_we), .out(x_regfile_we), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_nzp_we(.in(d_nzp_we), .out(x_nzp_we), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_select_pc_plus_one(.in(d_select_pc_plus_one), .out(x_select_pc_plus_one), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_is_load(.in(d_is_load), .out(x_is_load), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_is_store(.in(d_is_store), .out(x_is_store), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_is_branch(.in(d_is_branch), .out(x_is_branch), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) dx_is_control_insn(.in(d_is_control_insn), .out(x_is_control_insn), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));

   // r0-7
   //X 
   wire [15:0] x_pc,x_cur_insn,x_cur_dmem, x_rs_data, x_rt_data;
   wire [2:0] x_r1sel,x_r2sel,x_wsel;
   wire x_r1re,x_r2re,x_regfile_we,x_nzp_we,x_select_pc_plus_one,x_is_load,x_is_store,x_is_branch,x_is_control_insn;
   
   wire [15:0] x_rd_data,x_alu_result;
   //
   wire [15:0] t_x_pc, t_x_cur_insn, t_x_cur_dmem;
   
   assign t_x_pc = (should_stall) ? 16'd1: x_pc;
   assign t_x_cur_insn = (should_stall) ? 16'd0: x_cur_insn;
   assign t_x_cur_dmem = (should_stall) ? 16'd0: x_cur_dmem;
   
   wire [15:0] t_rs_data, t_rt_data, x_pc_plus_one,x_nzp_check;
   wire [2:0] x_last_nzp_bit, x_new_nzp_bit;
   wire x_nzp_result;
   cla16 h7 (.a(x_pc),.b(16'd1),.cin(1'd0),.sum(x_pc_plus_one));
   
   //mx and wx bypass logic that goes in to X 
   assign t_rs_data = (m_wsel == x_r1sel) ? m_rd_data : (w_wsel == x_r1sel)? w_rd_data: x_rs_data;
   assign t_rs_data = (m_wsel == x_r1sel) ? m_rd_data : (w_wsel == x_r1sel)? w_rd_data: x_rs_data;
   


   lc4_alu h2(.i_insn(t_x_cur_insn),.i_pc(t_x_pc),.i_r1data(t_rs_data),.i_r2data(t_rt_data),.o_result(x_alu_result));
   
   assign x_rd_data = (x_is_load) ? t_x_cur_dmem : (x_select_pc_plus_one) ? x_pc_plus_one : (x_regfile_we) ? x_alu_result : 16'd0;

   assign x_nzp_check = (x_is_load ) ? t_x_cur_dmem:(x_is_control_insn & x_regfile_we) ? 16'd1: x_alu_result;

   assign x_new_nzp_bit = (should_stall) ? x_last_nzp_bit: (x_nzp_check == 16'd0) ? 3'b010 :  ($signed(x_nzp_check) > $signed(16'd0)) ? 3'b001 : 3'b100;
   Nbit_reg #(3, 3'b000) nzp_reg (.in(x_new_nzp_bit), .out(x_last_nzp_bit), .clk(clk), .we(x_nzp_we), .gwe(gwe), .rst(rst)); 
   assign x_nzp_result = (t_x_cur_insn[11:9] & x_last_nzp_bit) > 3'd0;

   
   wire should_stall;
   assign should_stall = (x_is_load) && (((d_r1sel == x_wsel) || (d_r2sel == x_wsel)) && (d_is_store == 0));


   Nbit_reg #(16,16'd0) xm_pc(.in(t_x_pc), .out(m_pc), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_insn(.in(t_x_cur_insn), .out(m_cur_insn), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_cur_dmem(.in(t_x_cur_dmem), .out(m_cur_dmem), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_alu_result(.in(x_alu_result), .out(m_alu_result), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_rs_data(.in(x_rs_data), .out(m_rs_data), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_rt_data(.in(x_rt_data), .out(m_rt_data), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) xm_rd_data(.in(x_rd_data), .out(m_rd_data), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) xm_r1sel(.in(x_r1sel), .out(m_r1sel), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) xm_r2sel(.in(x_r2sel), .out(m_r2sel), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) xm_wsel(.in(x_wsel), .out(m_wsel), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_r1re(.in(x_r1re), .out(m_r1re), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_r2re(.in(x_r2re), .out(m_r2re), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_regfile_we(.in(x_regfile_we), .out(m_regfile_we), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_nzp_we(.in(x_nzp_we), .out(m_nzp_we), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_select_pc_plus_one(.in(x_select_pc_plus_one), .out(m_select_pc_plus_one), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_is_load(.in(x_is_load), .out(m_is_load), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_is_store(.in(x_is_store), .out(m_is_store), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_is_branch(.in(x_is_branch), .out(m_is_branch), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) xm_is_control_insn(.in(x_is_control_insn), .out(m_is_control_insn), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));

   // M 
   wire [15:0] m_pc,m_cur_insn,m_cur_dmem,m_alu_result, m_rs_data, m_rt_data, m_rd_data;
   wire [2:0] m_r1sel,m_r2sel,m_wsel;
   wire m_r1re,m_r2re,m_regfile_we,m_nzp_we,m_select_pc_plus_one,m_is_load,m_is_store,m_is_branch,m_is_control_insn;
   
   wire m_dmem_addr,m_dmem_we;
   
   // WM bypass
   wire [15:0] m_dmem_towrite;
   assign m_dmem_addr = (m_is_store || m_is_load) ? m_alu_result : 16'd0;
   assign m_dmem_we = m_is_store;
   // assign next_pc = ((is_branch & nzp_result) || is_control_insn)  ? alu_result: pc_plus_one;
   assign m_dmem_towrite = (w_is_load & m_is_store & (m_r2sel == w_wsel)) ? w_rd_data: (m_is_store ) ? m_rt_data : 16'd0;
   
   assign o_dmem_we = m_dmem_we;
   assign o_dmem_towrite = m_dmem_towrite;
   assign o_dmem_addr = m_dmem_addr;

   Nbit_reg #(16,16'd0) mw_pc(.in(m_pc), .out(w_pc), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_insn(.in(m_cur_insn), .out(w_cur_insn), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_alu_result(.in(m_alu_result), .out(w_alu_result), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_rs_data(.in(m_rs_data), .out(w_rs_data), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_rt_data(.in(m_rt_data), .out(w_rt_data), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(16,16'd0) mw_rd_data(.in(m_rd_data), .out(w_rd_data), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) mw_r1sel(.in(m_r1sel), .out(w_r1sel), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) mw_r2sel(.in(m_r2sel), .out(w_r2sel), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(3,3'b000) mw_wsel(.in(m_wsel), .out(w_wsel), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_r1re(.in(m_r1re), .out(w_r1re), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_r2re(.in(m_r2re), .out(w_r2re), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_regfile_we(.in(m_regfile_we), .out(w_regfile_we), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_nzp_we(.in(m_nzp_we), .out(w_nzp_we), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_select_pc_plus_one(.in(m_select_pc_plus_one), .out(w_select_pc_plus_one), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_is_load(.in(m_is_load), .out(w_is_load), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_is_store(.in(m_is_store), .out(w_is_store), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_is_branch(.in(m_is_branch), .out(w_is_branch), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   Nbit_reg #(1,1'b0) mw_is_control_insn(.in(m_is_control_insn), .out(w_is_control_insn), .we(1'b1), .gwe(gwe), .rst(rst), .clk(clk));
   
   //W 
   wire [15:0] w_pc,w_cur_insn,w_alu_result, w_rs_data, w_rt_data, w_rd_data;
   wire [2:0] w_r1sel,w_r2sel,w_wsel;
   wire w_r1re,w_r2re,w_regfile_we,w_nzp_we,w_select_pc_plus_one,w_is_load,w_is_store,w_is_branch,w_is_control_insn;

   wire [1:0] stall_value;
   assign stall_value = (w_pc == 16'd0 ) ? 2'd2: (should_stall) ? 2'd3 :2'd0;
   //
   
   wire [15:0] t_w_rs_data, t_w_rt_data;   

   //
   assign test_stall = stall_value;
   assign test_cur_pc = w_pc;
   assign test_cur_insn = w_cur_insn;
   assign test_regfile_we = w_regfile_we;
   assign test_regfile_wsel = w_wsel;
   assign test_regfile_data = w_rd_data;
   assign test_nzp_we = x_nzp_we;
   assign test_nzp_new_bits = x_new_nzp_bit ;
   assign test_dmem_we = m_dmem_we;
   assign test_dmem_addr = m_dmem_addr;
   assign test_dmem_data =  (m_is_store) ? m_dmem_towrite : (m_is_load) ? m_cur_dmem: 16'd0 ;
   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
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

      $display("x_pc: %h, insn: %b, nzp_check: %h, new_nzp_bit: %d , last_nzp_bit: %d, rd_data: %b, nzp_we: %d, alu_result: %h,stall:%d",t_x_pc, t_x_cur_insn, x_nzp_check, x_new_nzp_bit, x_last_nzp_bit, x_rd_data, x_nzp_we, x_alu_result, should_stall);
      // // Start each $display() format string with a %d argument for time
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
