`include "csr_defines.vh"
`timescale 1ns/1ps

module csr (
    input wire clk,
    input wire rst,

    // 和dispatch的接口
    input wire csr_read_data,               // csr读数据
    output wire csr_read_en,                // csr读使能信号
    output wire [13:0] csr_read_addr,       // csr读地址

    // 和tlb的接口
    output wire [31:0] tlbidx,           // tlb索引寄存器
    output wire [31:0] tlbehi,           // tlb高项寄存器
    output wire [31:0] tlbelo0,          // tlb低项寄存器0
    output wire [31:0] tlbelo1,          // tlb低项寄存器1
    output wire [9:0]  asid,             // tlb的asid寄存器
    output wire [5:0] ecode,

    output wire [31:0] csr_dmw0,    
    output wire [31:0] csr_dmw1,       
    output wire csr_da,
    output wire csr_pg,
    output wire [1:0] csr_plv,
    output wire [1:0] csr_datf,
    output wire [1:0] csr_datm,  

    // 来自wb的写端口
    input wire is_llw_scw,                 // 是否是llw/scw指令
    input wire csr_write_en,               // CSR写使能信号
    input wire [13:0] csr_write_addr,      // CSR写地址
    input wire [31:0] csr_write_data,      // CSR写数据

    input wire search_tlb_found;
    input wire [4:0] search_tlb_index;
    input wire tlbrd_valid; 
    input wire [31:0] tlbehi_out;
    input wire [31:0] tlbelo0_out;
    input wire [31:0] tlbelo1_out;
    input wire [31:0] tlbidx_out;
    input wire [9:0]  asid_out;
    input wire tlbsrch_ret;
    input wire tlbrd_ret;

    // 来自外设的信号
    input wire is_ipi,
    input wire [7:0] is_hwi,

    // 和 ctrl 的接口
    input wire is_exception,
    input wire [31:0] exception_pc,
    input wire [31:0] exception_addr,
    input wire [5:0] ecode,
    input wire [8:0] esubcode,
    input wire [6:0] exception_cause,
    input wire is_tlb_exception,
    input wire is_ertn,
    input wire is_inst_tlb_exception,

    output wire [31:0] eentry,
    output wire [31:0] era,
    output wire [31:0] crmd,
    output wire [31:0] tlbrentry,
    output wire is_interrupt,


    // diff
`ifdef DIFF
    output wire [31:0] csr_crmd_diff,
    output wire [31:0] csr_prmd_diff,
    output wire [31:0] csr_ectl_diff,
    output wire [31:0] csr_estat_diff,
    output wire [31:0] csr_era_diff,
    output wire [31:0] csr_badv_diff,
    output wire [31:0] csr_eentry_diff,
    output wire [31:0] csr_tlbidx_diff,
    output wire [31:0] csr_tlbehi_diff,
    output wire [31:0] csr_tlbelo0_diff,
    output wire [31:0] csr_tlbelo1_diff,
    output wire [31:0] csr_asid_diff,
    output wire [31:0] csr_save0_diff,
    output wire [31:0] csr_save1_diff,
    output wire [31:0] csr_save2_diff,
    output wire [31:0] csr_save3_diff,
    output wire [31:0] csr_tid_diff,
    output wire [31:0] csr_tcfg_diff,
    output wire [31:0] csr_tval_diff,
    output wire [31:0] csr_ticlr_diff,
    output wire [31:0] csr_llbctl_diff,
    output wire [31:0] csr_tlbrentry_diff,
    output wire [31:0] csr_dmw0_diff,
    output wire [31:0] csr_dmw1_diff,
    output wire [31:0] csr_pgdl_diff,
    output wire [31:0] csr_pgdh_diff
`endif

);
endmodule