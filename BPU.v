`timescale 1ns / 1ps

`define BHT_IDX_W 10                    // 表索引位�?
`define BHT_ENTRY (1 << `BHT_IDX_W)     // 表项个数
`define BHT_TAG_W 8                     // tag字段位宽

module BPU 
(
    input  wire         cpu_clk    ,
    input  wire         cpu_rstn   ,
    input  wire [31:0]  if_pc      ,        // IF阶段PC
    // predict branch direction and target
    output wire         pred_taken1,
    output wire         pred_taken2,
    output wire [31:0]  pred_addr,        // 预测目标地址
    output wire         BPU_flush ,        // 是否预测错误,驱动清除流水线上的错误指令
    
    input  wire         ex_is_bj_1   ,
    input  wire         ex_pred_taken1,      
    input  wire [31:0]  ex_pc_1      ,
    input  wire         ex_valid1    ,        
    input  wire         ex_is_bj_2   ,
    input  wire         ex_pred_taken2,     
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
reg  [`BHT_TAG_W-1:0] tag     [`BHT_ENTRY-1:0];
reg  [`BHT_ENTRY-1:0] valid;
reg  [           1:0] history [`BHT_ENTRY-1:0]; //数组用于存储 分支指令的历史记录，通过�? 2 位信息来预测未来分支指令的行为（跳转或不跳转）�?�饱和计数器
reg  [          31:0] addr  [`BHT_ENTRY-1:0];

wire [31:0]if_pc4 = if_pc + 4;

wire [`BHT_TAG_W-1:0] if_tag1 = if_pc[31:24];
wire [`BHT_TAG_W-1:0] if_tag2 = if_pc4[31:24];
wire [`BHT_IDX_W-1:0] index1 = {if_pc[29:24]^if_pc[23:18]^if_pc[17:12]^if_pc[11:6],if_pc[5:2]};
wire [`BHT_IDX_W-1:0] index2 = {if_pc4[29:24]^if_pc4[23:18]^if_pc4[17:12]^if_pc4[11:6],if_pc4[5:2]};

assign pred_taken1 = if_tag1 == tag[index1] & valid[index1] == 1'b1 & history[index1][1] == 1'b1;
assign pred_taken2 = if_tag2 == tag[index2] & valid[index2] == 1'b1 & history[index2][1] == 1'b1;
assign pred_addr = pred_taken1 ? addr[index1] : pred_taken2 ? addr[index2] : if_pc + 8;

wire ex_tag1 = ex_pc_1[31:24];
wire ex_tag2 = ex_pc_2[31:24];
wire ex_index1 = {ex_pc_1[29:24]^ex_pc_1[23:18]^ex_pc_1[17:12]^ex_pc_1[11:6],ex_pc_1[5:2]};
wire ex_index2 = {ex_pc_2[29:24]^ex_pc_2[23:18]^ex_pc_2[17:12]^ex_pc_2[11:6],ex_pc_2[5:2]};

wire add1 = ex_valid1 & !valid[ex_index1] & real_taken1;
wire add2 = ex_valid2 & !valid[ex_index2] & real_taken2;
wire update1 = ex_valid1 & valid[ex_index1] & tag[ex_index1]==ex_tag1 & ex_is_bj_1;
wire update2 = ex_valid2 & valid[ex_index2] & tag[ex_index2]==ex_tag2 & ex_is_bj_2;
wire replace1 = ex_valid1 & valid[ex_index1] & real_taken1 & tag[ex_index1]!=ex_tag1;
wire replace2 = ex_valid2 & valid[ex_index2] & real_taken2 & tag[ex_index2]!=ex_tag2;

wire addr_error1 = ex_valid1 & pred_addr1 != real_addr1;     //预测跳转方向错误而目标地址不错，则认为没错
wire addr_error2 = ex_valid2 & pred_addr2 != real_addr2;

assign BPU_flush = addr_error1 | addr_error2;

integer i;
always @(posedge cpu_clk or negedge cpu_rstn) 
begin
    if (!cpu_rstn) 
    begin
        valid <= {`BHT_ENTRY{1'b0}};
        for (i = 0; i < `BHT_ENTRY; i = i + 1)
        begin
            history[i] <= 2'b10;
            valid[i] <= 1'b0;
        end
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
endmodule