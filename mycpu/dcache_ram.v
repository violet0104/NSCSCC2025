module dcache_ram
(
    input clk,
    input [15:0] we,
    input [2:0] w_index,
    input [2:0] r_index,
    input [127:0] data_in,
    input rst,
    output reg [127:0] data_out
);

reg [127:0] data [7:0];

integer i;
wire [127:0] write_data;
wire [127:0] choose;
assign choose = {{8{we[15]}},{8{we[14]}},{8{we[13]}},{8{we[12]}},{8{we[11]}},{8{we[10]}},{8{we[9]}},{8{we[8]}},{8{we[7]}},{8{we[6]}},{8{we[5]}},{8{we[4]}},{8{we[3]}},{8{we[2]}},{8{we[1]}},{8{we[0]}}};
assign write_data = (data[w_index] & (~choose)) | (choose & data_in);
always @(posedge clk)
begin
    if(rst)
    begin
        for (i = 0; i < 64; i = i + 1)
        begin
            data[i] <= 128'b0;  // 151位全0
        end
        data_out <= 128'b0;
    end
    else
    begin
        data_out <= (we && w_index == r_index) ? write_data : data[r_index];
        if(we) data[w_index] <= write_data;
    end
end

endmodule