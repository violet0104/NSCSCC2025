`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"


module id
(   
    input wire   valid,

    input wire [31:0] pc,
    input wire [31:0] inst,

    input wire  pre_taken,          // 分支预测结果（是否跳转）
    input wire [31:0] pre_addr,     // 预测分支跳转目标地址
    input wire [1:0] is_exception,
    input wire [6:0] pc_exception_cause,
    input wire [6:0] instbuffer_exception_cause,


    output reg  id_valid,

    output reg  [31:0] pc_out,
    output reg  [31:0] inst_out,

    output reg  [2:0] is_exception_out,                 //是否异常
    output reg  [6:0] pc_exception_cause_out,           //异常原因
    output reg  [6:0] instbuffer_exception_cause_out, 
    output reg  [6:0] decoder_exception_cause_out,

    output reg  [7:0]aluop,
    output reg  [2:0]alusel,
    output reg  [31:0]imm,

    output reg  reg1_read_en,       //rR1寄存器读使能
    output reg  reg2_read_en,       //rR2寄存器读使能
    output reg  [4:0]reg1_read_addr,
    output reg  [4:0]reg2_read_addr,
    output reg  reg_writen_en,          //寄存器写使能信号
    output reg  [4:0]reg_write_addr,    //目的寄存器地址

    output reg  id_pre_taken,
    output reg  [31:0] id_pre_addr,

    output reg  is_privilege,       //特权指令标志
    output reg  csr_read_en,        //CSR寄存器读使能
    output reg  csr_write_en,       //CSR寄存器写使能
    output reg  [13:0] csr_addr,    //CSR
    output reg  is_cnt,             //是否是计数器寄存器
    output reg  [4:0]invtlb_op           //TLB无效操作

);
    wire  [5:0]  id_valid_o;
    
    wire  [31:0] id_pc_out0;
    wire  [31:0] id_pc_out1;
    wire  [31:0] id_pc_out2;
    wire  [31:0] id_pc_out3;
    wire  [31:0] id_pc_out4;
    wire  [31:0] id_pc_out5;

    wire  [2:0]  id_is_exception0;           //是否异常
    wire  [2:0]  id_is_exception1;
    wire  [2:0]  id_is_exception2;
    wire  [2:0]  id_is_exception3;
    wire  [2:0]  id_is_exception4;
    wire  [2:0]  id_is_exception5;          // 这个好像没用到

    wire  [6:0]  id_pc_exception_cause0;    //异常原因 
    wire  [6:0]  id_pc_exception_cause1;
    wire  [6:0]  id_pc_exception_cause2;
    wire  [6:0]  id_pc_exception_cause3;
    wire  [6:0]  id_pc_exception_cause4;
    wire  [6:0]  id_pc_exception_cause5;

    wire  [6:0]  id_instbuffer_exception_cause0; 
    wire  [6:0]  id_instbuffer_exception_cause1; 
    wire  [6:0]  id_instbuffer_exception_cause2; 
    wire  [6:0]  id_instbuffer_exception_cause3; 
    wire  [6:0]  id_instbuffer_exception_cause4; 
    wire  [6:0]  id_instbuffer_exception_cause5; 

    wire  [6:0]  id_decoder_exception_cause0;
    wire  [6:0]  id_decoder_exception_cause1;
    wire  [6:0]  id_decoder_exception_cause2;
    wire  [6:0]  id_decoder_exception_cause3;
    wire  [6:0]  id_decoder_exception_cause4;
    wire  [6:0]  id_decoder_exception_cause5;

    wire  [31:0] id_inst_out0;
    wire  [31:0] id_inst_out1;
    wire  [31:0] id_inst_out2;
    wire  [31:0] id_inst_out3;
    wire  [31:0] id_inst_out4;
    wire  [31:0] id_inst_out5;

    wire  [5:0]  id_reg_writen_en; 

    wire  [7:0]  id_aluop0;
    wire  [7:0]  id_aluop1;
    wire  [7:0]  id_aluop2;
    wire  [7:0]  id_aluop3;
    wire  [7:0]  id_aluop4;
    wire  [7:0]  id_aluop5;

    wire  [2:0]  id_alusel0;
    wire  [2:0]  id_alusel1;
    wire  [2:0]  id_alusel2;
    wire  [2:0]  id_alusel3;
    wire  [2:0]  id_alusel4;
    wire  [2:0]  id_alusel5;

    wire  [31:0] id_imm0;
    wire  [31:0] id_imm1;
    wire  [31:0] id_imm2;
    wire  [31:0] id_imm3;
    wire  [31:0] id_imm4;
    wire  [31:0] id_imm5;

    wire  [5:0]  id_reg1_read_en;   
    wire  [5:0]  id_reg2_read_en;   

    wire  [4:0]  id_reg1_read_addr0;
    wire  [4:0]  id_reg1_read_addr1;
    wire  [4:0]  id_reg1_read_addr2;
    wire  [4:0]  id_reg1_read_addr3;
    wire  [4:0]  id_reg1_read_addr4;
    wire  [4:0]  id_reg1_read_addr5;

    wire  [4:0]  id_reg2_read_addr0;
    wire  [4:0]  id_reg2_read_addr1;
    wire  [4:0]  id_reg2_read_addr2;
    wire  [4:0]  id_reg2_read_addr3;
    wire  [4:0]  id_reg2_read_addr4;
    wire  [4:0]  id_reg2_read_addr5;

    wire  [4:0]  id_reg_write_addr0;
    wire  [4:0]  id_reg_write_addr1;
    wire  [4:0]  id_reg_write_addr2;
    wire  [4:0]  id_reg_write_addr3;
    wire  [4:0]  id_reg_write_addr4;
    wire  [4:0]  id_reg_write_addr5;

    wire  [5:0]  id_is_privilege;   //特权指令标志
    wire  [5:0]  id_csr_read_en;    //CSR寄存器读使能
    wire  [5:0]  id_csr_write_en;   //CSR寄存器写使能

    wire  [13:0] id_csr_addr0;      //CSR
    wire  [13:0] id_csr_addr1;
    wire  [13:0] id_csr_addr2;
    wire  [13:0] id_csr_addr3;
    wire  [13:0] id_csr_addr4;
    wire  [13:0] id_csr_addr5;

    wire  [5:0]  id_is_cnt;         //是否是计数器寄存器

    wire  [4:0]  id_invtlb_op0;     //TLB无效操作  
    wire  [4:0]  id_invtlb_op1;
    wire  [4:0]  id_invtlb_op2;
    wire  [4:0]  id_invtlb_op3;
    wire  [4:0]  id_invtlb_op4;
    wire  [4:0]  id_invtlb_op5;

    wire [5:0]  id_valid_vec;       //这个6位的向量表示哪个解码器的输出是有效的

    id_1R_I26 u_id_1R_I26 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid_vec[0]),
        .pc_out(id_pc_out0),
        .is_exception(id_is_exception0),
        .pc_exception_cause(id_pc_exception_cause0),
        .instbuffer_exception_cause(id_instbuffer_exception_cause0),
        .decoder_exception_cause(id_decoder_exception_cause0),
        .inst_out(id_inst_out0),
        .reg_writen_en(id_reg_writen_en[0]), 
        .aluop(id_aluop0),
        .alusel(id_alusel0),
        .imm(id_imm0),
        .reg1_read_en(id_reg1_read_en[0]),   
        .reg2_read_en(id_reg2_read_en[0]),  
        .reg1_read_addr(id_reg1_read_addr0),
        .reg2_read_addr(id_reg2_read_addr0),
        .reg_write_addr(id_reg_write_addr0),
        .is_privilege(id_is_privilege[0]),
        .csr_read_en(id_csr_read_en[0]),
        .csr_write_en(id_csr_write_en[0]),
        .csr_addr(id_csr_addr0),
        .is_cnt(id_is_cnt[0]),
        .invtlb_op(id_invtlb_op0)
    ); 

    id_1RI20 u_id_1RI20 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid_vec[1]),
        .pc_out(id_pc_out1),
        .is_exception(id_is_exception1),
        .pc_exception_cause(id_pc_exception_cause1),
        .instbuffer_exception_cause(id_instbuffer_exception_cause1),
        .decoder_exception_cause(id_decoder_exception_cause1),
        .inst_out(id_inst_out1),
        .reg_writen_en(id_reg_writen_en[1]),
        .aluop(id_aluop1),
        .alusel(id_alusel1),
        .imm(id_imm1),
        .reg1_read_en(id_reg1_read_en[1]),  
        .reg2_read_en(id_reg2_read_en[1]),   
        .reg1_read_addr(id_reg1_read_addr1),
        .reg2_read_addr(id_reg2_read_addr1),
        .reg_write_addr(id_reg_write_addr1),
        .is_privilege(id_is_privilege[1]),
        .csr_read_en(id_csr_read_en[1]),
        .csr_write_en(id_csr_write_en[1]),
        .csr_addr(id_csr_addr1),
        .is_cnt(id_is_cnt[1]),
        .invtlb_op(id_invtlb_op1)
    ); 

    id_2RI12 u_id_2RI12 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid_vec[2]),
        .pc_out(id_pc_out2),
        .is_exception(id_is_exception2),
        .pc_exception_cause(id_pc_exception_cause2),
        .instbuffer_exception_cause(id_instbuffer_exception_cause2),
        .decoder_exception_cause(id_decoder_exception_cause2),
        .inst_out(id_inst_out2),
        .reg_writen_en(id_reg_writen_en[2]), 
        .aluop(id_aluop2),
        .alusel(id_alusel2),
        .imm(id_imm2),
        .reg1_read_en(id_reg1_read_en[2]),   
        .reg2_read_en(id_reg2_read_en[2]),   
        .reg1_read_addr(id_reg1_read_addr2),
        .reg2_read_addr(id_reg2_read_addr2),
        .reg_write_addr(id_reg_write_addr2),
        .is_privilege(id_is_privilege[2]),
        .csr_read_en(id_csr_read_en[2]),
        .csr_write_en(id_csr_write_en[2]),
        .csr_addr(id_csr_addr2),
        .is_cnt(id_is_cnt[2]),
        .invtlb_op(id_invtlb_op2)
    ); 

    id_2RI14 u_id_2RI14 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid_vec[3]),
        .pc_out(id_pc_out3),
        .is_exception(id_is_exception3),
        .pc_exception_cause(id_pc_exception_cause3),
        .instbuffer_exception_cause(id_instbuffer_exception_cause3),
        .decoder_exception_cause(id_decoder_exception_cause3),
        .inst_out(id_inst_out3),
        .reg_write_en(id_reg_writen_en[3]),
        .aluop(id_aluop3),
        .alusel(id_alusel3),
        .imm(id_imm3),
        .reg1_read_en(id_reg1_read_en[3]),  
        .reg2_read_en(id_reg2_read_en[3]),  
        .reg1_read_addr(id_reg1_read_addr3),
        .reg2_read_addr(id_reg2_read_addr3),
        .reg_write_addr(id_reg_write_addr3),
        .is_privilege(id_is_privilege[3]),
        .csr_read_en(id_csr_read_en[3]),
        .csr_write_en(id_csr_write_en[3]),
        .csr_addr(id_csr_addr3),
        .is_cnt(id_is_cnt[3]),
        .invtlb_op(id_invtlb_op3)
    ); 

    id_2RI16 u_id_2RI16 (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid_vec[4]),
        .pc_out(id_pc_out4),
        .is_exception(id_is_exception4),
        .pc_exception_cause(id_pc_exception_cause4),
        .instbuffer_exception_cause(id_instbuffer_exception_cause4),
        .decoder_exception_cause(id_decoder_exception_cause4),
        .inst_out(id_inst_out4),
        .reg_writen_en(id_reg_writen_en[4]), 
        .aluop(id_aluop4),
        .alusel(id_alusel4),
        .imm(id_imm4),
        .reg1_read_en(id_reg1_read_en[4]),   
        .reg2_read_en(id_reg2_read_en[4]),   
        .reg1_read_addr(id_reg1_read_addr4),
        .reg2_read_addr(id_reg2_read_addr4),
        .reg_write_addr(id_reg_write_addr4),
        .is_privilege(id_is_privilege[4]),
        .csr_read_en(id_csr_read_en[4]),
        .csr_write_en(id_csr_write_en[4]),
        .csr_addr(id_csr_addr4),
        .is_cnt(id_is_cnt[4]),
        .invtlb_op(id_invtlb_op4)
    ); 

    id_3R u_id_3R (
        .pc(pc),
        .inst(inst),

        .inst_valid(id_valid_vec[5]),
        .pc_out(id_pc_out5),
        .is_exception(id_is_exception5),
        .pc_exception_cause(id_pc_exception_cause5),
        .instbuffer_exception_cause(id_instbuffer_exception_cause5),
        .decoder_exception_cause(id_decoder_exception_cause5),
        .inst_out(id_inst_out5),
        .reg_write_en(id_reg_writen_en[5]), 
        .aluop(id_aluop5),
        .alusel(id_alusel5),
        .imm(id_imm5),
        .reg1_read_en(id_reg1_read_en[5]),  
        .reg2_read_en(id_reg2_read_en[5]),   
        .reg1_read_addr(id_reg1_read_addr5),
        .reg2_read_addr(id_reg2_read_addr5),
        .reg_write_addr(id_reg_write_addr5),
        .is_privilege(id_is_privilege[5]),
        .csr_read_en(id_csr_read_en[5]),
        .csr_write_en(id_csr_write_en[5]),
        .csr_addr(id_csr_addr5),
        .is_cnt(id_is_cnt[5]),
        .invtlb_op(id_invtlb_op5)
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
        case(id_valid_vec)
            6'b000001: begin
                pc_out = id_pc_out0;
                is_exception_out = id_is_exception0;
                pc_exception_cause_out = id_pc_exception_cause0;
                instbuffer_exception_cause_out = id_instbuffer_exception_cause0;
                decoder_exception_cause_out = id_decoder_exception_cause0;
                inst_out = id_inst_out0;
                reg_writen_en = id_reg_writen_en[0]; 
                aluop = id_aluop0;
                alusel = id_alusel0;
                imm = id_imm0;
                reg1_read_en = id_reg1_read_en[0];   
                reg2_read_en = id_reg2_read_en[0];   
                reg1_read_addr = id_reg1_read_addr0;
                reg2_read_addr = id_reg2_read_addr0;
                reg_write_addr = id_reg_write_addr0;
                is_privilege = id_is_privilege[0];
                csr_read_en = id_csr_read_en[0];
                csr_write_en = id_csr_write_en[0];
                csr_addr = id_csr_addr0;
                is_cnt = id_is_cnt[0];
                invtlb_op = id_invtlb_op0;
            end
            6'b000010: begin
                pc_out = id_pc_out1;
                is_exception_out = id_is_exception1;
                pc_exception_cause_out = id_pc_exception_cause1;
                instbuffer_exception_cause_out = id_instbuffer_exception_cause1;
                decoder_exception_cause_out = id_decoder_exception_cause1;
                inst_out = id_inst_out1;
                reg_writen_en = id_reg_writen_en[1]; 
                aluop = id_aluop1;
                alusel = id_alusel1;
                imm = id_imm1;
                reg1_read_en = id_reg1_read_en[1];   
                reg2_read_en = id_reg2_read_en[1];   
                reg1_read_addr = id_reg1_read_addr1;
                reg2_read_addr = id_reg2_read_addr1;
                reg_write_addr = id_reg_write_addr1;
                is_privilege = id_is_privilege[1];
                csr_read_en = id_csr_read_en[1];    
                csr_write_en = id_csr_write_en[1];
                csr_addr = id_csr_addr1;
                is_cnt = id_is_cnt[1];
                invtlb_op = id_invtlb_op1;
            end
            6'b000100: begin
                pc_out = id_pc_out2;
                is_exception_out = id_is_exception2;
                pc_exception_cause_out = id_pc_exception_cause2;
                instbuffer_exception_cause_out = id_instbuffer_exception_cause2;
                decoder_exception_cause_out = id_decoder_exception_cause2;
                inst_out = id_inst_out2;
                reg_writen_en = id_reg_writen_en[2]; 
                aluop = id_aluop2;
                alusel = id_alusel2;
                imm = id_imm2;
                reg1_read_en = id_reg1_read_en[2];   
                reg2_read_en = id_reg2_read_en[2];   
                reg1_read_addr = id_reg1_read_addr2;
                reg2_read_addr = id_reg2_read_addr2;
                reg_write_addr = id_reg_write_addr2;
                is_privilege = id_is_privilege[2];
                csr_read_en = id_csr_read_en[2];
                csr_write_en = id_csr_write_en[2];
                csr_addr = id_csr_addr2;
                is_cnt = id_is_cnt[2];
                invtlb_op = id_invtlb_op2;
            end
            6'b001000: begin
                pc_out = id_pc_out3;
                is_exception_out = id_is_exception3;
                pc_exception_cause_out = id_pc_exception_cause3;
                instbuffer_exception_cause_out = id_instbuffer_exception_cause3;
                decoder_exception_cause_out = id_decoder_exception_cause3;
                inst_out = id_inst_out3;
                reg_writen_en = id_reg_writen_en[3]; 
                aluop = id_aluop3;
                alusel = id_alusel3;
                imm = id_imm3;
                reg1_read_en = id_reg1_read_en[3];   
                reg2_read_en = id_reg2_read_en[3];   
                reg1_read_addr = id_reg1_read_addr3;
                reg2_read_addr = id_reg2_read_addr3;
                reg_write_addr = id_reg_write_addr3;
                is_privilege = id_is_privilege[3];
                csr_read_en = id_csr_read_en[3];
                csr_write_en = id_csr_write_en[3];
                csr_addr = id_csr_addr3;
                is_cnt = id_is_cnt[3];
                invtlb_op = id_invtlb_op3;
            end
            6'b010000: begin
                pc_out = id_pc_out4;
                is_exception_out = id_is_exception4;
                pc_exception_cause_out = id_pc_exception_cause4;
                instbuffer_exception_cause_out = id_instbuffer_exception_cause4;
                decoder_exception_cause_out = id_decoder_exception_cause4;
                inst_out = id_inst_out4;
                reg_writen_en = id_reg_writen_en[4]; 
                aluop = id_aluop4;
                alusel = id_alusel4;
                imm = id_imm4;
                reg1_read_en = id_reg1_read_en[4];   
                reg2_read_en = id_reg2_read_en[4];   
                reg1_read_addr = id_reg1_read_addr4;
                reg2_read_addr = id_reg2_read_addr4;
                reg_write_addr = id_reg_write_addr4;
                is_privilege = id_is_privilege[4];
                csr_read_en = id_csr_read_en[4];
                csr_write_en = id_csr_write_en[4];
                csr_addr = id_csr_addr4;
                is_cnt = id_is_cnt[4];
                invtlb_op = id_invtlb_op4;
            end
            6'b100000: begin
                pc_out = id_pc_out5;
                is_exception_out = {is_exception,sys_exception | brk_exception};
                pc_exception_cause_out = pc_exception_cause;  
                instbuffer_exception_cause_out = instbuffer_exception_cause;
                decoder_exception_cause_out = id_exception_cause_else;
                inst_out = id_inst_out5;
                reg_writen_en = id_reg_writen_en[5]; 
                aluop = id_aluop5;
                alusel = id_alusel5;
                imm = id_imm5;
                reg1_read_en = id_reg1_read_en[5];   
                reg2_read_en = id_reg2_read_en[5];   
                reg1_read_addr = id_reg1_read_addr5;
                reg2_read_addr = id_reg2_read_addr5;
                reg_write_addr = id_reg_write_addr5;
                is_privilege = id_is_privilege[5];
                csr_read_en = id_csr_read_en[5];
                csr_write_en = id_csr_write_en[5];
                csr_addr = id_csr_addr5;
                is_cnt = id_is_cnt[5];
                invtlb_op = id_invtlb_op5;
            end
            default: begin
                pc_out = pc;
                is_exception_out = {is_exception, 1'b1};
                pc_exception_cause_out = pc_exception_cause;  
                instbuffer_exception_cause_out = instbuffer_exception_cause;
                decoder_exception_cause_out = `EXCEPTION_INE;
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