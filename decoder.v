`timescale 1ps/1ps

module decoder (
    input wire clk,
    input wire rst,

    input wire flush, //强制更新信号

    input wire [1:0][31:0] pc,
    input wire [1:0][31:0] inst,
    input wire [1:0] valid,
    input wire [1:0] pretaken,
    input wire [1:0][31:0] pre_addr,
    input wire [1:0][1:0] is_exception,
    input wire [1:0][1:0][6:0] exception_cause,

    input wire [1:0] invalid_en, //用于从外部（如调度器）控制某些指令不进入队列

    output wire logic pause_decoder, //通知暂停取指信号

    output reg  [1:0]dispatch_inst_valid,
    output reg  [1:0][31:0] dispatch_pc_out,
    output reg  [1:0][31:0] dispatch_inst_out,
    output reg  [1:0]dispatch_reg_writen_en,  //寄存器写使能信号
    output reg  [1:0][7:0]dispatch_aluop,
    output reg  [1:0][2:0]dispatch_alusel,
    output reg  [1:0][31:0]dispatch_imm,
    output reg  [1:0]dispatch_reg1_read_en,   //rR1寄存器读使能
    output reg  [1:0]dispatch_reg2_read_en,   //rR2寄存器读使能
    output reg  [1:0][4:0]dispatch_reg1_read_addr,
    output reg  [1:0][4:0]dispatch_reg2_read_addr,
    output reg  [1:0][4:0]dispatch_reg_write_addr
);
    //内部信号
    reg  [1:0] inst_valid;  
    reg  [1:0] [31:0] pc_out;
    reg  [1:0] [31:0] inst_out;
    reg  [1:0] reg_writen_en; 
    reg  [1:0] [7:0]aluop;
    reg  [1:0] [2:0]alusel;
    reg  [1:0] [31:0]imm;
    reg  [1:0] reg1_read_en;   
    reg  [1:0] reg2_read_en;   
    reg  [1:0] [4:0]reg1_read_addr;
    reg  [1:0] [4:0]reg2_read_addr;
    reg  [1:0] [4:0]reg_write_addr;

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

    reg  [1:0] queue_inst_valid;  
    reg  [1:0] [31:0] queue_pc_out;
    reg  [1:0] [31:0] queue_inst_out;
    reg  [1:0] queue_reg_writen_en; 
    reg  [1:0] [7:0]queue_aluop;
    reg  [1:0] [2:0]queue_alusel;
    reg  [1:0] [31:0]queue_imm;
    reg  [1:0] queue_reg1_read_en;   
    reg  [1:0] queue_reg2_read_en;   
    reg  [1:0] [4:0]queuereg1_read_addr;
    reg  [1:0] [4:0]queue_reg2_read_addr;
    reg  [1:0] [4:0]queue_reg_write_addr;

    reg [1:0] enqueue_en; //入队使能信号

    reg full;
    reg empty;
    wire fifo_rst;
    assign fifo_rst = rst || flush;

    dram_fifo u_queue(
        .clk(clk),
        .rst(fifo_rst),
        .enqueue_en(enqueue_en),

        .in_inst_valid(inst_valid),
        .in_pc(pc_out),
        .in_inst(inst_out),
        .in_reg_writen_en(reg_writen_en),  
        .in_aluop(aluop),
        .in_alusel(alusel),
        .in_imm(imm),
        .in_reg1_read_en(reg1_read_en),
        .in_reg2_read_en(reg2_read_en),
        .in_reg1_read_addr(reg1_read_addr), 
        .in_reg2_read_addr(reg2_read_addr),
        .in_reg_write_addr(reg_write_addr), 

        .queue_inst_valid(queue_inst_valid),
        .queue_pc(queue_pc_out),
        .queue_inst_out(queue_inst_out),
        .queue_reg_writen_en(queue_reg_writen_en), 
        .queue_aluop(queue_aluop),
        .queue_alusel(queue_alusel),
        .queue_imm(queue_imm),
        .queue_reg1_read_en(queue_reg1_read_en),   
        .queue_reg2_read_en(queue_reg2_read_en),   
        .queue_reg1_read_addr(queue_reg1_read_addr),
        .queue_reg2_read_addr(queue_reg2_read_addr),
        .queue_reg_write_addr(queue_reg_write_addr),

        .invalid_en(invalid_en),

        .full(full),
        .empty(empty)
    );

    enqueue_en[0] = !full && valid[0];
    enqueue_en[1] = !full && valid[1];

    dispatch_inst_valid[0] = queue_inst_valid[0];
    dispatch_inst_valid[1] = queue_inst_valid[1];
    dispatch_pc_out[0] = queue_pc_out[0];
    dispatch_pc_out[1] = queue_pc_out[1];
    dispatch_inst_out[0] = queue_inst_out[0];
    dispatch_inst_out[1] = queue_inst_out[1];
    dispatch_reg_writen_en[0] = queue_reg_writen_en
    dispatch_reg_writen_en[1] = queue_reg_writen_en[1];  
    dispatch_aluop[0] = queue_aluop[0];
    dispatch_aluop[1] = queue_aluop[1];
    dispatch_alusel[0] = queue_alusel[0];
    dispatch_alusel[1] = queue_alusel[1];
    dispatch_imm[0] = queue_imm[0];
    dispatch_imm[1] = queue_imm[1];
    dispatch_reg1_read_en[0] = queue_reg1_read_en[0];   
    dispatch_reg2_read_en[1] = queue_reg2_read_en[1];   
    dispatch_reg1_read_addr[0] = queue_reg1_read_addr[0];
    dispatch_reg2_read_addr[1] = queue_reg2_read_addr[1];
    dispatch_reg_write_addr[0] = queue_reg_write_addr[0];
    dispatch_reg_write_addr[1] = queue_reg_write_addr[1];

    pause_decoder = |full;

endmodule