`timescale 1ns / 1ps

module core_top(
    input  wire        aclk,
    input  wire        aresetn,
    input  wire [ 7:0] intrpt, 
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

    // debug
    
    input           break_point,    //无需实现功能，仅提供接口即可，输�?1’b0
    input           infor_flag,     //无需实现功能，仅提供接口即可，输�?1’b0
    input  [ 4:0]   reg_num,        //无需实现功能，仅提供接口即可，输�?5’b0
    output          ws_valid,       //无需实现功能，仅提供接口即可
    output [31:0]   rf_rdata,       //无需实现功能，仅提供接口即可

    output [31:0] debug0_wb_pc,
    output [ 3:0] debug0_wb_rf_wen,
    output [ 4:0] debug0_wb_rf_wnum,
    output [31:0] debug0_wb_rf_wdata

);
    wire rst;
    assign rst = !aresetn;

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

    //icache  闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨抽�?顒傛�?鐎氼厼顭垮鈧矾闁告稑鐡ㄩ埛鎴︽偣閹帒濡奸柡瀣灴閺岋紕鈧綆浜堕悡鍏碱殽閻愯尙绠婚柡灞诲妿閳ь剨绲藉Λ鏃傛濮樿泛钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧瀚板娲捶椤撶偛骞嬮梺琛�?�亾闂侇剙绉撮崒銊╂⒑椤掆偓缁夌敻鎮￠妷鈺傜厽闁哄�?��?�ч崯鐐烘煟韫囷絽娅嶉柡宀€鍠愰ˇ鐗堟償閳ュ啿绠ｉ梻浣芥〃閻掞箓骞戦崶褜鍤曟い鎺戝鍥撮梺绯曞墲椤ㄥ繑�?�奸幘缁樷拺闁兼亽鍎旈幋婢濇椽鎮㈤悡搴㈢€梺鐟板⒔缁垶寮查幖浣规櫢闁跨噦鎷�??**********************
    wire BPU_flush;
    wire inst_rreq;
    wire [31:0] inst_addr;
    wire [31:0] BPU_pred_addr;
    wire pi_is_exception;
    wire [6:0] pi_exception_cause; 

    wire icache_inst_valid;
    wire [31:0] pred_addr_for_buffer;
    wire [1:0] pred_taken_for_buffer;
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


    // 闂傚倷绀�?幉锟犲箰閸濄儳鐭撶憸鐗堝笒閺嬩線鏌熼幑鎰靛殭缂佲偓閸儲鐓曠憸搴ㄣ€冮崱妯碱洸闁靛牆顦伴悡娆忣渻鐎ｎ亪顎楅柛妯绘尦閺屸剝鎷呯憴鍕３閻庢鍣�?崜鐔镐繆閸洖骞㈡俊銈咃梗缁憋箓姊洪懡銈呅㈡繛璇х畵楠炴劙骞庨挊澶嬬€梺瑙勫礃椤曆兾涘鈧弻鏇㈠醇濠靛浂妫炲銈呯箰閻栧ジ寮婚敃鈧灒缂備焦顭囬ˇ浼存⒑鏉炴壆鍔嶉柟鐟版喘�?�偊骞樼紒妯绘�??
    wire fb_pred_taken1;
    wire fb_pred_taken2;
    wire [31:0]fb_pc1;
    wire [31:0]fb_pc2;
    wire [31:0]fb_inst1;
    wire [31:0]fb_inst2;
    wire [1:0] fb_valid;
    wire [1:0]fb_pre_taken;
    
    
    wire [31:0]fb_pre_branch_addr1;
    wire [31:0]fb_pre_branch_addr2;
    wire [1:0] fb_is_exception1;
    wire [1:0] fb_is_exception2;
    wire [6:0] fb_pc_exception_cause1;
    wire [6:0] fb_pc_exception_cause2;
    wire [6:0] fb_instbuffer_exception_cause1;
    wire [6:0] fb_instbuffer_exception_cause2;

    // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨伴—鍐偓锝庝邯椤庢鏌涢幘鍗炲婵﹨娅ｉ幑鍕Ω閵夛妇浜炴俊鐐€ら崑鍛淬€冮崼銉ユ瀬妞ゆ洍鍋撴い銏＄懇閹稿﹥寰勫Ο鍦闂備浇宕垫慨鏉懨洪敃鍌氱闁规儼妫勯弸渚€鏌熼幑鎰靛殭婵☆偅锕㈤弻鏇㈠醇濠靛浂妫炲銈呯箰閻栧ジ寮婚敃鈧灒缂備焦顭囬ˇ浼存⒑鏉炴壆鍔嶉柟鐟版喘�?�偊骞樼紒妯绘�??
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

    // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨伴—鍐偓锝庝邯椤庢鏌涢幘鍗炲婵﹨娅ｉ幑鍕Ω閵夛妇褰氶梺璺ㄥ櫐閹凤拷?? dcache 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡灞诲€楅�?顒佺⊕钃遍柣銊﹀灴閹ǹ绠涚€ｎ亜顫囧Δ鐘靛仜缁绘﹢寮敓锟�??
    wire  backend_dcache_ren;
    wire [3:0]  backend_dcache_wen;
    wire [31:0] backend_dcache_addr;
    wire [31:0] backend_dcache_write_data;

    // dcache 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕�?�闁�?秴绠柣妯款嚙缁犵粯銇勯弮鍥撴繛鍛灲濮婃椽宕崟顐熷亾閸洖纾归柡宥呯仛鐎氾�??闂佽法鍠曞Λ鍕礊婵犲洤绠板┑鐘叉搐閸楁娊鏌曡箛濠傚⒉婵炲懌鍨藉铏规崉閵娿儲鐝㈤梺璺ㄥ櫐閹凤�??
    wire [31:0] dcache_backend_rdata;
    wire dcache_backend_rdata_valid;
    wire dcache_ready;

    // dcache-AXI 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷??? cache 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟閭�?枟閺嗘粓鏌熺紒銏犳灈缂佲偓�?�€鍕厓闁宠桨�?�?弳娆愩亜韫囨挾鍩ｆ慨濠呮閹瑰嫰濡搁妷锔句簽闂備礁鎲￠幐鎼佸Χ閹间礁绠栨い鏇炴鐎氾拷?闂佽法鍠曟慨銈夋晪闂佽法鍣﹂幏锟�??
    wire dev_rrdy_to_cache;
    wire dev_wrdy_to_cache;

    wire duncache_rvalid;
    wire [31:0] duncache_rdata;
    wire  duncache_ren;
    wire [31:0] duncache_raddr;

    wire duncache_write_finish;
    wire duncache_wen;
    wire [31:0] duncache_wdata;
    wire [31:0] duncache_waddr;
    
    wire [31:0] new_pc_from_ctrl;
    wire [1:0] BPU_pred_taken;

    //閸氬海顏惃鍒r鏉堟挸鍙嗙紒妾況ans_addr閻ㄥ嫪淇婇崣锟�
    wire [31:0] csr_dmw0;//dmw0閿涘本婀�?弫鍫滅秴閺勭�?27:25]閿涘苯褰查懗鎴掔窗娴ｆ粈璐熼張鈧崥搴ゆ祮閹广垹鍤弶銉ф畱閸︽澘娼冮惃鍕付妤傛ü绗佹担锟�?
    wire [31:0] csr_dmw1;//dmw1閿涘本婀�?弫鍫滅秴閺勭�?27:25]閿涘苯褰查懗鎴掔窗娴ｆ粈璐熼張鈧崥搴ゆ祮閹广垹鍤弶銉ф畱閸︽澘娼冮惃鍕付妤傛ü绗佹担锟�?
    wire        csr_da;
    wire        csr_pg;
    wire [1:0]  csr_plv;

    //trans_addr to dcache
    wire [31:0] ret_data_paddr;
    front u_front
    (
        // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷???
        .cpu_clk(aclk),
        .cpu_rst(rst),

        .iuncache(iuncache),//闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨伴—鍐偓锝庝簼閹癸綁鏌ㄩ悤鍌涘?闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡灞诲€楅�?顒佺⊕钃遍柣銊﹀灴閹ǹ绠涚€ｎ亜顫囧Δ鐘靛仜缁绘﹢骞冨⿰鍫熷殟闁靛�?闄勯鐔兼⒒娴ｅ憡鎯堥柛濠傜埣�?�曟劙寮介崹顐㈩�??闂佽法鍠撻弲顐﹀箠閹捐鐓橀柛鎰靛枟閺咃�??       //(闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱厽鎲哥紒杈ㄥ浮閹崇娀顢楅�?顒勬倶婵夌ache闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柡鍥ュ灩缁€鍫濃攽閸屾碍鍟為柛�?�墵閹鈽夊▍顓т邯閺佹捇鏁撻敓锟�??)

        // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷??? icache 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡灞诲€楅�?顒佺⊕钃遍柣銊﹀灴閹ǹ绠涚€ｎ亜顫囧Δ鐘靛仜缁绘﹢寮敓锟�??
        .pred_taken(BPU_pred_taken),
        .pi_icache_is_exception1(pi_icache_is_exception1),      //闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨崇槐鎺斾沪閹�?€碼che闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧�?�板楦裤亹閹烘繃顥栭梺绋跨箲閿曘垹顕ｉ锕€绠婚悹鍥у级椤ユ繈姊洪棃娑氬婵☆偅顨婇、鏃堝醇閺囩啿鎷洪柣鐘充航閸斿矂寮搁幋锔界厸閻庯綆浜堕悡鍏碱殽閻愯尙绠婚柟顔界矒閹崇偤濡烽敂绛嬩户闂傚�?�绀�?幖顐�?磹閸洖纾归柡宥呯仛鐎氾�??闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧�?�板娲捶椤撶偛骞嬮梺琛�?�亾閺夊牄鍔岄锟�?
        .pi_icache_is_exception2(pi_icache_is_exception2),
        .pi_icache_exception_cause1(pi_icache_exception_cause1),  
        .pi_icache_exception_cause2(pi_icache_exception_cause2),
        .pc_for_buffer1(icache_pc1),
        .pc_for_buffer2(icache_pc2),
        .pred_addr_for_buffer(pred_addr_for_buffer),
        .pred_taken_for_buffer(pred_taken_for_buffer),
        .icache_pc_suspend(pc_suspend),
        .inst_for_buffer1(icache_inst1),
        .inst_for_buffer2(icache_inst2),
        .icache_inst_valid(icache_inst_valid),

    // *******************
        .fb_flush({flush_o[2],flush_o[0]}), //闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧�?�板楦裤亹閹烘繃顥栭梺绋跨箲閿曘垹顕ｉ锕€绠婚悹鍥у级椤ユ繈姊洪棃娑氬婵☆偅顨婇、鏃堝醇閺囩啿鎷洪柣鐘充航閸斿矂寮稿▎蹇婃斀闁绘劕寮堕崰妯汇亜閵忊剝鈷愰柟顖涙婵偓闁绘瑢鍋撳ù鍏兼崌濮婄粯鎷呴懞銉с€婇梺鍝ュУ濞茬喖濡存担绯曞牚闁糕剝鐟﹂惁鏃堟⒒娓氣偓濞佳囨偋閸℃瑦宕查柟鎼灡鐎氾拷?闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧�?�板楦裤亹閹烘繃顥栭梺绋跨箲閿曘垹顕ｉ锕€绠婚柤鎼佹涧閺嗛亶姊虹紒妯荤闁稿﹨宕电划鍫熷緞�?�€鈧Λ顖炴煛婢跺鍎ユ俊鎻掔秺閹顫濋鍌溞ㄩ梺鍝勮閸�?垿骞冮姀銈呯闁稿繒鍘у▍婵嬫⒒娴ｈ櫣甯涢柤褰掔畺閹椽鈥﹂幒鎾愁�??闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧�?�板楦裤亹閹烘繃顥栭梺绋跨箲閿曘垹顕ｉ锕€绠婚柤鎼佹涧閺嬪�?�姊洪崷顓炲妺闁搞劎鏁搁懞杈ㄧ節濮橆厾鍘甸梺缁樺灱婵�?�寮柆宥嗘櫢闁跨噦鎷�?闂佽澹嗘晶妤呮偂閵夆晜鐓熼柡鍌涘閸熺偤鏌ｈ箛锝呮珝闁哄瞼鍠庨悾锟犲级閹稿巩鈺傜箾閺夋垵鎮戞俊顐㈠暣�?�濡搁埡鍌氫簻闂佹儳绻楅鏍虹花鍊乻h闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柡鍥ュ灩缁€鍫濃攽閸屾簱褰掓儗濡ゅ懏鐓曢柟�?�樼懃閳ь剚顨堢划鏃堝醇閺囩喓鍘垫俊鐐差儏妤犳悂宕㈤幘顔界厸濞达綀顫夌亸鐢告煙閸欏灏︽鐐村笒铻栧ù锝夋敱閸炲姊绘担鍝ョШ妞ゃ儲鎹囧畷妤€顫滈�?顒€顕ｉ锕€绠荤紓浣姑▓妤€鈹戦鏂や緵闁告挻鐟︾换娑㈠炊椤掍胶鍘遍梺鍝勭Р閸婃洘鏅堕弻銉�?€垫慨姗嗗墰缁夋椽鏌＄仦璇插闁诡喓鍨藉畷銊︾節閸曨亞纾块梻鍌欒兌閹虫捇宕查弻銉ュ簥闁哄被鍎遍崹鍌滄喐閻�?牆绗掗柛灞诲妼閳规垿鎮╁畷鍥舵殹闂佸搫鎳忛幃鍌炲蓟閿熺姴纾兼慨妤€鐗婄€氾拷?闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲倻鏆︽繝濠傚枤閸氬顭跨捄渚剱婵炲懌鍨藉娲川婵犲啫纾╁┑鐐差槹濞茬喖濡撮崒鐐存櫢闁跨噦鎷�?濡ょ姷鍋涚换鎺斿垝濮橆厺绻嗙€殿喗鐗犲缁樻媴閼恒儳銆婇梺鍝ュУ閸�?瑥顕ｉ崨濠勭瘈婵﹩鍓涢鍡涙⒑缂佹ê鐏卞┑顔哄€濆鏌ュ箹娴ｅ湱鍘搁梺绋挎湰閿曨偊骞忛敓锟�?闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕�?�闁�?秵鍎夋い蹇撶墛閻掕偐鈧箍鍎卞Λ娆忊枍閵忋倖鈷戦柛婵嗗閳ь剙鐖煎畷鎰板�?閸偄顏�??闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧�?�板娲偡閺夋寧些闂佹悶鍨鸿ぐ鍐偩娴ｅ啰鐤€婵炴垶鐟﹂崕顏呬繆閵堝繒鍒伴柛鐕佸灦瀵煡宕妷褏锛滈梺鍛婄懃椤︻垵鈪瞮sh闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柡鍥ュ灩缁€鍫濃攽閸屾簱褰掓儗濡も偓椤啰鈧綆浜滈惁銊╂煛閸℃鐭掗柡�?€鍠愰ˇ鐗堟償閳ュ啿绠ｉ梻浣芥〃閻掞箓骞戦崶褜鍤曟い鎺戝鍥撮梺绯曞墲椤ㄥ繑�?�奸幘缁樷拻濞达�?濮ょ涵鍫曟煕閻樿櫕宕�?€规洩绻濋獮搴ㄦ嚍閵夛附鐝抽梻濠庡亜濞诧箓寮婚妸鈺婃晜闁割偅娲橀埛鎴︽偣閹帒濡奸柡瀣灴閺岋紕鈧綆浜堕悡鍏碱殽閻愯尙绠婚柟顔界矒閹崇偤濡烽敂绛嬩户闂傚�?�绀�?幖顐�?磹閸洖纾归柡宥呯仛鐎氾�??闂佽法鍠庨埀顒傚櫏濞兼劗绱掔€ｎ亶妯€闁糕斁鍋撳銈嗗笒鐎氼參鎮￠妷鈺傜厽闁哄�?��?�ч崯鐐烘煟韫囷絽娅嶉柡宀€鍠庨悾锟犲级閹稿巩鈺佄旈悩闈涗沪闁圭懓娲濠氬Ω閳哄�?�浜滈梺鍛婄☉閿曪附瀵奸崟顖涒拺鐟滅増甯╁Λ鎴烆殰椤忓棭妫漮nt/pc闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫮鈧懓�?�妯肩磽閹惧墎纾奸柣鎰靛墯缁跺弶銇勯敃鈧惔婊堝箯閿燂拷?闂佽法鍠撻弲顐︽偩椤掑嫭鈷戦柛娑橈攻鐏忣厾绱掓径濠勭Ш鐎殿噮鍋婇獮妯兼嫚閸欏妫熼梻渚€娼ч悧鍡椢涘Δ鍜佹晜闁割偅娲橀埛鎴︽偣閹帒濡奸柡瀣⒒缁辨帡宕掑鎵佹敪_flush
        .fb_pause({pause_o[2],pause_o[0]}),
        .fb_interrupt(1'b0),       
//        .fb_new_pc(32'b0),
        .new_pc(new_pc_from_ctrl),

        .BPU_flush(BPU_flush),
        .pi_pc(inst_addr),
        .BPU_pred_addr(BPU_pred_addr),
        .inst_rreq_to_icache(inst_rreq),
        .pi_is_exception(pi_is_exception),
        .pi_exception_cause(pi_exception_cause),

        // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬秮婵℃悂濡烽敂缁橈骏闂佽绻愮换鍫ュ礉閹达妇宓�?煫鍥ㄧ⊕閸嬵亝銇勯弽鐢靛埌婵炲牜鍨跺缁樻媴閼恒儳銆婇梺鍝ュУ閸旀瑥顕ｉ崨濠勭瘈婵﹩鍓涢鍡涙⒑濮瑰洤鈧�?�宕归柆宓ュ鈻庨幘绮规嫼闁荤姵浜介崝灞解枍閹扮増鏅搁柨鐕傛�???
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

        // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧�?�板楦裤亹閹烘繃顥栭梺绋跨箲閿曘垹顕ｉ锕€绠婚悹鍥皺椤︻參鏌ｉ悩杈劅闁绘挸鐗撳鍐测堪閸喓鍘垫俊鐐差儏妤犳悂宕㈤幘顔界厸濞达綀顫夊畷宀勬煙閾忣個顏堬綖濠靛纭€闁绘劕鐏氶濠氭⒒娴ｇ儤鍤€闁搞�?�鐗犻弫鎾绘晸閿燂拷?
        .fb_pred_taken1(fb_pred_taken1),
        .fb_pred_taken2(fb_pred_taken2),
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

        // from outer
        .is_hwi(intrpt),
        
        // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲倻鏆︽繝濠傚枤閸氬顭跨捄渚剱婵炲懌鍨藉娲川婵犲啫纾╁┑鐐差槹濞茬喖濡撮崒鐐存櫢闁跨噦鎷�?濡ょ姷鍋涚换姗€骞冨⿰鍫熷殟闁靛�?闄勯鐔兼⒒娴ｅ搫甯堕柣掳鍔岄～婵嬪Ω瑜岄悞濠囨煏婵炵偓娅呯紒鐙€鍨堕弫鎾绘晸閿燂�???
        .new_pc(new_pc_from_ctrl),
        .pc_i1(fb_pc1),
        .pc_i2(fb_pc2),
        .inst_i1(fb_inst1),
        .inst_i2(fb_inst2),
        .valid_i(fb_valid),
        .pre_is_branch_taken_i({fb_pred_taken1,fb_pred_taken2}),
        .pre_branch_addr_i1(fb_pre_branch_addr1),
        .pre_branch_addr_i2(fb_pre_branch_addr2),
        .is_exception1_i(fb_is_exception1),
        .is_exception2_i(fb_is_exception2),
        .pc_exception_cause1_i(fb_pc_exception_cause1),
        .pc_exception_cause2_i(fb_pc_exception_cause2),
        .instbuffer_exception_cause1_i(fb_instbuffer_exception_cause1),
        .instbuffer_exception_cause2_i(fb_instbuffer_exception_cause2),

        .bpu_flush(BPU_flush),   // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨跺娲垂椤曞懎鍓遍梺鍝勬缁矁鐏嬮梺鍝勵槸閻忔繈顢旈銏＄厸濞达綀顫夊畷宀€鈧鍣崜鐔镐繆閸洖骞㈡俊銈咃梗缁憋箓姊婚崒娆愮グ婵炲娲熷畷浼村箛閺夊灝鍤戞繝鐢靛У閼瑰墽绮婚鐐寸厽闁硅揪绲借闂佸搫鎳忛幃鍌炲蓟閿熺姴纾兼慨妤€鐗婄€氾拷?闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧�?�板楦裤亹閹烘繃顥栭梺绋跨箲閿曘垹顕ｉ锕€绠婚悹鍥у级椤ユ繈姊洪棃娑氬婵☆偅顨婇、鏃堝醇閺囩啿鎷洪柣鐘充航閸斿矂寮搁幋锔界厸閻庯綆浜堕悡鍏碱殽閻愯尙绠婚柟顔界矒閹崇偤濡烽敂绛嬩户闂傚�?�绀�?幖顐�?磹閸洖纾归柡宥呯仛鐎氾�??闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪棝鏌涚仦鍓р槈妞ゅ骏鎷�
    
        // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫭绻涢懠顒傚笡闁稿鍎甸弻锝夊閳轰胶浼囬梺鍝ュУ椤ㄦ劙骞忛敓锟�??闂佽法鍠曞Λ鍕�?�闁�?秴绠柣妯款嚙缁犵粯銇勯弮鍥撴繛鍛灲濮婃椽宕崟顐熷亾閸洖纾归柡宥呯仛鐎氾�??闂佽法鍠曞Λ鍕礊婵犲洤绠板┑鐘叉搐閸楁娊鏌曡箛濠傚⒉婵炲懌鍨藉铏规崉閵娿儲鐝㈤梺璺ㄥ櫐閹凤�??
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
        .csr_dmw0(csr_dmw0),
        .csr_dmw1(csr_dmw1),
        .csr_da(csr_da),
        .csr_pg(csr_pg),
        .csr_plv(csr_plv),

/*******************************
        .tlbidx(),
        .tlbehi(),
        .tlbelo0(),
        .tlbelo1(),
        .tlbelo1(),
        .asid(),
        .ecode(),

        .csr_datf(),
        .csr_datm(),
***********************************/

        // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪棝鏌涚仦鍓р槈妞ゅ骏鎷� dcache 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡灞诲€楅�?顒佺⊕钃遍柣銊﹀灴閹ǹ绠涚€ｎ亜顫囧Δ鐘靛仜缁绘﹢寮敓锟�??
        .ren_o(backend_dcache_ren),
        .wstrb_o(backend_dcache_wen),
        .virtual_addr_o(backend_dcache_addr),
        .wdata_o(backend_dcache_write_data),

        // dcache 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?€鍠栭獮鏍敇濠靛牊鏅兼俊鐐€х紞鍡涘闯閿濆宓�?煫鍥ㄧ⊕閸婂鏌ら幁鎺戝姕婵炲懌鍨藉娲偂鎼达絾鎲煎┑顔角滈崝搴㈢閹间礁惟闁宠桨鑳堕鍡涙煥閻曞倹�?��??
        .rdata_i(dcache_rdata),
        .rdata_valid_i(dcache_backend_rdata_valid),
        .dcache_pause_i(~dcache_ready),

        // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨崇槐鎺斾沪缁涘鍋撻埀鐟€l闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧�?�板楦裤亹閹烘繃顥栭梺鍝勮嫰椤︻垵鐏嬮梺鍝勫暙閻楀﹪宕戠€ｎ偆绠鹃柟�?�樼懃閻忣亪鏌￠崨顔藉€愰柡灞诲姂閹�?�宕掑☉姗嗕�?8婵犵數鍋犻幓顏嗗緤閻ｅ瞼鐭撶憸鐗堝笒閺嬩線鏌熼幑鎰靛殭婵☆偅锕㈤弻鏇㈠醇濠靛浂妫為梺璺ㄥ櫐閹凤拷?
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

    wire icache_ren_received;
    wire dcache_ren_received;
    wire icache_flush_flag_valid;

    icache u_icache
    (
        .clk(aclk),
        .rst(rst),   
        .flush(flush_o[1]),       
    // Interface to CPU
        .inst_rreq(inst_rreq),  // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠撻弲顐︻敄�?�ゆ紛闂傚�?�鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨抽�?顒傛�?鐎氼厼顭垮Ο鐓庣筏闁秆勵殕閻撴瑧绱掔€ｎ偄顕滈柛鐘筹�?�閺屸剝鎷呯憴鍕３閻庢鍣�?崜鐔镐繆閸洖骞㈡俊銈咃梗缁憋箓姊婚崒娆愮グ婵炲娲熷畷浼村箛閺夊灝鍤戞繝鐢靛У閼瑰墽绮婚鐐存櫢闁跨噦鎷�???
        .inst_addr(inst_addr),      // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠撻弲顐︻敄�?�ゆ紛闂傚�?�鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨抽�?顒傛�?鐎氼厼顭垮Ο鐓庣筏闁秆勵殕閻撴瑧绱掔€ｎ偄顕滈柛鐘筹�?�閺屸剝鎷呯憴鍕３閻庢鍣�?崜鐔镐繆閸洖骞㈡俊銈咃梗缁憋箓姊绘笟鈧�?濠氬箯閿燂�??闂佽法鍣﹂幏锟�?
        .BPU_pred_addr(BPU_pred_addr),
        .BPU_pred_taken(BPU_pred_taken),

        .pi_is_exception(pi_is_exception),
        .pi_exception_cause(pi_exception_cause),

        .pred_addr(pred_addr_for_buffer),
        .pred_taken(pred_taken_for_buffer),
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
        .dev_rdata(icache_rdata),
        .ren_received(icache_ren_received),
        .flush_flag_valid(icache_flush_flag_valid)   
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

    wire [3:0] duncache_wstrb;

    dcache u_dcache(
        .clk(aclk),
        .rst(rst),

        // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬秮婵℃悂濡烽敂缁橈骏闂佽绻愮换鍫ュ礉閹达妇宓�?煫鍥ㄧ⊕閸嬵亝銇勯弽鐢靛埌婵炲牜鍨跺缁樻媴閼恒儳銆婇梺鍝ュУ閸旀瑥顕ｉ崨濠勭瘈婵﹩鍓涢鍡涙⒑濮瑰洤鈧�?�宕归柆宓ュ鈻庨幘绮规嫼闁荤姵浜介崝灞解枍閹扮増鏅搁柨鐕傛�???
        .ren(backend_dcache_ren),
        .wen(backend_dcache_wen),
        .vaddr(backend_dcache_addr),
        .write_data(backend_dcache_write_data),

        // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧�?�板楦裤亹閹烘繃顥栭梺绋跨箲閿曘垹顕ｉ锕€绠婚悹鍥皺椤︻參鏌ｉ悩杈劅闁绘挸鐗撳鍐测堪閸喓鍘垫俊鐐差儏妤犳悂宕㈤幘顔界厸濞达綀顫夊畷宀勬煙閾忣個顏堬綖濠靛纭€闁绘劕鐏氶濠氭⒒娴ｇ儤鍤€闁搞�?�鐗犻弫鎾绘晸閿燂拷?
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
        .ren_received(dcache_ren_received),
    //duncache to cache_axi
        .uncache_rvalid(duncache_rvalid),
        .uncache_rdata(duncache_rdata),
        .uncache_ren(duncache_ren),
        .uncache_raddr(duncache_raddr),

        //trans_addr to dcache
        .ret_data_paddr(ret_data_paddr),

        .uncache_write_finish(duncache_write_finish),
        .uncache_wen(duncache_wen),
        .uncache_wstrb(duncache_wstrb),
        .uncache_wdata(duncache_wdata),
        .uncache_waddr(duncache_waddr)  
    );
        
    addr_trans u_addr_trans(
        .clk(aclk),
        .rst(rst),
        .data_vaddr(backend_dcache_addr),
        .csr_da(csr_da),
        .csr_pg(csr_pg),
        .csr_dmw0(csr_dmw0),
        .csr_dmw1(csr_dmw1),
        .csr_plv(csr_plv),
        .ret_data_paddr(ret_data_paddr)
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
    //R闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧�?�板娲偡閺夋寧顔€闂佽法鍣﹂幏锟�??
        .rid(rid),
        .rdata(rdata),   
        .rresp(rresp),    
        .rlast(rlast),           
        .rvalid(rvalid),       
        .rready(rready),
        .rdata_o(axi_rdata),
        .rdata_valid_o(axi_rdata_valid),         
    //AW闂傚倷绀�?幉锟犲礉閺嶎厽鍋￠柍鍝勬噹閺嬩線鏌熼幑鎰靛殭婵☆偅锕㈤弻鏇㈠醇濠靛浂妫炲銈呯箰閻栧ジ寮诲☉婊庢Х闂佽法鍣﹂幏锟�?
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
    //W闂傚倷绀�?幉锟犲礉閺嶎厽鍋￠柍鍝勬噹閺嬩線鏌熼幑鎰靛殭婵☆偅锕㈤弻鏇㈠醇濠靛浂妫炲銈呯箰閻栫厧顫忛搹瑙勫磯闁靛ǹ鍎查悗楣冩⒑閸濆嫷鍎忔い顓犲厴閻涱喛绠涘☉娆愭�??
        .wid(wid),     
        .wdata(wdata),  
        .wstrb(wstrb),    
        .wlast(wlast),          
        .wvalid(wvalid),       
        .wready(wready),         
    //闂傚倷绀�?幉锟犲礉閺嶎厽鍋￠柍鍝勬噹閺嬩線鏌熼幑鎰靛殭婵☆偅锕㈤弻鏇㈠醇濠靛浂妫炲銈呯箰閻栧ジ鐛�?弽銊︾秶闁绘劦鍓欓锟�
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
        .icache_ren_received(icache_ren_received),
        .icache_flush_flag_valid(icache_flush_flag_valid),

    //dcache read
        .data_ren_i(dcache_ren),
        .data_araddr_i(dcache_araddr),
        .data_rvalid_o(dcache_rvalid),
        .data_rdata_o(dcache_axi_data_block),
        .dcache_ren_received(dcache_ren_received),

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
        .duncache_wstrb(duncache_wstrb),
        .duncache_wdata_i(duncache_wdata),
        .duncache_waddr_i(duncache_waddr),
        .duncache_write_resp(duncache_write_finish),

    //AXI communicate
        .axi_ce_o(axi_ce_o),
        .axi_wsel_o(axi_wsel),   // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡�?嬬節瀹曟帒顫滈崼鐔奉�??闂佽法鍠愰弸濠氬箯閿燂拷?闂佽法鍠曞Λ鍕礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧�?�板楦裤亹閹烘繃顥栭梺绋跨箲閿曘垹顕ｉ锕€绠婚柛鎾茬�?�曘儱顪冮妶鍡樺暗濠殿垼鍙冨鍐测堪閸喓鍘垫俊鐐差儏鐎垫帡鎮㈤崡绫簉b

    //AXI read
        .rdata_i(axi_rdata),
        .rdata_valid_i(axi_rdata_valid),
        .axi_ren_o(axi_ren),
        .axi_rready_o(axi_rready),
        .axi_raddr_o(axi_raddr),
        .axi_rlen_o(axi_rlen),

    //AXI write
        .wdata_resp_i(axi_wdata_resp),  // 闂傚倷绀�?幉锟犲礉閺嶎厽鍋￠柍鍝勬噹閺嬩線鏌熼幑鎰靛殭婵☆偅锕㈤弻鏇㈠醇濠靛浂妫炲銈呯箰閻栧ジ鐛�?弽顐熷亾濞戞鎴λ夐崼銉︾厸濞达綀顫夊畷宀勬煙閾忣個顏堬綖濠靛纭€闁绘劕鐏氶濠氭⒒娴ｇ儤鍤€闁搞�?�鐗犻弫鎾绘晸閿燂拷?
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

/*********************************************
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
***********************************************/


    assign debug0_wb_pc = debug_data_out[31:0];  
    assign debug0_wb_rf_wen = {4{debug_data_out[101]}};
    assign debug0_wb_rf_wnum = debug_data_out[100:96];
    assign debug0_wb_rf_wdata = debug_data_out[95:64];

endmodule