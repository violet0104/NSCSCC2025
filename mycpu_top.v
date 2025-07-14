`timescale 1ns / 1ps

module mycpu_top(
    input  wire        aclk,
    input  wire        aresetn,
    input  wire [ 7:0] ext_int, 
    //AXI interface 
    //read reqest
    output wire [ 3:0] arid,
    output wire [31:0] araddr,
    output wire [ 7:0] arlen,
    output wire [ 2:0] arsize,
    output wire [ 1:0] arburst,
    output wire [ 1:0] arlock,
    output wire [ 3:0] arcache,
    output wire [ 2:0] arprot,
    output wire        arvalid,
    input  wire        arready,
    //read back
    input  wire [ 3:0] rid,
    input  wire [31:0] rdata,
    input  wire [ 1:0] rresp,
    input  wire        rlast,
    input  wire        rvalid,
    output wire        rready,
    //write request
    output wire [ 3:0] awid,
    output wire [31:0] awaddr,
    output wire [ 7:0] awlen,
    output wire [ 2:0] awsize,
    output wire [ 1:0] awburst,
    output wire [ 1:0] awlock,
    output wire [ 3:0] awcache,
    output wire [ 2:0] awprot,
    output wire        awvalid,
    input  wire        awready,
    //write data
    output wire [ 3:0] wid,
    output wire [31:0] wdata,
    output wire [ 3:0] wstrb,
    output wire        wlast,
    output wire        wvalid,
    input  wire        wready,
    //write back
    input  wire [ 3:0] bid,
    input  wire [ 1:0] bresp,
    input  wire        bvalid,
    output wire        bready

/*****************************************
    output wire [31:0] debug_wb_pc,    
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,
    output wire [31:0] debug_wb_inst,

    `ifdef DIFF
    output [31:0] debug0_wb_pc,
    output [ 3:0] debug0_wb_rf_wen,
    output [ 4:0] debug0_wb_rf_wnum,
    output [31:0] debug0_wb_rf_wdata,
    output [31:0] debug0_wb_inst,
    
    output [31:0] debug1_wb_pc,
    output [ 3:0] debug1_wb_rf_wen,
    output [ 4:0] debug1_wb_rf_wnum,
    output [31:0] debug1_wb_rf_wdata,
    output [31:0] debug1_wb_inst
    `endif
*******************************************/
);
    wire rst;
    assign rst = ~aresetn;

    wire icache_ren;
    wire [31:0] icache_araddr;
    wire icache_rvalid;
    wire [127:0] icache_rdata;
    wire dcache_ren;
    wire [31:0] dcache_araddr;
    wire dcache_rvalid;
    wire dcache_rdata;
    wire dcache_wen;
    wire [127:0] dcache_wdata;
    wire [31:0] dcache_awaddr;
    wire dcache_bvalid;

    //AXI communicate
    wire axi_ce_o;
    wire [3:0] axi_wsel;   
    //AXI read
    wire [31:0] axi_rdata;
    wire axi_rdata_valid;
    wire axi_ren;
    wire axi_rready;
    wire [31:0] axi_raddr;
    wire [7:0] axi_rlen;
    //AXI write
    wire axi_wdata_resp;
    wire axi_wen;
    wire [31:0] axi_waddr;
    wire [31:0] axi_wdata;
    wire axi_wvalid;
    wire axi_wlast;
    wire [7:0] axi_wlen;
    wire [1:0] cache_brust_type;
    assign cache_brust_type = 2'b01;   
    wire [2:0] cache_brust_size;
    assign cache_brust_size = 3'b010;

    //icache  与前端模块的交互信号**********************
    wire BPU_flush;
    wire inst_rreq;
    wire [31:0] inst_addr;
    wire [31:0] BPU_pred_addr;
    wire pi_is_exception;
    wire [6:0] pi_exception_cause; 

    wire icache_inst_valid;
    wire [31:0] inst_for_buffer [1:0];
    wire [31:0] pred_addr_for_buffer;
    wire is_exception_for_buffer;
    wire [6:0] exception_cause_for_buffer;
    wire pc_suspend;
    wire [31:0] icache_pc [1:0];
    wire [31:0] icache_inst [1:0];
    //*************************************************


    // 前端给后端的信号
    wire [31:0]fb_pc[1:0];
    wire [31:0]fb_inst[1:0];
    wire fb_valid;
    wire [1:0]fb_pre_taken;
    wire [31:0]fb_pre_branch_addr[1:0];
    wire [1:0]fb_is_exception;
    wire [6:0]fb_exception_cause[1:0][1:0];

    // 后端给前端的信号
    wire iuncache;
    wire [1:0]ex_is_bj;
    wire [31:0]ex_pc[1:0];
    wire [1:0]ex_valid;
    wire [1:0]real_taken;
    wire [31:0]real_addr[1:0];
    wire [31:0]pred_addr[1:0];
    wire get_data_req;
    wire flush_o;
    wire pause_o;

    // 后端给 dcache 的信号
    wire [3:0]  backend_dcache_ren;
    wire [3:0]  backend_dcache_wen;
    wire [31:0] backend_dcache_addr;
    wire [31:0] backend_dcache_write_data;

    // dcache 给后端的信号
    wire [31:0] dcache_backend_rdata;
    wire dcache_backend_rdata_valid;
    wire dcache_backend_write_finish;

    // dcache-AXI 给的 cache 接口信号
    wire dev_rrdy_to_cache;
    wire dev_wrdy_to_cache;
    


    front u_front(
        // 输入
        .cpu_clk(aclk),
        .cpu_rst(rst),

        .iuncache(iuncache),//不知道信号来源       //(别管iuncache信号)

        // 来自 icache 的信号
        .pi_icache_is_exception(is_exception_for_buffer),      //从icache传回来的例外信息
        .pi_icache_exception_cause(exception_cause_for_buffer),
        .pc_for_buffer1(icache_pc[0]),
        .pc_for_buffer2(icache_pc[1]),
        .pred_addr_for_buffer(pred_addr_for_buffer),
        .icache_pc_suspend(pc_suspend),
        .inst_for_buffer1(icache_inst[0]),
        .inst_for_buffer2(icache_inst[1]),
        .icache_inst_valid(icache_inst_valid),

    // *******************
        .fb_flush(0), //如果这是因为分支预测错误，导致后端向前端发送的flush信号，那该信号可以删去，前端的bpu将完成错误判断和flush信号的生成（还需一并去掉front/pc调用中的|前面的fb_flush
        .fb_pause(0),
        .fb_interrupt(0),       // 先全接0

        // 输出给icache的信号
        .BPU_flush(BPU_flush),
        .pi_pc(inst_addr),
        .BPU_pred_addr(BPU_pred_addr),
        .inst_rreq_to_icache(inst_rreq),
        .pi_is_exception(pi_exception_cause),
        .pi_exception_cause(pi_exception_cause),

        // 来自后端的信号
        .ex_is_bj(ex_is_bj),
        .ex_pc1(ex_pc[0]),
        .ex_pc2(ex_pc[1]),
        .ex_valid(ex_valid),
        .real_taken(real_taken),
        .real_addr1(real_addr[0]),
        .read_addr2(real_addr[1]),
        .pred_addr1(pred_addr[0]),
        .pred_addr2(pred_addr[1]),
        .get_data_req(get_data_req),

        // 输出给后端的信号
        .fb_pc_out1(fb_pc[0]),
        .fb_pc_out2(fb_pc[1]),
        .fb_inst_out1(fb_inst[0]),
        .fb_inst_out2(fb_inst[0]),
        .fb_valid(fb_valid),
        .fb_pre_taken(fb_pre_taken),
        .fb_pre_branch_addr1(fb_pre_branch_addr[0]),
        .fb_pre_branch_addr2(fb_pre_branch_addr[1]),
        .fb_is_exception(fb_is_exception),
        .fb_exception_cause(fb_exception_cause)
    );


    backend u_backend(
        .clk(aclk),
        .rst(rst),
        
        // 来自前端的信号
        .pc_i1(fb_pc[0]),
        .pc_i2(fb_pc[1]),
        .inst_i1(fb_inst[0]),
        .inst_i2(fb_inst[1]),
        .valid_i(fb_valid),
        .pre_is_branch_taken_i(fb_pre_taken),
        .pre_branch_addr_i1(fb_pre_branch_addr[0]),
        .pre_branch_addr_i2(fb_pre_branch_addr[1]),
        .is_exception_i(fb_is_exception),
        .exception_cause_i(fb_exception_cause),

        .bpu_flush(BPU_flush),   // 分支预测错误，清空译码队列
    
        // 输出给前端的信号
        .ex_bpu_is_bj(ex_is_bj),
        .ex_pc1(ex_pc[0]),
        .ex_pc2(ex_pc[1]),
        .ex_valid(ex_valid),
        .ex_bpu_taken_or_not_actual(real_taken),
        .ex_bpu_branch_pred_addr1(pred_addr[0]),
        .ex_bpu_branch_pred_addr2(pred_addr[1]),
        .get_data_req_o(get_data_req),

/*******************************
        .tlbidx(),
        .tlbehi(),
        .tlbelo0(),
        .tlbelo1(),
        .tlbelo1(),
        .asid(),
        .ecode(),

        .csr_dme0(),
        .csr_dme1(),
        .csr_da(),
        .csr_pg(),
        .csr_plv(),
        .csr_datf(),
        .csr_datm(),
***********************************/

        // 输出给 dcache 的信号
        .ren_o(backend_dcache_ren),
        .wstrb_o(backend_dcache_wen),
        .virtual_addr_o(backend_dcache_addr),
        .wdata_o(backend_dcache_write_data),

        // dcache 返回的信号
        .rdata_i(dcache_backend_rdata),
        .rdata_valid_i(dcache_backend_rdata_valid),
        .dcache_pause_i(~dcache_backend_write_finish),

        // 从ctrl输出的信号（8位）
        .flush_o(flush_o),
        .pause_o(pause_o)
    );

    icache u_icache
    (
        .clk(aclk),
        .rst(rst),   
        .BPU_flush(BPU_flush),       
    // Interface to CPU
        .inst_rreq(inst_rreq),  // 来自CPU的取指请求
        .inst_addr(unst_addr),      // 来自CPU的取指地址
        .BPU_pred_addr(BPU_pred_addr),

        .pi_is_exception(pi_is_exception),
        .pi_exception_cause(pi_exception_cause),

        .pred_addr(pred_addr_for_buffer),
        .inst_valid(icache_inst_valid),     
        .inst_out1(icache_inst[0]),       
        .inst_out2(icache_inst[1]),
        .pc1(icache_pc[0]),
        .pc2(icache_pc[1]),
        .is_exception_out(is_exception_for_buffer),
        .exception_cause_out(exception_cause_for_buffer),
        .pc_suspend(pc_suspend), 
    // Interface to Read Bus
        .dev_rrdy(dev_rrdy_to_cache),       
        .cpu_ren(icache_ren),       
        .cpu_raddr(icache_araddr),      
        .dev_rvalid(icache_rvalid),     
        .dev_rdata(icache_rdata)   
    );

    dcache u_dcache(
        .clk(aclk),
        .rst(rst),

        // 来自后端的信号
        .ren(backend_dcache_ren),
        .wen(backend_dcache_wen),
        .addr(backend_dcache_addr),
        .write_data(backend_dcache_write_data),

        // 输出给后端的信号
        .rdata(dcache_rdata),
        .rdata_valid(dcache_backend_rdata_valid),    
        .write_finish(dcache_backend_write_finish),  

    //to write BUS
        .dev_wrdy(dev_wrdy_to_cache),      
        .cpu_wen(dcache_wen),        
        .cpu_waddr(dcache_awaddr),      
        .cpu_wdata(dcache_wdata),      
    //to Read Bus
        .dev_rrdy(dev_rrdy_to_cache),       
        .cpu_ren(dcache_ren),        
        .cpu_raddr(dcache_araddr),      
        .dev_rvalid(dcache_rvalid),     
        .dev_rdata(dcache_rdata)      
    );

    axi_interface u_axi_interface(
        .clk(aclk),
        .rst(rst),
    //connected to cache_axi
        .cache_ce(axi_ce_o),
        .cache_wen(axi_wen),         
        .cache_ren(axi_ren),         
        .cache_raddr(axi_raddr),
        .cache_waddr(axi_waddr),
        .cache_wdata(axi_wdata),
        .cache_rready(axi_rready),    
        .cache_wvalid(axi_wvalid),     
        .cache_wlast(axi_wlast),      
        .wdata_resp_o(axi_wdata_resp),    
    
        .cache_brust_type(cache_brust_type),  
        .cache_brust_size(cache_brust_size),
        .cacher_burst_length(axi_rlen),
        .cachew_burst_length(axi_wlen),

        .arid(arid),       
        .araddr(araddr),      
        .arlen(arlen),      
        .arsize(arsize),
        .arburst(arburst),
        .arlock(arlock),   
        .arcache(arcache),   
        .arprot(arprot),   
        .arvalid(arvalid),       
        .arready(arready),         
    //R读数据
        .rid(rid),
        .rdata(rdata),   
        .rresp(rresp),    
        .rlast(rlast),           
        .rvalid(rvalid),       
        .rready(rready),         
    //AW写地址
        .awid(awid),     
        .awaddr(awaddr),  
        .awlen(awlen),    
        .awsize(awsize),   
        .awburst(awburst),
        .awlock(awlock),   
        .awcache(awcache),
        .awprot(awprot),   
        .awvalid(awvalid),        
        .awready(awready),        
    //W写数据
        .wid(wid),     
        .wdata(wdata),  
        .wstrb(wstrb),    
        .wlast(wlast),          
        .wvalid(wvalid),       
        .wready(wready),         
    //写响应
        .bid(bid),      
        .bresp(bresp),    
        .bvalid(bvalid),        
        .bready(bready)         
    );

    cache_AXI u_cache_AXI(
        .clk(aclk),
        .rst(rst),    // low active

    //icache read
        .inst_ren_i(icache_ren),
        .inst_araddr_i(icache_araddr),
        .inst_rvalid_o(icache_rvalid),
        .inst_rdata_o(icache_rdata),

    //dcache read
        .data_ren_i(dcache_ren),
        .data_araddr_i(dcache_araddr),
        .data_rvalid_o(dcache_rvalid),
        .data_rdata_o(dcache_rdata),

    //dcache write
        .data_wen_i(dcache_wen),
        .data_wdata_i(dcache_wdata),
        .data_awaddr_i(dcache_awaddr),
        .data_bvalid_o(dcache_bvalid),

    //ready to cache
        .dev_rrdy_o(dev_rrdy_to_cache),
        .dev_wrdy_o(dev_wrdy_to_cache),

    //AXI communicate
        .axi_ce_o(axi_ce_o),
        .axi_wsel_o(axi_wsel),   // 连接总线的wstrb

    //AXI read
        .rdata_i(rdata),
        .rdata_valid_i(rdata_valid),
        .axi_ren_o(axi_ren),
        .axi_rready_o(axi_rready),
        .axi_raddr_o(axi_raddr),
        .axi_rlen_o(axi_rlen),

    //AXI write
        .wdata_resp_i(wdata_resp),  // 写响应信号
        .axi_wen_o(axi_wen),
        .axi_waddr_o(axi_waddr),
        .axi_wdata_o(axi_wdata),
        .axi_wvalid_o(axi_wvalid),
        .axi_wlast_o(axi_wlast),
        .axi_wlen_o(axi_wlen)
    );

endmodule