`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module CU
(
    input  wire        rst,

    input  wire        pause_buffer,//浠庡墠绔緭锟�?
    input  wire        pause_decode,//浠巇ecoder杈撳叆
    input  wire        pause_dispatch,//浠巇ispatch杈撳叆
    input  wire        pause_execute,//浠巈xecute杈撳叆
    input  wire        pause_mem,//浠巑em杈撳叆

    input  wire        branch_flush,//鍒嗘敮璺宠浆鍒锋柊淇″彿
    input  wire [31:0] branch_target,//鍒嗘敮璺宠浆鍦板潃锛屼粠execute闃舵杈撳叆 
    input  wire        ex_excp_flush,//寮傚父鍒锋柊淇″彿,浠巈xecute闃舵杈撳叆

    //wb闃舵杈撳叆wb
    input  wire [1:0]        reg_write_en_i,//鍐欏洖闃舵鍒锋柊淇″彿
    input  wire [4:0]        reg_write_addr1_i,//鍐欏洖闃舵瀵勫瓨鍣ㄥ湴锟�?
    input  wire [4:0]        reg_write_addr2_i,//鍐欏洖闃舵瀵勫瓨鍣ㄥ湴锟�?
    input  wire [31:0]       reg_write_data1_i,//鍐欏洖闃舵瀵勫瓨鍣ㄦ暟锟�?
    input  wire [31:0]       reg_write_data2_i,//鍐欏洖闃舵瀵勫瓨鍣ㄦ暟锟�?
    input  wire [1:0]        is_llw_scw_i,//鏄惁锟�? llw/scw 鎸囦护
    input  wire [1:0]        csr_write_en_i,//csr鍐欎娇鑳戒俊锟�?
    input  wire [13:0]       csr_write_addr1_i,//csr鍐欏湴锟�?
    input  wire [13:0]       csr_write_addr2_i,//csr鍐欏湴锟�?
    input  wire [31:0]       csr_write_data1_i,//csr鍐欐暟锟�?
    input  wire [31:0]       csr_write_data2_i,//csr鍐欐暟锟�?

    //浠巜b闃舵杈撳叆commit
    input wire  [5:0]  is_exception1_i,
    input wire  [5:0]  is_exception2_i,
    input wire  [6:0]  pc_exception_cause1_i,
    input wire  [6:0]  pc_exception_cause2_i, 
    input wire  [6:0]  instbuffer_exception_cause1_i,
    input wire  [6:0]  instbuffer_exception_cause2_i,
    input wire  [6:0]  decoder_exception_cause1_i,
    input wire  [6:0]  decoder_exception_cause2_i,
    input wire  [6:0]  dispatch_exception_cause1_i,
    input wire  [6:0]  dispatch_exception_cause2_i,
    input wire  [6:0]  execute_exception_cause1_i,
    input wire  [6:0]  execute_exception_cause2_i,
    input wire  [6:0]  commit_exception_cause1_i,
    input wire  [6:0]  commit_exception_cause2_i,

    input  wire [31:0]       pc1_i,
    input  wire [31:0]       pc2_i,
    input  wire [31:0]       refetch_target_pc_i,
    input  wire [31:0]       mem_addr1_i,
    input  wire [31:0]       mem_addr2_i,
    input  wire [1:0]        is_idle_i,//鏄惁澶勪簬绌洪棽鐘讹拷??
    input  wire [1:0]        is_ertn_i,//鏄惁鏄紓甯歌繑鍥炴寚锟�?
    input  wire [1:0]        is_privilege_i,//鏄惁鏄壒鏉冩寚锟�?
    input  wire [1:0]        icacop_en_i,
    input  wire [1:0]        valid_i,//鎸囦护鏄惁鏈夋晥
    //csr
    output wire              is_ertn_o,//鏄惁鏄紓甯歌繑鍥炴寚锟�?
    //
    output wire [7:0]  flush,//鍒锋柊淇″彿
    output wire [7:0]  pause,//鏆傚仠淇″彿
    output wire [31:0] new_pc,//鏂扮殑PC鍦板潃

    //to regfile
    output reg  [1:0]  reg_write_en_o,//鍐欏洖闃舵鍒锋柊淇″彿
    output reg  [4:0]  reg_write_addr1_o,//鍐欏洖闃舵瀵勫瓨鍣ㄥ湴锟�?
    output reg  [4:0]  reg_write_addr2_o,//鍐欏洖闃舵瀵勫瓨鍣ㄥ湴锟�?
    output reg  [31:0] reg_write_data1_o,//鍐欏洖闃舵瀵勫瓨鍣ㄦ暟锟�?
    output reg  [31:0] reg_write_data2_o,//鍐欏洖闃舵瀵勫瓨鍣ㄦ暟锟�?

    //to csr
    output wire is_llw_scw_o,//鏄惁锟�? llw/scw 鎸囦护
    output wire  csr_write_en_o,//csr鍐欎娇鑳戒俊锟�?
    output wire [13:0] csr_write_addr_o,//csr鍐欏湴锟�?
    output wire [31:0] csr_write_data_o,//csr鍐欐暟锟�?

    // with csr
    input wire [31:0] csr_eentry_i, //寮傚父鍏ュ彛鍦板潃
    input wire [31:0] csr_era_i, //寮傚父杩斿洖鍦板潃
    input wire [31:0] csr_crmd_i, //鎺у埗瀵勫瓨锟�? 
    input wire        csr_is_interrupt_i, //鏄惁鏄腑锟�?
    
    output wire        csr_is_exception_o, //鏄惁鏄紓锟�?
    output wire [31:0] csr_exception_pc_o, //寮傚父PC鍦板潃
    output wire [31:0] csr_exception_addr_o, //寮傚父鍦板潃
    output reg  [5:0]  csr_ecode_o, //寮傚父ecode
    output wire [6:0]  csr_exception_cause_o, //寮傚父鍘熷洜
    output reg  [8:0]  csr_esubcode_o //寮傚父瀛愮爜

);
    //ertn
    wire ertn_flush;
    assign ertn_flush = is_ertn_i[0]; //涓轰粈涔堝彧瑕佺0鏉℃寚锟�?
    assign is_ertn_o = ertn_flush;

    //鏂扮殑target,refetch閲嶆柊鍙栧潃锟�?
    wire refetch_flush;
    wire [31:0] refetch_target;
    assign refetch_target = refetch_target_pc_i; 
    reg [1:0] is_exception;
    assign new_pc = (|is_exception) ? csr_eentry_i : (ertn_flush ? csr_era_i : (refetch_flush ? refetch_target : branch_target));

    always @(*) begin
        is_exception[0] = valid_i[0] && (is_exception1_i != 6'b0 || csr_is_interrupt_i);
        is_exception[1] = valid_i[1] && (is_exception2_i != 6'b0 || csr_is_interrupt_i);
    end

    assign csr_is_exception_o = |is_exception;

    // cacop
    wire icacop_flush;
    assign icacop_flush =  (icacop_en_i[0] & valid_i[0]) || (icacop_en_i[1] & valid_i[1]);

    //璁剧疆鍚戦噺flush
    // flush[0] PC, flush[1] icache, flush[2] instbuffer, flush[3] id
    // flush[4] dispatch, flush[5] ex, flush[6] mem, flush[7] wb
    wire flush_ex_mem = |is_exception || ertn_flush || refetch_flush;
    wire flush_id_dispatch = |is_exception || ertn_flush || branch_flush || ex_excp_flush || refetch_flush;
    wire flush_buffer_icache_pc = |is_exception || ertn_flush || branch_flush || refetch_flush;
    assign flush = {
        1'b0,
        flush_ex_mem,   //mem
        flush_ex_mem,   //ex
        flush_id_dispatch,  //dispatch
        flush_id_dispatch, //id
        flush_buffer_icache_pc,     //instbuffer
        flush_buffer_icache_pc,     //icache
        flush_buffer_icache_pc    //pc
    };

    always @(*) begin
        reg_write_addr1_o = reg_write_addr1_i;
        reg_write_addr2_o = reg_write_addr2_i;
        reg_write_data1_o = reg_write_data1_i;
        reg_write_data2_o = reg_write_data2_i;
    end

    wire [1:0] reg_write_en_out;
    assign reg_write_en_out[0] = (is_exception[0] || pause[7]) ? 1'b0 : reg_write_en_i[0];
    assign reg_write_en_out[1] = (|is_exception || pause[7]) ? 1'b0 : reg_write_en_i[1];

    always @(*) begin
        if(reg_write_addr1_i == reg_write_addr2_i) begin
            reg_write_en_o[0] = 1'b0;
            reg_write_en_o[1] = reg_write_en_out[1];
        end
        else begin
            reg_write_en_o[0] = reg_write_en_out[0];
            reg_write_en_o[1] = reg_write_en_out[1];
        end
    end

    assign is_llw_scw_o = |is_exception ? 1'b0 : (is_llw_scw_i[0] | is_llw_scw_i[1]);
    assign csr_write_en_o = |is_exception ? 1'b0 : (csr_write_en_i[0] | csr_write_en_i[1]);
    assign csr_write_addr_o = (csr_write_en_i[0] ? csr_write_addr1_i : csr_write_addr2_i);
    assign csr_write_data_o = (csr_write_en_i[0] ? csr_write_data1_i : csr_write_data2_i);
    assign refetch_flush = csr_write_en_o;

    assign csr_exception_pc_o = is_exception[0] ? pc1_i : pc2_i;
    assign csr_exception_addr_o = is_exception[0] ? mem_addr1_i : mem_addr2_i;

    //寮傚父閫犳垚鐨勫師锟�?
    reg  [6:0] exception_cause1;
    reg  [6:0] exception_cause2;

    wire [5:0] inst_is_exception1;
    wire [5:0] inst_is_exception2;

    assign inst_is_exception1 = is_exception1_i;
    assign inst_is_exception2 = is_exception2_i;

    wire [6:0] inst_exception_cause1 [5:0]; 
    wire [6:0] inst_exception_cause2 [5:0];
    assign inst_exception_cause1 [0] = commit_exception_cause1_i;
    assign inst_exception_cause1 [1] = execute_exception_cause1_i;
    assign inst_exception_cause1 [2] = dispatch_exception_cause2_i;
    assign inst_exception_cause1 [3] = decoder_exception_cause1_i;
    assign inst_exception_cause1 [4] = instbuffer_exception_cause1_i; 
    assign inst_exception_cause1 [5] = pc_exception_cause1_i;
    assign inst_exception_cause2 [0] = commit_exception_cause2_i;
    assign inst_exception_cause2 [1] = execute_exception_cause2_i;
    assign inst_exception_cause2 [2] = dispatch_exception_cause2_i;
    assign inst_exception_cause2 [3] = decoder_exception_cause2_i;
    assign inst_exception_cause2 [4] = instbuffer_exception_cause2_i;
    assign inst_exception_cause2 [5] = pc_exception_cause2_i;

    wire [6:0] excp_vec1;
    wire [6:0] excp_vec2;
    assign excp_vec1 = {csr_is_interrupt_i, inst_is_exception1};
    assign excp_vec2 = {csr_is_interrupt_i, inst_is_exception2};

    always @(*) begin
        casez(excp_vec1) 
            7'b1??????: exception_cause1 = `EXCEPTION_INT; 
            7'b01?????: exception_cause1 = inst_exception_cause1[5]; 
            7'b001????: exception_cause1 = inst_exception_cause1[4];
            7'b0001???: exception_cause1 = (is_privilege_i[0] && csr_crmd_i[1:0] != 2'b00) ? `EXCEPTION_IPE : inst_exception_cause1[3];
            7'b00001??: exception_cause1 = inst_exception_cause1[2];
            7'b000001?: exception_cause1 = inst_exception_cause1[1];
            7'b0000001: exception_cause1 = inst_exception_cause1[0];
            default:    exception_cause1 = `EXCEPTION_NOP; 
        endcase
    end
    /*
    always @(*) 
    begin
        if (excp_vec1[6])       exception_cause1 = `EXCEPTION_INT; 
        else if (excp_vec1[5])  exception_cause1 = inst_exception_cause1[5]; 
        else if (excp_vec1[4])  exception_cause1 = inst_exception_cause1[4];
        else if (excp_vec1[3])  exception_cause1 = (is_privilege_i[0] && csr_crmd_i[1:0] != 2'b00) ? `EXCEPTION_IPE : inst_exception_cause1[3];
        else if (excp_vec1[2])  exception_cause1 = inst_exception_cause1[2];
        else if (excp_vec1[1])  exception_cause1 = inst_exception_cause1[1];
        else if (excp_vec1[0])  exception_cause1 = inst_exception_cause1[0];
        else                    exception_cause1 = `EXCEPTION_NOP; 
    end
*/
    always @(*) begin
        casez(excp_vec2) 
            7'b1??????: exception_cause2 = `EXCEPTION_INT; 
            7'b01?????: exception_cause2 = inst_exception_cause2[5]; 
            7'b001????: exception_cause2 = inst_exception_cause2[4];
            7'b0001???: exception_cause2 = (is_privilege_i[1] && csr_crmd_i[1:0] != 2'b00) ? `EXCEPTION_IPE : inst_exception_cause2[3];
            7'b00001??: exception_cause2 = inst_exception_cause2[2];
            7'b000001?: exception_cause2 = inst_exception_cause2[1];
            7'b0000001: exception_cause2 = inst_exception_cause2[0];
            default:    exception_cause2 = `EXCEPTION_NOP; 
        endcase
    end
  
    /*
    always @(*) 
    begin
    if (excp_vec2[6]) exception_cause2 = `EXCEPTION_INT;  // 锟�?楂樹紭鍏堢骇锛坆it6=1锟�?
    else if (excp_vec2[5]) exception_cause2 = inst_exception_cause2[5];  // 娆￠珮浼樺厛绾э紙bit5=1锟�?
    else if (excp_vec2[4]) exception_cause2 = inst_exception_cause2[4];  // bit4=1
    else if (excp_vec2[3]) exception_cause2 = (is_privilege_i[1] && csr_crmd_i[1:0] != 2'b00) ? `EXCEPTION_IPE : inst_exception_cause2[3];
    else if (excp_vec2[2]) exception_cause2 = inst_exception_cause2[2];  // bit2=1
    else if (excp_vec2[1]) exception_cause2 = inst_exception_cause2[1];  // bit1=1
    else if (excp_vec2[0]) exception_cause2 = inst_exception_cause2[0];  // bit0=1
    else exception_cause2 = `EXCEPTION_NOP;  // 榛樿鎯呭喌锛堟棤寮傚父锟�?
    end
*/
    //寮傚父鍘熷洜缂栫爜
    wire [6:0] exception_cause_out;
    assign exception_cause_out = is_exception[0] ? exception_cause1 : exception_cause2;
    assign csr_exception_cause_o = exception_cause_out;

    always @(*) begin
        case (exception_cause_out)
             `EXCEPTION_INT: begin
                csr_ecode_o = 6'h0;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_PIL: begin
                csr_ecode_o = 6'h1;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_PIS: begin
                csr_ecode_o = 6'h2;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_PIF: begin
                csr_ecode_o = 6'h3;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_PME: begin
                csr_ecode_o = 6'h4;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_PPI: begin
                csr_ecode_o = 6'h7;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_ADEF: begin
                csr_ecode_o = 6'h8;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_ADEM: begin
                csr_ecode_o = 6'h8;
                csr_esubcode_o = 9'b1;
            end
            `EXCEPTION_ALE: begin
                csr_ecode_o = 6'h9;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_SYS: begin
                csr_ecode_o = 6'hb;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_BRK: begin
                csr_ecode_o = 6'hc;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_INE: begin
                csr_ecode_o = 6'hd;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_IPE: begin
                csr_ecode_o = 6'he;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_FPD: begin
                csr_ecode_o = 6'hf;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_FPE: begin
                csr_ecode_o = 6'h12;
                csr_esubcode_o = 9'b0;
            end
            `EXCEPTION_TLBR: begin
                csr_ecode_o = 6'h3f;
                csr_esubcode_o = 9'b0;
            end
            default: begin
                csr_ecode_o = 6'h0;
                csr_esubcode_o = 9'b0;
            end
        endcase
    end

    //鏆傚仠pause
    wire pause_idle; //杩欎釜鏄痗ommit stage鐨刬dle鐘讹拷??
    assign pause_idle = is_idle_i[0] && !csr_is_interrupt_i;

    reg [4:0] pause_back;
    wire pause_buffer_temp;
    wire [1:0] pause_front;

    always @(*) begin
        if(pause_mem || pause_idle) begin
            pause_back = 5'b01111;
        end 
        else if (pause_execute) begin
            pause_back = 5'b00111;
        end 
        else if (pause_dispatch) begin
            pause_back = 5'b00011;
        end 
        else if (pause_decode) begin
            pause_back = 5'b00001;
        end 
        else begin
            pause_back = 5'b00000;
        end
    end

    assign pause_buffer_temp = pause_decode ? 1'b1 : 1'b0;
    assign pause_front = pause_buffer ? 2'b11 : 2'b00;

    assign pause = {pause_back, pause_buffer_temp, pause_front[1] && !flush[1], pause_front[0]};
endmodule