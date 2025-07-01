module instbuffer (
    input wire clk,
    input wire rst,
    input wire flush,
    input wire get_data_req,
    input wire inst_valid,
    input wire [31:0] pc1,
    input wire [31:0] pc2,
    input wire [31:0] inst1,
    input wire [31:0] inst2,
    input wire [31:0] pred_addr,
    input wire pred_taken1,
    input wire pred_taken2,

    output reg [1:0] [31:0] pc_out,
    output reg [1:0][31:0] inst_out,
    output reg [1:0] valid_out,
    output reg [1:0] pretaken_out,
    output reg [1:0][31:0] pre_addr_out,

    output wire data_valid,

    output wire stall,
    output wire empty,
    output wire full

    // 中断异常还没加
);
    wire stall2;
    wire empty2;
    wire full2;

    wire push_data1 = {pred_taken1,pred_addr,pc1,inst1};
    wire push_data2 = {pred_taken2,pred_addr,pc2,inst2};

    wire [96:0] data_out1;
    wire [96:0] data_out2;

    assign data_valid = !empty & get_data_req;

    FIFO fifo1
    (
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .push_en(inst_valid),
        .push_data(push_data1),
        .pop_en(get_data_req),
        .pop_data(data_out1),
        .empty(empty),
        .full(full),
        .stall(stall)
    );

    FIFO fifo2
    (
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .push_en(inst_valid),
        .push_data(push_data2),
        .pop_en(get_data_req),
        .pop_data(data_out2),
        .empty(empty2),
        .full(full2),
        .stall(stall2)
    );


    // 分解数据
    always @(*) begin
        pc_out[0]       = data_out1[63:32];
        inst_out[0]     = data_out1[31:0];
        valid_out[0]    = 1'b1;
        pretaken_out[0] = data_out1[96];
        pre_addr_out[0] = data_out1[95:64];

        pc_out[1]       = data_out2[63:32];
        inst_out[1]     = data_out2[31:0];
        valid_out[1]    = 1'b1;
        pretaken_out[1] = data_out2[96];
        pre_addr_out[1] = data_out2[95:64];
    end

endmodule