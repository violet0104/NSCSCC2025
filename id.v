`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"


module id
(
    input wire [31:0] pc,
    input wire [31:0] inst,
    input wire   valid,
    input wire   pre_taken,  //确定预测的分支跳转正确
    input wire [31:0] pre_addr,   // 预测的分支跳转的地址
    input wire [1:0] is_exception,
    input wire [1:0] [6:0] exception_cause,

    output reg  inst_valid,
    output reg  id_valid_out,
    output reg  [2:0] is_exception_out, //是否异常
    output reg  [2:0][6:0] exception_cause_out, //异常原因
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
    output reg  [31:0] id_pre_addr,
    output reg  is_privilege, //特权指令标志
    output reg  csr_read_en, //CSR寄存器读使能
    output reg  csr_write_en, //CSR寄存器写使能
    output reg  [13:0] csr_addr, //CSR
    output reg  is_cnt, //是否是计数器寄存器
    output reg  invtlb_op  //TLB无效操作

);
    reg  [5:0]  id_valid;  //这个6位的向量表示哪个解码器的输出是有效的
    reg  [31:0] id_pc_out[5:0];
    reg  [2:0]  id_is_exception[5:0]; //是否异常
    reg  [5:0] [6:0]  id_exception_cause [2:0]; //异常原因
    reg  [31:0] id_inst_out[5:0];
    reg  [5:0]  id_reg_writen_en; 
    reg  [5:0]  id_is_privilege;
    reg  [7:0]  id_aluop[5:0];
    reg  [2:0]  id_alusel[5:0];
    reg  [31:0] id_imm[5:0];
    reg  [5:0]  id_reg1_read_en;   
    reg  [5:0]  id_reg2_read_en;   
    reg  [4:0]  id_reg1_read_addr[5:0];
    reg  [4:0]  id_reg2_read_addr[5:0];
    reg  [4:0]  id_reg_write_addr[5:0];
    reg  [5:0]  is_privilege; //特权指令标志
    reg  [5:0]  id_csr_read_en; //CSR寄存器读使能
    reg  [5:0]  id_csr_write_en; //CSR寄存器写使能
    reg  [13:0] id_csr_addr[5:0]; //CSR
    reg  [5:0]  id_is_cnt; //是否是计数器寄存器
    reg  [5:0]  id_invtlb_op ; //TLB无效操作    
    wire [5:0]  id_valid_vec;

    id_1R_I26 u_did_1R_I26 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid[0]),
        .pc_out(id_pc_out[0]),
        .is_exception(id_is_exception[0]),
        .exception_cause(id_exception_cause[0]),
        .inst_out(id_inst_out[0]),
        .reg_writen_en(id_reg_writen_en[0]), 
        .aluop(id_aluop[0]),
        .alusel(id_alusel[0]),
        .imm(id_imm[0]),
        .reg1_read_en(id_reg1_read_en[0]),   
        .reg2_read_en(id_reg2_read_en[0]),  
        .reg1_read_addr(id_reg1_read_addr[0]),
        .reg2_read_addr(id_reg2_read_addr[0]),
        .reg_write_addr(id_reg_write_addr[0]),
        .is_privilege(id_is_privilege[0]),
        .csr_read_en(id_csr_read_en[0]),
        .csr_write_en(id_csr_write_en[0]),
        .csr_addr(csr_addr[0]),
        .is_cnt(id_is_cnt[0]),
        .invtlb_op(id_invtlb_op[0])
    ); 

    id_1RI21 u_id_1RI21 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid[1]),
        .pc_out(id_pc_out[1]),
        .is_exception(id_is_exception[1]),
        .exception_cause(id_exception_cause[1]),
        .inst_out(id_inst_out[1]),
        .reg_writen_en(id_reg_writen_en[1]),
        .aluop(id_aluop[1]),
        .alusel(id_alusel[1]),
        .imm(id_imm[1]),
        .reg1_read_en(id_reg1_read_en[1]),  
        .reg2_read_en(id_reg2_read_en[1]),   
        .reg1_read_addr(id_reg1_read_addr[1]),
        .reg2_read_addr(id_reg2_read_addr[1]),
        .reg_write_addr(id_reg_write_addr[1]),
        .is_privilege(id_is_privilege[1]),
        .csr_read_en(id_csr_read_en[1]),
        .csr_write_en(id_csr_write_en[1]),
        .csr_addr(id_csr_addr[1]),
        .is_cnt(id_is_cnt[1]),
        .invtlb_op(id_invtlb_op[1])
    ); 

    id_2RI12 u_id_2RI12 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid[2]),
        .pc_out(id_pc_out[2]),
        .is_exception(id_is_exception[2]),
        .exception_cause(id_exception_cause[2]),
        .inst_out(id_inst_out[2]),
        .reg_writen_en(id_reg_writen_en[2]), 
        .aluop(id_aluop[2]),
        .alusel(id_alusel[2]),
        .imm(id_imm[2]),
        .reg1_read_en(id_reg1_read_en[2]),   
        .reg2_read_en(id_reg2_read_en[2]),   
        .reg1_read_addr(id_reg1_read_addr[2]),
        .reg2_read_addr(id_reg2_read_addr[2]),
        .reg_write_addr(id_reg_write_addr[2]),
        .is_privilege(id_is_privilege[2]),
        .csr_read_en(id_csr_read_en[2]),
        .csr_write_en(id_csr_write_en[2]),
        .csr_addr(id_csr_addr[2]),
        .is_cnt(id_is_cnt[2]),
        .invtlb_op(id_invtlb_op[2])
    ); 

    id_2RI14 u_id_2RI14 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid[3]),
        .pc_out(id_pc_out[3]),
        .is_exception(id_is_exception[3]),
        .exception_cause(id_exception_cause[3]),
        .inst_out(id_inst_out[3]),
        .reg_writen_en(id_reg_writen_en[3]),
        .aluop(id_aluop[3]),
        .alusel(id_alusel[3]),
        .imm(id_imm[3]),
        .reg1_read_en(id_reg1_read_en[3]),  
        .reg2_read_en(id_reg2_read_en[3]),  
        .reg1_read_addr(id_reg1_read_addr[3]),
        .reg2_read_addr(id_reg2_read_addr[3]),
        .reg_write_addr(id_reg_write_addr[3]),
        .is_privilege(id_is_privilege[3]),
        .csr_read_en(id_csr_read_en[3]),
        .csr_write_en(id_csr_write_en[3]),
        .csr_addr(id_csr_addr[3]),
        .is_cnt(id_is_cnt[3]),
        .invtlb_op(id_invtlb_op[3])
    ); 

    id_2RI16 u_id_2RI16 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid[4]),
        .pc_out(id_pc_out[4]),
        .is_exception(id_is_exception[4]),
        .exception_cause(id_exception_cause[4]),
        .inst_out(id_inst_out[4]),
        .reg_writen_en(id_reg_writen_en[4]), 
        .aluop(id_aluop[4]),
        .alusel(id_alusel[4]),
        .imm(id_imm[4]),
        .reg1_read_en(id_reg1_read_en[4]),   
        .reg2_read_en(id_reg2_read_en[4]),   
        .reg1_read_addr(id_reg1_read_addr[4]),
        .reg2_read_addr(id_reg2_read_addr[4]),
        .reg_write_addr(id_reg_write_addr[4]),
        .is_privilege(id_is_privilege[4]),
        .csr_read_en(id_csr_read_en[4]),
        .csr_write_en(id_csr_write_en[4]),
        .csr_addr(id_csr_addr[4]),
        .is_cnt(id_is_cnt[4]),
        .invtlb_op(id_invtlb_op[4])
    ); 

    id_3R u_id_3R (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid[5]),
        .pc_out(id_pc_out[5]),
        .is_exception(id_is_exception[5]),
        .exception_cause(id_exception_cause[5]),
        .inst_out(id_inst_out[5]),
        .reg_writen_en(id_reg_writen_en[5]), 
        .aluop(id_aluop[5]),
        .alusel(id_alusel[5]),
        .imm(id_imm[5]),
        .reg1_read_en(id_reg1_read_en[5]),  
        .reg2_read_en(id_reg2_read_en[5]),   
        .reg1_read_addr(id_reg1_read_addr[5]),
        .reg2_read_addr(id_reg2_read_addr[5]),
        .reg_write_addr(id_reg_write_addr[5]),
        .is_privilege(id_is_privilege[5]),
        .csr_read_en(id_csr_read_en[5]),
        .csr_write_en(id_csr_write_en[5]),
        .csr_addr(id_csr_addr[5]),
        .is_cnt(id_is_cnt[5]),
        .invtlb_op(id_invtlb_op[5])
    ); 
    

    wire sys_exception;
    wire brk_exception;
    assign sys_exception = aluop == `ALU_SYSCALL;
    assign brk_exception = aluop == `ALU_BREAK;
    reg  [6:0]id_exception_cause_else;

    always  @(*) begin
        if (sys_exception) begin
            id_exception_cause_else = `EXCEPTION_SYS;
        end else if (brk_exception) begin
            id_exception_cause_else = `EXCEPTION_BRK;
        end else begin
            id_exception_cause_else = `EXCEPTION_NOP;
        end
    end


    always  @(*) begin
        case(id_valid)
            6'b000001: begin
                inst_valid = id_valid[0];
                pc_out = id_pc_out[0];
                is_exception_out = id_is_exception[0];
                exception_cause_out = id_exception_cause[0];
                inst_out = id_inst_out[0];
                reg_writen_en = id_reg_writen_en[0]; 
                aluop = id_aluop[0];
                alusel = id_alusel[0];
                imm = id_imm[0];
                reg1_read_en = id_reg1_read_en[0];   
                reg2_read_en = id_reg2_read_en[0];   
                reg1_read_addr = id_reg1_read_addr[0];
                reg2_read_addr = id_reg2_read_addr[0];
                reg_write_addr = id_reg_write_addr[0];
                is_privilege = id_is_privilege[0];
                csr_read_en = id_csr_read_en[0];
                csr_write_en = id_csr_write_en[0];
                csr_addr = id_csr_addr[0];
                is_cnt = id_is_cnt[0];
                invtlb_op = id_invtlb_op[0];
            end
            6'b000010: begin
                inst_valid = id_valid[1];
                pc_out = id_pc_out[1];
                is_exception_out = id_is_exception[1];
                exception_cause_out = id_exception_cause[1];
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
                is_privilege = id_is_privilege[1];
                csr_read_en = id_csr_read_en[1];    
                csr_write_en = id_csr_write_en[1];
                csr_addr = id_csr_addr[1];
                is_cnt = id_is_cnt[1];
                invtlb_op = id_invtlb_op[1];
            end
            6'b000100: begin
                inst_valid = id_valid[2];
                pc_out = id_pc_out[2];
                is_exception_out = id_is_exception[2];
                exception_cause_out = id_exception_cause[2];
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
                is_privilege = id_is_privilege[2];
                csr_read_en = id_csr_read_en[2];
                csr_write_en = id_csr_write_en[2];
                csr_addr = id_csr_addr[2];
                is_cnt = id_is_cnt[2];
                invtlb_op = id_invtlb_op[2];
            end
            6'b001000: begin
                inst_valid = id_valid[3];
                pc_out = id_pc_out[3];
                is_exception_out = id_is_exception[3];
                exception_cause_out = id_exception_cause[3];
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
                is_privilege = id_is_privilege[3];
                csr_read_en = id_csr_read_en[3];
                csr_write_en = id_csr_write_en[3];
                csr_addr = id_csr_addr[3];
                is_cnt = id_is_cnt[3];
                invtlb_op = id_invtlb_op[3];
            end
            6'b010000: begin
                inst_valid = id_valid[4];
                pc_out = id_pc_out[4];
                is_exception_out = id_is_exception[4];
                exception_cause_out = id_exception_cause[4];
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
                is_privilege = id_is_privilege[4];
                csr_read_en = id_csr_read_en[4];
                csr_write_en = id_csr_write_en[4];
                csr_addr = id_csr_addr[4];
                is_cnt = id_is_cnt[4];
                invtlb_op = id_invtlb_op[4];
            end
            6'b100000: begin
                inst_valid = id_valid[5];
                pc_out = id_pc_out[5];
                is_exception_out = {is_exception,sys_exception | brk_exception};
                exception_cause_out = {exception_cause,id_exception_cause_else};
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
                is_privilege = id_is_privilege[5];
                csr_read_en = id_csr_read_en[5];
                csr_write_en = id_csr_write_en[5];
                csr_addr = id_csr_addr[5];
                is_cnt = id_is_cnt[5];
                invtlb_op = id_invtlb_op[5];
            end
            default: begin
                inst_valid = 1'b0;
                pc_out = pc;
                is_exception_out = {is_exception,1'b1};
                exception_cause_out = {exception_cause,`EXCEPTION_INE};
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
                is_privilege = 0;
                csr_read_en = 0;
                csr_write_en = 0;
                csr_addr = 14'b0;
                is_cnt = 0;
                invtlb_op = 0;
            end
        endcase
     end

        always @(*) begin
            id_pre_taken = pre_taken;
            id_pre_addr  = pre_addr;
            id_valid     = valid;
        end
endmodule