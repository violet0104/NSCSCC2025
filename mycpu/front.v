`timescale 1ps/1ps

module front
(
    input wire cpu_clk,
    input wire cpu_rst,

    input wire iuncache,

    // 来自 icache 的信号
    input wire       pi_icache_is_exception1,            //指令缓存异常信号
    input wire       pi_icache_is_exception2,          
    input wire [6:0] pi_icache_exception_cause1,    //指令缓存异常原因
    input wire [6:0] pi_icache_exception_cause2,
    input wire [31:0] pc_for_buffer1,               //pc给指令缓存的信号
    input wire [31:0] pc_for_buffer2,               
    input wire [31:0] pred_addr_for_buffer,
    input wire [1:0] pred_taken_for_buffer,
    input wire icache_pc_suspend,
    input wire [31:0] inst_for_buffer1,
    input wire [31:0] inst_for_buffer2,
    input wire icache_inst_valid,       //指令缓存的使能信号

    //*******************
    input wire [1:0] fb_flush,
    input wire [1:0] fb_pause,
    input wire fb_interrupt,            //中断信号（这个没用到？？）
//    input wire [31:0] fb_new_pc,        //中断后新的pc地址
    
    //与icache的交互
    output wire BPU_flush,
    output reg [31:0] pi_pc,                //前端给icache的pc地址
    output wire [31:0] BPU_pred_addr,
    output wire [1:0] pred_taken,
    output wire inst_rreq_to_icache,            //前端给icache的指令使能信号
    output reg pi_is_exception,             //前端给icache的异常信号
    output reg [6:0] pi_exception_cause,    //前端给icache的异常原因

    //和backend的交互
    output wire fb_pred_taken1,
    output wire fb_pred_taken2,
    output wire [31:0] fb_pc_out1,              //前端给后端的pc地址
    output wire [31:0] fb_pc_out2,              
    output wire [31:0] fb_inst_out1,            //前端给后端的指令
    output wire [31:0] fb_inst_out2,           
    output wire [1:0] fb_valid,                           //前端给后端的指令使能信号
    output wire [31:0] fb_pre_branch_addr1,         //前端给后端的分支地址
    output wire [31:0] fb_pre_branch_addr2,

    output wire [1:0] fb_is_exception1,                 // 第一条指令是否异常
    output wire [6:0] fb_pc_exception_cause1,           // 第一条指令在pc的异常原因
    output wire [6:0] fb_instbuffer_exception_cause1,   // 第一条指令在instbuffer的异常原因
    
    output wire [1:0] fb_is_exception2,               
    output wire [6:0] fb_pc_exception_cause2,
    output wire [6:0] fb_instbuffer_exception_cause2,



    //我新加的信号**************************
    input  wire [31:0]          new_pc,
    input  wire [1:0]           ex_is_bj ,          // 两条指令是否是跳转指令
    input  wire [31:0]          ex_pc1 ,            // ex 阶段的 pc
    input  wire [31:0]          ex_pc2 ,             
    input  wire [1:0]           ex_valid ,        
    input  wire [1:0]           real_taken ,        // 两条指令实际是否跳转
    input  wire [31:0]          real_addr1 ,        // 两条指令实际跳转地址
    input  wire [31:0]          real_addr2 ,
    input  wire [31:0]          pred_addr1 ,         // 两条指令预测跳转地址
    input  wire [31:0]          pred_addr2 ,
    input  wire                 get_data_req     
    //*************************************
);
    reg [1:0] is_branch;            // 这个没用到？？
    wire [31:0] pre_addr;
    wire [31:0] pc_out;
    wire is_exception;
    wire [6:0] exception_cause;
    reg inst_en1;           // 这个没用到？？
    reg inst_en2;           // 这个没用到？？
    //我新加的信号**********************************
    wire instbuffer_stall;      // 这个没用到？？
    wire [104:0] data_out1;
    wire [104:0] data_out2;
    
    wire BPU_pred_taken;
    //***************************************
    assign fb_pred_taken1 = data_out1[104];
    assign fb_pred_taken2 = data_out2[104];
    assign fb_pre_branch_addr1 = data_out1[103:72];
    assign fb_pre_branch_addr2 = data_out2[103:72];
    assign fb_pc_out1 = data_out1[71:40];
    assign fb_pc_out2 = data_out2[71:40];
    assign fb_inst_out1 = data_out1[39:8];
    assign fb_inst_out2 = data_out2[39:8];
    assign fb_is_exception1 = {data_out1[7], 1'b0};
    assign fb_is_exception2 = {data_out2[7], 1'b0};
    assign fb_pc_exception_cause1 = data_out1[6:0];
    assign fb_pc_exception_cause2 = data_out2[6:0];
    assign fb_instbuffer_exception_cause1 = 7'b1111111;
    assign fb_instbuffer_exception_cause2 = 7'b1111111;

    //********************************
    always @(*) 
    begin
        pi_pc = pc_out;
        pi_is_exception = is_exception;
        pi_exception_cause = exception_cause;
    end

    assign BPU_pred_addr = pre_addr;
    assign BPU_pred_taken = pred_taken[0] | pred_taken[1];
    
    wire stall;
    
    pc u_pc 
    (
        .clk(cpu_clk),
        .rst(cpu_rst),    
        .stall(stall),
        .iuncache(iuncache),
        .flush(fb_flush[0] | BPU_flush),
        .new_pc(new_pc),       //后端需要接一个信号选择器，该pc来源有二：ex阶段分支预测错误，并得到的真正目标pc；触发例外，且例外处理程序的末尾，需要回到程序断点继续执行
        .pause(fb_pause[0] | icache_pc_suspend),
        .pre_addr(pre_addr),  
        .pred_taken(pred_taken[0] | pred_taken[1]),  
        .pc_out(pc_out),
        .pc_is_exception(is_exception),
        .pc_exception_cause(exception_cause),
        .inst_rreq_to_icache(inst_rreq_to_icache)
    );

    wire ex_valid1 = ex_valid[0];
    wire ex_valid2 = ex_valid[1];

    BPU u_BPU
    (
        .cpu_clk(cpu_clk),
        .cpu_rstn(cpu_rst),    //low active???
        .if_pc(pc_out),

        .pred_taken1(pred_taken[0]),
        .pred_taken2(pred_taken[1]),
        .pred_addr(pre_addr),

        .BPU_flush(BPU_flush),
//        .new_pc(new_pc),

        .ex_is_bj_1(ex_is_bj[0]),     //等后端给我的信号，ex阶段的指令是否是跳转指令
        .ex_pc_1(ex_pc1),
        .ex_valid1(ex_valid1),
        .ex_is_bj_2(ex_is_bj[1]),
        .ex_pc_2(ex_pc2),
        .ex_valid2(ex_valid2),
        .real_taken1(real_taken[0]),
        .real_taken2(real_taken[1]),
        .real_addr1(real_addr1),
        .real_addr2(real_addr2),
        .pred_addr1(pred_addr1),
        .pred_addr2(pred_addr2)
    );

    instbuffer u_instbuffer 
    (
        .clk(cpu_clk),
        .rst(cpu_rst),
        .flush(fb_flush[1] | BPU_flush),
        .get_data_req(get_data_req),   //给instbuffer这个信号instbuffer才会给后端输出inst（异步读）
        .inst_valid(icache_inst_valid),
        .pc1(pc_for_buffer1),
        .pc2(pc_for_buffer2),

        .inst1(inst_for_buffer1),
        .inst2(inst_for_buffer2),
        .pred_addr(pred_addr_for_buffer),
        .pred_taken(pred_taken_for_buffer),

        .pc_is_exception_in1(pi_icache_is_exception1),
        .pc_is_exception_in2(pi_icache_is_exception2),
        .pc_exception_cause_in1(pi_icache_exception_cause1),
        .pc_exception_cause_in2(pi_icache_exception_cause2),
        .data_out1(data_out1),

        .data_out2(data_out2),
        .data_valid(fb_valid),

        .stall(stall)
    );


endmodule