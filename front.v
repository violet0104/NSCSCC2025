`timescale 1ps/1ps

module myCPU
(
    input wire cpu_clk,
    input wire cpu_rst,
    input wire iuncache,
    input wire pause,         //暂停信号
    input wire pi_stall,   //停顿信号
    input wire stall_for_buffer,
    output reg pi_pc,     //当前的输出给cache的pc
    output reg pi_inst_en1,  //输出的第一个指令码的使能信号
    output reg pi_inst_en2,
    output reg pi_is_exception,
    output reg pi_exception_cause,

    output reg buffer_full,   //指令缓存满的信号
    output reg bpu_flush,       //分支预测单元的刷新信号
)
    reg pre_addr;
    reg new_pc;
    reg taken_sure;
    reg [1:0] flush;        
    reg [1:0] pause;

    pc u_pc (
        .clk(cpu_clk),
        .rst(cpu_rst),
        .stall(pi_stall),
        .iuncache(iuncache),
        .flush(flush[0]),
        .new_pc(new_pc),
        .pause(pause[0]),
        .pre_addr(pre_addr),  
        .taken_sure(taken_sure),  
        .pc_out(pi_pc),
        .pc_is_exception(pi_is_exception),
        .pc_exception_cause(pi_exception_cause),
        .inst_en_1(pi_inst_en1),
        .inst_en_2(pi_inst_en2)
    );

    bpu u_bpu()

    inst_buffer u_inst_buffer (
        .clk(cpu_clk),
        .rst(cpu_rst),
        .flush(flush[1]),
        .stall(stall_for_buffer),
        .pause(pause[1])
        .pi_pc(pi_pc),
        .pi_inst_en1(pi_inst_en1),
        .pi_inst_en2(pi_inst_en2),
        .buffer_full(buffer_full)
    );

endmodule