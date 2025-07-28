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
    output wire [31:0] debug_wb_rf_wdata

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

    //icache  闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垳鈧懓瀚姗€路閸涘瓨鈷戦悹鎭掑妼閺嬫垿鏌＄€ｎ亶鐓兼鐐茬箻閺屻劎鈧絽妫旂欢姘跺蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊洪崷顓炲幋闁衡偓闁秴鍌ㄩ梺顒€绉甸悡銉╂煟閺傛寧鍟為柣蹇ｅ櫍閺岀喐顦版惔鈥冲箣闂佽桨鐒﹂幑鍥ь嚕椤掑嫬围闁糕剝顨忔导鎾绘⒑閼恒儔鎴澝洪悢鐓庢瀬闁瑰墽绮弲鎼佹晸閿燂拷??**********************
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


    // 闂備礁鎲￠幐鍝ョ矓瑜版帒鏋侀柟鎹愵嚙缁€鍫ユ煕瑜庨〃鍡樼閵堝鐓欏瀣閸樻挳鏌℃担瑙勫磳鐎殿噮鍓熸俊鍫曞幢濡ゅ﹣绱﹂梺鑽ゅТ濞诧箓骞愰幎钘夋瀬闁规崘顕уΛ姗€鏌曢崼婵囶棞妞ゅ繐鐖奸弻锕€螣缂佹顦伴梺杞扮劍閹瑰洭寮幘缁樻櫢?
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

    // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垰顪冪€ｎ亪顎楅柛鎾卞姂濮婅櫣鎹勯妸銉︾亞濡炪値鍋呴〃鍫ュ极椤曗偓椤㈡瑩鎸婃径妯圭处闂佽崵濮村ú锕傚箰閹惰棄鏋侀柟鎹愵嚙濡﹢鏌曢崼婵囶棞妞ゅ繐鐖奸弻锕€螣缂佹顦伴梺杞扮劍閹瑰洭寮幘缁樻櫢?
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

    // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垰顪冪€ｎ亪顎楅柛鎾卞姂濮婅櫣鎹勯妸銉︾彚闁跨噦鎷�?? dcache 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺屻倗鈧稒蓱閻ㄦ垿鎮樿箛瀣妤犵偛绻橀弫锟�?
    wire  backend_dcache_ren;
    wire [3:0]  backend_dcache_wen;
    wire [31:0] backend_dcache_addr;
    wire [31:0] backend_dcache_write_data;

    // dcache 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喕妫勫﹢閬嶅箯閻樿绠绘い鏃囧Г濞呫垽姊洪崫鍕偓鍫曞磹閺嶅灚瀚�?闁跨喕妫勭紞濠囧箰婵犲洤鍗抽柕蹇婂墲濞呫垽姊虹捄銊ユ珢闁跨噦鎷�?
    wire [31:0] dcache_backend_rdata;
    wire dcache_backend_rdata_valid;
    wire dcache_ready;

    // dcache-AXI 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�??? cache 闂傚倷娴囧▔鏇㈠窗閹邦喗鏆滈柟缁㈠枛缁€宀勬煃閳轰礁鏆欐い蹇撶埣濮婅櫣鎹勯妸銉︾亞闂佸憡鎸搁妶鎼佸箖椤曞棙瀚�?闁跨喕濮ら敋闁跨噦鎷�?
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

    //鍚庣鐨刢sr杈撳叆缁檛rans_addr鐨勪俊鍙�
    wire [31:0] csr_dmw0;//dmw0锛屾湁鏁堜綅鏄痆27:25]锛屽彲鑳戒細浣滀负鏈€鍚庤浆鎹㈠嚭鏉ョ殑鍦板潃鐨勬渶楂樹笁浣�
    wire [31:0] csr_dmw1;//dmw1锛屾湁鏁堜綅鏄痆27:25]锛屽彲鑳戒細浣滀负鏈€鍚庤浆鎹㈠嚭鏉ョ殑鍦板潃鐨勬渶楂樹笁浣�
    wire        csr_da;
    wire        csr_pg;
    wire [1:0]  csr_plv;

    //trans_addr to dcache
    wire [31:0] ret_data_paddr;
    front u_front
    (
        // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�???
        .cpu_clk(aclk),
        .cpu_rst(rst),

        .iuncache(iuncache),//闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垰顪冪€ｎ亝鎹ｉ柨鐕傛嫹?闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺屻倗鈧稒蓱閻ㄦ垿鎮樿箛瀣妤犵偛绻橀幃婊堟嚍閵夛附顏熼梻浣告惈閸婂爼宕愰弽鍨?闁跨喓鏅幊鎾诲煘閸愵喗鏅�?       //(闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛憸缁辨帡鎳犻鈧悘濉禼ache闂傚倷娴囧▔鏇㈠窗閺囥垹绀堝┑鍌氭啞閸嬫牠鎮楀☉娅亪鏁撻敓锟�?)

        // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�??? icache 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺屻倗鈧稒蓱閻ㄦ垿鎮樿箛瀣妤犵偛绻橀弫锟�?
        .pred_taken(BPU_pred_taken),
        .pi_icache_is_exception1(pi_icache_is_exception1),      //闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垳绱掔仦鎯ь瀴ache闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊鸿ぐ鎺濇闁稿繑锕㈠顐﹀箻鐠囧弶顥濋梺闈涚墕濡顢旈崼鏇熲拺閻犳亽鍔岄弸鎴︽煛鐎ｎ亶鐓兼鐐茬箻閹粓鎳為妷锔筋仧闂備礁鎼崐鍫曞磹閺嶅灚瀚�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊洪崷顓炲幋闁衡偓鏉堛劌顕�?
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
        .fb_flush({flush_o[2],flush_o[0]}), //闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊鸿ぐ鎺濇闁稿繑锕㈠顐﹀箻鐠囧弶顥濋梺闈涚墕濡顢旈崼鏇熲拺閻犳亽鍔岄弸娆忊攽閻愬弶鍠樻い銏℃⒐閹棃濮€閻欌偓娴兼捇姊绘担鑺ョ《闁哥姵娲熼妴浣糕堪閸℃瑦鐦旈梻渚€娼ч悧鍡欐崲閹搭垱瀚�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊鸿ぐ鎺濇闁稿繑锕㈠顐﹀箻閼搁潧鏆遍梺缁樻礀閸婅崵绮堟径宀€妫柡澶嬵儥濡插綊鎮楀顒傜Ш闁哄被鍔戦幃銏ゅ礂閸忕厧娅濋梻浣虹帛閼归箖鎮洪…鎺撳?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊鸿ぐ鎺濇闁稿繑锕㈠顐﹀箻閼搁潧鏋傞梺鍦劋閸ㄧ數鑺辨繝姘厵闁绘垼濮ら弫閬嶆晸閿燂拷?闁规壆澧楅悡銉╂煟閺傛寧鍟為柣蹇ｅ櫍閺岀喎鐣￠弶鎸幮╂繛鏉戝悑濡啴寮婚妸鈺傚亜闁惧繗顕栧ú绨倁sh闂傚倷娴囧▔鏇㈠窗閺囥垹绀堝┑鍌溓归惌妤呮煕閹存瑥鈧绮旈崼鏇熺厵濡炲楠搁崢鎾煛娴ｈ灏甸柟鍙夋尦楠炴帒螖娴ｉ攱鍞夐梻浣哥秺椤ユ捇宕楀鈧顐﹀箻缂佹ê娈楀┑顔斤供閸撴瑦绻涢崶顒佺厱闁哄秲鍊曟晶鏌ユ倵濮橆剛绉洪柡灞诲姂閹垽宕ㄦ繝鍕磿闂備胶鎳撻崲鏌ュ床閺屻儱鍨傜憸鐗堝笒閸屻劌鈹戦悩宕囶暡闁哄懏鎮傞弻锟犲磼濮楀牊瀚�?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠傜暦濠婂喚鍚嬪璺侯儐濞呫垽姊洪崨濠冨磩婵炲娲熼妴鍌炴晸閿燂拷?妤犵偛绻掔划姘繆瀵牠姊绘担鑺ョ《闁哥姵鍔欏鍛婄節濮橆剛顔嗛梺缁樺灱婵倝寮查幖浣圭厸闁稿本锕幏锟�?闁跨喐鏋婚幏锟�?闁跨喕妫勫﹢閬嶆儉椤忓牊鐒肩€广儱妫欏▍銏ゆ⒑閸濆嫬鈧爼宕愰弽鍨?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊洪悷鏉挎Щ闁搞垺褰冮悾浣冪疀濞戞瑦鍎俊銈忕到閸燁垶寮查崫銉х＜闁告瑥顦ⅲush闂傚倷娴囧▔鏇㈠窗閺囥垹绀堝┑鍌溓归惌妤€顪冪€ｎ亜鐦ㄩ柡鍡樼矒閺岀喐顦版惔鈥冲箣闂佽桨鐒﹂幑鍥ь嚕椤掑嫬围闁糕剝顨忔导鎾绘⒒娴ｈ姤纭堕柛鐘虫崌瀹曪繝骞庨懞銉︽珳闂婎偄娲﹂弻銊╊敂閸洘鈷戦悹鎭掑妼閺嬫垿鏌＄€ｎ亶鐓兼鐐茬箻閹粓鎳為妷锔筋仧闂備礁鎼崐鍫曞磹閺嶅灚瀚�?闁跨喎鈧噥娼愮紒瀣樀閸┾偓妞ゆ帒瀚悡銉╂煟閺傛寧鍟為柣蹇ｅ櫍閺岀喎鐣￠弶鎸幮╁Δ鐘靛仦閹瑰洭寮婚妸鈺傚亜闁告稑锕︽导鍕⒑瑜版帩妫戞顏嗩棝ont/pc闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勭€瑰嫭婢樼紓鎾剁磼閻愵剚绶叉い锕€搴滈幏锟�?闁跨喓鏅悾顒勬⒑閸涘﹥灏紒澶婄秺瀵偊骞樼拠鍙夘棟闂侀潧鐗嗗Λ妤咁敂閸洘鈷戦悹鎭掑妼閺嬫梻绱掗崒姘扁攭_flush
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

        // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋綁濡搁妷锔绘￥闁诲繐绻堥崝鎴︾嵁韫囨稒鍋い鏍电到濞堫垶姊绘担鑺ョ《闁哥姵鍔欏鍛婄節濮橆剛顔嗛梺姹囧€ら崹閬嵥夊▎鎾粹拺閻犳亽鍔屽▍鎰版晸閿燂拷??
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

        // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊鸿ぐ鎺濇闁稿繑锕㈠顐﹀箻鐠囪尙顦柣鐘辫閻撳牓寮冲⿰鍫熺厵濡炲楠搁崢鎾煛娴ｈ宕岄柟铏～婵嬪础閻愬灚顓婚梻浣烘嚀閸ゆ牠鏁撻敓锟�?
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
        .is_hwi(ext_int),
        
        // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠傜暦濠婂喚鍚嬪璺侯儐濞呫垽姊洪崨濠冨磩婵炲娲熼妴鍌炴晸閿燂拷?妤犵偛绻橀幃婊堟嚍閵夛附顏熼梻浣哄帶閻°劌顫濋妸褌鐒婇柕濞炬櫅缁狀垶鏁撻敓锟�??
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

        .bpu_flush(BPU_flush),   // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶姊洪崹顕呭剱闁哄棙绮岃灋闁哄鐏濋顓㈡煛娴ｈ宕岀€殿噮鍓熸俊鍫曞幢濡ゅ﹣绱﹂梻鍌欐祰濞夋洟宕伴幇鏉垮嚑濠电姵鑹剧粻顖炴煟閹达絽袚闁哄懏鎮傞弻锟犲磼濮楀牊瀚�?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊鸿ぐ鎺濇闁稿繑锕㈠顐﹀箻鐠囧弶顥濋梺闈涚墕濡顢旈崼鏇熲拺閻犳亽鍔岄弸鎴︽煛鐎ｎ亶鐓兼鐐茬箻閹粓鎳為妷锔筋仧闂備礁鎼崐鍫曞磹閺嶅灚瀚�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋嗛柛灞剧☉椤忥拷
    
        // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勬繛鑼帛閸嬨儵鏌ｉ姀鈺佺伇闁哥姵顨愰幏锟�?闁跨喕妫勫﹢閬嶅箯閻樿绠绘い鏃囧Г濞呫垽姊洪崫鍕偓鍫曞磹閺嶅灚瀚�?闁跨喕妫勭紞濠囧箰婵犲洤鍗抽柕蹇婂墲濞呫垽姊虹捄銊ユ珢闁跨噦鎷�?
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

        // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋嗛柛灞剧☉椤忥拷 dcache 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺屻倗鈧稒蓱閻ㄦ垿鎮樿箛瀣妤犵偛绻橀弫锟�?
        .ren_o(backend_dcache_ren),
        .wstrb_o(backend_dcache_wen),
        .virtual_addr_o(backend_dcache_addr),
        .wdata_o(backend_dcache_write_data),

        // dcache 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岀喖骞栭婵堟晼濡炪倧缍嗛崳锝夌嵁韫囨稒鍊婚柤鎭掑劜濞呫垽姊洪悡搴ｆ憼婵ǜ鍔庢禍鎼佸Ω閳轰胶顔嗛柨鐕傛嫹??
        .rdata_i(dcache_rdata),
        .rdata_valid_i(dcache_backend_rdata_valid),
        .dcache_pause_i(~dcache_ready),

        // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垳绱掔仦绛嬧偓鈧瑀l闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊鸿ぐ鎺濇闁哄苯顦灋闁哄啫鐗婇崑瀣箾閹存瑥鐏柡鍛倐閺屻劑鎮ら崒娑橆伓8濠电偠鎻徊鐣岀矓瑜版帒鏋侀柟鎹愵嚙濡﹢鏌曢崼婵囶棞闁跨噦鎷�?
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
        .inst_rreq(inst_rreq),  // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喓鏅寤漊闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垳鈧懓瀚妯煎緤閸ф鐓欑紒瀣閸犳﹢鏌℃担瑙勫磳鐎殿噮鍓熸俊鍫曞幢濡ゅ﹣绱﹂梻鍌欐祰濞夋洟宕伴幇鏉垮嚑濠电姵鑹剧粻顖炴晸閿燂拷??
        .inst_addr(inst_addr),      // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喓鏅寤漊闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垳鈧懓瀚妯煎緤閸ф鐓欑紒瀣閸犳﹢鏌℃担瑙勫磳鐎殿噮鍓熸俊鍫曞幢濡ゅ﹣绱﹂梻渚€娼婚幏锟�?闁跨噦鎷�?
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

        // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋綁濡搁妷锔绘￥闁诲繐绻堥崝鎴︾嵁韫囨稒鍋い鏍电到濞堫垶姊绘担鑺ョ《闁哥姵鍔欏鍛婄節濮橆剛顔嗛梺姹囧€ら崹閬嵥夊▎鎾粹拺閻犳亽鍔屽▍鎰版晸閿燂拷??
        .ren(backend_dcache_ren),
        .wen(backend_dcache_wen),
        .vaddr(backend_dcache_addr),
        .write_data(backend_dcache_write_data),

        // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊鸿ぐ鎺濇闁稿繑锕㈠顐﹀箻鐠囪尙顦柣鐘辫閻撳牓寮冲⿰鍫熺厵濡炲楠搁崢鎾煛娴ｈ宕岄柟铏～婵嬪础閻愬灚顓婚梻浣烘嚀閸ゆ牠鏁撻敓锟�?
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
    //R闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊洪悷鏉挎闁跨噦鎷�?
        .rid(rid),
        .rdata(rdata),   
        .rresp(rresp),    
        .rlast(rlast),           
        .rvalid(rvalid),       
        .rready(rready),
        .rdata_o(axi_rdata),
        .rdata_valid_o(axi_rdata_valid),         
    //AW闂備礁鎲￠崝鏍偡閳哄懎鏋侀柟鎹愵嚙濡﹢鏌曢崼婵囶棞妞ゅ繐鐖奸弻娑滎槷闁跨噦鎷�?
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
    //W闂備礁鎲￠崝鏍偡閳哄懎鏋侀柟鎹愵嚙濡﹢鏌曢崼婵囶棞妞ゅ繐鐖煎铏规崉閵娿儲鐎鹃梺鍝勵儏椤兘鐛箛娑欐櫢?
        .wid(wid),     
        .wdata(wdata),  
        .wstrb(wstrb),    
        .wlast(wlast),          
        .wvalid(wvalid),       
        .wready(wready),         
    //闂備礁鎲￠崝鏍偡閳哄懎鏋侀柟鎹愵嚙濡﹢鏌曢崼婵囶棞妞ゅ繐鐖奸獮鏍ㄦ綇閻愵剙顏�
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
        .axi_wsel_o(axi_wsel),   // 闂傚倷娴囧▔鏇㈠窗閹版澘鍑犲┑鐘宠壘缁狀垶鏌ｉ幋锝呅撻柡鍛倐閺岋繝宕掑鍫熷?闁跨喐鏋婚幏锟�?闁跨喕妫勭紞濠囧蓟閵娾晜鍋勯柛娑橈功娴煎嫰姊鸿ぐ鎺濇闁稿繑锕㈠顐﹀箻閸撲礁宕ュ銈嗘尵婵參寮冲⿰鍫熺厵濡炲瀵掗悢鍗籺rb

    //AXI read
        .rdata_i(axi_rdata),
        .rdata_valid_i(axi_rdata_valid),
        .axi_ren_o(axi_ren),
        .axi_rready_o(axi_rready),
        .axi_raddr_o(axi_raddr),
        .axi_rlen_o(axi_rlen),

    //AXI write
        .wdata_resp_i(axi_wdata_resp),  // 闂備礁鎲￠崝鏍偡閳哄懎鏋侀柟鎹愵嚙濡﹢鏌曢崼婵囶棞妞ゅ繐鐖奸獮鏍偓娑櫳戦ˉ鍫ユ煛娴ｈ宕岄柟铏～婵嬪础閻愬灚顓婚梻浣烘嚀閸ゆ牠鏁撻敓锟�?
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

endmodule