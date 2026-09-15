module Seven_Segment_Display(
 input i_clk,i_rst,input [3:0] i_digit0,i_digit1,i_digit2,i_digit3,
 input [3:0] i_digit4,i_digit5,i_digit6,i_digit7,
 output CA,CB,CC,CD,CE,CF,CG, output logic [7:0] o_an);
 logic [12:0] scan_r; logic [3:0] selected; logic [6:0] seg; logic blank;
 always_ff @(posedge i_clk or posedge i_rst)
   if(i_rst) scan_r<='0; else scan_r<=scan_r+1'b1;
 always_comb begin
   case(scan_r[12:10])
    0:selected=i_digit0; 1:selected=i_digit1; 2:selected=i_digit2; 3:selected=i_digit3;
    4:selected=i_digit4; 5:selected=i_digit5; 6:selected=i_digit6; default:selected=i_digit7;
   endcase
   o_an=8'hff; o_an[scan_r[12:10]]=blank;
 end
 Display_digit decoder(.i_digit(selected),.seg(seg),.an(blank));
 assign {CG,CF,CE,CD,CC,CB,CA}=seg;
endmodule

module Display_digit #(parameter bit HEX_MODE=1'b0)(input [3:0] i_digit, output logic [6:0] seg, output logic an);
 always_comb begin
  an=1'b0;
  case(i_digit)
   0:seg=7'b1000000; 1:seg=7'b1111001; 2:seg=7'b0100100; 3:seg=7'b0110000;
   4:seg=7'b0011001; 5:seg=7'b0010010; 6:seg=7'b0000010; 7:seg=7'b1111000;
   8:seg=7'b0000000; 9:seg=7'b0010000;
   10:begin seg=HEX_MODE?7'b0001000:7'b1111111; an=~HEX_MODE; end
   11:begin seg=HEX_MODE?7'b0000011:7'b1111111; an=~HEX_MODE; end
   12:begin seg=HEX_MODE?7'b1000110:7'b1111111; an=~HEX_MODE; end
   13:begin seg=HEX_MODE?7'b0100001:7'b1111111; an=~HEX_MODE; end
   14:begin seg=HEX_MODE?7'b0000110:7'b1111111; an=~HEX_MODE; end
   15:begin seg=HEX_MODE?7'b0001110:7'b1111111; an=~HEX_MODE; end
   default:begin seg=7'b1111111; an=1'b1; end
  endcase
 end
endmodule
