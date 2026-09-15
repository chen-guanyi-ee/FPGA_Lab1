# FPGA_Lab1

三四個頻率(查是否比較簡單)
100MHZ clk 1秒 27bit

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
    o_random_out <= lfsr[3:0];
  end
end
```

```
剩下
clk_cnt [30:0]會不會耗太多資源?有沒有更好的方法?隨機方式可以更好?bonus要做什麼
```

## 2026/09/15 工作紀錄 陳冠亦

- 完成 `Top.sv`：4-bit LFSR、4-bit (`0-F`) 隨機輸出、逐步降低更新頻率並停止。
- 修正 reset與七段顯示器連接。不使用debounce。
- Nexys A7 運作成功
- Slice = 27。
