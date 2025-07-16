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
    input wire pred_taken, // 确定跳转的信号

    output reg [31:0]pc_out,
    output wire inst_rreq_to_icache,
    output reg pc_is_exception,
    output reg [6:0] pc_exception_cause

);
    //pc异常的情况
    wire pc_excp;
    assign pc_excp = (pc_out[1: 0] != 2'b00);
    assign inst_rreq_to_icache = !rst & !stall & !pause; 

    always @(*) begin
        pc_is_exception = pc_excp;
        pc_exception_cause = (pc_excp ?  `EXCEPTION_ADEF: `EXCEPTION_NOP);
    end

    reg    [31:0] pc_4,pc_8;

    always @(posedge clk) begin
        if(rst) begin
            pc_4 <= 32'h1c000000;
            pc_8 <= 32'h1c000000;
        end
        else if(flush) begin
            pc_4 <= new_pc;
            pc_8 <= new_pc;
        end
        else if(pause) begin
            pc_4 <= pc_4;
            pc_8 <= pc_8;
        end
        else if (stall) begin
            pc_4 <= pc_4;
            pc_8 <= pc_8;
        end
        else if(pred_taken) begin
            pc_4 <= pre_addr;
            pc_8 <= pre_addr;
        end
        else begin
            pc_4 <= pc_out + 32'h4;
            pc_8 <= pc_out + 32'h8;
        end
        
    end
    
    always @(*) begin
        if (iuncache) begin
            pc_out = pc_4;
            end
        else pc_out = pc_8;
    end

endmodule
