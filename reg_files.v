`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module reg_file(
    input  wire clk,
    input  wire [1:0]  reg1_read_en, 
    input  wire [1:0]  reg2_read_en, //寄存器读使能信号
    input  wire [4:0]  reg1_read_addr1,
    input  wire [4:0]  reg1_read_addr2, 
    input  wire [4:0]  reg2_read_addr1, //寄存器读地址
    input  wire [4:0]  reg2_read_addr2,
    input  wire [31:0] reg_write_data1, 
    input  wire [31:0] reg_write_data2,
    input  wire [4:0]  reg_write_addr1,
    input  wire [4:0]  reg_write_addr2,
    input  wire [1:0]  reg_write_en, //寄存器写使能信号

    output reg [31:0] reg1_read_data1 ,  //寄存器读数据
    output reg [31:0] reg1_read_data2 ,
    output reg [31:0] reg2_read_data1 ,   //寄存器读数据
    output reg [31:0] reg2_read_data2
);

reg [31:0] reg_file [31:0]; //寄存器文件

always @(posedge clk) begin
    // 写寄存器
    if (reg_write_en[0]) begin
        reg_file[reg_write_addr1] <= reg_write_data2;
    end
    if (reg_write_en[1]) begin
        reg_file[reg_write_addr1] <= reg_write_data2;
    end
end

always @(*) begin
    // 读寄存器
    if (reg1_read_en[0]) begin
        reg1_read_data1 = reg_file[reg1_read_addr1];
    end else begin
        reg1_read_data1 = 32'bz; // 如果没有使能，输出高阻态
    end

    if (reg1_read_en[1]) begin
        reg1_read_data2 = reg_file[reg1_read_addr2];
    end else begin
        reg1_read_data2 = 32'bz; // 如果没有使能，输出高阻态
    end

    if (reg2_read_en[0]) begin
        reg2_read_data1 = reg_file[reg2_read_addr1];
    end else begin
        reg2_read_data1 = 32'bz; // 如果没有使能，输出高阻态
    end

    if (reg2_read_en[1]) begin
        reg2_read_data2 = reg_file[reg2_read_addr2];
    end else begin
        reg2_read_data2 = 32'bz; // 如果没有使能，输出高阻态
    end
end

always @(*) begin
    // 初始化寄存器文件
        reg_file[0] = 32'b0; // 通常r0寄存器为0
end

endmodule