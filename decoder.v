`timescale 1ps/1ps

module decoder (
    input wire clk,
    input wire rst,

    input wire flush, //强制更新信号

    input wire [31:0] pc [1:0],
    input wire [31:0] inst [1:0],
    input wire [1:0]  valid,
    input wire [1:0]  pretaken,
    input wire [31:0] pre_addr [1:0],
    input wire [1:0]  is_exception [1:0],
    input wire [6:0]  exception_cause [1:0][1:0],

    input wire [1:0] invalid_en, //用于从外部（如调度器）控制某些指令不进入队列         // 为什么是出队信号？？

    output wire pause_decoder, //通知暂停取指信号

    output reg  [1:0]  dispatch_inst_valid,
    output reg  [31:0] dispatch_pc_out [1:0],
    output reg  [31:0] dispatch_inst_out [1:0],
    output reg  [7:0]  dispatch_aluop [1:0],
    output reg  [2:0]  dispatch_alusel [1:0],
    output reg  [31:0] dispatch_imm [1:0],
    output reg  [1:0]  dispatch_reg1_read_en,   //rR1寄存器读使能
    output reg  [1:0]  dispatch_reg2_read_en,   //rR2寄存器读使能
    output reg  [4:0]  dispatch_reg1_read_addr [1:0],
    output reg  [4:0]  dispatch_reg2_read_addr [1:0],
    output reg  [1:0]  dispatch_reg_writen_en,  //寄存器写使能信号
    output reg  [4:0]  dispatch_reg_write_addr [1:0]
);
    //内部信号
    reg  [1:0]  inst_valid;  
    reg  [31:0] pc_out [1:0];
    reg  [31:0] inst_out [1:0];
    reg  [1:0]  reg_writen_en; 
    reg  [7:0]  aluop [1:0];
    reg  [2:0]  alusel [1:0];
    reg  [31:0] imm [1:0];
    reg  [1:0]  reg1_read_en;   
    reg  [1:0]  reg2_read_en;   
    reg  [4:0]  reg1_read_addr [1:0];
    reg  [4:0]  reg2_read_addr [1:0];
    reg  [4:0]  reg_write_addr [1:0];

    id u_id1 (
        .pc(pc[0]),
        .inst(inst[0]),
        .valid(valid[0]),
        .pre_taken(pretaken[0]),
        .pre_addr(pre_addr[0]),
        .is_exception(is_exception[0]),
        .exception_cause(exception_cause[0]),

        .inst_valid(inst_valid[0]),
        .pc_out(pc_out[0]),
        .inst_out(inst_out[0]),
        .reg_writen_en (reg_writen_en[0]),  //寄存器写使能信号
        .aluop(aluop[0]),
        .alusel(alusel[0]),
        .imm(imm[0]),
        .reg1_read_en(reg1_read_en[0]),   //rR1寄存器读使能
        .reg2_read_en(reg2_read_en[0]),   //rR2寄存器读使能
        .reg1_read_addr(reg1_read_addr[0]),
        .reg2_read_addr(reg2_read_addr[0]),
        .reg_write_addr(reg_write_addr[0]),  //目的寄存器地址
    );

    id u_id2 (
        .pc(pc[1]),
        .inst(inst[1]),
        .valid(valid[1]),
        .pre_is_branch_taken(pre_is_branch_taken[1]),
        .pre_branch_addr(pre_branch_addr[1]),
        .is_exception(is_exception[1]),
        .exception_cause(exception_cause[1]),

        .inst_valid(inst_valid[1]),
        .pc_out(pc_out[1]),
        .inst_out(inst_out[1]),
        .reg_writen_en (reg_writen_en[1]),  //寄存器写使能信号
        .aluop(aluop[1]),
        .alusel(alusel[1]),
        .imm(imm[1]),
        .reg1_read_en(reg1_read_en[1]),   //rR1寄存器读使能
        .reg2_read_en(reg2_read_en[1]),   //rR2寄存器读使能
        .reg1_read_addr(reg1_read_addr[1]),
        .reg2_read_addr(reg2_read_addr[1]),
        .reg_write_addr(reg_write_addr[1]),  //目的寄存器地址
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
                                inst_valid[0]           // 64
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

    wire    dequeue_data1; 
    wire    dequeue_data2;
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
        dispatch_reg_writen_en[0]   =   dequeue_data1[120]
        dispatch_reg_writen_en[1]   =   dequeue_data2[120];  
        dispatch_reg_write_addr[0]  =   dequeue_data1[125:121];
        dispatch_reg_write_addr[1]  =   dequeue_data1[125:121];
    end

    pause_decoder = full;

endmodule