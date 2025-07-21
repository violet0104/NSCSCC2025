`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module wb
(
    input wire clk,
    input wire rst,

   //   mem传入的信号
    input wire  [1:0]wb_reg_write_en, 
    input wire  [4:0] wb_reg_write_addr1,
    input wire  [4:0] wb_reg_write_addr2,
    input wire  [31:0] wb_reg_write_data1,
    input wire  [31:0] wb_reg_write_data2,
    input wire  [1:0]wb_csr_write_en, //CSR寄存器写使能
    input wire  [13:0] wb_csr_addr1, //CSR寄存器地址
    input wire  [13:0] wb_csr_addr2,
    input wire  [31:0] wb_csr_write_data1,
    input wire  [31:0] wb_csr_write_data2,
    input wire  [1:0]wb_is_llw_scw, //是否是LLW/SCW指令

    input wire  [1:0] commit_valid, //指令是否有效
    input wire  [5:0]  is_exception1_i,
    input wire  [5:0]  is_exception2_i,
    input wire  [6:0]  pc_exception_cause1_i,
    input wire  [6:0]  pc_exception_cause2_i, 
    input wire  [6:0]  instbuffer_exception_cause1_i,
    input wire  [6:0]  instbuffer_exception_cause2_i,
    input wire  [6:0]  decoder_exception_cause1_i,
    input wire  [6:0]  decoder_exception_cause2_i,
    input wire  [6:0]  dispatch_exception_cause1_i,
    input wire  [6:0]  dispatch_exception_cause2_i,
    input wire  [6:0]  execute_exception_cause1_i,
    input wire  [6:0]  execute_exception_cause2_i,
    input wire  [6:0]  commit_exception_cause1_i,
    input wire  [6:0]  commit_exception_cause2_i,


    input wire  [31:0] commit_pc1,
    input wire  [31:0] commit_pc2,
    input wire  [31:0] commit_addr1, //内存地址
    input wire  [31:0] commit_addr2,
    input wire  [1:0]  commit_idle, //是否是空闲指令
    input wire  [1:0]  commit_ertn, //是否是异常返回指令
    input wire  [1:0]  commit_is_privilege, //特权指令

    input wire pause_mem,

    output reg [1:0]  wb_pf_reg_write_en, //输出的寄存器写使能
    output reg [4:0]  wb_pf_reg_write_addr1, //输出的寄存器写地址
    output reg [4:0]  wb_pf_reg_write_addr2,
    output reg [31:0] wb_pf_reg_write_data1,
    output reg [31:0] wb_pf_reg_write_data2, 

    // to ctrl
    output reg  [1:0]  ctrl_reg_write_en, 
    output reg  [4:0]  ctrl_reg_write_addr1,
    output reg  [4:0]  ctrl_reg_write_addr2,
    output reg  [31:0] ctrl_reg_write_data1,
    output reg  [31:0] ctrl_reg_write_data2,

    output reg  [1:0]ctrl_csr_write_en, //CSR寄存器写使能
    output reg  [13:0] ctrl_csr_addr1, //CSR寄存器地址
    output reg  [13:0] ctrl_csr_addr2,
    output reg  [31:0] ctrl_csr_write_data1,
    output reg  [31:0] ctrl_csr_write_data2,
    output reg  [1:0]  ctrl_is_llw_scw, //是否是LLW/SCW指令

    output reg  [1:0]  commit_valid_out, //指令是否有效
    output reg  [5:0]  is_exception1_o,
    output reg  [5:0]  is_exception2_o,
    output reg  [6:0]  pc_exception_cause1_o, //异常原因
    output reg  [6:0]  pc_exception_cause2_o,
    output reg  [6:0]  instbuffer_exception_cause1_o,
    output reg  [6:0]  instbuffer_exception_cause2_o,
    output reg  [6:0]  decoder_exception_cause1_o,
    output reg  [6:0]  decoder_exception_cause2_o,
    output reg  [6:0]  dispatch_exception_cause1_o,
    output reg  [6:0]  dispatch_exception_cause2_o,
    output reg  [6:0]  execute_exception_cause1_o,
    output reg  [6:0]  execute_exception_cause2_o,
    output reg  [6:0]  commit_exception_cause1_o,
    output reg  [6:0]  commit_exception_cause2_o,

    output reg  [31:0] commit_pc_out1,
    output reg  [31:0] commit_pc_out2,
    output reg  [31:0] commit_addr_out1, //内存地址
    output reg  [31:0] commit_addr_out2,
    output reg  [1:0] commit_idle_out, //是否是空闲指令
    output reg  [1:0] commit_ertn_out, //是否是异常返回指令
    output reg  [1:0] commit_is_privilege_out, //特权指令
/**********************************************************************8
   `ifdef DIFF
    input reg  [1:0][31:0] in_debug_wb_pc, // debug信息：写回阶段的PC
    input reg  [1:0][31:0] in_debug_wb_inst, 
    input reg  [1:0][3:0] in_debug_wb_rf_we, 
    input reg  [1:0][4:0] in_debug_wb_rf_wnum, // debug信息：寄存器写地址
    input reg  [1:0][31:0] in_debug_wb_rf_wdata, // debug信息：寄存器写数据
    input reg  [1:0] in_inst_valid, // debug信息：指令是否有效
    input reg  [1:0] in_cnt_inst,
    input reg  [1:0] in_csr_rstat_en,
    input reg  [1:0][31:0] in_csr_data,
    input reg  [1:0]in_excp_flush,
    input reg  [1:0]in_ertn_flush,
    input reg  [1:0][5:0] in_ecode,
    input reg  [1:0][7:0] in_inst_st_en,
    input reg  [1:0][31:0] in_st_paddr, //存储器地址
    input reg  [1:0][31:0] in_st_vaddr, //虚拟地址
    input reg  [1:0][31:0] in_st_data, //存储器写数据
    input reg  [1:0][7:0] in_inst_ld_en, //加载指令使能
    input reg  [1:0][31:0] in_ld_paddr, //加载指令地址
    input reg  [1:0][31:0] in_ld_vaddr, //加载指令虚拟地址
    input reg  [1:0] in_tlbfill_en, //TLB填充使能
    // diff
    output reg  [1:0][31:0] debug_wb_pc, // debug信息：写回阶段的PC
    output reg  [1:0][31:0] debug_wb_inst, 
    output reg  [1:0][3:0] debug_wb_rf_we, 
    output reg  [1:0][4:0] debug_wb_rf_wnum, // debug信息：寄存器写地址
    output reg  [1:0][31:0] debug_wb_rf_wdata, // debug信息：寄存器写数据
    output reg  [1:0] inst_valid, // debug信息：指令是否有效
    output reg  [1:0] cnt_inst,
    output reg  [1:0] csr_rstat_en,
    output reg  [1:0][31:0] csr_data,
    output reg  [1:0]excp_flush,
    output reg  [1:0]ertn_flush,
    output reg  [1:0][5:0] ecode,
    output reg  [1:0][7:0] inst_st_en,
    output reg  [1:0][31:0] st_paddr, //存储器地址
    output reg  [1:0][31:0] st_vaddr, //虚拟地址
    output reg  [1:0][31:0] st_data, //存储器写数据
    output reg  [1:0][7:0] inst_ld_en, //加载指令使能
    output reg  [1:0][31:0] ld_paddr, //加载指令地址
    output reg  [1:0][31:0] ld_vaddr, //加载指令虚拟地址
    output reg  [1:0] tlbfill_en //TLB填充使能
    `endif 
**************************************************************************/
//debug
    input wire [31:0] mem_inst1,
    input wire [31:0] mem_inst2,
    
    output reg [31:0] wb_inst1,
    output reg [31:0] wb_inst2
);


    always @(posedge clk) begin
        if(rst || pause_mem) begin
            ctrl_reg_write_en[0] <= 1'b0;
            ctrl_reg_write_en[1] <= 1'b0;
            ctrl_reg_write_addr1 <= 1'b0;
            ctrl_reg_write_addr2 <= 1'b0; 
            ctrl_reg_write_data1 <= 32'b0;
            ctrl_reg_write_data2 <= 32'b0;
            ctrl_csr_write_en[0] <= 1'b0;
            ctrl_csr_write_en[1] <= 1'b0; 
            ctrl_csr_addr1 <= 14'b0;
            ctrl_csr_addr2 <= 14'b0;
            ctrl_csr_write_data1 <= 32'b0;
            ctrl_csr_write_data2 <= 32'b0;
            ctrl_is_llw_scw[0] <= 1'b0;
            ctrl_is_llw_scw[1] <= 1'b0;
            commit_valid_out[0] <= 1'b0;
            commit_valid_out[1] <= 1'b0;
            is_exception1_o <= 5'b0;
            is_exception2_o <= 5'b0;
            pc_exception_cause1_o <= 7'b0;
            pc_exception_cause2_o <= 7'b0;
            instbuffer_exception_cause1_o <= 7'b0;
            instbuffer_exception_cause2_o <= 7'b0;
            decoder_exception_cause1_o <= 7'b0;
            decoder_exception_cause2_o <= 7'b0;
            dispatch_exception_cause1_o <= 7'b0;
            dispatch_exception_cause2_o <= 7'b0;
            execute_exception_cause1_o <= 7'b0;
            execute_exception_cause2_o <= 7'b0;
            commit_exception_cause1_o <= 7'b0;
            commit_exception_cause2_o <= 7'b0;
            commit_pc_out1 <= 32'b0;
            commit_pc_out2 <= 32'b0;
            commit_addr_out1 <= 32'b0;
            commit_addr_out2 <= 32'b0;
            commit_idle_out[0] <= 1'b0;
            commit_idle_out[1] <= 1'b0;
            commit_ertn_out[0] <= 1'b0;
            commit_ertn_out[1] <= 1'b0;
            commit_is_privilege_out[0] <= 1'b0;
            commit_is_privilege_out[1] <= 1'b0;
        end 
        else begin
            wb_inst1 <= mem_inst1;
            wb_inst2 <= mem_inst2;
            ctrl_reg_write_en[0] <= wb_reg_write_en[0];
            ctrl_reg_write_en[1] <= wb_reg_write_en[1];
            ctrl_reg_write_addr1 <= wb_reg_write_addr1;
            ctrl_reg_write_addr2 <= wb_reg_write_addr2; 
            ctrl_reg_write_data1 <= wb_reg_write_data1;
            ctrl_reg_write_data2 <= wb_reg_write_data2;
            ctrl_csr_write_en[0] <= wb_csr_write_en[0];
            ctrl_csr_write_en[1] <= wb_csr_write_en[1]; 
            ctrl_csr_addr1 <= wb_csr_addr1;
            ctrl_csr_addr2 <= wb_csr_addr2;
            ctrl_csr_write_data1 <= wb_csr_write_data1;
            ctrl_csr_write_data2 <= wb_csr_write_data2;
            ctrl_is_llw_scw[0] <= wb_is_llw_scw[0];
            ctrl_is_llw_scw[1] <= wb_is_llw_scw[1];
            commit_valid_out[0] <= commit_valid[0];
            commit_valid_out[1] <= commit_valid[1];
            is_exception1_o <= is_exception1_i;
            is_exception2_o <= is_exception2_i;
            pc_exception_cause1_o <= pc_exception_cause1_i;
            pc_exception_cause2_o <= pc_exception_cause2_i;
            instbuffer_exception_cause1_o <= instbuffer_exception_cause1_i;
            instbuffer_exception_cause2_o <= instbuffer_exception_cause2_i;
            decoder_exception_cause1_o <= decoder_exception_cause1_i;
            decoder_exception_cause2_o <= decoder_exception_cause2_i;
            dispatch_exception_cause1_o <= dispatch_exception_cause1_i;
            dispatch_exception_cause2_o <= dispatch_exception_cause2_i;
            execute_exception_cause1_o <= execute_exception_cause1_i;
            execute_exception_cause2_o <= execute_exception_cause2_i;
            commit_exception_cause1_o <= commit_exception_cause1_i;
            commit_exception_cause2_o <= commit_exception_cause2_i;
            commit_pc_out1 <= commit_pc1;
            commit_pc_out2 <= commit_pc2;
            commit_addr_out1 <= commit_addr1;
            commit_addr_out2 <= commit_addr2;
            commit_idle_out[0] <= commit_idle[0];
            commit_idle_out[1] <= commit_idle[1];
            commit_ertn_out[0] <= commit_ertn[0];
            commit_ertn_out[1] <= commit_ertn[1];
            commit_is_privilege_out[0] <= commit_is_privilege[0];
            commit_is_privilege_out[1] <= commit_is_privilege[1];
        end
    end

    always @(*) begin
        wb_pf_reg_write_en[0] = ctrl_reg_write_en[0];
        wb_pf_reg_write_en[1] = ctrl_reg_write_en[1];
        wb_pf_reg_write_addr1 = ctrl_reg_write_addr1;
        wb_pf_reg_write_addr2 = ctrl_reg_write_addr2;
        wb_pf_reg_write_data1 = ctrl_reg_write_data1;
        wb_pf_reg_write_data2 = ctrl_reg_write_data2;
        end
/**********************************************************************
    `ifdef DIFF
    always @(posedge clk) begin
        if(rst || pause_mem) begin
            debug_wb_pc[0] <= 32'b0;
            debug_wb_pc[1] <= 32'b0;
            debug_wb_inst[0] <= 32'b0;
            debug_wb_inst[1] <= 32'b0;
            debug_wb_rf_we[0] <= 4'b0;
            debug_wb_rf_we[1] <= 4'b0;
            debug_wb_rf_wnum[0] <= 5'b0;
            debug_wb_rf_wnum[1] <= 5'b0;
            debug_wb_rf_wdata[0] <= 32'b0;
            debug_wb_rf_wdata[1] <= 32'b0;
            inst_valid[0] <= 1'b0;
            inst_valid[1] <= 1'b0;
            cnt_inst[0] <= 1'b0;
            cnt_inst[1] <= 1'b0;
            csr_rstat_en[0] <= 1'b0;
            csr_rstat_en[1] <= 1'b0;
            csr_data[0] <= 32'b0;
            csr_data[1] <= 32'b0;
            excp_flush[0] <= 1'b0;
            excp_flush[1] <= 1'b0;
            ertn_flush[0] <= 1'b0;
            ertn_flush[1] <= 1'b0;
            ecode[0] <= 6'b0;
            ecode[1] <= 6'b0;
            inst_st_en[0] <= 8'b0;
            inst_st_en[1] <= 8'b0;
            st_paddr[0] <= 32'b0; 
            st_paddr[1] <= 32'b0; 
            st_vaddr[0] <= 32'b0; 
            st_vaddr[1] <= 32'b0; 
            st_data[0] <= 32'b0; 
            st_data[1] <= 32'b0; 
            inst_ld_en[0] <= 8'b0; 
            inst_ld_en[1] <= 8'b0; 
            ld_paddr[0] <= 32'b0; 
            ld_paddr[1] <= 32'b0; 
            ld_vaddr[0] <= 32'b0;
            ld_vaddr[1] <= 32'b0; 
            tlbfill_en[0] <= 1'b0; 
            tlbfill_en[1] <= 1'b0; 
        end
        else begin
            debug_wb_pc[0] <= in_debug_wb_pc[0];
            debug_wb_pc[1] <= in_debug_wb_pc[1];
            debug_wb_inst[0] <= in_debug_wb_inst[0];
            debug_wb_inst[1] <= in_debug_wb_inst[1];
            debug_wb_rf_we[0] <= in_debug_wb_rf_we[0];
            debug_wb_rf_we[1] <= in_debug_wb_rf_we[1];
            debug_wb_rf_wnum[0] <= in_debug_wb_rf_wnum[0];
            debug_wb_rf_wnum[1] <= in_debug_wb_rf_wnum[1];
            debug_wb_rf_wdata[0] <= in_debug_wb_rf_wdata[0];
            debug_wb_rf_wdata[1] <= in_debug_wb_rf_wdata[1];
            inst_valid[0] <= in_inst_valid[0];
            inst_valid[1] <= in_inst_valid[1];
            cnt_inst[0] <= in_cnt_inst[0];
            cnt_inst[1] <= in_cnt_inst[1];
            csr_rstat_en[0] <= in_csr_rstat_en[0];
            csr_rstat_en[1] <= in_csr_rstat_en[1];
            csr_data[0] <= in_csr_data[0];
            csr_data[1] <= in_csr_data[1];
            excp_flush[0] <= in_excp_flush[0];
            excp_flush[1] <= in_excp_flush[1];
            ertn_flush[0] <= in_ertn_flush[0];
            ertn_flush[1] <= in_ertn_flush[1];
            ecode[0] <= in_ecode[0];
            ecode[1] <= in_ecode[1];
            inst_st_en[0] <= in_inst_st_en[0]; 
            inst_st_en[1] <= in_inst_st_en[1]; 
            st_paddr[0] <= in_st_paddr[0]; 
            st_paddr[1] <= in_st_paddr[1]; 
            st_vaddr[0] <= in_st_vaddr[0]; 
            st_vaddr[1] <= in_st_vaddr[1]; 
            st_data[0] <= in_st_data[0]; 
            st_data[1] <= in_st_data[1];
            inst_ld_en[0] <= in_inst_ld_en[0]; 
            inst_ld_en[1] <= in_inst_ld_en[1];
            ld_paddr[0] <= in_ld_paddr[0]; 
            ld_paddr[1] <= in_ld_paddr[1];
            ld_vaddr[0] <= in_ld_vaddr[0];
            ld_vaddr[1] <= in_ld_vaddr[1];
            tlbfill_en[0] <= in_tlbfill_en[0];
            tlbfill_en[1] <= in_tlbfill_en[1];
        end
    end
    `endif
*******************************************************************************/
endmodule