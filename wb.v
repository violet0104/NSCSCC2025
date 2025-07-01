`timescale 1ps/

module wb
(
    input wire clk,
    input wire rst,

   //   mem传入的信号
    input wire  [1:0]wb_reg_write_en, 
    input wire  [1:0][4:0] wb_reg_write_addr,
    input wire  [1:0][31:0] wb_reg_write_data,
    input wire  [1:0]wb_csr_write_en, //CSR寄存器写使能
    input wire  [1:0][13:0] wb_csr_addr, //CSR寄存器地址
    input wire  [1:0][31:0] wb_csr_write_data,
    input wire  [1:0]wb_is_llw_scw, //是否是LLW/SCW指令

    input wire  [1:0] commit_valid, //指令是否有效
    input wire  [1:0][5:0]  commit_is_exception,
    input wire  [1:0][5:0][6:0] commit_exception_cause, //异常原因
    input wire  [1:0][31:0] commit_pc,
    input wire  [1:0][31:0] commit_addr, //内存地址
    input wire  [1:0] commit_idle, //是否是空闲指令
    input wire  [1:0] commit_ertn, //是否是异常返回指令
    input wire  [1:0] commit_is_privilege, //特权指令

    input wire pause_mem,

    output reg [1:0] wb_pf_reg_write_en, //输出的寄存器写使能
    output reg [1:0][4:0] wb_pf_reg_write_addr, //输出的寄存器写地址
    output reg [1:0][31:0] wb_pf_reg_write_data, 

    // to ctrl
    output reg  [1:0]ctrl_reg_write_en, 
    output reg  [1:0][4:0] ctrl_reg_write_addr,
    output reg  [1:0][31:0] ctrl_reg_write_data,

    output reg  [1:0]ctrl_csr_write_en, //CSR寄存器写使能
    output reg  [1:0][13:0] ctrl_csr_addr, //CSR寄存器地址
    output reg  [1:0][31:0] ctrl_csr_write_data,
    output reg  [1:0]ctrl_is_llw_scw, //是否是LLW/SCW指令

    output reg  [1:0] commit_valid_out, //指令是否有效
    output reg  [1:0][5:0]  commit_is_exception_out,
    output reg  [1:0][5:0][6:0] commit_exception_cause_out, //异常原因
    output reg  [1:0][31:0] commit_pc_out,
    output reg  [1:0][31:0] commit_addr_out, //内存地址
    output reg  [1:0] commit_idle_out, //是否是空闲指令
    output reg  [1:0] commit_ertn_out, //是否是异常返回指令
    output reg  [1:0] commit_is_privilege_out //特权指令

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
    output reg  [1:0] tlbfill_en, //TLB填充使能
    `endif 
);

    always @(posedge clk) begin
        if(rst || pause_mem) begin
            ctrl_reg_write_en[0] <= 1'b0;
            ctrl_reg_write_en[1] <= 1'b0;
            ctrl_reg_write_addr[0] <= 1'b0;
            ctrl_reg_write_addr[1] <= 1'b0; 
            ctrl_reg_write_data[0] <= 32'b0;
            ctrl_reg_write_data[1] <= 32'b0;
            ctrl_csr_write_en[0] <= 1'b0;
            ctrl_csr_write_en[1] <= 1'b0; 
            ctrl_csr_addr[0] <= 14'b0;
            ctrl_csr_addr[1] <= 14'b0;
            ctrl_csr_write_data[0] <= 32'b0;
            ctrl_csr_write_data[1] <= 32'b0;
            ctrl_is_llw_scw[0] <= 1'b0;
            ctrl_is_llw_scw[1] <= 1'b0;
            commit_valid_out[0] <= 1'b0;
            commit_valid_out[1] <= 1'b0;
            commit_is_exception_out[0] <= 1'b0;
            commit_is_exception_out[1] <= 1'b0;
            commit_exception_cause_out[0] <= 6'b0;
            commit_exception_cause_out[1] <= 6'b0;
            commit_pc_out[0] <= 32'b0;
            commit_pc_out[1] <= 32'b0;
            commit_addr_out[0] <= 32'b0;
            commit_addr_out[1] <= 32'b0;
            commit_idle_out[0] <= 1'b0;
            commit_idle_out[1] <= 1'b0;
            commit_ertn_out[0] <= 1'b0;
            commit_ertn_out[1] <= 1'b0;
            commit_is_privilege_out[0] <= 1'b0;
            commit_is_privilege_out[1] <= 1'b0;
        end 
        else begin
            ctrl_reg_write_en[0] <= wb_reg_write_en[0];
            ctrl_reg_write_en[1] <= wb_reg_write_en[1];
            ctrl_reg_write_addr[0] <= wb_reg_write_addr[0];
            ctrl_reg_write_addr[1] <= wb_reg_write_addr[1]; 
            ctrl_reg_write_data[0] <= wb_reg_write_data[0];
            ctrl_reg_write_data[1] <= wb_reg_write_data[1];
            ctrl_csr_write_en[0] <= wb_csr_write_en[0];
            ctrl_csr_write_en[1] <= wb_csr_write_en[1]; 
            ctrl_csr_addr[0] <= wb_csr_addr[0];
            ctrl_csr_addr[1] <= wb_csr_addr[1];
            ctrl_csr_write_data[0] <= wb_csr_write_data[0];
            ctrl_csr_write_data[1] <= wb_csr_write_data[1];
            ctrl_is_llw_scw[0] <= wb_is_llw_scw[0];
            ctrl_is_llw_scw[1] <= wb_is_llw_scw[1];
            commit_valid_out[0] <= commit_valid[0];
            commit_valid_out[1] <= commit_valid[1];
            commit_is_exception_out[0] <= commit_is_exception[0];
            commit_is_exception_out[1] <= commit_is_exception[1];
            commit_exception_cause_out[0] <= commit_exception_cause[0];
            commit_exception_cause_out[1] <= commit_exception_cause[1];
            commit_pc_out[0] <= commit_pc[0];
            commit_pc_out[1] <= commit_pc[1];
            commit_addr_out[0] <= commit_addr[0];
            commit_addr_out[1] <= commit_addr[1];
            commit_idle_out[0] <= commit_idle[0];
            commit_idle_out[1] <= commit_idle[1];
            commit_ertn_out[0] <= commit_ertn[0];
            commit_ertn_out[1] <= commit_ertn[1];
            commit_is_privilege_out[0] <= commit_is_privilege[0];
            commit_is_privilege_out[1] <= commit_is_privilege[1];
        end
                    