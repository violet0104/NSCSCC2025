`timescale 1ns / 1ps

module inst_cache
(
    input  wire         clk,
    input  wire         rst,       // low active
    // Interface to CPU
    input  wire         inst_rreq,      // 来自CPU的取指请求
    input  wire [31:0]  inst_addr,      // 来自CPU的取指地址
    input  wire [31:0]  BPU_pred_addr,
    input  wire         BPU_pred_taken1,
    input  wire         BPU_pred_taken2,
    output wire         pred_addr,
    output wire         pred_taken1,
    output wire         pred_taken2,
    output reg          inst_valid,     // 输出给CPU的指令有效信号（读指令命中）
    output reg  [31:0]  inst_out1,       // 输出给CPU的指令
    output reg  [31:0]  inst_out2,
    output reg  [31:0]  pc1,
    output reg  [31:0]  pc2,
    output wire         pc_suspend,  //返回数据有效，暂停FIFO
    // Interface to Read Bus
    input  wire         dev_rrdy,       // 主存就绪信号（高电平表示主存可接收ICache的读请求）
    output reg  [ 3:0]  cpu_ren,        // 输出给主存的读使能信号
    output reg  [31:0]  cpu_raddr,      // 输出给主存的读地址
    input  wire         dev_rvalid,     // 来自主存的数据有效信号
    input  wire [127:0] dev_rdata   // 来自主存的读数据  128
);

    wire [31:0] addr_1_1 = inst_addr;
    wire [31:0] addr_2_1 = inst_addr + 4;
    wire [5:0]  index_1_1 = addr_1_1[9:4];
    wire [5:0]  index_2_1 = addr_2_1[9:4];
    wire [21:5] tag_1_1 = addr_1_1[31:10];
    wire [21:5] tag_2_1 = addr_2_1[31:10];
    wire [1:0] offset1_1 = addr_1_1[3:2];
    wire [1:0] offset2_1 = addr_2_1[3:2];

    reg [31:0] addr_1_2;
    reg [31:0] addr_2_2;
    reg [1:0] offset1_2;
    reg [1:0] offset2_2;
    reg [21:0] tag_1_2;
    reg [21:0] tag_2_2;
    reg req_2;

    reg [31:0] pred_addr_2;
    reg        pred_taken1_2;
    reg        pred_taken2_2;

    wire [150:0]ram1_data_block1;
    wire [150:0]ram1_data_block2;
    wire [150:0]ram2_data_block1;
    wire [150:0]ram2_data_block2;

    wire [21:0]ram1_tag1 = ram1_data_block1[149:128];
    wire [21:0]ram1_tag2 = ram1_data_block2[149:128];
    wire [21:0]ram2_tag1 = ram2_data_block1[149:128];
    wire [21:0]ram2_tag2 = ram2_data_block2[149:128];

    reg [1:0] use_bit [63:0];
    wire [5:0] refill_index = dealing1 ? addr_1_2[9:4] : dealing2 ? addr_2_2[9:4] : 6'b0;
    wire [21:0] refill_tag = dealing1 ? addr_1_2[31:10] : dealing2 ? addr_2_2[31:10] : 22'b0;
    wire we1 = (dev_rvalid==1)&(use_bit[refill_index]==2'b10);
    wire we2 = (dev_rvalid==1)&(use_bit[refill_index]==2'b01);
    wire [150:0] refill_data = {{1'b1,refill_tag},dev_rdata};

    //hit第一个1代表ram1，第二个1代表index1
    wire hit1_1 = (tag_1_2==ram1_tag1) & req_2 & ram1_data_block1[150];  
    wire hit2_1 = (tag_1_2==ram2_tag1) & req_2 & ram2_data_block1[150];
    wire hit1 = hit1_1 | hit2_1;    //index1
    wire hit1_2 = (tag_2_2==ram1_tag2) & req_2 & ram1_data_block2[150];
    wire hit2_2 = (tag_2_2==ram2_tag2) & req_2 & ram2_data_block2[150];
    wire hit2 = hit1_2 | hit2_2;    //index2

    wire [127:0] hit1_data = {128{hit1_1}}&ram1_data_block1[127:0] | {128{hit2_1}}&ram2_data_block1[127:0];
    wire [127:0] hit2_data = {128{hit1_2}}&ram1_data_block2[127:0] | {128{hit2_2}}&ram2_data_block2[127:0];

    wire refill_1_2 = req_2 & !hit1;
    wire refill_2_2 = req_2 & !hit2;

    reg dealing1;
    reg dealing2;

    wire suspend = refill_1_2 | refill_2_2;
    assign pc_suspend = suspend;

    integer i;
    always @(posedge clk)
    begin
        if(rst)
        begin
            addr_1_2 <= 32'b0;
            addr_2_2 <= 32'b0;
            req_2 <= 0;
            offset1_2 <= 2'b0;
            offset2_2 <= 2'b0;
            tag_1_2 <= 22'b0;
            tag_2_2 <= 22'b0; 

            pred_addr_2 <= 32'b0;
            pred_taken1_2 <= 1'b0;
            pred_taken2_2 <= 1'b0;
            for(i=0;i<64;i=i+1)
            begin
                use_bit[i] <= 2'b10;
            end
        end
        else if(!suspend)
        begin
            addr_1_2 <= addr_1_1;
            addr_2_2 <= addr_2_1;
            req_2 <= inst_rreq;
            offset1_2 <= offset1_1;
            offset2_2 <= offset2_1;
            tag_1_2 <= tag_1_1;
            tag_2_2 <= tag_2_1;

            pred_addr_2 <= BPU_pred_addr;
            pred_taken1_2 <= BPU_pred_taken1;
            pred_taken2_2 <= BPU_pred_taken2;
        end
    end

    wire [5:0]index1 = (refill_1_2 | refill_2_2) ? addr_1_2[9:4] : index_1_1;
    wire [5:0]index2 = (refill_1_2 | refill_2_2) ? addr_2_2[9:4] : index_2_1;

    cache_ram ram1
    (
        .clk(clk),
        .we(we1),
        .w_index(refill_index),
        .r_index1(index1),
        .r_index2(index2),
        .rst(rst),
        .data_in(refill_data),
        .data_out1(ram1_data_block1),
        .data_out2(ram1_data_block2)
    );

    cache_ram ram2
    (
        .clk(clk),
        .we(we2),
        .w_index(refill_index),
        .r_index1(index1),
        .r_index2(index2),
        .rst(rst),
        .data_in(refill_data),
        .data_out1(ram2_data_block1),
        .data_out2(ram2_data_block2)
    );

    assign pred_addr = pred_addr_2;
    assign pred_taken1 = pred_taken1_2;
    assign pred_taken2 = pred_taken2_2;

    always @(*)
    begin
        inst_valid = hit1 & hit2;
        pc1 = addr_1_2;
        pc2 = addr_2_2;
        case(offset1_2)
        2'b00:inst_out1 = hit1_data[31:0];
        2'b01:inst_out1 = hit1_data[63:32];
        2'b10:inst_out1 = hit1_data[95:64];
        2'b11:inst_out1 = hit1_data[127:96];  
        default:inst_out1 = 32'b0;  
        endcase
        case(offset2_2)
        2'b00:inst_out2 = hit2_data[31:0];
        2'b01:inst_out2 = hit2_data[63:32];
        2'b10:inst_out2 = hit2_data[95:64];
        2'b11:inst_out2 = hit2_data[127:96];  
        default:inst_out2 = 32'b0;   
        endcase
    end

    reg [5:0] index1_delay;
    reg [5:0] index2_delay;

    always @(posedge clk)
    begin
        index1_delay <= index1;
        index2_delay <= index2;
        if(rst)
        begin
            dealing1 <= 1'b0;
            dealing2 <= 1'b0;
        end
        else
        begin
            if(dev_rrdy & !dealing1 & refill_1_2)
            begin
                cpu_raddr <= {addr_1_2[31:4],4'b0};
                cpu_ren <= 4'b1111;
                dealing1 <= 1'b1;
                if(addr_1_2[9:4]==addr_2_2[9:4]) dealing2 <= 1'b1;
            end
            else if(dev_rrdy & !dealing2 & refill_2_2 & !dealing1)
            begin
                cpu_ren <= {addr_2_2[31:4],4'b0};
                cpu_ren <= 4'b1111;
                dealing2 <= 1'b1;
            end
            else cpu_ren <= 4'b000;
            if(dev_rvalid)
            begin
                if(dealing1)
                begin 
                    use_bit[addr_1_2[9:4]] <= ~use_bit[addr_1_2[9:4]];
                end
                else if(dealing2)
                begin
                    use_bit[addr_2_2[9:4]] <= ~use_bit[addr_2_2[9:4]];
                end
                if(dealing1) dealing1 <= 1'b0;
                if(dealing2) dealing2 <= 1'b0;
            end
            else
            begin
                if(index1 == index2)
                begin
                    if(hit1_1) use_bit[index1_delay] <= 2'b01;
                    else if(hit2_1) use_bit[index1_delay] <= 2'b10;
                    if(hit1_2) use_bit[index2_delay] <= 2'b01;
                    else if(hit2_2) use_bit[index2_delay] <= 2'b10;
                end
            end
        end
    end


endmodule