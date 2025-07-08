`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module dram_fifo (
    input wire clk,
    input wire rst,

    input wire flush,

    input wire [1:0] enqueue_en, //入队使能信号
    input wire [1:0] [`DECODE_DATA_WIDTH - 1:0] enqueue_data, //入队数据

    input wire invalid_en, //数据有效使能信号
    output wire [1:0] [`DECODE_DATA_WIDTH - 1:0] dequeue_data, //出队数据
    
    output wire get_data_req,
    output wire full,
    output wire empty
);

    reg [`DECODE_DATA_WIDTH - 1:0] ram [`DEPTH - 1:0];

    // 尾进头出（队尾写数据，队头读数据）
    reg [$clog2(`DEPTH) - 1:0] head;    // 队头指针
    reg [$clog2(`DEPTH) - 1:0] tail;    // 队尾指针

    reg [$clog2(`DEPTH) - 1:0] head_plus;   // 队头指针加1
    reg [$clog2(`DEPTH) - 1:0] tail_plus;   // 队尾指针加1

    `ifdef DIFF
    // for simulation (仿真测试)
    initial begin
        for (integer i = 0; i < `DEPTH; i++) begin
            ram[i] = `DATA_WIDTH'(0);
        end
    end
    `endif

    always @(posedge clk) begin
        if (rst || flush) begin     // 初始化队尾指针
            tail      <= 0;
            tail_plus <= 1;
        end else if (&enqueue_en) begin     // 两个入队使能信号都为1时
            tail      <= tail + 2;
            tail_plus <= tail_plus + 2;
        end else if (|enqueue_en) begin     // 有一个入队使能信号为1时
            tail      <= tail + 1;
            tail_plus <= tail_plus + 1;
        end
    end

    always @(posedge clk) begin
        if (&enqueue_en) begin
            ram[tail]     <= enqueue_data[0];
            ram[tail + 1] <= enqueue_data[1];
        end else if (enqueue_en[0]) begin
            ram[tail] <= enqueue_data[0];
        end else if (enqueue_en[1]) begin
            ram[tail] <= enqueue_data[1];
        end
    end

    always @(posedge clk) begin
        if (rst || flush) begin     // 初始化队头指针
            head      <= 0;
            head_plus <= 1;
        end else if (&invalid_en && !empty) begin   // 两个出队使能信号都为1时
            head      <= head + 2;
            head_plus <= head_plus + 2;
        end else if (|invalid_en && !empty) begin   // 有一个出队使能信号为1时
            head      <= head + 1;
            head_plus <= head_plus + 1;
        end
    end

    // 出队
    assign dequeue_data[0] = ram[head];
    assign dequeue_data[1] = ram[head_plus];

    // 判断队列满，空，阻塞逻辑
    assign stall = (head == (tail + 3) % `DEPTH);
    assign full = (head == (tail_plus + 1) % `DEPTH) || (head == tail_plus);
    assign empty = (head == tail) || (head_plus == tail);

    assign get_data_req = !(stall || full);

endmodule