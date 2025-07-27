`timescale 1ns / 1ps

`define BHT_IDX_W 10                    // 闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸湱鏌夊〒鍦礊閿燂拷??
`define BHT_ENTRY (1 << `BHT_IDX_W)     // 闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘缁樻櫢闁跨噦鎷�?
`define BHT_TAG_W 8                     // tag闂備浇娉曢崰鏇€€佸⿰鍛閻熸瑥瀚璺好归敐鍛ч柡浣规崌瀵剟濡堕崱妤婁紦

module BPU 
(
    input  wire         cpu_clk    ,
    input  wire         cpu_rstn   ,        // 改成cpu_rst（高电平有效）
    input  wire [31:0]  if_pc      ,        // IF闂備浇娉曢崰鏍熸担鐑樺閻熸瑥瀚绂
    // predict branch direction and target
    output wire         pred_taken1,
    output wire         pred_taken2,
    output wire [31:0]  pred_addr,        // 婵☆偅婢樼€氫即寮幘璇叉闁靛牆妫楅鍫曟煟閳哄﹤娅嶉柡浣规崌瀵剟濡堕崱妤婁紦闂備浇娉曢崰鎰板几婵犳艾绠柨鐕傛嫹?
    output wire         BPU_flush ,        // 闂備浇娉曢崰鏇綖濡ゅ懎绀勯柕鍫濇椤忚泛螞閺夊灝顏柡浣规崌瀵剟濡堕崱妤婁紦闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌ㄩ悤鍌涘?,闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟⒑鐠恒劌鏋戦柡瀣煼楠炲繘鏁撻敓锟�?闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂寮堕崼婵嗘殶婵炲牊鍨跺蹇涙倷椤掆偓椤忓爼姊虹捄銊ユ瀾闁哄顭烽獮蹇涙煥鐎ｎ亞妯勯梻浣芥硶閸犳劙寮告繝姘闁跨噦鎷�
    output wire [31:0]  new_pc,     //分支预测错误后的新pc

    input  wire         ex_is_bj_1   ,  
    input  wire [31:0]  ex_pc_1      ,
    input  wire         ex_valid1    ,        
    input  wire         ex_is_bj_2   ,    
    input  wire [31:0]  ex_pc_2      , 
    input  wire         ex_valid2    ,
    input  wire         real_taken1 ,        
    input  wire         real_taken2 ,
    input  wire [31:0]  real_addr1, 
    input  wire [31:0]  real_addr2,
    input  wire [31:0]  pred_addr1,
    input  wire [31:0]  pred_addr2

);

// BHT and BTB
reg  [`BHT_TAG_W-1:0] tag     [`BHT_ENTRY-1:0];
reg  [`BHT_ENTRY-1:0] valid;
reg  [           1:0] history [`BHT_ENTRY-1:0]; //闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘缁樺殟闁稿本姘ㄩ幗鐘绘煕瀹€瀣 闂備浇娉曢崰鎰板几婵犳艾绠梺鍨儐閺嗘粓鏌熺粙鎸庡枠闁轰焦鎹囧顒勫Χ閸℃浼撻梻浣芥硶閸犳劙寮告繝姘闁绘垼濮ら弲鍝ョ磽娴ｅ搫浠滈柛銈嗙墵楠炲繘鎮滈懞銉︽闂備胶鍋撴竟鍡涘Υ鐎ｎ喖绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘炬嫹?闂備浇娉曢崰鎰板几婵犳艾绠柨鐕傛嫹?? 2 婵炶揪绲界粔褰掑极閹捐妫橀柕鍫濇椤忓爼鏌熼褍鐏﹂柡浣规崌瀵剟濡堕崱妤婁紦婵☆偅婢樼€氫即寮幘璇叉闁靛牆妫楅鍫曟煛閸偂閭柡浣规崌瀵剟濡堕崱妤婁紦闂備浇娉曢崰鎰板几婵犳艾绠梺鍨儐閺嗘粓鏌熺粙鎸庡枠闁轰焦鎹囧顒勫Χ閸℃浼撻梻浣芥硶閸犳劙寮告繝姘闁绘垼濮ら弲鎼佹煛閸屾ê鈧牜鈧熬鎷�?闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘愁潐濞碱亪顢楅崟顒佹闂佸搫鍊堕崐鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻弻澶娒归崱娑欑叆闁绘柨鎲￠悘顕€鏌熼崙銈嗗???闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂姊洪幍顔芥毄闁靛棗顑夐獮蹇涙倻閼恒儲娅㈤梺鍝勫€堕崐鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佺懓鍤栭幏锟�
reg  [          31:0] addr  [`BHT_ENTRY-1:0];

wire [31:0]if_pc4 = if_pc + 4;

wire [`BHT_TAG_W-1:0] if_tag1 = if_pc[31:24];
wire [`BHT_TAG_W-1:0] if_tag2 = if_pc4[31:24];
wire [`BHT_IDX_W-1:0] index1 = {if_pc[29:24]^if_pc[23:18]^if_pc[17:12]^if_pc[11:6],if_pc[5:2]};
wire [`BHT_IDX_W-1:0] index2 = {if_pc4[29:24]^if_pc4[23:18]^if_pc4[17:12]^if_pc4[11:6],if_pc4[5:2]};

