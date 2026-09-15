// Simple counter-bit timing scheme (as described in README.md).
module Top (
    input  logic       i_clk,
    input  logic       i_rst,
    input  logic       i_start,
    output logic [3:0] o_random_out
);
    logic [30:0] clk_cnt;
    logic [3:0]  clk_max;
    logic [4:0]  lfsr;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            clk_max       <= 3'd6;
            o_random_out  <= '0;
            clk_cnt <= '0;
            lfsr    <= 5'b00001;
        end else if (i_start) begin
            clk_cnt       <= '0;
            clk_max       <= '0;
        end else begin
            lfsr <= {lfsr[3:0], lfsr[4] ^ lfsr[2]};
            if (clk_max != 3'd6) begin
                clk_cnt <= clk_cnt + 1'b1;
                // Bit 25, 26, 27, then 28 selects progressively slower rates.
                if (clk_cnt[25 + clk_max]) begin
                    clk_cnt      <= '0;
                    o_random_out <= lfsr[3:0];
                    clk_max <= clk_max + 1'b1;
                end
            end
        end
    end
endmodule
