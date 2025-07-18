`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

//内部功能
//1.异常与中断处理
//遍历所有指令，生成 is_exception 信号
//根据异常种类的优先级，对指令异常类型进行编码，输出 exception_cause
//异常地址、异常指令 PC、ecode/esubcode 都通过 csr_master 接口传递给 CSR 模块
//如果有异常或中断，跳转到 csr_master.eentry 或 tlbrentry
//2.新PC的生成与异常跳转
//如果是 ertn（异常返回指令），跳转到 csr_master.era
//如果是 refetch（如 CSR 写后刷新指令），跳转到下一条指令
//否则走普通分支跳转地址 branch_target
//3.流水线刷新逻辑
//该模块生成一个 flush 信号，总共 8 位，分别控制流水线各个阶段（PC、icache、instbuffer、id、dispatch、ex、mem、wb）的清除
//一旦出现异常、分支跳转、CSR写、ERTN等信号，触发级联刷新。
//4.流水线暂停（Pause）控制
//由输入的控制信号,标识是否需要暂停某一级（如 decode、dispatch、execute、memory）
//暂停信号按照优先级处理，并生成对应的 8 位暂停向量 pause，其中，pause[7] 为 wb 阶段的暂停，pause[0] 为 PC 阶段
//5.写回处理
//如果两个指令写同一个寄存器地址，优先保留后发射的指令，防止冲突。
//在发生异常或流水线暂停时禁止写寄存器。
//6.csr写操作
//判断是否需要写csr寄存器，若有异常则禁止写
//CSR 写地址、数据优先第0条指令
module ctrl
(
    input  wire        rst,

    input  wire        pause_buffer,//从前端输入
    input  wire        pause_decode,//从decoder输入
    input  wire        pause_dispatch,//从dispatch输入
    input  wire        pause_execute,//从execute输入
    input  wire        pause_mem,//从mem输入

    input  wire        branch_flush,//分支跳转刷新信号
    input  wire [31:0] branch_target,//分支跳转地址，从execute阶段输入 
    input  wire        ex_excp_flush,//异常刷新信号,从execute阶段输入

    //wb阶段输入wb
    input  wire [1:0]        reg_write_en_i,//写回阶段刷新信号
    input  wire [4:0]        reg_write_addr1_i,//写回阶段寄存器地址
    input  wire [4:0]        reg_write_addr2_i,//写回阶段寄存器地址
    input  wire [31:0]       reg_write_data1_i,//写回阶段寄存器数据
    input  wire [31:0]       reg_write_data2_i,//写回阶段寄存器数据
    input  wire [1:0]        is_llw_scw_i,//是否是 llw/scw 指令
    input  wire [1:0]        csr_write_en_i,//csr写使能信号
    input  wire [13:0]       csr_write_addr1_i,//csr写地址
    input  wire [13:0]       csr_write_addr2_i,//csr写地址
    input  wire [31:0]       csr_write_data1_i,//csr写数据
    input  wire [31:0]       csr_write_data2_i,//csr写数据

    //从wb阶段输入commit
    input wire  [5:0]  is_exception1_i,
    input wire  [5:0]  is_exception2_i,
    input wire  [6:0]  pc_exception_cause1_i,
    input wire  [6:0]  pc_exception_cause2_i, 
    input wire  [6:0]  instbuffer_exception_cause1_i,
    input wire  [6:0]  instbuffer_exception_cause2_i,
    input wire  [6:0]  decoder_exception_cause1_i,
    input wire  [6:0]  decoder_exception_cause2_i,
    input wire  [6:0]  dispatch_exception_cause1_i,
    input wire  [6:0]  dispatch_exception_cause2_i,
    input wire  [6:0]  execute_exception_cause1_i,
    input wire  [6:0]  execute_exception_cause2_i,
    input wire  [6:0]  commit_exception_cause1_i,
    input wire  [6:0]  commit_exception_cause2_i,

    input  wire [31:0]       pc1_i,
    input  wire [31:0]       pc2_i,
    input  wire [31:0]       mem_addr1_i,
    input  wire [31:0]       mem_addr2_i,
    input  wire [1:0]        is_idle_i,//是否处于空闲状态
    input  wire [1:0]        is_ertn_i,//是否是异常返回指令
    input  wire [1:0]        is_privilege_i,//是否是特权指令
    input  wire [1:0]        valid_i,//指令是否有效
    //csr
    output wire              is_ertn_o,//是否是异常返回指令
    //
    output wire [7:0]  flush,//刷新信号
    output wire [7:0]  pause,//暂停信号
    output wire [31:0] new_pc,//新的PC地址

    //to regfile
    output reg  [1:0]  reg_write_en_o,//写回阶段刷新信号
    output reg  [4:0]  reg_write_addr1_o,//写回阶段寄存器地址
    output reg  [4:0]  reg_write_addr2_o,//写回阶段寄存器地址
    output reg  [31:0] reg_write_data1_o,//写回阶段寄存器数据
    output reg  [31:0] reg_write_data2_o,//写回阶段寄存器数据

    //to csr
    output wire is_llw_scw_o,//是否是 llw/scw 指令
    output wire  csr_write_en_o,//csr写使能信号
    output wire [13:0] csr_write_addr_o,//csr写地址
    output wire [31:0] csr_write_data_o,//csr写数据

    // with csr
    input wire [31:0] csr_eentry_i, //异常入口地址
    input wire [31:0] csr_era_i, //异常返回地址
    input wire [31:0] csr_crmd_i, //控制寄存器 
    input wire        csr_is_interrupt_i, //是否是中断
    
    output wire        csr_is_exception_o, //是否是异常
    output wire [31:0] csr_exception_pc_o, //异常PC地址
    output wire [31:0] csr_exception_addr_o, //异常地址
    output reg  [5:0]  csr_ecode_o, //异常ecode
    output wire [6:0]  csr_exception_cause_o, //异常原因
    output reg  [8:0]  csr_esubcode_o //异常子码

);
    //ertn
    wire ertn_flush;
    assign ertn_flush = is_ertn_i[0]; //为什么只要第0条指令
    assign is_ertn_o = ertn_flush;

    //新的target,refetch重新取址后
    wire refetch_flush;
    wire [31:0] refetch_target;
    assign refetch_target = (pc1_i | pc2_i) + 32'h4; 
    reg [1:0] is_exception;
    assign new_pc = (|is_exception) ? csr_eentry_i : (ertn_flush ? csr_era_i : (refetch_flush ? refetch_target : branch_target));

    always @(*) begin
        is_exception[0] = !rst && valid_i[0] && (is_exception1_i != 6'b0 || csr_is_interrupt_i);
        is_exception[1] = !rst && valid_i[1] && (is_exception2_i != 6'b0 || csr_is_interrupt_i);
    end

    assign csr_is_exception_o = |is_exception;

    //设置向量flush
    // flush[0] PC, flush[1] icache, flush[2] instbuffer, flush[3] id
    // flush[4] dispatch, flush[5] ex, flush[6] mem, flush[7] wb
    assign flush = {
        1'b0,
        |is_exception || ertn_flush || refetch_flush,
        |is_exception || ertn_flush || refetch_flush,
        |is_exception || ertn_flush || branch_flush || ex_excp_flush || refetch_flush,
        |is_exception || ertn_flush || branch_flush || ex_excp_flush || refetch_flush,
        |is_exception || ertn_flush || branch_flush || refetch_flush,
        |is_exception || ertn_flush || branch_flush || refetch_flush,
        |is_exception || ertn_flush || branch_flush || refetch_flush
    };

    always @(*) begin
        reg_write_addr1_o = reg_write_addr1_i;
        reg_write_addr2_o = reg_write_addr2_i;
        reg_write_data1_o = reg_write_data1_i;
        reg_write_data2_o = reg_write_data2_i;
    end

    wire [1:0] reg_write_en_out;
    assign reg_write_en_out[0] = (is_exception[0] || pause[7]) ? 1'b0 : reg_write_en_i[0];
    assign reg_write_en_out[1] = (|is_exception || pause[7]) ? 1'b0 : reg_write_en_i[1];

    always @(*) begin
        if(reg_write_addr1_i == reg_write_addr2_i) begin
            reg_write_en_o[0] = 1'b0;
            reg_write_en_o[1] = reg_write_en_out[1];
        end
        else begin
            reg_write_en_o[0] = reg_write_en_out[0];
            reg_write_en_o[1] = reg_write_en_out[1];
        end
    end

    assign is_llw_scw_o = |is_exception ? 1'b0 : (is_llw_scw_i[0] | is_llw_scw_i[1]);
    assign csr_write_en_o = |is_exception ? 1'b0 : (csr_write_en_i[0] | csr_write_en_i[1]);
    assign csr_write_addr_o = (csr_write_en_i[0] ? csr_write_addr1_i : csr_write_addr2_i);
    assign csr_write_data_o = (csr_write_en_i[0] ? csr_write_data1_i : csr_write_data2_i);
    assign refetch_flush = csr_write_en_o;

    assign csr_exception_pc_o = is_exception[0] ? pc1_i : pc2_i;
    assign csr_exception_addr_o = is_exception[0] ? mem_addr1_i : mem_addr2_i;

    //异常造成的原因
    reg  [6:0] exception_cause1;
    reg  [6:0] exception_cause2;

    wire [5:0] inst_is_exception1;
    wire [5:0] inst_is_exception2;

    assign inst_is_exception1 = is_exception1_i;
    assign inst_is_exception2 = is_exception2_i;

    wire [6:0] inst_exception_cause1 [5:0]; 
    wire [6:0] inst_exception_cause2 [5:0];
    assign inst_exception_cause1 [0] = commit_exception_cause1_i;
    assign inst_exception_cause1 [1] = execute_exception_cause1_i;
    assign inst_exception_cause1 [2] = dispatch_exception_cause2_i;
    assign inst_exception_cause1 [3] = decoder_exception_cause1_i;
    assign inst_exception_cause1 [4] = instbuffer_exception_cause1_i; 
    assign inst_exception_cause1 [5] = pc_exception_cause1_i;
    assign inst_exception_cause2 [0] = commit_exception_cause2_i;
    assign inst_exception_cause2 [1] = execute_exception_cause2_i;
    assign inst_exception_cause2 [2] = dispatch_exception_cause2_i;
    assign inst_exception_cause2 [3] = decoder_exception_cause2_i;
    assign inst_exception_cause2 [4] = instbuffer_exception_cause2_i;
    assign inst_exception_cause2 [5] = pc_exception_cause2_i;

    wire [6:0] excp_vec1;
    wire [6:0] excp_vec2;
    assign excp_vec1 = {csr_is_interrupt_i, inst_is_exception1};
    assign excp_vec2 = {csr_is_interrupt_i, inst_is_exception2};

    always @(*) begin
        case(excp_vec1) 
            7'b1??????: exception_cause1 = `EXCEPTION_INT; 
            7'b01?????: exception_cause1 = inst_exception_cause1[5]; 
            7'b001????: exception_cause1 = inst_exception_cause1[4];
            7'b0001???: exception_cause1 = (is_privilege_i[0] && csr_crmd_i[1:0] != 2'b00) ? `EXCEPTION_IPE : inst_exception_cause1[3];
            7'b00001??: exception_cause1 = inst_exception_cause1[2];
            7'b000001?: exception_cause1 = inst_exception_cause1[1];
            7'b0000001: exception_cause1 = inst_exception_cause1[0];
            default:    exception_cause1 = `EXCEPTION_NOP; 
        endcase
    end

    always @(*) begin
        case(excp_vec2) 
            7'b1??????: exception_cause2 = `EXCEPTION_INT; 
            7'b01?????: exception_cause2 = inst_exception_cause2[5]; 
            7'b001????: exception_cause2 = inst_exception_cause2[4];
            7'b0001???: exception_cause2 = (is_privilege_i[1] && csr_crmd_i[1:0] != 2'b00) ? `EXCEPTION_IPE : inst_exception_cause2[3];
            7'b00001??: exception_cause2 = inst_exception_cause2[2];
            7'b000001?: exception_cause2 = inst_exception_cause2[1];
            7'b0000001: exception_cause2 = inst_exception_cause2[0];
            default:    exception_cause2 = `EXCEPTION_NOP; 
        endcase
    end

    //异常原因编码
    wire [6:0] exception_cause_out;
    assign exception_cause_out = is_exception[0] ? exception_cause1 : exception_cause2;
    assign csr_exception_cause_o = exception_cause_out;

    always @(*) begin
        case (exception_cause_out)
             `EXCEPTION_INT: begin
                csr_ecode_o = 6'h0;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_PIL: begin
                csr_ecode_o = 6'h1;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_PIS: begin
                csr_ecode_o = 6'h2;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_PIF: begin
                csr_ecode_o = 6'h3;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_PME: begin
                csr_ecode_o = 6'h4;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_PPI: begin
                csr_ecode_o = 6'h7;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_ADEF: begin
                csr_ecode_o = 6'h8;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_ADEM: begin
                csr_ecode_o = 6'h8;
                csr_esubcode_o = 9'b1;
            end
            `EXCEPTION_ALE: begin
                csr_ecode_o = 6'h9;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_SYS: begin
                csr_ecode_o = 6'hb;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_BRK: begin
                csr_ecode_o = 6'hc;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_INE: begin
                csr_ecode_o = 6'hd;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_IPE: begin
                csr_ecode_o = 6'he;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_FPD: begin
                csr_ecode_o = 6'hf;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_FPE: begin
                csr_ecode_o = 6'h12;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_TLBR: begin
                csr_ecode_o = 6'h3f;
                csr_esubcode_o = 9'b0;
            end
            default: begin
                csr_ecode_o = 6'h0;
                csr_esubcode_o = 9'b0;
            end
        endcase
    end

    //暂停pause
    wire pause_idle; //这个是commit stage的idle状态
    assign pause_idle = is_idle_i[0] && !csr_is_interrupt_i;

    reg [4:0] pause_back;
    wire pause_buffer_temp;
    wire [1:0] pause_front;

    always @(*) begin
        if(pause_mem || pause_idle) begin
            pause_back = 5'b01111;
        end 
        else if (pause_execute) begin
            pause_back = 5'b00111;
        end 
        else if (pause_dispatch) begin
            pause_back = 5'b00011;
        end 
        else if (pause_decode) begin
            pause_back = 5'b00001;
        end 
        else begin
            pause_back = 5'b00000;
        end
    end

    assign pause_buffer_temp = pause_decode ? 1'b1 : 1'b0;
    assign pause_front = pause_buffer ? 2'b11 : 2'b00;

    assign pause = {pause_back, pause_buffer_temp, pause_front[1] && !flush[1], pause_front[0]};
endmodule