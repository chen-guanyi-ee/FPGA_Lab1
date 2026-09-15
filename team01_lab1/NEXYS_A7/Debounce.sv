module Debounce #(parameter integer CNT_N = 1048575) (
    input i_in, i_clk, i_rst,
    output logic o_debounced, o_neg, o_pos
);
    // Default: stable for 10.48576 ms at 100 MHz, after two-flop synchronization.
    localparam integer CNT_BIT = (CNT_N < 1) ? 1 : $clog2(CNT_N+1);
    (* ASYNC_REG = "TRUE" *) logic sync_meta, sync_in;
    logic [CNT_BIT-1:0] counter_r;
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            sync_meta <= 0;
            sync_in <= 0;
            o_debounced <= 0;
            counter_r <= CNT_BIT'(CNT_N);
            o_pos <= 0;
            o_neg <= 0;
        end else begin
            sync_meta <= i_in;
            sync_in <= sync_meta;
            o_pos <= 0;
            o_neg <= 0;
            if (sync_in == o_debounced) counter_r <= CNT_BIT'(CNT_N);
            else if (counter_r == 0) begin
                o_debounced <= sync_in;
                o_pos <= sync_in;
                o_neg <= ~sync_in;
                counter_r <= CNT_BIT'(CNT_N);
            end else counter_r <= counter_r - 1'b1;
        end
    end
endmodule
