// Simple counter-bit timing scheme (as described in README.md).
module Top (
    input  logic       i_clk,
    input  logic       i_rst,
    input  logic       i_start,
    output logic [3:0] o_random_out
);
    logic [29:0] clk_cnt;
    logic [2:0]  clk_max; // 0..3 active rates, 4 = idle
    logic [1:0]  update_cnt;
    logic [4:0]  lfsr;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            clk_cnt       <= '0;
            clk_max       <= 3'd4;
            update_cnt    <= '0;
            lfsr          <= 5'b00001;
            o_random_out  <= '0;
        end else begin
            // x^5 + x^3 + 1: nonzero maximal-length pseudo-random sequence.
            lfsr <= {lfsr[3:0], lfsr[4] ^ lfsr[2]};

            if (clk_max == 3'd4) begin
                if (i_start) begin
                    clk_cnt    <= '0;
                    clk_max    <= '0;
                    update_cnt <= '0;
                end
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
                // Bit 25, 26, 27, then 28 selects progressively slower rates.
                if (clk_cnt[25 + clk_max]) begin
                    clk_cnt      <= '0;
                    o_random_out <= lfsr[3:0];
                    update_cnt   <= update_cnt + 1'b1;

                    if (update_cnt == 2'd3) begin
                        update_cnt <= '0;
                        if (clk_max == 3'd3)
                            clk_max <= 3'd4;
                        else
                            clk_max <= clk_max + 1'b1;
                    end
                end
            end
        end
    end
endmodule
