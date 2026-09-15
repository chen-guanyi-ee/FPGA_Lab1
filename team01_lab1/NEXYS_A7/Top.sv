module Top #(parameter integer BASE_BITS = 23) (
    input logic i_clk, i_rst, i_start,
    output logic [3:0] o_random_out
);
    // 4 updates at each of 83.9, 167.8, 335.5, 671.1 ms: 5.03 s.
    localparam integer TIMER_BITS = BASE_BITS + 3;
    logic [TIMER_BITS-1:0] timer_r, reload;
    logic [1:0] speed_r, count_r;
    logic running_r;
    logic [15:0] lfsr_r;
    always_comb begin
        case (speed_r)
            0: reload = {3'b000, {BASE_BITS{1'b1}}};
            1: reload = {2'b00, {(BASE_BITS+1){1'b1}}};
            2: reload = {1'b0, {(BASE_BITS+2){1'b1}}};
            default: reload = {TIMER_BITS{1'b1}};
        endcase
    end
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            lfsr_r <= 16'h1;
            timer_r <= '0;
            speed_r <= '0;
            count_r <= '0;
            running_r <= 1'b0;
            o_random_out <= '0;
        end else begin
            // Free-running maximal-length LFSR; button timing selects the sample.
            lfsr_r <= {lfsr_r[14:0], lfsr_r[15] ^ lfsr_r[13] ^ lfsr_r[12] ^ lfsr_r[10]};
            if (!running_r) begin
                if (i_start) begin
                    running_r <= 1'b1;
                    speed_r <= '0;
                    count_r <= '0;
                    timer_r <= {3'b000, {BASE_BITS{1'b1}}};
                    o_random_out <= lfsr_r[3:0];
                end
            end else if (timer_r != 0) begin
                timer_r <= timer_r - 1'b1;
            end else begin
                o_random_out <= lfsr_r[3:0];
                timer_r <= reload;
                count_r <= count_r + 1'b1;
                if (count_r == 2'd3) begin
                    if (speed_r == 2'd3) running_r <= 1'b0;
                    else begin
                        speed_r <= speed_r + 1'b1;
                        timer_r <= (reload << 1) | {{(TIMER_BITS-1){1'b0}}, 1'b1};
                    end
                end
            end
        end
    end
endmodule
