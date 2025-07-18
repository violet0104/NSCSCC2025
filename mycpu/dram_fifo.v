`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module dram_fifo (
    input wire clk,
    input wire rst,

    input wire flush,

    input wire [1:0] enqueue_en, //鍏ラ槦浣胯兘淇″彿
    input wire [`DECODE_DATA_WIDTH - 1:0] enqueue_data1, //閸忋儵妲﹂弫鐗堝祦
    input wire [`DECODE_DATA_WIDTH - 1:0] enqueue_data2, 

    input wire [1:0] invalid_en, // 鏁版嵁鏈夋晥浣胯兘淇″彿
    output wire [`DECODE_DATA_WIDTH - 1:0] dequeue_data1, //閸戞椽妲﹂弫鐗堝祦
    output wire [`DECODE_DATA_WIDTH - 1:0] dequeue_data2,
    
    output wire get_data_req,
    output wire full,
    output wire empty
);

    reg [`DECODE_DATA_WIDTH - 1:0] ram [`DEPTH - 1:0];

    // 闃熷熬鍐欐暟鎹紝闃熷ご璇绘暟鎹�
    reg [$clog2(`DEPTH) - 1:0] head;    
    reg [$clog2(`DEPTH) - 1:0] tail;   

    reg [$clog2(`DEPTH) - 1:0] head_plus;   
    reg [$clog2(`DEPTH) - 1:0] tail_plus;  

    `ifdef DIFF
    // or simulation (浠跨湡娴嬭瘯)
    initial begin
        for (integer i = 0; i < `DEPTH; i++) begin
            ram[i] = `DATA_WIDTH'(0);
        end
    end
    `endif

    always @(posedge clk) begin
        if (rst || flush) begin    
            tail      <= 0;
            tail_plus <= 1;
        end else if (&enqueue_en) begin    
            tail      <= tail + 2;
            tail_plus <= tail_plus + 2;
        end else if (|enqueue_en) begin     
            tail      <= tail + 1;
            tail_plus <= tail_plus + 1;
        end
    end

    always @(posedge clk) begin
        if (&enqueue_en) begin
            ram[tail]     <= enqueue_data1;
            ram[tail + 1] <= enqueue_data2;
        end else if (enqueue_en[0]) begin
            ram[tail] <= enqueue_data1;
        end else if (enqueue_en[1]) begin
            ram[tail] <= enqueue_data2;
        end
    end

    always @(posedge clk) begin
        if (rst || flush) begin     // 闂佽法鍠愰弸濠氬箯瀹勯偊娼楅梺璺ㄥ枑閺嬪骞忛悜鑺ユ櫢闁哄倶鍊栫€氳寰勭€涙ê鐦归梺璺ㄥ枑閺嬪骞忛敓锟�
            head      <= 0;
            head_plus <= 1;
        end else if (&invalid_en && !empty) begin   // 闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏橀弫鎾诲棘閵堝棗顏跺ù锝呮健閺佹捇寮妶鍡楊伓闂佽法鍠曢崜濂稿矗閻ゎ垼鍟囬柟鐤腹鐠愶拷1闁哄喛鎷�
            head      <= head + 2;
            head_plus <= head_plus + 2;
        end else if (|invalid_en && !empty) begin   // 闂佽法鍠愰弸濠氬箯閾氬倻顏遍梺璺ㄥ枑閺嬪骞忛悜鑺ユ櫢闁哄倶鍊栫€氬綊鏌ㄩ悢鍛婄伄闁圭柉娓规繛鍥煥閻斿憡鐏柟椋庡厴閺佹捇鎳樺鍗炵殤闁圭柉娓圭拹锟�1闁哄喛鎷�
            head      <= head + 1;
            head_plus <= head_plus + 1;
        end
    end

    // 闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氾拷
    assign dequeue_data1 = ram[head];
    assign dequeue_data2 = ram[head_plus];



    // 闂佽法鍠庤ぐ銊╁棘椤撯槅鍟囬柟椋庡厴閺佹捇寮妶鍡楊伓闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鐩掞箓鏁愯箛鏂款伓闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢渚痪缁绢參鏀辩€氾拷
    wire stall;
    assign stall = (head == (tail + 3) % `DEPTH);
    assign full = (head == (tail_plus + 1) % `DEPTH) || (head == tail_plus);
    assign empty = (head == tail) || (head_plus == tail);

    assign get_data_req = !(stall || full);

endmodule