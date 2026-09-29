// Simple counter-bit timing scheme (as described in README.md).
module Top (
    input  logic       i_clk,
    input  logic       i_rst,
    input  logic       i_start,
    output logic [3:0] o_random_out,
    output logic       o_scan
);

    logic [2:0]  clk_cnt;
    logic [2:0]  clk_max = 3'd4;
    logic repeat_cnt;
    logic [3:0]  lfsr;
    logic [22:0] clk_cnt_23 = 23'd1;
    wire [2:0] clk_max_next;
    assign clk_max_next = {
        clk_max[1:0],
        clk_max[2] ^ clk_max[0]
    };
    always_ff @(posedge i_clk) begin
        if(&clk_cnt_23[7:0]) begin
            o_scan <= ~o_scan;
        end
        if (i_rst) begin
            o_random_out  <= 0;
        end else if (i_start) begin
            clk_max       <= 3'd1;
            clk_cnt       <= 3'd1;
            repeat_cnt    <= 0;
        end else begin
            clk_cnt_23 <= {clk_cnt_23[21:0], clk_cnt_23[22] ^ clk_cnt_23[17]};
            lfsr <= {lfsr[2:0], lfsr[3] ^lfsr[0]^~(|lfsr[2:0])};
            if(clk_cnt_23 == 23'd1 && clk_max != 3'd4) begin
                if (clk_cnt == 3'd1) begin
                    o_random_out <= lfsr;
                    if (repeat_cnt) begin
                        clk_max <= clk_max_next;
                    end
                    repeat_cnt <= ~repeat_cnt;
                    clk_cnt <= clk_max;
                end else begin
                    clk_cnt <= {clk_cnt[0] ^ clk_cnt[1], clk_cnt[2:1]};
                end
            end
        end
    end
endmodule


