# FPGA_Lab1

三四個頻率(查是否比較簡單)
100MHZ clk 1秒 27bit
不要用FSM?

```
logic [30:0]clk_cnt;
logic [2:0]random_clk;
logic [4:0] lfsr;
always @(posedge clk) begin
  clk_cnt = clk_cnt + 1;
  if (rst_i) begin
    clk_max = 0;
    clk_cnt=0;
  end else if(clk_cnt[25+clk_max])begin
    lfsr <= {lfsr[3:0],lfsr[4] ^ lfsr[2]};
    clk_max <= clk_max + 1;
    clk_cnt=0;
  end
  o_random_out <= lfsr[3:0];
end
```

```
剩下
clk_cnt [30:0]會不會耗太多資源?有沒有更好的方法?隨機方式可以更好?bonus要做什麼
vivado 大架構
```
