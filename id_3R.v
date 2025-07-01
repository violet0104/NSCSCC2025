`include "defines.vh"
`timescale 1ns / 1ps

module id_3R
(
    input  wire [31:0] pc,
    input  wire [31:0] inst,
    output reg  inst_valid,
    output reg  [31:0] pc_out,
    output reg  [31:0] inst_out,
    output reg  reg_writen_en,  //寄存器写使能信号
    output reg  [7:0]aluop,
    output reg  [2:0]alusel,
    output reg  [31:0]imm,
    output reg  reg1_read_en,   //rR1寄存器读使能
    output reg  reg2_read_en,   //rR2寄存器读使能
    output reg  [4:0]reg1_read_addr,
    output reg  [4:0]reg2_read_addr,
    output reg  [4:0]reg_write_addr,  //目的寄存器地址
    output reg  privilege, //特权指令标志
    output reg  csr_read_en, //CSR寄存器读使能
    output reg  csr_write_en, //CSR寄存器写使能
    output reg  [13:0] csr_addr, //CSR
    output reg  is_cnt, //是否是计数器寄存器
    output reg  invtlb_op , //TLB无效操作
);
    reg [16:0] opcode;
    reg [4:0] rk;
    reg [4:0] rj;  
    reg [4:0] rd;
    reg [4:0] ui5;

    opcode = inst[31:15];
    rk = inst[14:10];
    rj = inst[9:5];
    rd = inst[4:0];
    ui5 = inst[14:10];

    pc_out = pc;
    inst_out = inst;
    reg1_read_addr = rj;
    reg2_read_addr = rk;
    reg_write_addr = rd;
    csr_read_en = 1'b0;
    csr_write_en = 1'b0;
    csr_addr = 14'b0;
    is_cnt = 1'b0;

    always @(*) begin

        case(opcode)
            `ADD_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_ADD;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b1;
                imm = 32'b0;
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            `SUB_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_SUB;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b1;
                imm = 32'b0;
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            `AND_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_AND;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b1;
                imm = 32'b0;
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            `SLT_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_SLT;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b1;
                imm = 32'b0;
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            `SLTU_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_SLTU;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b1;
                imm = 32'b0;
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            `OR_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_OR;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b1;
                imm = 32'b0;
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            `XOR_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_XOR;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b1;
                imm = 32'b0;
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            `NOR_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_NOR;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b1;
                imm = 32'b0;
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            `SLL_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_SLL;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b1;
                imm = 32'b0;
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            `SRL_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_SRL;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b1;
                imm = 32'b0;
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            `SRA_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_SRA;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b1;
                imm = 32'b0;
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            `SLLI_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_SLLI;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b0;
                imm = {27'b0,ui5};
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            `SRLI_OPCODE:begin
                is_privilege = 1'b0;
                reg_write_en = 1'b1;
                aluop = `ALU_SRLI;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b0;
                imm = {27'b0,ui5};
                inst_valid = 1'b1;
                invtlb_op = 5'b0;
            end
            default: begin
                is_privilege = 1'b0;
                reg_write_en = 1'b0;
                aluop = `ALU_NOP;
                alusel = `ALU_SEL_NOP;
                reg1_read_en = 1'b0;
                reg2_read_en = 1'b0;
                imm = 32'b0;
                inst_valid = 1'b0;
                invtlb_op = 5'b0;
            end
        endcase
    end
endmodule