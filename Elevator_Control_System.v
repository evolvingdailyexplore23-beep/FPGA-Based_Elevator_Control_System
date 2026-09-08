`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/03 11:56:07
// Design Name: 
// Module Name: Elevator_System_Design
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Elevator_System_Design(
    input  CLK,       // 100MHz 系統主時脈輸入
    input  RSTN,      // 非同步低準位重置訊號，按下為 0
    input  OPEN,      // 手動開門按鈕輸入
    input  CLOSE,     // 手動關門按鈕輸入
    input  UP,        // 1樓外部向上呼叫按鈕輸入
    input  DOWN,      // 2樓外部向下呼叫按鈕輸入
    input  ENTER,     // 內部樓層選擇確認按鈕輸入
    input  ELE_IN,    // 內部樓層選擇開關 (1=2樓, 0=1樓)
    output [3:0] LEFTEN,        // 接到實體板子的左側七段致能 (板子為 Active High，1=致能)
    output [3:0] RIGHTEN,       // 接到實體板子的右側七段致能 (板子為 Active High，1=致能)
    output [7:0] LEFT_DISPLAY,  // 接到實體板子的左側七段資料 (板子為 Active High，1=該段點亮)
    output [7:0] RIGHT_DISPLAY, // 接到實體板子的右側七段資料 (板子為 Active High，1=該段點亮)
    output [15:0] LED           // 一般 LED，EGO1 上為 Active High，不需反相
);

    // 核心 FSM 模組的輸出 (內部維持 Active High 定義，符合規格文字敘述)
    wire [3:0] leften_i;
    wire [3:0] righten_i;
    wire [7:0] left_disp_i;
    wire [7:0] right_disp_i;

    Lab5_4 core (
        .CLK           (CLK),
        .RSTN          (RSTN),
        .OPEN          (OPEN),
        .CLOSE         (CLOSE),
        .UP            (UP),
        .DOWN          (DOWN),
        .ENTER         (ENTER),
        .ELE_IN        (ELE_IN),
        .LEFTEN        (leften_i),
        .RIGHTEN       (righten_i),
        .LEFT_DISPLAY  (left_disp_i),
        .RIGHT_DISPLAY (right_disp_i),
        .LED           (LED)          // LED 直接接出去，不反相
    );

    // 板子確認為 Active High，核心模組輸出本身就是 Active High，
    // 因此七段顯示器訊號直接 passthrough，不再做反相
    assign LEFTEN        = leften_i;
    assign RIGHTEN       = righten_i;
    assign LEFT_DISPLAY  = left_disp_i;
    assign RIGHT_DISPLAY = right_disp_i;

endmodule


// ============================================================================
// Lab5_4 (核心電梯控制邏輯，內部訊號皆為 Active High)
// ============================================================================
module Lab5_4(
    input CLK,       // 100MHz 系統主時脈輸入
    input RSTN,      // 非同步低準位重置訊號，按下為 0
    input OPEN,      // 手動開門按鈕輸入
    input CLOSE,     // 手動關門按鈕輸入
    input UP,        // 1樓外部向上呼叫按鈕輸入
    input DOWN,      // 2樓外部向下呼叫按鈕輸入
    input ENTER,     // 內部樓層選擇確認按鈕輸入
    input ELE_IN,    // 內部樓層選擇開關 (1=2樓, 0=1樓)
    output reg [3:0] LEFTEN,       // 左側七段顯示器致能控制 (Active High)
    output reg [3:0] RIGHTEN,      // 右側七段顯示器致能控制 (Active High)
    output reg [7:0] LEFT_DISPLAY, // 左側七段顯示器 8 段資料 (Active High)
    output reg [7:0] RIGHT_DISPLAY,// 右側七段顯示器 8 段資料 (Active High)
    output [15:0] LED              // 16 顆 LED 輸出 (LED[15:2]門, LED[1:0]請求)
);

    reg [26:0] cnt_1hz;  // 27位元計數器，用於產生 1Hz 訊號
    reg [25:0] cnt_2hz;  // 26位元計數器，用於產生 2Hz 訊號
    reg [16:0] cnt_1khz; // 17位元計數器，用於產生 1kHz 訊號
    reg clk_1hz;         // 1Hz 時脈狀態暫存器
    reg clk_2hz;         // 2Hz 時脈狀態暫存器
    reg clk_1khz;        // 1kHz 時脈狀態暫存器

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            cnt_1hz <= 0;
            clk_1hz <= 0;
        end else if (cnt_1hz == 99999999) begin // 數到 100M-1，代表經過 1.0 秒 (半週期) -> 完整週期 2.0 秒，樓層移動時間變為 2 秒
            cnt_1hz <= 0;
            clk_1hz <= ~clk_1hz;
        end else begin
            cnt_1hz <= cnt_1hz + 1;
        end
    end

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            cnt_2hz <= 0;
            clk_2hz <= 0;
        end else if (cnt_2hz == 24999999) begin
            cnt_2hz <= 0;
            clk_2hz <= ~clk_2hz;
        end else begin
            cnt_2hz <= cnt_2hz + 1;
        end
    end

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            cnt_1khz <= 0;
            clk_1khz <= 0;
        end else if (cnt_1khz == 49999) begin
            cnt_1khz <= 0;
            clk_1khz <= ~clk_1khz;
        end else begin
            cnt_1khz <= cnt_1khz + 1;
        end
    end

    reg open_r1, open_r2;
    reg close_r1, close_r2;
    reg up_r1, up_r2;
    reg down_r1, down_r2;
    reg enter_r1, enter_r2;

    always @(posedge CLK or negedge RSTN) begin
        if(!RSTN) begin
            open_r1 <= 0; open_r2 <= 0;
            close_r1 <= 0; close_r2 <= 0;
            up_r1 <= 0; up_r2 <= 0;
            down_r1 <= 0; down_r2 <= 0;
            enter_r1 <= 0; enter_r2 <= 0;
        end else begin
            open_r1 <= OPEN; open_r2 <= open_r1;
            close_r1 <= CLOSE; close_r2 <= close_r1;
            up_r1 <= UP; up_r2 <= up_r1;
            down_r1 <= DOWN; down_r2 <= down_r1;
            enter_r1 <= ENTER; enter_r2 <= enter_r1;
        end
    end

    wire open_pulse = open_r1 & ~open_r2;
    wire close_pulse = close_r1 & ~close_r2;
    wire up_pulse = up_r1 & ~up_r2;
    wire down_pulse = down_r1 & ~down_r2;
    wire enter_pulse = enter_r1 & ~enter_r2;

    reg req_f1_up;
    reg req_f2_down;
    reg req_f1_in;
    reg req_f2_in;

    reg clr_f1_up;
    reg clr_f2_down;
    reg clr_f1_in;
    reg clr_f2_in;

    always @(posedge CLK or negedge RSTN) begin
        if(!RSTN) begin
            req_f1_up <= 0;
            req_f2_down <= 0;
            req_f1_in <= 0;
            req_f2_in <= 0;
        end else begin
            if (up_pulse) req_f1_up <= 1;
            if (down_pulse) req_f2_down <= 1;
            if (enter_pulse && ELE_IN == 0) req_f1_in <= 1;
            if (enter_pulse && ELE_IN == 1) req_f2_in <= 1;

            if (clr_f1_up) req_f1_up <= 0;
            if (clr_f2_down) req_f2_down <= 0;
            if (clr_f1_in) req_f1_in <= 0;
            if (clr_f2_in) req_f2_in <= 0;
        end
    end

    assign LED[0] = req_f1_up;
    assign LED[1] = req_f2_down;

    localparam S_STOP = 2'b00;
    localparam S_UP   = 2'b01;
    localparam S_DOWN = 2'b10;
    localparam S_DOOR = 2'b11;

    reg [1:0] state;
    reg [1:0] current_floor;

    reg [2:0] door_progress;
    reg [2:0] door_wait_cnt;
    reg door_is_opening;
    reg door_is_closing;

    reg clk_1hz_r;
    reg clk_2hz_r;
    wire tick_1hz = clk_1hz & ~clk_1hz_r;
    wire tick_2hz = clk_2hz & ~clk_2hz_r;

    always @(posedge CLK) begin
        clk_1hz_r <= clk_1hz;
        clk_2hz_r <= clk_2hz;
    end

    always @(posedge CLK or negedge RSTN) begin
        if(!RSTN) begin
            state <= S_STOP;
            current_floor <= 1;
            door_progress <= 0;
            door_wait_cnt <= 0;
            door_is_opening <= 0;
            door_is_closing <= 0;

            clr_f1_up <= 0;
            clr_f2_down <= 0;
            clr_f1_in <= 0;
            clr_f2_in <= 0;
        end else begin
            clr_f1_up <= 0;
            clr_f2_down <= 0;
            clr_f1_in <= 0;
            clr_f2_in <= 0;

            case(state)
                S_STOP: begin
                    if (current_floor == 1) begin
                        if (req_f1_up || req_f1_in) begin
                            state <= S_DOOR;
                            door_is_opening <= 1;
                            door_is_closing <= 0;
                            clr_f1_up <= 1;
                            clr_f1_in <= 1;
                        end else if (req_f2_down || req_f2_in) begin
                            state <= S_UP;
                        end else if (open_pulse) begin
                            state <= S_DOOR;
                            door_is_opening <= 1;
                            door_is_closing <= 0;
                        end
                    end else if (current_floor == 2) begin
                        if (req_f2_down || req_f2_in) begin
                            state <= S_DOOR;
                            door_is_opening <= 1;
                            door_is_closing <= 0;
                            clr_f2_down <= 1;
                            clr_f2_in <= 1;
                        end else if (req_f1_up || req_f1_in) begin
                            state <= S_DOWN;
                        end else if (open_pulse) begin
                            state <= S_DOOR;
                            door_is_opening <= 1;
                            door_is_closing <= 0;
                        end
                    end
                end

                S_UP: begin
                    if (tick_1hz) begin
                        current_floor <= 2;
                        state <= S_DOOR;
                        door_is_opening <= 1;
                        clr_f2_down <= 1;
                        clr_f2_in <= 1;
                    end
                end

                S_DOWN: begin
                    if (tick_1hz) begin
                        current_floor <= 1;
                        state <= S_DOOR;
                        door_is_opening <= 1;
                        clr_f1_up <= 1;
                        clr_f1_in <= 1;
                    end
                end

                // ------------------------------------------------------------
                // [FIX 1] 自動關門計時：door_wait_cnt 從 0 數到 5 剛好是
                // 6 個 tick = 3.0 秒。原本寫 ==6 會多等一拍變成 3.5 秒。
                // ------------------------------------------------------------
                S_DOOR: begin
                    if (tick_2hz) begin
                        if (door_is_opening) begin
                            if (door_progress == 6) begin
                                door_progress   <= 7;
                                door_is_opening <= 0;
                                door_wait_cnt   <= 0;
                            end else if (door_progress < 7) begin
                                door_progress <= door_progress + 1;
                            end
                        end else if (door_is_closing) begin
                            if (door_progress == 1) begin
                                door_progress   <= 0;
                                door_is_closing <= 0;
                                state           <= S_STOP;
                            end else if (door_progress > 0) begin
                                door_progress <= door_progress - 1;
                            end
                        end else begin
                            if (door_wait_cnt == 5) begin          // FIX: 6 -> 5
                                door_is_closing <= 1;
                                door_progress   <= door_progress - 1;
                            end else begin
                                door_wait_cnt <= door_wait_cnt + 1;
                            end
                        end
                    end

                    if (close_pulse && !door_is_opening && !door_is_closing) begin
                        door_is_closing <= 1;
                        door_wait_cnt <= 0;
                    end

                    // ------------------------------------------------------------
                    // [FIX 2] 門已經全開 (door_progress==7) 時再按 OPEN 不應該
                    // 做任何事，否則 door_is_opening 會卡在 1 但 door_progress
                    // 已經是 7，永遠不會再往下走，導致門卡死打不開也關不了。
                    // ------------------------------------------------------------
                    if (open_pulse && door_progress != 7) begin    // FIX: 加上條件
                        door_is_closing <= 0;
                        door_is_opening <= 1;
                        door_wait_cnt <= 0;
                    end
                end
            endcase
        end
    end

    reg [13:0] door_mask;
    always @(*) begin
        case(door_progress)
            0: door_mask = 14'b1111111_1111111;
            1: door_mask = 14'b1111110_0111111;
            2: door_mask = 14'b1111100_0011111;
            3: door_mask = 14'b1111000_0001111;
            4: door_mask = 14'b1110000_0000111;
            5: door_mask = 14'b1100000_0000011;
            6: door_mask = 14'b1000000_0000001;
            7: door_mask = 14'b0000000_0000000;
            default: door_mask = 14'b1111111_1111111;
        endcase
    end
    assign LED[15:2] = door_mask;

    reg clk_1khz_r;
    wire tick_1khz = clk_1khz & ~clk_1khz_r;

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN)
            clk_1khz_r <= 0;
        else
            clk_1khz_r <= clk_1khz;
    end

    reg [1:0] scan_cnt;
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN)
            scan_cnt <= 0;
        else if (tick_1khz)
            scan_cnt <= scan_cnt + 1;
    end

    localparam CHAR_S = 8'b01101101;
    localparam CHAR_t = 8'b01111000;
    localparam CHAR_o = 8'b01011100;
    localparam CHAR_P = 8'b01110011;
    localparam CHAR_U = 8'b00111110;
    localparam CHAR_d = 8'b01011110;
    localparam CHAR_w = 8'b00101010;
    localparam CHAR_n = 8'b01010100;
    localparam CHAR_r = 8'b01010000;
    localparam CHAR_BLANK = 8'b00000000;
    localparam CHAR_1 = 8'b00000110;
    localparam CHAR_2 = 8'b01011011;

    // ------------------------------------------------------------
    // [FIX 3] LEFTEN 的實體接線 (依 EGo1 官方手冊 DN0_K1~K4 對應
    // G2/C2/C1/H1 = LEFTEN[0..3]) 經比對後，bit0(K1) 其實接的是最
    // 左邊那顆數位管、bit3(K4) 接的才是最右邊，跟原本假設方向相反。
    // 這裡把每個 scan_cnt case 點亮的 one-hot bit 左右對調，
    // 內容 (P/o/t/S) 完全不用動，畫面就會從 "PotS" 變回 "Stop"。
    // ------------------------------------------------------------
    always @(*) begin
        LEFTEN = 4'b0000;
        LEFT_DISPLAY = CHAR_BLANK;
        case (scan_cnt)
            2'b00: begin
                LEFTEN = 4'b1000; // FIX: 0001 -> 1000
                if (state == S_STOP) LEFT_DISPLAY = CHAR_P;
                else if (state == S_UP) LEFT_DISPLAY = CHAR_P;
                else if (state == S_DOWN) LEFT_DISPLAY = CHAR_n;
                else if (state == S_DOOR) LEFT_DISPLAY = CHAR_r;
            end
            2'b01: begin
                LEFTEN = 4'b0100; // FIX: 0010 -> 0100
                if (state == S_STOP) LEFT_DISPLAY = CHAR_o;
                else if (state == S_UP) LEFT_DISPLAY = CHAR_U;
                else if (state == S_DOWN) LEFT_DISPLAY = CHAR_w;
                else if (state == S_DOOR) LEFT_DISPLAY = CHAR_o;
            end
            2'b10: begin
                LEFTEN = 4'b0010; // FIX: 0100 -> 0010
                if (state == S_STOP) LEFT_DISPLAY = CHAR_t;
                else if (state == S_DOWN) LEFT_DISPLAY = CHAR_o;
                else if (state == S_DOOR) LEFT_DISPLAY = CHAR_o;
            end
            2'b11: begin
                LEFTEN = 4'b0001; // FIX: 1000 -> 0001
                if (state == S_STOP) LEFT_DISPLAY = CHAR_S;
                else if (state == S_DOWN) LEFT_DISPLAY = CHAR_d;
                else if (state == S_DOOR) LEFT_DISPLAY = CHAR_d;
            end
        endcase
    end

    // RIGHTEN 接線 (DN1_K1~K4 對應 G1/F1/E1/G6) 跟 LEFTEN 完全對稱，
    // 所以同樣把 one-hot bit 左右對調，內容不變。
    always @(*) begin
        RIGHTEN = 4'b0000;
        RIGHT_DISPLAY = CHAR_BLANK;
        case (scan_cnt)
            2'b00: begin
                RIGHTEN = 4'b1000; // FIX: 0001 -> 1000
                RIGHT_DISPLAY = (current_floor == 1) ? CHAR_1 : CHAR_2;
            end
            2'b01: begin
                RIGHTEN = 4'b0100; // FIX: 0010 -> 0100
                if (req_f1_in) RIGHT_DISPLAY = CHAR_1;
            end
            2'b10: begin
                RIGHTEN = 4'b0010; // FIX: 0100 -> 0010
                if (req_f2_in) RIGHT_DISPLAY = CHAR_2;
            end
            2'b11: begin
                RIGHTEN = 4'b0001; // FIX: 1000 -> 0001
                RIGHT_DISPLAY = CHAR_BLANK;
            end
        endcase
    end

endmodule
