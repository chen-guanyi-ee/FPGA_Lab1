module Seven_Segment_Display(
 input i_clk,i_rst,input i_scan,input [3:0] random_value,
 output CA,CB,CC,CD,CE,CF,CG, output logic [7:0] o_an);
 logic scan_r; logic [3:0] selected; logic [3:0] decimal_tens, decimal_ones; logic [6:0] seg;
 assign scan_r = i_scan;
 assign decimal_tens = (random_value >= 4'd10) ? 4'd1 : 4'd0;
 assign decimal_ones = (random_value >= 4'd10) ? (random_value - 4'd10) : random_value;
 always_comb begin
   selected = scan_r ? decimal_tens : decimal_ones;
   // Active-low enables: only digit0 or digit1 is enabled at a time.
   o_an = scan_r ? 8'b11111101 : 8'b11111110;
 end
 Display_digit decoder(.i_digit(selected),.seg(seg));
 assign {CG,CF,CE,CD,CC,CB,CA}=seg;
endmodule

module Display_digit(input [3:0] i_digit, output logic [6:0] seg);
 always_comb begin
  case(i_digit)
   0:seg=7'b1000000; 1:seg=7'b1111001; 2:seg=7'b0100100; 3:seg=7'b0110000;
   4:seg=7'b0011001; 5:seg=7'b0010010; 6:seg=7'b0000010; 7:seg=7'b1111000;
   8:seg=7'b0000000; 9:seg=7'b0010000;
   default: seg=7'b1111111;
  endcase
 end
endmodule
