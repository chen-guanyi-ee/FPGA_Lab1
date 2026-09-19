# Lab1 Bonus 說明

## 修改的檔案
- `Top.sv`：加入 RNG 的 FSM (IDLE/ROLL/DONE)、LFSR 隨機數產生、slow-down 機制、
  capture/record/max 邏輯、LED 進度條。
- `NEXYS_A7.sv`：新增 BTNL 的 debounce（當作 capture 按鈕）、把 0-15 的二進位轉成
  十進位兩位數（十位/個位）分別送到 7 段顯示器、把 LED 接到進度條輸出。
- `Debounce.sv`、`Seven_Segment_Display.sv`、`Nexys-A7-100T-Master.xdc`：未修改，
  直接沿用（BTNL 與 LED[15:0] 在原始 xdc 裡已經有腳位定義）。

## 功能對應

### 1. 七段顯示器：最大值｜紀錄｜即時抓取｜目前數字
8 位數的顯示器從左到右分成 4 組，每組 2 位十進位數字（0~15 最大只會用到十位的 "0" 或 "1"）：

| 位置 (AN7..AN0) | 內容 |
|---|---|
| AN7, AN6 | 最大值 (max) |
| AN5, AN4 | 紀錄 (record) |
| AN3, AN2 | 即時抓取 (capture) |
| AN1, AN0 | 目前數字 (current，持續跳動中的數字) |

十進位轉換：`tens = (value>=10) ? 1 : 0`，`units = value - tens*10`，因此原本
0~15 直接當十六進位顯示（會出現 A~F）的問題已經改成兩位數的十進位顯示。

### 2. BTNU（開始/重新搖）
按下 BTNU 後，`Top.sv` 內的 LFSR 會用一個一直在跑的 16-bit 計數器當種子，
每次按下都會得到不同的隨機序列。FSM 進入 ROLL 狀態後，每次「畫出」新數字所需要
等待的時脈數（`delay_th = DLY_BASE + DLY_STEP * step`）會隨著 `step` 增加而變大，
所以數字更新的頻率會越來越慢，總共跑 16 次 (`STEPS = 16`) 之後進入 DONE 狀態，
數字就停在最後一次產生的隨機值上。

### 3. LED 進度條（隨頻率變慢，LED 越亮越多）
LED 顆數與目前的 `step` 成正比：
```
o_led = 16'hFFFF >> (STEPS - 1 - step_r)
```
- 剛開始滾動（更新很快）→ 只有 1 顆 LED 亮
- 越接近停止（更新越慢）→ 越多顆 LED 亮
- 完全停止（DONE）→ 16 顆 LED 全亮

### 4. Capture / Record / Max（BTNL）
- 第一次按 BTNL：把「目前數字 (current)」存進「即時抓取 (capture)」。
- 再按一次 BTNL：先把舊的 `capture` 值搬進「紀錄 (record)」，
  再把新的「目前數字」存進 `capture`（等於每按一次就往後推一格）。
- `max`：只要新抓取的數字比目前 `max` 大，就更新 `max`；
  重置（BTNC）時 `capture / record / max` 都會歸零。
- Capture 可以在 ROLL（滾動中）或 DONE（已停止）狀態下按，皆會抓到當下顯示的數字，
  滿足「在滾動過程中抓取隨機數」的需求。

## 可以微調的參數（在 Top.sv 開頭）
- `STEPS`：總共要滾幾次才停（同時也是 LED 顆數，預設 16）。
- `DLY_BASE` / `DLY_STEP`：控制一開始的速度、以及每一步變慢多少，
  可依展示需求調整整體滾動所需的時間長短。

## 燒錄前檢查
- Vivado 專案裡把 `Top.sv`、`NEXYS_A7.sv` 換成這裡的版本即可，
  `Nexys-A7-100T-Master.xdc` 不需要修改（BTNL、LED[15:0] 腳位皆已存在）。
