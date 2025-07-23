`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module dram_fifo (
    input wire clk,
    input wire rst,

    input wire flush,

    input wire [1:0] enqueue_en, //闂備胶枪缁诲牓宕曢棃娴筹綁鏁傞懞銉ヮ€撻梺鍏煎墯閸ㄤ即宕㈤弶鎳酣宕堕敐鍌氫壕闁告劖褰冮埢锟�
    input wire [`DECODE_DATA_WIDTH - 1:0] enqueue_data1, //闂傚倷鑳舵灙缂佽鐗撳畷鏇㈡濞寸缍侀弫鍐磼濮橆厾鈧剟姊虹紒姗嗘當闁绘妫涚划濠囨晸閿燂拷
    input wire [`DECODE_DATA_WIDTH - 1:0] enqueue_data2, 

    input wire [1:0] invalid_en, // 闂備浇妗ㄩ懗鑸垫櫠濡も偓閻ｅ灚绗熼埀顒€顕ｉ崹顐㈢窞閻庯綆鍋呴悵鈩冪箾鏉堝墽绉柛搴☆煼瀹曟螣閼姐倐鏀抽梺鐐藉劚閸熸寧绻涢敓锟�
    output wire [`DECODE_DATA_WIDTH - 1:0] dequeue_data1, //闂傚倷绀侀幉锟犲垂鐠轰警娓婚柦妯猴級閿濆鏅濋柛灞剧閻庮剟姊虹紒姗嗘當闁绘妫涚划濠囨晸閿燂拷
    output wire [`DECODE_DATA_WIDTH - 1:0] dequeue_data2,
    
    output wire get_data_req,
    output wire full,
    output wire empty
);

    reg [`DECODE_DATA_WIDTH - 1:0] ram [`DEPTH - 1:0];

    // 闂傚倸鍊搁崯浼村窗鎼淬劍鍋勬い鎺戝缁€鍐╃箾閸℃ê濮堟繛鍫濈埣閺岀喓鎷犻垾铏彲缂備浇椴哥换鍫濐潖婵傚憡鍋勯柡瀣靛亗缁捇鏌ｉ悩鍙夊窛缂侇噮鍨跺鎶芥偄閻撳海顔夐梺璺ㄥ櫐閹凤拷
    reg [$clog2(`DEPTH) - 1:0] head;    
    reg [$clog2(`DEPTH) - 1:0] tail;   

    reg [$clog2(`DEPTH) - 1:0] head_plus;   
    reg [$clog2(`DEPTH) - 1:0] tail_plus;  


    integer j;
    always @(posedge clk) 
    begin
        if (rst || flush) 
        begin 
            tail      <= 0;
            tail_plus <= 1;
        end else if (&enqueue_en) begin    
            tail      <= tail + 2;
            tail_plus <= tail_plus + 2;
        end else if (|enqueue_en) begin     
            tail      <= tail + 1;
            tail_plus <= tail_plus + 1;
        end
    end

    always @(posedge clk) 
    begin
        if(rst || flush)
        begin
            for(j=0;j<8;j=j+1)
            begin
                ram[j] <= 0;
            end
        end
        else if (&enqueue_en) 
        begin
            ram[tail]     <= enqueue_data1;
            ram[tail + 1] <= enqueue_data2;
        end 
        else if (enqueue_en[0]) 
        begin
            ram[tail] <= enqueue_data1;
        end 
        else if (enqueue_en[1]) 
        begin
            ram[tail] <= enqueue_data2;
        end
    end

    always @(posedge clk) 
    begin
        if (rst || flush) 
        begin     // 闂傚倸鍊搁崐宄懊归崶褉鏋栭柡鍥ュ灩缁愭鏌熼悧鍫熺凡闁告垹濮撮埞鎴︽偐鐎圭姴顥濈紓浣哄閸ㄦ娊鍩€椤掑倹鍤€閻庢矮鍗冲畷鎴炵節閸屻倗鍔峰┑掳鍊曢幊蹇涘煕閹达附鍋ｉ柟顓熷笒婵″ジ鏌＄€ｎ偄鐏撮柡宀嬬磿閳ь剨缍嗘禍鍫曟偂閸忕⒈娈介柣鎰皺缁犲鏌熼鐣岀煉闁瑰磭鍋ゆ俊鐑芥晜缁涘鎴烽梻鍌氬€风粈渚€骞栭锕€纾归柛顐ｆ礀绾惧綊鏌″搴′簮闁稿鎸搁～婵嬪箛娴ｅ湱绉烽柣搴＄仛濠㈡鈧凹鍣ｉ崺鈧い鎺嶈兌閳洟鏌ㄥ鑸电厽闁挎洍鍋撶紓宥咃工椤繘鎼圭憴鍕／闂侀潧枪閸庢煡鎮楁ィ鍐┾拺闁告繂瀚烽崕蹇斻亜椤撶姴鍘撮柣娑卞枦缁犳稑鈽夊▎鎰仧闂備浇娉曢崳锕傚箯閿燂拷
            head      <= 0;
            head_plus <= 1;
        end else if (&invalid_en && !empty) 
        begin   // 闂傚倸鍊搁崐宄懊归崶褉鏋栭柡鍥ュ灩缁愭鏌熼悧鍫熺凡闁告垹濮撮埞鎴︽偐鐎圭姴顥濈紓浣哄閸ㄥ爼寮婚敐澶婄闁挎繂鎲涢幘缁樼厸闁告侗鍠楅崐鎰版煛瀹€瀣瘈鐎规洘甯掕灒閻炴稈鈧厖澹曢梺鍝勭▉閸嬧偓闁稿鎸搁～婵嬵敆閸屾簽銊╂⒑閸濆嫯顫﹂柛鏃€鍨块獮鍐閵堝懎绐涙繝鐢靛Т鐎氼亞妲愰弴銏♀拻濞达絽鎽滅粔鐑樸亜閵夛附宕岀€规洘顨呴～婊堝焵椤掆偓椤曪綁顢曢敃鈧粻濠氭偣閸パ冪骇妞ゃ儲绻堝娲濞戞艾顣哄┑鈽嗗亝椤ㄥ﹪銆侀弮鍌涘磯濠靛倽妫勭紞濠囧极閹版澘宸濇い鏃堟？濞ｎ噣姊绘担鑺ャ€冮柣鎺炵畵楠炴垿宕惰閸ゆ洘銇勯幒鎴濐仼閸ユ挳姊虹化鏇炲⒉妞ゃ劌绻戠€靛ジ骞樼紒妯锋嫽婵炶揪缍€婵倗娑甸崼鏇熺厱闁绘ǹ娅曠粈瀣偓瑙勬礃缁秶缂撻悾宀€鐭欓悹鎭掑妿閸橆剟姊绘担鍦菇闁稿ǹ鍊濆畷瑙勭附缁嬭法鏌堥梺鎼炲労閸撴岸鎮″▎鎾寸厽闁靛牆楠搁悘锟犳煠闂堟稓绉洪柟顔肩秺楠炲洭鎳滈棃娑变紦1闂傚倸鍊风粈渚€骞栭锕€绐楁繛鎴欏灩缁狀垶鏌ㄩ悤鍌涘
            head      <= head + 2;
            head_plus <= head_plus + 2;
            ram[head][0] <= 0;
            ram[head_plus][0] <= 0;
        end else if (|invalid_en && !empty) 
        begin   // 闂傚倸鍊搁崐宄懊归崶褉鏋栭柡鍥ュ灩缁愭鏌熼悧鍫熺凡闁告垹濮撮埞鎴︽偐鐎圭姴顥濈紓浣哄閸ㄥ爼寮昏椤繈顢楅埀顒勫焵椤掆偓椤兘銆侀弮鍫熺劶鐎广儱妫岄幏娲煟閻樺厖鑸柛鏂跨焸瀵悂骞嬮敂鐣屽幐闁诲函缍嗘禍鍫曟偂閸忕⒈娈介柣鎰皺缁犲鏌熼鐣岀煉闁瑰磭鍋ゆ俊鐑芥晜缁涘鎴烽梻鍌氬€风粈渚€骞栭锕€纾归柛顐ｆ礀绾惧綊鏌″搴′簮闁稿鎸搁～婵嬵敆閸屾簽銊╂⒑閸濆嫯顫﹂柛鏃€鍨块獮鍐閵堝懎绐涙繝鐢靛Т鐎氼亞妲愰弴銏♀拻濞达絽鎲＄拹锟犳煛鐏炵瓔妲搁柕鍡樺笧閹叉挳宕熼鐙€鍟庨梻浣规偠閸庢椽宕滃鑸靛亗闁靛鏅滈悡鐔兼煛閸屾稑顕滈柛鐔哄仱閺岋綀绠涢敐鍛彎闂佸搫鐬奸崰鎰八囬悧鍫熷劅闁炽儱鍟跨粻锝夋⒒娴ｈ姤銆冮柣鎺炵畵楠炴垿宕堕鈧粻鐘充繆椤栨瑨顒熸繛灏栨櫊閺屾稑螖閸愩劋鎴峰┑鐐茬墑閸婃繂顫忓ú顏勬嵍妞ゆ挾鍠撻崝鐟扳攽閻愬瓨灏繝鈧柆宥呯鐟滅増甯楅弲鎼佹煥閻曞倹瀚�1闂傚倸鍊风粈渚€骞栭锕€绐楁繛鎴欏灩缁狀垶鏌ㄩ悤鍌涘
            head      <= head + 1;
            head_plus <= head_plus + 1;
            ram[head][0] <= 0;
        end
    end

    // 闂傚倸鍊搁崐宄懊归崶褉鏋栭柡鍥ュ灩缁愭鏌熼悧鍫熺凡闁告垹濮撮埞鎴︽偐鐎圭姴顥濈紓浣哄閸ㄥ爼寮婚敐澶婄闁挎繂鎲涢幘缁樼厸闁告侗鍠楅崐鎰版煛瀹€瀣瘈鐎规洘甯掕灒閻炴稈鈧厖澹曢梺鍝勭▉閸嬧偓闁稿鎸搁～婵嬫倷椤掆偓椤忥拷
    assign dequeue_data1 = ram[head];
    assign dequeue_data2 = ram[head_plus];



    // 闂傚倸鍊搁崐宄懊归崶褉鏋栭柡鍥ュ灩缁愭骞栧ǎ顒€鈧垶绂嶈ぐ鎺撶厪濠电偟鍋撳▍鍛繆椤愶缉鎴﹀Φ閸曨垰绠绘い鏍ㄤ緱濞兼垿姊洪崫銉ユ瀻婵炲樊鍙冨濠氭偄閸撳弶效闁硅偐琛ラ埀顒€鍟跨粻锝夋⒒娴ｈ姤銆冮柣鎺炵畵楠炴垿宕惰閸ゆ洘銇勯幒鎴濐仼閸ユ挳姊虹化鏇炲⒉妞ゃ劌绻戠€靛ジ骞樼紒妯锋嫽婵炶揪缍€婵倗娑甸崼鏇熺厱闁绘ê鍟挎慨宥団偓娈垮枛閹诧紕鎹㈠┑鍡╂僵妞ゆ帒鍋嗛崬鐢告⒒娴ｈ櫣甯涢柛銊ュ悑閹便劑濡舵径濠勬煣闂佸綊妫块悞锕傛偂濞戙垺鐓曢悘鐐扮畽椤忓牆鐒垫い鎺嶈兌婢ч亶鏌嶈閸撴岸鎳濋崜褏绀婂┑鐘叉搐閽冪喖鏌曟繛鐐珕闁稿瀚伴弻锝夊煛閸屾岸鍤嬬紓浣哄У閹瑰洤顕ｉ锕€绠涙い鏍ㄧ矌閺夋悂姊洪崫鍕偓褰掝敄濞嗘劕顕遍柟鍓х帛閳锋帒霉閿濆牆袚缁绢厼鐖奸弻娑㈡偐閸愭彃顫掗悗娈垮枛閹诧紕鎹㈠┑鍡╂僵妞ゆ帒鍋嗛崬鐢告⒒娴ｈ櫣甯涢柛銊ュ悑閹便劑濡舵径濠勬煣闂佸綊妫块悞锕傛偂濞戙垺鐓曢悘鐐扮畽椤忓牆鐒垫い鎺嶈兌婢ч亶鏌嶈閸撴岸鎳濋崜褏绀婂┑鐘叉搐閽冪喖鏌曟繛鐐珕闁稿瀚妴鎺戭潩閻撳海浠ч梺姹囧労娴滅偟妲愰幒鏃傜＜闁靛繒濮寸猾宥夋⒑鐞涒€充壕闁哄鐗冮弬渚€宕戦幘鎰佹僵闁绘劦鍓欓锟�
    wire stall;
    assign stall = (head == (tail + 3) % `DEPTH);
    assign full = (head == (tail_plus + 1) % `DEPTH) || (head == tail_plus);
    assign empty = (head == tail) || (head == tail_plus);

    assign get_data_req = !(stall || full);

endmodule