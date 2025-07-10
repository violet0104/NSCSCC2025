`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module backend (
    input wire clk,
    input wire rst,

/*****************************
    不知道什么意思
    // from outer
    input wire [7:0] is_hwi,
******************************/

    // 来自前端的信息
    input wire [1:0] [31:0] pc_i,
    input wire [1:0] [31:0] inst_i,
    input wire [1:0] valid_i,                           // 前端传递的数据有效信号
    input wire [1:0] pre_is_branch_taken_i,             // 前端传递的分支预测结果
    input wire [1:0] [31:0] pre_branch_addr_i,          // 前端传递的分支预测目标地址
    input wire [1:0] [1:0] is_exception_i,              // 前端传递的异常标志
    input wire [1:0] [1:0] [6:0] exception_cause_i,     // 异常原因

//*********************************
    input wire pause_i,
    input wire flush_i,      // 这两个信号不知道对应前端什么信号
//*********************************


/*****************************
    这个我们没有
    // to pc
    output logic   is_interrupt,
    output bus32_t new_pc,
    
******************************/

    // 输出给 bpu 的信息
    output wire updata_en_o,
    output wire taken_or_not_actual_o,
    output wire [31:0] branch_actual_addr_o,
    output wire [31:0] pc_dispatch_o,

    // 输出给 instbuffer 的取指请求信号
    output wire get_data_req_o,

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

    // 和 Cache 的接口
    input wire addr_ok_i,
    input wire data_ok_i,
    input wire [31:0] rdata_i,
    input wire [31:0] physical_addr_i,

    output wire valid_o,
    output wire op_o,
    output wire virtual_addr_o,
    output wire wstrb_o,
    output wire wdata,

    // 从 ctrl 输出的信号
    output wire [7:0] flush_o,
    output wire [7:0] pause_o, 

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

);

    /*************************

    assign pause_request.pause_buffer = pause_buffer;
    assign pause_decoder = pause_request.pause_decoder;

    **************************/

    // reg_files
    wire [1:0] reg1_read_en ;       // 寄存器读使能
    wire [1:0] reg2_read_en ;
    wire [1:0] reg_write_en;            // 寄存器写使能
    wire [4:0] reg1_read_addr [1:0];     // 寄存器读地址
    wire [4:0] reg2_read_addr [1:0];
    wire [4:0] reg_write_addr [1:0];    // 寄存器写地址
    wire [31:0] reg1_read_data [1:0];    // 寄存器读数据
    wire [31:0] reg2_read_data [1:0];
    wire [31:0] reg_write_data [1:0];   // 寄存器写数据

    // csr
    wire [1:0] csr_read_en;             // csr 读使能
    wire [1:0] csr_write_en;            // csr 写使能
    wire [13:0] csr_read_addr [1:0];    // csr 读地址
    wire [13:0] csr_write_addr [1:0];   // csr 写地址
    wire [31:0] csr_read_data [1:0];    // csr 读数据
    wire [31:0] csr_write_data [1:0];   // csr 写数据
    wire is_llw_scw;                    // 是否是 llw/scw 指令

    // ctrl
    wire pause_buffer;
    wire pause_decoder;
    wire pause_dispatch;
    wire pause_execute;
    wire pause_mem;
    wire branch_flush;
    wire [31:0] branch_addr;
    wire ex_excep_flush;            // 执行阶段异常的 flush 信号

    // decoder
    wire [31:0] pc_decoder [1:0];
    wire [31:0] inst_decoder [1:0];
    wire [2:0] is_exception_decoder;
    wire [2:0][6:0] exception_cause_decoder [1:0];
    wire [1:0] inst_valid_decoder;
    wire [1:0] is_privilege_decoder;
    wire [1:0] is_cnt_decoder;
    wire [1:0] valid_decoder;
    wire [7:0] aluop_decoder [1:0];
    wire [2:0] alusel_decoder [1:0];
    wire [31:0] imm_decoder [1:0];
    wire [4:0] invtlb_op_decoder [1:0];
    wire [1:0] reg_read_en_decoder [1:0];
    wire [1:0] reg_write_en_decoder;
    wire [4:0] reg_read_addr_decoder [1:0];
    wire [4:0] reg_write_addr_decoder [1:0];
    wire [1:0] csr_read_en_decoder;
    wire [1:0] csr_write_en_decoder;
    wire [13:0] csr_addr_decoder [1:0];
    wire [1:0] pre_is_branch_taken_decoder;
    wire [31:0] pre_branch_addr_decoder [1:0];


    // dispatch
    wire [1:0] reg_write_en_ex_pf;
    wire [4:0] reg_write_addr_ex_pf [1:0];
    wire [31:0] reg_write_data_ex_pf [1:0];
    wire [1:0] reg_write_en_mem_pf;
    wire [4:0] reg_write_addr_mem_pf [1:0];
    wire [31:0] reg_write_data_mem_pf [1:0];
    wire [1:0] reg_write_en_wb_pf;
    wire [4:0] reg_write_addr_wb_pf [1:0];
    wire [31:0] reg_write_data_wb_pf [1:0];
    wire [7:0] pre_ex_aluop [1:0];
    wire [31:0] pc_dispatch [1:0];
    wire [31:0] inst_dispatch [1:0];
    wire [1:0] valid_dispatch;
    wire [3:0] is_exception_dispatch [1:0];
    wire [3:0] [6:0] exception_cause_dispatch [1:0];
    wire [1:0] is_privilege_dispatch;
    wire [7:0] aluop_dispatch [1:0];
    wire [2:0] alusel_dispatch [1:0];
    wire [31:0] reg_data0_dispatch [1:0];
    wire [31:0] reg_data1_dispatch [1:0];
    wire [1:0] reg_write_en_dispatch;                // 寄存器写使能
    wire [4:0] reg_write_addr_dispatch [1:0];        // 寄存器写地址
    wire [31:0] csr_read_data_dispatch [1:0];      // csr读数据
    wire [1:0] csr_write_en_dispatch;              // csr写使能
    wire [13:0] csr_addr_dispatch [1:0];           // csr地址 
    wire [4:0] invtlb_op_dispatch [1:0];
    wire [1:0] pre_is_branch_taken_dispatch;     // 预测分支指令是否跳转
    wire [31:0] pre_branch_addr_dispatch [1:0];   // 预测分支指令跳转地址
    wire [1:0] invalid_en_dispatch;


    // execute
    wire [31:0] pc_execute [1:0];
    wire [31:0] inst_execute [1:0];
    wire [1:0] is_exception_execute;
    wire [4:0] [6:0] exception_cause_execute [1:0];
    wire [1:0] is_privilege_execute;
    wire [1:0] is_ertn_execute;
    wire [1:0] is_idle_execute;
    wire [1:0] valid_execute;
    wire [1:0] reg_write_en_execute;
    wire [4:0] reg_write_addr_execute [1:0];
    wire [31:0] reg_write_data_execute [1:0]; 
    wire [7:0] aluop_execute [1:0];
    wire [31:0] addr_execute [1:0];
    wire [31:0] data_execute [1:0] ;
    wire [1:0] csr_write_en_execute;
    wire [13:0] csr_addr_execute [1:0];
    wire [31:0] csr_write_data_execute [1:0];
    wire [1:0] is_llw_scw_execute;  


    // mem
    wire [31:0] pc_mem [1:0];
    wire [5:0] is_exception_mem [1:0];
    wire [5:0][6:0] exception_cause_mem [1:0];
    wire [1:0] is_privilege_mem;
    wire [1:0] is_ertn_mem;
    wire [1:0] is_idle_mem;
    wire [1:0] valid_mem;
    wire [1:0] reg_write_en_mem;
    wire [4:0] reg_write_addr_mem [1:0];
    wire [31:0] reg_write_data_mem [1:0];
    wire [1:0] csr_write_en_mem;
    wire [13:0] csr_write_addr_mem [1:0];
    wire [31:0] csr_write_data_mem [1:0];
    wire [1:0] is_llw_scw_mem;
    wire [31:0] addr_mem [1:0];


    // wb
    wire [31:0] pc_wb [1:0];
    wire [5:0] is_exception_wb [1:0];
    wire [5:0][6:0] exception_cause_wb [1:0];
    wire [1:0] is_privilege_wb;
    wire [1:0] is_ertn_wb;
    wire [1:0] is_idle_wb;
    wire [1:0] valid_wb;
    wire [1:0] reg_write_en_wb;
    wire [4:0] reg_write_addr_wb [1:0];
    wire [31:0] reg_write_data_wb [1:0];
    wire [1:0] csr_write_en_wb;
    wire [13:0] csr_write_addr_wb [1:0];
    wire [31:0] csr_write_data_wb [1:0];
    wire [1:0] is_llw_scw_wb;
    wire [31:0] addr_wb [1:0];


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

        pc(pc_i),
        inst(inst_i) ,
        valid(valid_i),        
        pretaken(pre_is_branch_taken_i),
        pre_addr_in(pre_branch_addr_i) ,
        is_exception(is_exception_i) ,
        exception_cause(exception_cause_i) ,
        invalid_en(invalid_en_dispatch),

        get_data_req(get_data_req_o),
        dispatch_inst_valid(inst_valid_decoder), 
        dispatch_pc_out(pc_decoder) ,
        dispatch_exception_cause(exception_cause_decoder) , 
        dispatch_is_exception(is_exception_decoder) ,
        dispatch_inst_out(inst_decoder) ,
        dispatch_aluop(aluop_decoder) ,
        dispatch_alusel(alusel_decoder) ,
        dispatch_imm(imm_decoder) ,
        dispatch_reg1_read_en(reg_read_en_decoder[0]),  
        dispatch_reg2_read_en(reg_read_en_decoder[1]),   
        dispatch_reg1_read_addr(reg_read_addr_decoder[0]) ,
        dispatch_reg2_read_addr(reg_read_addr_decoder[1]) ,
        dispatch_reg_writen_en(reg_write_en_decoder),  
        dispatch_reg_write_addr(reg_write_addr_decoder) ,
        dispatch_id_pre_taken(pre_is_branch_taken_decoder),
        dispatch_id_pre_addr(pre_branch_addr_decoder),
        dispatch_is_privilege(is_privilege_decoder), 
        dispatch_csr_read_en(csr_read_en_decoder), 
        dispatch_csr_write_en(csr_write_en_decoder),
        dispatch_csr_addr(csr_addr_decoder), 
        dispatch_is_cnt(is_cnt_decoder), 
        dispatch_invtlb_op(invtlb_op_decoder)  

    );


    dispatch u_dispatch (
        .clk(clk),
        .rst(rst),

    //控制单元的暂停和刷新信号
        .pause(pause_o[4]),
        .flush(flush_o[4]),

        .pc_i(pc_decoder),      //指令地址
        .inst_i(inst_decoder),    //指令编码
        .valid_i(valid_decoder),   //指令有效标志
        .reg_read_en_i0(reg_read_en_decoder[0]),     //第0条指令的两个源寄存器源寄存器读使能
        .reg_read_en_i1(reg_read_en_decoder[1]),     //第1条指令的两个源寄存器源寄存器读使能   
        .reg_read_addr_i0(reg_read_addr_decoder[0]),   //第0条指令的两个源寄存器地址
        .reg_read_addr_i1(reg_read_addr_decoder[1]),   //第1条指令的两个源寄存器地址
        .is_privilege_i(is_privilege_decoder), //两条指令的特权指令标志
        .is_cnt_i(is_cnt_decoder),       //两条指令的计数器指令标志
        .is_exception_i(is_exception_decoder), //两条指令的异常标志
        .exception_cause_i(exception_cause_decoder), //两条指令的异常原因,会变长
        .invtlb_op_i(invtlb_op_decoder),   //两条指令的分支指令标志
        .reg_write_en_i(reg_write_en_decoder),    //目的寄存器写使能
        .reg_write_addr_i(reg_write_addr_decoder),  //目的寄存器地址
        .imm_i(imm_decoder),     //立即数值
        .alu_op_i(aluop_decoder),  //ALU操作码
        .alu_sel_i(alusel_decoder), //ALU功能选择

    //前递数据
        .ex_pf_write_en(reg_write_en_ex_pf),     //从ex阶段前递出来的使能
        .ex_pf_write_addr(reg_write_addr_ex_pf),   //从ex阶段前递出来的地址
        .ex_pf_write_data(reg_write_data_ex_pf),   //从ex阶段前递出来的数据

        .mem_pf_write_en(reg_write_en_mem_pf),    //从mem阶段前递出来的使能
        .mem_pf_write_addr(reg_write_addr_mem_pf),  //从mem阶段前递出来的地址
        .mem_pf_write_data(reg_write_data_mem_pf),  //从mem阶段前递出来的数据

        .wb_pf_write_en(reg_write_en_wb_pf),     //从wb阶段前递出来的使能
        .wb_pf_write_addr(reg_write_addr_wb_pf),   //从wb阶段前递出来的地址
        .wb_pf_write_data(reg_write_data_wb_pf),   //从wb阶段前递出来的数据

    //来自ex阶段的，用于判断ex运行的指令是否是load指令
        .ex_pre_aluop(pre_ex_aluop),       //ex阶段的load指令标志

    //来自ex阶段的，可能由于乘除法等指令引起的暂停信号
        .ex_pause(pause_execute),           //ex阶段的暂停信号

        .pc_o(pc_dispatch),  
        .inst_o(inst_dispatch),
        .valid_o(valid_dispatch),

        .is_privilege_o(is_privilege_dispatch), //两条指令的特权指令标志
        .is_exception_o(is_exception_dispatch), //两条指令的异常标志
        .exception_cause_o(exception_cause_dispatch), //两条指令的异常原因,会变长
        .invtlb_op_o(invtlb_op_dispatch),   //两条指令的分支指令标志

        .reg_write_en_o(reg_write_en_dispatch),    //目的寄存器写使能
        .reg_write_addr_o(reg_write_addr_dispatch),  //目的寄存器地址
    
        .reg_read_data_o0(reg_data0_dispatch), //寄存器堆给出的第0条指令的两个源操作数
        .reg_read_data_o1(reg_data1_dispatch), //寄存器堆给出的第1条指令的两个源操作数

        .alu_op_o(aluop_dispatch),
        .alu_sel_o(alusel_dispatch),

        .invalid_en(invalid_en_dispatch), //指令发射控制信号

        .from_reg_read_data_i0(reg1_read_data),
        .from_reg_read_data_i1(reg2_read_data),

        .dispatch_pause(pause_dispatch),

        .csr_read_en_i(csr_read_en_decoder),//csr写使能
        .csr_addr_i(csr_addr_decoder),//寄csr写地址
        .csr_write_en_i(csr_write_en_decoder),//csr写数据
        .pre_is_branch_taken_i(pre_is_branch_taken_decoder),// //前一条指令是否是分支指令
        .pre_branch_addr_i(pre_branch_addr_decoder), //前一条指令的分支地址

        .csr_read_data_i(csr_read_data),//csr读数据

        .csr_write_en_o(csr_write_en_dispatch), //寄存器堆的csr读使能
        .csr_addr_o(csr_addr_dispatch), //寄存器堆的csr写地址

        .csr_read_data_o(csr_read_data_dispatch), //寄存器堆的csr写数据
    
        .pre_is_branch_taken_o(pre_is_branch_taken_dispatch), //前一条指令是否是分支指令
        .pre_branch_addr_o(pre_branch_addr_dispatch) //前一条指令的分支地址


    );

    execute u_execute (
        .clk(clk),
        .rst(rst),

    // 来自ctrl的信号
        .flush(flush_o[5]),
        .pause(flush_o[5]),

    // 来自stable counter的信号
        .cnt_i(cnt_i), //暂时没有此信号

    // 来自dispatch的数据
        .pc_i(pc_dispatch),
        .inst_i(inst_dispatch),
        .valid_i(valid_dispatch),

        .is_exception_i(is_exception_dispatch),
        .exception_cause_i(exception_cause_dispatch),
        .is_privilege_i(is_privilege_dispatch),

        .aluop_i(aluop_dispatch),
        .alusel_i(alusel_dispatch),

        .reg_data0_i(reg_data0_dispatch),
        .reg_data1_i(reg_data1_dispatch),
        .reg_write_en_i(reg_write_en_dispatch),                // 寄存器写使能
        .reg_write_addr_i(reg_write_addr_dispatch),        // 寄存器写地址

        .csr_read_data_i(csr_read_data_dispatch),    // csr读数据
        .csr_write_en_i(csr_write_en_dispatch),     // csr写使能
        .csr_addr_i(csr_addr_dispatch),  // csr地址 

        .invtlb_op_i(invtlb_op_dispatch),

        .pre_is_branch_taken_i(pre_is_branch_taken_dispatch),      // 预测分支指令是否跳转
        .pre_branch_addr_i(pre_branch_addr_dispatch),   // 预测分支指令跳转地址
    
    // 来自mem的信号
        .pause_mem_i(pause_mem),

    // 和dcache的接口
        .data_ok_i(data_ok_i),            
        .rdata_i(rdata_i),            // 读DCache的结果
        .physical_addr_i(physical_addr_i),    // 物理地址
    
        .valid_dache_o(valid_o),      
        .op_o(op_o),           // 0表示读，1表示写
        .virtual_addr_o(virtual_addr_o),
        .wstrb_o(wstrb_o),
        .wdata_o(wdata_o),

    // 前递给bpu的数据
        .updata_en_o(updata_en_o),
        .taken_or_not_actual_o(taken_or_not_actual_o),
        .branch_actual_addr_o(branch_actual_addr_o),
        .pc_dispatch_o(pc_dispatch_o),

    // 前递给dispatch的数据
        .pre_ex_aluop_o(pre_ex_aluop),
        .reg_write_en_o(reg_write_en_ex_pf),
        .reg_write_addr_o(reg_write_addr_ex_pf),
        .reg_write_data_o(reg_write_data_ex_pf),
    
    // 输出给ctrl的数据
        .pause_ex_o(pause_execute),
        .branch_flush_o(branch_flush),
        .ex_excp_flush_o(ex_excep_flush),
        .branch_target_o(branch_addr),

    // 输出给mem的数据
        .pc_mem(pc_execute),
        .inst_mem(pc_execute),
        .is_exception_mem(is_exception_execute),
        .exception_cause_mem(exception_cause_execute),
        .is_privilege_mem(is_privilege_execute),
        .is_ertn_mem(is_ertn_execute),
        .is_idle_mem(is_idle_execute),
        .valid_mem(valid_execute),

        .reg_write_en_mem(reg_write_en_execute),
        .reg_write_addr_mem(reg_write_addr_execute),
        .reg_write_data_mem(reg_write_data_execute), 

        .aluop_mem(aluop_execute),

        .addr_mem(addr_execute),
        .data_mem(data_execute),

        .csr_write_en_mem(csr_write_en_execute),
        .csr_addr_mem(csr_addr_execute),
        .csr_write_data_mem(csr_write_data_execute),

        .is_llw_scw_mem(is_llw_scw_execute)

    );

    mem u_mem (
        .clk(clk),
        .rst(rst),

    // 执行阶段的信号
        .pc(pc_execute) ,
        .inst(inst_execute),
        .is_exception(is_exception_execute),   //异常标志
        .exception_cause(exception_cause_execute), //异常原因
        .is_privilege(is_privilege_execute), //特权指令标志
        .is_ertn(is_ertn_execute), //是否是异常返回指令
        .is_idle(is_idle_execute), //是否是空闲指令
        .valid(valid_execute), //指令是否有效
        .reg_write_en(reg_write_en_execute),  //寄存器写使能信号
        .reg_write_addr(reg_write_addr_execute),
        .reg_write_data(reg_write_addr_execute), //寄存器写数据
        .aluop(aluop_execute),
        .mem_addr(addr_execute), //内存地址
        .mem_write_data(data_execute), //内存写数据
        .csr_write_en(csr_write_en_execute), //CSR寄存器写使能
        .csr_addr(csr_addr_execute), //CSR寄存器地址
        .csr_write_data_mem(csr_write_data_execute),
        .is_llw_scw(is_llw_scw_execute), //是否是LLW/SCW指令

    //dcache的信号
        .dcache_read_data(rdata_i), 
        .addr_ok(addr_ok_i),
        .data_ok(data_ok_i), //数据访问完成信号
        .dcache_P_addr(physical_addr_i),
    
    // 输出给dispatcher的信号
        .mem_pf_reg_write_en(reg_write_en_mem_pf), 
        .mem_pf_reg_write_addr(reg_write_addr_mem_pf),
        .mem_pf_reg_write_data(reg_write_data_mem_pf),

    // 输出给ctrl的信号
        .pause_mem(pause_mem), //通知暂停内存访问信号

    //输出给wb的信号
        .wb_reg_write_en(reg_write_en_mem), 
        .wb_reg_write_addr(reg_write_addr_mem),
        .wb_reg_write_data(reg_write_data_mem),

        .wb_csr_write_en(csr_write_en_mem), //CSR寄存器写使能
        .wb_csr_addr(csr_addr_mem), //CSR寄存器地址
        .wb_csr_write_data(csr_write_data_mem),
        .wb_is_llw_scw(is_llw_scw_mem), //是否是LLW/SCW指令

    //commit_ctrl的信号
        .commit_valid(valid_mem), //指令是否有效
        .commit_is_exception(is_exception_mem),
        .commit_exception_cause(exception_cause_mem), //异常原因
        .commit_pc(pc_mem),
        .commit_addr(addr_mem), //内存地址
        .commit_idle(is_idle_mem), //是否是空闲指令
        .commit_ertn(is_ertn_mem), //是否是异常返回指令
        .commit_is_privilege(is_privilege_mem) //特权指令

    );

    wb u_wb (
        .clk(clk),
        .rst(rst),

   //   mem传入的信号
        .wb_reg_write_en(reg_write_en_mem), 
        .wb_reg_write_addr(reg_write_addr_mem),
        .wb_reg_write_data(reg_write_data_mem),
        .wb_csr_write_en(csr_write_en_mem), //CSR寄存器写使能
        .wb_csr_addr(csr_addr_mem), //CSR寄存器地址
        .wb_csr_write_data(csr_write_data_mem),
        .wb_is_llw_scw(is_llw_scw_mem), //是否是LLW/SCW指令

        .commit_valid(valid_mem), //指令是否有效
        .commit_is_exception(is_exception_mem),
        .commit_exception_cause(exception_cause_mem), //异常原因
        .commit_pc(pc_mem),
        .commit_addr(addr_mem), //内存地址
        .commit_idle(is_idle_mem), //是否是空闲指令
        .commit_ertn(is_ertn_mem), //是否是异常返回指令
        .commit_is_privilege(is_privilege_mem), //特权指令
        .pause_mem(pause_mem),

        .wb_pf_reg_write_en(reg_write_en_wb_pf),    
        .wb_pf_reg_write_addr(reg_write_addr_wb_pf),    
        .wb_pf_reg_write_data(reg_write_data_wb_pf), 

    // to ctrl
        .ctrl_reg_write_en(reg_write_en_wb), 
        .ctrl_reg_write_addr(reg_write_addr_wb),
        .ctrl_reg_write_data(reg_write_data_wb),

        .ctrl_csr_write_en(csr_write_en_wb), //CSR寄存器写使能
        .ctrl_csr_addr(csr_write_addr_wb), //CSR寄存器地址
        .ctrl_csr_write_data(csr_write_data_wb),
        .ctrl_is_llw_scw(is_llw_scw_wb), //是否是LLW/SCW指令

        .commit_valid_out(valid_wb), //指令是否有效
        .commit_is_exception_out(is_exception_wb),
        .commit_exception_cause_out(exception_cause_wb), //异常原因
        .commit_pc_out(pc_wb),
        .commit_addr_out(addr_wb), //内存地址
        .commit_idle_out(is_idle_wb), //是否是空闲指令
        .commit_ertn_out(is_ertn_wb), //是否是异常返回指令
        .commit_is_privilege_out(is_privilege_wb) //特权指令

    );

    ctrl u_ctrl (

    );

    reg_files u_reg_files (
        .clk(clk),
        .reg1_read_en(reg1_read_en), 
        .reg2_read_en(reg2_read_en), //寄存器读使能信号
        .reg1_read_addr(reg1_read_addr), 
        .reg2_read_addr(reg2_read_addr), //寄存器读地址
        .reg_write_data(reg_write_data), 
        .reg_write_en(reg_write_en), //寄存器写使能信号

        .reg1_read_data(reg1_read_data),  //寄存器读数据
        .reg2_read_data(reg2_read_data)   //寄存器读数据
    );

    csr u_csr (

    );

    stable_counter u_stable_counter (

    );


endmodule