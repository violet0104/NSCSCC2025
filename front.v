`timescale 1ps/1ps

module front
(
    input wire cpu_clk,
    input wire cpu_rst,

    input wire iuncache,

    // 可能是 ctrl
    input wire pause,         //暂停信号

    // 来自 pc 的信号
    input wire [1:0] pi_icache_is_exception,            //指令缓存异常信号
    input wire [6:0] pi_icache_exception_cause[1:0],    //指令缓存异常原因
    input wire [31:0] pc_for_buffer[1:0],               //pc给指令缓存的信号

    // 来自 icache 的信号
    input wire icache_pc_suspend,
    input wire [31:0] inst_for_buffer[1:0],
    input wire [1:0] icache_fetch_en,       //指令缓存的使能信号

    //*******************
    input wire [1:0] fb_flush,
    input wire [1:0] fb_pause,
    input wire fb_interrupt,            //中断信号
    input wire [31:0] fb_new_pc,        //中断后新的pc地址
    input wire [1:0] fb_send_inst_en,   //发送给指令缓存的使能信号
    input wire fb_up_date_en,
    

    //与icache的交互
    output reg [31:0] pi_pc,                //前端给icache的pc地址
    output reg [1:0] pi_inst_en,            //前端给icache的指令使能信号
    output reg pi_is_exception,             //前端给icache的异常信号
    output reg [6:0] pi_exception_cause,    //前端给icache的异常原因
    output reg [1:0] pi_fetch_en,           //前端给icache的指令缓存使能信号

    //和backend的交互
    output wire [31:0] fb_pc_out[1:0],              //前端给后端的pc地址
    output wire [31:0] fb_inst_out[1:0],            //前端给后端的指令
    output wire fb_valid,                           //前端给后端的指令使能信号
    output wire [1:0] fb_pre_taken,
    output wire [31:0] fb_pre_branch_addr[1:0],     //前端给后端的分支地址
    output reg [1:0] fb_is_exception,               //前端给后端的
    output reg [6:0] fb_exception_cause[1:0][1:0],  //前端给后端的异常原因


    //我新加的信号**************************
    output wire inst_buffer_empty;          // 暂时不知道有什么用??
    input  wire [1:0]           ex_is_bj ,          // 两条指令是否是跳转指令
    input  wire [1:0] [31:0]    ex_pc ,             // ex 阶段的 pc
    input  wire [1:0]           ex_valid ,        
    input  wire [1:0]           real_taken ,        // 两条指令实际是否跳转
    input  wire [1:0] [31:0]    real_addr ,         // 两条指令实际跳转地址
    input  wire [1:0] [31:0]    pred_addr ,         // 两条指令预测跳转地址
    input  wire                 get_data_req     
    //*************************************
)
    reg [1:0] is_branch;
    reg [31:0] pre_addr;
    reg [31:0] pc_out;
    reg is_exception;
    reg [6:0] exception_cause;
    reg inst_en1;
    reg inst_en2;
    //我新加的信号**********************************
    wire if_valid;
    wire instbuffer_stall;
    wire [96:0] data_out1;
    wire [96:0] data_out2;
    wire [1:0] pred_taken;
    wire inst_valid;
    //***************************************

    assign fb_pre_taken[0] = data_out1[96];
    assign fb_pre_taken[1] = data_out2[96];
    assign fb_pre_branch_addr[0] = data_out1[95:64];
    assign fb_pre_branch_addr[1] = data_out2[95:64];
    assign fb_pc_out[0] = data_out1[63:32];
    assign fb_pc_out[1] = data_out2[63:32];
    assign fb_inst_out[0] = data_out1[31:0];
    assign fb_inst_out[1] = data_out2[31:0];


    //********************************
    always @(*) 
    begin
        pi_pc = pc_out;
        pi_is_exception = is_exception;
        pi_exception_cause = exception_cause;
        pi_inst_en = {inst_en2, inst_en1};
    end

    pc u_pc 
    (
        .clk(cpu_clk),
        .rst(cpu_rst),    
        .stall(stall),
        .iuncache(iuncache),
        .flush(fb_flush[0]),
        .new_pc(fb_new_pc),
        .pause(fb_pause[0] | icache_pc_suspend),
        .pre_addr(pre_addr),  
        .pred_taken(pred_taken),  
        .pc_out(pc_out),
        .pc_is_exception(is_exception),
        .pc_exception_cause(exception_cause),
        .inst_en_1(inst_en1),
        .inst_en_2(inst_en2),
        .if_valid(if_valid)
    );

    bpu u_bpu
    (
        .cpu_clk(cpu_clk),
        .cpu_rst(cpu_rst),    //low active???
        .if_pc(pc_out),

        .pred_taken1(pred_taken[0]),
        .pred_taken2(pred_taken[1]),
        .pred_addr(pre_addr),

        .pred_error1(), //这是我当初设计给pc的，表示预测错误
        .pred_error2(), //需要pc更新为新的取指地址，现在似乎被flush替代

        .if_valid(if_valid),
        .ex_is_bj_1(ex_is_bj[0]),     //等后端给我的信号，ex阶段的指令是否是跳转指令
        .ex_pc_1(ex_pc[0]),
        .ex_valid1(ex_valid[0]),
        .ex_is_bj_2(ex_is_bj_2),
        .ex_pc_2(ex_pc[1]),
        .ex_valid2(ex_valid[1]),
        .real_taken1(real_taken[0]),
        .real_taken2(real_taken[1]),
        .real_addr1(real_addr[0]),
        .real_addr2(real_addr[1]),
        .pred_addr1(pred_addr[0]),
        .pred_addr2(pred_addr[1]),
    )

    inst_buffer u_inst_buffer 
    (
        .clk(cpu_clk),
        .rst(cpu_rst),
        .flush(flush[1]),
        .get_data_req(get_data_req),   //给instbuffer这个信号instbuffer才会给后端输出inst（异步读）
        .inst_valid(inst_valid),
        .pc1(pc_for_buffer[0]),
        .pc2(pc_for_buffer[1]),

        .inst1(inst_for_buffer[0]),
        .inst2(inst_for_buffer[1]),
        .pred_addr(pre_addr),
        .pred_taken1(pred_taken[0]),
        .pred_taken2(pred_taken[1]),

        .data_out1(data_out1),
        .data_out1(data_out2),
        .data_valid(fb_valid),

        .stall(stall),
        .empty(inst_buffer_empty),
        .full(buffer_full)
    );


endmodule