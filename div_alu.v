module div_alu (
    input wire clk,
    input wire rstn,

    input wire start,               // 除法运算开始信号
    input wire signed_op,           // 操作数有无符号选择（1表示有符号数，0表示无符号数）
    input wire [31:0] dividend,     // 被除数
    input wire [31:0] divisor,      // 除数

    output wire [31:0] remainder_out,   // 余数
    output wire [31:0] quotient_out,    // 商
    output wire divide_by_zero,         // 是否除零标志（1表示发生了除零错误）
    output wire done                    // 除法运算完成信号
);

    wire valid_signed    = start & signed_op;      // 有符号除法有效信号
    wire valid_unsigned  = start & ~signed_op;     // 无符号除法有效信号

    wire [31:0] s_axis_dividend = dividend;
    wire [31:0] s_axis_divisor  = divisor;

    wire [63:0] m_axis_tdata_signed;     // 有符号除法结果
    wire        m_axis_tuser_signed;     // 有符号除法除零信号
    wire        m_axis_tvalid_singned;   // 有符号除法结果有效信号

    wire [63:0] m_axis_tdata_unsigned;   // 无符号除法结果
    wire        m_axis_tuser_unsigned;   // 无符号除法除零信号
    wire        m_axis_tvalid_unsingned; // 无符号除法结果有效信号

    // 除法器IP核实例化
    div_gen_0 u_divider_0 (
        .aclk(clk),
        .aresetn(rstn),
        .s_axis_dividend_tdata(s_axis_dividend),
        .s_axis_dividend_tvalid(valid_signed), 
        .s_axis_divisor_tdata(s_axis_divisor),
        .s_axis_divisor_tvalid(valid_signed),

        .m_axis_dout_tdata(m_axis_tdata_signed),
        .m_axis_dout_tuser(m_axis_tuser_signed),
        .m_axi_dout_tvalid(m_axis_tvalid_singned)
    );

    div_gen_1 u_divider_1 (
        .aclk(clk),
        .aresetn(rstn),
        .s_axis_dividend_tdata(s_axis_dividend),
        .s_axis_dividend_tvalid(valid_unsigned), 
        .s_axis_divisor_tdata(s_axis_divisor),
        .s_axis_divisor_tvalid(valid_unsigned),

        .m_axis_dout_tdata(m_axis_tdata_unsigned),
        .m_axis_dout_tuser(m_axis_tuser_unsigned),
        .m_axi_dout_tvalid(m_axis_tvalid_unsingned)
    );

    // 选择有符号或无符号除法结果
    assign remainder_out  = signed_op ? m_axis_tdata_signed[31:0] : m_axis_tdata_unsigned[31:0];
    assign quotient_out   = signed_op ? m_axis_tdata_signed[63:32] : m_axis_tdata_unsigned[63:32];
    assign divide_by_zero = signed_op ? m_axis_tuser_signed : m_axis_tuser_unsigned;
    assign done           = signed_op ? m_axis_tvalid_singned : m_axis_tvalid_unsingned;

endmodule