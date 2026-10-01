module Top (
    input        i_clk,
    input        i_rst,
    input        i_pause,      // BTNR debounced pulse -> toggle pause / resume
    input        i_freq_up,    // BTNU debounced pulse -> increase update frequency (faster)
    input        i_freq_down,  // BTND debounced pulse -> decrease update frequency (slower)
    input        i_capture,    // BTNL debounced pulse -> capture current number
    input  [2:0] i_range_bits, // from SW[6:0] priority encoder: random value in [0, 2^i_range_bits - 1]
    output [5:0] o_random_out, // 目前數字 : number currently jumping / paused (0-63)
    output [5:0] o_capture,    // 即時抓取 : last captured number
    output [5:0] o_record,     // 紀錄     : previously captured number
    output [5:0] o_max,        // 最大值   : max value ever captured
    output [15:0] o_led,       // LED bar: more LEDs lit = the selected speed is slower
    output       o_paused      // 1 while the number is paused (frozen)
);

    // -----------------------------------------------------------------
    // FSM states - it starts jumping right out of reset; BTNR only
    // pauses/resumes it (there is no separate "start" button anymore,
    // since BTNU/BTND are now used for frequency up/down).
    // -----------------------------------------------------------------
    typedef enum logic {RUN, PAUSED} state_t;
    state_t state_r, state_w;

    // -----------------------------------------------------------------
    // 8 fixed update-speeds, selected with BTNU (faster) / BTND (slower).
    // freq_level_r: 0 = slowest, 7 = fastest. It saturates at both ends
    // (does not wrap around). Level 3 (~100 ms) is the default right
    // after reset - a "middle" speed.
    // Values are the number of i_clk cycles between two draws
    // (100 MHz clock, so e.g. 10_000_000 cycles = 100 ms).
    // -----------------------------------------------------------------
    logic [2:0]  freq_level_r, freq_level_w;
    logic [25:0] delay_th;
    always_comb begin
        case (freq_level_r)
            3'd0: delay_th = 26'd50_000_000;   // slowest  (~500 ms)
            3'd1: delay_th = 26'd30_000_000;   //          (~300 ms)
            3'd2: delay_th = 26'd18_000_000;   //          (~180 ms)
            3'd3: delay_th = 26'd10_000_000;   // middle   (~100 ms) <- default
            3'd4: delay_th = 26'd5_000_000;    //          (~50  ms)
            3'd5: delay_th = 26'd2_000_000;    //          (~20  ms)
            3'd6: delay_th = 26'd800_000;      //          (~8   ms)
            3'd7: delay_th = 26'd300_000;      // fastest  (~3   ms)
            default: delay_th = 26'd10_000_000;
        endcase
    end

    // -----------------------------------------------------------------
    // Free running counter, used to reseed the LFSR whenever i_rst is
    // released, so a fresh run doesn't always start from the same seed.
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
    // delay counter: counts up to delay_th, then a new number is drawn
    // -----------------------------------------------------------------
    logic [25:0] delay_r, delay_w;

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
        state_w      = state_r;
        delay_w      = delay_r + 26'd1;
        lfsr_w       = lfsr_r;
        current_w    = current_r;
        capture_w    = capture_r;
        record_w     = record_r;
        max_w        = max_r;
        freq_level_w = freq_level_r;

        case (state_r)
            RUN: begin
                if (i_pause) begin
                    // freeze: stop the delay counter exactly where it is
                    state_w = PAUSED;
                    delay_w = delay_r;
                end else if (draw_en) begin
                    lfsr_w    = {lfsr_r[14:0], feedback};
                    current_w = lfsr_r[5:0] & range_mask;  // new random number, 0-63 (masked to selected range)
                    delay_w   = 26'd0;
                end
            end

            PAUSED: begin
                delay_w = delay_r;   // keep frozen, do not advance the timer
                if (i_pause) begin
                    state_w = RUN;    // resume exactly where it left off
                end
            end

            default: state_w = RUN;
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

        // ---------------- frequency up / down (BTNU / BTND) -------------
        // saturates at both ends (does not wrap around); works in any
        // state and takes effect on the very next draw (delay_th is comb)
        if (i_freq_up && !i_freq_down) begin
            freq_level_w = (freq_level_r == 3'd7) ? freq_level_r : freq_level_r + 3'd1;
        end else if (i_freq_down && !i_freq_up) begin
            freq_level_w = (freq_level_r == 3'd0) ? freq_level_r : freq_level_r - 3'd1;
        end
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state_r      <= RUN;    // starts jumping immediately after reset
            delay_r      <= 26'd0;
            lfsr_r       <= 16'hACE1;
            current_r    <= 6'd0;
            capture_r    <= 6'd0;   // 一開始都設置成 0
            record_r     <= 6'd0;   // 一開始都設置成 0
            max_r        <= 6'd0;   // 一開始都設置成 0
            freq_level_r <= 3'd3;   // default = middle speed
        end else begin
            state_r      <= state_w;
            delay_r      <= delay_w;
            lfsr_r       <= lfsr_w;
            current_r    <= current_w;
            capture_r    <= capture_w;
            record_r     <= record_w;
            max_r        <= max_w;
            freq_level_r <= freq_level_w;
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

    // LED bar reflects the SELECTED speed: the slower the frequency,
    // the more LEDs light up (freq_level 0 = slowest -> 16 LEDs lit,
    // freq_level 7 = fastest -> 2 LEDs lit).
    logic [4:0] num_leds;
    assign num_leds = (5'd8 - {2'd0, freq_level_r}) * 5'd2;
    assign o_led = 16'hFFFF >> (16 - num_leds);

endmodule


