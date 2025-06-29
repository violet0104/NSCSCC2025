`timescale 1ns / 1ps
`include "defines.vh"

module pc
(
    input wire clk,
    input wire rst,
    input wire stall,     //停顿信号
    input wire iuncache,  //控制是否使用缓存的的信号，决定使用pc4还是pc8

    //后端给的分支真实情况
    input wire flush,     //强制更新信号
    input wire [31:0] new_pc, //跳转后更新的pc
    input wire pause,     //暂停信号
    input wire [31:0] pre_addr, //预测的分支地址
    input wire [1:0]  taken_sure, // 确定跳转的信号

    output reg pc_o,
    output reg pc_is_exception,
    output reg pc_exception_cause,
    output reg inst_en_1,   //指令使能信号
    output reg inst_en_2
);


    assign inst_en_1 = rst? 1'b0: 1'b1;
    assign inst_en_2 = rst? 1'b0: 1'b1;

    //pc异常的情况
    reg pc_excp;
    assign pc_excp = (pc_o[1: 0] != 2'b00);
    assign pc_is_exception = pc_excp;
    assign pc_exception_cause = (pc_excp ?  `EXCEPTION_ADEF: `EXCEPTION_NOP);

    reg[31:0] pc_4,pc_8;

    always @(posedge clk) begin
        if(rst) begin
            pc_4 <= 32'h1c000000;
            pc_8 <= 32'h1c000000;
        end
        else if(flush) begin
            pc_4 <= new_pc;
            pc_8 <= new_pc;
        end
        else if(|taken_sure) begin
            pc_4 <= pre_branch_addr;
            pc_8 <= pre_branch_addr;
        end
        else if(pause) begin
            pc_4 <= pc_4;
            pc_8 <= pc_8;
        end
        else begin
            if (stall) begin
                pc_4 <= pc_4;
                pc_8 <= pc_8;
            end
            else begin
                pc_4 <= pc_o + 32'h4;
                pc_8 <= pc_o + 32'h8;
            end
        end
    end
    assign pc_o=iuncache?pc_4:pc_8;

endmodule
