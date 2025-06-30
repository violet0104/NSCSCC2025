`include "csr_defines.vh"
`timescale 1ns/1ps

module csr (
    input wire clk,
    input wire rst,

    // 和dispatch的接口 （dispatch_csr）
    input wire dispatch_slave;      // ?? 位宽是多少

    // 和tlb的接口 （crs_tlb）
    input wire tlb_master   

    // 来自wb的写端口
    input wire is_llw_scw,                 // 是否是llw/scw指令
    input wire csr_write_en,               // CSR写使能信号
    input wire [13:0] csr_write_addr,      // CSR写地址
    input wire [31:0] csr_write_data,      // CSR写数据

    input tlb_inst_se
);
endmodule