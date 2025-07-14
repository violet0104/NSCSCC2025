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

    input wire is_exception,
    input wire [6:0] exception_cause,

    output wire [103:0] data_out1,
    output wire [103:0] data_out2,
    output wire data_valid,

    output wire stall
);
    wire stall1;
    wire full1;
    wire empty1;
    wire stall2;
    wire empty2;
    wire full2;
    wire empty2;

    wire push_data1 = {pred_addr,pc1,inst1,is_exception,exception_cause};
    wire push_data2 = {pred_addr+4,pc2,inst2,is_exception,exception_cause};

    assign data_valid = !empty1 & !empty2 & get_data_req;
    assign stall = stall1 | full1;

    FIFO fifo1
    (
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .push_en(inst_valid),
        .push_data(push_data1),
        .pop_en(get_data_req),
        .pop_data(data_out1),
        .empty(empty1),
        .full(full1),
        .stall(stall1)
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