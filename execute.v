`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module execute (
    input wire clk,
    input wire rst,

    // 来自ctrl的信号
    input wire flush,
    input wire pause,

    // 来自stable counter的信号
    input wire [63:0] cnt_i,

    // 来自dispatch的数据
    input wire [1:0] [31:0] pc_i,
    input wire [1:0] [31:0] inst_i,
    input wire [1:0] valid_i,

    input wire [1:0] [3:0] is_exception_i,
    input wire [1:0] [3:0] [6:0] exception_cause_i,
    input wire [1:0] is_privilege_i,

    input wire [1:0] [7:0] aluop_i,
    input wire [1:0] [2:0] alusel_i,

    input wire [1:0] [31:0] reg_data0_i,
    input wire [1:0] [31:0] reg_data1_i,
    input wire [1:0] reg_write_en_i,                // 寄存器写使能
    input wire [1:0] [4:0] reg_write_addr_i,        // 寄存器写地址

    input wire [1:0] [31:0] csr_read_data_i,    // csr读数据
    input wire [1:0] csr_write_en_i,     // csr写使能
    input wire [1:0] [13:0] csr_addr_i,  // csr地址 

    input wire [1:0] [4:0] invtlb_op_i,

    input wire [1:0] pre_is_branch_taken_i,      // 预测分支指令是否跳转
    input wire [1:0] [31:0] pre_branch_addr_i,   // 预测分支指令跳转地址
    
    // 来自mem的信号
    input wire pause_mem_i,

    // 和dcache的接口
    input wire data_ok_i,            
    input wire [31:0] rdata_i,            // 读DCache的结果
    input wire [31:0] physical_addr_i,    // 物理地址
    
    output wire valid_dache_o,      
    output wire op_o,           // 0表示读，1表示写
    output wire [31:0] virtual_addr_o,
    output wire [3:0] wstrb_o,
    output wire [31:0] wdata_o,

    // 前递给bpu的数据
    output reg update_en_o,
    output reg taken_or_not_actual_o,
    output reg [31:0] branch_actual_addr_o,
    output reg [31:0] pc_dispatch_o,

    // 前递给dispatch的数据
    output wire [1:0] [7:0] pre_ex_aluop_o,
    output wire [1:0] reg_write_en_o,
    output wire [1:0] [31:0] reg_write_addr_o,
    output wire [1:0] [31:0] reg_write_data_o,
    
    // 输出给ctrl的数据
    output wire   pause_ex_o,
    output wire   branch_flush_o,
    output wire   ex_excp_flush_o,
    output wire [31:0] branch_target_o,

    // 输出给mem的数据
    output reg [1:0] [31:0] pc_mem,
    output reg [1:0] [31:0] inst_mem,
    output reg [1:0] is_exception_mem,
    output reg [1:0] [4:0] [6:0] exception_cause_mem,
    output reg [1:0] is_privilege_mem,
    output reg [1:0] is_ertn_mem,
    output reg [1:0] is_idle_mem,
    output reg [1:0] [1:0] valid_mem,

    output reg [1:0] reg_write_en_mem,
    output reg [1:0] [4:0] reg_write_addr_mem,
    output reg [1:0] [31:0] reg_write_data_mem, 

    output reg [1:0] [7:0] aluop_mem,

    output reg [1:0] [31:0] addr_mem,
    output reg [1:0] [31:0] data_mem,

    output reg [1:0] csr_write_en_mem,
    output reg [1:0] [13:0] csr_addr_mem,
    output reg [1:0] [31:0] csr_write_data_mem,

    output reg [1:0] is_llw_scw_mem
);
    wire [1:0] pause_alu;

    // 和分支预测器有关的信息
    wire [1:0] branch_flush_alu;
    wire [31:0] branch_target_addr_alu [1:0];

    wire [1:0] update_en_alu;
    wire [1:0] taken_or_not_actual_alu;
    wire [31:0] branch_actual_addr_alu [1:0];
    wire [31:0] pc_dispatch_alu [1:0];

    // 和cache有关的信息
    wire [1:0] is_cacop_alu;
    wire [4:0] cacop_code_alu [1:0];
    wire [1:0] is_preld_alu;
    wire [1:0] hint_alu;
    wire [31:0] addr_alu;

    wire [1:0] valid;
    wire [1:0] op;
    wire addr_ok;
    wire [31:0] virtual_addr [1:0];
    wire [31:0] wdata [1:0];
    wire [3:0] wstrb [1:0];

    // to mem
    wire [31:0] pc [1:0];
    wire [31:0] inst [1:0];
    wire [4:0] is_exception [1:0];
    wire [4:0] [6:0] exception_cause [1:0];
    wire [1:0] is_privilege;
    wire is_ert [1:0];
    wire is_idle [1:0];
    wire [1:0] valid_o;

    wire [1:0] reg_write_en;
    wire [4:0] reg_write_addr [1:0];
    wire [31:0] reg_write_data [1:0]; 

    wire [7:0] aluop [1:0];

    wire [31:0] addr [1:0];
    wire [31:0] data [1:0];

    wire [1:0] csr_write_en;
    wire [13:0] csr_addr [1:0];
    wire [31:0] csr_write_data [1:0];

    wire [1:0] is_llw_scw;

    assign valid_dache_o = |valid_o;
    assign op_o = valid_o[0] ? op[0] : op[1]; 
    assign virtual_addr_o = valid_o[0] ? virtual_addr[0] : virtual_addr[1];
    assign wdata_o = valid_o[0] ? wdata[0] : wdata[1];
    assign wstrb_o = valid_o[0] ? wstrb[0] : wstrb[1];


    alu u_alu_0 (
        .clk(clk),
        .rst(rst),
        .flush(flush),

        // from dispatch
        .pc_i(pc_i[0]),
        .inst_i(inst_i[0]),

        .is_exception_i(is_exception_i[0]),
        .exception_cause_i(exception_cause_i[0]),
        .privilege_i(is_privilege_i[0]),
        .valid_i(valid_i[0]),

        .aluop_i(aluop_i[0]),
        .alusel_i(alusel_i[0]),

        .reg_data_i(reg_data0_i),
        .reg_write_en_i(reg_write_en_i[0]),
        .reg_write_addr_i(reg_write_addr_i[0]),

        .csr_read_data_i(csr_read_data_i[0]),
        .csr_write_en_i(csr_write_en_i[0]),
        .csr_addr_i(csr_addr_i[0]),

        .invtlb_op_i(invtlb_op_i[0]),

        .pre_is_branch_taken_i(pre_is_branch_taken_i[0]),
        .pre_branch_addr_i(pre_branch_addr_i[0]),

        // from stable counter
        .cnt_i(cnt_i),

        // with dache
        .valid_o(valid_o[0]),
        .op_o(op[0]),
        .virtual_addr_o(virtual_addr[0]),
        .wdata_o(wdata[0]),
        .wstrb_o(wstrb[0]),

        // to bpu
        .update_en_o(update_en_alu[0]),
        .taken_or_not_actual_o(taken_or_not_actual_alu[0]),
        .branch_actual_addr_o(branch_actual_addr_alu[0]),
        .pc_dispatch_o(pc_dispatch_alu[0]),

        // to ctrl
        .pause_alu_o(pause_alu[0]),
        .branch_flush_alu_o(branch_flush_alu[0]),
        .branch_target_addr_alu_o(branch_target_addr_alu[0]),
        
        // to dispatch
        .pre_ex_aluop_o(pre_ex_aluop_o[0]),
        
        // to Cache
        .is_cacop_o(is_cacop_alu[0]),
        .cacop_code_o(cacop_code_alu[0]),
        .is_preld_o(is_preld_alu[0]),
        .hint_o(hint_alu[0]),
        .addr_o(addr_alu[0]),

        // to mem
        .pc_mem(pc[0]),
        .inst_mem(inst[0]),
        .is_exception_mem(is_exception[0]),
        .exception_cause_mem(exception_cause[0]),
        .is_privilege_mem(is_privilege[0]),
        .is_ertn_mem(is_ert[0]),
        .is_idle_mem(is_idle[0]),
        .valid_mem(valid_o[0]),
        .reg_write_en_mem(reg_write_en[0]),
        .reg_write_addr_mem(reg_write_addr[0]),
        .reg_write_data_mem(reg_write_data[0]),
        .aluop_mem(aluop[0]),
        .addr_mem(addr[0]),
        .data_mem(data[0]),
        .csr_write_en_mem(csr_write_en[0]),
        .csr_addr_mem(csr_addr[0]),
        .csr_write_data_mem(csr_write_data[0]),
        .is_llw_scw_mem(is_llw_scw[0])
);

    alu u_alu_1 (
        .clk(clk),
        .rst(rst),
        .flush(flush),

        // from dispatch
        .pc_i(pc_i[1]),
        .inst_i(inst_i[1]),

        .is_exception_i(is_exception_i[1]),
        .exception_cause_i(exception_cause_i[1]),
        .privilege_i(is_privilege_i[1]),
        .valid_i(valid_i[1]),

        .aluop_i(aluop_i[1]),
        .alusel_i(alusel_i[1]),

        .reg_data_i(reg_data1_i),
        .reg_write_en_i(reg_write_en_i[1]),
        .reg_write_addr_i(reg_write_addr_i[1]),

        .csr_read_data_i(csr_read_data_i[1]),
        .csr_write_en_i(csr_write_en_i[1]),
        .csr_addr_i(csr_addr_i[1]),

        .invtlb_op_i(invtlb_op_i[1]),

        .pre_is_branch_taken_i(pre_is_branch_taken_i[1]),
        .pre_branch_addr_i(pre_branch_addr_i[1]),

        // from stable counter
        .cnt_i(cnt_i),

        // with dache
        .valid_o(valid_o[1]),
        .op_o(op[1]),
        .virtual_addr_o(virtual_addr[1]),
        .wdata_o(wdata[1]),
        .wstrb_o(wstrb[1]),

        // to bpu
        .update_en_o(update_en_alu[1]),
        .taken_or_not_actual_o(taken_or_not_actual_alu[1]),
        .branch_actual_addr_o(branch_actual_addr_alu[1]),
        .pc_dispatch_o(pc_dispatch_alu[1]),

        // to ctrl
        .pause_alu_o(pause_alu[1]),
        .branch_flush_alu_o(branch_flush_alu[1]),
        .branch_target_addr_alu_o(branch_target_addr_alu[1]),
        
        // to dispatch
        .pre_ex_aluop_o(pre_ex_aluop_o[1]),
        
        // to Cache
        .is_cacop_o(is_cacop_alu[1]),
        .cacop_code_o(cacop_code_alu[1]),
        .is_preld_o(is_preld_alu[1]),
        .hint_o(hint_alu[1]),
        .addr_o(addr_alu[1]),

        // to mem
        .pc_mem(pc[1]),
        .inst_mem(inst[1]),
        .is_exception_mem(is_exception[1]),
        .exception_cause_mem(exception_cause[1]),
        .is_privilege_mem(is_privilege[1]),
        .is_ertn_mem(is_ert[1]),
        .is_idle_mem(is_idle[1]),
        .valid_mem(valid_o[1]),
        .reg_write_en_mem(reg_write_en[1]),
        .reg_write_addr_mem(reg_write_addr[1]),
        .reg_write_data_mem(reg_write_data[1]),
        .aluop_mem(aluop[1]),
        .addr_mem(addr[1]),
        .data_mem(data[1]),
        .csr_write_en_mem(csr_write_en[1]),
        .csr_addr_mem(csr_addr[1]),
        .csr_write_data_mem(csr_write_data[1]),
        .is_llw_scw_mem(is_llw_scw[1])
);

    // 前递给 dispatch 的数据
    assign reg_write_en_o[0] = reg_write_en[0];
    assign reg_write_en_o[1] = reg_write_en[1];
    assign reg_write_addr[0] = reg_write_addr[0];
    assign reg_write_addr[1] = reg_write_addr[1];
    assign reg_write_data[0] = reg_write_data[0];
    assign reg_write_data[1] = reg_write_data[1];

    // 输出给 ctrl 的信息
    assign pause_ex_o = |pause_alu;
    assign branch_flush_o = |branch_flush_alu && !pause_ex_o && !pause_mem_i;

    assign branch_target_o = branch_flush_alu[0] ? branch_target_addr_alu[0] : branch_target_addr_alu[1];

    always @(posedge clk) begin
        if (branch_flush_alu[0]) begin
            update_en_o = update_en_alu[0];
            taken_or_not_actual_o = taken_or_not_actual_alu[0];
            branch_actual_addr_o = branch_actual_addr_alu[0];
            pc_dispatch_o = pc_dispatch_alu[0];
        end 
        else begin
            update_en_o = update_en_alu[1];
            taken_or_not_actual_o = taken_or_not_actual_alu[1];
            branch_actual_addr_o = branch_actual_addr_alu[1];
            pc_dispatch_o = pc_dispatch_alu[1];
        end
    end

    assign ex_excp_flush_o = (is_exception[0] != 0 || is_exception[1] != 0 
                            || csr_write_en[0] || csr_write_en[1]
                            || aluop[0] == `ALU_ERTN || aluop[1] == `ALU_ERTN) 
                            && !pause_ex_o && !pause_mem_i;

    wire ex_mem_pause;
    assign ex_mem_pause = pause_ex_o && !pause_mem_i;

    // to mem
    always @(posedge clk) begin
        if (rst || ex_mem_pause || flush) begin
            pc_mem[0] <= 32'b0;
            pc_mem[1] <= 32'b0;
            inst_mem[0] <= 32'b0;
            inst_mem[1] <= 32'b0;
            is_exception_mem[0] <= 5'b0;
            is_exception_mem[1] <= 5'b0;
            exception_cause_mem[0] <= 7'b0;
            exception_cause_mem[1] <= 7'b0;
            is_privilege_mem[0] <= 1'b0;
            is_privilege_mem[1] <= 1'b0;
            is_ertn_mem[0] <= 1'b0;
            is_ertn_mem[1] <= 1'b0;
            is_idle_mem[0] <= 1'b0;
            is_idle_mem[1] <= 1'b0;
            valid_mem[0] <= 1'b0;
            valid_mem[1] <= 1'b0;
            reg_write_en_mem[0] <= 1'b0;
            reg_write_en_mem[1] <= 1'b0;
            reg_write_addr_mem[0] <= 5'b0;
            reg_write_addr_mem[1] <= 5'b0;
            reg_write_data_mem[0] <= 32'b0;
            reg_write_data_mem[1] <= 32'b0;
            aluop_mem[0] <= 8'b0;
            aluop_mem[1] <= 8'b0;
            addr_mem[0] <= 32'b0;
            addr_mem[1] <= 32'b0;
            data_mem[0] <= 32'b0;
            data_mem[1] <= 32'b0;
            csr_write_en_mem[0] <= 1'b0;
            csr_write_en_mem[1] <= 1'b0;
            csr_addr_mem[0] <= 14'b0;
            csr_addr_mem[1] <= 14'b0;
            csr_write_data_mem[0] <= 32'b0;
            csr_write_data_mem[1] <= 32'b0;
            is_llw_scw_mem[0] <= 1'b0;
            is_llw_scw_mem[1] <= 1'b0;
        end else if (!pause) begin
            if (branch_flush_alu[0]) begin
                pc_mem[0] <= pc[0];
                inst_mem[0] <= inst[0];
                is_exception_mem[0] <= is_exception[0];
                exception_cause_mem[0] <= exception_cause[0];
                is_privilege_mem[0] <= is_privilege[0];
                is_ertn_mem[0] <= aluop[0] == `ALU_ERTN;
                is_idle_mem[0] <= aluop[0] == `ALU_IDLE;
                valid_mem[0] <= valid_o[0];
                reg_write_en_mem[0] <= reg_write_en[0];
                reg_write_addr_mem[0] <= reg_write_addr[0];
                reg_write_data_mem[0] <= reg_write_data[0];
                aluop_mem[0] <= aluop[0];
                addr_mem[0] <= addr[0];
                data_mem[0] <= data[0];
                csr_write_en_mem[0] <= csr_write_en[0];
                csr_addr_mem[0] <= csr_addr[0];
                csr_write_data_mem[0] <= csr_write_data[0];
                is_llw_scw_mem[0] <= is_llw_scw[0];

                pc_mem[1] <= 32'b0;
                inst_mem[1] <= 32'b0;
                is_exception_mem[1] <= 5'b0;
                is_exception_mem[1] <= 5'b0;
                exception_cause_mem[1] <= 7'b0;
                is_privilege_mem[1] <= 1'b0;
                is_ertn_mem[1] <= 1'b0;
                is_idle_mem[1] <= 1'b0;
                valid_mem[1] <= 1'b0;
                reg_write_en_mem[1] <= 1'b0;
                reg_write_addr_mem[1] <= 5'b0;
                reg_write_data_mem[1] <= 32'b0;
                aluop_mem[1] <= 8'b0;
                addr_mem[1] <= 32'b0;
                data_mem[1] <= 32'b0;
                csr_write_en_mem[1] <= 1'b0;
                csr_addr_mem[1] <= 14'b0;
                csr_write_data_mem[1] <= 32'b0;
                is_llw_scw_mem[1] <= 1'b0;
            end else begin
                pc_mem[0] <= pc[0];
                pc_mem[1] <= pc[1];
                inst_mem[0] <= inst[0];
                inst_mem[1] <= inst[1];
                is_exception_mem[0] <= is_exception[0];
                is_exception_mem[1] <= is_exception[1];
                exception_cause_mem[0] <= exception_cause[0];
                exception_cause_mem[1] <= exception_cause[1];
                is_privilege_mem[0] <= is_privilege[0];
                is_privilege_mem[1] <= is_privilege[1];
                is_ertn_mem[0] <= aluop[0] == `ALU_ERTN;
                is_ertn_mem[1] <= aluop[1] == `ALU_ERTN;
                is_idle_mem[0] <= aluop[0] == `ALU_IDLE;
                is_idle_mem[1] <= aluop[1] == `ALU_IDLE;
                valid_mem[0] <= valid_o[0];
                valid_mem[1] <= valid_o[1];
                reg_write_en_mem[0] <= reg_write_en[0];
                reg_write_en_mem[1] <= reg_write_en[1];
                reg_write_addr_mem[0] <= reg_write_addr[0];
                reg_write_addr_mem[1] <= reg_write_addr[1];
                reg_write_data_mem[0] <= reg_write_data[0];
                reg_write_data_mem[1] <= reg_write_data[1];
                aluop_mem[0] <= aluop[0];
                aluop_mem[1] <= aluop[1];
                addr_mem[0] <= addr[0];
                addr_mem[1] <= addr[1];
                data_mem[0] <= data[0];
                data_mem[1] <= data[1];
                csr_write_en_mem[0] <= csr_write_en[0];
                csr_write_en_mem[1] <= csr_write_en[1];
                csr_addr_mem[0] <= csr_addr[0];
                csr_addr_mem[1] <= csr_addr[1];
                csr_write_data_mem[0] <= csr_write_data[0];
                csr_write_data_mem[1] <= csr_write_data[1];
                is_llw_scw_mem[0] <= is_llw_scw[0];
                is_llw_scw_mem[1] <= is_llw_scw[1];
            end
        end else begin
            pc_mem[0] <= pc_mem[0];
            pc_mem[1] <= pc_mem[1];
            inst_mem[0] <= inst_mem[0];
            inst_mem[1] <= inst_mem[1];
            is_exception_mem[0] <= is_exception_mem[0];
            is_exception_mem[1] <= is_exception_mem[1];
            exception_cause_mem[0] <= exception_cause_mem[0];
            exception_cause_mem[1] <= exception_cause_mem[1];
            is_privilege_mem[0] <= is_privilege_mem[0];
            is_privilege_mem[1] <= is_privilege_mem[1];
            is_ertn_mem[0] <= is_ertn_mem[0];
            is_ertn_mem[1] <= is_ertn_mem[1];
            is_idle_mem[0] <= is_idle_mem[0];
            is_idle_mem[1] <= is_idle_mem[1];
            valid_mem[0] <= valid_mem[0];
            valid_mem[1] <= valid_mem[1];
            reg_write_en_mem[0] <= reg_write_en_mem[0];
            reg_write_en_mem[1] <= reg_write_en_mem[1];
            reg_write_addr_mem[0] <= reg_write_addr_mem[0];
            reg_write_addr_mem[1] <= reg_write_addr_mem[1];
            reg_write_data_mem[0] <= reg_write_data_mem[0];
            reg_write_data_mem[1] <= reg_write_data_mem[1];
            aluop_mem[0] <= aluop_mem[0];
            aluop_mem[1] <= aluop_mem[1];
            addr_mem[0] <= addr_mem[0];
            addr_mem[1] <= addr_mem[1];
            data_mem[0] <= data_mem[0];
            data_mem[1] <= data_mem[1];
            csr_write_en_mem[0] <= csr_write_en_mem[0];
            csr_write_en_mem[1] <= csr_write_en_mem[1];
            csr_addr_mem[0] <= csr_addr_mem[0];
            csr_addr_mem[1] <= csr_addr_mem[1];
            csr_write_data_mem[0] <= csr_write_data_mem[0];
            csr_write_data_mem[1] <= csr_write_data_mem[1];
            is_llw_scw_mem[0] <= is_llw_scw_mem[0];
            is_llw_scw_mem[1] <= is_llw_scw_mem[1];
        end
    end
endmodule