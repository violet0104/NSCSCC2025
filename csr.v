`include "csr_defines.vh"
`timescale 1ns/1ps

module csr (
    input wire clk,
    input wire rst,

    // 和dispatch的接口
    input wire csr_read_data,              // csr读数据
    output wire csr_read_en,                // csr读使能信号
    output wire [13:0] csr_read_addr,       // csr读地址

    // 和tlb的接口
    output [31:0] tlbidx,
    

    // 来自wb的写端口
    input wire is_llw_scw,                 // 是否是llw/scw指令
    input wire csr_write_en,               // CSR写使能信号
    input wire [13:0] csr_write_addr,      // CSR写地址
    input wire [31:0] csr_write_data,      // CSR写数据

    input tlb_inst_se
);
endmodule