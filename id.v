`include "defines.v"
`timescale 1ps/1ps

module id
(
    input [31:0] pc,
    input [31:0] inst,
    input wire   valid,
    input wire   pre_taken,  //确定预测的分支跳转正确
    input [31:0] pre_addr,   // 预测的分支跳转的地址
    input wire [1:0] is_exception,
    input wire [1:0] [6:0] exception_cause,

    output reg  inst_valid,
    output reg  [31:0] pc_out,
    output reg  [31:0] inst_out,
    output reg  reg_writen_en,  //寄存器写使能信号
    output reg  [7:0]aluop,
    output reg  [3:0]alusel,
    output reg  [31:0]imm,
    output reg  reg1_read_en,   //rR1寄存器读使能
    output reg  reg2_read_en,   //rR2寄存器读使能
    output reg  [4:0]reg1_read_addr,
    output reg  [4:0]reg2_read_addr,
    output reg  [4:0]reg_write_addr,  //目的寄存器地址
    output reg  id_pre_taken,
    output reg  [31:0] id_pre_addr
)
    reg  [5:0] id_valid;  //这个6位的向量表示哪个解码器的输出是有效的
    reg  [5:0] [31:0] id_pc_out;
    reg  [5:0] [31:0] id_inst_out;
    reg  [5:0] id_reg_writen_en; 
    reg  [5:0] [7:0]id_aluop;
    reg  [5:0] [2:0]id_alusel;
    reg  [5:0] [31:0]id_imm;
    reg  [5:0] id_reg1_read_en;   
    reg  [5:0] id_reg2_read_en;   
    reg  [5:0] [4:0]id_reg1_read_addr;
    reg  [5:0] [4:0]id_reg2_read_addr;
    reg  [5:0] [4:0]id_reg_write_addr;

    decoder_1R u_decoder_1R (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid[0]),
        .pc_out(id_pc_out[0]);
        .inst_out(id_inst_out[0]);
        .reg_writen_en(id_reg_writen_en[0]); 
        .aluop(id_aluop[0]);
        .alusel(id_alusel[0]);
        .imm(id_imm[0]);
        .reg1_read_en(id_reg1_read_en[0]);   
        .reg2_read_en(id_reg2_read_en[0]);   
        .reg1_read_addr(id_reg1_read_addr[0]);
        .reg2_read_addr(id_reg2_read_addr[0]);
        .reg_write_addr(id_reg1_write_addr[0]);
    ); 

    decoder_1RI21 u_decoder_1RI21 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid[1]),
        .pc_out(id_pc_out[1]);
        .inst_out(id_inst_out[1]);
        .reg_writen_en(id_reg_writen_en[1]); 
        .aluop(id_aluop[1]);
        .alusel(id_alusel[1]);
        .imm(id_imm[1]);
        .reg1_read_en(id_reg1_read_en[1]);   
        .reg2_read_en(id_reg2_read_en[1]);   
        .reg1_read_addr(id_reg1_read_addr[1]);
        .reg2_read_addr(id_reg2_read_addr[1]);
        .reg_write_addr(id_reg1_write_addr[1]);
    ); 

    decoder_2RI12 u_decoder_2RI12 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid[2]),
        .pc_out(id_pc_out[2]);
        .inst_out(id_inst_out[2]);
        .reg_writen_en(id_reg_writen_en[2]); 
        .aluop(id_aluop[2]);
        .alusel(id_alusel[2]);
        .imm(id_imm[2]);
        .reg1_read_en(id_reg1_read_en[2]);   
        .reg2_read_en(id_reg2_read_en[2]);   
        .reg1_read_addr(id_reg1_read_addr[2]);
        .reg2_read_addr(id_reg2_read_addr[2]);
        .reg_write_addr(id_reg1_write_addr[2]);
    ); 

    decoder_2RI14 u_decoder_2RI14 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid[3]),
        .pc_out(id_pc_out[3]);
        .inst_out(id_inst_out[3]);
        .reg_writen_en(id_reg_writen_en[3]); 
        .aluop(id_aluop[3]);
        .alusel(id_alusel[3]);
        .imm(id_imm[3]);
        .reg1_read_en(id_reg1_read_en[3]);   
        .reg2_read_en(id_reg2_read_en[3]);   
        .reg1_read_addr(id_reg1_read_addr[3]);
        .reg2_read_addr(id_reg2_read_addr[3]);
        .reg_write_addr(id_reg1_write_addr[3]);
    ); 

    decoder_2RI16 u_decoder_2RI16 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid[4]),
        .pc_out(id_pc_out[4]);
        .inst_out(id_inst_out[4]);
        .reg_writen_en(id_reg_writen_en[4]); 
        .aluop(id_aluop[4]);
        .alusel(id_alusel[4]);
        .imm(id_imm[4]);
        .reg1_read_en(id_reg1_read_en[4]);   
        .reg2_read_en(id_reg2_read_en[4]);   
        .reg1_read_addr(id_reg1_read_addr[4]);
        .reg2_read_addr(id_reg2_read_addr[4]);
        .reg_write_addr(id_reg1_write_addr[4]);
    ); 

    decoder_3R u_decoder_3R (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid[5]),
        .pc_out(id_pc_out[5]);
        .inst_out(id_inst_out[5]);
        .reg_writen_en(id_reg_writen_en[5]); 
        .aluop(id_aluop[5]);
        .alusel(id_alusel[5]);
        .imm(id_imm[5]);
        .reg1_read_en(id_reg1_read_en[5]);   
        .reg2_read_en(id_reg2_read_en[5]);   
        .reg1_read_addr(id_reg1_read_addr[5]);
        .reg2_read_addr(id_reg2_read_addr[5]);
        .reg_write_addr(id_reg1_write_addr[5]);
    ); 

    always  @(*) begin
        case(id_valid)
            6'b000001: begin
                inst_valid = id_valid[1];
                pc_out = id_pc_out[1];
                inst_out = id_inst_out[1];
                reg_writen_en = id_reg_writen_en[1]; 
                aluop = id_aluop[1];
                alusel = id_alusel[1];
                imm = id_imm[1];
                reg1_read_en = id_reg1_read_en[1];   
                reg2_read_en = id_reg2_read_en[1];   
                reg1_read_addr = id_reg1_read_addr[1];
                reg2_read_addr = id_reg2_read_addr[1];
                reg_write_addr = id_reg_write_addr[1];
            end
            6'b000010: begin
                inst_valid = id_valid[2];
                pc_out = id_pc_out[2];
                inst_out = id_inst_out[2];
                reg_writen_en = id_reg_writen_en[2]; 
                aluop = id_aluop[2];
                alusel = id_alusel[2];
                imm = id_imm[2];
                reg1_read_en = id_reg1_read_en[2];   
                reg2_read_en = id_reg2_read_en[2];   
                reg1_read_addr = id_reg1_read_addr[2];
                reg2_read_addr = id_reg2_read_addr[2];
                reg_write_addr = id_reg_write_addr[2];
            end
            6'b000100: begin
                inst_valid = id_valid[3];
                pc_out = id_pc_out[3];
                inst_out = id_inst_out[3];
                reg_writen_en = id_reg_writen_en[3]; 
                aluop = id_aluop[3];
                alusel = id_alusel[3];
                imm = id_imm[3];
                reg1_read_en = id_reg1_read_en[3];   
                reg2_read_en = id_reg2_read_en[3];   
                reg1_read_addr = id_reg1_read_addr[3];
                reg2_read_addr = id_reg2_read_addr[3];
                reg_write_addr = id_reg_write_addr[3];
            end
            6'b001000: begin
                inst_valid = id_valid[4];
                pc_out = id_pc_out[4];
                inst_out = id_inst_out[4];
                reg_writen_en = id_reg_writen_en[4]; 
                aluop = id_aluop[4];
                alusel = id_alusel[4];
                imm = id_imm[4];
                reg1_read_en = id_reg1_read_en[4];   
                reg2_read_en = id_reg2_read_en[4];   
                reg1_read_addr = id_reg1_read_addr[4];
                reg2_read_addr = id_reg2_read_addr[4];
                reg_write_addr = id_reg_write_addr[4];
            end
            6'b010000: begin
                inst_valid = id_valid[5];
                pc_out = id_pc_out[5];
                inst_out = id_inst_out[5];
                reg_writen_en = id_reg_writen_en[5]; 
                aluop = id_aluop[5];
                alusel = id_alusel[5];
                imm = id_imm[5];
                reg1_read_en = id_reg1_read_en[5];   
                reg2_read_en = id_reg2_read_en[5];   
                reg1_read_addr = id_reg1_read_addr[5];
                reg2_read_addr = id_reg2_read_addr[5];
                reg_write_addr = id_reg_write_addr[5];
            end
            6'b100000: begin
                inst_valid = id_valid[6];
                pc_out = id_pc_out[6];
                inst_out = id_inst_out[6];
                reg_writen_en = id_reg_writen_en[6]; 
                aluop = id_aluop[6];
                alusel = id_alusel[6];
                imm = id_imm[6];
                reg1_read_en = id_reg1_read_en[6];   
                reg2_read_en = id_reg2_read_en[6];   
                reg1_read_addr = id_reg1_read_addr[6];
                reg2_read_addr = id_reg2_read_addr[6];
                reg_write_addr = id_reg_write_addr[6];
            end
            default: begin
                inst_valid = 0;
                pc_out = pc;
                inst_out = 32'b0;
                reg_writen_en = 0; 
                aluop = 8'b0;
                alusel = 3'b0;
                imm = 32'b0;
                reg1_read_en = 0;   
                reg2_read_en = 0;   
                reg1_read_addr = 0;
                reg2_read_addr = 0;
                reg_write_addr = 0;
            end
        endcase

        id_pre_taken = pre_taken;
        id_pre_addr  = pre_addr;
    end
endmodule