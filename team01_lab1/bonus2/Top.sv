module Top (
    input        i_clk,
    input        i_rst,
    input        i_start,      // BTNU debounced pulse -> start / re-roll (from scratch)
    input        i_pause,      // BTND debounced pulse -> toggle pause / resume
    input        i_capture,    // BTNL debounced pulse -> capture current number
    input  [2:0] i_range_bits, // from SW[6:0] priority encoder: random value in [0, 2^i_range_bits - 1]
    output [5:0] o_random_out, // 目前數字 : number currently jumping / paused (0-63)
    output [5:0] o_capture,    // 即時抓取 : last captured number
    output [5:0] o_record,     // 紀錄     : previously captured number
    output [5:0] o_max,        // 最大值   : max value ever captured
    output [15:0] o_led,       // LED progress bar (more LEDs lit as it slows down)
    output       o_paused      // 1 while the number is paused (frozen)
);

    // -----------------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------------
    // STEPS-1 is the slowest update rate; once reached it keeps jumping
    // forever at that rate instead of stopping (it only freezes on i_pause).
    localparam int STEPS    = 16;                 // 1 speed-step <-> 1 LED
    localparam [25:0] DLY_BASE = 26'd500_000;     // delay of the very first draw   (~5  ms @100MHz)
    localparam [25:0] DLY_STEP = 26'd3_300_000;   // extra delay added every step   (slows it down)

    // -----------------------------------------------------------------
    // FSM states
    // -----------------------------------------------------------------
    typedef enum logic [1:0] {IDLE, RUN, PAUSED} state_t;
    state_t state_r, state_w;

    // -----------------------------------------------------------------
    // Free running counter, used to reseed the LFSR every time BTNU is
    // pressed -> a different sequence is produced each time.
    // -----------------------------------------------------------------
    logic [15:0] seed_cnt_r, seed_cnt_w;
    assign seed_cnt_w = seed_cnt_r + 16'd1;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) seed_cnt_r <= 16'hACE1;     // non-zero default seed
        else       seed_cnt_r <= seed_cnt_w;
    end

    // -----------------------------------------------------------------
    // 16-bit maximal length LFSR (taps 16,14,13,11, see lecture slide)
    // -----------------------------------------------------------------
    logic [15:0] lfsr_r, lfsr_w;
    logic        feedback;
    assign feedback = lfsr_r[15] ^ lfsr_r[13] ^ lfsr_r[12] ^ lfsr_r[10];

    // -----------------------------------------------------------------
    // step / delay counters that control the "slow down" behaviour
    // -----------------------------------------------------------------
    logic [3:0]  step_r,  step_w;      // 0 .. STEPS-1
    logic [25:0] delay_r, delay_w;
    logic [25:0] delay_th;             // current threshold, grows every step
    assign delay_th = DLY_BASE + DLY_STEP * step_r;

    logic draw_en;                     // pulse: draw a new random number
    assign draw_en = (state_r == RUN) && (delay_r >= delay_th);

    // -----------------------------------------------------------------
    // range mask, driven by i_range_bits (0..6) : keeps only the low
    // i_range_bits bits of the LFSR -> value in [0, 2^i_range_bits - 1]
    // -----------------------------------------------------------------
    logic [5:0] range_mask;
    assign range_mask = (i_range_bits == 3'd0) ? 6'b000000 :
                         (6'b111111 >> (6 - i_range_bits));

    // -----------------------------------------------------------------
    // current number / capture / record / max registers (0-63)
    // -----------------------------------------------------------------
    logic [5:0] current_r, current_w;  // 目前數字
    logic [5:0] capture_r, capture_w;  // 即時抓取
    logic [5:0] record_r,  record_w;   // 紀錄
    logic [5:0] max_r,     max_w;      // 最大值

    // -----------------------------------------------------------------
    // Next state / datapath logic
    // -----------------------------------------------------------------
    always_comb begin
        // defaults: hold current values, delay counter keeps counting up
        state_w   = state_r;
        step_w    = step_r;
        delay_w   = delay_r + 26'd1;
        lfsr_w    = lfsr_r;
        current_w = current_r;
        capture_w = capture_r;
        record_w  = record_r;
        max_w     = max_r;

        case (state_r)
            IDLE: begin
                delay_w = 26'd0;
                step_w  = 4'd0;
                if (i_start) begin
                    state_w = RUN;
                    lfsr_w  = (seed_cnt_r == 16'd0) ? 16'hACE1 : seed_cnt_r;
                end
                // i_pause has no effect before the first roll has started
            end

            RUN: begin
                if (i_start) begin
                    // BTNU pressed again -> restart from scratch with a fresh seed
                    step_w  = 4'd0;
                    delay_w = 26'd0;
                    lfsr_w  = (seed_cnt_r == 16'd0) ? 16'hACE1 : seed_cnt_r;
                end else if (i_pause) begin
                    // freeze: stop the delay counter exactly where it is
                    state_w = PAUSED;
                    delay_w = delay_r;
                end else if (draw_en) begin
                    lfsr_w    = {lfsr_r[14:0], feedback};
                    current_w = lfsr_r[5:0] & range_mask;  // new random number, 0-63 (masked to selected range)
                    delay_w   = 26'd0;
                    // saturate at the slowest speed instead of stopping -
                    // it keeps jumping forever at that rate
                    step_w = (step_r == STEPS-1) ? step_r : step_r + 4'd1;
                end
            end

            PAUSED: begin
                delay_w = delay_r;   // keep frozen, do not advance the timer
                if (i_start) begin
                    // restart from scratch even while paused
                    state_w = RUN;
                    step_w  = 4'd0;
                    delay_w = 26'd0;
                    lfsr_w  = (seed_cnt_r == 16'd0) ? 16'hACE1 : seed_cnt_r;
                end else if (i_pause) begin
                    // resume exactly where it left off
                    state_w = RUN;
                end
            end

            default: state_w = IDLE;
        endcase

        // ---------------- capture / record / max (bonus) ---------------
        // 1st press  : capture_r <= current number
        // 2nd press  : record_r  <= old capture_r ; capture_r <= new current number
        // max_r always keeps the largest value that has ever been captured
        if (i_capture) begin
            record_w  = capture_r;
            capture_w = current_r;
            if (current_r > max_r) max_w = current_r;
        end
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state_r   <= IDLE;
            step_r    <= 4'd0;
            delay_r   <= 26'd0;
            lfsr_r    <= 16'hACE1;
            current_r <= 6'd0;
            capture_r <= 6'd0;   // 一開始都設置成 0
            record_r  <= 6'd0;   // 一開始都設置成 0
            max_r     <= 6'd0;   // 一開始都設置成 0
        end else begin
            state_r   <= state_w;
            step_r    <= step_w;
            delay_r   <= delay_w;
            lfsr_r    <= lfsr_w;
            current_r <= current_w;
            capture_r <= capture_w;
            record_r  <= record_w;
            max_r     <= max_w;
        end
    end

    // -----------------------------------------------------------------
    // Outputs
    // -----------------------------------------------------------------
    assign o_random_out = current_r;
    assign o_capture    = capture_r;
    assign o_record     = record_r;
    assign o_max        = max_r;
    assign o_paused      = (state_r == PAUSED);

    // LED progress bar: the slower the update rate, the more LEDs light up.
    // Once it reaches the slowest rate (step_r == STEPS-1) all 16 stay lit
    // for as long as it keeps jumping (it no longer auto-stops).
    // While paused the bar just holds whatever it last showed.
    assign o_led = (state_r == IDLE) ? 16'h0000 :
                                        (16'hFFFF >> (STEPS - 1 - step_r));

endmodule
