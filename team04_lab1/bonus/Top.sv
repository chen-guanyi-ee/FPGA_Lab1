module Top (
    input        i_clk,
    input        i_rst,
    input        i_start,      // BTNU debounced pulse -> start / re-roll
    input        i_capture,    // BTNL debounced pulse -> capture current number
    output [3:0] o_random_out, // 目前數字 : number currently rolling / settled (0-15)
    output [3:0] o_capture,    // 即時抓取 : last captured number
    output [3:0] o_record,     // 紀錄     : previously captured number
    output [3:0] o_max,        // 最大值   : max value ever captured
    output [15:0] o_led,       // LED progress bar (more LEDs lit as it slows down)
    output       o_finish      // 1 when the rolling process has stopped
);

    // -----------------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------------
    localparam int STEPS    = 16;            // number of draws before it stops (1 draw <-> 1 LED)
    localparam [25:0] DLY_BASE = 26'd500_000;     // delay of the very first draw   (~5   ms @100MHz)
    localparam [25:0] DLY_STEP = 26'd3_300_000;   // extra delay added every draw   (slows it down)

    // -----------------------------------------------------------------
    // FSM states
    // -----------------------------------------------------------------
    typedef enum logic [1:0] {IDLE, ROLL, DONE} state_t;
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
    assign draw_en = (state_r == ROLL) && (delay_r >= delay_th);

    // -----------------------------------------------------------------
    // current number / capture / record / max registers
    // -----------------------------------------------------------------
    logic [3:0] current_r, current_w;  // 目前數字
    logic [3:0] capture_r, capture_w;  // 即時抓取
    logic [3:0] record_r,  record_w;   // 紀錄
    logic [3:0] max_r,     max_w;      // 最大值

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
                    state_w = ROLL;
                    lfsr_w  = (seed_cnt_r == 16'd0) ? 16'hACE1 : seed_cnt_r;
                end
            end

            ROLL: begin
                if (i_start) begin
                    // pressed again while still rolling -> restart with a fresh seed
                    step_w  = 4'd0;
                    delay_w = 26'd0;
                    lfsr_w  = (seed_cnt_r == 16'd0) ? 16'hACE1 : seed_cnt_r;
                end else if (draw_en) begin
                    lfsr_w    = {lfsr_r[14:0], feedback};
                    current_w = lfsr_r[3:0];       // new random number, 0-15
                    delay_w   = 26'd0;
                    if (step_r == STEPS-1) begin
                        state_w = DONE;             // last draw -> stop here
                    end else begin
                        step_w = step_r + 4'd1;
                    end
                end
            end

            DONE: begin
                if (i_start) begin
                    state_w = ROLL;
                    step_w  = 4'd0;
                    delay_w = 26'd0;
                    lfsr_w  = (seed_cnt_r == 16'd0) ? 16'hACE1 : seed_cnt_r;
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
            current_r <= 4'd0;
            capture_r <= 4'd0;   // 一開始都設置成 0
            record_r  <= 4'd0;   // 一開始都設置成 0
            max_r     <= 4'd0;   // 一開始都設置成 0
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
    assign o_finish      = (state_r == DONE);

    // LED progress bar: the slower the update rate, the more LEDs light up,
    // fully lit (16/16) once the number has settled.
    assign o_led = (state_r == DONE) ? 16'hFFFF :
                   (state_r == IDLE) ? 16'h0000 :
                                       (16'hFFFF >> (STEPS - 1 - step_r));

endmodule
