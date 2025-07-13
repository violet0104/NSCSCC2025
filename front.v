`timescale 1ps/1ps

module front
(
    input wire cpu_clk,
    input wire cpu_rst,

    input wire iuncache,

    // 来自 icache 的信号
    input wire pi_icache_is_exception,            //指令缓存异常信号
    input wire [6:0] pi_icache_exception_cause,    //指令缓存异常原因
    input wire [31:0] pc_for_buffer[1:0],               //pc给指令缓存的信号
    input wire [31:0] pred_addr_for_buffer,
    input wire icache_pc_suspend,
    input wire [31:0] inst_for_buffer[1:0],
    input wire icache_inst_valid,       //指令缓存的使能信号

    //*******************
    input wire [1:0] fb_flush,
    input wire [1:0] fb_pause,
    input wire fb_interrupt,            //中断信号
    input wire [31:0] fb_new_pc,        //中断后新的pc地址
    input wire [1:0] fb_send_inst_en,   //发送给指令缓存的使能信号
    input wire fb_up_date_en,
    

    //与icache的交互
    output wire BPU_flush,
    output reg [31:0] pi_pc,                //前端给icache的pc地址
    output wire [31:0] BPU_pred_addr,
    output wire BPU_pred_taken,
    output wire inst_rreq_to_icache,            //前端给icache的指令使能信号
    output reg pi_is_exception,             //前端给icache的异常信号
    output reg [6:0] pi_exception_cause,    //前端给icache的异常原因

    //和backend的交互
    output wire [1:0][31:0] fb_pc_out              //前端给后端的pc地址
    output wire [1:0][31:0] fb_inst_out,            //前端给后端的指令
    output wire fb_valid,                           //前端给后端的指令使能信号
    output wire [1:0] fb_pre_taken,
    output wire [1:0][31:0] fb_pre_branch_addr,     //前端给后端的分支地址
    output reg  [1:0] fb_is_exception,               //前端给后端的
    output reg  [1:0][1:0][6:0] fb_exception_cause,  //前端给后端的异常原因


    //我新加的信号**************************
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
    end

    assign BPU_pred_addr = pre_addr;
    assign BPU_pred_taken = pred_taken[0] | pred_taken[1];

    pc u_pc 
    (
        .clk(cpu_clk),
        .rst(cpu_rst),    
        .stall(stall),
        .iuncache(iuncache),
        .flush(fb_flush[0] | BPU_flush),
        .new_pc(fb_new_pc),       //后端需要接一个信号选择器，该pc来源有二：ex阶段分支预测错误，并得到的真正目标pc；触发例外，且例外处理程序的末尾，需要回到程序断点继续执行
        .pause(fb_pause[0] | icache_pc_suspend),
        .pre_addr(pre_addr),  
        .pred_taken(pred_taken[0] | pred_taken[1]),  
        .pc_out(pc_out),
        .pc_is_exception(is_exception),
        .pc_exception_cause(exception_cause),
        inst_rreq_to_icache(inst_rreq_to_icache)
    );

    bpu u_bpu
    (
        .cpu_clk(cpu_clk),
        .cpu_rst(cpu_rst),    //low active???
        .if_pc(pc_out),

        .pred_taken1(pred_taken[0]),
        .pred_taken2(pred_taken[1]),
        .pred_addr(pre_addr),

        .BPU_flush(),

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
    );

    inst_buffer u_inst_buffer 
    (
        .clk(cpu_clk),
        .rst(cpu_rst),
        .flush(flush[1]),
        .get_data_req(get_data_req),   //给instbuffer这个信号instbuffer才会给后端输出inst（异步读）
        .inst_valid(icache_inst_valid),
        .pc1(pc_for_buffer[0]),
        .pc2(pc_for_buffer[1]),

        .inst1(inst_for_buffer[0]),
        .inst2(inst_for_buffer[1]),
        .pred_addr(),

        .data_out1(data_out1),
        .data_out1(data_out2),
        .data_valid(fb_valid),

        .stall(stall)
    );


endmodule