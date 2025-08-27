`timescale 1ps/1ps

module front
(
    input wire cpu_clk,
    input wire cpu_rst,
    // 閿熸枻鎷烽敓鏂ゆ嫹 icache 閿熸枻鎷烽敓鏂ゆ嫹??
    input wire       pi_icache_is_exception1,            //鎸囬敓绛嬬紦閿熸枻鎷烽敓灞婂父閿熻剼鐚存嫹
    input wire       pi_icache_is_exception2,          
    input wire [6:0] pi_icache_exception_cause1,    //鎸囬敓绛嬬紦閿熸枻鎷烽敓灞婂父鍘熼敓鏂ゆ嫹
    input wire [6:0] pi_icache_exception_cause2,
    input wire [31:0] pc_for_buffer1,               //pc閿熸枻鎷锋寚閿熺瓔缂撻敓鏂ゆ嫹閿熸枻鎷疯棔閿燂拷
    input wire [31:0] pc_for_buffer2,               
    input wire [31:0] pred_addr1_for_buffer,
    input wire [31:0] pred_addr2_for_buffer,
    input wire [1:0] pred_taken_for_buffer,
    input wire icache_pc_suspend,
    input wire [31:0] inst_for_buffer1,
    input wire [31:0] inst_for_buffer2,
    input wire icache_inst_valid1,       //鎸囬敓绛嬬紦閿熸枻鎷烽敓缁炵櫢鎷烽敓鏂ゆ嫹閿燂拷??
    input wire icache_inst_valid2,
    input wire icache_valid_in,

    //*******************
    input wire [1:0] fb_flush,
    input wire [1:0] fb_pause,
    input wire fb_interrupt,            //閿熷彨璁规嫹閿熻剼鍙凤綇鎷烽敓鏂ゆ嫹閿熺煫浼欐嫹鐜敓鏂ゆ嫹閿熸枻鎷烽敓锟�??
//    input wire [31:0] fb_new_pc,        //閿熷彨鏂尨鎷烽敓閾扮鎷穚c閿熸枻鎷峰潃
    
    //閿熸枻鎷穒cache閿熶茎鏂ゆ嫹??
    output wire BPU_flush,
    output reg [31:0] pi_pc1,                //鍓嶉敓鍓块潻鎷穒cache閿熸枻鎷穚c閿熸枻鎷峰潃
    output reg [31:0] pi_pc2,
    output wire [31:0] if_pred_addr1,
    output wire [31:0] if_pred_addr2,
    output wire [1:0] pred_taken,
    output wire inst_rreq_to_icache,            //鍓嶉敓鍓块潻鎷穒cache閿熸枻鎷锋寚閿熸枻鎷蜂娇閿熸枻鎷烽敓鏂ゆ嫹??
    output reg pi_is_exception,             //鍓嶉敓鍓块潻鎷穒cache閿熸枻鎷烽敓灞婂父閿熸枻鎷�??
    output reg [6:0] pi_exception_cause,    //鍓嶉敓鍓块潻鎷穒cache閿熸枻鎷烽敓灞婂父鍘�??

    //閿熸枻鎷穊ackend閿熶茎鏂ゆ嫹??
    output wire fb_pred_taken1,
    output wire fb_pred_taken2,
    output wire [31:0] fb_pc_out1,              //鍓嶉敓鍓块潻鎷烽敓鏂ゆ嫹璇撮敓绲閿熸枻鎷峰潃
    output wire [31:0] fb_pc_out2,              
    output wire [31:0] fb_inst_out1,            //鍓嶉敓鍓块潻鎷烽敓鏂ゆ嫹璇撮敓琛楅潻鎷烽敓锟�
    output wire [31:0] fb_inst_out2,           
    output wire [1:0] fb_valid,                           //鍓嶉敓鍓块潻鎷烽敓鏂ゆ嫹璇撮敓琛楅潻鎷烽敓缁炵櫢鎷烽敓鏂ゆ嫹钘曢敓锟�
    output wire [31:0] fb_pre_branch_addr1,         //鍓嶉敓鍓块潻鎷烽敓鏂ゆ嫹璇村閿熻褝鎷烽敓琛楋拷
    output wire [31:0] fb_pre_branch_addr2,

    output wire [1:0] fb_is_exception1,                 // 閿熸枻鎷蜂竴閿熸枻鎷锋寚閿熸枻鎷烽敓瑙掑嚖鎷烽敓鏂ゆ嫹??
    output wire [6:0] fb_pc_exception_cause1,           // 閿熸枻鎷蜂竴閿熸枻鎷锋寚閿熸枻鎷烽敓鏂ゆ嫹pc閿熸枻鎷烽敓灞婂父鍘�??
    output wire [6:0] fb_instbuffer_exception_cause1,   // 閿熸枻鎷蜂竴閿熸枻鎷锋寚閿熸枻鎷烽敓鏂ゆ嫹instbuffer閿熸枻鎷烽敓灞婂父鍘�??
    
    output wire [1:0] fb_is_exception2,               
    output wire [6:0] fb_pc_exception_cause2,
    output wire [6:0] fb_instbuffer_exception_cause2,



    //閿熸枻鎷烽敓閾板姞纰夋嫹閿熻剼鐚存嫹**************************
    input  wire [31:0]          new_pc,
    input  wire [1:0]           ex_is_bj ,          // 閿熸枻鎷烽敓鏂ゆ嫹鎸囬敓鏂ゆ嫹閿熻鍑ゆ嫹閿熸枻鎷烽敓鏂ゆ嫹杞寚??
    input  wire [31:0]          ex_pc1 ,            // ex 閿熼樁璁规嫹?? pc
    input  wire [31:0]          ex_pc2 ,             
    input  wire [1:0]           ex_valid ,        
    input  wire [1:0]           real_taken ,        // 閿熸枻鎷烽敓鏂ゆ嫹鎸囬敓鏂ゆ嫹瀹為敓鏂ゆ嫹閿熻鍑ゆ嫹閿熸枻鎷疯浆
    input  wire [31:0]          real_addr1 ,        // 閿熸枻鎷烽敓鏂ゆ嫹鎸囬敓鏂ゆ嫹瀹為敓鏂ゆ嫹閿熸枻鎷疯浆閿熸枻鎷峰潃
    input  wire [31:0]          real_addr2 ,
    input  wire [31:0]          pred_addr1 ,         // 閿熸枻鎷烽敓鏂ゆ嫹鎸囬敓鏂ゆ嫹棰勯敓鏂ゆ嫹閿熸枻鎷疯浆閿熸枻鎷峰潃
    input  wire [31:0]          pred_addr2 ,
    input  wire                 get_data_req     
    //*************************************
);
    reg [1:0] is_branch;            // 閿熸枻鎷烽敓鐭紮鎷风帿閿熸枻鎷烽敓锟�??
    wire [31:0] pre_addr;
    wire [31:0] pc_out1;
    wire [31:0] pc_out2;
    wire is_exception;
    wire [6:0] exception_cause;
    reg inst_en1;           // 閿熸枻鎷烽敓鐭紮鎷风帿閿熸枻鎷烽敓锟�??
    reg inst_en2;           // 閿熸枻鎷烽敓鐭紮鎷风帿閿熸枻鎷烽敓锟�??
    //閿熸枻鎷烽敓閾板姞纰夋嫹閿熻剼鐚存嫹**********************************
    wire instbuffer_stall;      // 閿熸枻鎷烽敓鐭紮鎷风帿閿熸枻鎷烽敓锟�??
    wire [105:0] data_out1;
    wire [105:0] data_out2;
    
    wire BPU_pred_taken;
    //***************************************
    assign fb_pred_taken1 = data_out1[104];
    assign fb_pred_taken2 = data_out2[104];
    assign fb_pre_branch_addr1 = data_out1[103:72];
    assign fb_pre_branch_addr2 = data_out2[103:72];
    assign fb_pc_out1 = data_out1[71:40];
    assign fb_pc_out2 = data_out2[71:40];
    assign fb_inst_out1 = data_out1[39:8];
    assign fb_inst_out2 = data_out2[39:8];
    assign fb_is_exception1 = {data_out1[7], 1'b0};
    assign fb_is_exception2 = {data_out2[7], 1'b0};
    assign fb_pc_exception_cause1 = data_out1[6:0];
    assign fb_pc_exception_cause2 = data_out2[6:0];
    assign fb_instbuffer_exception_cause1 = 7'b1111111;
    assign fb_instbuffer_exception_cause2 = 7'b1111111;

    //********************************
    always @(*) 
    begin
        pi_pc1 = pc_out1;
        pi_pc2 = pc_out2;
        pi_is_exception = is_exception;
        pi_exception_cause = exception_cause;
    end

    assign BPU_pred_taken = pred_taken[0] | pred_taken[1];
    
    wire stall;
    
    pc u_pc 
    (
        .clk(cpu_clk),
        .rst(cpu_rst),    
        .stall(stall),
        .flush(fb_flush[0]),
        .new_pc(new_pc),       //閿熸枻鎷烽敓锟�??瑕侀敓鏂ゆ嫹??閿熸枻鎷烽敓鑴氱尨鎷�???閿熸枻鎷烽敓鏂ゆ嫹閿熸枻鎷烽敓鏂ゆ嫹pc閿熸枻鎷锋簮閿熷彨璁规嫹閿熸枻鎷積x閿熼樁娈靛嚖鎷锋敮棰勯敓鏂ゆ嫹閿熸枻鎷疯瀰顑嶉敓鏂ゆ嫹鐜敓鏂ゆ嫹閿熸枻鎷烽敓鏂ゆ嫹閿熶茎鍖℃嫹閿熺掸c閿熸枻鎷烽敓鏂ゆ嫹閿熸枻鎷烽敓鏂ゆ嫹閿熻В锛岄敓鏂ゆ嫹閿熸枻鎷烽敓瑙ｅ閿熸枻鎷烽敓鏂ゆ嫹閿熸枻鎷烽敓渚モ敧璇ф嫹閿熸枻鎷烽敓鎻亷鎷锋皭閿熸枻鎷烽敓鏂ゆ嫹閿熻緝纰夋嫹閿熸枻鎷烽敓琛楋拷??
        .pause(fb_pause[0] | icache_pc_suspend),
        .pre_addr(pre_addr),  
        .pred_taken(pred_taken[0] | pred_taken[1]),  
        .pc_out1(pc_out1),
        .pc_out2(pc_out2),
        .pc_is_exception(is_exception),
        .pc_exception_cause(exception_cause),
        .inst_rreq_to_icache(inst_rreq_to_icache)
    );

    wire ex_valid1 = ex_valid[0];
    wire ex_valid2 = ex_valid[1];
    wire BPU_pred_taken1;
    wire BPU_pred_taken2;
    assign pred_taken = {BPU_pred_taken2,BPU_pred_taken1};
    
    BPU u_BPU
    (
        .cpu_clk(cpu_clk),
        .cpu_rstn(cpu_rst),    //low active???
        .if_pc1(pc_out1),
        .if_pc2(pc_out2),

        .pred_taken1(BPU_pred_taken1),
        .pred_taken2(BPU_pred_taken2),
        .pred_addr(pre_addr),
        .if_pred_addr1(if_pred_addr1),
        .if_pred_addr2(if_pred_addr2),

        .BPU_flush(BPU_flush),
//        .new_pc(new_pc),

        .ex_is_bj_1(ex_is_bj[0]),     //閿熼ズ鐚存嫹鐑侀敓鏂ゆ嫹涓氶敓鏂ゆ嫹钘曠墰閿熺禍x閿熼樁娈电鎷锋寚閿熸枻鎷烽敓瑙掑嚖鎷烽敓鏂ゆ嫹閿熸枻鎷疯浆鎸囬敓鏂ゆ嫹
        .ex_pc_1(ex_pc1),
        .ex_valid1(ex_valid1),
        .ex_is_bj_2(ex_is_bj[1]),
        .ex_pc_2(ex_pc2),
        .ex_valid2(ex_valid2),
        .real_taken1(real_taken[0]),
        .real_taken2(real_taken[1]),
        .real_addr1(real_addr1),
        .real_addr2(real_addr2),
        .pred_addr1(pred_addr1),
        .pred_addr2(pred_addr2)
    );

    instbuffer u_instbuffer 
    (
        .clk(cpu_clk),
        .rst(cpu_rst),
        .flush(fb_flush[1]),
        .get_data_req(get_data_req),   //閿熸枻鎷穒nstbuffer閿熸枻鎷烽敓鏂ゆ嫹钘曢敓绲爊stbuffer閿熻剼浼欐嫹閿熸枻鎷烽敓鏂ゆ嫹閿熸枻鎷烽敓绲爊st閿熸枻鎷烽敓灞婃閿熸枻鎷�??
        .inst_valid1(icache_inst_valid1),
        .inst_valid2(icache_inst_valid2),
        .icache_valid_in(icache_valid_in),
        .pc1(pc_for_buffer1),
        .pc2(pc_for_buffer2),

        .inst1(inst_for_buffer1),
        .inst2(inst_for_buffer2),
        .pred_addr1(pred_addr1_for_buffer),
        .pred_addr2(pred_addr2_for_buffer),
        .pred_taken(pred_taken_for_buffer),

        .pc_is_exception_in1(pi_icache_is_exception1),
        .pc_is_exception_in2(pi_icache_is_exception2),
        .pc_exception_cause_in1(pi_icache_exception_cause1),
        .pc_exception_cause_in2(pi_icache_exception_cause2),
        .data_out1(data_out1),

        .data_out2(data_out2),
        .data_valid(fb_valid),

        .stall(stall)
    );


endmodule