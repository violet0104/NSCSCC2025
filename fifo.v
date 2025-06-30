module FIFO
(
    input wire clk,
    input wire rst,
    input wire flush,

    input wire push_en,
    input wire [96:0] push_data,
    input wire pop_en,
    output wire [96:0] pop_data,
    output wire empty,
    output wire full,
    output wire stall
);
    localparam length = 4;

    reg [3:0] write_index;   
    reg [3:0] read_index;
    reg [96:0] data [15:0];  //32+32+32+1
    
    assign empty = write_index == read_index;
    assign full  = read_index == (write_index + 1)%16;
    assign stall = read_index == (write_index + 2)%16;
    assign pop_data = data[read_index];
    
    integer i;
    always @(posedge clk or negedge rst)
    begin
        if(!rst | flush)
        begin
            write_index <= 4'b0;
            read_index <= 4'b0;
            for(i=0; i<16; i=i+1)
                data[i] <= 97'b0;
        end
        else 
        begin
            if(push_en & !full)
            begin
                data[write_index] <= push_data;
                write_index <= write_index +1;
            end
            if(pop_en & !empty)
            begin
                read_index <= read_index + 1;
            end
        end
    end

endmodule