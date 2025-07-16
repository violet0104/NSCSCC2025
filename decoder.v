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
    input wire [1:0]  valid,                        // 前端传递的数据有效信号
    input wire [1:0]  pretaken,                     // 前端传递的分支预测结果（是否跳转）
    input wire [31:0] pre_addr_in1 ,           // 前端传递的分支预测目标地址
    input wire [31:0] pre_addr_in2 ,

    input wire [1:0]  is_exception_in1 ,          // 第一条指令的异常信号
    input wire [1:0]  is_exception_in2 ,          // 第二条指令的异常信号

    input wire [6:0]  pc_exception_cause_in1 ,        // 异常原因
    input wire [6:0]  pc_exception_cause_in2 ,        

    input wire [6:0]  instbuffer_exception_cause_in1 ,   
    input wire [6:0]  instbuffer_exception_cause_in2 ,

    // 来自 dispatch 的信号
    input wire [1:0] invalid_en,  // 无效信号


    // 输出给前端的取指请求信号
    output wire get_data_req,   
    output wire pause_decoder,


    // 输出给 dispatch 的信号
    output reg  [1:0]  dispatch_id_valid,       // pc有效信号  

    output reg  [31:0] dispatch_pc_out1 ,
    output reg  [31:0] dispatch_pc_out2 ,
    output reg  [31:0] dispatch_inst_out1 ,
    output reg  [31:0] dispatch_inst_out2 ,

    output reg  [2:0]  is_exception_o1 ,            // 是否异常
    output reg  [2:0]  is_exception_o2 ,         
    output reg  [6:0]  pc_exception_cause_o1 ,         // 异常原因
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

    output reg  [1:0]  dispatch_reg1_read_en,           // 源寄存器1读使能
    output reg  [1:0]  dispatch_reg2_read_en,           // 源寄存器2读使能
    output reg  [4:0]  dispatch_reg1_read_addr1 ,   // 源寄存器1读地址
    output reg  [4:0]  dispatch_reg1_read_addr2 ,
    output reg  [4:0]  dispatch_reg2_read_addr1 ,   // 源寄存器2读地址
    output reg  [4:0]  dispatch_reg2_read_addr2,
    output reg  [1:0]  dispatch_reg_writen_en,          // 寄存器写使能信号（2位）
    output reg  [4:0]  dispatch_reg_write_addr1 ,   // 寄存器写地址
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
    wire  [1:0]  id_valid;       //ID阶段有效信号

    reg  [31:0] pc_out [1:0];
    reg  [31:0] inst_out [1:0];

    reg  [2:0] is_exception1;               //是否异常
    reg  [2:0] is_exception2;              
    reg  [6:0] pc_exception_cause1;         //异常原因
    reg  [6:0] pc_exception_cause2;
    reg  [6:0] instbuffer_exception_cause1; 
    reg  [6:0] instbuffer_exception_cause2;
    reg  [6:0] decoder_exception_cause1;
    reg  [6:0] decoder_exception_cause2;

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
    reg  [4:0]  invtlb_op [1:0];         // TLB无效

    id u_id_0 (
        // 输入信号
        .valid(valid[0]),

        .pre_taken(pretaken[0]),
        .pre_addr(pre_addr_in1),

        .pc(pc1),
        .inst(inst1),
        
        .is_exception(is_exception_in1),
        .pc_exception_cause(pc_exception_cause_in1),
        .instbuffer_exception_cause(instbuffer_exception_cause_in1),


        // 输出信号
        .id_valid(id_valid[0]),

        .pc_out(pc_out[0]),
        .inst_out(inst_out[0]),

        .is_exception_out(is_exception1),
        .pc_exception_cause_out(pc_exception_cause1),
        .instbuffer_exception_cause_out(instbuffer_exception_cause1),
        .decoder_exception_cause_out(decoder_exception_cause1),

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
        .pre_addr(pre_addr_in2),

        .pc(pc2),
        .inst(inst2),
        
        .is_exception(is_exception_in2),
        .pc_exception_cause(pc_exception_cause_in2),
        .instbuffer_exception_cause(instbuffer_exception_cause_in2),


        .id_valid(id_valid[1]),

        .pc_out(pc_out[1]),
        .inst_out(inst_out[1]),

        .is_exception_out(is_exception2),
        .pc_exception_cause_out(pc_exception_cause2),
        .instbuffer_exception_cause_out(instbuffer_exception_cause2),
        .decoder_exception_cause_out(decoder_exception_cause2),

        .aluop(aluop[1]),
        .alusel(alusel[1]),
        .imm(imm[1]),

        .reg1_read_en(reg1_read_en[1]),   
        .reg2_read_en(reg2_read_en[1]),   
        .reg1_read_addr(reg1_read_addr[1]),
        .reg2_read_addr(reg2_read_addr[1]),
        .reg_writen_en (reg_writen_en[1]),  
        .reg_write_addr(reg_write_addr[1]),  

        .id_pre_taken(id_pre_taken[1]), 
        .id_pre_addr(pre_addr[1]), 
        
        .is_privilege(is_privilege[1]), 
        .csr_read_en(csr_read_en[1]), 
        .csr_write_en(csr_write_en[1]), 
        .csr_addr(csr_addr[1]), 
        .is_cnt(is_cnt[1]), 
        .invtlb_op(invtlb_op[1]) 
    );
    
    // 入队数据，如果要添加信号，加信号加在最前面并且修改`DECODE_DATA_WIDTH的值
    wire [`DECODE_DATA_WIDTH:0] enqueue_data [1:0];
    assign  enqueue_data[0] =  {
                                decoder_exception_cause1,     // 205:199     
                                instbuffer_exception_cause1,  // 198:192
                                pc_exception_cause1,          // 191:185      
                                is_exception1,    // 184:182

                                invtlb_op[0],           // 181:177
                                is_cnt[0],              // 176
                                csr_addr[0],            // 175:162
                                csr_write_en[0],        // 161
                                csr_read_en[0],         // 160
                                is_privilege[0],        // 159    
                                pre_addr[0],            // 158:127
                                id_pre_taken[0],        // 126
                                
                                reg_write_addr[0],      // 125:121
                                reg_writen_en[0],       // 120
                                reg2_read_addr[0],      // 119:115
                                reg1_read_addr[0],      // 114:110
                                reg2_read_en[0],        // 109
                                reg1_read_en[0],        // 108

                                imm[0],                 // 107:76
                                alusel[0],              // 75:73
                                aluop[0],               // 72:65
                                
                                inst_out[0],            // 64:33
                                pc_out[0],              // 32:1

                                id_valid[0]};           // 0

    assign  enqueue_data[1] =  {
                                decoder_exception_cause2,     // 205:199     
                                instbuffer_exception_cause2,  // 198:192
                                pc_exception_cause2,          // 191:185    
                                is_exception2,    // 184:182

                                invtlb_op[1],           // 181:177
                                is_cnt[1],              // 176
                                csr_addr[1],            // 175:162
                                csr_write_en[1],        // 161
                                csr_read_en[1],         // 160
                                is_privilege[1],        // 159    
                                pre_addr[1],            // 158:127
                                id_pre_taken[1],        // 126
                                
                                reg_write_addr[1],      // 125:121
                                reg_writen_en[1],       // 120
                                reg2_read_addr[1],      // 119:115
                                reg1_read_addr[1],      // 114:110
                                reg2_read_en[1],        // 109
                                reg1_read_en[1],        // 108

                                imm[1],                 // 107:76
                                alusel[1],              // 75:73
                                aluop[1],               // 72:65
                                
                                inst_out[1],            // 64:33
                                pc_out[1],              // 32:1

                                id_valid[1]};           // 0      

    // 出队数据
    wire [`DECODE_DATA_WIDTH:0] dequeue_data [1:0];

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
        .enqueue_data1(enqueue_data[0]),
        .enqueue_data2(enqueue_data[1]),

        .invalid_en(invalid_en),
        .dequeue_data1(dequeue_data[0]),
        .dequeue_data2(dequeue_data[1]),

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
        dispatch_reg1_read_en[0]    =   dequeue_data1[108];   
        dispatch_reg1_read_en[1]    =   dequeue_data2[108];   
        dispatch_reg2_read_en[0]    =   dequeue_data1[109];   
        dispatch_reg2_read_en[1]    =   dequeue_data2[109];   
        dispatch_reg1_read_addr1    =   dequeue_data1[114:110];
        dispatch_reg1_read_addr2    =   dequeue_data2[114:110];
        dispatch_reg2_read_addr1    =   dequeue_data1[119:115];
        dispatch_reg2_read_addr2    =   dequeue_data2[119:115];
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