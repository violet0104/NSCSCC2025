`include   "defines.vh"
`timescale  1ns / 1ps

module decoder_2RI12
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
);
    reg [9:0] opcode;
    reg [4:0] rj;
    reg [4:0] rd;
    reg [11:0] ui12;
    reg [11:0] si12;

    assign opcode = inst[31:22];
    assign rj = inst[9:5];
    assign rd = inst[21:10];
    assign ui12 = inst[21:10];
    assign si12 = inst[21:10];
    assign pc_out = pc;
    assign inst_out = inst;
    assign reg_write_addr = rdl;

    always @(*) begin
        case(opcode)
            `ORI_OPCODE:begin
                reg_writen_en = 1'b1;
                aluop = `ALU_ORI;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b0;
                reg1_read_addr = rj;
                reg2_read_addr = 5'b0;
                imm = {20'b0,ui12};
                inst_valid = 1'b1;
            end
            `SLTI_OPCODE:begin
                reg_writen_en = 1'b1;
                aluop = `ALU_SLTI;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b0;
                reg1_read_addr = rj;
                reg2_read_addr = 5'b0;
                imm = {{20{si12[11]}},si12};
                inst_valid = 1'b1;
            end
            `SLTUI_OPCODE:begin
                reg_writen_en = 1'b1;
                aluop = `ALU_SLTUI;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b0;
                reg1_read_addr = rj;
                reg2_read_addr = 5'b0;
                imm = {{20{si12[11]}},si12};
                inst_valid = 1'b1;
            end
            `ADDI_OPCODE:begin
                reg_writen_en = 1'b1;
                aluop = `ALU_ADDIW;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b0;
                reg1_read_addr = rj;
                reg2_read_addr = 5'b0;
                imm = {{20{si12[11]}},si12};
                inst_valid = 1'b1;
            end
            `ANDI_OPCODE:begin
                reg_writen_en = 1'b1;
                aluop = `ALU_ADDI;
                alusel = `ALU_SEL_ARITHMETIC;
                reg1_read_en = 1'b1;
                reg2_read_en = 1'b0;
                reg1_read_addr = rj;
                reg2_read_addr = 5'b0;
                imm = {20'b0,ui12};
                inst_valid = 1'b1;
            end
            default:begin
                aluop = `ALU_NOP;
                alusel = `ALU_SEL_NOP;
                reg_writen_en = 1'b0;
                reg1_read_en  = 1'b0;
                reg2_read_en  = 1'b0;
                reg1_read_addr= 5'b0;
                reg2_read_addr= 5'b0;
                imm = 32'b0;
                inst_valid = 1'b0;
            end
        endcase
    end
endmodule