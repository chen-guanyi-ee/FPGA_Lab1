// Simple counter-bit timing scheme (as described in README.md).
module Top (
    input  logic       i_clk,
    input  logic       i_rst,
    input  logic       i_start,
    output logic [3:0] o_random_out,
    output logic       o_scan
);
    localparam integer TIMER_BASE_BIT = 22;

    logic [27:0] clk_cnt;
    logic [2:0]  clk_max;
    logic [1:0]  repeat_cnt;
    logic [4:0]  lfsr;

    // Buttons are sampled by the 100 MHz clock.  They must not appear in the
    // event control: doing so makes Vivado treat them as clocks and prevents
    // placement on their ordinary I/O pins.
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            clk_max       <= 3'd4;
            o_random_out  <= '0;
            clk_cnt <= '0;
            lfsr    <= 5'b00001;
            repeat_cnt <= '0;
        end else if (i_start) begin
            clk_cnt       <= '0;
            clk_max       <= '0;
            repeat_cnt    <= '0;
        end else begin
            // Shared counter also provides the two-digit display scan clock.
            clk_cnt <= clk_cnt + 1'b1;
            lfsr <= {lfsr[3:0], lfsr[4] ^ lfsr[2]};
            if (clk_max != 3'd4) begin
                // Use four progressively slower rates and show four values at
                // each rate before keeping the final result on the display.
                if (clk_cnt[TIMER_BASE_BIT + clk_max]) begin
                    clk_cnt      <= '0;
                    o_random_out <= lfsr[3:0];
                    if (repeat_cnt == 2'd3) begin
                        repeat_cnt <= '0;
                        clk_max    <= clk_max + 1'b1;
                    end else begin
                        repeat_cnt <= repeat_cnt + 1'b1;
                    end
                end
            end
        end
    end
    assign o_scan = clk_cnt[10];
endmodule
