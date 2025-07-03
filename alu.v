
module alu (
    input wire clk.
    input wire rst,
    input wire flush,           // 流水线刷新信号

    input wire pasue_mem,       // 访存阶段暂停信号

    input wire [31:0] pc,
    input wire [31:0] inst,

    input wire [2:0] is_exception,
);
    
    
endmodule