module Top (
    input  logic       i_clk,
    input  logic       i_rst,
    input  logic       i_start,
    input  logic       i_capture,

    output logic [3:0] o_random_out,
    output logic [3:0] o_capture,
    output logic [3:0] o_record,
    output logic [3:0] o_max,

    output logic [2:0] o_stage,
    output logic       o_done
);

    logic [30:0] clk_cnt;
    logic [2:0]  clk_max;
    logic [4:0]  lfsr;
    logic        tick;

    // ------------------------------------------------------------
    // Slowdown timing selection
    // clk_max = 0~5 : rolling stages
    // clk_max = 6   : stopped
    // ------------------------------------------------------------
    always_comb begin
        tick = 1'b0;

        case (clk_max)
            3'd0: tick = clk_cnt[25];
            3'd1: tick = clk_cnt[26];
            3'd2: tick = clk_cnt[27];
            3'd3: tick = clk_cnt[28];
            3'd4: tick = clk_cnt[29];
            3'd5: tick = clk_cnt[30];
            default: tick = 1'b0;
        endcase
    end

    assign o_stage = clk_max;

    // ------------------------------------------------------------
    // Main logic
    // ------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_rst) begin

        if (i_rst) begin
            clk_cnt      <= 31'd0;
            clk_max      <= 3'd6;

            lfsr         <= 5'b00001;

            o_random_out <= 4'd0;
            o_capture    <= 4'd0;
            o_record     <= 4'd0;
            o_max        <= 4'd0;

            o_done       <= 1'b0;
        end

        // --------------------------------------------------------
        // Start new RNG round
        // --------------------------------------------------------
        else if (i_start) begin
            clk_cnt <= 31'd0;
            clk_max <= 3'd0;
            o_done  <= 1'b0;
        end

        else begin

            // LFSR continuously runs
            lfsr <= {
                lfsr[3:0],
                lfsr[4] ^ lfsr[2]
            };

            // ----------------------------------------------------
            // CAPTURE BONUS
            //
            // Previous capture -> record
            // Current random    -> capture
            // Max compares only numbers that were actually captured
            // ----------------------------------------------------
            if (i_capture) begin

                o_record  <= o_capture;
                o_capture <= o_random_out;

                if (o_random_out > o_max)
                    o_max <= o_random_out;
            end


            // ----------------------------------------------------
            // Random rolling
            // ----------------------------------------------------
            if (clk_max != 3'd6) begin

                clk_cnt <= clk_cnt + 1'b1;

                if (tick) begin
                    clk_cnt <= 31'd0;

                    // sample current LFSR value
                    o_random_out <= lfsr[3:0];

                    // final stage
                    if (clk_max == 3'd5) begin
                        clk_max <= 3'd6;
                        o_done  <= 1'b1;
                    end

                    else begin
                        clk_max <= clk_max + 1'b1;
                    end
                end
            end

        end
    end

endmodule