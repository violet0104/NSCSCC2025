module dcache
(
    input wire clk,
    input wire rst,
    //to CPU
    input wire ren,
    input wire [3:0] wen,
    input wire writen,
    input wire [31:0] vaddr,
    input wire [31:0] ret_data_paddr,
    input wire duncache_en,
    input wire [31:0] write_data,

    input wire dcacop_en,
    input wire [1:0] cacop_mode,
    input wire [31:0] cache_cacop_vaddr,
    input wire cache_axi_write_pre_ready,

    output reg [31:0] rdata,
    output reg rdata_valid,    // 闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鐑樻КPU闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲棘閵堝棗顏堕柡浣哥墦閺佹捇鎳樺顒€濞囬柨婵嗙箲鐎氬綊鏌ㄩ悢渚痪缁炬澘顦扮€氬綊鐛幎鑺ユ櫢闁哄倶鍊栫€氬湱绮堢弧濠che闂佽法鍠愰弸濠氬�????勬澘娅欓梺璺ㄥ枑閺嬪骞忛悜鑺ユ櫢闁哄�?�鍊栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲箲閸戙倗绉堕柟鍑ゆ??
    output wire dcache_ready,   

    //to write BUS
    input  wire         dev_wrdy,       // 闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悤鍌涘/闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢宄板缓閺夊牏鍋撶€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲棘閵堝棗顏堕柦妯绘礈婢т即鏌ㄩ悢鍛婄伄闁瑰嘲鍢茶ぐ銉╂煥閻斿搫鐝遍柡鍌樺€栫€氬綊鏌ㄩ悢铏瑰摵闁规儳鎳忕€氬綊鏌ㄩ悢鍛婄伄闁归鍏橀弫鎾绘晸閿燂??/闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬湱浠﹂柆宥嗘櫢闁哄倶鍊栫€氬綊鏌ㄩ悢鐑樸仧Cache闂佽法鍠愰弸濠氬�????勬澘鏅搁梺璺ㄥ枑閺嬪骞忛悜鑺ユ櫢闁哄�?�鍊栫€氾拷
    input  wire         write_finish,
    output reg  [ 3:0]  cpu_wen,        // 闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲棘閵堝棗顏堕梺璺ㄥ櫐閹凤拷/闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢宄板缓閻犲洤绉跺▍銏ゅ箯閻戣姤鏅搁柡鍌樺€栫€氬綊鎸婇弴銏℃櫢闁跨噦鎷??
    output reg  [31:0]  cpu_waddr,      // 闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲棘閵堝棗顏堕梺璺ㄥ櫐閹凤拷/闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢宄板缓閺夊牏鍋撶€氬綊鏌ㄩ悢娲绘晭闁跨噦鎷??
    output reg  [255:0] cpu_wdata,      // 闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲棘閵堝棗顏堕梺璺ㄥ櫐閹凤拷/闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢宄板缓閺夊牏鍋撶€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾绘晸閿燂??
    //to Read Bus
    input  wire         dev_rrdy,       // 闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氾拷/闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氳绂嶉埡鍛櫢闁哄倶鍊栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲棘閵堝棗顏堕柦妯绘礈婢т即鏌ㄩ悢鍛婄伄闁瑰嘲鍢茶ぐ銉╂煥閻斿搫鐝遍柡鍌樺€栫€氬綊鏌ㄩ悢铏瑰摵闁规儳鎳忕€氬綊鏌ㄩ悢鍛婄伄闁归鍏橀弫鎾绘晸閿燂??/闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬湱浠﹂柆宥嗘櫢闁哄倶鍊栫€氬綊鏌ㄩ悢鐑樸仧Cache闂佽法鍠嶉懠搴ｆ媼鐟欏嫬顏堕梺璺ㄥ枑閺嬪骞忛悜鑺ユ櫢闁�????鍊栫€氾�??
    output reg          cpu_ren,        // 闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲棘閵堝棗顏堕梺璺ㄥ櫐閹凤拷/闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氳绂嶉埡鍛櫢缂備胶鍋熷▍銏ゅ箯閻戣姤鏅搁柡鍌樺€栫€氬綊鎸婇弴銏℃櫢闁跨噦鎷??
    output reg  [31:0]  cpu_raddr,      // 闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲棘閵堝棗顏堕梺璺ㄥ櫐閹凤拷/闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氳绂嶉埡鍛櫢闁哄倶鍊栫€氬綊鏌ㄩ悢娲绘晭闁跨噦鎷??
    input  wire         dev_rvalid,     // 闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲棘閵堝棗顏??/闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲棘閵堝棗顏堕梺璺ㄥ枑閺嬪骞忛悜鑺ユ櫢闁告瑯鍊ゅ鍡楊伓闁芥ɑ娲熼弫鎾绘晸閿燂拷
    input  wire [255:0] dev_rdata,       // 闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲棘閵堝棗顏??/闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氳绂嶉埡鍛櫢闁哄倶鍊栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾绘晸閿燂??
    input  wire         ren_received,

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
    localparam REFILL = 3'b100;   //闁告劖鐟╅弫鎾诲棘閵堝棗顏堕梺璺ㄥ枑閺嬪骞忛悜鑺ユ櫢闁圭懓鍢插锟犳晬瀹€鍕櫢闁�????鍊栫€氳绋夐埢?顒勬煥閻斿憡鐏柟椋庘勘lk闂佽法鍠庢慨顓熸綇閻愵剙顏堕柛鎰嵁rite_data
    localparam UNCACHE = 3'b101;
    localparam CACOP = 3'b110;
    
    reg [2:0] state;
    reg [2:0] next_state;
    reg [1:0] dirty [127:0];
    reg use_bit [127:0];  //2'b10闂佽法鍠嶉懠搴ｅ枈婢跺顏跺☉鎾亾闂佽法鍠愰弸濠氬箯閿燂拷
    
    wire [31:0] vaddr_1 = vaddr;      
    wire [6:0] index_1 ;
    wire [2:0] offset_1 = vaddr[4:2];
    //闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悤鍌涘2闂佽法鍠愰弸濠氬箯妞嬪簺浠涢梺璺ㄥ枑閺嬪骞忛悜鑺ユ櫢闁�????鍊栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏橢?弫鎾诲棘閵堝棗顏堕梺璺ㄥ枔缁悂骞夌€ｎ偄顏堕梺璺ㄥ枑瑜邦喗瀵煎▎鎰伓闂佽法鍠撶粋濯梜
    reg [6:0] index_2;
    reg [31:0] paddr_2;
    reg [31:0] w_data_2;
    reg [3:0] wen_2;
    reg ren_2;
    reg req_2;
    reg writen_2;
    reg uncache_2;

    reg dcacop_en_2;
    reg [1:0] cacop_mode_2;
    reg [1:0] cacop_write_count;
    reg [1:0] cacop_target_count;
    reg cacop_mode0_3;
    reg cacop_we1;
    reg cacop_we2;

    //*****    try to fix write first problem
    reg we1_delay;
    reg we2_delay;
    reg [6:0] write_index_delay;
    reg [6:0] read_index_delay;
    reg [20:0] write_tag_delay;  //include valid
    reg [255:0] write_data_delay;
    //*****
    wire [255:0] data_block1;  
    wire [255:0] data_block2;  
    wire [255:0] data_block1_choose;   //delete write first in dcache ram
    wire [255:0] data_block2_choose;

    wire [20:0] ram_tag1;
    wire [20:0] ram_tag2;
    wire [20:0] ram_tag1_choose;      //delete write first in dcache ram
    wire [20:0] ram_tag2_choose;
    wire [2:0] offset_2 = paddr_2[4:2];
    wire [20:0] tag_2 = {1'b1,paddr_2[31:12]};
    wire is_load = ren_2;
    wire is_store = writen_2;
    wire hit1 = req_2 & (tag_2 == ram_tag1_choose);
    wire hit2 = req_2 & (tag_2 == ram_tag2_choose);
    wire hit = hit1 | hit2;
    wire dirty_index = use_bit[index_2];
    wire [255:0] hit_data = {256{hit1}}&data_block1_choose | {256{hit2}}&data_block2_choose;//
  
    wire write_dirty = !hit & req_2 & dirty[index_2][dirty_index];
    wire ask_mem = !hit & req_2 & !dirty[index_2][dirty_index];
    wire read_index_choose = next_state == IDLE;
    
    reg [255:0] attach_write_data;  //闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬湱鎲版担绋挎櫢闂佽法鍠愰弸濠氬箯缁屾竵m闂佽法鍠愰弸濠氬箯闁垮顏婚梺璺ㄥ枑閺嬪骞忛悜鑺ユ櫢闁�????鍊栫€氬綊宕掓繝姘櫢闁哄�?�鍊栫€氬綊鏌ㄩ悢鍛婄伄闁归鏌夎ぐ澶愭煥閻�???????
    reg [31:0] we1_choose;   //闂佽法鍠愰弸濠氬�????勬澘鏅�?ù锝呮健閺佹捇寮妶鍡楊伓闂佽法鍠愰弸濠氬箯閻戣姤鏅搁悹鍥跺亾缁辨繃绋夐埢?顒佹�????ュ鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鍛婄伄闁圭柉娓圭粩鎾煥閻斿憡鐏?柟椋庡厴閺佹挾鎮板Δ鍕濈痪鏉款槹鐎氬綊宕樺▎鎾存櫢闁�????鍊栫€氾�??
    reg [31:0] we2_choose;

    always @(*)
    begin
        case(offset_2)
        3'b000:attach_write_data = {224'b0,w_data_2};
        3'b001:attach_write_data = {192'b0,w_data_2,32'b0};
        3'b010:attach_write_data = {160'b0,w_data_2,64'b0};
        3'b011:attach_write_data = {128'b0,w_data_2,96'b0};
        3'b100:attach_write_data = {96'b0,w_data_2,128'b0};
        3'b101:attach_write_data = {64'b0,w_data_2,160'b0};
        3'b110:attach_write_data = {32'b0,w_data_2,192'b0};
        3'b111:attach_write_data = {w_data_2,224'b0};
        default:attach_write_data = 256'b0;
        endcase
    end
    
    assign index_1 = read_index_choose ? vaddr_1[11:5] : index_2;
    wire [255:0] write_ram_data = dev_rvalid ? dev_rdata : (attach_write_data & (we1_256 | we2_256)) | (hit_data & ~(we1_256 | we2_256));
    wire [20:0] write_ram_tag = dcacop_en_2 ? 21'b0 : tag_2;

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
            if(dcacop_en_2&(cacop_mode_2[1] == 1'b0 | hit & cacop_mode_2[1])) next_state = CACOP; //cacop_mode_2 == 1 | cacop_mode_2 == 0 | hit
            else if(uncache_2) next_state = UNCACHE;
            else if(write_dirty) next_state = DIRTY_WRITE;
            else if(ask_mem) next_state = ASKMEM;
            else next_state = IDLE;
        end
        ASKMEM:begin
            if(dev_rvalid) next_state = REFILL;
            else next_state = ASKMEM;
        end
        DIRTY_WRITE:begin 
            if(!write_dirty) next_state = ASKMEM;  //闂佽法鍠嶉懠搴ｇ驳鐟欏嫬顏禿ev_wrdy?
            else next_state = DIRTY_WRITE;
        end
        REFILL:begin
            next_state = IDLE;
        end
        UNCACHE:begin
            if(uncache_rvalid) next_state = IDLE;
            else if(uncache_write_finish) next_state = IDLE;
            else next_state = UNCACHE;
        end
        CACOP:begin//replace cacop_write_count == 1 & cacop_mode_2 == 2  by dirty[index_2]=0?
            if(cacop_mode0_3) next_state = IDLE;
            else if(dirty[index_2] == 2'b0 & cache_axi_write_pre_ready) next_state = IDLE;
            else next_state = CACOP;
        end
        default:next_state = IDLE;
        endcase
    end
    /*
        CACOP:begin//replace cacop_write_count == 1 & cacop_mode_2 == 2  by dirty[index_2]=0?
            if(cacop_mode0_3) next_state = IDLE;
            else if(dirty[index_2] == 2'b0 & cacop_mode_2 == 1 & cache_axi_write_pre_ready) next_state = IDLE;
            else if(dirty[index_2] == 2'b0 & cacop_mode_2 == 2 & cache_axi_write_pre_ready) next_state = IDLE;
            else next_state = CACOP;
        end
    */

    reg dealing;
    reg uncache_dealing;
    wire [255:0] we1_256;
    wire [255:0] we2_256;
    assign we1_256 = {
        {8{we1_choose[31]}},
        {8{we1_choose[30]}},
        {8{we1_choose[29]}},
        {8{we1_choose[28]}},
        {8{we1_choose[27]}},
        {8{we1_choose[26]}},
        {8{we1_choose[25]}},
        {8{we1_choose[24]}},
        {8{we1_choose[23]}},
        {8{we1_choose[22]}},
        {8{we1_choose[21]}},
        {8{we1_choose[20]}},
        {8{we1_choose[19]}},
        {8{we1_choose[18]}},
        {8{we1_choose[17]}},
        {8{we1_choose[16]}},
        {8{we1_choose[15]}},
        {8{we1_choose[14]}},
        {8{we1_choose[13]}},
        {8{we1_choose[12]}},
        {8{we1_choose[11]}},
        {8{we1_choose[10]}},
        {8{we1_choose[9]}},
        {8{we1_choose[8]}},
        {8{we1_choose[7]}},
        {8{we1_choose[6]}},
        {8{we1_choose[5]}},
        {8{we1_choose[4]}},
        {8{we1_choose[3]}},
        {8{we1_choose[2]}},
        {8{we1_choose[1]}},
        {8{we1_choose[0]}}
    };

    assign we2_256 = {
        {8{we2_choose[31]}},
        {8{we2_choose[30]}},
        {8{we2_choose[29]}},
        {8{we2_choose[28]}},
        {8{we2_choose[27]}},
        {8{we2_choose[26]}},
        {8{we2_choose[25]}},
        {8{we2_choose[24]}},
        {8{we2_choose[23]}},
        {8{we2_choose[22]}},
        {8{we2_choose[21]}},
        {8{we2_choose[20]}},
        {8{we2_choose[19]}},
        {8{we2_choose[18]}},
        {8{we2_choose[17]}},
        {8{we2_choose[16]}},
        {8{we2_choose[15]}},
        {8{we2_choose[14]}},
        {8{we2_choose[13]}},
        {8{we2_choose[12]}},
        {8{we2_choose[11]}},
        {8{we2_choose[10]}},
        {8{we2_choose[9]}},
        {8{we2_choose[8]}},
        {8{we2_choose[7]}},
        {8{we2_choose[6]}},
        {8{we2_choose[5]}},
        {8{we2_choose[4]}},
        {8{we2_choose[3]}},
        {8{we2_choose[2]}},
        {8{we2_choose[1]}},
        {8{we2_choose[0]}}
    };

    always @(posedge clk)
    begin
        if(rst)
        begin
            we1_delay <= 1'b0;
            we2_delay <= 1'b0;
            write_index_delay <= 7'b0;
            read_index_delay <= 7'b0;
            write_tag_delay <= 21'b0;
            write_data_delay <= 256'b0;

            cacop_mode0_3 <= 1'b0;
        end
        else 
        begin
            we1_delay <= we1;
            we2_delay <= we2;
            write_index_delay <= index_2;
            read_index_delay <= index_1;
            write_tag_delay <= write_ram_tag;
            write_data_delay <= (write_ram_data & (we1_256 | we2_256)) | (hit_data & ~(we1_256 | we2_256));

            cacop_mode0_3 <= dcacop_en_2 & (cacop_mode_2 == 2'b00);
        end
    end

    always @(posedge clk)
    begin
        if(rst)
        begin
            paddr_2 <= 32'b0;
            w_data_2 <= 32'b0;
            wen_2 <= 4'b0;
            writen_2 <= 1'b0;
            req_2 <= 1'b0;
            ren_2 <= 1'b0;
            index_2 <= 7'b0;
            cpu_wen <= 4'b0;
            cpu_ren <= 1'b0;
            cpu_waddr <= 32'b0;
            cpu_raddr <= 32'b0;
            cpu_wdata <= 256'b0;
            dealing <= 1'b0;
            uncache_dealing <= 1'b0;
            uncache_2 <= 1'b0;
            cacop_write_count <= 2'b0;
            cacop_target_count <= 2'b0;
            cacop_we1 <= 1'b0;
            cacop_we2 <= 1'b0;

            for(i=0;i<128;i=i+1)
            begin
                dirty[i] <= 2'b00;
            end
        end
        else if((next_state == IDLE) & (req_2 & hit | !req_2))  
        begin
            paddr_2 <= ret_data_paddr;                         
            uncache_2 <= duncache_en & (ren | writen);     
            w_data_2 <= write_data;
            wen_2 <= wen;
            ren_2 <= ren;
            writen_2 <= writen;
            req_2 <= ren | writen;
            index_2 <= index_1;
            uncache_dealing <= 1'b0;

            cacop_we1 <= 1'b0;
            cacop_we2 <= 1'b0;
            cacop_mode_2 <= cacop_mode;
            dcacop_en_2 <= dcacop_en;
            if(hit & is_store) 
            begin
                if(hit1) dirty[index_2][0] <= 1'b1;
                else dirty[index_2][1] <= 1'b1;
            end
        end
        else if(state == DIRTY_WRITE)   //闂佽法鍠愰弸濠氬箯閻戠晫鎽岄梺璺ㄥ枑閺嬪骞忛悜鑺ユ櫢缂�????鎸冲濠氬箯缁屽獘se
        begin
            if(dev_wrdy & !dealing)
            begin
                cpu_wen <= 4'b1111;
                cpu_waddr <= use_bit[index_2] ? {ram_tag2_choose[19:0],index_2,5'b0} : {ram_tag1_choose[19:0],index_2,5'b0};
                dealing <= 1'b1;
                dirty[index_2][dirty_index] <= 1'b0;
                if(use_bit[index_2]) cpu_wdata <= data_block2_choose;
                else cpu_wdata <= data_block1_choose;
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
                cpu_raddr <= paddr_2;
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
                req_2 <= 1'b0;
            end
            if(uncache_write_finish)
            begin
                uncache_2 <= 1'b0;
                wen_2 <= 4'b0;
                writen_2 <= 1'b0;
                req_2 <= 1'b0;
            end
            if(uncache_rvalid | uncache_write_finish) uncache_dealing <= 1'b0;
            else uncache_dealing <= 1'b1;
        end
        else if(state == IDLE)
        begin
            if(cacop_mode_2 == 2'b0 & dcacop_en_2)
            begin
                cacop_we1 <= 1'b1;
                cacop_we2 <= 1'b1;
            end
        end
        else if(state == CACOP)
        begin
            if(cacop_mode_2 == 2'b10)  //write and flush only when it is dirty?
            begin
                if(dev_wrdy & !dealing & dirty[index_2][hit2])
                begin
                    cpu_wen <= 4'b1111;
                    cacop_we1 <= hit1 & dirty[index_2][0];  //hit1 ? dirty[index_2][0] : 1'b0
                    cacop_we2 <= hit2 & dirty[index_2][1];
                    cpu_waddr <= {tag_2[19:0],index_2,5'b0};
                    dealing <= 1'b1;
                    dirty[index_2][hit2] <= 1'b0;   //if hit1 ,I should choose way1,the index is 0
                    cpu_wdata <= hit1 ? data_block1_choose : data_block2_choose;
                end
                else if(cpu_wen != 4'b0000) 
                begin
                    cpu_wen <= 4'b0000;
                    dealing <= 1'b0;
                    cacop_we1 <= 1'b0;
                    cacop_we2 <= 1'b0;
                end
            end
            else if(cacop_mode_2 == 2'b01)
            begin
                if(dev_wrdy & !dealing)
                begin
                    case(dirty[index_2])
                    2'b11:begin
                        cpu_waddr <= {ram_tag2_choose[19:0],index_2,5'b0};
                        cpu_wdata <= data_block2_choose;
                        dirty[index_2][1] <= 1'b0;
                        cacop_we1 <= 1'b0;
                        cacop_we2 <= 1'b1;
                        cpu_wen <= 4'b1111;
                        dealing <= 1'b1;
                    end
                    2'b10:begin
                        cpu_waddr <= {ram_tag2_choose[19:0],index_2,5'b0};
                        cpu_wdata <= data_block2_choose;
                        dirty[index_2][1] <= 1'b0;
                        cacop_we1 <= 1'b0;
                        cacop_we2 <= 1'b1;
                        cpu_wen <= 4'b1111;
                        dealing <= 1'b1;
                    end
                    2'b01:begin
                        cpu_waddr <= {ram_tag1_choose[19:0],index_2,5'b0};
                        cpu_wdata <= data_block1_choose;
                        dirty[index_2][0] <= 1'b0;
                        cacop_we1 <= 1'b1;
                        cacop_we2 <= 1'b0;
                        cpu_wen <= 4'b1111;
                        dealing <= 1'b1;
                    end
                    default:begin
                        cpu_waddr <= 32'b0;
                        cpu_wdata <= 256'b0;
                        cpu_wen <= 4'b0000;
                        cacop_we1 <= 1'b0;
                        cacop_we2 <= 1'b0;
                        dealing <= 1'b0;
                    end
                    endcase
                end
                else if(cpu_wen != 4'b0000) 
                begin
                    cpu_wen <= 4'b0000;
                    dealing <= 1'b0;
                    cacop_we1 <= 1'b0;
                    cacop_we2 <= 1'b0;
                end
            end
        end
    end
//
    reg [31:0] hit_data_word_choose; //闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氱ffset闂佽法鍠愰弸濠氬箯閻戣В鍋撴径鎰櫢闁�????鍊栫€氱ache闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柨鐕傛嫹4闂佽法鍠愰弸濠氬箯閻戣姤鏅搁柡鍌樺€栫€氬綊鏌ㄩ悢鍛婄伄闁归鍏�???弫鎾诲棘閵堝棗顏堕梺璺ㄥ枔閻�????鍩ラ崨顔碱伓闂佽法鍠愯ぐ顔藉濞嗘劕顏堕梺璺ㄥ櫐閹凤�??
    always @(*)
    begin
        case(offset_2)
        3'b000:hit_data_word_choose = hit_data[31:0];
        3'b001:hit_data_word_choose = hit_data[63:32];
        3'b010:hit_data_word_choose = hit_data[95:64];
        3'b011:hit_data_word_choose = hit_data[127:96];
        3'b100:hit_data_word_choose = hit_data[159:128];
        3'b101:hit_data_word_choose = hit_data[191:160];
        3'b110:hit_data_word_choose = hit_data[223:192];
        3'b111:hit_data_word_choose = hit_data[255:224];
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
            for(i=0;i<128;i=i+1)
            begin
                use_bit[i] <= 1'b0;
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
            if(hit1) use_bit[index_2] <= 1'b1;
            else use_bit[index_2] <= 1'b0;
        end
        else 
        begin
            rdata_valid <= 1'b0;
        end
    end

    wire we1 = (dev_rvalid & (!use_bit[index_2])) | (hit1 & is_store) | cacop_we1;
    wire we2 = (dev_rvalid & use_bit[index_2]) | (hit2 & is_store) | cacop_we2;

    always @(*)
    begin
        case(offset_2)
        3'b000:begin
            we1_choose = {32{dev_rvalid & (!use_bit[index_2])}} | ({32{(hit1 & is_store)}} & {28'b0,wen_2});
            we2_choose = {32{dev_rvalid &  (use_bit[index_2])}} | ({32{(hit2 & is_store)}} & {28'b0,wen_2});
        end
        3'b001:begin
            we1_choose = {32{dev_rvalid & (!use_bit[index_2])}} | ({32{(hit1 & is_store)}} & {24'b0,wen_2,4'b0});
            we2_choose = {32{dev_rvalid &  (use_bit[index_2])}} | ({32{(hit2 & is_store)}} & {24'b0,wen_2,4'b0});
        end
        3'b010:begin
            we1_choose = {32{dev_rvalid & (!use_bit[index_2])}} | ({32{(hit1 & is_store)}} & {20'b0,wen_2,8'b0});
            we2_choose = {32{dev_rvalid &  (use_bit[index_2])}} | ({32{(hit2 & is_store)}} & {20'b0,wen_2,8'b0});
        end
        3'b011:begin
            we1_choose = {32{dev_rvalid & (!use_bit[index_2])}} | ({32{(hit1 & is_store)}} & {16'b0,wen_2,12'b0});
            we2_choose = {32{dev_rvalid &  (use_bit[index_2])}} | ({32{(hit2 & is_store)}} & {16'b0,wen_2,12'b0});
        end
        3'b100:begin
            we1_choose = {32{dev_rvalid & (!use_bit[index_2])}} | ({32{(hit1 & is_store)}} & {12'b0,wen_2,16'b0});
            we2_choose = {32{dev_rvalid &  (use_bit[index_2])}} | ({32{(hit2 & is_store)}} & {12'b0,wen_2,16'b0});
        end
        3'b101:begin
            we1_choose = {32{dev_rvalid & (!use_bit[index_2])}} | ({32{(hit1 & is_store)}} & {8'b0,wen_2,20'b0});
            we2_choose = {32{dev_rvalid &  (use_bit[index_2])}} | ({32{(hit2 & is_store)}} & {8'b0,wen_2,20'b0});
        end
        3'b110:begin
            we1_choose = {32{dev_rvalid & (!use_bit[index_2])}} | ({32{(hit1 & is_store)}} & {4'b0,wen_2,24'b0});
            we2_choose = {32{dev_rvalid &  (use_bit[index_2])}} | ({32{(hit2 & is_store)}} & {4'b0,wen_2,24'b0});
        end
        3'b111:begin
            we1_choose = {32{dev_rvalid & (!use_bit[index_2])}} | ({32{(hit1 & is_store)}} & {wen_2,28'b0});
            we2_choose = {32{dev_rvalid & (use_bit[index_2])}} | ({32{(hit2 & is_store)}} & {wen_2,28'b0});
        end
        default:begin
            we1_choose = 32'b0;
            we2_choose = 32'b0;
        end
        endcase
    end

    assign ram_tag1_choose = (read_index_delay == write_index_delay)&we1_delay ? write_tag_delay : ram_tag1;
    assign ram_tag2_choose = (read_index_delay == write_index_delay)&we2_delay ? write_tag_delay : ram_tag2;
    assign data_block1_choose = (read_index_delay == write_index_delay)&we1_delay ? write_data_delay : data_block1;
    assign data_block2_choose = (read_index_delay == write_index_delay)&we2_delay ? write_data_delay : data_block2;
/*
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
    
*/
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

    dcache_dram data_ram2    //maybe I can set enable signal to make we shorter!!!!!!
    (                                 
        .clka(clk),
        .addra(index_2),
        .dina(write_ram_data),
        .wea(we2_choose),

        .clkb(clk),
        .addrb(index_1),
        .doutb(data_block2)
    );
    

    
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
    
    assign uncache_ren = (state == UNCACHE) & dev_rrdy & ren_2 & !uncache_rvalid;
    assign uncache_raddr = paddr_2;

    assign uncache_wen = (state == UNCACHE) & !uncache_write_finish & (!ren_2);
    assign uncache_wstrb = wen_2;
    assign uncache_waddr = paddr_2;
    assign uncache_wdata = w_data_2;

    //***************************************************
    reg [31:0] req_count;
    reg [31:0] hit_count;
    reg [31:0] uncache_count;
    reg data_rreq_delay;

    always @(posedge clk)
    begin
        if(rst)
        begin
            req_count <= 0;
            hit_count <= 0;
            uncache_count <= 0;
            data_rreq_delay <= 0;
        end
        else
        begin
            data_rreq_delay <= ren | writen;
            if(data_rreq_delay & hit) hit_count <= hit_count + 1;
            if(data_rreq_delay) req_count <= req_count + 1;
            if(duncache_en) uncache_count <= uncache_count + 1;
        end
    end
    //***************************************************
endmodule