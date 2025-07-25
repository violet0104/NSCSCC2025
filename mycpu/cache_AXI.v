module cache_AXI
(
    input  wire         clk,
    input  wire         rst,    // low active

    //icache read
    input wire inst_ren_i,
    input wire [31:0] inst_araddr_i,
    output reg inst_rvalid_o,
    output reg [127:0] inst_rdata_o,
    output wire icache_ren_received,
    output wire icache_flush_flag_valid,

    //dcache read
    input wire data_ren_i,
    input wire [31:0] data_araddr_i,
    output reg data_rvalid_o,
    output reg [127:0] data_rdata_o,
    output wire dcache_ren_received,

    //dcache write
    input wire [3:0] data_wen_i,
    input wire [127:0] data_wdata_i,
    input wire [31:0] data_awaddr_i,
    output reg data_bvalid_o,

    //ready to dcache
    output wire dev_rrdy_o,
    output wire dev_wrdy_o,

    //duncache read channel
    input wire duncache_ren_i,
    input wire [31:0] duncache_raddr_i,
    output reg duncache_rvalid_o,
    output reg [31:0] duncache_rdata_o,

    //duncache write channel
    input wire [3:0] duncache_wen_i,
    input wire [31:0] duncache_wdata_i,
    input wire [31:0] duncache_waddr_i,
    output reg duncache_write_resp,  //dcache中的duncache_write_finish

    //AXI communicate
    output wire axi_ce_o,
    output wire [3:0] axi_wsel_o,   // 连接总线的wstrb

    //AXI read
    input wire [31:0] rdata_i,
    input wire rdata_valid_i,
    output wire axi_ren_o,
    output wire axi_rready_o,
    output wire [31:0] axi_raddr_o,
    output wire [7:0] axi_rlen_o,

    //AXI write
    input wire wdata_resp_i,  // 写响应信号
    output wire axi_wen_o,
    output wire [31:0] axi_waddr_o,
    output reg [31:0] axi_wdata_o,
    output wire axi_wvalid_o,
    output wire axi_wlast_o,
    output wire [7:0] axi_wlen_o
);  

    localparam  read_FREE = 2'b00;
    localparam  read_ICACHE = 2'b01;
    localparam  read_DCACHE = 2'b10;
    localparam  read_UNCACHE = 2'b11;

    localparam  write_FREE = 2'b00;
    localparam  write_BUSY = 2'b01;
    localparam  write_UNCACHE = 2'b10;

    reg [1:0] read_state;
    reg [1:0] next_read_state;
    reg [1:0] write_state;
    reg [1:0] next_write_state;
    reg [1:0] read_count;
    reg [1:0] write_count;

    assign axi_ce_o = rst ? 1'b0 : 1'b1;
    assign dev_rrdy_o = read_state == read_FREE;
    assign dev_wrdy_o = write_state == write_FREE;
    assign icache_ren_received = read_state == read_FREE & next_read_state == read_ICACHE;
    assign dcache_ren_received = read_state == read_FREE & next_read_state == read_DCACHE;
    assign icache_flush_flag_valid = read_state == read_ICACHE | next_read_state == read_ICACHE;

    always @(posedge clk)
    begin
        if(rst)
        begin
            read_state <= read_FREE;
            write_state <= write_FREE;
        end
        else
        begin
            read_state <= next_read_state;
            write_state <= next_write_state;
        end
    end

    //read state machine
    always @(*)
    begin
        case(read_state)
        read_FREE:begin
            if(duncache_ren_i) next_read_state = read_UNCACHE;
            else if(data_ren_i) next_read_state = read_DCACHE;
            else if(inst_ren_i) next_read_state = read_ICACHE;
            else next_read_state = read_FREE;
        end
        read_ICACHE:begin
            if(rdata_valid_i & read_count == 2'b11) next_read_state = read_FREE;
            else next_read_state = read_ICACHE;
        end
        read_DCACHE:begin
            if(rdata_valid_i & read_count == 2'b11) next_read_state = read_FREE;
            else next_read_state = read_DCACHE;
        end
        read_UNCACHE:begin
            if(rdata_valid_i) next_read_state = read_FREE;
            else next_read_state = read_UNCACHE;
        end
        endcase

    end 
    //write state machine
    always @(*)
    begin
        case(write_state)
        write_FREE:begin
            if(|duncache_wen_i) next_write_state = write_UNCACHE;
            else if(|data_wen_i) next_write_state = write_BUSY;
            else next_write_state = write_FREE;
        end
        write_BUSY:begin
            if(wdata_resp_i & write_count == 2'b11) next_write_state = write_FREE;
            else next_write_state = write_BUSY;
        end
        write_UNCACHE:begin
            if(wdata_resp_i) next_write_state = write_FREE;
            else next_write_state = write_UNCACHE;
        end
        endcase
    end

    //read and write counter
    always @(posedge clk)
    begin
        if(rst)
        begin
            read_count <= 2'b0;
            write_count <= 2'b0;
        end
        else
        begin
            if(read_state == read_FREE)
                read_count <=2'b0;
            else if(rdata_valid_i)
                read_count <= read_count +1;
            if(write_state == write_FREE)
                write_count <= 2'b0;
            else if(wdata_resp_i)
                write_count <= write_count + 1;
        end
    end

    assign axi_ren_o = read_state != read_FREE;
    assign axi_rready_o = axi_ren_o;
    assign axi_raddr_o = (read_state == read_UNCACHE) ? duncache_raddr_i :
                         (read_state == read_DCACHE) ? {data_araddr_i[31:4],4'b0} :
                         (read_state == read_ICACHE) ? {inst_araddr_i[31:4],4'b0} : 32'b0;

    always @(posedge clk)
    begin
        if(rst)
        begin
            inst_rvalid_o <= 1'b0;
            data_rvalid_o <= 1'b0;
        end
        else
        begin
            if(read_state == read_ICACHE & read_count == 2'b11 & rdata_valid_i)
                inst_rvalid_o <= 1'b1;
            else 
                inst_rvalid_o <= 1'b0;
            if(read_state == read_DCACHE &read_count == 2'b11 & rdata_valid_i)
                data_rvalid_o <= 1'b1;
            else
                data_rvalid_o <= 1'b0;
            if(read_state == read_UNCACHE & rdata_valid_i)
                duncache_rvalid_o <= 1'b1;
            else 
                duncache_rvalid_o <= 1'b0;
        end
    end
    //connected to the data block of icache or dcache
    always @(posedge clk)
    begin
        if(rst)
        begin
            inst_rdata_o <= 128'b0;
        end
        else if(rdata_valid_i)
        begin
            case(read_count)
            2'b00:inst_rdata_o[31:0] <= rdata_i;
            2'b01:inst_rdata_o[63:32] <= rdata_i;
            2'b10:inst_rdata_o[95:64] <= rdata_i;
            2'b11:inst_rdata_o[127:96] <= rdata_i;
            endcase
        end
    end

    always @(posedge clk)
    begin
        if(rst)
        begin
            data_rdata_o <= 128'b0;
        end
        else if(rdata_valid_i)
        begin
            case(read_count)
            2'b00:data_rdata_o[31:0] <= rdata_i;
            2'b01:data_rdata_o[63:32] <= rdata_i;
            2'b10:data_rdata_o[95:64] <= rdata_i;
            2'b11:data_rdata_o[127:96] <= rdata_i;
            endcase
        end
    end
    //duncache 
    always @(posedge clk)
    begin
        if(rst)
            duncache_rdata_o <= 32'b0;
        else
        begin
            if(rdata_valid_i & read_state == read_UNCACHE)
                duncache_rdata_o <= rdata_i;
        end
    end

    //AXI
    assign axi_wen_o = write_state != write_FREE; //一直维持直到从设备接受完成
    assign axi_wvalid_o = write_state != write_FREE; //这个信号和上面的信号重合了，连接到后面的axi_interface,但axi_interface中也没有用到这个信号，意义不明
    assign axi_wlen_o = (write_state == write_UNCACHE) ? 8'h0 : 8'h3;
    assign axi_rlen_o = (read_state == read_UNCACHE ) ? 8'h0 : 8'h3;
    assign axi_wsel_o = (write_state == write_UNCACHE) ? duncache_wen_i : 4'b1111;
    assign axi_waddr_o = write_state == write_UNCACHE ? duncache_waddr_i : {data_awaddr_i[31:4],4'b0};
    assign axi_wlast_o = ((write_state == write_BUSY) & write_count == 2'b11) | write_state == write_UNCACHE;

    always @(posedge clk)
    begin
        if(rst)
        begin
            data_bvalid_o <= 1'b0;
            duncache_write_resp <= 1'b0;
        end
        else 
        begin
            data_bvalid_o <= wdata_resp_i & ((write_state == write_BUSY) & write_count == 2'b11 ) | (write_state == write_UNCACHE & wdata_resp_i);
            duncache_write_resp <= (write_state == write_UNCACHE) & wdata_resp_i;
        end
    end

    always @(*)
    begin
        if(write_state == write_UNCACHE)
        begin
            axi_wdata_o = duncache_wdata_i;
        end
        else
        begin
            case(write_count)
            2'b00:axi_wdata_o = data_wdata_i[31:0];
            2'b01:axi_wdata_o = data_wdata_i[63:32];
            2'b10:axi_wdata_o = data_wdata_i[95:64];
            2'b11:axi_wdata_o = data_wdata_i[127:96];
            default:axi_wdata_o = 32'b0;
        endcase
        end
    end
endmodule