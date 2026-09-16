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
    
    
// Asynchronous assertion, synchronous release of the global reset.
(* ASYNC_REG = "TRUE" *) logic [1:0] reset_sync;
always_ff @(posedge CLK100MHZ or posedge BTNC) begin
    if (BTNC) reset_sync <= 2'b11;
    else reset_sync <= {reset_sync[0], 1'b0};
end
wire rst = reset_sync[1];
(* ASYNC_REG = "TRUE" *) logic btnu_meta, btnu_sync;
logic btnu_prev;
wire BTNU_down = btnu_sync & ~btnu_prev;
wire [3:0] random_value;
wire scan_value;
wire [3:0] decimal_tens = (random_value >= 4'd10) ? 4'd1 : 4'd0;
wire [3:0] decimal_ones = (random_value >= 4'd10) ? (random_value - 4'd10) : random_value;
// Two-flop synchronization plus one-cycle rising-edge pulse.
always_ff @(posedge CLK100MHZ or posedge rst) begin
    if (rst) begin
        btnu_meta <= 1'b0;
        btnu_sync <= 1'b0;
        btnu_prev <= 1'b0;
    end else begin
        btnu_meta <= BTNU;
        btnu_sync <= btnu_meta;
        btnu_prev <= btnu_sync;
    end
end
Top top0(.i_clk(CLK100MHZ), .i_rst(rst), .i_start(BTNU_down),
         .o_random_out(random_value), .o_scan(scan_value));
// Display decimal 00-15 on two multiplexed digits; six digits are blank (10).
Seven_Segment_Display display(
    .i_clk(CLK100MHZ), .i_rst(rst), .i_scan(scan_value),
    .i_digit0(decimal_ones), .i_digit1(decimal_tens),
    .i_digit2(4'd10), .i_digit3(4'd10), .i_digit4(4'd10),
    .i_digit5(4'd10), .i_digit6(4'd10), .i_digit7(4'd10),
    .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG), .o_an(AN));
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
