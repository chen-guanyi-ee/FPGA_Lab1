module NEXYS_A7(

    input CLK100MHZ,

    input [15:0] SW,

    output [15:0] LED,

    output LED16_B,
    output LED16_G,
    output LED16_R,
    output LED17_B,
    output LED17_G,
    output LED17_R,

    output CA,
    output CB,
    output CC,
    output CD,
    output CE,
    output CF,
    output CG,
    output DP,
    output [7:0] AN,

    input CPU_RESETN,

    input BTNC,
    input BTNU,
    input BTNL,
    input BTNR,
    input BTND,

    inout [10:0] JA,
    inout [10:0] JB,
    inout [10:0] JC,
    inout [10:0] JD,

    inout [4:0] XA_N,
    inout [4:0] XA_P,

    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HS,
    output VGA_VS,

    output SD_RESET,
    input SD_CD,
    inout SD_SCK,
    inout SD_CMD,
    inout [3:0] SD_DAT,

    input ACL_MISO,
    output ACL_MOSI,
    output ACL_SCLK,
    output ACL_CSN,
    input [2:0] ACL_INT,

    output TMP_SCL,
    inout TMP_SDA,
    input TMP_INT,
    input TMP_CT,

    output M_CLK,
    input M_DATA,
    output M_LRSEL,

    output AUD_PWM,
    output AUD_SD,

    input UART_TXD_IN,
    output UART_RXD_OUT,
    output UART_CTS,
    input UART_RTS,

    inout PS2_CLK,
    inout PS2_DATA,

    output ETH_MDC,
    inout ETH_MDIO,
    output ETH_RSTN,
    inout ETH_CRSDV,
    inout ETH_RXERR,
    inout [1:0] ETH_RXD,
    output ETH_TXEN,
    output [1:0] ETH_TXD,
    inout ETH_REFCLK,
    inout ETH_INTN,

    inout [3:0] QSPI_DQ,
    output QSPI_CSN
);


    // ============================================================
    // Reset synchronization
    // ============================================================

    (* ASYNC_REG = "TRUE" *)
    logic [1:0] reset_sync;

    always_ff @(posedge CLK100MHZ or posedge BTNC) begin
        if (BTNC)
            reset_sync <= 2'b11;
        else
            reset_sync <= {reset_sync[0], 1'b0};
    end

    wire rst = reset_sync[1];


    // ============================================================
    // BTNU synchronizer + rising-edge detection
    // START
    // ============================================================

    (* ASYNC_REG = "TRUE" *)
    logic btnu_meta, btnu_sync;

    logic btnu_prev;

    wire BTNU_down = btnu_sync & ~btnu_prev;

    always_ff @(posedge CLK100MHZ or posedge rst) begin
        if (rst) begin
            btnu_meta <= 1'b0;
            btnu_sync <= 1'b0;
            btnu_prev <= 1'b0;
        end

        else begin
            btnu_meta <= BTNU;
            btnu_sync <= btnu_meta;
            btnu_prev <= btnu_sync;
        end
    end


    // ============================================================
    // BTNL synchronizer + rising-edge detection
    // CAPTURE
    // ============================================================

    (* ASYNC_REG = "TRUE" *)
    logic btnl_meta, btnl_sync;

    logic btnl_prev;

    wire BTNL_down = btnl_sync & ~btnl_prev;

    always_ff @(posedge CLK100MHZ or posedge rst) begin
        if (rst) begin
            btnl_meta <= 1'b0;
            btnl_sync <= 1'b0;
            btnl_prev <= 1'b0;
        end

        else begin
            btnl_meta <= BTNL;
            btnl_sync <= btnl_meta;
            btnl_prev <= btnl_sync;
        end
    end


    // ============================================================
    // RNG signals
    // ============================================================

    wire [3:0] current_value;
    wire [3:0] capture_value;
    wire [3:0] record_value;
    wire [3:0] max_value;

    wire [2:0] stage;
    wire done;


    // ============================================================
    // RNG core
    // ============================================================

    Top top0(
        .i_clk        (CLK100MHZ),
        .i_rst        (rst),

        .i_start      (BTNU_down),
        .i_capture    (BTNL_down),

        .o_random_out (current_value),
        .o_capture    (capture_value),
        .o_record     (record_value),
        .o_max        (max_value),

        .o_stage      (stage),
        .o_done       (done)
    );


    // ============================================================
    // Convert 0~15 into two decimal digits
    //
    // output [7:4] = tens
    // output [3:0] = ones
    //
    //  0 -> 00
    //  7 -> 07
    // 12 -> 12
    // 15 -> 15
    // ============================================================

    function automatic [7:0] to_decimal(
        input logic [3:0] value
    );

        begin

            if (value >= 4'd10)
                to_decimal = {
                    4'd1,
                    value - 4'd10
                };

            else
                to_decimal = {
                    4'd0,
                    value
                };

        end
    endfunction


    wire [7:0] current_dec;
    wire [7:0] capture_dec;
    wire [7:0] record_dec;
    wire [7:0] max_dec;


    assign current_dec = to_decimal(current_value);
    assign capture_dec = to_decimal(capture_value);
    assign record_dec  = to_decimal(record_value);
    assign max_dec     = to_decimal(max_value);


    // ============================================================
    // Display layout
    //
    // LEFT                                      RIGHT
    //
    // MAX      RECORD      CAPTURE      CURRENT
    //
    // d7 d6    d5 d4       d3 d2        d1 d0
    //
    // Example:
    //
    // 15 07 12 03
    // ============================================================

    Seven_Segment_Display display0(

        .i_clk    (CLK100MHZ),
        .i_rst    (rst),

        // CURRENT
        .i_digit0 (current_dec[3:0]),
        .i_digit1 (current_dec[7:4]),

        // CAPTURE
        .i_digit2 (capture_dec[3:0]),
        .i_digit3 (capture_dec[7:4]),

        // RECORD
        .i_digit4 (record_dec[3:0]),
        .i_digit5 (record_dec[7:4]),

        // MAX
        .i_digit6 (max_dec[3:0]),
        .i_digit7 (max_dec[7:4]),

        .CA       (CA),
        .CB       (CB),
        .CC       (CC),
        .CD       (CD),
        .CE       (CE),
        .CF       (CF),
        .CG       (CG),

        .o_an     (AN)
    );


    assign DP = 1'b1;


    // ============================================================
    // LED slowdown progress
    //
    // Faster -> fewer LEDs
    // Slower -> more LEDs
    // Finished -> all LEDs on
    // ============================================================

    logic [15:0] led_value;

    always_comb begin

        if (done) begin
            led_value = 16'hFFFF;
        end

        else begin

            case (stage)

                3'd0:
                    led_value =
                        16'b0000000000000001;

                3'd1:
                    led_value =
                        16'b0000000000000111;

                3'd2:
                    led_value =
                        16'b0000000000111111;

                3'd3:
                    led_value =
                        16'b0000000111111111;

                3'd4:
                    led_value =
                        16'b0000111111111111;

                3'd5:
                    led_value =
                        16'b0111111111111111;

                default:
                    led_value =
                        16'h0000;

            endcase
        end
    end

    assign LED = led_value;


    // ============================================================
    // Unused peripherals
    // ============================================================

    assign {
        LED16_B,
        LED16_G,
        LED16_R,
        LED17_B,
        LED17_G,
        LED17_R
    } = 6'b0;


    assign {
        VGA_R,
        VGA_G,
        VGA_B,
        VGA_HS,
        VGA_VS
    } = 14'b0;


    assign SD_RESET = 1'b0;


    assign {
        ACL_MOSI,
        ACL_SCLK,
        ACL_CSN
    } = 3'b001;


    assign TMP_SCL = 1'b1;


    assign {
        M_CLK,
        M_LRSEL,
        AUD_PWM,
        AUD_SD
    } = 4'b0;


    assign {
        UART_RXD_OUT,
        UART_CTS
    } = 2'b11;


    assign {
        ETH_MDC,
        ETH_RSTN,
        ETH_TXEN,
        ETH_TXD
    } = 5'b0;


    assign QSPI_CSN = 1'b1;

endmodule