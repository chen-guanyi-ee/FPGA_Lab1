// Simple counter-bit timing scheme (as described in README.md).
module Top (
    input  logic       i_clk,
    input  logic       i_rst,
    input  logic       i_start,
    output logic [3:0] o_random_out,
    output logic       o_scan
);

    logic [1:0]  clk_cnt;
    logic [1:0]  clk_max;
    logic [1:0]  repeat_cnt;
    logic [3:0]  lfsr;
    logic [22:0] clk_cnt_23 = 23'd1;
    logic stop;
    always_ff @(posedge i_clk) begin
        o_scan <= &clk_cnt_23[10:0]? ~o_scan : o_scan;
        if (i_rst) begin
            o_random_out  <= 0;
            stop <= 1;
        end else if (i_start) begin
            clk_cnt       <= 2'd0;
            clk_max       <= 2'd0;
            repeat_cnt    <= 2'd2;
            stop          <= 0;
        end else begin
            clk_cnt_23 <= {clk_cnt_23[21:0], clk_cnt_23[22] ^ clk_cnt_23[17]};
            lfsr <= {lfsr[2:0], lfsr[3] ^lfsr[0]^~(|lfsr[2:0])};
            if(~stop && clk_cnt_23 == 23'd2044) begin
                if (clk_cnt == clk_max) begin
                    clk_cnt <= 2'd0;
                    o_random_out <= lfsr;
                    if (repeat_cnt == 2'd3) begin
                        clk_max    <= {clk_max[0], ~clk_max[1]};
                        stop <= clk_cnt==2'd2;
                    end
                    repeat_cnt <= {repeat_cnt[0], ~repeat_cnt[1]};
                end else begin
                    clk_cnt <= {clk_cnt[0], ~clk_cnt[1]};
                end
            end
        end
    end
endmodule

