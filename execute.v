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
    input wire [31:0] pc1_i,
    input wire [31:0] pc2_i,
    input wire [31:0] inst1_i,
    input wire [31:0] inst2_i,
    input wire [1:0] valid_i,

    input wire [3:0] is_exception1_i,
    input wire [3:0] is_exception2_i,
    input wire [6:0] pc_exception_cause1_i,     
    input wire [6:0] pc_exception_cause2_i,      
    input wire [6:0] instbuffer_exception_cause1_i,
    input wire [6:0] instbuffer_exception_cause2_i,
    input wire [6:0] decoder_exception_cause1_i,
    input wire [6:0] decoder_exception_cause2_i,
    input wire [6:0] dispatch_exception_cause1_i,
    input wire [6:0] dispatch_exception_cause2_i,

    input wire [1:0] is_privilege_i,

    input wire [7:0] aluop1_i,
    input wire [7:0] aluop2_i,
    input wire [2:0] alusel1_i,
    input wire [2:0] alusel2_i,

    input wire [31:0] reg_data1_1_i,
    input wire [31:0] reg_data1_2_i,
    input wire [31:0] reg_data2_1_i,
    input wire [31:0] reg_data2_2_i,
    input wire [1:0] reg_write_en_i,           // 寄存器写使能
    input wire [4:0] reg_write_addr1_i,        // 寄存器写地址
    input wire [4:0] reg_write_addr2_i,        // 寄存器写地址

    input wire [31:0] csr_read_data1_i,     // csr读数据
    input wire [31:0] csr_read_data2_i,     // csr读数据
    input wire [1:0]  csr_write_en_i,       // csr写使能
    input wire [13:0] csr_addr1_i,          // csr地址
    input wire [13:0] csr_addr2_i,          // csr地址


    input wire [4:0] invtlb_op1_i,
    input wire [4:0] invtlb_op2_i,

    input wire [1:0] pre_is_branch_taken_i,       // 预测分支指令是否跳转
    input wire [31:0] pre_branch_addr1_i,         // 预测分支指令跳转地址
    input wire [31:0] pre_branch_addr2_i,         // 预测分支指令跳转地址
    
    // 来自mem的信号
    input wire pause_mem_i,

    // 和dcache的接口
    input wire dcache_pause_i,       // 写/读dache 暂停信号 （接dache的write_finish）          
      
    output wire [3:0]  ren_o,                // dcache读使能信号
    output wire [3:0]  wstrb_o,              // dcache写使能信号
    output wire [31:0] virtual_addr_o,      // dcache虚拟地址
    output wire [31:0] wdata_o,             // dcache写数据


    // 输出给前端的信号
    output wire [1:0]  ex_bpu_is_bj,
    output wire [31:0] ex_pc1,
    output wire [31:0] ex_pc2,
    output wire [1:0]  ex_bpu_taken_or_not_actual,
    output wire [31:0] ex_bpu_branch_actual_addr1,
    output wire [31:0] ex_bpu_branch_actual_addr2,
    output wire [31:0] ex_bpu_branch_pred_addr1,     // pred是不是不要了
    output wire [31:0] ex_bpu_branch_pred_addr2,

    // 前递给dispatch的数据
    output wire [7:0]  pre_ex_aluop1_o,
    output wire [7:0]  pre_ex_aluop2_o,
    output wire [1:0]  reg_write_en_o,
    output wire [31:0] reg_write_addr1_o,
    output wire [31:0] reg_write_addr2_o,
    output wire [31:0] reg_write_data1_o,
    output wire [31:0] reg_write_data2_o,
    
    // 输出给ctrl的数据
    output wire   pause_ex_o,
    output wire   branch_flush_o,
    output wire   ex_excp_flush_o,
    output wire [31:0] branch_target_o,

    // 输出给mem的数据
    output reg [1:0] valid_mem,

    output reg [31:0] pc1_mem,
    output reg [31:0] pc2_mem,
    output reg [31:0] inst1_mem,
    output reg [31:0] inst2_mem,

    output reg [4:0] is_exception1_o,      
    output reg [4:0] is_exception2_o, 

    output reg [6:0] pc_exception_cause1_o, 
    output reg [6:0] pc_exception_cause2_o,
    output reg [6:0] instbuffer_exception_cause1_o,
    output reg [6:0] instbuffer_exception_cause2_o,
    output reg [6:0] decoder_exception_cause1_o,
    output reg [6:0] decoder_exception_cause2_o,
    output reg [6:0] dispatch_exception_cause1_o,
    output reg [6:0] dispatch_exception_cause2_o,
    output reg [6:0] execute_exception_cause1_o,
    output reg [6:0] execute_exception_cause2_o,

    output reg [7:0] aluop1_mem,
    output reg [7:0] aluop2_mem,

    output reg [1:0]  reg_write_en_mem,
    output reg [4:0]  reg_write_addr1_mem,
    output reg [4:0]  reg_write_addr2_mem,
    output reg [31:0] reg_write_data1_mem, 
    output reg [31:0] reg_write_data2_mem,

    output reg [31:0] addr1_mem,
    output reg [31:0] addr2_mem,
    output reg [31:0] data1_mem,
    output reg [31:0] data2_mem,

    output reg [1:0]  csr_write_en_mem,
    output reg [13:0] csr_addr1_mem,
    output reg [13:0] csr_addr2_mem,
    output reg [31:0] csr_write_data1_mem,
    output reg [31:0] csr_write_data2_mem,

    output reg [1:0] is_privilege_mem,
    output reg [1:0] is_ertn_mem,
    output reg [1:0] is_idle_mem,
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

    wire [4:0] is_exception1;
    wire [4:0] is_exception2;
    wire [6:0] pc_exception_cause1;
    wire [6:0] pc_exception_cause2;
    wire [6:0] instbuffer_exception_cause1;
    wire [6:0] instbuffer_exception_cause2;
    wire [6:0] decoder_exception_cause1;
    wire [6:0] decoder_exception_cause2;
    wire [6:0] dispatch_exception_cause1;
    wire [6:0] dispatch_exception_cause2;
    wire [6:0] execute_exception_cause1;
    wire [6:0] execute_exception_cause2;

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

    assign ren_o = dcache_pause_i ? 4'h0 : 4'hf;
    assign wstrb_o = dcache_pause_i ? 4'h0  : (valid_o[0] ? wstrb[0] : wstrb[1]);
    assign virtual_addr_o = dcache_pause_i ? 32'h0 : (valid_o[0] ? virtual_addr[0]: virtual_addr[1]);
    assign wdata_o = dcache_pause_i ? 32'b0 : (valid_o[0] ? wdata[0] : wdata[1]);



    alu u_alu_1 (
        // 输入
        .clk(clk),
        .rst(rst),
        .flush(flush),

        // from dispatch
        .pc_i(pc1_i),
        .inst_i(inst1_i),

        .is_exception_i(is_exception1_i),
        .pc_exception_cause_i(pc_exception_cause1_i),
        .instbuffer_exception_cause_i(instbuffer_exception_cause1_i),
        .decoder_exception_cause_i(decoder_exception_cause1_i),
        .dispatch_exception_cause_i(dispatch_exception_cause1_i),

        .privilege_i(is_privilege_i[0]),
        .valid_i(valid_i[0]),

        .aluop_i(aluop1_i),
        .alusel_i(alusel1_i),

        .reg_data1_i(reg_data1_1_i),
        .reg_data2_i(reg_data1_2_i),
        .reg_write_en_i(reg_write_en_i[0]),
        .reg_write_addr_i(reg_write_addr1_i),

        .csr_read_data_i(csr_read_data1_i),
        .csr_write_en_i(csr_write_en_i[0]),
        .csr_addr_i(csr_addr1_i),

        .invtlb_op_i(invtlb_op1_i),

        .pre_is_branch_taken_i(pre_is_branch_taken_i[0]),
        .pre_branch_addr_i(pre_branch_addr1_i),

        // from stable counter
        .cnt_i(cnt_i),

        // 输出
        // with dache
        .valid_o(valid_o[0]),
        .virtual_addr_o(virtual_addr[0]),
        .wdata_o(wdata[0]),
        .wstrb_o(wstrb[0]),

        // to bpu
        .taken_or_not_actual_o(taken_or_not_actual_alu[0]),
        .branch_actual_addr_o(branch_actual_addr_alu[0]),
        .pc_dispatch_o(pc_dispatch_alu[0]),

        // to ctrl
        .pause_alu_o(pause_alu[0]),
        .branch_flush_alu_o(branch_flush_alu[0]),
        .branch_target_addr_alu_o(branch_target_addr_alu[0]),
        
        // to dispatch
        .pre_ex_aluop_o(pre_ex_aluop1_o),
        
        // to Cache
        .is_cacop_o(is_cacop_alu[0]),
        .cacop_code_o(cacop_code_alu[0]),
        .is_preld_o(is_preld_alu[0]),
        .hint_o(hint_alu[0]),
        .addr_o(addr_alu[0]),

        // to mem
        .pc_mem(pc[0]),
        .inst_mem(inst[0]),

        .is_exception_o(is_exception1),
        .pc_exception_cause_o(pc_exception_cause1),
        .instbuffer_exception_cause_o(instbuffer_exception_cause1),
        .decoder_exception_cause_o(decoder_exception_cause1),
        .dispatch_exception_cause_o(dispatch_exception_cause1),
        .execute_exception_cause_o(execute_exception_cause1),

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

    alu u_alu_2 (
        // 输入
        .clk(clk),
        .rst(rst),
        .flush(flush),

        // from dispatch
        .pc_i(pc2_i),
        .inst_i(inst2_i),

        .is_exception_i(is_exception2_i),
        .pc_exception_cause_i(pc_exception_cause2_i),
        .instbuffer_exception_cause_i(instbuffer_exception_cause2_i),
        .decoder_exception_cause_i(decoder_exception_cause2_i),
        .dispatch_exception_cause_i(dispatch_exception_cause2_i),
        
        .privilege_i(is_privilege_i[1]),
        .valid_i(valid_i[1]),

        .aluop_i(aluop2_i),
        .alusel_i(alusel2_i),

        .reg_data1_i(reg_data2_1_i),
        .reg_data2_i(reg_data2_2_i),
        .reg_write_en_i(reg_write_en_i[1]),
        .reg_write_addr_i(reg_write_addr2_i),

        .csr_read_data_i(csr_read_data2_i),
        .csr_write_en_i(csr_write_en_i[1]),
        .csr_addr_i(csr_addr2_i),

        .invtlb_op_i(invtlb_op2_i),

        .pre_is_branch_taken_i(pre_is_branch_taken_i[1]),
        .pre_branch_addr_i(pre_branch_addr2_i),

        // from stable counter
        .cnt_i(cnt_i),

        // 输出
        // with dache
        .valid_o(valid_o[1]),
        .virtual_addr_o(virtual_addr[1]),
        .wdata_o(wdata[1]),
        .wstrb_o(wstrb[1]),

        // to bpu
        .taken_or_not_actual_o(taken_or_not_actual_alu[1]),
        .branch_actual_addr_o(branch_actual_addr_alu[1]),
        .pc_dispatch_o(pc_dispatch_alu[1]),

        // to ctrl
        .pause_alu_o(pause_alu[1]),
        .branch_flush_alu_o(branch_flush_alu[1]),
        .branch_target_addr_alu_o(branch_target_addr_alu[1]),
        
        // to dispatch
        .pre_ex_aluop_o(pre_ex_aluop2_o),
        
        // to Cache
        .is_cacop_o(is_cacop_alu[1]),
        .cacop_code_o(cacop_code_alu[1]),
        .is_preld_o(is_preld_alu[1]),
        .hint_o(hint_alu[1]),
        .addr_o(addr_alu[1]),

        // to mem
        .pc_mem(pc[1]),
        .inst_mem(inst[1]),

        .is_exception_o(is_exception2),
        .pc_exception_cause_o(pc_exception_cause2),
        .instbuffer_exception_cause_o(instbuffer_exception_cause2),
        .decoder_exception_cause_o(decoder_exception_cause2),
        .dispatch_exception_cause_o(dispatch_exception_cause2),
        .execute_exception_cause_o(execute_exception_cause2),

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

    // 输出给前端的信号
    assign ex_bpu_is_bj[0] = alusel1_i == `ALU_SEL_JUMP_BRANCH;
    assign ex_bpu_is_bj[1] = alusel2_i == `ALU_SEL_JUMP_BRANCH;
    assign ex_pc1 = pc1_i;
    assign ex_pc2 = pc2_i;
    assign ex_bpu_taken_or_not_actual = taken_or_not_actual_alu;
    assign ex_bpu_branch_actual_addr1 = branch_actual_addr_alu[0];
    assign ex_bpu_branch_actual_addr2 = branch_actual_addr_alu[1];
    assign ex_bpu_branch_pred_addr1   = pre_branch_addr1_i;
    assign ex_bpu_branch_pred_addr2   = pre_branch_addr2_i;


    // 前递给 dispatch 的数据
    assign reg_write_en_o[0] = reg_write_en[0];
    assign reg_write_en_o[1] = reg_write_en[1];
    assign reg_write_addr1_o   = reg_write_addr[0];
    assign reg_write_addr2_o   = reg_write_addr[1];
    assign reg_write_data1_o   = reg_write_data[0];
    assign reg_write_data2_o   = reg_write_data[1];



    // 输出给 ctrl 的信息
    assign pause_ex_o = |pause_alu;
    assign branch_flush_o = |branch_flush_alu && !pause_ex_o && !pause_mem_i;

    assign branch_target_o = branch_flush_alu[0] ? branch_target_addr_alu[0] : branch_target_addr_alu[1];

/*********************************************************************
    always @(posedge clk) begin
        if (branch_flush_alu[0]) begin      
            update_en_o <= update_en_alu[0];
            taken_or_not_actual_o <= taken_or_not_actual_alu[0];
            branch_actual_addr_o <= branch_actual_addr_alu[0];
            pc_dispatch_o <= pc_dispatch_alu[0];
        end 
        else begin
            update_en_o <= update_en_alu[1];
            taken_or_not_actual_o <= taken_or_not_actual_alu[1];
            branch_actual_addr_o <= branch_actual_addr_alu[1];
            pc_dispatch_o <= pc_dispatch_alu[1];
        end
    end
*********************************************************************/

    assign ex_excp_flush_o = (is_exception[0] != 0 || is_exception[1] != 0 
                            || csr_write_en[0] || csr_write_en[1]
                            || aluop[0] == `ALU_ERTN || aluop[1] == `ALU_ERTN) 
                            && !pause_ex_o && !pause_mem_i;

    wire ex_mem_pause;
    assign ex_mem_pause = pause_ex_o && !pause_mem_i;

    // to mem
    always @(posedge clk) begin
        if (rst || ex_mem_pause || flush) begin
            pc1_mem <= 32'b0;
            pc2_mem <= 32'b0;
            inst1_mem <= 32'b0;
            inst2_mem <= 32'b0;
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
            reg_write_addr1_mem <= 5'b0;
            reg_write_addr2_mem <= 5'b0;
            reg_write_data1_mem <= 32'b0;
            reg_write_data2_mem <= 32'b0;
            aluop1_mem <= 8'b0;
            aluop2_mem <= 8'b0;
            addr1_mem  <= 32'b0;
            addr2_mem  <= 32'b0;
            data1_mem  <= 32'b0;
            data2_mem  <= 32'b0;
            csr_write_en_mem[0] <= 1'b0;
            csr_write_en_mem[1] <= 1'b0;
            csr_addr1_mem <= 14'b0;
            csr_addr2_mem <= 14'b0;
            csr_write_data1_mem <= 32'b0;
            csr_write_data2_mem <= 32'b0;
            is_llw_scw_mem[0] <= 1'b0;
            is_llw_scw_mem[1] <= 1'b0;
        end else if (!pause) begin
            if (branch_flush_alu[0]) begin
                pc1_mem <= pc[0];
                inst1_mem <= inst[0];
                is_exception1_o <= is_exception1;
                pc_exception_cause1_o<= pc_exception_cause1;
                instbuffer_exception_cause1_o <= instbuffer_exception_cause1;
                decoder_exception_cause1_o <= decoder_exception_cause1;
                dispatch_exception_cause1_o <= decoder_exception_cause1;
                execute_exception_cause1_o <= execute_exception_cause1;
                is_privilege_mem[0] <= is_privilege[0];
                is_ertn_mem[0] <= aluop[0] == `ALU_ERTN;
                is_idle_mem[0] <= aluop[0] == `ALU_IDLE;
                valid_mem[0] <= valid_o[0];
                reg_write_en_mem[0] <= reg_write_en[0];
                reg_write_addr1_mem <= reg_write_addr[0];
                reg_write_data1_mem <= reg_write_data[0];
                aluop1_mem <= aluop[0];
                addr1_mem <= addr[0];
                data1_mem <= data[0];
                csr_write_en_mem[0] <= csr_write_en[0];
                csr_addr1_mem <= csr_addr[0];
                csr_write_data1_mem <= csr_write_data[0];
                is_llw_scw_mem[0] <= is_llw_scw[0];

                pc1_mem <= 32'b0;
                inst1_mem <= 32'b0;
                is_exception2_o <= 5'b0;
                pc_exception_cause_o <= 7'b0;
                instbuffer_exception_cause2_o <= 7'b0;
                decoder_exception_cause2_o <= 7'b0;
                dispatch_exception_cause2_o <= 7'b0;
                execute_exception_cause2_o <= 7'b0;
                is_privilege_mem[1] <= 1'b0;
                is_ertn_mem[1] <= 1'b0;
                is_idle_mem[1] <= 1'b0;
                valid_mem[1] <= 1'b0;
                reg_write_en_mem[1] <= 1'b0;
                reg_write_addr1_mem <= 5'b0;
                reg_write_data1_mem <= 32'b0;
                aluop1_mem <= 8'b0;
                addr1_mem <= 32'b0;
                data1_mem <= 32'b0;
                csr_write_en_mem[1] <= 1'b0;
                csr_addr1_mem <= 14'b0;
                csr_write_data1_mem <= 32'b0;
                is_llw_scw_mem[1] <= 1'b0;
            end else begin
                pc1_mem <= pc[0];
                pc2_mem <= pc[1];
                inst1_mem <= inst[0];
                inst2_mem <= inst[1];
                is_exception1_o <= is_exception1;
                is_exception2_o <= is_exception2;
                pc_exception_cause_o <= pc_exception_cause1;
                pc_exception_cause2_o <= pc_exception_cause2;
                instbuffer_exception_cause1_o <= instbuffer_exception_cause1;
                instbuffer_exception_cause2_o <= instbuffer_exception_cause2;
                decoder_exception_cause1_o <= decoder_exception_cause1;
                decoder_exception_cause2_o <= decoder_exception_cause2;
                dispatch_exception_cause1_o <= dispatch_exception_cause1;
                dispatch_exception_cause2_o <= dispatch_exception_cause2;
                execute_exception_cause1_o <= execute_exception_cause1;
                execute_exception_cause2_o <= execute_exception_cause2;
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
                reg_write_addr1_mem <= reg_write_addr[0];
                reg_write_addr2_mem <= reg_write_addr[1];
                reg_write_data1_mem <= reg_write_data[0];
                reg_write_data2_mem <= reg_write_data[1];
                aluop1_mem <= aluop[0];
                aluop2_mem <= aluop[1];
                addr1_mem <= addr[0];
                addr2_mem <= addr[1];
                data1_mem <= data[0];
                data2_mem <= data[1];
                csr_write_en_mem[0] <= csr_write_en[0];
                csr_write_en_mem[1] <= csr_write_en[1];
                csr_addr1_mem <= csr_addr[0];
                csr_addr2_mem <= csr_addr[1];
                csr_write_data1_mem <= csr_write_data[0];
                csr_write_data2_mem <= csr_write_data[1];
                is_llw_scw_mem[0] <= is_llw_scw[0];
                is_llw_scw_mem[1] <= is_llw_scw[1];
            end
        end else begin
            pc1_mem <= pc1_mem;
            pc2_mem <= pc2_mem;
            inst1_mem <= inst1_mem;
            inst2_mem <= inst2_mem;
            is_exception1_o <= is_exception1_o;
            is_exception2_o <= is_exception2_o;
            pc_exception_cause1_o <= pc_exception_cause1_o;
            pc_exception_cause2_o <= pc_exception_cause2_o;
            instbuffer_exception_cause1_o <= instbuffer_exception_cause1_o;
            instbuffer_exception_cause2_o <= instbuffer_exception_cause2_o;
            decoder_exception_cause1_o <= decoder_exception_cause1_o;
            decoder_exception_cause2_o <= decoder_exception_cause2_o;
            dispatch_exception_cause1_o <= dispatch_exception_cause1_o;
            dispatch_exception_cause2_o <= dispatch_exception_cause2_o;
            execute_exception_cause1_o <= execute_exception_cause1_o;
            execute_exception_cause2_o <= execute_exception_cause2_o;
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
            reg_write_addr1_mem <= reg_write_addr1_mem;
            reg_write_addr2_mem <= reg_write_addr2_mem;
            reg_write_data1_mem <= reg_write_data1_mem;
            reg_write_data2_mem <= reg_write_data2_mem;
            aluop1_mem <= aluop1_mem;
            aluop2_mem <= aluop2_mem;
            addr1_mem <= addr1_mem;
            addr2_mem <= addr2_mem;
            data1_mem <= data1_mem;
            data2_mem <= data2_mem;
            csr_write_en_mem[0] <= csr_write_en_mem[0];
            csr_write_en_mem[1] <= csr_write_en_mem[1];
            csr_addr1_mem <= csr_addr1_mem;
            csr_addr2_mem <= csr_addr2_mem;
            csr_write_data1_mem <= csr_write_data1_mem;
            csr_write_data2_mem <= csr_write_data2_mem;
            is_llw_scw_mem[0] <= is_llw_scw_mem[0];
            is_llw_scw_mem[1] <= is_llw_scw_mem[1];
        end
    end
endmodule