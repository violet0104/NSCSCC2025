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
    output reg rdata_valid,    // �����CPU��������Ч�źţ��ߵ�ƽ��ʾDCache��׼�������ݣ�
    output wire dcache_ready,   
    //to write BUS
    input  wire         dev_wrdy,       // �����/�����д�����źţ��ߵ�ƽ��ʾ����/����ɽ���DCache��д����
    input  wire         write_finish,
    output reg  [ 3:0]  cpu_wen,        // ���������/�����дʹ���ź�
    output reg  [31:0]  cpu_waddr,      // ���������/�����д��ַ
    output reg  [127:0]  cpu_wdata,      // ���������/�����д����
    //to Read Bus
    input  wire         dev_rrdy,       // ����/����Ķ������źţ��ߵ�ƽ��ʾ����/����ɽ���DCache�Ķ�����
    output reg          cpu_ren,        // ���������/����Ķ�ʹ���ź�
    output reg  [31:0]  cpu_raddr,      // ���������/����Ķ���ַ
    input  wire         dev_rvalid,     // ��������/�����������Ч�ź�
    input  wire [127:0] dev_rdata,       // ��������/����Ķ�����
    input  wire         ren_received,

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
    localparam REFILL = 3'b100;   //д�����ݿ飬��һ��clk�ٴ�дwrite_data
    localparam UNCACHE = 3'b101;
    
    reg [2:0] state;
    reg [2:0] next_state;
    reg [1:0] dirty [63:0];
    reg [1:0] use_bit [63:0];  //2'b10�ĵ�һ��
    
    wire [31:0] vaddr_1 = vaddr;      
    wire [5:0] index_1 ;
    //�����2��ʾ���������ʱ��һ��clk
    reg [5:0] index_2;
    reg [31:0] paddr_2;
    reg [31:0] w_data_2;
    reg [3:0] wen_2;
    reg ren_2;
    reg uncache_2;

    wire [127:0] data_block1;  
    wire [127:0] data_block2;  
    wire [22:0] ram_tag1;
    wire [22:0] ram_tag2;
    wire [1:0] offset_2 = paddr_2[3:2];
    wire [21:0] tag_2 = paddr_2[31:10];
    wire is_load = ren_2;
    wire is_store = |wen_2;
    wire req_2 = is_load | is_store;
    wire hit1 = req_2 & (tag_2 == ram_tag1[21:0]) & ram_tag1[22];
    wire hit2 = req_2 & (tag_2 == ram_tag2[21:0]) & ram_tag2[22];
    wire hit = hit1 | hit2;
    wire dirty_index = use_bit[index_2] != 2'b10;
    wire [127:0] hit_data = {128{hit1}}&data_block1 | {128{hit2}}&data_block2;//
  
    wire write_dirty = !hit & req_2 & dirty[index_2][dirty_index];
    wire ask_mem = !hit & req_2 & !dirty[index_2][dirty_index];
    wire read_index_choose = next_state == IDLE;
    
    reg [127:0] attach_write_data;  //����Ҫд��ram��ƴ����ɵ����ݿ�
    reg [15:0] we1_choose;   //��дʹ�����룬һλ����һ���ֽڵ�д��
    reg [15:0] we2_choose;

    always @(*)
    begin
        case(offset_2)
        2'b00:attach_write_data = dev_rvalid ? dev_rdata : {96'b0,w_data_2};
        2'b01:attach_write_data = dev_rvalid ? dev_rdata : {64'b0,w_data_2,32'b0};
        2'b10:attach_write_data = dev_rvalid ? dev_rdata : {32'b0,w_data_2,64'b0};
        2'b11:attach_write_data = dev_rvalid ? dev_rdata : {w_data_2,96'b0};
        default:;
        endcase
    end
    
    assign index_1 = read_index_choose ? vaddr_1[9:4] : index_2;
    wire [127:0] write_ram_data = dev_rvalid ? dev_rdata : attach_write_data;
    wire [22:0] write_ram_tag = {1'b1,tag_2};

    assign dcache_ready = next_state == IDLE & state != UNCACHE;
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
            if(dev_rvalid & ren_2) next_state = RETURN;
            else if(dev_rvalid) next_state = REFILL;
            else next_state = ASKMEM;
        end
        DIRTY_WRITE:begin 
            if(!write_dirty) next_state = ASKMEM;  //�ĳ�dev_wrdy?
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
    reg uncache_dealing;

    always @(posedge clk)
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
            uncache_dealing <= 1'b0;
            uncache_2 <= 1'b0;

            for(i=0;i<64;i=i+1)
            begin
                dirty[i] <= 2'b00;
            end
        end
        else if((next_state == IDLE) & (req_2 & hit | !req_2))  //閿熸枻鎷烽敓鏂ゆ嫹瑕侢�敓鏂ゆ嫹閿熸枻鎷穝tate == `RETURN
        begin
            paddr_2 <= vaddr_1;                         //閿熷壙杈炬嫹閿熸枻鎷烽敓鏂ゆ嫹閿熸枻鎷烽敓琛楢�嚖鎷烽敓鏂ゆ嫹閿熸枻鎷烽敓鏂ゆ嫹閿熻鍑ゆ嫹閿熼樁顏庢嫹閿熸枻鎷烽敓鎻亷鎷烽敓鏂ゆ嫹閿燂拷
            uncache_2 <= vaddr_1[31:16] == 16'hbfaf & (ren | (|wen));     //閿熸枻鎷疯閿熸枻鎷烽敓鏂ゆ嫹閿熸枻鎷烽敓鏂ゆ嫹
            w_data_2 <= write_data;
            wen_2 <= wen;
            ren_2 <= ren;
            index_2 <= index_1;
            uncache_dealing <= 1'b0;
            if(hit & is_store) 
            begin
                if(hit1) dirty[index_2][0] <= 1'b1;
                else dirty[index_2][1] <= 1'b1;
            end
        end
        else if(state == DIRTY_WRITE)   //��κ���ɸ�case
        begin
            if(dev_wrdy & !dealing)
            begin
                cpu_wen <= 4'b1111;
                cpu_waddr <= use_bit[index_2] == 2'b10 ? {ram_tag1,index_2,4'b0} : {ram_tag2,index_2,4'b0};
                dealing <= 1'b1;
                dirty[index_2][dirty_index] <= 1'b0;
                case(use_bit[index_2])
                2'b10:cpu_wdata <= data_block1;
                2'b01:cpu_wdata <= data_block2;
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
            else if(ren_received)
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
            if(uncache_rvalid | uncache_write_finish) uncache_dealing <= 1'b0;
            else uncache_dealing <= 1'b1;
        end
    end
//
    reg [31:0] hit_data_word_choose; //����offset��ѡ��cache���4���������ѡ��һ��
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
//
    always @(posedge clk)
    begin
        if(rst)
        begin
            rdata <= 32'b0;
            rdata_valid <= 1'b0;
            for(i=0;i<64;i=i+1)
            begin
                use_bit[i] <= 2'b10;
            end
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
            if(hit1) use_bit[index_2] <= 2'b01;
            else use_bit[index_2] <= 2'b10;
        end
        else 
        begin
            rdata_valid <= 1'b0;
        end
    end

    wire we1 = (dev_rvalid & (use_bit[index_2]==2'b10)) | (hit1 & is_store & state != RETURN);
    wire we2 = (dev_rvalid & (use_bit[index_2]==2'b01)) | (hit2 & is_store & state != RETURN);

    always @(*)
    begin
        case(offset_2)
        2'b00:begin
            we1_choose = {16{dev_rvalid & (use_bit[index_2]==2'b10)}} | ({16{(hit1 & is_store)}} & {12'b0,wen_2}) & {16{state != RETURN}};
            we2_choose = {16{dev_rvalid & (use_bit[index_2]==2'b01)}} | ({16{(hit2 & is_store)}} & {12'b0,wen_2}) & {16{state != RETURN}};
        end
        2'b01:begin
            we1_choose = {16{dev_rvalid & (use_bit[index_2]==2'b10)}} | ({16{(hit1 & is_store)}} & {8'b0,wen_2,4'b0}) & {16{state != RETURN}};
            we2_choose = {16{dev_rvalid & (use_bit[index_2]==2'b01)}} | ({16{(hit2 & is_store)}} & {8'b0,wen_2,4'b0}) & {16{state != RETURN}};
        end
        2'b10:begin
            we1_choose = {16{dev_rvalid & (use_bit[index_2]==2'b10)}} | ({16{(hit1 & is_store)}} & {4'b0,wen_2,8'b0}) & {16{state != RETURN}};
            we2_choose = {16{dev_rvalid & (use_bit[index_2]==2'b01)}} | ({16{(hit2 & is_store)}} & {4'b0,wen_2,8'b0}) & {16{state != RETURN}};
        end
        2'b11:begin
            we1_choose = {16{dev_rvalid & (use_bit[index_2]==2'b10)}} | ({16{(hit1 & is_store)}} & {wen_2,12'b0}) & {16{state != RETURN}};
            we2_choose = {16{dev_rvalid & (use_bit[index_2]==2'b01)}} | ({16{(hit2 & is_store)}} & {wen_2,12'b0}) & {16{state != RETURN}};
        end
        default:begin
            we1_choose = 16'b0;
            we2_choose = 16'b0;
        end
        endcase
    end
    /*
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
    */

    dcache_dram data_ram1  //128
    (
        .clka(clk),
        .addra(index_2),
        .dina(write_ram_data),
        .wea(we1_choose),

        .clkb(clk),
        .addrb(index_1),
        .doutb(data_block1)
    );

    dcache_dram data_ram2
    (
        .clka(clk),
        .addra(index_2),
        .dina(write_ram_data),
        .wea(we2_choose),

        .clkb(clk),
        .addrb(index_1),
        .doutb(data_block2)
    );
    dcache_bram tag_bram1
    (
        .clka(clk),
        .addra(index_2),
        .dina(write_ram_tag),
        .wea(we1),

        .clkb(clk),
        .addrb(index_1),
        .doutb(ram_tag1)
    );
    dcache_bram tag_bram2
    (
        .clka(clk),
        .addra(index_2),
        .dina(write_ram_tag),
        .wea(we2),

        .clkb(clk),
        .addrb(index_1),
        .doutb(ram_tag2)
    );

    assign uncache_ren = (state == UNCACHE) & dev_rrdy & ren_2 & !uncache_rvalid;
    assign uncache_raddr = paddr_2;

    assign uncache_wen = (state == UNCACHE) & dev_wrdy & !uncache_dealing ? wen_2 : 4'b0;
    assign uncache_waddr = paddr_2;
    assign uncache_wdata = w_data_2;
endmodule