`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module addr_trans
(
    input wire        clk,
    input wire        rst,

    input wire [31:0] data_vaddr,           //数据虚拟地址

    input wire        csr_da,
    input wire        csr_pg,       
    input wire [31:0] csr_dmw0,
    input wire [31:0] csr_dmw1,
    input wire [1:0]  csr_plv,  

    output wire [31:0]  ret_data_paddr,
    output wire uncache_en
);
    wire pg_mode;
    wire da_mode;

    wire data_dmw0_en,data_dmw1_en;
    assign data_dmw0_en = ((csr_dmw0[0] & csr_plv == 2'd0) | (csr_dmw0[3] & csr_plv == 2'd3)) & (data_vaddr[31:29] == csr_dmw0[31:29]) & pg_mode;
    assign data_dmw1_en = ((csr_dmw1[0] & csr_plv == 2'd0) | (csr_dmw1[3] & csr_plv == 2'd3)) & (data_vaddr[31:29] == csr_dmw1[31:29]) & pg_mode;

    assign pg_mode = !csr_da && csr_pg;
    assign da_mode = csr_da && !csr_pg;   

    assign uncache_en = (data_dmw0_en && (csr_dmw0[5:4] == 2'b0))||(data_dmw1_en && (csr_dmw1[5:4] == 2'b0))||(data_vaddr[31:16] == 16'hbfaf);

    assign ret_data_paddr = (pg_mode & data_dmw0_en ) ? {csr_dmw0[27:25],data_vaddr[28:0]} : 
                    (pg_mode & data_dmw1_en) ? {csr_dmw1[27:25],data_vaddr[28:0]} : data_vaddr;


endmodule