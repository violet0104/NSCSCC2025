`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module dram_fifo (
    input wire clk,
    input wire rst,

    input wire flush,

    input wire [1:0] enqueue_en, //闂備胶枪缁诲牓宕曢棃娴筹綁鏁傞懞銉ヮ€撻梺鍏煎墯閸ㄤ即宕㈤弶鎳酣宕堕敐鍌氫壕闁告劖褰冮埢锟�?
    input wire [`DECODE_DATA_WIDTH - 1:0] enqueue_data1, //闂傚倷鑳舵灙缂佽鐗撳畷鏇㈡濞寸缍侀弫鍐磼濮橆厾鈧剟姊虹紒姗嗘當闁绘妫涚划濠囨晸閿燂拷
    input wire [`DECODE_DATA_WIDTH - 1:0] enqueue_data2, 

    input wire [1:0] invalid_en, // 闂備浇妗ㄩ懗鑸垫櫠濡も偓閻ｅ灚绗熼埀顒€顕ｉ崹顐㈢窞閻庯綆鍋呴悵鈩冪箾鏉堝墽绉柛搴☆煼瀹曟螣閼姐倐鏀抽梺鐐藉劚閸熸寧绻涢敓锟�?
    output wire [`DECODE_DATA_WIDTH - 1:0] dequeue_data1, //闂傚倷绀侢�幉锟犲垂鐠轰警娓婚柦妯猴級閿濆鏅濋柛灞剧閻庮剟姊虹紒姗嗘當闁绘妫涚划濠囨晸閿燂�?
    output wire [`DECODE_DATA_WIDTH - 1:0] dequeue_data2,
    
    output wire get_data_req,
    output wire full,
    output wire empty
);

    reg [`DECODE_DATA_WIDTH - 1:0] ram [`DEPTH - 1:0];

    // 闂傚倸鍊搁崯浼村窗鎼淬劍鍋勬い鎺戝缁€鍐╃箾閸℃ê濮堟繛鍫濈埣閺岢�喓鎷犻垾铏彲缂備浇椴哥换鍫濐潖婵傚憡鍋勯柡瀣靛亗缁捇鏌ｉ悩鍙夊窛缂侇噮鍨跺鎶芥偄閻撳海顔夐梺璺ㄥ櫐閹凤�?
    reg [$clog2(`DEPTH) - 1:0] head;    
    reg [$clog2(`DEPTH) - 1:0] tail;   

    reg [$clog2(`DEPTH) - 1:0] head_plus;   
    reg [$clog2(`DEPTH) - 1:0] tail_plus;  


    integer j;

    always @(posedge clk) 
    begin
        if(rst || flush)
        begin
            for(j=0;j<8;j=j+1)
            begin
                ram[j] <= 0;
            end
            tail <= 0;
            tail_plus <= 1;
            head <= 0;
            head_plus <= 1;
        end
        else 
        begin
            case({invalid_en,enqueue_en})
            4'b1111:begin
                tail <= tail + 2;
                tail_plus <= tail_plus + 2;
                head <= head + 2;
                head_plus <= head_plus + 2;
                ram[head][0] <= 0;
                ram[head_plus][0] <= 0;
                ram[tail] <= enqueue_data1;
                ram[tail_plus] <= enqueue_data2;
            end
            4'b1011:begin
                tail <= tail + 2;
                tail_plus <= tail_plus + 2;
                head <= head + 1;
                head_plus <= head_plus + 1;
                ram[head][0] <= 0;
                ram[tail] <= enqueue_data1;
                ram[tail_plus] <= enqueue_data2;
            end
            4'b0111:begin
                tail <= tail + 2;
                tail_plus <= tail_plus + 2;
                head <= head + 1;
                head_plus <= head_plus + 1;
                ram[head][0] <= 0;
                ram[tail]     <= enqueue_data1;
                ram[tail_plus] <= enqueue_data2;
            end
            4'b0011:begin
                tail <= tail + 2;
                tail_plus <= tail_plus + 2;
                ram[tail]     <= enqueue_data1;
                ram[tail_plus] <= enqueue_data2;
            end
            4'b1100:begin
                head <= head + 2;
                head_plus <= head_plus + 2;
                ram[head][0] <= 0;
                ram[head_plus][0] <= 0;
            end
            4'b1000:begin
                head <= head + 1;
                head_plus <= head_plus + 1;
                ram[head][0] <= 0;
            end
            4'b0100:begin
                head <= head + 1;
                head_plus <= head_plus + 1;
                ram[head][0] <= 0;
            end
            default:;
            endcase
        end
    end


    // 闂傚倸鍊搁崐宄懊归崶褉鏋栭柡鍥ュ灩缁愭鏌熼悧鍫熺凡闁告垹濮撮埞鎴︽偐鐎圭姴顥濈紓浣哄��閸ㄥ爼寮婚敐澶婄闁挎繂鎲涢幘缁樼厸闁告侗鍠楅崐鎰版煛瀹€瀣瘈鐎规洘甯掕灒閻炴稈鈧厖澹曢梺鍝勭▉閸嬧偓闁�?鎸搁～婵嬫倷椤掆偓椤忥�?
    assign dequeue_data1 = ram[head];
    assign dequeue_data2 = ram[head_plus];



    // 闂傚倸鍊搁崐宄懊归崶褉鏋栭柡鍥ュ灩缁愭骞栧ǎ顒€鈧垶绂嶈ぐ鎺撶厪濠电偟鍋撳▍鍛繆椤愶缉鎴﹢�Φ閸曨垰绠绘い鏍ㄤ緱濞兼垿姊洪崫銉ユ��婵炲樊鍙冨濠氭偄閸撳弶效闁硅偐琛ラ埀顒€鍟跨粻锝夋⒒娴ｈ姤銆冮柣鎺炵畵楠炴垿宕惰閸ゆ洘銇勯幒鎴濐仼閸ユ挳姊虹化鏇炲⒉妞ゃ劌绻戠€靛ジ骞樼紒妯锋嫽婵炶揪缍€婵倗娑甸崼鏇熺厱闁绘ê鍟挎慨宥団偓娈垮枛閹诧紕鎹㈠┑鍡╂僵妞ゆ帒鍋嗛崬鐢告⒒娴ｈ櫣甯涢柛銊ュ悑閹便劑濡舵径濠勬煣闂佸綊妫块悞锕傛偂濞戙垺鐓曢悘鐐扮畽椤忓牆鐒垫い鎺嶈兌婢ч亶鏌嶈閸撴岸鎳濋崜褏绀婂┑鐘叉搐閽冪喖鏌曟繛鐐珕闁�?��伴弻锝夊煛閸屾岸鍤嬬紓浣哄У閹瑰洤顕ｉ锕€绠涙い鏍ㄧ矌閺夋悂姊洪崫鍕偓褰掝敄濞嗘劕顕遍柟鍓х帛閳锋帒霉閿濆牆袚缁绢厼鐖奸弻娑㈡偐閸愭彃顫掗悗娈垮枛閹诧紕鎹㈠┑鍡╂僵妞ゆ帒鍋嗛崬鐢告⒒娴ｈ櫣甯涢柛銊ュ悑閹便劑濡舵径濠勬煣闂佸綊妫块悞锕傛偂濞戙垺鐓曢悘鐐扮畽椤忓牆鐒垫い鎺嶈兌婢ч亶鏌嶈閸撴岸鎳濋崜褏绀婂┑鐘叉搐閽冪喖鏌曟繛鐐珕闁�?��妴鎺戭潩閻撳海浠ч梺姹囧労娴滅偟妲愰幒鏃傜＜闁靛繒濮寸猾宥夋⒑鐞涒€充壕闁哄鐗冮弬渚€宕戦幘鎰佹僵闁绘劦鍓欓锟�?
    wire stall;
    assign stall = (head == (tail + 3) % `DEPTH);
    assign full = (head == (tail_plus + 1) % `DEPTH) || (head == tail_plus);
    assign empty = (head == tail) || (head == tail_plus);

    assign get_data_req = !(stall || full);

endmodule