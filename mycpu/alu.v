`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"


module alu (
    input wire clk,
    input wire rst,
    input wire flush,           // 流水线刷新信号

    input wire pause_mem_i,       // 访存阶段暂停信号

    // 来自dispatch的指令信息
    input wire [31:0] pc_i,
    input wire [31:0] inst_i,

    input wire [3:0] is_exception_i,
    input wire [6:0] pc_exception_cause_i,
    input wire [6:0] instbuffer_exception_cause_i,
    input wire [6:0] decoder_exception_cause_i,
    input wire [6:0] dispatch_exception_cause_i,

    input wire is_privilege_i,
    input wire valid_i,

    input wire [7:0] aluop_i,
    input wire [2:0] alusel_i,

    input wire [31:0] reg_data1_i,
    input wire [31:0] reg_data2_i,  

    input wire reg_write_en_i,                // 寄存器写使能
    input wire [4:0] reg_write_addr_i,        // 寄存器写地址

    input wire [31:0] csr_read_data_i,      // csr读数据
    input wire csr_write_en_i,              // csr写使能
    input wire [13:0] csr_addr_i,           // csr地址 

    input wire [4:0] invtlb_op_i,

    input wire pre_is_branch_taken_i,      // 预测分支指令是否跳转
    input wire [31:0] pre_branch_addr_i,   // 预测分支指令跳转地址


    // 来自 stable counter 的计数器
    input wire [63:0] cnt_i,

    // 和dcache的接口
    input wire dcache_pause,

    output wire valid_o,
    output wire [31:0] virtual_addr_o,
    output reg ren_o,
    output reg [31:0] wdata_o,
    output reg [3:0] wstrb_o,          // 访存地址字节偏移

    // 输出给 bpu 的信息, 到分支预测单元的更新
    output wire taken_or_not_actual_o,
    output wire [31:0] branch_actual_addr_o,
    output wire [31:0] pc_dispatch_o,         // 发射阶段的pc

    // 输出给 ctrl 的信号
    output wire pause_alu_o,                    // alu暂停信号
    output wire branch_flush_o,                 // 分支刷新信号
    output wire [31:0] branch_target_addr_o,    // 分支目标地址

    // 输出给 dispatch 的信号
    output wire [7:0] pre_ex_aluop_o,     // 到发射阶段的aluop，用于判断ex阶段的指令是否是load

    // 输出给 mem 的信号
    output wire [31:0] pc_mem,
    output wire [31:0] inst_mem,

    output wire [4:0] is_exception_o,
    output wire [6:0] pc_exception_cause_o,
    output wire [6:0] instbuffer_exception_cause_o,
    output wire [6:0] decoder_exception_cause_o,
    output wire [6:0] dispatch_exception_cause_o,
    output wire [6:0] execute_exception_cause_o,
    
    output wire is_privilege_mem,
    output wire is_ertn_mem,
    output wire is_idle_mem,
    output wire valid_mem,

    output wire reg_write_en_mem, 
    output wire [4:0] reg_write_addr_mem,
    output reg [31:0] reg_write_data_mem,
    
    output wire [7:0] aluop_mem,         
    output reg [31:0] addr_mem,
    output wire [31:0] data_mem,

    output reg csr_write_en_mem,
    output reg [13:0] csr_addr_mem,
    output reg [31:0] csr_write_data_mem,

    output reg is_llw_scw_mem
);

    wire [31:0] reg_data1;
    wire [31:0] reg_data2;
    assign reg_data1 = reg_data1_i;   // 源操作数1
    assign reg_data2 = reg_data2_i;   // 源操作数2

    assign pc_mem      = pc_i;
    assign inst_mem    = inst_i;
    assign valid_mem   = valid_i;
    assign is_privilege_mem = is_privilege_i;
    assign aluop_mem   = aluop_i;
    assign is_ertn_mem = (aluop_i == `ALU_ERTN);
    assign is_idle_mem = (aluop_i == `ALU_IDLE);

    //异常处理
    reg ex_mem_exception;
    assign is_exception_o = {is_exception_i, ex_mem_exception};  
    assign pc_exception_cause_o = pc_exception_cause_i;
    assign instbuffer_exception_cause_o = instbuffer_exception_cause_i;
    assign decoder_exception_cause_o = decoder_exception_cause_i;
    assign dispatch_exception_cause_o = dispatch_exception_cause_i;
    assign execute_exception_cause_o = `EXCEPTION_ALE;      // 执行阶段的异常原因

    
    // 预执行alu操作类型
    assign pre_ex_aluop_o = aluop_i;

    // regular alu 
    wire [31:0] regular_alu_res;

    regular_alu u_regular_alu (
        .aluop(aluop_i),
        .reg1(reg_data1),
        .reg2(reg_data2),
        .result(regular_alu_res)
    );

    // mul alu
    reg [31:0] mul_alu_res;    // 乘法器输出结果
    wire pause_ex_mul;
    wire is_mul;
    reg start_mul;
    wire signed_mul;
    wire mul_done;
    wire [63:0] mul_result;
    reg [31:0] mul_data1;
    reg [31:0] mul_data2;
        
    assign is_mul = (aluop_i == `ALU_MULW || aluop_i == `ALU_MULHW || aluop_i == `ALU_MULHWU ) && !mul_done;
    assign pause_ex_mul = is_mul && !mul_done;      // 乘法未完成时暂停

    always @(posedge clk) begin
        if (rst) begin
            start_mul <= 1'b0 ;
            mul_data1 <= 32'b0;
            mul_data2 <= 32'b0;
        end else if (start_mul) begin
            start_mul <= 1'b0;
        end else if (is_mul) begin
            start_mul <= 1'b1;
            mul_data1 <= reg_data1;
            mul_data2 <= reg_data2;
        end else begin
            start_mul <= 1'b0;
        end
    end

    assign signed_mul = (aluop_i == `ALU_MULW || aluop_i == `ALU_MULHW);      // 有符号乘法

    mul_alu u_mul_alu (
        .clk(clk),
        .rst(rst),
        .start(start_mul),
        .signed_op(signed_mul),
        .reg1(mul_data1),
        .reg2(mul_data2),
        .done(mul_done),
        .result(mul_result)
    );

    // 结果选择
    always @(*) begin
        case (aluop_i)
            `ALU_MULW: begin
                mul_alu_res = mul_result[31:0];     // 低32位
            end

            `ALU_MULHW, `ALU_MULHWU: begin
                mul_alu_res = mul_result[63:32];    // 高32位
            end

            default: begin
                mul_alu_res = 32'b0;
            end
        endcase
    end

    // div alu
    reg [31:0] div_alu_res;
    wire pause_ex_div;
    wire is_div;
    reg start_div;          // 这个地方学长有个logic is_running，我这里删掉了
    wire signed_div;
    wire div_done;
    wire [31:0] remainder;
    wire [31:0] quotient;
    reg [31:0] div_data1;
    reg [31:0] div_data2;
    wire is_running;

    assign is_div = (aluop_i == `ALU_DIVW || aluop_i == `ALU_DIVWU
                    || aluop_i == `ALU_MODW || aluop_i == `ALU_MODWU) && !div_done;
    assign pause_ex_div = is_div && !div_done;  // 除法未完成时暂停

    assign signed_div = aluop_i == `ALU_DIVW || aluop_i == `ALU_MODW;

    always @(posedge clk) 
    begin
        if (rst) begin
            start_div <= 1'b0 ;
            div_data1 <= 32'b0;
            div_data2 <= 32'b0;
        end
        else if (start_div)
        begin
            start_div <= 1'b0;
        end 
        else if(is_div && !is_running)
        begin
            start_div <= 1'b1;
            div_data1 <= reg_data1;
            div_data2 <= reg_data2;
        end
        else begin
            start_div <= 1'b0;
        end
    end 

    div_alu u_div_alu 
    (
        .clk(clk),
        .rst(rst),
        .op(signed_div),
        .dividend(div_data1),
        .divisor(div_data2),
        .start(start_div),

        .is_running(is_running),
        .quotient_out(quotient),
        .remainder_out(remainder),
        .done(div_done)
    );

    // 结果选择
    always @(*) begin
        case (aluop_i) 
            `ALU_DIVW, `ALU_DIVWU: begin
                div_alu_res = quotient;  // 商
            end

            `ALU_MODW, `ALU_MODWU: begin
                div_alu_res = remainder;  // 余数
            end

            default: begin
                div_alu_res = 32'b0;      // 其他情况
            end
        endcase
    end
    // branch alu
    wire [31:0] branch_alu_res;

    branch_alu u_branch_alu (
        .pc(pc_i),
        .inst(inst_i),
        .aluop(aluop_i),

        .reg1(reg_data1),
        .reg2(reg_data2),

        .pre_is_branch_taken(pre_is_branch_taken_i),
        .pre_branch_addr(pre_branch_addr_i),

        .taken_or_not_actual(taken_or_not_actual_o),
        .branch_actual_addr(branch_actual_addr_o),
        .pc_dispatch(pc_dispatch_o),
        .branch_flush(branch_flush_o),
        .branch_alu_res(branch_alu_res)
    );

    assign branch_target_addr_o = branch_actual_addr_o;

    // load & store alu
    wire LLbit;
    assign LLbit = csr_read_data_i[0];  // 从csr中读取LLbit

    wire [31:0] load_store_alu_res;
    assign load_store_alu_res = (aluop_i == `ALU_SCW) ? {31'b0, LLbit} : 32'b0;

    wire is_mem;
    assign is_mem =    aluop_i == `ALU_LDB || aluop_i == `ALU_LDBU 
                    || aluop_i == `ALU_LDH || aluop_i == `ALU_LDHU 
                    || aluop_i == `ALU_LDW
                    || aluop_i == `ALU_STB || aluop_i == `ALU_STH 
                    || aluop_i == `ALU_STW 
                    || aluop_i == `ALU_LLW || aluop_i == `ALU_SCW
                    || aluop_i == `ALU_PRELD;
    wire pause_ex_mem;
    assign pause_ex_mem = is_mem && valid_o && dcache_pause;  

    wire [11:0] si12;
    wire [13:0] si14;
    assign si12 = inst_i[21:10];  // 12位立即数
    assign si14 = inst_i[23:10];  // 14位立即数

    always @(*) begin
        case (aluop_i) 
            `ALU_LDB, `ALU_LDBU, `ALU_LDH, `ALU_LDHU, `ALU_LDW, `ALU_LLW, `ALU_PRELD, `ALU_CACOP: begin
                addr_mem = reg_data1 + reg_data2;
            end

            `ALU_STB, `ALU_STH, `ALU_STW: begin
                addr_mem = reg_data1 + {{20{si12[11]}}, si12};
            end
            
            `ALU_SCW: begin
                addr_mem = reg_data1 + {{16{si14[13]}}, si14, 2'b00};
            end

            default: begin
                addr_mem = 32'b0;        
            end 
                       
        endcase
    end

    assign virtual_addr_o = addr_mem;  // 输出给dcache的虚拟地址

    reg mem_is_valid;
    assign valid_o = mem_is_valid && !flush && !pause_mem_i && !is_exception_o;

    always @(*) begin
        case (aluop_i)
            `ALU_LDB, `ALU_LDBU: begin
                ren_o = 1'b1;
                wstrb_o = 4'b0;
                ex_mem_exception = 1'b0;
                mem_is_valid = 1'b1;
                wdata_o = 32'b0;
            end

            `ALU_LDH, `ALU_LDHU: begin
                ren_o = (addr_mem[1:0] == 2'b00) || (addr_mem[1:0] == 2'b10);
                ex_mem_exception = (addr_mem[1:0] == 2'b01) || (addr_mem[1:0] == 2'b11);
                mem_is_valid = 1'b1;
                wdata_o = 32'b0;
                wstrb_o = 4'b0;
            end

            `ALU_LDW, `ALU_LLW: begin
                ren_o = (addr_mem[1:0] == 2'b00);
                ex_mem_exception = (addr_mem[1:0] != 2'b00);
                mem_is_valid = 1'b1;
                wdata_o = 32'b0;
                wstrb_o = 4'b0;
            end

            `ALU_STB: begin
                ex_mem_exception = 1'b0;
                mem_is_valid = 1'b1;
                ren_o = 1'b0;
                case (addr_mem[1: 0])
                    2'b00: begin
                        wstrb_o = 4'b0001;
                        wdata_o = {24'b0, reg_data2[7: 0]};
                    end 
                    2'b01: begin
                        wstrb_o = 4'b0010;
                        wdata_o = {16'b0, reg_data2[7: 0], 8'b0};
                    end
                    2'b10: begin
                        wstrb_o = 4'b0100;
                        wdata_o = {8'b0, reg_data2[7: 0], 16'b0};
                    end
                    2'b11: begin
                        wstrb_o = 4'b1000;
                        wdata_o = {reg_data2[7: 0], 24'b0};
                    end
                    default: begin
                        wstrb_o = 4'b0000;          
                        wdata_o = 32'b0;           
                    end
                endcase
            end

            `ALU_STH: begin
                ren_o = 1'b0;
                mem_is_valid = 1'b1;
                case (addr_mem[1: 0])
                    2'b00: begin
                        wstrb_o = 4'b0011;
                        wdata_o = {16'b0, reg_data2[15: 0]};
                        ex_mem_exception = 1'b0;
                    end 
                    2'b10: begin
                        wstrb_o = 4'b1100;
                        wdata_o = {reg_data2[15: 0], 16'b0};
                        ex_mem_exception = 1'b0;
                    end
                    2'b01, 2'b11: begin
                        wstrb_o = 4'b0000;
                        wdata_o = 32'b0;
                        ex_mem_exception = 1'b1;
                    end
                    default: begin
                        wstrb_o = 4'b0000; 
                        wdata_o = 32'b0;    
                        ex_mem_exception = 1'b0;        
                    end
                endcase
            end

            `ALU_STW: begin
                ren_o = 1'b0;
                ex_mem_exception = (addr_mem[1: 0] != 2'b00);
                mem_is_valid = 1'b1;
                wdata_o = reg_data2;
                wstrb_o = (addr_mem[1: 0] == 2'b00) ? 4'b1111 : 4'b0000;
            end

            `ALU_SCW: begin
                ren_o = 1'b0;
                ex_mem_exception = (addr_mem[1:0] != 2'b00);
                wstrb_o = (addr_mem[1:0] == 2'b00) ? 4'b1111 : 4'b0000;
                if (LLbit) begin
                    mem_is_valid = 1'b1;
                    wdata_o = reg_data2;
                end else begin
                    mem_is_valid = 1'b0;
                    wdata_o = 32'b0;
                end
            end

            default: begin
                ex_mem_exception = 1'b0;
                mem_is_valid = 1'b0;
                ren_o = 1'b0;
                wdata_o = 32'b0;
                wstrb_o = 4'b0000;
            end
        endcase
    end

    // csr alu
    reg [31:0] csr_alu_res;
    wire [31:0] mask_data;
    assign mask_data = ((csr_read_data_i & ~reg_data2) | (reg_data1 & reg_data2));


    always @(*) begin
        if (aluop_i == `ALU_LLW) begin
            csr_write_en_mem = 1'b1;  
            csr_addr_mem = `CSR_LLBCTL;
            csr_write_data_mem = 32'b1;
            is_llw_scw_mem = 1'b1;
        end
        else if (aluop_i == `ALU_SCW && LLbit) begin
            csr_write_en_mem = 1'b1;
            csr_addr_mem = `CSR_LLBCTL;
            csr_write_data_mem = 32'b0;
            is_llw_scw_mem = 1'b1;
        end
        else begin
            csr_write_en_mem = csr_write_en_i;
            csr_addr_mem = csr_addr_i;
            csr_write_data_mem = (aluop_i == `ALU_CSRXCHG) ? mask_data : reg_data1;
            is_llw_scw_mem = 1'b0;
        end
    end

    always @(*) begin
        case (aluop_i)
            `ALU_CSRRD, `ALU_CSRWR, `ALU_CSRXCHG: begin
                csr_alu_res = csr_read_data_i;  // 读csr寄存器
            end

            `ALU_RDCNTID: begin
                csr_alu_res = csr_read_data_i;   // 读csr寄存器
            end

            `ALU_RDCNTVLW: begin
                csr_alu_res = cnt_i[31:0];      // 读计数器低32位
            end

            `ALU_RDCNTVHW: begin
                csr_alu_res = cnt_i[63:32];       // 读计数器高32位
            end

            `ALU_CPUCFG: begin
                csr_alu_res = csr_read_data_i;
            end
            default: begin
                csr_alu_res = 32'b0;            // 其他情况
            end
        endcase
    end
    
    // 寄存器数据
    assign reg_write_en_mem = !ex_mem_exception ? reg_write_en_i : 1'b0;
    assign reg_write_addr_mem = reg_write_addr_i;

    always @(*) begin
        case (alusel_i) 
            `ALU_SEL_ARITHMETIC: begin
                reg_write_data_mem = regular_alu_res;    // 普通算术运算
            end

            `ALU_SEL_MUL: begin
                reg_write_data_mem = mul_alu_res;        // 乘法
            end

            `ALU_SEL_DIV: begin
                reg_write_data_mem = div_alu_res;        // 除法
            end

            `ALU_SEL_JUMP_BRANCH: begin
                reg_write_data_mem = branch_alu_res;     // 分支指令
            end

            `ALU_SEL_LOAD_STORE: begin
                reg_write_data_mem = reg_data2_i; // 访存指令
            end

            `ALU_SEL_CSR: begin
                reg_write_data_mem = csr_alu_res;        // csr操作
            end

            default: begin
                reg_write_data_mem = 32'b0;              // 默认情况
            end
        endcase
    end

    // 暂停信号
    assign pause_alu_o = pause_ex_mul || pause_ex_div || pause_ex_mem;

endmodule