assign pred_taken1 = if_tag1 == tag[index1] & valid[index1] == 1'b1 & history[index1][1] == 1'b1;
assign pred_taken2 = if_tag2 == tag[index2] & valid[index2] == 1'b1 & history[index2][1] == 1'b1;
assign pred_addr = pred_taken1 ? addr[index1] : pred_taken2 ? addr[index2] : if_pc + 8;

wire ex_tag1 = ex_pc_1[31:24];
wire ex_tag2 = ex_pc_2[31:24];
wire ex_index1 = {ex_pc_1[29:24]^ex_pc_1[23:18]^ex_pc_1[17:12]^ex_pc_1[11:6],ex_pc_1[5:2]};
wire ex_index2 = {ex_pc_2[29:24]^ex_pc_2[23:18]^ex_pc_2[17:12]^ex_pc_2[11:6],ex_pc_2[5:2]};

wire add1 = ex_valid1 & !valid[ex_index1] & real_taken1;
wire add2 = ex_valid2 & !valid[ex_index2] & real_taken2;
wire update1 = ex_valid1 & valid[ex_index1] & tag[ex_index1]==ex_tag1 & ex_is_bj_1;
wire update2 = ex_valid2 & valid[ex_index2] & tag[ex_index2]==ex_tag2 & ex_is_bj_2;
wire replace1 = ex_valid1 & valid[ex_index1] & real_taken1 & tag[ex_index1]!=ex_tag1;
wire replace2 = ex_valid2 & valid[ex_index2] & real_taken2 & tag[ex_index2]!=ex_tag2;

wire addr_error1 = ex_valid1 & pred_addr1 != real_addr1;     //婵☆偅婢樼€氫即寮幘璇叉闁靛牆妫楅鍫曟⒑鐠恒劌鏋戦柡瀣煼楠炲繘鎮块娑氥偖闂備浇娉曢崰鎰板几婵犳艾绠柣鎴ｅГ閺呮悂鏌￠崒妯衡偓鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟煟閳哄﹤娅嶉柡浣规崌瀵剟濡堕崱妤婁紦闂備浇娉曢崰鏇€€佸⿰鍫濈闁靛牆妫楅鍫曟⒑鐠恒劌鏋戦柡瀣煼楠炲繘鎮滈懞銉︽闂佸搫鍊堕崐鏍偓姘秺閺屻劑鎮㈤崨濠勪紕闂佸綊顥撻崗姗€寮幘璇叉闁靛牆妫楅鍫曟⒑鐠恒劌鏋戦柡瀣煼楠炲繘鏁撻敓锟�?濠电偛鐭夌换婵嬪极閹捐妫橀柕鍫濇椤忥拷
wire addr_error2 = ex_valid2 & pred_addr2 != real_addr2;

assign BPU_flush = addr_error1 | addr_error2;
assign new_pc = addr_error1 ? real_addr1 : real_addr2; 

integer i;
always @(posedge cpu_clk) 
begin
    if (cpu_rstn) 
    begin
        valid <= {`BHT_ENTRY{1'b0}};
        for (i = 0; i < `BHT_ENTRY; i = i + 1)
        begin
            history[i] <= 2'b10;
            valid[i] <= 1'b0;
            tag[i] <= 8'b0;
            addr[i] <= 32'b0;
        end
    end 
    else 
    begin
        if(add1)
        begin
            history[ex_index1] <= 2'b10;
            valid[ex_index1] <= 1'b1;
            tag[ex_index1] <= ex_tag1;
            addr[ex_index1] <= real_addr1;
        end
        else if(add2 & ex_index1 != ex_index2)
        begin
            history[ex_index2] <= 2'b10;
            valid[ex_index2] <= 1'b1;
            tag[ex_index2] <= ex_tag2;
            addr[ex_index2] <= real_addr2;
        end
        if(update1)
        begin
            if(real_taken1)
            begin
                case(history[ex_index1])
                    2'b00: history[ex_index1] <= 2'b01;
                    2'b01: history[ex_index1] <= 2'b10;
                    2'b10: history[ex_index1] <= 2'b11;
                    2'b11: history[ex_index1] <= 2'b11;
                endcase
            end
            else
            begin
                case(history[ex_index1])
                2'b00: history[ex_index1] <= 2'b00;
                2'b01: history[ex_index1] <= 2'b00;
                2'b10: history[ex_index1] <= 2'b01;
                2'b11: history[ex_index1] <= 2'b10;
                endcase
            end
        end
        if(update2 & !real_taken1)
        begin
            if(real_taken2)
            begin
                case(history[ex_index2])
                    2'b00: history[ex_index2] <= 2'b01;
                    2'b01: history[ex_index2] <= 2'b10;
                    2'b10: history[ex_index2] <= 2'b11;
                    2'b11: history[ex_index2] <= 2'b11;
                endcase
            end
            else
            begin
                case(history[ex_index2])
                    2'b00: history[ex_index2] <= 2'b00;
                    2'b01: history[ex_index2] <= 2'b00;
                    2'b10: history[ex_index2] <= 2'b01;
                    2'b11: history[ex_index2] <= 2'b10;
                endcase
            end
        end
        if(replace1)
        begin
            tag[ex_index1] <= ex_tag1;
            history[ex_index1] <= 2'b10;
            addr[ex_index1] <= real_addr1;
        end
        else if(replace2 & ex_index1 != ex_index2)
        begin
            tag[ex_index2] <= ex_tag2;
            history[ex_index2] <= 2'b10;
            addr[ex_index2] <= real_addr2;
        end
    end
end
endmodule