module icache_ram
(
    input clk,
    input we1,
    input we2,
    input [2:0] index1,
    input [2:0] index2,
    input [153:0] data_in,
    input rst,
    output reg [153:0] data_out1,
    output reg [153:0] data_out2
);

reg [153:0] data [7:0];

integer i;
always @(posedge clk)
begin
    if(rst)
    begin
        for (i = 0; i < 8; i = i + 1)
        begin
            data[i] <= 154'b0;  // 151位全0
        end
        data_out1 <= 154'b0;
        data_out2 <= 154'b0;
    end
    else
    begin
        data_out1 <= (we1 | index1==index2 & we2) ? data_in : data[index1];
        data_out2 <= (we2 | index1==index2 & we1) ? data_in : data[index2];
        if(we1) data[index1] <= data_in;
        else if(we2) data[index2] <= data_in;
    end
end

endmodule