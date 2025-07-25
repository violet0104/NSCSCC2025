`timescale 1ns / 1ps
module icache
(
    input  wire         clk,
    input  wire         rst,       // low active
    input  wire         flush,
    // Interface to CPU
    input  wire         inst_rreq,      // ����CPU��ȡָ����
    input  wire [31:0]  inst_addr,      // ����CPU��ȡָ��ַ
    input  wire [31:0]  BPU_pred_addr,
    input  wire [1:0]   BPU_pred_taken,

    input  wire         pi_is_exception,
    input  wire [6:0]   pi_exception_cause, 

    output wire [31:0]  pred_addr,
    output wire [1:0]   pred_taken,
    output reg          inst_valid,     // �����CPU��ָ����Ч�ź�
    output reg  [31:0]  inst_out1,       // 
    output reg  [31:0]  inst_out2,
    output reg  [31:0]  pc1,
    output reg  [31:0]  pc2,
    output reg          pc_is_exception_out1,
    output reg          pc_is_exception_out2,
    output reg  [6:0]   pc_exception_cause_out1,
    output reg  [6:0]   pc_exception_cause_out2,
    output wire         pc_suspend,  
    // Interface to Read Bus
    input  wire         dev_rrdy,       // ��������źţ��ߵ�ƽ��ʾ����ɽ���ICache�Ķ�����
    output reg          cpu_ren,        // ���������Ķ�ʹ���ź�
    output reg  [31:0]  cpu_raddr,      // ���������Ķ���ַ
    input  wire         dev_rvalid,     // ���������������Ч�ź�
    input  wire [127:0] dev_rdata,   // ��������Ķ�����  128
    input  wire         ren_received,
    input  wire         flush_flag_valid
);

    localparam IDLE = 2'b00;
    localparam DEALING1 = 2'b01;
    localparam DEALING2 = 2'b10;
    localparam REFILL = 2'b11;
    reg [1:0] state;
    reg [1:0] next_state;

    wire [31:0] addr_1_1 = inst_addr;
    wire [31:0] addr_2_1 = inst_addr + 4;
    wire [5:0]  index_1_1 = addr_1_1[9:4];
    wire [5:0]  index_2_1 = addr_2_1[9:4];
    wire [21:0] tag_1_1 = addr_1_1[31:10];
    wire [21:0] tag_2_1 = addr_2_1[31:10];
    wire [1:0] offset1_1 = addr_1_1[3:2];
    wire [1:0] offset2_1 = addr_2_1[3:2];

    reg [31:0] addr_1_2;
    reg [31:0] addr_2_2;
    reg [1:0] offset1_2;
    reg [1:0] offset2_2;
    reg [21:0] tag_1_2;
    reg [21:0] tag_2_2;
    reg req_2;
    reg pi_is_exception_2;
    reg [6:0] pi_exception_cause_2;

    reg [31:0] pred_addr_2;
    reg [1:0]  pred_taken_2;   

    wire [150:0]ram1_data_block1;
    wire [150:0]ram1_data_block2;
    wire [150:0]ram2_data_block1;
    wire [150:0]ram2_data_block2;

    wire [21:0]ram1_tag1 = ram1_data_block1[149:128];
    wire [21:0]ram1_tag2 = ram1_data_block2[149:128];
    wire [21:0]ram2_tag1 = ram2_data_block1[149:128];
    wire [21:0]ram2_tag2 = ram2_data_block2[149:128];

    reg [1:0] use_bit [63:0];

    wire [21:0] refill_tag = state == DEALING1 ? addr_1_2[31:10] :  addr_2_2[31:10];


    wire [5:0]index1 = (next_state != IDLE) ? addr_1_2[9:4] : index_1_1;
    wire [5:0]index2 = (next_state != IDLE) ? addr_2_2[9:4] : index_2_1;
    reg [5:0]index1_delay;
    reg [5:0]index2_delay;

    wire [150:0] refill_data = {{1'b1,refill_tag},dev_rdata};

    //��һ��1����ram1���ڶ���1����index1
    wire hit_ram1_index1 = !flush & (tag_1_2==ram1_tag1) & req_2 & ram1_data_block1[150];  
    wire hit_ram2_index1 = !flush & (tag_1_2==ram2_tag1) & req_2 & ram2_data_block1[150];
    wire hit_index1 = hit_ram1_index1 | hit_ram2_index1;    //index1
    wire hit_ram1_index2 = !flush & (tag_2_2==ram1_tag2) & req_2 & ram1_data_block2[150];
    wire hit_ram2_index2 = !flush & (tag_2_2==ram2_tag2) & req_2 & ram2_data_block2[150];
    wire hit_index2 = hit_ram1_index2 | hit_ram2_index2;    //index2

    wire [127:0] hit1_data = {128{hit_ram1_index1}}&ram1_data_block1[127:0] | {128{hit_ram2_index1}}&ram2_data_block1[127:0];
    wire [127:0] hit2_data = {128{hit_ram1_index2}}&ram1_data_block2[127:0] | {128{hit_ram2_index2}}&ram2_data_block2[127:0];
    
    wire we_ram1_index1 = dev_rvalid & (use_bit[index1]==2'b10) & !flush & req_2 & state == DEALING1 & !flush_flag;
    wire we_ram1_index2 = dev_rvalid & (use_bit[index2]==2'b10) & !flush & req_2 & state == DEALING2 & !flush_flag;
    wire we_ram2_index1 = dev_rvalid & (use_bit[index1]==2'b01) & !flush & req_2 & state == DEALING1 & !flush_flag;
    wire we_ram2_index2 = dev_rvalid & (use_bit[index2]==2'b01) & !flush & req_2 & state == DEALING2 & !flush_flag;

    assign pc_suspend = next_state != IDLE;
    integer i;
    reg flush_flag;

    always @(posedge clk)
    begin
        if(rst | flush) state <= IDLE;
        else state <= next_state;
    end

    always @(*)
    begin
        case(state)
        IDLE:begin
            if(!hit_index1 & req_2) next_state = DEALING1;
            else if(!hit_index2 & req_2) next_state = DEALING2;
            else next_state = IDLE;
        end
        DEALING1:begin
            if(dev_rvalid & (index1 == index2 | hit_index2) & !flush_flag) next_state = REFILL;
            else if(dev_rvalid & !flush_flag) next_state = DEALING2;
            else next_state = DEALING1; 
        end
        DEALING2:begin
            if(dev_rvalid & !flush_flag) next_state = REFILL;
            else next_state = DEALING2;
        end
        REFILL:begin
            next_state = IDLE;
        end
        endcase
    end
        always @(posedge clk)
        begin
            if(rst | flush)
            begin
            addr_1_2 <= 32'b0;
            addr_2_2 <= 32'b0;
            req_2 <= 0;
            offset1_2 <= 2'b0;
            offset2_2 <= 2'b0;
            tag_1_2 <= 22'b0;
            tag_2_2 <= 22'b0; 

            pred_addr_2 <= 32'b0;
            pred_taken_2 <= 2'b0;

            pi_is_exception_2 <= 1'b0;
            pi_exception_cause_2 <= 7'b0;
            cpu_ren <= 1'b0;
            cpu_raddr <= 32'b0;
            if(flush)
            begin
                case(state)
                IDLE:begin
                    if(dev_rvalid) flush_flag <= 1'b0;
                end
                DEALING1:begin
                    if(!dev_rvalid & flush_flag_valid)
                    begin
                        flush_flag <= 1'b1;     //flush������������������������һ��dev_rvalid
                    end
                end
                DEALING2:begin
                    if(!dev_rvalid & flush_flag_valid)
                    begin
                        flush_flag <= 1'b1;
                    end
                end
                default:;
                endcase
            end
            if(rst)
            begin
                flush_flag <= 1'b0;
                for(i=0;i<64;i=i+1)
                begin
                    use_bit[i] <= 2'b10;
                end
            end
            end
            else
            begin
                case(state)
                IDLE,REFILL:begin
                    if(dev_rvalid) flush_flag <= 1'b0;
                    if(next_state == IDLE)
                    begin
                    addr_1_2 <= addr_1_1;
                    addr_2_2 <= addr_2_1;
                    req_2 <= inst_rreq;
                    offset1_2 <= offset1_1;
                    offset2_2 <= offset2_1;
                    tag_1_2 <= tag_1_1;
                    tag_2_2 <= tag_2_1;

                    pred_addr_2 <= BPU_pred_addr;
                    pred_taken_2 <= BPU_pred_taken;

                    pi_is_exception_2 <= pi_is_exception;
                    pi_exception_cause_2 <= pi_exception_cause;
                    end
                    else if(next_state == DEALING1)
                    begin
                        cpu_ren <= 1'b1;
                        cpu_raddr <= {addr_1_2[31:4],4'b0};
                    end
                    else if(next_state == DEALING2)
                    begin
                        cpu_ren <= 1'b1;
                        cpu_raddr <= {addr_2_2[31:4],4'b0};
                    end
                    if(hit_ram1_index1) use_bit[index1_delay] <= 2'b01;
                    else if(hit_ram2_index1) use_bit[index1_delay] <= 2'b10;
                    if(index1_delay != index2_delay)
                    begin
                        if(hit_ram1_index2) use_bit[index2_delay] <= 2'b01;
                        else if(hit_ram2_index2) use_bit[index2_delay] <= 2'b10;
                    end
                end
                DEALING1:begin
                    if(dev_rvalid) flush_flag <= 1'b0;
                    if(ren_received)
                    begin
                        cpu_ren <= 1'b0;
                    end
                    else if(next_state == DEALING2)
                    begin
                        cpu_ren <= 1'b1;
                        cpu_raddr <= {addr_2_2[31:4],4'b0};
                    end
                end
                DEALING2:begin
                    if(dev_rvalid) flush_flag <= 1'b0;
                    if(ren_received)
                    begin
                        cpu_ren <= 1'b0;
                    end
                end
                endcase
            end
        end

    always @(posedge clk)
    begin
        if(rst | flush)
        begin
            index1_delay <= 6'b0;
            index2_delay <= 6'b0;
        end
        else
        begin
            index1_delay <= index1;
            index2_delay <= index2;
        end
    end
/*
    icache_ram ram1
    (
        .clk(clk),
        .we1(we_ram1_index1),
        .we2(we_ram1_index2),
        .rst(rst),
        .index1(index1),
        .index2(index2),
        .data_in(refill_data),
        .data_out1(ram1_data_block1),
        .data_out2(ram1_data_block2)
    );

    icache_ram ram2
    (
        .clk(clk),
        .we1(we_ram2_index1),
        .we2(we_ram2_index2),
        .index1(index1),
        .index2(index2),
        .rst(rst),
        .data_in(refill_data),
        .data_out1(ram2_data_block1),
        .data_out2(ram2_data_block2)
    );
    */
    assign pred_addr = pred_addr_2;
    assign pred_taken = pred_taken_2;

    always @(*)
    begin
        inst_valid = hit_index1 & hit_index2;
        pc1 = addr_1_2;
        pc2 = addr_2_2;

        pc_is_exception_out1 = pi_is_exception_2;
        pc_is_exception_out2 = pi_is_exception_2;
        pc_exception_cause_out1 = pi_exception_cause_2;
        pc_exception_cause_out2 = pi_exception_cause_2;

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

    bram ram1
    (
        .clka(clk),
        .addra(index1),
        .dina(refill_data),
        .douta(ram1_data_block1),
        .ena(1'b1),
        .wea(we_ram1_index1),

        .clkb(clk),
        .addrb(index2),
        .dinb(refill_data),
        .doutb(ram1_data_block2),
        .enb(1'b1),
        .web(we_ram1_index2)
    );

    bram ram2
    (
        .clka(clk),
        .addra(index1),
        .dina(refill_data),
        .douta(ram2_data_block1),
        .ena(1'b1),
        .wea(we_ram2_index1),

        .clkb(clk),
        .addrb(index2),
        .dinb(refill_data),
        .doutb(ram2_data_block2),
        .enb(1'b1),
        .web(we_ram2_index2)
    );

    endmodule