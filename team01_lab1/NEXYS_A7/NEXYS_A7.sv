module NEXYS_A7(
    //Clock signal
    input CLK100MHZ,
    //Switches
    input [15:0]SW,
    //LEDs
    output [15:0]LED,
    //RGB LEDs
    output LED16_B,
    output LED16_G,
    output LED16_R,
    output LED17_B,
    output LED17_G,
    output LED17_R,
    //7 segment display
    output CA,
    output CB,
    output CC,
    output CD,
    output CE,
    output CF,
    output CG,
    output DP,
    output [7:0]AN,
    //CPU Reset Button
    input CPU_RESETN,
    //Buttons
    input BTNC,
    input BTNU,
    input BTNL,
    input BTNR,
    input BTND,
    //Pmod Headers
    inout [10:0]JA,
    inout [10:0]JB,
    inout [10:0]JC,
    inout [10:0]JD,
    inout [4:0]XA_N,
    inout [4:0]XA_P,
    //VGA Connector
    output [3:0]VGA_R,
    output [3:0]VGA_G,
    output [3:0]VGA_B,
    output VGA_HS,
    output VGA_VS,
    //Micro SD Connector
    output SD_RESET,
    input SD_CD,
    inout SD_SCK,
    inout SD_CMD,
    inout [3:0]SD_DAT,
    //Accelerometer
    input ACL_MISO,
    output ACL_MOSI,
    output ACL_SCLK,
    output ACL_CSN,
    input [2:0]ACL_INT,
    //Temperature Sensor
    output TMP_SCL,
    inout TMP_SDA,
    input TMP_INT,
    input TMP_CT,
    //Omnidirectional Microphone
    output M_CLK,
    input M_DATA,
    output M_LRSEL,
    //PWM Audio Amplifier
    output AUD_PWM,
    output AUD_SD,
    //USB-RS232 Interface
    input UART_TXD_IN,
    output UART_RXD_OUT,
    output UART_CTS,
    input UART_RTS,
    //USB HID (PS/2)
    inout PS2_CLK,
    inout PS2_DATA,
    //SMSC Ethernet PHY
    output ETH_MDC,
    inout ETH_MDIO,
    output ETH_RSTN,
    inout ETH_CRSDV,
    inout ETH_RXERR,
    inout [1:0]ETH_RXD,
    output ETH_TXEN,
    output [1:0]ETH_TXD,
    inout ETH_REFCLK,
    inout ETH_INTN,
    //Quad SPI Flash
    inout [3:0]QSPI_DQ,
    output QSPI_CSN
    );
wire [3:0] random_value;
wire scan_value;
Top top0(.i_clk(CLK100MHZ), .i_rst(BTNC), .i_start(BTNU),
         .o_random_out(random_value), .o_scan(scan_value));
logic [3:0] decimal_tens, decimal_ones, selected_digit;
logic [6:0] seg;
assign decimal_tens = (random_value >= 4'd10) ? 4'd1 : 4'd0;
assign decimal_ones = (random_value >= 4'd10) ? (random_value - 4'd10) : random_value;
assign selected_digit = scan_value ? decimal_tens : decimal_ones;
assign {CG,CF,CE,CD,CC,CB,CA} = seg;
assign AN = scan_value ? 8'b11111101 : 8'b11111110;
always_comb begin
  case(selected_digit)
   4'd0: seg = 7'b1000000;
   4'd1: seg = 7'b1111001;
   4'd2: seg = 7'b0100100;
   4'd3: seg = 7'b0110000;
   4'd4: seg = 7'b0011001;
   4'd5: seg = 7'b0010010;
   4'd6: seg = 7'b0000010;
   4'd7: seg = 7'b1111000;
   4'd8: seg = 7'b0000000;
   default: seg = 7'b0010000;
  endcase
end
assign DP = 1'b1;
assign LED = 16'b0;
assign {LED16_B,LED16_G,LED16_R,LED17_B,LED17_G,LED17_R} = 6'b0;
assign {VGA_R,VGA_G,VGA_B,VGA_HS,VGA_VS} = 14'b0;
assign SD_RESET = 1'b0;
assign {ACL_MOSI,ACL_SCLK,ACL_CSN} = 3'b001;
assign TMP_SCL = 1'b1;
assign {M_CLK,M_LRSEL,AUD_PWM,AUD_SD} = 4'b0;
assign {UART_RXD_OUT,UART_CTS} = 2'b11;
assign {ETH_MDC,ETH_RSTN,ETH_TXEN,ETH_TXD} = 5'b0;
assign QSPI_CSN = 1'b1;
endmodule
