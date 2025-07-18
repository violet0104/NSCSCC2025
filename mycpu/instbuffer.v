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

    input wire  pc_is_exception_in1,
    input wire  pc_is_exception_in2,
    input wire [6:0] pc_exception_cause_in1,
    input wire [6:0] pc_exception_cause_in2,

    output wire [103:0] data_out1,      
    output wire [103:0] data_out2,
    output wire [1:0] data_valid,

    output wire stall
);
    wire stall1;
    wire full1;
    wire empty1;
    wire stall2;
    wire full2;
    wire empty2;

    wire [103:0] push_data1 = {pred_addr,  pc1,inst1,pc_is_exception_in1,pc_exception_cause_in1};
    wire [103:0] push_data2 = {pred_addr+4,pc2,inst2,pc_is_exception_in2,pc_exception_cause_in2};

    assign data_valid[0] = !empty1 & !empty2 & get_data_req;
    assign data_valid[1] = data_valid[0];
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