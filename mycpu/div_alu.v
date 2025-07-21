module div_alu
(
    input wire clk,
    input wire rst,

    input wire valid_in,
    input wire [31:0] a,
    input wire [31:0] b,
    input wire sign,

    output reg [31:0] div,
    output reg [31:0] rest,
    output wire div_zero_error,
    output reg valid_out
);

    reg [3:0] count;
    reg dealing;
    assign div_zero_error = valid_out & b == 0;
    always @(posedge clk)
    begin
        if(rst)
        begin
            count <= 0;
            div <= 0;
            rest <= 0;
            valid_out <= 0;
            dealing <= 0;
        end
        else 
        begin
            if(valid_in) dealing <= 1;
            if(count == 7)
            begin
                count <= 0;
                valid_out <= 1;
                dealing <= 0;
                if(sign & b!=0)
                begin
                    div <= $signed(a)/$signed(b);
                    rest <= $signed(a)%$signed(b);
                end
                else if(b!=0)
                begin
                    div <= a / b;
                    rest <= a % b;
                end
            end
            else if(dealing)
            begin
                count <= count + 1;
            end
            else 
            begin
                valid_out <= 0;
            end
        end
    end 
   
endmodule