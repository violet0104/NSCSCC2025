module dcache
(
    input wire clk,
    input wire rst,
    //to CPU
    input wire [3:0] ren,
    input wire [3:0] wen,
    input wire [31:0] addr,
    input wire [31:0] write_data,
    output reg [31:0] rdata,
    output reg rdata_valid,
    output reg write_finish,   // 输出给CPU的写响应（高电平表示DCache已完成写操作）
    //to write BUS
    input  wire         dev_wrdy,       // 主存/外设的写就绪信号（高电平表示主存/外设可接收DCache的写请求）
    output reg  [ 3:0]  cpu_wen,        // 输出给主存/外设的写使能信号
    output reg  [31:0]  cpu_waddr,      // 输出给主存/外设的写地址
    output reg  [127:0]  cpu_wdata,      // 输出给主存/外设的写数据
    //to Read Bus
    input  wire         dev_rrdy,       // 主存/外设的读就绪信号（高电平表示主存/外设可接收DCache的读请求）
    output reg  [ 3:0]  cpu_ren,        // 输出给主存/外设的读使能信号
    output reg  [31:0]  cpu_raddr,      // 输出给主存/外设的读地址
    input  wire         dev_rvalid,     // 来自主存/外设的数据有效信号
    input  wire [127:0] dev_rdata       // 来自主存/外设的读数据
);

    localparam IDLE = 3'b000;
    localparam ASKMEM = 3'b001;
    localparam DIRTY_WRITE = 3'b010;
    localparam RETURN = 3'b011;
    localparam REFILL = 3'b100;
    
    reg [2:0] state;
    reg [2:0] next_state;
    reg [1:0] dirty [63:0];
    reg [1:0] use_bit [63:0];  //2'b10改第一个
    
    wire [31:0] addr_1 = {addr[31:2],2'b0};
    wire [5:0] index_1 ;
    //这里的2表示相比输入延时了一个clk
    reg [5:0] index_2;
    reg [31:0] addr_2;
    reg [31:0] w_data_2;
    reg [3:0] wen_2;
    reg [3:0] ren_2;

    wire [150:0] data_block1;
    wire [150:0] data_block2;
    wire [21:0] ram_tag1 = data_block1[149:128];
    wire [21:0] ram_tag2 = data_block2[149:128];
    wire [1:0] offset_2 = addr_2[3:2];
    wire [21:0] tag_2 = addr_2[31:10];
    wire is_load = |ren_2;
    wire is_store = |wen_2;
    wire req_2 = is_load | is_store;
    wire hit1 = req_2 & (tag_2 == ram_tag1) & data_block1[150];
    wire hit2 = req_2 & (tag_2 == ram_tag2) & data_block2[150];
    wire hit = hit1 | hit2;
    wire dirty_index = use_bit[index_2] != 2'b10;
    wire [127:0] hit_data = {128{hit1}}&data_block1[127:0] | {128{hit2}}&data_block2[127:0];

    wire write_dirty = !hit & req_2 & dirty[index_2][dirty_index];
    wire ask_mem = !hit & req_2 & !dirty[index_2][dirty_index];
    wire read_index_choose = (state==IDLE&hit)|(state==RETURN);
    wire [127:0] attach_block_choose = hit1 ? data_block1[127:0] : data_block2[127:0];
    reg [127:0] attach_write_data;  //最终要写回ram的拼接完成的数据块
    reg [31:0] block_word_choose;   //根据输入地址的offset来选则data block中的哪一个字
    wire [31:0] wen_2_choose = {{8{wen_2[3]}},{8{wen_2[2]}},{8{wen_2[1]}},{8{wen_2[0]}}};; //根据wen来将需要写入ram的部分（wen对应位为1）与该字中不需要写入且来自block的（wen对应位为0）进行拼接
    wire [31:0] wen_attach_data = (wen_2_choose&w_data_2)|((~wen_2_choose)&block_word_choose);
    always @(*)
    begin
        case(offset_2)
        2'b00:block_word_choose = attach_block_choose[31:0];
        2'b01:block_word_choose = attach_block_choose[63:32];
        2'b10:block_word_choose = attach_block_choose[95:64];
        2'b11:block_word_choose = attach_block_choose[127:96];
        default:block_word_choose = 32'b0;
        endcase
        case(offset_2)
        2'b00:attach_write_data = {attach_block_choose[127:32],wen_attach_data};
        2'b01:attach_write_data = {attach_block_choose[127:64],wen_attach_data,attach_block_choose[31:0]};
        2'b10:attach_write_data = {attach_block_choose[127:96],wen_attach_data,attach_block_choose[63:0]};
        2'b11:attach_write_data = {wen_attach_data,attach_block_choose[95:0]};
        default:attach_write_data = 128'b0;
        endcase
    end
    assign index_1 = read_index_choose ? addr_1[9:4] : index_2;
    wire write_ram_choose = dev_rvalid;
    wire [150:0] write_ram_data = write_ram_choose ? {1'b1,tag_2,dev_rdata} : {1'b1,tag_2,attach_write_data};


    integer i;

    always @(posedge clk or negedge rst) 
    begin
        if (!rst) state <= IDLE;
        else state <= next_state;
    end

    always @(*)
    begin
        case(state)
        IDLE:begin
            if(write_dirty) next_state <= DIRTY_WRITE;
            else if(ask_mem) next_state <= ASKMEM;
            else next_state <= IDLE;
        end
        ASKMEM:begin
            if(dev_rvalid) next_state <= REFILL;
            else next_state <= ASKMEM;
        end
        DIRTY_WRITE:begin 
            if(!write_dirty) next_state <= ASKMEM;  //改成dev_wrdy?
            else next_state <= DIRTY_WRITE;
        end
        RETURN:begin
            next_state <= IDLE;
        end
        REFILL:begin
            next_state <= RETURN;
        end
        default:next_state <= IDLE;
        endcase
    end

    reg dealing;

    always @(posedge clk or negedge rst)
    begin
        if(!rst)
        begin
            addr_2 <= 32'b0;
            w_data_2 <= 32'b0;
            wen_2 <= 4'b0;
            ren_2 <= 4'b0;
            index_2 <= 6'b0;
            cpu_wen <= 4'b0;
            cpu_ren <= 4'b0;
            cpu_waddr <= 32'b0;
            cpu_raddr <= 32'b0;
            cpu_wdata <= 128'b0;
            dealing <= 1'b0;
            for(i=0;i<64;i=i+1)
            begin
                dirty[i] <= 2'b00;
                use_bit[i] <= 2'b10;
            end
        end
        else if((state == IDLE | state == RETURN) & (req_2 & hit | !req_2))  //可能要补充state == `RETURN
        begin
            addr_2 <= addr_1;
            w_data_2 <= write_data;
            wen_2 <= wen;
            ren_2 <= ren;
            index_2 <= index_1;
        end
        else if(state == DIRTY_WRITE)
        begin
            if(dev_wrdy & !dealing)
            begin
                cpu_wen <= 4'b1111;
                cpu_waddr <= addr_2;
                dealing <= 1'b1;
                dirty[index_2][dirty_index] <= 1'b0;
                case(use_bit[index_2])
                2'b10:cpu_wdata <= data_block1[127:0];
                2'b01:cpu_wdata <= data_block2[127:0];
                default:cpu_wdata <= 128'b0;
                endcase
            end
            else if(cpu_wen != 4'b0000) 
            begin
                cpu_wen <= 4'b0000;
                dealing <= 1'b0;
            end
        end
        else if(state == ASKMEM)
        begin
            if(dev_rrdy & !dealing)
            begin
                cpu_ren <= 4'b1111;
                cpu_raddr <= addr_2;
                dealing <= 1'b1;
            end
            else if(cpu_ren != 4'b0000)
            begin
                cpu_ren <= 4'b0000;
            end
            if(dev_rvalid)
            begin
                use_bit[index_2] <= ~use_bit[index_2];
                dealing <= 1'b0;
            end
        end
    end

    reg [31:0] hit_data_word_choose; //根据offset来选出cache块的4个字里具体选哪一个
    always @(*)
    begin
        case(offset_2)
        2'b00:hit_data_word_choose = hit_data[31:0];
        2'b01:hit_data_word_choose = hit_data[63:32];
        2'b10:hit_data_word_choose = hit_data[95:64];
        2'b11:hit_data_word_choose = hit_data[127:96];
        default:hit_data_word_choose = 32'b0;
        endcase
    end

    always @(posedge clk or negedge rst)
    begin
        if(!rst)
        begin
            rdata <= 32'b0;
            rdata_valid <= 1'b0;
            write_finish <= 1'b0;
        end
        else if(hit)
        begin
            if(is_load)
            begin
                rdata_valid <= 1'b1;
                case(ren_2)
                4'b1111:rdata <= hit_data_word_choose;
                4'b0011:rdata <= {16'b0,hit_data_word_choose[15:0]};
                4'b1100:rdata <= {16'b0,hit_data_word_choose[31:16]};
                4'b0001:rdata <= {24'b0,hit_data_word_choose[7:0]};
                4'b0010:rdata <= {16'b0,hit_data_word_choose[15:8],8'b0};
                4'b0100:rdata <= {8'b0,hit_data_word_choose[23:16],16'b0};
                4'b1000:rdata <= {hit_data_word_choose[31:24],24'b0};
                default:rdata <= 32'b0;
                endcase
            end
            if(is_store) 
            begin
                write_finish <= 1'b1;
                if(hit1) dirty[index_2][0] <= 1'b1;
                else dirty[index_2][1] <= 1'b1;
            end
            if(hit1) use_bit[index_2] <= 2'b01;
            else use_bit[index_2] <= 2'b10;
        end
        else 
        begin
            rdata_valid <= 1'b0;
            write_finish <= 1'b0;
        end
    end

    wire we1 = (dev_rvalid & (use_bit[index_2]==2'b10)) | (hit1 & is_store);
    wire we2 = (dev_rvalid & (use_bit[index_2]==2'b01)) | (hit2 & is_store);
    cache_ram ram1
    (
        .clk(clk),
        .we(we1),
        .w_index(index_2),
        .r_index(index_1),
        .rst(rst),
        .data_in(write_ram_data),
        .data_out(data_block1)
    );

    cache_ram ram2
    (
        .clk(clk),
        .we(we2),
        .w_index(index_2),
        .r_index(index_1),
        .rst(rst),
        .data_in(write_ram_data),
        .data_out(data_block2)
    );

endmodule