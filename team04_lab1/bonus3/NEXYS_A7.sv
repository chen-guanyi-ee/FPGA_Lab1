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


wire BTNU_down;
wire BTNL_down;
wire BTND_down;
wire BTNR_down;
wire [3:0] digit0,digit1,digit2,digit3,digit4,digit5,digit6,digit7;

// values coming from Top (all 0-63, binary)
wire [5:0] current_val;   // 目前數字
wire [5:0] capture_val;   // 即時抓取
wire [5:0] record_val;    // 紀錄
wire [5:0] max_val;       // 最大值
wire [15:0] led_progress;
wire paused;

    // -----------------------------------------------------------------
    // SW[6:0] priority encoder -> how many bits the random number uses.
    // Highest switch that is ON wins, e.g. SW[4]=1 (others don't matter
    // below it) -> range becomes 0 ~ 2^4-1 = 15.
    // If none of SW[6:0] are on, fall back to the original 0~15 range.
    // SW[15:7] are not used.
    // -----------------------------------------------------------------
    logic [2:0] range_bits;
    always_comb begin
        if      (SW[6]) range_bits = 3'd6;   // 0 ~ 63
        else if (SW[5]) range_bits = 3'd5;   // 0 ~ 31
        else if (SW[4]) range_bits = 3'd4;   // 0 ~ 15
        else if (SW[3]) range_bits = 3'd3;   // 0 ~ 7
        else if (SW[2]) range_bits = 3'd2;   // 0 ~ 3
        else if (SW[1]) range_bits = 3'd1;   // 0 ~ 1
        else if (SW[0]) range_bits = 3'd0;   // 0 only
        else             range_bits = 3'd4;   // default: 0 ~ 15
    end

    Seven_Segment_Display seven0(
    	.i_clk(CLK100MHZ),
    	.i_rst(BTNC),
    	.i_digit0(digit0),
    	.i_digit1(digit1),
    	.i_digit2(digit2),
    	.i_digit3(digit3),
    	.i_digit4(digit4),
    	.i_digit5(digit5),
    	.i_digit6(digit6),
    	.i_digit7(digit7),
    	.CA(CA),
    	.CB(CB),
    	.CC(CC),
    	.CD(CD),
    	.CE(CE),
    	.CF(CF),
    	.CG(CG),
    	.o_an(AN)
    );

    Debounce deb0(
        .i_in(BTNU),
        .i_clk(CLK100MHZ),
        .i_rst(BTNC),
        .o_pos(BTNU_down)
    );

    Debounce deb1(
        .i_in(BTNL),
        .i_clk(CLK100MHZ),
        .i_rst(BTNC),
        .o_pos(BTNL_down)
    );

    Debounce deb2(
        .i_in(BTND),
        .i_clk(CLK100MHZ),
        .i_rst(BTNC),
        .o_pos(BTND_down)
    );

    Debounce deb3(
        .i_in(BTNR),
        .i_clk(CLK100MHZ),
        .i_rst(BTNC),
        .o_pos(BTNR_down)
    );

    Top top0(
	.i_clk(CLK100MHZ),
	.i_rst(BTNC),
	.i_pause(BTNR_down),
	.i_freq_up(BTNU_down),
	.i_freq_down(BTND_down),
	.i_capture(BTNL_down),
	.i_range_bits(range_bits),
	.o_random_out(current_val),
	.o_capture(capture_val),
	.o_record(record_val),
	.o_max(max_val),
	.o_led(led_progress),
	.o_paused(paused)
    );

    // ---------------------------------------------------------------
    // Binary (0-63) -> two decimal digits (tens/units), for each of
    // the 4 quantities shown on the seven-segment display.
    // ---------------------------------------------------------------
    wire [3:0] current_tens  = current_val  / 10;
    wire [3:0] current_units = current_val  % 10;

    wire [3:0] capture_tens  = capture_val  / 10;
    wire [3:0] capture_units = capture_val  % 10;

    wire [3:0] record_tens   = record_val   / 10;
    wire [3:0] record_units  = record_val   % 10;

    wire [3:0] max_tens      = max_val      / 10;
    wire [3:0] max_units     = max_val      % 10;

    // Display layout (left -> right) :  最大值 | 紀錄 | 即時抓取 | 目前數字
    // AN7 (leftmost) ... AN0 (rightmost)
    assign digit7 = max_tens;
    assign digit6 = max_units;
    assign digit5 = record_tens;
    assign digit4 = record_units;
    assign digit3 = capture_tens;
    assign digit2 = capture_units;
    assign digit1 = current_tens;
    assign digit0 = current_units;

    // LED bar: reflects the currently SELECTED speed (BTNU/BTND), not
    // elapsed time - more LEDs lit means the selected speed is slower.
    assign LED = led_progress;

    // decimal point lights up while paused, as a visual "pause" indicator
    assign DP = paused ? 1'b0 : 1'b1;

endmodule
