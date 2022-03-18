

/* adong9 alexander */
`timescale 1ns / 1ps
`default_nettype none

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/
//       ADD, MUL, SUB, DIV, MOD,
//       AND, NOT, OR, XOR, SLL, 
//       SRA, SRL, CONST, HICONST,LDR, 
        // STR,CMP, CMPU, CMPI, CMPIU,
        // BR, JMP, JMPR, JSR, JSRR, 
        // RTI, TRAP, ADDI,ANDI):
      wire [3:0] temp;
      wire [15:0] four;
      wire [4:0] isncode;

      wire cin;
      assign cin = 1'b0;
      
      assign isncode = ((i_insn[15:12] == 4'b0001) & (i_insn[5:3] == 3'b000)) ? 5'd0:
                        (i_insn[15:12] == 4'b0001 & i_insn[5:3] == 3'b001) ? 5'd1:
                        (i_insn[15:12] == 4'b0001 & i_insn[5:3] == 3'b010) ? 5'd2:
                        (i_insn[15:12] == 4'b0001 & i_insn[5:3] == 3'b011) ? 5'd3:
                        (i_insn[15:12] == 4'b1010 & i_insn[5:4] == 2'b11) ? 5'd4:
                        (i_insn[15:12] == 4'b0101 & i_insn[5:3] == 3'b000) ? 5'd5:
                        (i_insn[15:12] == 4'b0101 & i_insn[5:3] == 3'b001) ? 5'd6:
                        (i_insn[15:12] == 4'b0101 & i_insn[5:3] == 3'b010) ? 5'd7:
                        (i_insn[15:12] == 4'b0101 & i_insn[5:3] == 3'b011) ? 5'd8:
                        (i_insn[15:12] == 4'b1010 & i_insn[5:4] == 2'b00)  ? 5'd9:
                        
                        (i_insn[15:12] == 4'b1010 & i_insn[5:4] == 2'b01)  ? 5'd10:
                         (i_insn[15:12] == 4'b1010 & i_insn[5:4] == 2'b10) ? 5'd11:
                           (i_insn[15:12] == 4'b1001) ? 5'd12:
                           (i_insn[15:12] == 4'b1101) ? 5'd13:
                         (i_insn[15:12] == 4'b0110)  ? 5'd14:

                         (i_insn[15:12] == 4'b0111) ? 5'd15:
                         (i_insn[15:12] == 4'b0010 & i_insn[8:7] == 2'b00)  ? 5'd16:
                         (i_insn[15:12] == 4'b0010 & i_insn[8:7] == 2'b01)  ? 5'd17:
                         (i_insn[15:12] == 4'b0010 & i_insn[8:7] == 2'b10)  ? 5'd18:
                         (i_insn[15:12] == 4'b0010 & i_insn[8:7] == 2'b11)  ? 5'd19:

                         (i_insn[15:12] == 4'b0000)  ? 5'd20:
                        (i_insn[15:11] == 5'b11001)  ? 5'd21:
                          (i_insn[15:11] == 5'b11000)  ? 5'd22:
                          (i_insn[15:11] == 5'b01001)  ? 5'd23:
                        (i_insn[15:11] == 5'b01000)  ? 5'd24:
                        (i_insn[15:12] == 4'b1000)  ? 5'd25: 
                        (i_insn[15:12] == 4'b1111) ? 5'd26 :
                        (i_insn[15:12] == 4'b0001 & i_insn[5] == 1'b1) ? 5'd27://addi
                        (i_insn[15:12] == 4'b0101 & i_insn[5] == 1'b1) ? 5'd28: //andi
                        5'd29;





      
        // RTI, TRAP,NOP):
      wire [15:0] temp16,temp17,temp18, mod,div,sub,add, addi;
      cla16 h0(.a(i_r1data),.b(i_r2data),.cin(cin),.sum(add));
      cla16 h1(.a(i_r1data), .b(16'b1111111111111111 * i_r2data),.cin(cin),.sum(sub));
      cla16 h4(.a(i_r1data), .b({{11{i_insn[4]}}, i_insn[4:0]}),.cin(cin),.sum(addi));
      lc4_divider h2(.i_dividend(i_r1data),.i_divisor(i_r2data),.o_remainder(mod),.o_quotient(div));

      assign temp17 = $signed(i_r1data) >>> i_insn[3:0];

       assign o_result = (isncode === 5'd0) ? add :
                        (isncode === 5'd1) ? i_r1data * i_r2data :
                        (isncode === 5'd2) ? sub :
                        (isncode === 5'd3) ? div :
                        (isncode === 5'd4) ? mod :
                        (isncode === 5'd5) ? i_r1data & i_r2data :
                        (isncode === 5'd6) ?  ~ i_r1data:
                        (isncode === 5'd7) ?  i_r1data | i_r2data:
                        (isncode === 5'd8) ? i_r1data ^ i_r2data:
                        (isncode === 5'd9) ? i_r1data << i_insn[3:0]:
                        (isncode === 5'd10) ? temp17 :
                        (isncode === 5'd11) ? i_r1data >> i_insn[3:0]:
                        (isncode === 5'd12) ? (i_insn[8] == 1'b0 ? {7'd0, i_insn[8:0]}:{7'b1111111, i_insn[8:0]}):
                        (isncode === 5'd13) ? (i_r1data & 'hFF) | (i_insn[7:0] << 8):
                        (isncode === 5'd14) ? (i_insn[5] == 1'b0 ? i_r1data + {10'd0,i_insn[5:0]} : i_r1data +  {10'b1111111111,i_insn[5:0]}):
                        (isncode === 5'd15) ?  (i_insn[5] == 1'b0 ? i_r1data + {10'd0, i_insn[5:0]} : i_r1data + {10'b1111111111, i_insn[5:0]}):
                        (isncode === 5'd16) ? (i_r1data == i_r2data ? 16'd0 :  $signed(i_r1data) > $signed(i_r2data) ? 16'd1 :'hFFFF):
                        (isncode === 5'd17) ? (i_r1data == i_r2data ? 16'd0 :  i_r1data > i_r2data ? 16'd1 :'hFFFF):
                        (isncode === 5'd18) ?  (i_r1data == {{9{i_insn[6]}},i_insn[6:0]} ? 16'd0 : $signed(i_r1data) > $signed(i_insn[6:0]) ? 16'd1 : 'hFFFF):
                        (isncode === 5'd19) ? (i_r1data == i_insn[6:0] ? 16'd0 :  i_r1data > i_insn[6:0] ? 16'd1 :'hFFFF):
                        (isncode === 5'd20) ? (i_insn[8] == 1'b0 ? i_pc + 1 + {7'd0, i_insn[8:0]}: i_pc + 1 + {7'b1111111, i_insn[8:0]}): 
                        (isncode === 5'd21) ? (i_insn[10] == 1'b0 ? i_pc + 1 + {5'd0, i_insn[10:0]}: i_pc + 1 + {5'b11111, i_insn[10:0]}):
                        (isncode === 5'd22) ? i_r1data:
                        (isncode === 5'd23) ? (i_pc & 'h8000) | (i_insn[10:0] <<4):
                        (isncode === 5'd24) ? i_r1data:
                        (isncode === 5'd25) ?  i_r1data:
                        (isncode === 5'd26) ? ('h8000 | i_insn[7:0]) : 
                        (isncode === 5'd27) ? addi:
                        (isncode === 5'd28) ? i_r1data & {{11{i_insn[4]}},i_insn[4:0]}:
                        i_pc + 1;      
endmodule