`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module dram_fifo (
    input wire clk,
    input wire rst,

    input wire flush,

    input wire [1:0] enqueue_en, //闂佺ǹ绻堥崕闈浳ｉ敂鑺ュ闁兼剚鍨伴崢鏉懬庨崶锝傚亾閸愭彃鈻�
    input wire [`DECODE_DATA_WIDTH - 1:0] enqueue_data1, //闂備胶枪缁诲牓宕曢棃娴筹綁鏁冮崒姘€梺缁橆殔閻楀棛绮婇敓锟�
    input wire [`DECODE_DATA_WIDTH - 1:0] enqueue_data2, 

    input wire [1:0] invalid_en, // 闂佽桨鑳舵晶妤€鐣垫笟鈧鍨緞鐎ｎ偅鐝℃繛杈剧秬閸庡宕楀Ο鑽も攳闁炽儱鍟挎繛锟�
    output wire [`DECODE_DATA_WIDTH - 1:0] dequeue_data1, //闂備礁鎲￠崹璺侯渻閽樺）锝夋晝閸屾碍鐎梺缁橆殔閻楀棛绮婇敓锟�
    output wire [`DECODE_DATA_WIDTH - 1:0] dequeue_data2,
    
    output wire get_data_req,
    output wire full,
    output wire empty
);

    reg [`DECODE_DATA_WIDTH - 1:0] ram [`DEPTH - 1:0];

    // 闂傚倸鍟伴崰搴ㄦ偄椤掑嫬绀冩繛鍡樺姈濞堝爼鏌熺拠鈥虫珯缂佽鲸绻堝濂告偄閺嬵偂绮撻柣鐘叉川缁垶寮抽悢鐓庣闁跨噦鎷�
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
        begin     // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨抽埀顒傛嚀鐎氫即宕戞繝鍌ょ劷婵°倕鎳忛埛鎴︽偣閹帒濡奸柡瀣灴閺岋紕鈧綆浜堕悡鍏碱殽閻愯尙绠婚柟顔界矒閹崇偤濡烽敂绛嬩户闂傚倷绀侀幖顐﹀磹閸洖纾归柡宥庡亐閸嬫挸顫濋幇浣圭秷閻庡灚婢樼€氼噣鍩€椤掍胶鈯曢柨姘舵煟閿曗偓缂嶅﹤顫忛搹瑙勫磯闁靛ǹ鍎查悗楣冩⒑閸濆嫷鍎忔い顓犲厴閻涱喛绠涘☉娆愭闂佽法鍣﹂幏锟�
            head      <= 0;
            head_plus <= 1;
        end else if (&invalid_en && !empty) 
        begin   // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡宀嬬節瀹曟帒螣鐞涒€充壕闁哄稁鍋€閸嬫挸顫濋鍌溞ㄩ梺鍝勮閸旀垿骞冮姀銈呭窛濠电姴瀚槐鏇㈡⒒娴ｅ摜绉烘い銉︽崌瀹曟顫滈埀顒€顕ｉ锕€绠婚悹鍥у级椤ユ繈姊洪棃娑氬婵☆偅顨婇、鏃傛崉婵傝棄缍婇弫鎰板川椤旈棿娣梻浣芥〃閻掞箓骞戦崶褜鍤曟い鎺戝鍥撮梺绯曞墲椤ㄥ繑瀵奸幘缁樷拻濞达綀濮ょ涵鍫曟煕閻樿櫕绀嬬€规洘绮嶇缓鐣岀矙鐠恒劎鍘梻浣圭湽閸娿倝宕规總绋跨柈闁搞儺鍓氶悡娆撴煟閵堝骸鐏￠柤闈涚秺閹綊骞囬懜闈涱伓1闂傚倷绀侀幖顐﹀窗濞戙垹绠柨鐕傛嫹
            head      <= head + 2;
            head_plus <= head_plus + 2;
            ram[head][0] <= 0;
            ram[head_plus][0] <= 0;
        end else if (|invalid_en && !empty) 
        begin   // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻褍顫濋鈧埀顒€顭烽、鏃堟焼瀹ュ棌鎷洪柣鐘充航閸斿矂寮搁幋锔界厸閻庯綆浜堕悡鍏碱殽閻愯尙绠婚柟顔界矒閹崇偤濡烽敂绛嬩户闂傚倷绀侀幖顐﹀磹閸洖纾归柡宥庡亐閸嬫挸顫濋鍌溞ㄩ梺鍝勮閸旀垿骞冮姀銈呭窛濠电姴瀚槐鏇㈡⒒娴ｅ憡璐￠柡灞筋槸閵嗘帞鎲撮崟顓狀啎闂佹悶鍎洪崜姘舵偂閵夆晜鐓熼柡鍌涘閸熺偤鏌ｈ箛锝呮珝闁哄瞼鍠愰ˇ鐗堟償閳ュ啿绠ｉ梻浣芥〃閻掞箓骞戦崶顒€绠犳俊顖欒濞尖晠鏌涘Δ鍐ㄤ户婵炲牄鍊濆娲捶椤撶喓鍔瑰┑鐐存尭濠€閬嶅箯瑜版帗鏅搁柨鐕傛嫹1闂傚倷绀侀幖顐﹀窗濞戙垹绠柨鐕傛嫹
            head      <= head + 1;
            head_plus <= head_plus + 1;
            ram[head][0] <= 0;
        end
    end

    // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡宀嬬節瀹曟帒螣鐞涒€充壕闁哄稁鍋€閸嬫挸顫濋悙顒€顏�
    assign dequeue_data1 = ram[head];
    assign dequeue_data2 = ram[head_plus];



    // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅幖娣€戞禍褰掓煏婵炵偓娅呮俊顐Ｉ戦妵鍕箻椤栨侗娼戦梺鍝ュ枎濞差參寮婚悢鍓叉Ч閹肩补鈧啿绠ｉ梻浣芥〃閻掞箓骞戦崶褜鍤曟い鎺戝鍥撮梺绯曞墲椤ㄥ繑瀵奸幘缁樷拻濞达綀濮ょ涵鍫曟煕閻樺啿濮嶇€殿喖鎲＄换婵嗩潩椤掑偆鍞甸梻浣虹帛閸ㄥ吋鎱ㄩ妶澶婄柧闁归棿鐒﹂悡娑㈡煕鐏炰箙顏堝焵椤掍胶澧遍柍褜鍓氶懝鍓х礊婵犲洤钃熼柕濞炬櫆閸嬪嫰鏌ｉ埡鍌氶嚋缂佺姵鎹囧顐﹀箛椤栨粎鏉搁梺鍝勫€归娆愬閹剧粯鈷掑ù锝堝Г绾爼鏌涢悩鍐插鐎殿喖鎲＄换婵嗩潩椤掑偆鍞甸梻浣虹帛閸ㄥ吋鎱ㄩ妶澶婄柧闁归棿鐒﹂悡娑㈡煕鐏炰箙顏堝焵椤掍胶澧遍柍褜鍓氶懝鍓х礊婵犲洤钃熼柕濞炬櫆閸嬪嫬銆掑鐓庣仧闁汇儺浜炵槐鎺旂磼閵忕姴绫嶉梺琛″亾閺夊牃鏂侀崑鎾愁潩閻愵剙顏�
    wire stall;
    assign stall = (head == (tail + 3) % `DEPTH);
    assign full = (head == (tail_plus + 1) % `DEPTH) || (head == tail_plus);
    assign empty = (head == tail) || (head == tail_plus);

    assign get_data_req = !(stall || full);

endmodule