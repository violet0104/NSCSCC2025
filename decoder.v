`timescale 1ps/1ps

module decoder (
    input wire clk,
    input wire rst,

    input wire flush, //强制更新信号

    input wire [31:0][1:0] pc,
    input wire [31:0][1:0] inst ,
    input wire [1:0]  valid,
    input wire [1:0]  pretaken,
    input wire [31:0][1:0] pre_addr_in ,
    input wire [1:0][1:0]  is_exception ,
    input wire [6:0][1:0][1:0]  exception_cause ,

    input wire [1:0] invalid_en,  //无效信号

    output wire pause_decoder, //通知暂停取指信号

    output reg  [1:0]  dispatch_inst_valid,
    output reg  [1:0]  dispatch_id_valid, //pc有效信号  
    output reg  [31:0][1:0] dispatch_pc_out ,
    output reg  [6:0][1:0][2:0]  dispatch_exception_cause , //异常原因
    output reg  [1:0][2:0]  dispatch_is_exception , //是否异常
    output reg  [31:0][1:0] dispatch_inst_out ,
    output reg  [7:0][1:0]  dispatch_aluop ,
    output reg  [2:0][1:0]  dispatch_alusel ,
    output reg  [31:0][1:0] dispatch_imm ,
    output reg  [1:0]  dispatch_reg1_read_en,   //rR1寄存器读使能
    output reg  [1:0]  dispatch_reg2_read_en,   //rR2寄存器读使能
    output reg  [4:0][1:0]  dispatch_reg1_read_addr ,
    output reg  [4:0][1:0]  dispatch_reg2_read_addr ,
    output reg  [1:0]  dispatch_reg_writen_en,  //寄存器写使能信号
    output reg  [4:0][1:0]  dispatch_reg_write_addr ,
    output reg  [1:0]  dispatch_id_pre_taken,
    output reg  [31:0][1:0] dispatch_id_pre_addr,
    output reg  [1:0]  dispatch_is_privilege, //特权指令标志
    output reg  [1:0]  dispatch_csr_read_en, //CSR寄存器读使能
    output reg  [1:0]  dispatch_csr_write_en, //CSR寄存器写使能
    output reg  [13:0][1:0] dispatch_csr_addr, //CSR
    output reg  [1:0]  dispatch_is_cnt, //是否是计数器寄存器
    output reg  [1:0]  dispatch_invtlb_op  //TLB无效操作


);
    //内部信号
    reg  [1:0]  inst_valid;  
    reg  [1:0]  id_valid; //ID阶段有效信号
    reg  [31:0] pc_out [1:0];
    reg  [1:0]  is_exception_out [2:0]; //是否异常
    reg  [6:0]  exception_cause_out [1:0][2:0]; //异常原因
    reg  [31:0] inst_out [1:0];
    reg  [1:0]  reg_writen_en; 
    reg  [7:0]  aluop [1:0];
    reg  [2:0]  alusel [1:0];
    reg  [31:0] imm [1:0];
    reg  [1:0]  reg1_read_en;   
    reg  [1:0]  reg2_read_en;   
    reg  [4:0]  reg1_read_addr [1:0];
    reg  [4:0]  reg2_read_addr [1:0];
    reg  [1:0]  id_pre_taken; //ID阶段预测跳转信号
    reg  [31:0] pre_addr [1:0]; //ID阶段预测
    reg  [4:0]  reg_write_addr [1:0];
    reg  [1:0]  is_privilege; //特权指令标志
    reg  [1:0]  csr_read_en; //CSR寄存器读使能
    reg  [1:0]  csr_write_en; //CSR寄存器写使能
    reg  [13:0] csr_addr [1:0]; //CSR
    reg  [1:0]  is_cnt; //是否是计数器寄存器
    reg  [1:0]  invtlb_op ; //TLB无效

    id u_id1 (
        .pc(pc[0]),
        .inst(inst[0]),
        .valid(valid[0]),
        .pre_taken(pretaken[0]),
        .pre_addr(pre_addr[0]),
        .is_exception(is_exception[0]),
        .exception_cause(exception_cause[0]),

        .inst_valid(inst_valid[0]),
        .id_valid(id_valid[0]),
        .pc_out(pc_out[0]),
        .is_exception_out(is_exception_out[0]),
        .exception_cause_out(exception_cause_out[0]),
        .inst_out(inst_out[0]),
        .reg_writen_en (reg_writen_en[0]),  //寄存器写使能信号
        .aluop(aluop[0]),
        .alusel(alusel[0]),
        .imm(imm[0]),
        .reg1_read_en(reg1_read_en[0]),   //rR1寄存器读使能
        .reg2_read_en(reg2_read_en[0]),   //rR2寄存器读使能
        .reg1_read_addr(reg1_read_addr[0]),
        .reg2_read_addr(reg2_read_addr[0]),
        .id_pre_taken(id_pre_taken[0]), //ID阶段预测跳转信号
        .id_pre_addr(pre_addr[0]), //ID阶段预测
        .reg_write_addr(reg_write_addr[0]),  //目的寄存器地址
        .is_privilege(is_privilege[0]), //特权指令标志
        .csr_read_en(csr_read_en[0]), //CSR寄存器读使能
        .csr_write_en(csr_write_en[0]), //CSR寄存器写使能
        .csr_addr(csr_addr[0]), //CSR
        .is_cnt(is_cnt[0]), //是否是计数器寄存器
        .invtlb_op(invtlb_op[0]) //TLB无效操作
    );

    id u_id2 (
        .pc(pc[1]),
        .inst(inst[1]),
        .valid(valid[1]),
        .pre_taken(pretaken[1]),
        .pre_addr(pre_addr[1]),
        .is_exception(is_exception[1]),
        .exception_cause(exception_cause[1]),

        .inst_valid(inst_valid[1]),
        .id_valid(id_valid[1]),
        .pc_out(pc_out[1]),
        .is_exception(is_exception_out[1]),
        .exception_cause(exception_cause_out[1]),
        .inst_out(inst_out[1]),
        .reg_writen_en (reg_writen_en[1]),  //寄存器写使能信号
        .aluop(aluop[1]),
        .alusel(alusel[1]),
        .imm(imm[1]),
        .reg1_read_en(reg1_read_en[1]),   //rR1寄存器读使能
        .reg2_read_en(reg2_read_en[1]),   //rR2寄存器读使能
        .reg1_read_addr(reg1_read_addr[1]),
        .reg2_read_addr(reg2_read_addr[1]),
        .id_pre_taken(id_pre_taken[1]), //ID阶段预测跳转信号
        .id_pre_addr(pre_addr[1]), //ID阶段预测
        .reg_write_addr(reg_write_addr[1]),  //目的寄存器地址
        .is_privilege(is_privilege[1]), //特权指令标志
        .csr_read_en(csr_read_en[1]), //CSR寄存器读使
        .csr_write_en(csr_write_en[1]), //CSR寄存器写使能
        .csr_addr(csr_addr[1]), //CSR
        .is_cnt(is_cnt[1]), //是否是计数器寄存器
        .invtlb_op(invtlb_op[1]) //TLB无效操作
    );

    // 入队数据，如果要添加信号，加信号加在最前面并且修改`DECODE_DATA_WIDTH的值
    wire [`DECODE_DATA_WIDTH - 1] enqueue_data [1:0];
    assign  enqueue_data[0] =  {
                                reg_write_addr[0],      // 125:121
                                reg_writen_en[0],       // 120
                                reg2_read_addr[0],      // 119:115
                                reg1_read_addr[0],      // 114:110
                                reg2_read_en[0],        // 109
                                reg1_read_en[0],        // 108
                                imm[0],                 // 107:76
                                alusel[0],              // 75:73
                                aluop[0],               // 72:65
                                inst_valid[0],           // 64
                                inst_out[0],            // 63:32
                                pc_out[0]};             // 31:0
    assign  enqueue_data[1] =  {
                                reg_write_addr[0],      
                                reg_writen_en[0],       
                                reg2_read_addr[0],      
                                reg1_read_addr[0],       
                                reg2_read_en[0],         
                                reg1_read_en[0],        
                                imm[0],                 
                                alusel[0],              
                                aluop[0],    
                                inst_valid[0],                
                                inst_out[0],            
                                pc_out[0]};                   
    // 出队数据
    wire [`DECODE_DATA_WIDTH - 1] dequeue_data [1:0];

    reg [1:0] enqueue_en; //入队使能信号

    reg full;
    reg empty;
    wire fifo_rst;
    assign fifo_rst = rst || flush;

    dram_fifo u_queue(
        .clk(clk),
        .rst(fifo_rst),
        .flush(flush),

        .enqueue_en(enqueue_en),
        .enqueue_data(enqueue_data),

        .invalid_en(invalid_en),
        .dequeue_data(dequeue_data),

        .full(full),
        .empty(empty)
    );

    enqueue_en[0] = !full && valid[0];
    enqueue_en[1] = !full && valid[1];

    wire    [125:0]dequeue_data1; 
    wire    [125:0]dequeue_data2;
    assign  dequeue_data1 = dequeue_data[0];
    assign  dequeue_data2 = dequeue_data[1];

    // 分解出队数据
    always @(*) begin
        dispatch_pc_out[0]          =   dequeue_data1[31:0];
        dispatch_pc_out[1]          =   dequeue_data2[31:0];
        dispatch_inst_out[0]        =   dequeue_data1[63:32];
        dispatch_inst_out[1]        =   dequeue_data2[63:32];
        dispatch_inst_valid[0]      =   dequeue_data1[64];
        dispatch_inst_valid[1]      =   dequeue_data2[64];
        dispatch_aluop[0]           =   dequeue_data1[72:65];
        dispatch_aluop[1]           =   dequeue_data2[72:65];
        dispatch_alusel[0]          =   dequeue_data1[75:73];
        dispatch_alusel[1]          =   dequeue_data2[75:73];
        dispatch_imm[0]             =   dequeue_data1[107:76];
        dispatch_imm[1]             =   dequeue_data2[107:76];
        dispatch_reg1_read_en[0]    =   dequeue_data1[108];   
        dispatch_reg1_read_en[1]    =   dequeue_data1[109];   
        dispatch_reg2_read_en[0]    =   dequeue_data2[108];   
        dispatch_reg2_read_en[1]    =   dequeue_data2[109];   
        dispatch_reg1_read_addr[0]  =   dequeue_data1[114:110];
        dispatch_reg1_read_addr[1]  =   dequeue_data1[119:115];
        dispatch_reg2_read_addr[0]  =   dequeue_data2[114:110];
        dispatch_reg2_read_addr[1]  =   dequeue_data2[119:115];
        dispatch_reg_writen_en[0]   =   dequeue_data1[120];
        dispatch_reg_writen_en[1]   =   dequeue_data2[120];  
        dispatch_reg_write_addr[0]  =   dequeue_data1[125:121];
        dispatch_reg_write_addr[1]  =   dequeue_data1[125:121];
    end

    assign pause_decoder = full;

endmodule