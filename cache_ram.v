module cache_ram
(
    input clk,
    input we,
    input [5:0] w_index,
    input [5:0] r_index,
    input [150:0] data_in,
    input rst,
    output reg [150:0] data_out
);

(* ram_style = "block" *)reg [150:0] data [63:0];

integer i;
always @(posedge clk)
begin
    if(rst)
    begin
        for (i = 0; i < 64; i = i + 1)
        begin
            data[i] <= 151'b0;  // 151位全0
        end
        data_out <= 151'b0;
    end
    else
    begin
        data_out <= data[r_index];
        if(we) data[w_index] <= data_in;
    end
end

endmodule