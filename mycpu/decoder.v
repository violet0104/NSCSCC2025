`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module decoder (
    input wire clk,
    input wire rst,

    input wire flush, //强制更新信号

    // 前端传递的数据
    input wire [31:0] pc1,
    input wire [31:0] pc2,
    input wire [31:0] inst1,
    input wire [31:0] inst2,
    input wire [1:0]  valid,                        //  前端传递的数据有效信号
    input wire [1:0]  pretaken,                     // 鍓前端传递的分支预测结果（是否跳转）
    input wire [31:0] pre_addr_in1 ,           // 前端传递的分支预测目标地址
    input wire [31:0] pre_addr_in2 ,

    input wire [1:0]  is_exception_in1 ,          // 第一条指令的异常信号
    input wire [1:0]  is_exception_in2 ,          // 第二条指令的异常信号

    input wire [6:0]  pc_exception_cause_in1 ,        // 异常原因
    input wire [6:0]  pc_exception_cause_in2 ,        

    input wire [6:0]  instbuffer_exception_cause_in1 ,   
    input wire [6:0]  instbuffer_exception_cause_in2 ,

    //来自 dispatch 的信号
    input wire [1:0] invalid_en,  // 无效信号


    // 输出给前端的取指请求信号
    output wire get_data_req,   
    output wire pause_decoder,


    //  输出给 dispatch 的信号
    output reg  [1:0]  dispatch_id_valid,       // pc有效信号

    output reg  [31:0] dispatch_pc_out1 ,
    output reg  [31:0] dispatch_pc_out2 ,
    output reg  [31:0] dispatch_inst_out1 ,
    output reg  [31:0] dispatch_inst_out2 ,

    output reg  [2:0]  is_exception_o1 ,            //  是否异常
    output reg  [2:0]  is_exception_o2 ,         
    output reg  [6:0]  pc_exception_cause_o1 ,         // 常原因
    output reg  [6:0]  pc_exception_cause_o2 ,
    output reg  [6:0]  instbuffer_exception_cause_o1,
    output reg  [6:0]  instbuffer_exception_cause_o2,
    output reg  [6:0]  decoder_exception_cause_o1,
    output reg  [6:0]  decoder_exception_cause_o2, 

    output reg  [7:0]  dispatch_aluop1 ,
    output reg  [7:0]  dispatch_aluop2 ,
    output reg  [2:0]  dispatch_alusel1 ,
    output reg  [2:0]  dispatch_alusel2 ,
    output reg  [31:0] dispatch_imm1 ,
    output reg  [31:0] dispatch_imm2 ,

    output reg  [1:0]  dispatch_reg_read_en1,           // 第一条指令的读使能
    output reg  [1:0]  dispatch_reg_read_en2,           // 第二条指令的读使能
    output reg  [4:0]  dispatch_reg_read_addr1_1 ,      // 第一条指令的两个读地址
    output reg  [4:0]  dispatch_reg_read_addr1_2 ,
    output reg  [4:0]  dispatch_reg_read_addr2_1 ,      // 第二条指令的两个读地址
    output reg  [4:0]  dispatch_reg_read_addr2_2,
    output reg  [1:0]  dispatch_reg_writen_en,          // 寄存器写使能信号（2位）
    output reg  [4:0]  dispatch_reg_write_addr1 ,       // 寄存器写地址
    output reg  [4:0]  dispatch_reg_write_addr2 ,

    output reg  [1:0]  dispatch_id_pre_taken,           // 分支预测结果（是否跳转）
    output reg  [31:0] dispatch_id_pre_addr1,       // 分支预测目标地址
    output reg  [31:0] dispatch_id_pre_addr2,

    output reg  [1:0]  dispatch_is_privilege,           //是否是特权指令
    output reg  [1:0]  dispatch_csr_read_en,            //CSR读使能
    output reg  [1:0]  dispatch_csr_write_en,           //CSR写使能
    output reg  [13:0] dispatch_csr_addr1,          //CSR地址
    output reg  [13:0] dispatch_csr_addr2,
    output reg  [1:0]  dispatch_is_cnt,                 //是否是计数器
    output reg  [4:0]  dispatch_invtlb_op1,               //TLB无效操作
    output reg  [4:0]  dispatch_invtlb_op2
);

    //内部信号
    wire  id_valid1;       //ID阶段有效信号
    wire  id_valid2;

    wire  valid1_i ;
    assign valid1_i = valid[0];
    wire  valid2_i ;
    assign valid2_i = valid[1];

    wire pre_taken1_i;
    assign pre_taken1_i = pretaken[0];
    wire pre_taken2_i;
    assign pre_takne2_i = pretaken[1];

    wire  [31:0] pc_out1;
    wire  [31:0] pc_out2;
    wire  [31:0] inst_out1;
    wire  [31:0] inst_out2;

    wire  [2:0] is_exception1;               //是否异常
    wire  [2:0] is_exception2;              
    wire  [6:0] pc_exception_cause1;         //异常原因
    wire  [6:0] pc_exception_cause2;
    wire  [6:0] instbuffer_exception_cause1; 
    wire  [6:0] instbuffer_exception_cause2;
    wire  [6:0] decoder_exception_cause1;
    wire  [6:0] decoder_exception_cause2;

    wire  [7:0]  aluop1;
    wire  [7:0]  aluop2;
    wire  [2:0]  alusel1;
    wire  [2:0]  alusel2;
    wire  [31:0] imm1;
    wire  [31:0] imm2;

    wire  [1:0]  reg_read_en1;          // 第一条指令的读使能
    wire  [1:0]  reg_read_en2;          // 第二条指令的读使能
    wire  [4:0]  reg_read_addr1_1;      // 第一条指令的读地址
    wire  [4:0]  reg_read_addr1_2;
    wire  [4:0]  reg_read_addr2_1;      // 第二条指令的读地址
    wire  [4:0]  reg_read_addr2_2;
    wire  [1:0]  reg_writen_en; 
    wire  [4:0]  reg_write_addr1;
    wire  [4:0]  reg_write_addr2;

    wire  id_pre_taken1;       // ID 阶段预测分支是否跳转
    wire  id_pre_taken2;
    wire  [31:0] pre_addr1;     // ID 阶段预测分支跳转地址
    wire  [31:0] pre_addr2;

    wire  is_privilege1;       // 是否是特权指令
    wire  is_privilege2;
    wire  csr_read_en1 ;        // CSR读使能
    wire  csr_read_en2 ;
    wire  csr_write_en1;       //CSR写使能
    wire  csr_write_en2;
    wire  [13:0] csr_addr1;     // CSR
    wire  [13:0] csr_addr2;
    wire  is_cnt1;             // 否是计数器
    wire  is_cnt2;
    wire  [4:0]  invtlb_op1;         // TLB无效\
    wire  [4:0]  invtlb_op2;

    id u_id_0 (
        // 输入信号
        .valid(valid1_i),

        .pre_taken(pre_taken1_i),
        .pre_addr(pre_addr_in1),

        .pc(pc1),
        .inst(inst1),
        
        .is_exception(is_exception_in1),
        .pc_exception_cause(pc_exception_cause_in1),
        .instbuffer_exception_cause(instbuffer_exception_cause_in1),


        // 输出信号
        .id_valid(id_valid1),

        .pc_out(pc_out1),
        .inst_out(inst_out1),

        .is_exception_out(is_exception1),
        .pc_exception_cause_out(pc_exception_cause1),
        .instbuffer_exception_cause_out(instbuffer_exception_cause1),
        .decoder_exception_cause_out(decoder_exception_cause1),

        .aluop(aluop1),
        .alusel(alusel1),
        .imm(imm1),

        .reg1_read_en(reg_read_en1[0]),   
        .reg2_read_en(reg_read_en1[1]),   
        .reg1_read_addr(reg_read_addr1_1),
        .reg2_read_addr(reg_read_addr1_2),
        .reg_writen_en (reg_writen_en[0]),  
        .reg_write_addr(reg_write_addr1),  

        .id_pre_taken(id_pre_taken1), 
        .id_pre_addr(pre_addr1), 

        .is_privilege(is_privilege1), 
        .csr_read_en(csr_read_en1), 
        .csr_write_en(csr_write_en1), 
        .csr_addr(csr_addr1), 
        .is_cnt(is_cnt1), 
        .invtlb_op(invtlb_op1) 
    );

    id u_id_1 (
        .valid(valid2_i),

        .pre_taken(pre_taken2_i),
        .pre_addr(pre_addr_in2),

        .pc(pc2),
        .inst(inst2),
        
        .is_exception(is_exception_in2),
        .pc_exception_cause(pc_exception_cause_in2),
        .instbuffer_exception_cause(instbuffer_exception_cause_in2),


        .id_valid(id_valid2),

        .pc_out(pc_out2),
        .inst_out(inst_out2),

        .is_exception_out(is_exception2),
        .pc_exception_cause_out(pc_exception_cause2),
        .instbuffer_exception_cause_out(instbuffer_exception_cause2),
        .decoder_exception_cause_out(decoder_exception_cause2),

        .aluop(aluop2),
        .alusel(alusel2),
        .imm(imm2),

        .reg1_read_en(reg_read_en2[0]),   
        .reg2_read_en(reg_read_en2[1]),   
        .reg1_read_addr(reg_read_addr2_1),
        .reg2_read_addr(reg_read_addr2_2),
        .reg_writen_en (reg_writen_en[1]),  
        .reg_write_addr(reg_write_addr2),  

        .id_pre_taken(id_pre_taken2), 
        .id_pre_addr(pre_addr2), 
        
        .is_privilege(is_privilege2), 
        .csr_read_en(csr_read_en2), 
        .csr_write_en(csr_write_en2), 
        .csr_addr(csr_addr2), 
        .is_cnt(is_cnt2), 
        .invtlb_op(invtlb_op2) 
    );
    /////////////////////////////////////////////
    // 入队数据，如果要添加信号，加信号加在最前面并且修改`DECODE_DATA_WIDTH的值
    wire [`DECODE_DATA_WIDTH - 1:0] enqueue_data1;
    wire [`DECODE_DATA_WIDTH - 1:0] enqueue_data2;
    assign  enqueue_data1 =  {
                                decoder_exception_cause1,     // 205:199     
                                instbuffer_exception_cause1,  // 198:192
                                pc_exception_cause1,          // 191:185      
                                is_exception1,    // 184:182

                                invtlb_op1,           // 181:177
                                is_cnt1,              // 176
                                csr_addr1,            // 175:162
                                csr_write_en1,        // 161
                                csr_read_en1,         // 160
                                is_privilege1,        // 159    
                                pre_addr1,            // 158:127
                                id_pre_taken1,        // 126
                                
                                reg_write_addr1,      // 125:121
                                reg_writen_en[0],     // 120
                                reg_read_addr1_2,     // 119:115
                                reg_read_addr1_1,     // 114:110
                                reg_read_en1,         // 109:108

                                imm1,                 // 107:76
                                alusel1,              // 75:73
                                aluop1,               // 72:65
                                
                                inst_out1,            // 64:33
                                pc_out1,              // 32:1

                                id_valid1};           // 0

    assign  enqueue_data2 =  {
                                decoder_exception_cause2,     // 205:199     
                                instbuffer_exception_cause2,  // 198:192
                                pc_exception_cause2,          // 191:185    
                                is_exception2,    // 184:182

                                invtlb_op2,           // 181:177
                                is_cnt2,              // 176
                                csr_addr2,            // 175:162
                                csr_write_en2,        // 161
                                csr_read_en2,         // 160
                                is_privilege2,        // 159    
                                pre_addr2,            // 158:127
                                id_pre_taken2,        // 126
                                
                                reg_write_addr2,      // 125:121
                                reg_writen_en[1],     // 120
                                reg_read_addr2_2,     // 119:115
                                reg_read_addr2_1,     // 114:110
                                reg_read_en2,         // 109:108

                                imm2,                 // 107:76
                                alusel2,              // 75:73
                                aluop2,               // 72:65
                                
                                inst_out2,            // 64:33
                                pc_out2,              // 32:1

                                id_valid2};           // 0      

    // 出队数据
    wire [`DECODE_DATA_WIDTH - 1:0] dequeue_data1;
    wire [`DECODE_DATA_WIDTH - 1:0] dequeue_data2;

    wire fifo_rst;
    assign fifo_rst = rst || flush;
    reg [1:0] enqueue_en;   //入队使能信号
    wire get_data_req_o;
    wire full;
    wire empty;

    dram_fifo u_queue(
        .clk(clk),
        .rst(fifo_rst),
        .flush(flush),

        .enqueue_en(enqueue_en),
        .enqueue_data1(enqueue_data1),
        .enqueue_data2(enqueue_data2),

        .invalid_en(invalid_en),
        .dequeue_data1(dequeue_data1),
        .dequeue_data2(dequeue_data2),

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


    // 分解出队数据
    always @(*) begin
        dispatch_id_valid[0]        =   dequeue_data1[0];
        dispatch_id_valid[1]        =   dequeue_data2[0];
        dispatch_pc_out1            =   dequeue_data1[32:1];
        dispatch_pc_out2            =   dequeue_data2[32:1];
        dispatch_inst_out1          =   dequeue_data1[64:33];
        dispatch_inst_out2          =   dequeue_data2[64:33];
        dispatch_aluop1             =   dequeue_data1[72:65];
        dispatch_aluop2             =   dequeue_data2[72:65];
        dispatch_alusel1            =   dequeue_data1[75:73];
        dispatch_alusel2            =   dequeue_data2[75:73];
        dispatch_imm1               =   dequeue_data1[107:76];
        dispatch_imm2               =   dequeue_data2[107:76];
        dispatch_reg_read_en1       =   dequeue_data1[109:108];   
        dispatch_reg_read_en2       =   dequeue_data2[109:108];     
        dispatch_reg_read_addr1_1   =   dequeue_data1[114:110];
        dispatch_reg_read_addr1_2   =   dequeue_data1[119:115];
        dispatch_reg_read_addr2_1   =   dequeue_data2[114:110];
        dispatch_reg_read_addr2_2   =   dequeue_data2[119:115];
        dispatch_reg_writen_en[0]   =   dequeue_data1[120];
        dispatch_reg_writen_en[1]   =   dequeue_data2[120];  
        dispatch_reg_write_addr1    =   dequeue_data1[125:121];
        dispatch_reg_write_addr2    =   dequeue_data2[125:121];
        dispatch_id_pre_taken[0]    =   dequeue_data1[126];
        dispatch_id_pre_taken[1]    =   dequeue_data2[126];
        dispatch_id_pre_addr1       =   dequeue_data1[158:127];
        dispatch_id_pre_addr2       =   dequeue_data2[158:127];
        dispatch_is_privilege[0]    =   dequeue_data1[159];
        dispatch_is_privilege[1]    =   dequeue_data2[159];
        dispatch_csr_read_en[0]     =   dequeue_data1[160];
        dispatch_csr_read_en[1]     =   dequeue_data2[160];
        dispatch_csr_write_en[0]    =   dequeue_data1[161];
        dispatch_csr_write_en[1]    =   dequeue_data2[161];
        dispatch_csr_addr1          =   dequeue_data1[175:162];
        dispatch_csr_addr2          =   dequeue_data2[175:162];
        dispatch_is_cnt[0]          =   dequeue_data1[176];
        dispatch_is_cnt[1]          =   dequeue_data2[176];
        dispatch_invtlb_op1         =   dequeue_data1[181:177];
        dispatch_invtlb_op2         =   dequeue_data2[181:177];
        
        is_exception_o1                 =   dequeue_data1[184:182];
        is_exception_o2                 =   dequeue_data2[184:182];
        pc_exception_cause_o1           =   dequeue_data1[191:185];
        pc_exception_cause_o2           =   dequeue_data2[191:185];
        instbuffer_exception_cause_o1   =   dequeue_data1[198:192];
        instbuffer_exception_cause_o2   =   dequeue_data2[198:192];
        decoder_exception_cause_o1      =   dequeue_data1[205:199];
        decoder_exception_cause_o2      =   dequeue_data2[205:199];
    end

    assign pause_decoder = full;


endmodule