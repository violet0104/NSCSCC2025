`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module decoder (
    input wire clk,
    input wire rst,

    input wire flush, //强制更新信号

    // 前端传递的数据
    input wire [1:0] [31:0] pc,
    input wire [1:0] [31:0] inst ,
    input wire [1:0]  valid,                        // 前端传递的数据有效信号
    input wire [1:0]  pretaken,                     // 前端传递的分支预测结果（是否跳转）
    input wire [1:0] [31:0] pre_addr_in ,           // 前端传递的分支预测目标地址
    input wire [1:0] [1:0]  is_exception ,          // 前端传递的异常信号，is_exception[0]表示inst[0]是否异常，is_exception[1]表示inst[1]是否异常
                                                    // is_exception[0][1]表示译码阶段第一条指令出现异常...... is_exception的位宽每经过一个阶段加一
    input wire [1:0] [1:0] [6:0] exception_cause ,  // 7位宽的异常原因，在csr_defines里定义

    // 来自 dispatch 的信号
    input wire [1:0] invalid_en,  // 无效信号


    // 输出给前端的取指请求信号
    output wire get_data_req,   
    output wire pause_decoder,


    // 输出给 dispatch 的信号
    output reg  [1:0]  dispatch_inst_valid,
    output reg  [1:0]  dispatch_id_valid,       // pc有效信号  

    output reg  [31:0][1:0] dispatch_pc_out ,
    output reg  [31:0][1:0] dispatch_inst_out ,

    output reg  [1:0][2:0]  dispatch_is_exception ,         // 是否异常
    output reg  [6:0][1:0][2:0]  dispatch_exception_cause , // 异常原因

    output reg  [7:0][1:0]  dispatch_aluop ,
    output reg  [2:0][1:0]  dispatch_alusel ,
    output reg  [31:0][1:0] dispatch_imm ,

    output reg  [1:0]  dispatch_reg1_read_en,           // 源寄存器1读使能
    output reg  [1:0]  dispatch_reg2_read_en,           // 源寄存器2读使能
    output reg  [4:0][1:0]  dispatch_reg1_read_addr ,   // 源寄存器1读地址
    output reg  [4:0][1:0]  dispatch_reg2_read_addr ,   // 源寄存器2读地址
    output reg  [1:0]  dispatch_reg_writen_en,          // 寄存器写使能信号（2位）
    output reg  [4:0][1:0]  dispatch_reg_write_addr ,   // 寄存器写地址

    output reg  [1:0]  dispatch_id_pre_taken,           // 分支预测结果（是否跳转）
    output reg  [31:0][1:0] dispatch_id_pre_addr,       // 分支预测目标地址

    output reg  [1:0]  dispatch_is_privilege,           //是否是特权指令
    output reg  [1:0]  dispatch_csr_read_en,            //CSR读使能
    output reg  [1:0]  dispatch_csr_write_en,           //CSR写使能
    output reg  [13:0][1:0] dispatch_csr_addr,          //CSR地址
    output reg  [1:0]  dispatch_is_cnt,                 //是否是计数器
    output reg  [1:0]  dispatch_invtlb_op               //TLB无效操作


);

    //内部信号
    reg  [1:0]  inst_valid;  
    reg  [1:0]  id_valid;       //ID阶段有效信号

    reg  [31:0] pc_out [1:0];
    reg  [31:0] inst_out [1:0];

    reg  [2:0] is_exception_out [1:0];              //是否异常
    reg  [2:0] [6:0]  exception_cause_out [1:0];    //异常原因

    reg  [7:0]  aluop [1:0];
    reg  [2:0]  alusel [1:0];
    reg  [31:0] imm [1:0];

    reg  [1:0]  reg1_read_en;   
    reg  [1:0]  reg2_read_en;   
    reg  [4:0]  reg1_read_addr [1:0];
    reg  [4:0]  reg2_read_addr [1:0];
    reg  [1:0]  reg_writen_en; 
    reg  [4:0]  reg_write_addr [1:0];

    reg  [1:0]  id_pre_taken;       // ID 阶段预测分支是否跳转
    reg  [31:0] pre_addr [1:0];     // ID 阶段预测分支跳转地址

    reg  [1:0]  is_privilege;       // 是否是特权指令
    reg  [1:0]  csr_read_en;        // CSR读使能
    reg  [1:0]  csr_write_en;       // CSR写使能
    reg  [13:0] csr_addr [1:0];     // CSR
    reg  [1:0]  is_cnt;             // 是否是计数器
    reg  [1:0]  invtlb_op ;         // TLB无效

    id u_id_0 (
        // 输入信号
        .valid(valid[0]),

        .pre_taken(pretaken[0]),
        .pre_addr(pre_addr_in[0]),

        .pc(pc[0]),
        .inst(inst[0]),
        
        .is_exception(is_exception[0]),
        .exception_cause(exception_cause[0]),

        // 输出信号
        .inst_valid(inst_valid[0]),
        .id_valid(id_valid[0]),

        .pc_out(pc_out[0]),
        .inst_out(inst_out[0]),

        .is_exception_out(is_exception_out[0]),
        .exception_cause_out(exception_cause_out[0]),

        .aluop(aluop[0]),
        .alusel(alusel[0]),
        .imm(imm[0]),

        .reg1_read_en(reg1_read_en[0]),   
        .reg2_read_en(reg2_read_en[0]),   
        .reg1_read_addr(reg1_read_addr[0]),
        .reg2_read_addr(reg2_read_addr[0]),
        .reg_writen_en (reg_writen_en[0]),  
        .reg_write_addr(reg_write_addr[0]),  

        .id_pre_taken(id_pre_taken[0]), 
        .id_pre_addr(pre_addr[0]), 

        .is_privilege(is_privilege[0]), 
        .csr_read_en(csr_read_en[0]), 
        .csr_write_en(csr_write_en[0]), 
        .csr_addr(csr_addr[0]), 
        .is_cnt(is_cnt[0]), 
        .invtlb_op(invtlb_op[0]) 
    );

    id u_id_1 (
        .valid(valid[1]),

        .pre_taken(pretaken[1]),
        .pre_addr(pre_addr_in[1]),

        .pc(pc[1]),
        .inst(inst[1]),
        
        .is_exception(is_exception[1]),
        .exception_cause(exception_cause[1]),


        .inst_valid(inst_valid[1]),
        .id_valid(id_valid[1]),

        .pc_out(pc_out[1]),
        .inst_out(inst_out[1]),

        .is_exception_out(is_exception_out[1]),
        .exception_cause_out(exception_cause_out[1]),

        .aluop(aluop[1]),
        .alusel(alusel[1]),
        .imm(imm[1]),

        .reg1_read_en(reg1_read_en[0]),   
        .reg2_read_en(reg2_read_en[0]),   
        .reg1_read_addr(reg1_read_addr[0]),
        .reg2_read_addr(reg2_read_addr[0]),
        .reg_writen_en (reg_writen_en[0]),  
        .reg_write_addr(reg_write_addr[0]),  

        .id_pre_taken(id_pre_taken[0]), 
        .id_pre_addr(pre_addr[0]), 
        
        .is_privilege(is_privilege[0]), 
        .csr_read_en(csr_read_en[0]), 
        .csr_write_en(csr_write_en[0]), 
        .csr_addr(csr_addr[0]), 
        .is_cnt(is_cnt[0]), 
        .invtlb_op(invtlb_op[0]) 
    );
    
    // 入队数据，如果要添加信号，加信号加在最前面并且修改`DECODE_DATA_WIDTH的值
    wire [1:0] [`DECODE_DATA_WIDTH:0] enqueue_data;
    assign  enqueue_data[0] =  {
                                exception_cause_out[0], // 201:181      // 这个不知道对不对
                                is_exception_out[0],    // 180:179

                                invtlb_op[0],           // 178
                                is_cnt[0],              // 177
                                csr_addr[0],            // 176:163
                                csr_write_en[0],        // 162
                                csr_read_en[0],         // 161
                                is_privilege[0],        // 160    
                                pre_addr[0],            // 159:128
                                id_pre_taken[0],        // 127
                                
                                reg_write_addr[0],      // 126:122
                                reg_writen_en[0],       // 121
                                reg2_read_addr[0],      // 120:116
                                reg1_read_addr[0],      // 115:111
                                reg2_read_en[0],        // 110
                                reg1_read_en[0],        // 109

                                imm[0],                 // 108:77
                                alusel[0],              // 76:74
                                aluop[0],               // 73:66
                                
                                inst_out[0],            // 65:34
                                pc_out[0],              // 33:2

                                id_valid[0],            // 1
                                inst_valid[0]};         // 0

    assign  enqueue_data[1] =  {
                                exception_cause_out[0], // 201:181      // 这个不知道对不对
                                is_exception_out[0],    // 180:179

                                invtlb_op[1],           // 178
                                is_cnt[1],              // 177
                                csr_addr[1],            // 176:163
                                csr_write_en[1],        // 162
                                csr_read_en[1],         // 161
                                is_privilege[1],        // 160    
                                pre_addr[1],            // 159:128
                                id_pre_taken[1],        // 127
                                
                                reg_write_addr[1],      // 126:122
                                reg_writen_en[1],       // 121
                                reg2_read_addr[1],      // 120:116
                                reg1_read_addr[1],      // 115:111
                                reg2_read_en[1],        // 110
                                reg1_read_en[1],        // 109

                                imm[1],                 // 108:77
                                alusel[1],              // 76:74
                                aluop[1],               // 73:66
                                
                                inst_out[1],            // 65:34
                                pc_out[1],              // 33:2

                                id_valid[1],            // 1
                                inst_valid[1]};         // 0                  
    // 出队数据
    wire  [1:0] [`DECODE_DATA_WIDTH:0] dequeue_data;

    wire fifo_rst;
    assign fifo_rst = rst || flush;
    reg [1:0] enqueue_en;   //入队使能信号
    reg get_data_req_o;
    reg full;
    reg empty;

    dram_fifo u_queue(
        .clk(clk),
        .rst(fifo_rst),
        .flush(flush),

        .enqueue_en(enqueue_en),
        .enqueue_data(enqueue_data),

        .invalid_en(invalid_en),
        .dequeue_data(dequeue_data),

        .get_data_req(get_data_req_o),
        .full(full),
        .empty(empty)
    );
    
    // 传递给前端的取指请求信号
    assign get_data_req = get_data_req_o;

    always @(*) begin
        enqueue_en[0] = !full && valid[0];
        enqueue_en[1] = !full && valid[1];
    end

    // 出队数据
    wire    [`DECODE_DATA_WIDTH:0]dequeue_data1; 
    wire    [`DECODE_DATA_WIDTH:0]dequeue_data2;
    assign  dequeue_data1 = dequeue_data[0];
    assign  dequeue_data2 = dequeue_data[1];

    // 分解出队数据
    always @(*) begin
        dispatch_inst_valid[0]      =   dequeue_data1[0];
        dispatch_inst_valid[1]      =   dequeue_data2[0];
        dispatch_id_valid[0]        =   dequeue_data1[1];
        dispatch_id_valid[1]        =   dequeue_data2[1];
        dispatch_pc_out[0]          =   dequeue_data1[33:2];
        dispatch_pc_out[1]          =   dequeue_data2[33:2];
        dispatch_inst_out[0]        =   dequeue_data1[65:34];
        dispatch_inst_out[1]        =   dequeue_data2[65:34];
        dispatch_aluop[0]           =   dequeue_data1[73:66];
        dispatch_aluop[1]           =   dequeue_data2[73:66];
        dispatch_alusel[0]          =   dequeue_data1[76:74];
        dispatch_alusel[1]          =   dequeue_data2[76:74];
        dispatch_imm[0]             =   dequeue_data1[108:77];
        dispatch_imm[1]             =   dequeue_data2[108:77];
        dispatch_reg1_read_en[0]    =   dequeue_data1[109];   
        dispatch_reg1_read_en[1]    =   dequeue_data2[109];   
        dispatch_reg2_read_en[0]    =   dequeue_data2[110];   
        dispatch_reg2_read_en[1]    =   dequeue_data2[110];   
        dispatch_reg1_read_addr[0]  =   dequeue_data1[115:111];
        dispatch_reg1_read_addr[1]  =   dequeue_data1[115:111];
        dispatch_reg2_read_addr[0]  =   dequeue_data2[120:116];
        dispatch_reg2_read_addr[1]  =   dequeue_data2[120:116];
        dispatch_reg_writen_en[0]   =   dequeue_data1[121];
        dispatch_reg_writen_en[1]   =   dequeue_data2[121];  
        dispatch_reg_write_addr[0]  =   dequeue_data1[126:122];
        dispatch_reg_write_addr[1]  =   dequeue_data1[126:122];
        dispatch_id_pre_taken[0]    =   dequeue_data1[127];
        dispatch_id_pre_taken[1]    =   dequeue_data2[127];
        dispatch_id_pre_addr[0]     =   dequeue_data1[159:128];
        dispatch_id_pre_addr[1]     =   dequeue_data2[159:128];
        dispatch_is_privilege[0]    =   dequeue_data1[160];
        dispatch_is_privilege[1]    =   dequeue_data2[160];
        dispatch_csr_read_en[0]     =   dequeue_data1[161];
        dispatch_csr_read_en[1]     =   dequeue_data2[161];
        dispatch_csr_write_en[0]    =   dequeue_data1[162];
        dispatch_csr_write_en[1]    =   dequeue_data2[162];
        dispatch_csr_addr[0]        =   equeue_data1[176:163];
        dispatch_csr_addr[1]        =   dequeue_data2[176:163];
        dispatch_is_cnt[0]          =   dequeue_data1[177];
        dispatch_is_cnt[1]          =   dequeue_data2[177];
        dispatch_invtlb_op[0]       =   dequeue_data1[178];
        dispatch_invtlb_op[1]       =   dequeue_data2[178];
        dispatch_is_exception[0]    =   dequeue_data1[180:179];
        dispatch_is_exception[1]    =   dequeue_data2[180:179];
        dispatch_exception_cause[0] =   dequeue_data1[201:181];
        dispatch_exception_cause[1] =   dequeue_data2[201:181];
    end



    assign pause_decoder = full;


endmodule