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

## 2026/09/16 
- bonus: 七段顯示器 最大值｜紀錄｜即時抓取｜目前數字。
- 隨數字更動的頻率愈慢，LED亮起的數量愈多，直至全部亮起
- 用SW控制亂數選取的範圍

## 2026/09/16 工作紀錄 陳冠亦
- Slice = 23。

## 2026/09/17 工作紀錄 陳冠亦
- bonus完成
- slice=21

## 2026/09/20 
- slice=20
- 增加數字跳動的次數

## 2026/09/21 工作紀錄

- 最佳化 `Top.sv` 的計時與階段控制：縮短 counter 位寬，改為三段更新速度，每段顯示四個亂數，共更新十二次後停止；總展示時間約 2.35 秒。
- 將 LFSR 改為 zero-seed XNOR feedback，使相關 registers 一致 reset 。
- 桌機 Vivado implementation 實測 Slice = 18，低於 baseline 40。
- 研究後續 area optimization：規劃比較 `Flow_AreaOptimized_high` 搭配 `Area_Explore`、`Area_ExploreSequential` 與 `Area_ExploreWithRemap`，並以 implemented Slice、Timing 和板上功能作為最終判定依據。
