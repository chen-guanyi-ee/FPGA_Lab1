// Simple counter-bit timing scheme (as described in README.md).
module Top (
    input  logic       i_clk,
    input  logic       i_rst,
    input  logic       i_start,
    output logic [3:0] o_random_out,
    output logic       o_scan
);

    logic [1:0] clk_cnt;
    logic [1:0]  clk_max;
    logic [1:0]  repeat_cnt;
    logic [3:0]  lfsr;
    logic [22:0] clk_cnt_23;

    // Buttons are sampled by the 100 MHz clock.  They must not appear in the
    // event control: doing so makes Vivado treat them as clocks and prevents
    // placement on their ordinary I/O pins.
    always_ff @(posedge i_clk) begin
        o_scan <= &clk_cnt_23[10:0]? ~o_scan : o_scan;
        if (i_rst) begin
            clk_max       <= 2'd2;
            o_random_out  <= 0;
            clk_cnt <= 2'd2;
            clk_cnt_23 <= '1;
            lfsr    <= 4'b0000;
            repeat_cnt <= 2'd3;
        end else if (i_start) begin
            clk_cnt       <= 2'd2;
            clk_cnt_23    <= '1;
            clk_max       <= 2'd0;
            repeat_cnt    <= 2'd2;
        end else begin
            // Shared counter also provides the two-digit display scan clock.

            clk_cnt_23 <= {clk_cnt_23[21:0], clk_cnt_23[22] ^ clk_cnt_23[17]};
            lfsr <= {lfsr[2:0], lfsr[3] ^lfsr[0]^~(|lfsr[2:0])};
            if (clk_max !=2'd2 ) begin
                // Use three progressively slower rates and show four values at
                // each rate before keeping the final result on the display.
                if (clk_cnt_23 == 23'd1 ) begin
                    if (clk_cnt == clk_max) begin
                        clk_cnt <= 2'd2;
                        o_random_out <= lfsr;
                        if (repeat_cnt == 2'd3) begin
                            clk_max    <= {clk_max[0], ~clk_max[1]};
                        end
                        repeat_cnt <= {repeat_cnt[0], ~repeat_cnt[1]};
                    end else begin
                        clk_cnt <= {clk_cnt[0], ~clk_cnt[1]};
                    end
                end
            end
        end
    end
endmodule
