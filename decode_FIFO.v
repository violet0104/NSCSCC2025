module decode_FIFO
(
    input wire clk,
    input wire rst,
    input wire flush,
    //与前端的交互信号
    input wire data_valid,
    input wire [96:0] data1,
    input wire [96:0] data2,
    output wire data_req,
    //与后端的交互信号
    input wire [1:0] control,
    output reg [96:0] inst_data1,
    output reg [96:0] inst_data2,
    output reg data_valid1,
    output reg data_valid2
);

    reg [96:0] data [7:0];
    reg [7:0] valid;
    wire [2:0] count;
    reg [2:0] read_index;
    reg [2:0] write_index;

    wire stall = read_index == (write_index+1)%8;
    wire full = read_index == (write_index+2)%8;

    assign count = valid[0]+valid[1]+valid[2]+valid[3]+valid[4]+valid[5]+valid[6]+valid[7];
    assign data_req = !full & !stall;

    integer i;

//后续可添加写直达功能
    always @(posedge clk or negedge rst)
    begin
        if(!rst | flush)
        begin
            read_index <= 3'b0;
            write_index <= 3'b0;
            inst_data1 <= 97'b0;
            inst_data2 <= 97'b0;
            data_valid1 <= 1'b0;
            data_valid2 <= 1'b0;
            for(i=0;i<8;i=i+1)
            begin
                valid[i] <= 1'b0;
                data[i] <= 97'b0;
            end
        end
        else
        begin
            if(control == 2'b00 | count == 0)
            begin
                data_valid1 <= 1'b0;
                data_valid2 <= 1'b0;
            end
            else if((control == 2'b01 & count>=1)|(control == 2'b10 & count ==1))
            begin
                inst_data1 <= data[read_index];
                data_valid1 <= 1'b1;
                data_valid2 <= 1'b0;
                valid[read_index] <= 1'b0;
                read_index <= (read_index+1)%8;
            end
            else if(control == 2'b10 & count >=2)
            begin
                inst_data1 <= data[read_index];
                inst_data2 <= data[(read_index+1)%8];
                data_valid1 <= 1'b1;
                data_valid2 <= 1'b1;
                valid[read_index] <= 1'b0;
                valid[(read_index+1)%8] <= 1'b0;
                read_index <= (read_index+2)%8;
            end
            if(data_valid)
            begin
                data[write_index] <= data1;
                data[(write_index+1)%8] <= data2;
                valid[write_index] <= 1'b1;
                valid[(write_index+1)%8] <= 1'b1;
                write_index <= (write_index+2)%8;
            end
        end
    end

endmodule