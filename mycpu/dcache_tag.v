module dcache_tag
(
    input clk,
    input we,
    input [2:0] w_index,
    input [2:0] r_index,
    input [25:0] data_in,
    input rst,
    output reg [25:0] data_out
);

reg [25:0] data [7:0];

integer i;
always @(posedge clk)
begin
    if(rst)
    begin
        for (i = 0; i < 8; i = i + 1)
        begin
            data[i] <= 26'b0;  // 151浣嶅叏0
        end
        data_out <= 26'b0;
    end
    else
    begin
        data_out <= (we && w_index == r_index) ? data_in : data[r_index];
        if(we) data[w_index] <= data_in;
    end
end

endmodule