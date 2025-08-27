`timescale 1ns / 1ps
module BPU 
(
    input  wire         cpu_clk    ,
    input  wire         cpu_rstn   ,        
    input  wire [31:0]  if_pc1      , 
    input  wire [31:0]  if_pc2     ,
    // predict branch direction and target
    output wire         pred_taken1,
    output wire         pred_taken2,
    output wire [31:0]  pred_addr,        
    output wire         BPU_flush ,        
    output wire [31:0]  new_pc,    
    output wire [31:0]  if_pred_addr1,
    output wire [31:0]  if_pred_addr2,

    input  wire         ex_is_bj_1   ,  
    input  wire [31:0]  ex_pc_1      ,
    input  wire         ex_valid1    ,        
    input  wire         ex_is_bj_2   ,    
    input  wire [31:0]  ex_pc_2      , 
    input  wire         ex_valid2    ,
    input  wire         real_taken1 ,        
    input  wire         real_taken2 ,
    input  wire [31:0]  real_addr1, 
    input  wire [31:0]  real_addr2,
    input  wire [31:0]  pred_addr1,
    input  wire [31:0]  pred_addr2

);

// BHT and BTB
reg  [9:0]    tag     [255:0];
reg  [255:0] valid;
reg  [1:0]    history [255:0]; 
reg  [31:0]   addr    [255:0];


wire [9:0] if_tag1 = if_pc1[19:10];
wire [9:0] if_tag2 = if_pc2[19:10];
wire [7:0] index1 = if_pc1[9:2];
wire [7:0] index2 = if_pc2[9:2];

assign pred_taken1 = (if_tag1 == tag[index1]) & valid[index1]  & history[index1][1];
assign pred_taken2 = (if_tag2 == tag[index2]) & valid[index2]  & history[index2][1];// & !pred_taken1;

assign if_pred_addr1 = pred_taken1 ? addr[index1] : (if_pc1 + 32'h4);
assign if_pred_addr2 = pred_taken2 ? addr[index2] : (if_pc2 + 32'h4);
assign pred_addr = pred_taken1 ? addr[index1] : pred_taken2 ? addr[index2] : (if_pc1 + 32'h8);

wire [9:0] ex_tag1 = ex_pc_1[19:10];
wire [9:0] ex_tag2 = ex_pc_2[19:10];
wire [7:0] ex_index1 = ex_pc_1[9:2];
wire [7:0] ex_index2 = ex_pc_2[9:2];

wire add1 = ex_valid1 & !valid[ex_index1] & real_taken1;
wire add2 = ex_valid2 & !valid[ex_index2] & real_taken2;
wire update1 = ex_valid1 & valid[ex_index1] & tag[ex_index1]==ex_tag1 & ex_is_bj_1;
wire update2 = ex_valid2 & valid[ex_index2] & tag[ex_index2]==ex_tag2 & ex_is_bj_2;
wire replace1 = ex_valid1 & valid[ex_index1] & real_taken1 & tag[ex_index1]!=ex_tag1;
wire replace2 = ex_valid2 & valid[ex_index2] & real_taken2 & tag[ex_index2]!=ex_tag2;

wire addr_error1 = ex_valid1 & pred_addr1 != real_addr1;     //濡�???锟斤�??????????????????锟斤�????????锟斤拷顏堕梺璺ㄥ枑锟�????锟斤拷骞忛悿锟�??????????????????锟斤拷鍠愰弸濠氾�???????????锟�?�姤鏅革�????????????????锟斤�?????????????锟斤拷锟�???P???????鍛婏�??????????锟斤�???????????????????????锟藉棘閵堝棗???????????锟斤拷锟�?????????閺侊�???????????锟介�????????????锟斤拷闂佽法锟�????????????锟藉�??????????锟斤拷顏讹拷?????????????????锟斤拷锟�????????锟斤拷骞忛悜锟�?????????闁哄倶鍊栵拷????锟藉綊锟�???P???????鍛婄伄闁癸拷??????????????????????锟藉棘閵堝棗???????????锟斤拷璺ㄥ枑閺嬪骞忛敓锟�?????婵炲矉绻濋弫鎾诲棘閵堝棗锟�??????
wire addr_error2 = ex_valid2 & pred_addr2 != real_addr2;

assign BPU_flush = addr_error1 | addr_error2;
assign new_pc = addr_error1 ? real_addr1 : real_addr2; 

integer i;
always @(posedge cpu_clk) 
begin
    if (cpu_rstn) 
    begin
        valid <= {256{1'b0}};
    end 
    else 
    begin
        if(add1)
        begin
            history[ex_index1] <= 2'b10;
            valid[ex_index1] <= 1'b1;
            tag[ex_index1] <= ex_tag1;
            addr[ex_index1] <= real_addr1;
        end
        else if(add2 & ex_index1 != ex_index2)
        begin
            history[ex_index2] <= 2'b10;
            valid[ex_index2] <= 1'b1;
            tag[ex_index2] <= ex_tag2;
            addr[ex_index2] <= real_addr2;
        end
        if(update1)
        begin
            if(real_taken1)
            begin
                case(history[ex_index1])
                    2'b00: history[ex_index1] <= 2'b01;
                    2'b01: history[ex_index1] <= 2'b10;
                    2'b10: history[ex_index1] <= 2'b11;
                    2'b11: history[ex_index1] <= 2'b11;
                endcase
            end
            else
            begin
                case(history[ex_index1])
                2'b00: history[ex_index1] <= 2'b00;
                2'b01: history[ex_index1] <= 2'b00;
                2'b10: history[ex_index1] <= 2'b01;
                2'b11: history[ex_index1] <= 2'b10;
                endcase
            end
        end
        if(update2 & !real_taken1)
        begin
            if(real_taken2)
            begin
                case(history[ex_index2])
                    2'b00: history[ex_index2] <= 2'b01;
                    2'b01: history[ex_index2] <= 2'b10;
                    2'b10: history[ex_index2] <= 2'b11;
                    2'b11: history[ex_index2] <= 2'b11;
                endcase
            end
            else
            begin
                case(history[ex_index2])
                    2'b00: history[ex_index2] <= 2'b00;
                    2'b01: history[ex_index2] <= 2'b00;
                    2'b10: history[ex_index2] <= 2'b01;
                    2'b11: history[ex_index2] <= 2'b10;
                endcase
            end
        end
        if(replace1)
        begin
            tag[ex_index1] <= ex_tag1;
            history[ex_index1] <= 2'b10;
            addr[ex_index1] <= real_addr1;
        end
        else if(replace2 & ex_index1 != ex_index2)
        begin
            tag[ex_index2] <= ex_tag2;
            history[ex_index2] <= 2'b10;
            addr[ex_index2] <= real_addr2;
        end
    end
end

    //***********************************************
    reg [31:0] jump_correct_count;      //??????????????????
    reg [31:0] normal_correct_count;    //????????????????????
    reg [31:0] jump_inst_count;         //???????????
    reg [31:0] normal_inst_count;       //?????????????
    reg [31:0] inst_count;              //???????
    always @(posedge cpu_clk)
    begin
        if(cpu_rstn)
        begin
            jump_correct_count <= 0;
            jump_inst_count <= 0;
            normal_correct_count <= 0;
            normal_inst_count <= 0;
            inst_count <= 0;
        end
        else 
        begin
            case({ex_valid2,ex_valid1})
            2'b01:begin
                inst_count <= inst_count + 1;
                if(ex_is_bj_1) 
                begin
                    if(!addr_error1) jump_correct_count <= jump_correct_count + 1;
                    jump_inst_count <= jump_inst_count + 1;
                end
                else 
                begin
                    if(!addr_error1) normal_correct_count <= normal_correct_count + 1;
                    normal_inst_count <= normal_inst_count + 1;
                end
            end
            2'b10:begin
                inst_count <= inst_count + 1;
                if(ex_is_bj_2) 
                begin
                    if(!addr_error2) jump_correct_count <= jump_correct_count + 1;
                    jump_inst_count <= jump_inst_count + 1;
                end
                else 
                begin
                    if(!addr_error2) normal_correct_count <= normal_correct_count + 1;
                    normal_inst_count <= normal_inst_count + 1;
                end
            end
            2'b11:begin
                case({ex_is_bj_2,ex_is_bj_1})
                2'b00:begin
                    case({addr_error2,addr_error1}) 
                    2'b00:begin
                        normal_correct_count <= normal_correct_count + 2;
                        inst_count <= inst_count + 2;
                        normal_inst_count <= normal_inst_count + 2;
                    end
                    2'b01:begin
                        inst_count <= inst_count + 1;
                        normal_inst_count <= normal_inst_count + 1;
                    end
                    2'b10:begin
                        normal_correct_count <= normal_correct_count + 1;
                        inst_count <= inst_count + 2;
                        normal_inst_count <= normal_inst_count + 2;
                    end
                    2'b11:begin
                        inst_count <= inst_count + 1;
                        normal_inst_count <= normal_inst_count + 1;
                    end
                    default:;
                    endcase
                end
                2'b01:begin
                    case({addr_error2,addr_error1})
                    2'b00:begin
                        normal_correct_count <= normal_correct_count + 1;
                        jump_correct_count <= jump_correct_count + 1;
                        inst_count <= inst_count + 2;
                        normal_inst_count <= normal_inst_count + 1;
                        jump_inst_count <= jump_inst_count + 1;
                    end
                    2'b01:begin
                        inst_count <= inst_count + 1;
                        jump_inst_count <= jump_inst_count + 1;
                    end
                    2'b10:begin
                        jump_correct_count <= jump_correct_count + 1;
                        inst_count <= inst_count + 2;
                        normal_inst_count <= normal_inst_count + 1;
                        jump_inst_count <= jump_inst_count + 1;
                    end
                    2'b11:begin
                        inst_count <= inst_count + 1;
                        jump_inst_count <= jump_inst_count + 1;
                    end
                    default:;
                    endcase
                end
                2'b10:begin
                    case({addr_error2,addr_error1})
                    2'b00:begin
                        normal_correct_count <= normal_correct_count + 1;
                        jump_correct_count <= jump_correct_count + 1;
                        inst_count <= inst_count + 2;
                        normal_inst_count <= normal_inst_count + 1;
                        jump_inst_count <= jump_inst_count + 1;
                    end
                    2'b01:begin
                        inst_count <= inst_count + 1;
                        normal_inst_count <= normal_inst_count + 1;
                    end
                    2'b10:begin
                        normal_correct_count <= normal_correct_count + 1;
                        inst_count <= inst_count + 2;
                        normal_inst_count <= normal_inst_count + 1;
                        jump_inst_count <= jump_inst_count + 1;
                    end
                    2'b11:begin
                        inst_count <= inst_count + 1;
                        normal_inst_count <= normal_inst_count + 1;
                    end
                    default:;
                    endcase
                end
                2'b11:begin
                    case({addr_error2,addr_error1})
                    2'b00:begin
                        jump_correct_count <= jump_correct_count + 2;
                        inst_count <= inst_count + 2;
                        jump_inst_count <= jump_inst_count + 2;
                    end
                    2'b01:begin
                        inst_count <= inst_count + 1;
                        jump_inst_count <= jump_inst_count + 1;
                    end
                    2'b10:begin
                        jump_correct_count <= jump_correct_count + 1;
                        inst_count <= inst_count + 2;
                        jump_inst_count <= jump_inst_count + 2;
                    end
                    2'b11:begin
                        inst_count <= inst_count + 1;
                        jump_inst_count <= jump_inst_count + 1;
                    end
                    default:;
                    endcase
                end
                endcase
            end
            default:;
            endcase
        end
    end
    //***********************************************
endmodule