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
    output wire        bready,

    output wire [31:0] debug_wb_pc,    
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,
    output wire [31:0] debug_wb_inst

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
    wire [31:0] dcache_rdata;
    wire [3:0] dcache_wen;
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
    wire [127:0] dcache_axi_data_block;

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

    //icache  闁跨喐鏋婚幏宄板闁跨喐鏋婚幏閿嬆侀柨鐔告灮閹烽攱鍘遍柨鐔告灮閹风兘鏁撻弬銈嗗閽樻洟鏁撻敓锟?**********************
    wire BPU_flush;
    wire inst_rreq;
    wire [31:0] inst_addr;
    wire [31:0] BPU_pred_addr;
    wire pi_is_exception;
    wire [6:0] pi_exception_cause; 

    wire icache_inst_valid;
    wire [31:0] pred_addr_for_buffer;
    wire pi_icache_is_exception1;
    wire pi_icache_is_exception2;
    wire [6:0] pi_icache_exception_cause1;
    wire [6:0] pi_icache_exception_cause2;
    wire pc_suspend;
    wire [31:0] icache_pc1;
    wire [31:0] icache_pc2;
    wire [31:0] icache_inst1;
    wire [31:0] icache_inst2;
    //*************************************************


    // 閸撳秹鏁撻崜鍧楁交閹风兘鏁撻弬銈嗗鐠囨挳鏁撻弬銈嗗閽樻洟鏁撻敓锟?
    wire [31:0]fb_pc1;
    wire [31:0]fb_pc2;
    wire [31:0]fb_inst1;
    wire [31:0]fb_inst2;
    wire [1:0] fb_valid;
    wire [1:0]fb_pre_taken;
    
    assign fb_pre_taken = 2'b0;
    
    wire [31:0]fb_pre_branch_addr1;
    wire [31:0]fb_pre_branch_addr2;
    wire [1:0] fb_is_exception1;
    wire [1:0] fb_is_exception2;
    wire [6:0] fb_pc_exception_cause1;
    wire [6:0] fb_pc_exception_cause2;
    wire [6:0] fb_instbuffer_exception_cause1;
    wire [6:0] fb_instbuffer_exception_cause2;

    // 闁跨喐鏋婚幏椋庡剨闁跨喕顫楃敮顔藉鐠囨挳鏁撻弬銈嗗閽樻洟鏁撻敓锟?
    wire iuncache;
    wire [1:0]ex_is_bj;
    wire [31:0]ex_pc1;
    wire [31:0]ex_pc2;
    wire [1:0]ex_valid;
    wire [1:0]ex_real_taken;
    wire [31:0]ex_real_addr1;
    wire [31:0]ex_real_addr2;
    wire [31:0]ex_pred_addr1;
    wire [31:0]ex_pred_addr2;
    wire get_data_req;
    wire [7:0] flush_o;
    wire [7:0] pause_o;

    // 闁跨喐鏋婚幏椋庡剨闁跨噦鎷? dcache 闁跨喐鏋婚幏鐑芥晸閼存氨灏ㄩ幏锟?
    wire  backend_dcache_ren;
    wire [3:0]  backend_dcache_wen;
    wire [31:0] backend_dcache_addr;
    wire [31:0] backend_dcache_write_data;

    // dcache 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚圭拠鎾晸閺傘倖瀚归挊鏇㈡晸閿燂拷
    wire [31:0] dcache_backend_rdata;
    wire dcache_backend_rdata_valid;
    wire dcache_ready;

    // dcache-AXI 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚? cache 闁跨喐甯撮崠鈩冨闁跨喕鍓奸悮瀛樺
    wire dev_rrdy_to_cache;
    wire dev_wrdy_to_cache;

    wire duncache_rvalid;
    wire [31:0] duncache_rdata;
    wire  duncache_ren;
    wire [31:0] duncache_raddr;

    wire duncache_write_finish;
    wire [3:0] duncache_wen;
    wire [31:0] duncache_wdata;
    wire [31:0] duncache_waddr;
    


    front u_front(
        // 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚?
        .cpu_clk(aclk),
        .cpu_rst(rst),

        .iuncache(iuncache),//闁跨喐鏋婚幏椋庣叀闁跨喐鏋婚幏鐑芥晸閼存氨灏ㄩ幏鐑芥晸閺傘倖瀚瑰┃锟?       //(闁跨喐鏋婚幏鐑芥晸缁茬垜ncache闁跨喕鍓奸悮瀛樺)

        // 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚? icache 闁跨喐鏋婚幏鐑芥晸閼存氨灏ㄩ幏锟?
        .pi_icache_is_exception1(pi_icache_is_exception1),      //闁跨喐鏋婚幏绌抍ache闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔告灮閹风兘鏁撻弬銈嗗闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔告灮閹烽攱浼?
        .pi_icache_is_exception2(pi_icache_is_exception2),
        .pi_icache_exception_cause1(pi_icache_exception_cause1),  
        .pi_icache_exception_cause2(pi_icache_exception_cause2),
        .pc_for_buffer1(icache_pc1),
        .pc_for_buffer2(icache_pc2),
        .pred_addr_for_buffer(pred_addr_for_buffer),
        .icache_pc_suspend(pc_suspend),
        .inst_for_buffer1(icache_inst1),
        .inst_for_buffer2(icache_inst2),
        .icache_inst_valid(icache_inst_valid),

    // *******************
        .fb_flush({flush_o[2],flush_o[0]}), //闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔告灮閹风兘鏁撻弬銈嗗闁跨喕濞囬搴㈠闁跨喕顢滆皭閵堝繑瀚归柨鐔告灮閹风兘鏁撶憲鐕傜礉绾板瀚归柨鐔兼應閻氬瓨瀚归柨鐔告灮閹风兘鏁撶憴鎺戝簻閹烽攱婀愰柨鐔告灮閹峰嘲浼旈柨鐔虹lush闁跨喕鍓奸崣鍑ょ秶閹风兘鏁撶憴鎺楁交閹风兘鏁撻懘姘娇閸栤剝瀚归柨鐔告灮閹峰嘲鍨归崢濠氭晸閺傘倖瀚归崜宥夋晸閸撹法顣幏绌妏u闁跨喐鏋婚幏鐑芥晸閺傘倖瀚圭痪閬嶆晸閺傘倖瀚归柨鐔告灮閹峰嘲宓忛搹楣冩晸缁叉姬ush闁跨喕鍓奸崣椋庮暜閹风兘鏁撻弬銈嗗闁跨喓鍗抽敐蹇斿闁跨喐鏋婚幏鐑芥晸閺傘倖瀚规稉鈧柨鐔告灮閹峰嘲骞撻柨鐔告灮閹风⿴ront/pc闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔峰建绾板瀚箌閸撳秹鏁撻弬銈嗗闁跨喓绂巄_flush
        .fb_pause({pause_o[2],pause_o[0]}),
        .fb_interrupt(1'b0),       // 闁跨喐鏋婚幏宄板弿闁跨喐鏋婚幏锟?0
//        .fb_new_pc(32'b0),

        // 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔虹cache闁跨喐鏋婚幏鐑芥晸閼存氨灏ㄩ幏锟?
        .BPU_flush(BPU_flush),
        .pi_pc(inst_addr),
        .BPU_pred_addr(BPU_pred_addr),
        .inst_rreq_to_icache(inst_rreq),
        .pi_is_exception(pi_is_exception),
        .pi_exception_cause(pi_exception_cause),

        // 闁跨喐鏋婚幏鐑芥晸閻ㄥ棛灏ㄩ幏鐤嚛闁跨喐鏋婚幏鐤闁跨噦鎷?
        .ex_is_bj(ex_is_bj),
        .ex_pc1(ex_pc1),
        .ex_pc2(ex_pc2),
        .ex_valid(ex_valid),
        .real_taken(ex_real_taken),
        .real_addr1(ex_real_addr1),
        .real_addr2(ex_real_addr2),
        .pred_addr1(ex_pred_addr1),
        .pred_addr2(ex_pred_addr2),
        .get_data_req(get_data_req),

        // 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔告灮閹风兘鏁撻崜璺暜閹风兘鏁撻懘姘卞皑閹凤拷
        .fb_pc_out1(fb_pc1),
        .fb_pc_out2(fb_pc2),
        .fb_inst_out1(fb_inst1),
        .fb_inst_out2(fb_inst2),
        .fb_valid(fb_valid),
        .fb_pre_branch_addr1(fb_pre_branch_addr1),
        .fb_pre_branch_addr2(fb_pre_branch_addr2),
        .fb_is_exception1(fb_is_exception1),
        .fb_is_exception2(fb_is_exception2),
        .fb_pc_exception_cause1(fb_pc_exception_cause1),
        .fb_pc_exception_cause2(fb_pc_exception_cause2),
        .fb_instbuffer_exception_cause1(fb_instbuffer_exception_cause1),
        .fb_instbuffer_exception_cause2(fb_instbuffer_exception_cause2)
    );


    backend u_backend(
        .clk(aclk),
        .rst(rst),
        
        // 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归崜宥夋晸閸撹法顣幏鐑芥晸閼存氨灏ㄩ幏锟?
        .pc_i1(fb_pc1),
        .pc_i2(fb_pc2),
        .inst_i1(fb_inst1),
        .inst_i2(fb_inst2),
        .valid_i(fb_valid),
        .pre_is_branch_taken_i(fb_pre_taken),
        .pre_branch_addr_i1(fb_pre_branch_addr1),
        .pre_branch_addr_i2(fb_pre_branch_addr2),
        .is_exception1_i(fb_is_exception1),
        .is_exception2_i(fb_is_exception2),
        .pc_exception_cause1_i(fb_pc_exception_cause1),
        .pc_exception_cause2_i(fb_pc_exception_cause2),
        .instbuffer_exception_cause1_i(fb_instbuffer_exception_cause1),
        .instbuffer_exception_cause2_i(fb_instbuffer_exception_cause2),

        .bpu_flush(BPU_flush),   // 闁跨喐鏋婚幏閿嬫暜妫板嫰鏁撻弬銈嗗闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔告灮閹风兘鏁撻弬銈嗗闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐕傛嫹
    
        // 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔活潡鐢喗瀚圭拠鎾晸閺傘倖瀚归挊鏇㈡晸閿燂拷
        .ex_bpu_is_bj(ex_is_bj),
        .ex_pc1(ex_pc1),
        .ex_pc2(ex_pc2),
        .ex_valid(ex_valid),
        .ex_bpu_taken_or_not_actual(ex_real_taken),
        .ex_bpu_branch_actual_addr1(ex_real_addr1),  
        .ex_bpu_branch_actual_addr2(ex_real_addr2),
        .ex_bpu_branch_pred_addr1(ex_pred_addr1),
        .ex_bpu_branch_pred_addr2(ex_pred_addr2),
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

        // 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐕傛嫹 dcache 闁跨喐鏋婚幏鐑芥晸閼存氨灏ㄩ幏锟?
        .ren_o(backend_dcache_ren),
        .wstrb_o(backend_dcache_wen),
        .virtual_addr_o(backend_dcache_addr),
        .wdata_o(backend_dcache_write_data),

        // dcache 闁跨喐鏋婚幏鐑芥晸閹搭亞顣幏鐑芥晸閼存氨灏ㄩ幏锟?
        .rdata_i(dcache_rdata),
        .rdata_valid_i(dcache_backend_rdata_valid),
        .dcache_pause_i(~dcache_ready),

        // 闁跨喐鏋婚幏绌媡rl闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔告灮閹风柉妫旈悧娑㈡晸閿燂拷8娴ｅ秹鏁撻弬銈嗗
        .flush_o(flush_o),
        .pause_o(pause_o),
        
        //debug
        .debug_wb_valid1(debug_wb_valid1),
        .debug_wb_valid2(debug_wb_valid2),
        .debug_pc1(debug_pc1),
        .debug_pc2(debug_pc2),
        .debug_inst1(debug_inst1),
        .debug_inst2(debug_inst2),
        .debug_reg_addr1(debug_reg_addr1),
        .debug_reg_addr2(debug_reg_addr2),
        .debug_wdata1(debug_wdata1),
        .debug_wdata2(debug_wdata2),
        .debug_wb_we1(debug_wb_we1),
        .debug_wb_we2(debug_wb_we2) 
    );

    icache u_icache
    (
        .clk(aclk),
        .rst(rst),   
        .BPU_flush(BPU_flush),       
    // Interface to CPU
        .inst_rreq(inst_rreq),  // 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚笴PU闁跨喐鏋婚幏宄板絿閹稿洭鏁撻弬銈嗗闁跨喐鏋婚幏锟?
        .inst_addr(inst_addr),      // 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚笴PU闁跨喐鏋婚幏宄板絿閹稿洭鏁撻弬銈嗗閸р偓
        .BPU_pred_addr(BPU_pred_addr),

        .pi_is_exception(pi_is_exception),
        .pi_exception_cause(pi_exception_cause),

        .pred_addr(pred_addr_for_buffer),
        .inst_valid(icache_inst_valid),     
        .inst_out1(icache_inst1),       
        .inst_out2(icache_inst2),
        .pc1(icache_pc1),
        .pc2(icache_pc2),
        .pc_is_exception_out1(pi_icache_is_exception1),
        .pc_is_exception_out2(pi_icache_is_exception2), 
        .pc_exception_cause_out1(pi_icache_exception_cause1),
        .pc_exception_cause_out2(pi_icache_exception_cause2),
        .pc_suspend(pc_suspend), 
    // Interface to Read Bus
        .dev_rrdy(dev_rrdy_to_cache),       
        .cpu_ren(icache_ren),       
        .cpu_raddr(icache_araddr),      
        .dev_rvalid(icache_rvalid),     
        .dev_rdata(icache_rdata)   
    );

    wire debug_wb_valid1;
    wire debug_wb_valid2;
    wire [31:0] debug_pc1;
    wire [31:0] debug_pc2;
    wire [31:0] debug_inst1;
    wire [31:0] debug_inst2;
    wire [4:0] debug_reg_addr1;
    wire [4:0] debug_reg_addr2;
    wire [31:0] debug_wdata1;
    wire [31:0] debug_wdata2;
    wire debug_wb_we1;
    wire debug_wb_we2;

    dcache u_dcache(
        .clk(aclk),
        .rst(rst),

        // 闁跨喐鏋婚幏鐑芥晸閻ㄥ棛灏ㄩ幏鐤嚛闁跨喐鏋婚幏鐤闁跨噦鎷?
        .ren(backend_dcache_ren),
        .wen(backend_dcache_wen),
        .vaddr(backend_dcache_addr),
        .write_data(backend_dcache_write_data),

        // 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔告灮閹风兘鏁撻崜璺暜閹风兘鏁撻懘姘卞皑閹凤拷
        .rdata(dcache_rdata),
        .rdata_valid(dcache_backend_rdata_valid),    
        .dcache_ready(dcache_ready),  

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
        .dev_rdata(dcache_axi_data_block),
    //duncache to cache_axi
        .uncache_rvalid(duncache_rvalid),
        .uncache_rdata(duncache_rdata),
        .uncache_ren(duncache_ren),
        .uncache_raddr(duncache_raddr),

        .uncache_write_finish(duncache_write_finish),
        .uncache_wen(duncache_wen),
        .uncache_wdata(duncache_wdata),
        .uncache_waddr(duncache_waddr)  
    );

    axi_interface u_axi_interface(
        .clk(aclk),
        .rst(rst),
    //connected to cache_axi
        .cache_ce(axi_ce_o),
        .cache_wen(axi_wen),   
        .cache_wsel(axi_wsel),      
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
    //R闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔告灮閹凤拷
        .rid(rid),
        .rdata(rdata),   
        .rresp(rresp),    
        .rlast(rlast),           
        .rvalid(rvalid),       
        .rready(rready),
        .rdata_o(axi_rdata),
        .rdata_valid_o(axi_rdata_valid),         
    //AW閸愭瑩鏁撻弬銈嗗閸р偓
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
    //W閸愭瑩鏁撻弬銈嗗闁跨喐鏋婚幏锟?
        .wid(wid),     
        .wdata(wdata),  
        .wstrb(wstrb),    
        .wlast(wlast),          
        .wvalid(wvalid),       
        .wready(wready),         
    //閸愭瑩鏁撻弬銈嗗鎼达拷
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
        .data_rdata_o(dcache_axi_data_block),

    //dcache write
        .data_wen_i(dcache_wen),
        .data_wdata_i(dcache_wdata),
        .data_awaddr_i(dcache_awaddr),
        .data_bvalid_o(dcache_bvalid),

    //ready to cache
        .dev_rrdy_o(dev_rrdy_to_cache),
        .dev_wrdy_o(dev_wrdy_to_cache),

    //uncache to dcache
        .duncache_ren_i(duncache_ren),
        .duncache_raddr_i(duncache_raddr),
        .duncache_rvalid_o(duncache_rvalid),
        .duncache_rdata_o(duncache_rdata),

        .duncache_wen_i(duncache_wen),
        .duncache_wdata_i(duncache_wdata),
        .duncache_waddr_i(duncache_waddr),
        .duncache_write_resp(duncache_write_finish),

    //AXI communicate
        .axi_ce_o(axi_ce_o),
        .axi_wsel_o(axi_wsel),   // 闁跨喐鏋婚幏鐑芥晸閺傘倖瀚归柨鐔告灮閹风兘鏁撶粩顓狀暜閹风strb

    //AXI read
        .rdata_i(axi_rdata),
        .rdata_valid_i(axi_rdata_valid),
        .axi_ren_o(axi_ren),
        .axi_rready_o(axi_rready),
        .axi_raddr_o(axi_raddr),
        .axi_rlen_o(axi_rlen),

    //AXI write
        .wdata_resp_i(axi_wdata_resp),  // 閸愭瑩鏁撻弬銈嗗鎼存棃鏁撻懘姘卞皑閹凤拷
        .axi_wen_o(axi_wen),
        .axi_waddr_o(axi_waddr),
        .axi_wdata_o(axi_wdata),
        .axi_wvalid_o(axi_wvalid),
        .axi_wlast_o(axi_wlast),
        .axi_wlen_o(axi_wlen)
    );


    wire [101:0] data1;
    wire [101:0] data2;
    wire valid1;
    wire valid2;
    wire [101:0] debug_data_out;
    wire debug_valid_out;

    assign data1 = {debug_wb_we1,debug_reg_addr1,debug_wdata1,debug_inst1,debug_pc1};
    assign data2 = {debug_wb_we2,debug_reg_addr2,debug_wdata2,debug_inst2,debug_pc2};
    assign valid1 = debug_wb_valid1;
    assign valid2 = debug_wb_valid2;


    debug_FIFO debug
    (
        .clk(aclk),
        .rst(rst),
        .valid1(valid1),
        .data1(data1),
        .valid2(valid2),
        .data2(data2),
        .data_out(debug_data_out),
        .valid_out(debug_valid_out)
    );

    assign debug_wb_pc = debug_data_out[31:0];  
    assign debug_wb_rf_we = {4{debug_data_out[101]}};
    assign debug_wb_rf_wnum = debug_data_out[100:96];
    assign debug_wb_rf_wdata = debug_data_out[95:64];
    assign debug_wb_inst = debug_data_out[63:32];

endmodule