module Seven_Segment_Display(
    input  logic       i_clk,
    input  logic       i_rst,

    input  logic [3:0] i_digit0,
    input  logic [3:0] i_digit1,
    input  logic [3:0] i_digit2,
    input  logic [3:0] i_digit3,
    input  logic [3:0] i_digit4,
    input  logic [3:0] i_digit5,
    input  logic [3:0] i_digit6,
    input  logic [3:0] i_digit7,

    output logic CA,
    output logic CB,
    output logic CC,
    output logic CD,
    output logic CE,
    output logic CF,
    output logic CG,

    output logic [7:0] o_an
);

    logic [9:0] scan_r;
    logic [3:0] selected;
    logic [6:0] seg;
    logic blank;

    // ------------------------------------------------------------
    // Display scan counter
    // ------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst)
            scan_r <= 10'd0;
        else
            scan_r <= scan_r + 1'b1;
    end

    // ------------------------------------------------------------
    // Select one of eight digits
    // ------------------------------------------------------------
    always_comb begin

        case (scan_r[9:7])
            3'd0: selected = i_digit0;
            3'd1: selected = i_digit1;
            3'd2: selected = i_digit2;
            3'd3: selected = i_digit3;
            3'd4: selected = i_digit4;
            3'd5: selected = i_digit5;
            3'd6: selected = i_digit6;
            default: selected = i_digit7;
        endcase

        o_an = 8'hFF;
        o_an[scan_r[9:7]] = blank;
    end

    Display_digit decoder(
        .i_digit(selected),
        .seg(seg),
        .an(blank)
    );

    assign {CG, CF, CE, CD, CC, CB, CA} = seg;

endmodule



module Display_digit(
    input  logic [3:0] i_digit,
    output logic [6:0] seg,
    output logic       an
);

    always_comb begin

        an = 1'b0;

        case (i_digit)

            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;

            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;

            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;

            default: begin
                seg = 7'b1111111;
                an  = 1'b1;
            end

        endcase
    end

endmodule