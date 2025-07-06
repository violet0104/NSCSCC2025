module cache_ram
(
    input clk,
    input we,
    input [5:0] w_index,
    input [5:0] r_index1,
    input [5:0] r_index2,
    input [150:0] data_in,
    input rst,
    output reg [150:0] data_out1,
    output reg [150:0] data_out2
);

(* ram_style = "block" *)reg [150:0] data [63:0];

integer i;
always @(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        for (i = 0; i < 64; i = i + 1)
        begin
            data[i] <= 151'b0;  // 151位全0
        end
        data_out1 <= 151'b0;
        data_out2 <= 151'b0;
    end
    else
    begin
        data_out1 <= (we && w_index==r_index1) ? data_in : data[r_index1];
        data_out2 <= (we && w_index==r_index2) ? data_in : data[r_index2];
        if(we) data[w_index] <= data_in;
    end
end

endmodule