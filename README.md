# FPGA_Lab1

三四個頻率(查是否比較簡單)
100MHZ clk 1秒 27bit
不要用FSM?

```
logic clk[30:0]
logic random_clk[3:0]
always @(posedge clk) begin譬如最後一次八秒左右 假設clk_max = 30
  if (rst_i) begin
    clk_max = 25;
    random_clk = clk[3:0];
  end else if(clk[clk_max]==1)begin
    o_random_out <= 0_random_out*2 + random_clk;
    clk_max <= clk_max + 1;
    clk=0;
  end else if begin(clk_max == 30)
    clk_max = 50
  end
end
```

```
剩下
clk [30:0]會不會耗太多資源?有沒有更好的方法?隨機方式可以更好?bonus要做什麼
vivado 大架構
```
