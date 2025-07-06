module instbuffer
(
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

    output wire [96:0] data_out1,
    output wire [96:0] data_out2,
    output wire data_valid,

    output wire stall,
    output wire empty,
    output wire full
);
    wire stall2;
    wire empty2;
    wire full2;

    wire push_data1 = {pred_taken1,pred_addr,pc1,inst1};
    wire push_data2 = {pred_taken2,pred_addr,pc2,inst2};

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

endmodule