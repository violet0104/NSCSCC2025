module dcache
(
    input wire clk,
    input wire rst,
    //to CPU
    input wire ren,
    input wire [3:0] wen,
    input wire [31:0] vaddr,
    input wire [31:0] write_data,
    output reg [31:0] rdata,
    output reg rdata_valid,    // 输出给CPU的数据有效信号（高电平表示DCache已准备好数据）
    output reg write_finish,   // 输出给CPU的写响应（高电平表示DCache已完成写操作）
    //to write BUS
    input  wire         dev_wrdy,       // 闁主存/外设的写就绪信号（高电平表示主存/外设可接收DCache的写请求）
    output reg  [ 3:0]  cpu_wen,        // 输出给主存/外设的写使能信号
    output reg  [31:0]  cpu_waddr,      // 输出给主存/外设的写地址
    output reg  [127:0]  cpu_wdata,      // 输出给主存/外设的写数据
    //to Read Bus
    input  wire         dev_rrdy,       // 主存/外设的读就绪信号（高电平表示主存/外设可接收DCache的读请求）
    output reg          cpu_ren,        // 输出给主存/外设的读使能信号
    output reg  [31:0]  cpu_raddr,      // 输出给主存/外设的读地址
    input  wire         dev_rvalid,     // 来自主存/外设的数据有效信号
    input  wire [127:0] dev_rdata,       // 来自主存/外设的读数据

    input wire uncache_rvalid,
    input wire [31:0] uncache_rdata,
    output wire uncache_ren,
    output wire [31:0] uncache_raddr,

    input wire uncache_write_finish,
    output wire [3:0] uncache_wen,   
    output wire [31:0] uncache_wdata,
    output wire [31:0] uncache_waddr
);


    localparam IDLE = 3'b000;
    localparam ASKMEM = 3'b001;
    localparam DIRTY_WRITE = 3'b010;
    localparam RETURN = 3'b011;
    localparam REFILL = 3'b100;
    localparam UNCACHE = 3'b101;
    
    reg [2:0] state;
    reg [2:0] next_state;
    reg [1:0] dirty [63:0];
    reg [1:0] use_bit [63:0];  //2'b10改第一个
    
    wire [31:0] vaddr_1 = vaddr;      
    wire [5:0] index_1 ;
    //这里的2表示相比输入延时了一个clk
    reg [5:0] index_2;
    reg [31:0] paddr_2;
    reg [31:0] w_data_2;
    reg [3:0] wen_2;
    reg ren_2;
    reg uncache_2;

    wire [150:0] data_block1;
    wire [150:0] data_block2;
    wire [21:0] ram_tag1 = data_block1[149:128];
    wire [21:0] ram_tag2 = data_block2[149:128];
    wire [1:0] offset_2 = paddr_2[3:2];
    wire [21:0] tag_2 = paddr_2[31:10];
    wire is_load = ren_2;
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
    wire [31:0] wen_2_choose = {{8{wen_2[3]}},{8{wen_2[2]}},{8{wen_2[1]}},{8{wen_2[0]}}}; //根据wen来将需要写入ram的部分（wen对应位为1）与该字中不需要写入且来自block的（wen对应位为0）进行拼接
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
    assign index_1 = read_index_choose ? vaddr_1[9:4] : index_2;
    wire write_ram_choose = dev_rvalid;
    wire [150:0] write_ram_data = write_ram_choose ? {1'b1,tag_2,dev_rdata} : {1'b1,tag_2,attach_write_data};


    integer i;

    always @(posedge clk) 
    begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    always @(*)
    begin
        case(state)
        IDLE:begin
            if(uncache_2) next_state = UNCACHE;
            else if(write_dirty) next_state = DIRTY_WRITE;
            else if(ask_mem) next_state = ASKMEM;
            else next_state = IDLE;
        end
        ASKMEM:begin
            if(dev_rvalid) next_state = REFILL;
            else next_state = ASKMEM;
        end
        DIRTY_WRITE:begin 
            if(!write_dirty) next_state = ASKMEM;  //改成dev_wrdy?
            else next_state = DIRTY_WRITE;
        end
        RETURN:begin
            next_state = IDLE;
        end
        REFILL:begin
            next_state = RETURN;
        end
        UNCACHE:begin
            if(uncache_rvalid) next_state = IDLE;
            else if(uncache_write_finish) next_state = IDLE;
            else next_state = UNCACHE;
        end
        default:next_state = IDLE;
        endcase
    end

    reg dealing;

    always @(posedge clk or negedge rst)
    begin
        if(rst)
        begin
            paddr_2 <= 32'b0;
            w_data_2 <= 32'b0;
            wen_2 <= 4'b0;
            ren_2 <= 1'b0;
            index_2 <= 6'b0;
            cpu_wen <= 4'b0;
            cpu_ren <= 1'b0;
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
        else if((state == IDLE | state == RETURN) & (req_2 & hit | !req_2) & (next_state != UNCACHE))  //闁跨喐鏋婚幏鐑芥晸閺傘倖瀚圭憰渚€鏁撻弬銈嗗闁跨喐鏋婚幏绌漷ate == `RETURN
        begin
            paddr_2 <= vaddr_1;                         //闁跨喎澹欐潏鐐闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔告灮閹风兘鏁撶悰妤€鍤栭幏鐑芥晸閺傘倖瀚归柨鐔告灮閹风兘鏁撻弬銈嗗闁跨喕顢滈崙銈嗗闁跨喖妯侀搴㈠闁跨喐鏋婚幏鐑芥晸閹活収浜烽幏鐑芥晸閺傘倖瀚归柨鐕傛嫹
            uncache_2 <= vaddr_1[31:16] == 16'hbfaf & (ren | (|wen));     //闁跨喐鏋婚幏鐤洣闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔告灮閹风兘鏁撻弬銈嗗
            w_data_2 <= write_data;
            wen_2 <= wen;
            ren_2 <= ren;
            index_2 <= index_1;
            if(hit & is_store) 
            begin
                if(hit1) dirty[index_2][0] <= 1'b1;
                else dirty[index_2][1] <= 1'b1;
            end
        end
        else if(state == DIRTY_WRITE)   //这段后面可改case
        begin
            if(dev_wrdy & !dealing)
            begin
                cpu_wen <= 4'b1111;
                cpu_waddr <= paddr_2;
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
                cpu_ren <= 1'b1;
                cpu_raddr <= paddr_2;
                dealing <= 1'b1;
            end
            else if(cpu_ren != 1'b0)
            begin
                cpu_ren <= 1'b0;
            end
            if(dev_rvalid)
            begin
                dealing <= 1'b0;
            end
        end
        else if(state == UNCACHE)
        begin
            if(uncache_rvalid)
            begin
                uncache_2 <= 1'b0;
                ren_2 <= 1'b0;
            end
            if(uncache_write_finish)
            begin
                uncache_2 <= 1'b0;
                wen_2 <= 4'b0;
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

    always @(posedge clk)
    begin
        if(rst)
        begin
            rdata <= 32'b0;
            rdata_valid <= 1'b0;
            write_finish <= 1'b0;
        end
        else if(state == UNCACHE & uncache_rvalid)
        begin
            rdata_valid <= 1'b1;
            rdata <= uncache_rdata;
        end
        else if(hit)
        begin
            if(is_load)
            begin
                rdata_valid <= 1'b1;
                rdata <= hit_data_word_choose;
            end
            if(is_store) 
            begin
                write_finish <= 1'b1;
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
    dcache_ram ram1
    (
        .clk(clk),
        .we(we1),
        .w_index(index_2),
        .r_index(index_1),
        .rst(rst),
        .data_in(write_ram_data),
        .data_out(data_block1)
    );

    dcache_ram ram2
    (
        .clk(clk),
        .we(we2),
        .w_index(index_2),
        .r_index(index_1),
        .rst(rst),
        .data_in(write_ram_data),
        .data_out(data_block2)
    );

    assign uncache_ren = (state == UNCACHE) & dev_rrdy & ren_2;
    assign uncache_raddr = paddr_2;

    assign uncache_wen = (state == UNCACHE) & dev_wrdy ? wen_2 : 4'b0;
    assign uncache_waddr = paddr_2;
    assign uncache_wdata = w_data_2;
endmodule