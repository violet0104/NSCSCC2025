`timescale 1ns / 1ps

module fifo #(
    parameter DATA_WIDTH = 128,     // 数据位宽（默认128位）
    parameter      DEPTH = 8        // FIFO深度（默认8个条目）
) (
    input wire clk,
    input wire rst,
    
    // 入队信号
    input wire push,    // 入队使能信号
    input wire [DATA_WIDTH - 1 : 0] push_data,      // 入队数据

    // 出队信号
    input wire pop,     // 出队使能信号
    output wire [DATA_WIDTH - 1 : 0] pop_data,      // 出队数据

    input wire flush,       // FIFO清空信号
    output reg full,        // FIFO满标志
    output reg push_stall,  // 入队阻塞信号
    output reg empty        // FIFO空标志
);

    localparam PTR_WIDTH = $clog2(DEPTH); // 指针位宽
    
    // 队列主体
    reg [DATA_WIDTH - 1 : 0] ram [0 : DEPTH - 1];

    // 头尾指针
    wire [PTR_WIDTH - 1 : 0] write_index;   // 写指针
    wire [PTR_WIDTH - 1 : 0] read_index;    // 读指针

    
    // 写入数据
    always @(posedge clk) begin
        // if (rst|flush) ram <= '{default: '0};
        // else 
        if (push) ram[write_index] <= push_data;
    end

    // 更新指针
    always @(posedge clk) begin
        if (rst || flush) begin
            read_index <= 0;
            // for(integer i = 0 ; i < DEPTH ; ++i) begin       // 初始化数组
            //     ram[i] = 0;
            // end
        end
        else if (pop & ~empty) read_index <= read_index + 1;
    end
    always @(posedge clk) begin
        if (rst || flush) begin
            write_index <= 0;
        end
        else if (push & ~push_stall) write_index <= write_index + 1;
    end

    // 读出数据
    assign pop_data = ram[read_index];

    //判断是否空或者满
    assign full        =    (read_index == (write_index + 2) % DEPTH);
    assign push_stall  =    (read_index == (write_index + 1) % DEPTH);
    assign empty       =    (read_index == write_index);

endmodule