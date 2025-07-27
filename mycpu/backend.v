`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module backend (
    input wire clk,
    input wire rst,

    // from outer
    input wire [7:0] is_hwi,


    // 来自前端的信号
    input wire [31:0] pc_i1,
    input wire [31:0] pc_i2,
    input wire [31:0] inst_i1,
    input wire [31:0] inst_i2,
    input wire [1:0] valid_i,                           // 前端传递的数据有效信号
    input wire [1:0] pre_is_branch_taken_i,             // 前端传递的分支预测结果
    input wire [31:0] pre_branch_addr_i1,          // 前端传递的分支预测目标地址
    input wire [31:0] pre_branch_addr_i2,

    input wire [1:0] is_exception1_i,              // 前端传递的异常标志
    input wire [1:0] is_exception2_i,
    input wire [6:0] pc_exception_cause1_i,     // 异常原因
    input wire [6:0] pc_exception_cause2_i,
    input wire [6:0] instbuffer_exception_cause1_i,
    input wire [6:0] instbuffer_exception_cause2_i,

    input wire bpu_flush,      // 分支预测错误，清空译码队列（这个没用到？？）


/*****************************
    这个我们没有
    // to pc
    output logic   is_interrupt,
    */
    output [31:0] new_pc,
    


      // 输出给前端的信号
    output wire [1:0]  ex_bpu_is_bj,     // 两条指令是否是跳转指令
    output wire [31:0] ex_pc1,            // ex 阶段的 pc 
    output wire [31:0] ex_pc2,
    output wire [1:0]  ex_valid,
    output wire [1:0]  ex_bpu_taken_or_not_actual,       // 两条指令实际是否跳转
    output wire  [31:0] ex_bpu_branch_actual_addr1,  //  两条指令实际跳转地址
    output wire  [31:0] ex_bpu_branch_actual_addr2,
    output wire  [31:0] ex_bpu_branch_pred_addr1,    // 两条指令预测跳转地址
    output wire  [31:0] ex_bpu_branch_pred_addr2,
    output wire get_data_req_o,     // 输出给前端的取指请求
    // 和tlb的接口
    output wire [31:0] tlbidx,           // tlb索引寄存器
    output wire [31:0] tlbehi,           // tlb高项寄存器
    output wire [31:0] tlbelo0,          // tlb低项寄存器0
    output wire [31:0] tlbelo1,          // tlb低项寄存器1
    output wire [9:0]  asid,             //tlb的asid寄存器
    output wire [5:0] ecode,

    output wire [31:0] csr_dmw0,    
    output wire [31:0] csr_dmw1,       
    output wire csr_da,
    output wire csr_pg,
    output wire [1:0] csr_plv,
    output wire [1:0] csr_datf,
    output wire [1:0] csr_datm,  

    // dcache 返回的信号
    input wire [31:0] rdata_i,
    input wire rdata_valid_i,               // Dcache 输出的数据有效信号
    input wire dcache_pause_i,              // 接Dcache的write_finish，如果未完成写操作，就暂停后续的写操作，直到写完）
    // input wire [31:0] physical_addr_i,          //这个不知道接Dcahce的哪个信号
    
    // 输出给dcache的信号
    output wire ren_o,
    output wire [3:0] wstrb_o,
    output wire [31:0] virtual_addr_o,
    output wire [31:0] wdata_o,

    // 从 ctrl 输出的信号
    output wire [7:0] flush_o,
    output wire [7:0] pause_o ,

/**************************************
    `ifdef DIFF
    
    // debug
    output bus64_t cnt,
    output diff_t [1:0] diff,

    output bus32_t regs_diff[0:31],

    output logic [31:0] csr_crmd_diff,
    output logic [31:0] csr_prmd_diff,
    output logic [31:0] csr_ectl_diff,
    output logic [31:0] csr_estat_diff,
    output logic [31:0] csr_era_diff,
    output logic [31:0] csr_badv_diff,
    output logic [31:0] csr_eentry_diff,
    output logic [31:0] csr_tlbidx_diff,
    output logic [31:0] csr_tlbehi_diff,
    output logic [31:0] csr_tlbelo0_diff,
    output logic [31:0] csr_tlbelo1_diff,
    output logic [31:0] csr_asid_diff,
    output logic [31:0] csr_save0_diff,
    output logic [31:0] csr_save1_diff,
    output logic [31:0] csr_save2_diff,
    output logic [31:0] csr_save3_diff,
    output logic [31:0] csr_tid_diff,
    output logic [31:0] csr_tcfg_diff,
    output logic [31:0] csr_tval_diff,
    output logic [31:0] csr_ticlr_diff,
    output logic [31:0] csr_llbctl_diff,
    output logic [31:0] csr_tlbrentry_diff,
    output logic [31:0] csr_dmw0_diff,
    output logic [31:0] csr_dmw1_diff,
    output logic [31:0] csr_pgdl_diff,
    output logic [31:0] csr_pgdh_diff
    `endif
****************************************/
//debug
    output wire debug_wb_valid1,
    output wire debug_wb_valid2,
    output wire debug_wb_we1,
    output wire debug_wb_we2,
    output wire [31:0] debug_pc1,
    output wire [31:0] debug_pc2,
    output wire [31:0] debug_inst1,
    output wire [31:0] debug_inst2,
    output wire [4:0] debug_reg_addr1,
    output wire [4:0] debug_reg_addr2,
    output wire [31:0] debug_wdata1,
    output wire [31:0] debug_wdata2
);

    /*************************

    assign pause_request.pause_buffer = pause_buffer;
    assign pause_decoder = pause_request.pause_decoder;

    **************************/

    assign ex_valid = valid_dispatch;

    wire [63:0] cnt;


    // reg_files
    wire [31:0] reg_read_data1_1; //寄存器读数据
    wire [31:0] reg_read_data1_2;
    wire [31:0] reg_read_data2_1;
    wire [31:0] reg_read_data2_2;

    wire [1:0] reg_write_en;            // 寄存器写使能
    wire [4:0] reg_write_addr1;
    wire [4:0] reg_write_addr2;
    wire [31:0] reg_write_data1;
    wire [31:0] reg_write_data2;

    // csr
    wire [1:0] csr_read_en;             // csr 读使能
    wire  csr_write_en;            // csr写使能
    wire [13:0] csr_read_addr1;
    wire [13:0] csr_read_addr2;
    wire [13:0] csr_write_addr ;        // csr 写地址
    wire [31:0] csr_read_data1;
    wire [31:0] csr_read_data2;
    wire [31:0] csr_write_data ;        // csr 写数据
    wire is_llw_scw_ctrl;               // 是否是 llw/scw 指令
    // csr to ctrl
    wire [31:0] csr_eentry;         //异常入口地址
    wire [31:0] csr_era;            //异常返回地址
    wire [31:0] csr_crmd;           //控制寄存器 
    wire [31:0] csr_tlbrentry;
    wire csr_is_interrupt;


    // ctrl
    wire pause_buffer;
    wire pause_decoder;
    wire pause_dispatch;
    wire pause_execute;
    wire pause_mem;
    wire branch_flush;
    wire [31:0] branch_addr;
    wire ex_excep_flush;            // 执行阶段异常的 flush 信号

    wire csr_is_exception; //是否是异常
    wire [6:0]  csr_exception_cause; //异常原因
    wire [31:0] csr_exception_pc; //异常PC地址
    wire [31:0] csr_exception_addr; //异常地址
    wire [5:0]  csr_ecode; //异常ecode
    wire [8:0] csr_esubcode; //异常子码
    wire csr_is_ertn;
    wire csr_is_tlb_exception;
    wire csr_is_inst_tlb_exception;


    // decoder
    wire [31:0] pc_decoder1;
    wire [31:0] pc_decoder2;
    wire [31:0] inst_decoder1;
    wire [31:0] inst_decoder2;
    wire [2:0]  is_exception_decoder1;
    wire [2:0]  is_exception_decoder2;
    wire [6:0] pc_exception_cause_decoder1 ;
    wire [6:0] pc_exception_cause_decoder2 ;
    wire [6:0] instbuffer_exception_cause_decoder1;
    wire [6:0] instbuffer_exception_cause_decoder2;
    wire [6:0] decoder_exception_cause_decoder1;
    wire [6:0] decoder_exception_cause_decoder2;
    wire [1:0] is_privilege_decoder;
    wire [1:0] is_cnt_decoder;
    wire [1:0] valid_decoder;
    wire [7:0] aluop_decoder1;
    wire [7:0] aluop_decoder2;
    wire [2:0] alusel_decoder1;
    wire [2:0] alusel_decoder2;
    wire [31:0] imm_decoder1;
    wire [31:0] imm_decoder2;
    wire [4:0] invtlb_op_decoder1;
    wire [4:0] invtlb_op_decoder2;
    wire [1:0] reg_read_en_decoder1;
    wire [1:0] reg_read_en_decoder2;
    wire [1:0] reg_write_en_decoder;
    wire [4:0] reg_read_addr_decoder1_1;
    wire [4:0] reg_read_addr_decoder1_2;
    wire [4:0] reg_read_addr_decoder2_1;
    wire [4:0] reg_read_addr_decoder2_2;
    wire [4:0] reg_write_addr_decoder1;
    wire [4:0] reg_write_addr_decoder2;
    wire [1:0] csr_read_en_decoder;
    wire [1:0] csr_write_en_decoder;
    wire [13:0] csr_addr_decoder1;
    wire [13:0] csr_addr_decoder2;
    wire [1:0] pre_is_branch_taken_decoder;
    wire [31:0] pre_branch_addr_decoder1;
    wire [31:0] pre_branch_addr_decoder2;


    // dispatch
    wire [1:0] reg_write_en_ex_pf;
    wire [4:0] reg_write_addr_ex_pf1;
    wire [4:0] reg_write_addr_ex_pf2;
    wire [31:0] reg_write_data_ex_pf1;
    wire [31:0] reg_write_data_ex_pf2;
    wire [1:0] reg_write_en_mem_pf;
    wire [4:0] reg_write_addr_mem_pf1;
    wire [4:0] reg_write_addr_mem_pf2;
    wire [31:0] reg_write_data_mem_pf1;
    wire [31:0] reg_write_data_mem_pf2;
    wire [1:0] reg_write_en_wb_pf;
    wire [4:0] reg_write_addr_wb_pf1;
    wire [4:0] reg_write_addr_wb_pf2;
    wire [31:0] reg_write_data_wb_pf1;
    wire [31:0] reg_write_data_wb_pf2;
    wire [7:0] pre_ex_aluop1;
    wire [7:0] pre_ex_aluop2;
    wire [31:0] pc_dispatch1;
    wire [31:0] pc_dispatch2;
    wire [31:0] inst_dispatch1;
    wire [31:0] inst_dispatch2;
    wire [1:0] valid_dispatch;
    wire [3:0]  is_exception_dispatch1;
    wire [3:0]  is_exception_dispatch2;
    wire [6:0] pc_exception_cause_dispatch1 ;
    wire [6:0] pc_exception_cause_dispatch2 ;
    wire [6:0] instbuffer_exception_cause_dispatch1;
    wire [6:0] instbuffer_exception_cause_dispatch2;
    wire [6:0] decoder_exception_cause_dispatch1;
    wire [6:0] decoder_exception_cause_dispatch2;
    wire [6:0] dispatch_exception_cause_dispatch1;
    wire [6:0] dispatch_exception_cause_dispatch2;
    wire [1:0] is_privilege_dispatch;
    wire [7:0] aluop_dispatch1;
    wire [7:0] aluop_dispatch2;
    wire [2:0] alusel_dispatch1;
    wire [2:0] alusel_dispatch2;
    wire [31:0] reg_data_dispatch1_1;
    wire [31:0] reg_data_dispatch1_2;
    wire [31:0] reg_data_dispatch2_1;
    wire [31:0] reg_data_dispatch2_2;
    wire [1:0] reg_write_en_dispatch;                // 寄存器写使能
    wire [4:0] reg_write_addr_dispatch1;
    wire [4:0] reg_write_addr_dispatch2;
    wire [31:0] csr_read_data_dispatch1;
    wire [31:0] csr_read_data_dispatch2;
    wire [1:0] csr_write_en_dispatch;              // csr写使能
    wire [13:0] csr_addr_dispatch1;
    wire [13:0] csr_addr_dispatch2;
    wire [4:0] invtlb_op_dispatch1;
    wire [4:0] invtlb_op_dispatch2;
    wire [1:0] pre_is_branch_taken_dispatch;     // 预测分支指令是否跳转
    wire [31:0] pre_branch_addr_dispatch1;
    wire [31:0] pre_branch_addr_dispatch2;
    wire [1:0] invalid_en_dispatch;


    // execute
    wire [31:0] pc_execute1;
    wire [31:0] pc_execute2;
    wire [31:0] inst_execute1;
    wire [31:0] inst_execute2;
    wire [4:0]  is_exception_execute1;
    wire [4:0]  is_exception_execute2;
    wire [6:0] pc_exception_cause_execute1 ;
    wire [6:0] pc_exception_cause_execute2 ;
    wire [6:0] instbuffer_exception_cause_execute1;
    wire [6:0] instbuffer_exception_cause_execute2;
    wire [6:0] decoder_exception_cause_execute1;
    wire [6:0] decoder_exception_cause_execute2;
    wire [6:0] dispatch_exception_cause_execute1;
    wire [6:0] dispatch_exception_cause_execute2;
    wire [6:0] execute_exception_cause_execute1;
    wire [6:0] execute_exception_cause_execute2;
    wire [1:0] is_privilege_execute;
    wire [1:0] is_ertn_execute;
    wire [1:0] is_idle_execute;
    wire [1:0] valid_execute;
    wire [1:0] reg_write_en_execute;
    wire [4:0] reg_write_addr_execute1;
    wire [4:0] reg_write_addr_execute2;
    wire [31:0] reg_write_data_execute1;
    wire [31:0] reg_write_data_execute2;
    wire [7:0] aluop_execute1;
    wire [7:0] aluop_execute2;
    wire [31:0] addr_execute1;
    wire [31:0] addr_execute2;
    wire [31:0] data_execute1;
    wire [31:0] data_execute2;
    wire [1:0] csr_write_en_execute;
    wire [13:0] csr_addr_execute1;
    wire [13:0] csr_addr_execute2;
    wire [31:0] csr_write_data_execute1;
    wire [31:0] csr_write_data_execute2;
    wire [1:0] is_llw_scw_execute;  


    // mem
    wire [31:0] pc_mem1;
    wire [31:0] pc_mem2;
    wire [5:0]  is_exception_mem1;
    wire [5:0]  is_exception_mem2;
    wire [6:0] pc_exception_cause_mem1 ;
    wire [6:0] pc_exception_cause_mem2 ;
    wire [6:0] instbuffer_exception_cause_mem1;
    wire [6:0] instbuffer_exception_cause_mem2;
    wire [6:0] decoder_exception_cause_mem1;
    wire [6:0] decoder_exception_cause_mem2;
    wire [6:0] dispatch_exception_cause_mem1;
    wire [6:0] dispatch_exception_cause_mem2;
    wire [6:0] execute_exception_cause_mem1;
    wire [6:0] execute_exception_cause_mem2;
    wire [6:0] commit_exception_cause_mem1;
    wire [6:0] commit_exception_cause_mem2;
    wire [1:0] is_privilege_mem;
    wire [1:0] is_ertn_mem;
    wire [1:0] is_idle_mem;
    wire [1:0] valid_mem;
    wire [1:0] reg_write_en_mem;
    wire [4:0] reg_write_addr_mem1;
    wire [4:0] reg_write_addr_mem2;
    wire [31:0] reg_write_data_mem1;
    wire [31:0] reg_write_data_mem2;
    wire [1:0] csr_write_en_mem;
    wire [13:0] csr_write_addr_mem1;
    wire [13:0] csr_write_addr_mem2;
    wire [31:0] csr_write_data_mem1;
    wire [13:0] csr_write_data_mem2;
    wire [1:0] is_llw_scw_mem;
    wire [31:0] addr_mem1;
    wire [31:0] addr_mem2;


    // wb
    wire [31:0] pc_wb1;
    wire [31:0] pc_wb2;
    wire [5:0]  is_exception_wb1;
    wire [5:0]  is_exception_wb2;
    wire [6:0] pc_exception_cause_wb1 ;
    wire [6:0] pc_exception_cause_wb2 ;
    wire [6:0] instbuffer_exception_cause_wb1;
    wire [6:0] instbuffer_exception_cause_wb2;
    wire [6:0] decoder_exception_cause_wb1;
    wire [6:0] decoder_exception_cause_wb2;
    wire [6:0] dispatch_exception_cause_wb1;
    wire [6:0] dispatch_exception_cause_wb2;
    wire [6:0] execute_exception_cause_wb1;
    wire [6:0] execute_exception_cause_wb2;
    wire [6:0] commit_exception_cause_wb1;
    wire [6:0] commit_exception_cause_wb2;
    wire [1:0] is_privilege_wb;
    wire [1:0] is_ertn_wb;
    wire [1:0] is_idle_wb;
    wire [1:0] valid_wb;
    wire [1:0] reg_write_en_wb;
    wire [4:0] reg_write_addr_wb1;
    wire [4:0] reg_write_addr_wb2;
    wire [31:0] reg_write_data_wb1;
    wire [31:0] reg_write_data_wb2;
    wire [1:0] csr_write_en_wb;
    wire [13:0] csr_write_addr_wb1;
    wire [13:0] csr_write_addr_wb2;
    wire [31:0] csr_write_data_wb1;
    wire [31:0] csr_write_data_wb2;
    wire [1:0] is_llw_scw_wb;
    wire [31:0] addr_wb [1:0];
    wire [31:0] addr_wb1;
    wire [31:0] addr_wb2;


    // stable counter
    wire [63:0] stable_counter;

/******************************************
    `ifdef DIFF
    // diff
    diff_t [ISSUE_WIDTH - 1:0] wb_diff_i;
    diff_t [ISSUE_WIDTH - 1:0] wb_diff_o;
    assign cnt = stable_cnt;
    `endif
*******************************************/

    decoder u_decoder (
        .clk(clk),
        .rst(rst),
        .flush(flush_o[3]),

        .pc1(pc_i1),
        .pc2(pc_i2),
        .inst1(inst_i1),
        .inst2(inst_i2),
        .valid(valid_i),        
        .pretaken(pre_is_branch_taken_i),
        .pre_addr_in1(pre_branch_addr_i1) ,
        .pre_addr_in2(pre_branch_addr_i2) ,
        .is_exception_in1(is_exception1_i) ,
        .is_exception_in2(is_exception2_i) ,
        .pc_exception_cause_in1(pc_exception_cause1_i) ,
        .pc_exception_cause_in2(pc_exception_cause2_i) ,
        .instbuffer_exception_cause_in1(instbuffer_exception_cause1_i) ,
        .instbuffer_exception_cause_in2(instbuffer_exception_cause2_i) ,
        .invalid_en(invalid_en_dispatch),

        .get_data_req(get_data_req_o),
        .dispatch_id_valid(valid_decoder),
        .dispatch_pc_out1(pc_decoder1) ,
        .dispatch_pc_out2(pc_decoder2) ,
        .is_exception_o1(is_exception_decoder1) ,
        .is_exception_o2(is_exception_decoder2) ,
        .pc_exception_cause_o1(pc_exception_cause_decoder1) ,
        .pc_exception_cause_o2(pc_exception_cause_decoder2) ,
        .instbuffer_exception_cause_o1(instbuffer_exception_cause_decoder1) ,
        .instbuffer_exception_cause_o2(instbuffer_exception_cause_decoder2) ,
        .decoder_exception_cause_o1(decoder_exception_cause_decoder1) ,
        .decoder_exception_cause_o2(decoder_exception_cause_decoder2) ,
        .dispatch_inst_out1(inst_decoder1) ,
        .dispatch_inst_out2(inst_decoder2) ,
        .dispatch_aluop1(aluop_decoder1) ,
        .dispatch_aluop2(aluop_decoder2),
        .dispatch_alusel1(alusel_decoder1) ,
        .dispatch_alusel2(alusel_decoder2),
        .dispatch_imm1(imm_decoder1) ,
        .dispatch_imm2(imm_decoder2),
        .dispatch_reg_read_en1(reg_read_en_decoder1),  
        .dispatch_reg_read_en2(reg_read_en_decoder2),   
        .dispatch_reg_read_addr1_1(reg_read_addr_decoder1_1) ,
        .dispatch_reg_read_addr1_2(reg_read_addr_decoder1_2),
        .dispatch_reg_read_addr2_1(reg_read_addr_decoder2_1) ,
        .dispatch_reg_read_addr2_2(reg_read_addr_decoder2_2),
        .dispatch_reg_writen_en(reg_write_en_decoder),  
        .dispatch_reg_write_addr1(reg_write_addr_decoder1) ,
        .dispatch_reg_write_addr2(reg_write_addr_decoder2),
        .dispatch_id_pre_taken(pre_is_branch_taken_decoder),
        .dispatch_id_pre_addr1(pre_branch_addr_decoder1),
        .dispatch_id_pre_addr2(pre_branch_addr_decoder2),
        .dispatch_is_privilege(is_privilege_decoder), 
        .dispatch_csr_read_en(csr_read_en_decoder), 
        .dispatch_csr_write_en(csr_write_en_decoder),
        .dispatch_csr_addr1(csr_addr_decoder1),
        .dispatch_csr_addr2(csr_addr_decoder2), 
        .dispatch_is_cnt(is_cnt_decoder), 
        .dispatch_invtlb_op1(invtlb_op_decoder1),
        .dispatch_invtlb_op2(invtlb_op_decoder2),
        .pause_decoder(pause_decoder)

    );

    wire pause_to_dispatch = pause_o[4];
    wire pause_to_dispatch_ex_pause = pause_o[5];
    wire flush_to_dispatch = flush_o[4];

    dispatch u_dispatch (
        .clk(clk),
        .rst(rst),

    //控制单元的暂停和刷新信号
        .pause(pause_to_dispatch),//pause_o[4]    //发射器暂停信号,当发生load-use冒险时需要暂停  
        .flush(flush_to_dispatch),//flush_o[4]    //发射器刷新信号,当发生分支预测错误时需要刷新

    // 来自decoder的信号
        .pc1_i(pc_decoder1),      //指令地址
        .pc2_i(pc_decoder2),

        .inst1_i(inst_decoder1),    //指令编码
        .inst2_i(inst_decoder2),
        .valid_i(valid_decoder),   //指令有效标志

        .is_exception_i1(is_exception_decoder1), //两条指令的异常标志
        .is_exception_i2(is_exception_decoder2),
        .pc_exception_cause_i1(pc_exception_cause_decoder1), //两条指令的异常原因,会变长
        .pc_exception_cause_i2(pc_exception_cause_decoder2),
        .instbuffer_exception_cause_i1(instbuffer_exception_cause_decoder1), //两条指令的异常原因,会变长
        .instbuffer_exception_cause_i2(instbuffer_exception_cause_decoder2),
        .decoder_exception_cause_i1(decoder_exception_cause_decoder1), //两条指令的异常原因,会变长
        .decoder_exception_cause_i2(decoder_exception_cause_decoder2),

        .is_privilege_i(is_privilege_decoder), //两条指令的特权指令标志
        .is_cnt_i(is_cnt_decoder),       //两条指令的计数器指令标志

        .alu_op_i1(aluop_decoder1),  //ALU操作码
        .alu_op_i2(aluop_decoder2),
        .alu_sel_i1(alusel_decoder1), //ALU功能选择
        .alu_sel_i2(alusel_decoder2),
        .imm_i1(imm_decoder1),     //立即数值
        .imm_i2(imm_decoder2),

        .invtlb_op_i1(invtlb_op_decoder1),   //两条指令的分支指令标志
        .invtlb_op_i2(invtlb_op_decoder2),
        
        .reg_read_en_i1(reg_read_en_decoder1),     //第0条指令的两个源寄存器源寄存器读使能
        .reg_read_en_i2(reg_read_en_decoder2),     //第1条指令的两个源寄存器源寄存器读使能   
        .reg_read_addr_i1_1(reg_read_addr_decoder1_1),  
        .reg_read_addr_i1_2(reg_read_addr_decoder1_2),
        .reg_read_addr_i2_1(reg_read_addr_decoder2_1),   
        .reg_read_addr_i2_2(reg_read_addr_decoder2_2),
        
        .reg_write_en_i(reg_write_en_decoder),    //的寄存器写使能
        .reg_write_addr_i1(reg_write_addr_decoder1),  //目的寄存器地址
        .reg_write_addr_i2(reg_write_addr_decoder2),

        .csr_read_en_i(csr_read_en_decoder),//csr写使能
        .csr_addr_i1(csr_addr_decoder1),
        .csr_addr_i2(csr_addr_decoder2),
        .csr_write_en_i(csr_write_en_decoder),//csrcsr写数据
        .pre_is_branch_taken_i(pre_is_branch_taken_decoder),// //前一条指令是否是分支指令
        .pre_branch_addr_i1(pre_branch_addr_decoder1), //前一条指令的分支地址
        .pre_branch_addr_i2(pre_branch_addr_decoder2),


        // 来自ex和mem的前递数据
        .ex_pf_write_en(reg_write_en_ex_pf),     //从ex阶段前递出来的使能
        .ex_pf_write_addr1(reg_write_addr_ex_pf1),   //从ex阶段前递出来的地址
        .ex_pf_write_addr2(reg_write_addr_ex_pf2),
        .ex_pf_write_data1(reg_write_data_ex_pf1),   //从ex阶段前递出来的数据
        .ex_pf_write_data2(reg_write_data_ex_pf2),

        .mem_pf_write_en(reg_write_en_mem_pf),    //从mem阶段前递出来的使能
        .mem_pf_write_addr1(reg_write_addr_mem_pf1),  //从mem阶段前递出来的地址
        .mem_pf_write_addr2(reg_write_addr_mem_pf2),
        .mem_pf_write_data1(reg_write_data_mem1),
        .mem_pf_write_data2(reg_write_data_mem2),  //从mem阶段前递出来的数据

        .wb_pf_write_en(reg_write_en_wb_pf),     //从wb阶段前递出来的使能
        .wb_pf_write_addr1(reg_write_addr_wb_pf1),   //从wb阶段前递出来的地址
        .wb_pf_write_addr2(reg_write_addr_wb_pf2),
        .wb_pf_write_data1(reg_write_data_wb_pf1),
        .wb_pf_write_data2(reg_write_data_wb_pf2),   //从wb阶段前递出来的数据

        //来自ex阶段的，用于判断ex运行的指令是否是load指令
        .ex_pre_aluop1(pre_ex_aluop1),       //ex阶段的load指令标志
        .ex_pre_aluop2(pre_ex_aluop2),

        //来自ex阶段的，可能由于乘除法等指令引起的暂停信号
        .ex_pause(pause_to_dispatch_ex_pause),//pause_o[5]           //ex阶段的暂停信号

        // 输出给execute的数据
        .pc1_o(pc_dispatch1),  
        .pc2_o(pc_dispatch2),
        .inst1_o(inst_dispatch1),
        .inst2_o(inst_dispatch2),
        .valid_o(valid_dispatch),

        .is_exception_o1(is_exception_dispatch1), //两条指令的异常标志
        .is_exception_o2(is_exception_dispatch2),

        .pc_exception_cause_o1(pc_exception_cause_dispatch1), 
        .pc_exception_cause_o2(pc_exception_cause_dispatch2),
        .instbuffer_exception_cause_o1(instbuffer_exception_cause_dispatch1),
        .instbuffer_exception_cause_o2(instbuffer_exception_cause_dispatch2),
        .decoder_exception_cause_o1(decoder_exception_cause_dispatch1), 
        .decoder_exception_cause_o2(decoder_exception_cause_dispatch2),
        .dispatch_exception_cause_o1(dispatch_exception_cause_dispatch1),
        .dispatch_exception_cause_o2(dispatch_exception_cause_dispatch2),

        .is_privilege_o(is_privilege_dispatch), //两条指令的特权指令标志

        .alu_op_o1(aluop_dispatch1),
        .alu_op_o2(aluop_dispatch2),
        .alu_sel_o1(alusel_dispatch1),
        .alu_sel_o2(alusel_dispatch2),

        .reg_read_data_o1_1(reg_data_dispatch1_1), //寄存器堆给出的第1条指令的两个源操作数
        .reg_read_data_o1_2(reg_data_dispatch1_2),
        .reg_read_data_o2_1(reg_data_dispatch2_1), //寄存器堆给出的第2条指令的两个源操作数
        .reg_read_data_o2_2(reg_data_dispatch2_2),

        .reg_write_en_o(reg_write_en_dispatch),    //目的寄存器写使能
        .reg_write_addr_o1(reg_write_addr_dispatch1),  //目的寄存器地址
        .reg_write_addr_o2(reg_write_addr_dispatch2),

        .csr_read_data_o1(csr_read_data_dispatch1), 
        .csr_read_data_o2(csr_read_data_dispatch2),
        .csr_write_en_o(csr_write_en_dispatch), //存器堆的csr读使能
        .csr_addr_o1(csr_addr_dispatch1),
        .csr_addr_o2(csr_addr_dispatch2),

        .invtlb_op_o1(invtlb_op_dispatch1),   //两条指令的分支指令标志
        .invtlb_op_o2(invtlb_op_dispatch2),

        .pre_is_branch_taken_o(pre_is_branch_taken_dispatch), //前一条指令是否是分支指令
        .pre_branch_addr_o1(pre_branch_addr_dispatch1),
        .pre_branch_addr_o2(pre_branch_addr_dispatch2),


         // 输出给 id 阶段的信号
        .invalid_en(invalid_en_dispatch), //指令发射控制信号

        // 与寄存器的接口
        .from_reg_read_data_i1_1(reg_read_data1_1),
        .from_reg_read_data_i1_2(reg_read_data1_2),
        .from_reg_read_data_i2_1(reg_read_data2_1),       
        .from_reg_read_data_i2_2(reg_read_data2_2),

        .dispatch_pause(pause_dispatch),    //发射器暂停信号,当发生load-use冒险时需要暂停

        // 和csr的接口
        // 输入
        .csr_read_data_i1(csr_read_data1),
        .csr_read_data_i2(csr_read_data2),
        // 输出
        .csr_read_en_o(csr_read_en),
        .csr_read_addr_o1(csr_read_addr1),
        .csr_read_addr_o2(csr_read_addr2)

    );

    wire flush_to_execute = flush_o[5];
    wire pause_to_execute = pause_o[5];

    execute u_execute 
    (
        .clk(clk),
        .rst(rst),

    // 来自ctrl的信号
        .flush(flush_to_execute),    // 执行阶段刷新信号,当发生分支预测错误时需要刷新
        .pause(pause_to_execute),    // 执行阶段暂停信号,当发生load-use冒险时需要暂停

    // 来自stable counter的信号
        .cnt_i(cnt), 

    // 来自dispatch的数据
        .pc1_i(pc_dispatch1),
        .pc2_i(pc_dispatch2),
        .inst1_i(inst_dispatch1),
        .inst2_i(inst_dispatch2),
        .valid_i(valid_dispatch),

        .is_exception1_i(is_exception_dispatch1), // 两条指令的异常标志
        .is_exception2_i(is_exception_dispatch2),
        .pc_exception_cause1_i(pc_exception_cause_dispatch1), 
        .pc_exception_cause2_i(pc_exception_cause_dispatch2),
        .instbuffer_exception_cause1_i(instbuffer_exception_cause_dispatch1),
        .instbuffer_exception_cause2_i(instbuffer_exception_cause_dispatch2),
        .decoder_exception_cause1_i(decoder_exception_cause_dispatch1),
        .decoder_exception_cause2_i(decoder_exception_cause_dispatch2),
        .dispatch_exception_cause1_i(dispatch_exception_cause_dispatch1),
        .dispatch_exception_cause2_i(dispatch_exception_cause_dispatch2),

        .is_privilege_i(is_privilege_dispatch),

        .aluop1_i(aluop_dispatch1),
        .aluop2_i(aluop_dispatch2),
        .alusel1_i(alusel_dispatch1),//????为什么原是1
        .alusel2_i(alusel_dispatch2),


        .reg_data1_1_i(reg_data_dispatch1_1),
        .reg_data1_2_i(reg_data_dispatch1_2),
        .reg_data2_1_i(reg_data_dispatch2_1),
        .reg_data2_2_i(reg_data_dispatch2_2),
        .reg_write_en_i(reg_write_en_dispatch),                // 寄存器写使能
        .reg_write_addr1_i(reg_write_addr_dispatch1),        // 寄存器写地址
        .reg_write_addr2_i(reg_write_addr_dispatch2),

        .csr_read_data1_i(csr_read_data_dispatch1),    // csr读数据
        .csr_read_data2_i(csr_read_data_dispatch2),
        .csr_write_en_i(csr_write_en_dispatch),     // csr写使能
        .csr_addr1_i(csr_addr_dispatch1), 
        .csr_addr2_i(csr_addr_dispatch2),

        .invtlb_op1_i(invtlb_op_dispatch1),
        .invtlb_op2_i(invtlb_op_dispatch2),

        .pre_is_branch_taken_i(pre_is_branch_taken_dispatch),      // 预测分支指令是否跳转
        .pre_branch_addr1_i(pre_branch_addr_dispatch1), 
        .pre_branch_addr2_i(pre_branch_addr_dispatch2),

        .ex_bpu_is_bj(ex_bpu_is_bj),     // 两条指令是否是跳转指令
        .ex_pc1(ex_pc1),            // eex 阶段的 pc
        .ex_pc2(ex_pc2),
        .ex_bpu_taken_or_not_actual(ex_bpu_taken_or_not_actual),       // 两条指令实际是否跳转
        .ex_bpu_branch_actual_addr1(ex_bpu_branch_actual_addr1),  // 两条指令实际跳转地址
        .ex_bpu_branch_actual_addr2(ex_bpu_branch_actual_addr2),
        .ex_bpu_branch_pred_addr1(ex_bpu_branch_pred_addr1),    // 两条指令预测跳转地址
        .ex_bpu_branch_pred_addr2(ex_bpu_branch_pred_addr2),
    
    // 来自mem的信号
        .pause_mem_i(pause_mem),

    // 和dcache的接口
        .dcache_pause_i(dcache_pause_i),    // 暂停dcache访问信号

        .ren_o(ren_o),          
        .wstrb_o(wstrb_o),
        .virtual_addr_o(virtual_addr_o),
        .wdata_o(wdata_o),


    // 前递给dispatch的数据
        .pre_ex_aluop1_o(pre_ex_aluop1),
        .pre_ex_aluop2_o(pre_ex_aluop2),
        .reg_write_en_o(reg_write_en_ex_pf),
        .reg_write_addr1_o(reg_write_addr_ex_pf1),
        .reg_write_addr2_o(reg_write_addr_ex_pf2),
        .reg_write_data1_o(reg_write_data_ex_pf1),
        .reg_write_data2_o(reg_write_data_ex_pf2),
    
    // 输出给ctrl的数据
        .pause_ex_o(pause_execute),
        .branch_flush_o(branch_flush),
        .ex_excp_flush_o(ex_excep_flush),
        .branch_target_o(branch_addr),

    // 输出给mem的数据
        .pc1_mem(pc_execute1),
        .pc2_mem(pc_execute2),
        .inst1_mem(inst_execute1),
        .inst2_mem(inst_execute2),

        .is_exception1_o(is_exception_execute1),
        .is_exception2_o(is_exception_execute2),
        .pc_exception_cause1_o(pc_exception_cause_execute1),
        .pc_exception_cause2_o(pc_exception_cause_execute2),
        .instbuffer_exception_cause1_o(instbuffer_exception_cause_execute1),
        .instbuffer_exception_cause2_o(instbuffer_exception_cause_execute2),
        .decoder_exception_cause1_o(decoder_exception_cause_execute1),
        .decoder_exception_cause2_o(decoder_exception_cause_execute2),
        .dispatch_exception_cause1_o(dispatch_exception_cause_execute1),
        .dispatch_exception_cause2_o(dispatch_exception_cause_execute2),
        .execute_exception_cause1_o(execute_exception_cause_execute1),
        .execute_exception_cause2_o(execute_exception_cause_execute2),

        .is_privilege_mem(is_privilege_execute),
        .is_ertn_mem(is_ertn_execute),
        .is_idle_mem(is_idle_execute),
        .valid_mem(valid_execute),

        .reg_write_en_mem(reg_write_en_execute),
        .reg_write_addr1_mem(reg_write_addr_execute1),
        .reg_write_addr2_mem(reg_write_addr_execute2),
        .reg_write_data1_mem(reg_write_data_execute1), 
        .reg_write_data2_mem(reg_write_data_execute2),

        .aluop1_mem(aluop_execute1),
        .aluop2_mem(aluop_execute2),

        .addr1_mem(addr_execute1),
        .addr2_mem(addr_execute2),
        .data1_mem(data_execute1),
        .data2_mem(data_execute2),

        .csr_write_en_mem(csr_write_en_execute),
        .csr_addr1_mem(csr_addr_execute1),
        .csr_addr2_mem(csr_addr_execute2),
        .csr_write_data1_mem(csr_write_data_execute1),
        .csr_write_data2_mem(csr_write_data_execute2),

        .is_llw_scw_mem(is_llw_scw_execute)

    );

    mem u_mem (
        .clk(clk),
        .rst(rst),

    // 执行阶段的信号
        .pc1(pc_execute1) ,
        .pc2(pc_execute2) ,
        .inst1(inst_execute1),
        .inst2(inst_execute2),

        .is_exception1_i(is_exception_execute1),  
        .is_exception2_i(is_exception_execute2),
        .pc_exception_cause1_i(pc_exception_cause_execute1) ,
        .pc_exception_cause2_i(pc_exception_cause_execute2) ,
        .instbuffer_exception_cause1_i(instbuffer_exception_cause_execute1),
        .instbuffer_exception_cause2_i(instbuffer_exception_cause_execute2),
        .decoder_exception_cause1_i(decoder_exception_cause_execute1),
        .decoder_exception_cause2_i(decoder_exception_cause_execute2),
        .dispatch_exception_cause1_i(dispatch_exception_cause_execute1),
        .dispatch_exception_cause2_i(dispatch_exception_cause_execute2),
        .execute_exception_cause1_i(execute_exception_cause_execute1),
        .execute_exception_cause2_i(execute_exception_cause_execute2),

        .is_privilege(is_privilege_execute), 
        .is_ertn(is_ertn_execute),
        .is_idle(is_idle_execute), 
        .valid(valid_execute),

        .reg_write_en(reg_write_en_execute),  //寄存器写使能信号
        .reg_write_addr1(reg_write_addr_execute1),
        .reg_write_addr2(reg_write_addr_execute2),
        .reg_write_data1(reg_write_data_execute1), 
        .reg_write_data2(reg_write_data_execute2),
        .aluop1(aluop_execute1),
        .aluop2(aluop_execute2),
        .mem_addr1(addr_execute1), //内存地址
        .mem_addr2(addr_execute2), 
        .mem_write_data1(data_execute1),
        .mem_write_data2(data_execute2),
        .csr_write_en(csr_write_en_execute), //CSR寄存器写使能
        .csr_addr1(csr_addr_execute1), //CSR寄存器地址
        .csr_addr2(csr_addr_execute2),
        .csr_write_data_mem1(csr_write_data_execute1),
        .csr_write_data_mem2(csr_write_data_execute2),
        .is_llw_scw(is_llw_scw_execute), //是否是LLW/SCW指令

    //dcache的信号
        .dcache_read_data(rdata_i), 

        .data_ok(rdata_valid_i),                //dcache的信号
        .dcache_P_addr(32'b0),
    
    // 输出给dispatcher的信号
        .mem_pf_reg_write_en(reg_write_en_mem_pf), 
        .mem_pf_reg_write_addr1(reg_write_addr_mem_pf1),
        .mem_pf_reg_write_addr2(reg_write_addr_mem_pf2),

    // 输出给ctrl的信号
        .pause_mem(pause_mem), //閫通知暂停内存访问信号

    //输出给wb的信号
        .wb_reg_write_en(reg_write_en_mem), 
        .wb_reg_write_addr1(reg_write_addr_mem1),
        .wb_reg_write_addr2(reg_write_addr_mem2),
        .wb_reg_write_data1(reg_write_data_mem1),
        .wb_reg_write_data2(reg_write_data_mem2),

        .wb_csr_write_en(csr_write_en_mem), //CSR寄存器写使能
        .wb_csr_addr1(csr_write_addr_mem1), //CSR寄存器地址
        .wb_csr_addr2(csr_write_addr_mem2),
        .wb_csr_write_data1(csr_write_data_mem1),
        .wb_csr_write_data2(csr_write_data_mem2),
        .wb_is_llw_scw(is_llw_scw_mem), //是否是LLW/SCW指令

    //commit_ctrl的信号
        .commit_valid(valid_mem), //指令是否有效

        .is_exception1_o(is_exception_mem1),
        .is_exception2_o(is_exception_mem2), 
        .pc_exception_cause1_o(pc_exception_cause_mem1),
        .pc_exception_cause2_o(pc_exception_cause_mem2),
        .instbuffer_exception_cause1_o(instbuffer_exception_cause_mem1),
        .instbuffer_exception_cause2_o(instbuffer_exception_cause_mem2),
        .decoder_exception_cause1_o(decoder_exception_cause_mem1),
        .decoder_exception_cause2_o(decoder_exception_cause_mem2),
        .dispatch_exception_cause1_o(dispatch_exception_cause_mem1),
        .dispatch_exception_cause2_o(dispatch_exception_cause_mem2),
        .execute_exception_cause1_o(execute_exception_cause_mem1),
        .execute_exception_cause2_o(execute_exception_cause_mem2),
        .commit_exception_cause1_o(commit_exception_cause_mem1),
        .commit_exception_cause2_o(commit_exception_cause_mem2),

        .commit_pc1(pc_mem1),
        .commit_pc2(pc_mem2),
        .commit_addr1(addr_mem1), //内存地址
        .commit_addr2(addr_mem2),
        .commit_idle(is_idle_mem), //是否是空闲指令
        .commit_ertn(is_ertn_mem), //是否是异常返回指令
        .commit_is_privilege(is_privilege_mem) //特权指令

    );

    wire [31:0] wb_inst1;
    wire [31:0] wb_inst2;

    wb u_wb (
        .clk(clk),
        .rst(rst),

   //   mem传入的信号
        .wb_reg_write_en(reg_write_en_mem), 
        .wb_reg_write_addr1(reg_write_addr_mem1),
        .wb_reg_write_addr2(reg_write_addr_mem2),
        .wb_reg_write_data1(reg_write_data_mem1),
        .wb_reg_write_data2(reg_write_data_mem2),
        .wb_csr_write_en(csr_write_en_mem), //CSR寄存器写使能
        .wb_csr_addr1(csr_write_addr_mem1), //CSR寄存器地址
        .wb_csr_addr2(csr_write_addr_mem2),
        .wb_csr_write_data1(csr_write_data_mem1),
        .wb_csr_write_data2(csr_write_data_mem2),
        .wb_is_llw_scw(is_llw_scw_mem), //是否是LLW/SCW指令

        .commit_valid(valid_mem), //指令是否有效

        .is_exception1_i(is_exception_mem1),
        .is_exception2_i(is_exception_mem2),
        .pc_exception_cause1_i(pc_exception_cause_mem1),
        .pc_exception_cause2_i(pc_exception_cause_mem2),
        .instbuffer_exception_cause1_i(instbuffer_exception_cause_mem1),
        .instbuffer_exception_cause2_i(instbuffer_exception_cause_mem2),
        .decoder_exception_cause1_i(decoder_exception_cause_mem1),
        .decoder_exception_cause2_i(decoder_exception_cause_mem2),
        .dispatch_exception_cause1_i(dispatch_exception_cause_mem1),
        .dispatch_exception_cause2_i(dispatch_exception_cause_mem2),
        .execute_exception_cause1_i(execute_exception_cause_mem1),
        .execute_exception_cause2_i(execute_exception_cause_mem2),
        .commit_exception_cause1_i(commit_exception_cause_mem1),
        .commit_exception_cause2_i(commit_exception_cause_mem2),

        .commit_pc1(pc_mem1),
        .commit_pc2(pc_mem2),
        .commit_addr1(addr_mem1), //内存地址
        .commit_addr2(addr_mem2), 
        .commit_idle(is_idle_mem), //是否是空闲指令
        .commit_ertn(is_ertn_mem), //是否是异常返回指令
        .commit_is_privilege(is_privilege_mem), //特权指令
        .pause_mem(pause_mem),

        .wb_pf_reg_write_en(reg_write_en_wb_pf),    
        .wb_pf_reg_write_addr1(reg_write_addr_wb_pf1), 
        .wb_pf_reg_write_addr2(reg_write_addr_wb_pf2),   
        .wb_pf_reg_write_data1(reg_write_data_wb_pf1), 
        .wb_pf_reg_write_data2(reg_write_data_wb_pf2), 

    // to ctrl
        .ctrl_reg_write_en(reg_write_en_wb), 
        .ctrl_reg_write_addr1(reg_write_addr_wb1),
        .ctrl_reg_write_addr2(reg_write_addr_wb2),
        .ctrl_reg_write_data1(reg_write_data_wb1),
        .ctrl_reg_write_data2(reg_write_data_wb2),

        .ctrl_csr_write_en(csr_write_en_wb), //CSR寄存器写使能
        .ctrl_csr_addr1(csr_write_addr_wb1), //CSR寄存器地址
        .ctrl_csr_addr2(csr_write_addr_wb2),
        .ctrl_csr_write_data1(csr_write_data_wb1),
        .ctrl_csr_write_data2(csr_write_data_wb2),
        .ctrl_is_llw_scw(is_llw_scw_wb), //是否是LLW/SCW指令

        .commit_valid_out(valid_wb), //指令是否有效

        .is_exception1_o(is_exception_wb1),
        .is_exception2_o(is_exception_wb2),
        .pc_exception_cause1_o(pc_exception_cause_wb1),
        .pc_exception_cause2_o(pc_exception_cause_wb2),
        .instbuffer_exception_cause1_o(instbuffer_exception_cause_wb1),
        .instbuffer_exception_cause2_o(instbuffer_exception_cause_wb2),
        .decoder_exception_cause1_o(decoder_exception_cause_wb1),
        .decoder_exception_cause2_o(decoder_exception_cause_wb2),
        .dispatch_exception_cause1_o(dispatch_exception_cause_wb1),
        .dispatch_exception_cause2_o(dispatch_exception_cause_wb2),
        .execute_exception_cause1_o(execute_exception_cause_wb1),
        .execute_exception_cause2_o(execute_exception_cause_wb2),
        .commit_exception_cause1_o(commit_exception_cause_wb1),
        .commit_exception_cause2_o(commit_exception_cause_wb2),

        .commit_pc_out1(pc_wb1),
        .commit_pc_out2(pc_wb2),
        .commit_addr_out1(addr_wb1), //内存地址
        .commit_addr_out2(addr_wb2),
        .commit_idle_out(is_idle_wb), //是否是空闲指令
        .commit_ertn_out(is_ertn_wb), //是否是异常返回指令
        .commit_is_privilege_out(is_privilege_wb), //特权指令
        .mem_inst1(inst_execute1),
        .mem_inst2(inst_execute2),
        .wb_inst1(wb_inst1),
        .wb_inst2(wb_inst2)
    );


    ctrl u_ctrl (
        .rst(rst),

        .pause_buffer(1'b0),//从前端输入,不知道有没有
        .pause_decode(pause_decoder),//从decoder输入,  暂时也没有
        .pause_dispatch(pause_dispatch),//从dispatch输入
        .pause_execute(pause_execute),//从execute输入
        .pause_mem(pause_mem),//从mem输入

        .branch_flush(branch_flush),//分支跳转刷新信号
        .branch_target(branch_addr),//分支跳转地址，从execute阶段输入
        .ex_excp_flush(ex_excep_flush),//异常刷新信号,从execute阶段输入

    //wb阶段输入wb
        .reg_write_en_i(reg_write_en_wb),//写回阶段刷新信号
        .reg_write_addr1_i(reg_write_addr_wb1),//写回阶段寄存器地址
        .reg_write_addr2_i(reg_write_addr_wb2),
        .reg_write_data1_i(reg_write_data_wb1),//写回阶段寄存器数据
        .reg_write_data2_i(reg_write_data_wb2),
        .is_llw_scw_i(is_llw_scw_wb),//是否是 llw/scw 指令
        .csr_write_en_i(csr_write_en_wb),//csr写使能信号
        .csr_write_addr1_i(csr_write_addr_wb1),//csr写地址
        .csr_write_addr2_i(csr_write_addr_wb2),
        .csr_write_data1_i(csr_write_data_wb1),//csr写数据
        .csr_write_data2_i(csr_write_data_wb2),

    //从wb阶段输入commit
        .is_exception1_i(is_exception_wb1),//是否有异常
        .is_exception2_i(is_exception_wb2),
        .pc_exception_cause1_i(pc_exception_cause_wb1),
        .pc_exception_cause2_i(pc_exception_cause_wb2),
        .instbuffer_exception_cause1_i(instbuffer_exception_cause_wb1),
        .instbuffer_exception_cause2_i(instbuffer_exception_cause_wb2),
        .decoder_exception_cause1_i(decoder_exception_cause_wb1),
        .decoder_exception_cause2_i(decoder_exception_cause_wb2),
        .dispatch_exception_cause1_i(dispatch_exception_cause_wb1),
        .dispatch_exception_cause2_i(dispatch_exception_cause_wb2),
        .execute_exception_cause1_i(execute_exception_cause_wb1),
        .execute_exception_cause2_i(execute_exception_cause_wb2),
        .commit_exception_cause1_i(commit_exception_cause_wb1),
        .commit_exception_cause2_i(commit_exception_cause_wb2),

        .pc1_i(pc_wb1),
        .pc2_i(pc_wb2),
        .mem_addr1_i(addr_wb1),
        .mem_addr2_i(addr_wb2),
        .is_idle_i(is_idle_wb),//是否处于空闲状态
        .is_ertn_i(is_ertn_wb),//是否是异常返回指令
        .is_privilege_i(is_privilege_wb),//是否是特权指令
        .valid_i(valid_wb),//指令是否有效
    //csr
        .is_ertn_o(csr_is_ertn),//是否是异常返回指令
    //
        .flush(flush_o),//刷新信号
        .pause(pause_o),//暂停信号


        .new_pc(new_pc),

    //to regfile
        .reg_write_en_o(reg_write_en),//写回阶段刷新信号
        .reg_write_addr1_o(reg_write_addr1),//写回阶段寄存器地址
        .reg_write_addr2_o(reg_write_addr2),
        .reg_write_data1_o(reg_write_data1),//写回阶段寄存器数据
        .reg_write_data2_o(reg_write_data2),

    //to csr
        .is_llw_scw_o(is_llw_scw_ctrl),//是否是 llw/scw 指令
        .csr_write_en_o(csr_write_en),//csr写使能信号
        .csr_write_addr_o(csr_write_addr),//csr写地址
        .csr_write_data_o(csr_write_data),//csr写数据

    // with csr
        .csr_eentry_i(csr_eentry), //异常入口地址
        .csr_era_i(csr_era), //异常返回地址
        .csr_crmd_i(csr_crmd), //控制寄存器  
        .csr_is_interrupt_i(csr_is_interrupt), //是否是中断
    
        .csr_is_exception_o(csr_is_exception), //是否是异常
        .csr_exception_pc_o(csr_exception_pc), //异常PC地址
        .csr_exception_addr_o(csr_exception_addr), //异常地址
        .csr_ecode_o(csr_ecode), //异常ecode
        .csr_exception_cause_o(csr_exception_cause), //异常原因
        .csr_esubcode_o(csr_esubcode) //异常子码
    );

    reg_files u_reg_files (
        // 输入
        .clk(clk),
        .rst(rst),
        .reg_read_en1(reg_read_en_decoder1),            // 第一条指令的两个读使能
        .reg_read_en2(reg_read_en_decoder2),            // 第二条指令的两个读使能
        .reg_read_addr1_1(reg_read_addr_decoder1_1), 
        .reg_read_addr1_2(reg_read_addr_decoder1_2), 
        .reg_read_addr2_1(reg_read_addr_decoder2_1), //寄存器读地址
        .reg_read_addr2_2(reg_read_addr_decoder2_2),
        .reg_write_data1(reg_write_data1), 
        .reg_write_data2(reg_write_data2),
        .reg_write_en(reg_write_en), //寄存器写使能信号
        .reg_write_addr1(reg_write_addr1),
        .reg_write_addr2(reg_write_addr2),

        // 输出
        .reg_read_data1_1(reg_read_data1_1),  //寄存器读数据
        .reg_read_data1_2(reg_read_data1_2), 
        .reg_read_data2_1(reg_read_data2_1),   //寄存器读数据
        .reg_read_data2_2(reg_read_data2_2)
    );

    csr u_csr (
        .clk(clk),
        .rst(rst),

        // 和dispatch的接口
        // 输入
        .csr_read_en_i(csr_read_en),
        .csr_read_addr_i1(csr_read_addr1),
        .csr_read_addr_i2(csr_read_addr2),
        //  输出
        .csr_read_data_o1(csr_read_data1),
        .csr_read_data_o2(csr_read_data2),

        // 来自wb的信号
        .is_llw_scw_i(is_llw_scw_ctrl),
        .csr_write_en_i(csr_write_en),
        .csr_write_addr_i(csr_write_addr),
        .csr_write_data_i(csr_write_data),

        //tlb相关输入
        .search_tlb_found_i(1'b0),
        .search_tlb_index_i(5'b0),
        .tlbrd_valid_i(1'b0),
        .tlbehi_out_i(32'b0),
        .tlbelo0_out_i(32'b0),
        .tlbelo1_out_i(32'b0),
        .tlbidx_out_i(32'b0),
        .asid_out_i(10'b0),
        .tlbsrch_ret_i(1'b0),
        .tlbrd_ret_i(1'b0),

        //tlb相关输出
        .tlbidx_o(tlbidx),  //7.5.1TLB索引寄存器，包含[4:0]为index,[29:24]为PS，[31]为NE
        .tlbehi_o(tlbehi),  //7.5.2TLB表项高位，包含[31:13]为VPPN
        .tlbelo0_o(tlbelo0),   //7.5.3TLB表项低位，包含写入TLB表项的内容
        .tlbelo1_o(tlbelo1),
        .asid_o(asid),  //7.5.4ASID的低9位
        //TLBFILL和TLBWR指令
        .ecode_o(ecode),//7.5.1对于NE变量的描述中讲到，CSR.ESTAT.Ecode   (大概使能信号，若为111111则写使能，否则根据tlbindex_in.NE判断是否写使能？
        //CSR信号
        .csr_dmw0_o(csr_dmw0),//dmw0，有效位是[27:25]，可能会作为最后转换出来的地址的最高三位
        .csr_dmw1_o(csr_dmw1),//dmw1，有效位是[27:25]，可能会作为最后转换出来的地址的最高三位
        .csr_da_o(csr_da),
        .csr_pg_o(csr_pg),
        .csr_plv_o(csr_plv),
        .csr_datf_o(csr_datf),
        .csr_datm_o(csr_datm),
    
    
        // from outer（不知道是什么）
        .is_ipi(1'b0), //接0
        .is_hwi(is_hwi),//mytop输入的


        // 和ctrl的接口
        // 输入
        .is_exception_i(csr_is_exception), //是否是异常
        .exception_cause_i(csr_exception_cause), //异常原因
        .exception_pc_i(csr_exception_pc), //异常PC地址
        .exception_addr_i(csr_exception_addr), //异常地址
        .ecode_i(csr_ecode), //异常ecode
        .esubcode_i(csr_esubcode), //异常子码
        .is_ertn_i(csr_is_ertn),
        .is_inst_tlb_exception_i(csr_is_inst_tlb_exception), //是否是指令TLB异常
        .is_tlb_exception_i(csr_is_tlb_exception),
        // 输出
        .eentry_o(csr_eentry), //异常入口地址
        .era_o(csr_era), //常返回地址
        .crmd_o(csr_crmd), //控制寄存器
        .is_interrupt_o(csr_is_interrupt), //是否是中断
        .tlbrentry_o(csr_tlbrentry)
    );

    clock u_clock 
    (
        .clk(clk),
        .rst(rst),

        .count_64(cnt)
    );

    assign debug_wb_valid1 = valid_wb[0];
    assign debug_wb_valid2 = valid_wb[1];
    assign debug_pc1 = !is_exception_wb1[1] ? pc_wb1 : 32'b0;
    assign debug_pc2 = !is_exception_wb2[1] ? pc_wb2 : 32'b0;
    assign  debug_inst1 = wb_inst1;
    assign debug_inst2 = wb_inst2;
    assign  debug_reg_addr1 = !is_exception_wb1[1] ? reg_write_addr_wb1 : 5'b0;
    assign  debug_reg_addr2 = !is_exception_wb2[1] ? reg_write_addr_wb2 : 5'b0;
    assign  debug_wdata1 = !is_exception_wb1[1] ? reg_write_data_wb1 : 32'b0;
    assign  debug_wdata2 = !is_exception_wb2[1] ? reg_write_data_wb2 : 32'b0; 
    assign debug_wb_we1 = reg_write_en_wb[0];
    assign debug_wb_we2 = reg_write_en_wb[1];

endmodule