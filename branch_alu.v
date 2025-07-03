
module branch_alu (
    input wire [31:0] pc,          // 当前指令地址
    input wire [31:0] inst,        // 当前指令码
    input wire [7:0]  aluop,       // ALU操作类型

    input wire [31:0] reg1,        // 操作数1的值
    input wire [31:0] reg2,        // 操作数2的值

    input wire pre_is_branch_taken,     // 预测分支跳转指令是否跳转
    input wire [31:0] pre_branch_addr,  // 预测分支跳转指令目标地址

    output wire update_en,                  // 分支预测器更新使能信号
    output wire taken_or_not_actual,        // 分支跳转指令实际是否跳转
    output wire [31:0] branch_actual_addr,  // 分支跳转指令实际跳转地址
    output wire [31:0] pc_dispatch          // 传给dispatch的pc

    output reg branch_flush,             // 分支预测状态刷新信号
    output wire [31:0] branch_alu_res     // ALU计算结果 
);

    wire reg1_eq_reg2;          // 操作数1和操作数2是否相等
    wire reg1_lt_reg2;          // 操作数1是否小于操作数2

    assign reg1_eq_reg2 = (reg1 == reg2);

    wire [31:0] reg2_i_mux;     // 操作数2的选择
    
    wire [31:0] sum_result;     // 加法器结果

    assign reg2_i_mux = ((alu_op == `ALU_BLT) || (alu_op == `ALU_BGE)) ? ~reg2 + 1 : reg2;
    assign sum_result = reg1 + reg2_i_mux;

    assign reg1_lt_reg2 = ((aluop == `ALU_BLT) || (aluop == `ALU_BGE)) ? 
                          ((reg1[31] && !reg2[31]) ||                      // 符号不同且reg1为负
                           (!reg1[31] && !reg2[31] && sum_result[31]) ||   // 同正且相减结果为负
                           (reg1[31] && reg2[31] && sum_result[31])        // 同负且相减结果为负
                          ) : (reg1 < reg2);  // 无符号比较

    wire [31:0] branch16_addr = {{14{inst[25]}}, inst[25:10], 2'b00};           // 符号扩展16位地址偏移量
    wire [31:0] branch26_addr = {{4{inst[9]}}, inst[9:0], inst[25:10], 2'b00};  // 符号扩展26为地址偏移量

    reg is_branch;                 // 是否为分支指令 
    reg is_branch_taken;           // 分支指令是否跳转
    reg [31:0] branch_target_addr; // 分支指令目标地址

    assign branch_alu_res = pc + 32'h4;

    always @(*) begin
        case (aluop) 
            `ALU_BEQ: begin
                is_branch           =  1'b1;
                is_branch_taken     =  reg1_eq_reg2 ? 1'b1 : 1'b0;
                branch_target_addr  =  pc + branch16_addr;
            end
            
            `ALU_BNE: begin
                is_branch           =  1'b1;
                is_branch_taken     =  !reg1_eq_reg2 ? 1'b1 : 1'b0;
                branch_target_addr  =  pc + branch16_addr;
            end

            `ALU_BLT, `ALU_BLTU: begin
                is_branch = 1'b1;
                is_branch_taken     =  reg1_lt_reg2 ? 1'b1 : 1'b0;
                branch_target_addr  =  pc + branch16_addr;
            end

            `ALU_BGE, `ALU_BGEU: begin
                is_branch           =  1'b1;
                is_branch_taken     =  !reg1_lt_reg2 ? 1'b1 : 1'b0;
                branch_target_addr  =  pc + branch16_addr;
            end

            `ALU_B: begin
                is_branch           =  1'b1;
                is_branch_taken     =  1'b1;
                branch_target_addr  =  pc + branch26_addr;
            end

            `ALU_BL: begin
                is_branch           =  1'b1;
                is_branch_taken     =  1'b1;
                branch_target_addr  =  pc + branch26_addr;
            end

            `ALU_JIRL: begin
                is_branch           =  1'b1;
                is_branch_taken     =  1'b1;
                branch_target_addr  =  reg1 + branch16_addr;
            end

            default: begin
                is_branch           =  1'b0;
                is_branch_taken     =  1'b0;
                branch_target_addr  =  32'b0; // 默认不跳转
            end
        endcase
    end

    wire [2:0] branch_pre_vec;      // 分支预测向量（用于更新分支刷新信号）
    assign branch_pre_vec = {is_branch, is_branch_taken, pre_is_branch_taken};

    // 分支刷新信号更新逻辑
    always @(*) begin
        case (branch_pre_vec)
            // 情况1：预测正确，但预测跳转地址可能错误
            3'b111: begin
                branch_flush = |(pre_branch_addr ^ branch_target_addr);     // 预测跳转地址和实际地址相同，则不用刷新
            end

            // 情况2：预测错误
            3'b110, 3'b101: begin
                branch_flush = 1'b1;        // 必须刷新流水线
            end

            // 其他情况：预测正确或为非分支指令
            default: begin
                branch_flush = 1'b0;
            end
        endcase
    end

    always @(*) begin
        case (branch_pre_vec)
            3'b111, 3'b110: begin
                taken_or_not_actual = 1'b1;
                branch_actual_addr  = branch_target_addr;
            end

            3'b101: begin
                taken_or_not_actual = 1'b0;
                branch_actual_addr  = pc + 32'h4;
            end

            default: begin
                taken_or_not_actual = 1'b0;
                branch_actual_addr  = 32'b0; 
            end
        endcase    
    end

    assign pc_dispatch = pc;
    assign update_en   = is_branch && (aluop != `ALU_B || aluop != `ALU_BL); 

endmodule