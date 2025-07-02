
module branch_alu (
    input wire [31:0] pc,          // 当前指令地址
    input wire [31:0] inst,        // 当前指令码
    input wire [7:0]  aluop,       // ALU操作类型

    input wire [31:0] reg1,        // 寄存器1的值
    input wire [31:0] reg2,        // 寄存器2的值

    input wire pre_is_branch_taken,     // 预测分支跳转指令是否跳转
    input wire [31:0] pre_branch_addr,  // 预测分支跳转指令跳转地址

    output branch_updata
);

endmodule