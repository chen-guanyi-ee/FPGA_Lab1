# FPGA_Lab1
三四個頻率(查是否比較簡單)
100MHZ clk 1秒 27bit
不要用FSM?
(1.clk[clk_max] clk_max =25  clk_max <= clk_max + 1;
always @(*) begin譬如最後一次八秒左右 假設clk_max = 30
  if (rst_i) begin
    clk_max = 25;
    random_clk = clk[3:0];
  end else if(clk[clk_max]==1)begin
    o_random_out <= 0_random_out + random_clk;
   clk_max <= clk_max + 1;
  end else if begin(clk_max == 30)
    clk_max = 50
  end
end
我們設定一個parameter random_clk[3:0]
clk [30:0]會不會皓太多資源?有沒有更好的方法?隨機方式可以更好?
