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
    output reg rdata_valid,    // 闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤悜妯恍歅U闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟煛娴ｅ摜澧﹂柡浣规崌閹虫ê顫濋鈧繛鍥煥濠靛棛绠查悗姘秺閺屻劑鎮㈡笟顖欑棯缂佺偓婢橀ˇ鎵偓姘秺閻涱噣骞庨懞銉︽闂佸搫鍊堕崐鏍偓姘贡缁牏寮ф繝顧he闂備浇娉曢崰鎰板几婵犳艾绠€瑰嫭婢樺▍娆撴⒑鐠恒劌鏋戦柡瀣煼楠炲繘鎮滈懞銉︽闂佸搫鍊堕崐鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇茬闁告垯鍊楃粔鍫曟煙閸戙倖瀚�
    output wire dcache_ready,   
    //to write BUS
    input  wire         dev_wrdy,       // 闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮ら崒娑橆伓/闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈠畡鏉跨紦闁哄鐗忛崑鎾垛偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟煢濡粯绀堝褌鍗抽弻銊╂偄閸涘﹦浼勯梺鐟板槻閸㈣尪銇愰妷鈺傜叆闁绘柨鎼悵閬嶆煛閸屾ê鈧牜鈧艾缍婇弻銊╂偄閾忕懓鎽甸梺瑙勫劤閹冲繒鈧艾缍婇弻銊╂偄閸涘﹦浼勯梺褰掝棑閸忔﹢寮幘缁樻櫢闁跨噦鎷�/闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘贡娴狅箓鏌嗗鍡樻闂佸搫鍊堕崐鏍偓姘秺閺屻劑鎮㈤悜妯镐户Cache闂備浇娉曢崰鎰板几婵犳艾绠€瑰嫭婢橀弲鎼佹⒑鐠恒劌鏋戦柡瀣煼楠炲繘鎮滈懞銉︽闂佸搫鍊堕崐鏍偓姘炬嫹
    input  wire         write_finish,
    output reg  [ 3:0]  cpu_wen,        // 闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟⒑鐠恒劌娅愰柟鍑ゆ嫹/闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈠畡鏉跨紦闁荤姴娲ょ粔璺衡枍閵忋倕绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閹稿﹪寮撮姀鈩冩闂佽法鍣﹂幏锟�
    output reg  [31:0]  cpu_waddr,      // 闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟⒑鐠恒劌娅愰柟鍑ゆ嫹/闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈠畡鏉跨紦闁哄鐗忛崑鎾垛偓姘秺閺屻劑鎮㈠ú缁樻櫗闂佽法鍣﹂幏锟�
    output reg  [127:0]  cpu_wdata,      // 闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟⒑鐠恒劌娅愰柟鍑ゆ嫹/闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈠畡鏉跨紦闁哄鐗忛崑鎾垛偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘缁樻櫢闁跨噦鎷�
    //to Read Bus
    input  wire         dev_rrdy,       // 闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘炬嫹/闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘愁潐缁傚秹鍩￠崨顔芥闂佸搫鍊堕崐鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟煢濡粯绀堝褌鍗抽弻銊╂偄閸涘﹦浼勯梺鐟板槻閸㈣尪銇愰妷鈺傜叆闁绘柨鎼悵閬嶆煛閸屾ê鈧牜鈧艾缍婇弻銊╂偄閾忕懓鎽甸梺瑙勫劤閹冲繒鈧艾缍婇弻銊╂偄閸涘﹦浼勯梺褰掝棑閸忔﹢寮幘缁樻櫢闁跨噦鎷�/闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘贡娴狅箓鏌嗗鍡樻闂佸搫鍊堕崐鏍偓姘秺閺屻劑鎮㈤悜妯镐户Cache闂備浇娉曢崰宥夋嚑鎼达絾濯奸悷娆忓椤忓爼姊虹捄銊ユ瀾闁哄顭烽獮蹇涙倻閼恒儲娅㈤梺鍝勫€堕崐鏍偓姘炬嫹
    output reg          cpu_ren,        // 闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟⒑鐠恒劌娅愰柟鍑ゆ嫹/闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘愁潐缁傚秹鍩￠崨顔芥缂傚倷鑳堕崑鐔封枍閵忋倕绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閹稿﹪寮撮姀鈩冩闂佽法鍣﹂幏锟�
    output reg  [31:0]  cpu_raddr,      // 闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟⒑鐠恒劌娅愰柟鍑ゆ嫹/闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘愁潐缁傚秹鍩￠崨顔芥闂佸搫鍊堕崐鏍偓姘秺閺屻劑鎮㈠ú缁樻櫗闂佽法鍣﹂幏锟�
    input  wire         dev_rvalid,     // 闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅锟�/闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟⒑鐠恒劌鏋戦柡瀣煼楠炲繘鎮滈懞銉︽闂佸憡鐟崐銈咁吋閸℃浼撻梺鑺ド戝ú鐔煎极閹剧粯鏅搁柨鐕傛嫹
    input  wire [127:0] dev_rdata,       // 闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅锟�/闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘愁潐缁傚秹鍩￠崨顔芥闂佸搫鍊堕崐鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘缁樻櫢闁跨噦鎷�
    input  wire         ren_received,

    input wire [31:0] ret_data_paddr,//////////////////////////////////////////

    input wire uncache_rvalid,
    input wire [31:0] uncache_rdata,
    output wire uncache_ren,
    output wire [31:0] uncache_raddr,

    input wire uncache_write_finish,
    output wire uncache_wen,   
    output wire [3:0] uncache_wstrb,
    output wire [31:0] uncache_wdata,
    output wire [31:0] uncache_waddr
);


    localparam IDLE = 3'b000;
    localparam ASKMEM = 3'b001;
    localparam DIRTY_WRITE = 3'b010;
    localparam RETURN = 3'b011;
    localparam REFILL = 3'b100;   //闂佸憡鍔栭悷鈺呭极閹捐妫橀柕鍫濇椤忓爼姊虹捄銊ユ瀾闁哄顭烽獮蹇涙倻閼恒儲娅㈤梺鍦嚀閸㈡彃顭囬敓鐘虫櫖鐎光偓閸曨剚娅㈤梺鍝勫€堕崐鏍偓姘愁潐缁嬪鍩€椤掑嫭鐓ラ柣鏂挎啞閻忣噣鏌熸搴樺嫎lk闂備浇娉曢崰搴㈡叏椤撶喐缍囬柣鎰靛墮椤忓爼鏌涢幇顓犲祦rite_data
    localparam UNCACHE = 3'b101;
    
    reg [2:0] state;
    reg [2:0] next_state;
    reg [1:0] dirty [7:0];
    reg [1:0] use_bit [7:0];  //2'b10闂備浇娉曢崰宥夋嚑鎼达絽鏋堝璺侯儏椤忚泛鈽夐幘顖氫壕闂備浇娉曢崰鎰板几婵犳艾绠柨鐕傛嫹
    
    wire [31:0] vaddr_1 = vaddr;      
    wire [2:0] index_1;
    //闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮ら崒娑橆伓2闂備浇娉曢崰鎰板几婵犳艾绠瀣昂娴犳盯姊虹捄銊ユ瀾闁哄顭烽獮蹇涙倻閼恒儲娅㈤梺鍝勫€堕崐鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟⒑鐠恒劌鏋旂紒顔芥倐楠炲鈧綆鍋勯鍫曟⒑鐠恒劌鏋戠憸閭﹀枟鐎电厧鈻庨幇顒変紦闂備浇娉曢崰鎾剁矉婵
    reg [2:0] index_2;
    reg [31:0] w_data_2;
    reg [3:0] wen_2;
    reg ren_2;
    reg uncache_2;

    wire [127:0] data_block1;  
    wire [127:0] data_block2;  
    wire [25:0] ram_tag1;
    wire [25:0] ram_tag2;
    wire [1:0] offset_2 = ret_data_paddr[3:2];
    wire [24:0] tag_2 = ret_data_paddr[31:7];
    wire is_load = ren_2;
    wire is_store = |wen_2;
    wire req_2 = is_load | is_store;
    wire hit1 = req_2 & (tag_2 == ram_tag1[24:0]) & ram_tag1[25];
    wire hit2 = req_2 & (tag_2 == ram_tag2[24:0]) & ram_tag2[25];
    wire hit = hit1 | hit2;
    wire dirty_index = use_bit[index_2] != 2'b10;
    wire [127:0] hit_data = {128{hit1}}&data_block1 | {128{hit2}}&data_block2;//
  
    wire write_dirty = !hit & req_2 & dirty[index_2][dirty_index];
    wire ask_mem = !hit & req_2 & !dirty[index_2][dirty_index];
    wire read_index_choose = next_state == IDLE;
    
    reg [127:0] attach_write_data;  //闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘贡閹茬増鎷呯粙鎸庢闂備浇娉曢崰鎰板几婵犳艾绠紒灞剧m闂備浇娉曢崰鎰板几婵犳艾绠梺鍨儏椤忓姊虹捄銊ユ瀾闁哄顭烽獮蹇涙倻閼恒儲娅㈤梺鍝勫€堕崐鏍偓姘秺瀹曟帗绻濆顓熸闂佸搫鍊堕崐鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻弻澶庛亹婢舵劖鐓ラ柣鏇炲€圭€氾拷
    reg [15:0] we1_choose;   //闂備浇娉曢崰鎰板几婵犳艾绠€瑰嫭婢橀弲绋棵归敐鍛仴闁轰焦鎹囧顒勫Χ閸℃浼撻梻浣芥硶閸犳劙寮告繝姘闁绘垼濮ら弲鎼佹偣閸ヨ泛浜剧紒杈ㄧ箖缁嬪鍩€椤掍焦濯寸€广儱顦伴弲鎼佹煛閸屾ê鈧牜鈧艾缍婇弻銊╂偄閸涘﹦浼勯梺鍦焿濞撳湱绮╅幘顔界叆闁绘柨鎲￠悘顕€鏌熸搴″幋闁轰焦鎸鹃幃鏉课旈崟顐嬫繄鐥弶娆炬Ч閻庢艾缍婂畷妯衡枎閹惧瓨娅㈤梺鍝勫€堕崐鏍偓姘炬嫹
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
    
    assign index_1 = read_index_choose ? vaddr_1[6:4] : index_2;
    wire [127:0] write_ram_data = dev_rvalid ? dev_rdata : attach_write_data;
    wire [25:0] write_ram_tag = {1'b1,tag_2};

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
            if(!write_dirty) next_state = ASKMEM;  //闂備浇娉曢崰宥夋嚑鎼达絿椹抽悷娆忓椤忕ev_wrdy?
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
            w_data_2 <= 32'b0;
            wen_2 <= 4'b0;
            ren_2 <= 1'b0;
            index_2 <= 3'b0;
            cpu_wen <= 4'b0;
            cpu_ren <= 1'b0;
            cpu_waddr <= 32'b0;
            cpu_raddr <= 32'b0;
            cpu_wdata <= 128'b0;
            dealing <= 1'b0;
            uncache_dealing <= 1'b0;
            uncache_2 <= 1'b0;

            for(i=0;i<8;i=i+1)
            begin
                dirty[i] <= 2'b00;
            end
        end
        else if((next_state == IDLE) & (req_2 & hit | !req_2))  //闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡宀嬬節瀹曟帒螣鐞涒€充壕闁哄稁鍋€閸嬫挸顫濋浣界闂佺灏欐晶妤冪箔閻旂》缍栨い鏃囨椤忓爼姊烘潪鎵妽闁圭懓娲ら锝夘敆閸曨倠褔鏌涢埄鍐炬濞村吋鎹囧缁樻媴閼恒儳銆婇梺鍝ュУ閸旀瑥顕ｉ崨濠勭瘈婵﹩鍓涢鍡欑磽娴ｅ憡婀伴柟鍓叉te == `RETURN
        begin
            uncache_2 <= vaddr_1[31:16] == 16'hbfaf & (ren | (|wen));     //闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊Χ鎼达紕浼囧┑鐐额嚋缂嶄礁顫忛搹瑙勫磯闁靛ǹ鍎查悗楣冩⒑閸濆嫷鍎忔い顓犲厴閻涱喛绠涘☉娆忊偓濠氭煠閹帒鍔滄繛鍛灲濮婃椽宕崟顐熷亾閸洖纾归柡宥庡亐閸嬫挸顫濋鍌溞ㄩ梺鍝勮閸旀垿骞冮姀銈呭窛濠电姴瀚槐鏇㈡⒒娴ｅ摜绉烘い銉︽崌瀹曟顫滈埀顒€顕ｉ锕€绠婚悹鍥у级椤ユ繈姊洪棃娑氬婵☆偅顨婇、鏃堟晸閿燂拷
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
        else if(state == DIRTY_WRITE)   //闂備浇娉曢崰鎰板几婵犳艾绠柣鎴犳櫕閹藉矂姊虹捄銊ユ瀾闁哄顭烽獮蹇涙倻閼恒儲娅㈢紓鍌氬€归幐鍐差焽婵犳艾绠紒灞界崢se
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
                cpu_raddr <= ret_data_paddr;
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
    reg [31:0] hit_data_word_choose; //闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘鳖劦ffset闂備浇娉曢崰鎰板几婵犳艾绠柣鎴Ｐ掗崑鎾村緞閹邦厽娅㈤梺鍝勫€堕崐鏍偓姘鳖劉ache闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌ㄩ悤鍌涘4闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟⒑鐠恒劌鏋旈柣娑栧€濋崺銉╁川椤旂⒈浼撻梻浣芥硶閸犳劘銇愰钘夘嚤婵炲棙鍔曢鍫曟⒑鐠恒劌娅愰柟鍑ゆ嫹
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
            for(i=0;i<8;i=i+1)
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
    
    dcache_ram ram1
    (
        .clk(clk),
        .we(we1_choose),
        .w_index(index_2),
        .r_index(index_1),
        .rst(rst),
        .data_in(write_ram_data),
        .data_out(data_block1)
    );

    dcache_ram ram2
    (
        .clk(clk),
        .we(we2_choose),
        .w_index(index_2),
        .r_index(index_1),
        .rst(rst),
        .data_in(write_ram_data),
        .data_out(data_block2)
    );
    
/*
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
    */
    dcache_tag tag_ram1
    (
        .clk(clk),
        .we(we1),
        .w_index(index_2),
        .r_index(index_1),
        .rst(rst),
        .data_in(write_ram_tag),
        .data_out(ram_tag1)
    );
    dcache_tag tag_ram2
    (
        .clk(clk),
        .we(we2),
        .w_index(index_2),
        .r_index(index_1),
        .rst(rst),
        .data_in(write_ram_tag),
        .data_out(ram_tag2)
    );
    /*
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
    */
    assign uncache_ren = (state == UNCACHE) & dev_rrdy & ren_2 & !uncache_rvalid;
    assign uncache_raddr = ret_data_paddr;

    assign uncache_wen = (state == UNCACHE) & !uncache_write_finish & (!ren_2);
    assign uncache_wstrb = wen_2;
    assign uncache_waddr = ret_data_paddr;
    assign uncache_wdata = w_data_2;
endmodule