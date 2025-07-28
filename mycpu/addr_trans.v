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
    input wire [2:0]  csr_plv,  

    output reg [31:0]  ret_data_paddr
);
    wire pg_mode;
    wire da_mode;

    wire data_dmw0_en,data_dmw1_en;
    assign data_dmw0_en = ((csr_dmw0[0] & csr_plv == 2'd0) | (csr_dmw0[3] & csr_plv == 2'd3)) & (data_vaddr[31:29] == csr_dmw0[31:29]) & pg_mode;
    assign data_dmw1_en = ((csr_dmw1[0] & csr_plv == 2'd0) | (csr_dmw1[3] & csr_plv == 2'd3)) & (data_vaddr[31:29] == csr_dmw1[31:29]) & pg_mode;

    wire [31:0] data_paddr;//转换出的物理地址


    assign pg_mode = !csr_da && csr_pg;
    assign pg_mode = csr_da && !csr_pg;   


    assign data_paddr = (pg_mode & data_dmw0_en ) ? {csr_dmw0[27:25],data_vaddr[28:0]} : 
                    (pg_mode & data_dmw1_en) ? {csr_dmw1[27:25],data_vaddr[28:0]} : data_vaddr;

    always @( posedge clk) 
    begin
        if(rst) ret_data_paddr <= 0;
        else ret_data_paddr <= data_paddr;
    end


endmodule