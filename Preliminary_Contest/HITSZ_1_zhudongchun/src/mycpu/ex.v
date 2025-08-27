`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module ex (
    input wire clk,
    input wire rst,

    // / 锟斤拷锟斤拷ctrl锟斤拷锟斤拷???
    input wire flush,
    input wire pause,

    // 锟斤拷锟斤拷stable counter锟斤拷锟斤拷???
    input wire [63:0] cnt_i,

    // 锟斤拷锟斤拷dispatch锟斤拷锟斤拷???
    input wire [31:0] pc1_i,
    input wire [31:0] pc2_i,
    input wire soft1_i,
    input wire soft2_i,
    input wire [31:0] inst1_i,
    input wire [31:0] inst2_i,
    input wire [1:0] valid_i,

    input wire [3:0] is_exception1_i,
    input wire [3:0] is_exception2_i,
    input wire [6:0] pc_exception_cause1_i,     
    input wire [6:0] pc_exception_cause2_i,      
    input wire [6:0] instbuffer_exception_cause1_i,
    input wire [6:0] instbuffer_exception_cause2_i,
    input wire [6:0] decoder_exception_cause1_i,
    input wire [6:0] decoder_exception_cause2_i,
    input wire [6:0] dispatch_exception_cause1_i,
    input wire [6:0] dispatch_exception_cause2_i,

    input wire [1:0] is_privilege_i,

    input wire icacop_en1_i,
    input wire icacop_en2_i,
    input wire dcacop_en1_i,
    input wire dcacop_en2_i,
    input wire [4:0] cacop_opcode1_i,
    input wire [4:0] cacop_opcode2_i,

    input wire [7:0] aluop1_i,
    input wire [7:0] aluop2_i,
    input wire [2:0] alusel1_i,
    input wire [2:0] alusel2_i,

    input wire [1:0]  is_div_i,
    input wire [1:0]  is_mul_i,

    input wire [31:0] reg_data1_1_i,        // 锟侥达拷锟斤拷锟窖革拷锟斤拷锟侥碉拷1锟斤拷指锟斤拷锟�??????1锟斤拷源锟斤拷锟斤拷???
    input wire [31:0] reg_data1_2_i,        // 锟侥达拷锟斤拷锟窖革拷锟斤拷锟侥碉拷1锟斤拷指锟斤拷锟�??????2锟斤拷源锟斤拷锟斤拷???
    input wire [31:0] reg_data2_1_i,        // 锟侥达拷锟斤拷锟窖革拷锟斤拷锟侥碉拷2锟斤拷指锟斤拷锟�??????1锟斤拷源锟斤拷锟斤拷???
    input wire [31:0] reg_data2_2_i,        // 锟侥达拷锟斤拷锟窖革拷锟斤拷锟侥碉拷2锟斤拷指锟斤拷锟�??????2锟斤拷源锟斤拷锟斤拷???
    input wire [1:0] reg_write_en_i,           // 锟侥达拷锟斤拷写使锟斤拷
    input wire [4:0] reg_write_addr1_i,        //  锟侥达拷锟斤拷写锟斤拷址
    input wire [4:0] reg_write_addr2_i,        //锟侥达拷锟斤拷写锟斤拷址

    input wire [31:0] csr_read_data1_i,     // csr锟斤拷锟斤拷???
    input wire [31:0] csr_read_data2_i,     // csr锟斤拷锟斤拷???
    input wire [1:0]  csr_write_en_i,       // csr写使???
    input wire [13:0] csr_addr1_i,          // csr锟斤拷址
    input wire [13:0] csr_addr2_i,          // csr锟斤拷址


    input wire [4:0] invtlb_op1_i,
    input wire [4:0] invtlb_op2_i,

    input wire [1:0] pre_is_branch_taken_i,       //预锟斤拷锟街е革拷锟斤拷欠锟斤拷锟阶�
    input wire [31:0] pre_branch_addr1_i,         // 预锟斤拷锟街е革拷锟斤拷锟阶拷锟街�
    input wire [31:0] pre_branch_addr2_i,         // 预锟斤拷锟街е革拷锟斤拷锟阶拷锟街�

    
    // 锟斤拷锟斤拷mem锟斤拷锟斤拷???
    input wire pause_mem_i,

    // 锟斤拷dcache锟侥斤拷???
    input wire dcache_pause_i,       // ???/锟斤拷dache 锟斤拷停锟脚猴拷 锟斤拷锟斤拷dache锟斤拷write_finish???          
      
    output wire ren_o,                // dcache锟斤拷使锟斤拷锟斤拷???
    output wire [3:0]  wstrb_o,              // dcache写使锟斤拷锟斤拷???
    output wire wen_o,
    output wire [31:0] virtual_addr_o,      // dcache锟斤拷锟斤拷锟街�???
    output wire [31:0] wdata_o,             // dcache写锟斤拷???


    // 锟斤拷锟斤拷锟角帮拷说锟斤拷藕锟�???
    output wire [1:0]  ex_bpu_is_bj,
    output wire [31:0] ex_pc1,
    output wire [31:0] ex_pc2,
    output wire [1:0]  ex_bpu_taken_or_not_actual,
    output wire [31:0] ex_bpu_branch_actual_addr1,
    output wire [31:0] ex_bpu_branch_actual_addr2,
    output wire [31:0] ex_bpu_branch_pred_addr1,     // pred锟角诧拷锟角诧拷要锟斤拷
    output wire [31:0] ex_bpu_branch_pred_addr2,

    // �??????锟斤拷dispatch锟斤拷锟斤拷???
    output wire [7:0]  pre_ex_aluop1_o,
    output wire [7:0]  pre_ex_aluop2_o,
    output wire [1:0]  reg_write_en_o,
    output wire [4:0] reg_write_addr1_o,
    output wire [4:0] reg_write_addr2_o,
    output wire [31:0] reg_write_data1_o,
    output wire [31:0] reg_write_data2_o,
    
    // 锟斤拷锟斤拷锟絚trl锟斤拷锟斤拷???
    output wire   pause_ex_o,
    output wire   branch_flush_o,
    output wire   ex_excp_flush_o,
    output wire [31:0] branch_target_o,

    // 锟斤拷锟斤拷锟絤em锟斤拷锟斤拷???
    output reg [1:0] valid_mem,

    output reg [31:0] pc1_mem,
    output reg [31:0] pc2_mem,
    output reg [31:0] inst1_mem,
    output reg [31:0] inst2_mem,

    output reg [4:0] is_exception1_o,      
    output reg [4:0] is_exception2_o, 

    output reg [6:0] pc_exception_cause1_o, 
    output reg [6:0] pc_exception_cause2_o,
    output reg [6:0] instbuffer_exception_cause1_o,
    output reg [6:0] instbuffer_exception_cause2_o,
    output reg [6:0] decoder_exception_cause1_o,
    output reg [6:0] decoder_exception_cause2_o,
    output reg [6:0] dispatch_exception_cause1_o,
    output reg [6:0] dispatch_exception_cause2_o,
    output reg [6:0] execute_exception_cause1_o,
    output reg [6:0] execute_exception_cause2_o,

    output reg [7:0] aluop1_mem,
    output reg [7:0] aluop2_mem,

    output reg [1:0]  reg_write_en_mem,
    output reg [4:0]  reg_write_addr1_mem,
    output reg [4:0]  reg_write_addr2_mem,
    output reg [31:0] reg_write_data1_mem, 
    output reg [31:0] reg_write_data2_mem,

    output reg [31:0] addr1_mem,
    output reg [31:0] addr2_mem,
    output reg [31:0] data1_mem,
    output reg [31:0] data2_mem,

    output reg [1:0]  csr_write_en_mem,
    output reg [13:0] csr_addr1_mem,
    output reg [13:0] csr_addr2_mem,
    output reg [31:0] csr_write_data1_mem,
    output reg [31:0] csr_write_data2_mem,

    output reg [1:0] is_privilege_mem,
    output reg [1:0] is_ertn_mem,
    output reg [1:0] is_idle_mem,
    output reg [1:0] is_llw_scw_mem,

    output reg [1:0] icacop_en_mem,

    //cacop
    output wire icacop_en, 
    output wire dcacop_en,
    output wire [1:0] cacop_mode,
    output wire [31:0] cache_cacop_vaddr    // to addr_trans
);

    wire [1:0] pause_alu;

    // 锟酵凤拷支预锟斤拷锟斤拷锟叫关碉拷锟斤拷???
    wire [1:0] branch_flush_alu_o;
    wire [1:0] branch_flush_alu;
    wire [31:0] branch_target_addr_alu1;
    wire [31:0] branch_target_addr_alu2;

    wire [1:0] update_en_alu;
    wire [1:0] taken_or_not_actual_alu;
    wire [31:0] branch_actual_addr_alu1;
    wire [31:0] branch_actual_addr_alu2;
    wire [31:0] pc_dispatch_alu1;
    wire [31:0] pc_dispatch_alu2;

/*************************************
    // 锟斤拷cache锟叫关碉拷锟斤拷???
    wire [1:0] is_cacop_alu;
    wire [4:0] cacop_code_alu1;
    wire [4:0] cacop_code_alu2;
    wire [1:0] is_preld_alu;
    wire [1:0] hint_alu;
    wire [31:0] addr_alu;

*************************************/

    wire [1:0] valid_o;

    wire [1:0] op;
    wire addr_ok;
    wire [31:0] virtual_addr1;
    wire [31:0] virtual_addr2;
    wire [31:0] wdata1;
    wire [31:0] wdata2;
    wire ren1;
    wire ren2;
    wire [3:0] wstrb1;
    wire [3:0] wstrb2;
    wire wen1;
    wire wen2;

    // to mem
    wire [1:0] valid_mem_o;
    wire [31:0] pc1;
    wire [31:0] pc2;
    wire [31:0] inst1;
    wire [31:0] inst2;

    wire [4:0] is_exception1;
    wire [4:0] is_exception2;
    wire [6:0] pc_exception_cause1;
    wire [6:0] pc_exception_cause2;
    wire [6:0] instbuffer_exception_cause1;
    wire [6:0] instbuffer_exception_cause2;
    wire [6:0] decoder_exception_cause1;
    wire [6:0] decoder_exception_cause2;
    wire [6:0] dispatch_exception_cause1;
    wire [6:0] dispatch_exception_cause2;
    wire [6:0] execute_exception_cause1;
    wire [6:0] execute_exception_cause2;

    wire [1:0] is_privilege;
    wire [1:0] is_ert;
    wire [1:0] is_idle;

    wire [1:0] reg_write_en;
    wire [4:0] reg_write_addr1;
    wire [4:0] reg_write_addr2;
    wire [31:0] reg_write_data1; 
    wire [31:0] reg_write_data2; 

    wire [7:0] aluop1;
    wire [7:0] aluop2;

    wire [31:0] addr1;
    wire [31:0] addr2;
    wire [31:0] data1;
    wire [31:0] data2;

    wire [1:0] csr_write_en;
    wire [13:0] csr_addr1;
    wire [13:0] csr_addr2;
    wire [31:0] csr_write_data1;
    wire [31:0] csr_write_data2;

    wire [1:0] is_llw_scw;

    wire       dcache_pause;

    assign dcache_pause = dcache_pause_i;

    assign ren_o   = dcache_pause_i ? 1'b0 : (valid_o[0] ? ren1 : ren2);
    assign wstrb_o = dcache_pause_i ? 4'h0 : (valid_o[0] ? wstrb1 : wstrb2);
    assign wen_o   = dcache_pause_i ? 1'b0 : (valid_o[0] ? wen1 : wen2);
    assign virtual_addr_o = dcache_pause_i ? 32'h0 : (valid_o[0] ? virtual_addr1: virtual_addr2);
    assign wdata_o = dcache_pause_i ? 32'b0 : (valid_o[0] ? wdata1 : wdata2);



    alu u_alu_1 (
        .dcache_pause(dcache_pause),
        // 锟斤拷锟斤拷
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .pause_mem_i(pause_mem_i),

        // from dispatch
        .pc_i(pc1_i),
        .inst_i(inst1_i),

        .is_exception_i(is_exception1_i),
        .pc_exception_cause_i(pc_exception_cause1_i),
        .instbuffer_exception_cause_i(instbuffer_exception_cause1_i),
        .decoder_exception_cause_i(decoder_exception_cause1_i),
        .dispatch_exception_cause_i(dispatch_exception_cause1_i),

        .is_privilege_i(is_privilege_i[0]),
        
        .icacop_en_i(icacop_en1_i),
        .dcacop_en_i(dcacop_en1_i),
        
        .valid_i(valid_i[0]),

        .aluop_i(aluop1_i),
        .alusel_i(alusel1_i),

        .is_div_i(is_div_i[0]),
        .is_mul_i(is_mul_i[0]),

        .reg_data1_i(reg_data1_1_i),
        .reg_data2_i(reg_data1_2_i),
        .reg_write_en_i(reg_write_en_i[0]),
        .reg_write_addr_i(reg_write_addr1_i),

        .csr_read_data_i(csr_read_data1_i),
        .csr_write_en_i(csr_write_en_i[0]),
        .csr_addr_i(csr_addr1_i),

        .invtlb_op_i(invtlb_op1_i),

        .pre_is_branch_taken_i(pre_is_branch_taken_i[0]),
        .pre_branch_addr_i(pre_branch_addr1_i),


        // from stable counter
        .cnt_i(cnt_i),

        // 锟斤拷锟�???
        // with dache
        .valid_o(valid_o[0]),
        .virtual_addr_o(virtual_addr1),
        .ren_o(ren1),
        .wdata_o(wdata1),
        .wstrb_o(wstrb1),
        .wen_o(wen1),

        // to bpu
        .taken_or_not_actual_o(taken_or_not_actual_alu[0]),
        .branch_actual_addr_o(branch_actual_addr_alu1),
        .pc_dispatch_o(pc_dispatch_alu1),

        // to ctrl
        .pause_alu_o(pause_alu[0]),
        .branch_flush_o(branch_flush_alu_o[0]),
        .branch_target_addr_o(branch_target_addr_alu1),
        
        // to dispatch
        .pre_ex_aluop_o(pre_ex_aluop1_o),
        
        /*to Cache*********************锟斤拷一锟介都没锟斤�???****************************************
        .is_cacop_o(is_cacop_alu[0]),
        .cacop_code_o(cacop_code_alu[0]),
        .is_preld_o(is_preld_alu[0]),
        .hint_o(hint_alu[0]),
        .addr_o(addr_alu[0]),
        *******************************************************************************/
        // to mem
        .pc_mem(pc1),
        .inst_mem(inst1),

        .is_exception_o(is_exception1),
        .pc_exception_cause_o(pc_exception_cause1),
        .instbuffer_exception_cause_o(instbuffer_exception_cause1),
        .decoder_exception_cause_o(decoder_exception_cause1),
        .dispatch_exception_cause_o(dispatch_exception_cause1),
        .execute_exception_cause_o(execute_exception_cause1),

        .is_privilege_mem(is_privilege[0]),
        .is_ertn_mem(is_ert[0]),
        .is_idle_mem(is_idle[0]),
        .valid_mem(valid_mem_o[0]),
        .reg_write_en_mem(reg_write_en[0]),
        .reg_write_addr_mem(reg_write_addr1),
        .reg_write_data_mem(reg_write_data1),
        .aluop_mem(aluop1),
        .addr_mem(addr1),
        .data_mem(data1),
        .csr_write_en_mem(csr_write_en[0]),
        .csr_addr_mem(csr_addr1),
        .csr_write_data_mem(csr_write_data1),//////////////////////////////////
        .is_llw_scw_mem(is_llw_scw[0])
    );

    alu u_alu_2 (
        .dcache_pause(dcache_pause),
        // 锟斤拷锟斤拷
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .pause_mem_i(pause_mem_i),

        // from dispatch
        .pc_i(pc2_i),
        .inst_i(inst2_i),

        .is_exception_i(is_exception2_i),
        .pc_exception_cause_i(pc_exception_cause2_i),
        .instbuffer_exception_cause_i(instbuffer_exception_cause2_i),
        .decoder_exception_cause_i(decoder_exception_cause2_i),
        .dispatch_exception_cause_i(dispatch_exception_cause2_i),
        
        .is_privilege_i(is_privilege_i[1]),
        
        .icacop_en_i(icacop_en2_i),
        .dcacop_en_i(dcacop_en2_i),
        
        .valid_i(valid_i[1]),

        .aluop_i(aluop2_i),
        .alusel_i(alusel2_i),

        .reg_data1_i(reg_data2_1_i),
        .reg_data2_i(reg_data2_2_i),
        .reg_write_en_i(reg_write_en_i[1]),
        .reg_write_addr_i(reg_write_addr2_i),

        .csr_read_data_i(csr_read_data2_i),
        .csr_write_en_i(csr_write_en_i[1]),
        .csr_addr_i(csr_addr2_i),

        .invtlb_op_i(invtlb_op2_i),

        .pre_is_branch_taken_i(pre_is_branch_taken_i[1]),
        .pre_branch_addr_i(pre_branch_addr2_i),

        .is_div_i(is_div_i[1]),
        .is_mul_i(is_mul_i[1]),

        // from stable counter
        .cnt_i(cnt_i),

        // 锟斤拷锟�???
        // with dache
        .valid_o(valid_o[1]),
        .virtual_addr_o(virtual_addr2),
        .ren_o(ren2),
        .wdata_o(wdata2),
        .wstrb_o(wstrb2),
        .wen_o(wen2),

        // to bpu
        .taken_or_not_actual_o(taken_or_not_actual_alu[1]),
        .branch_actual_addr_o(branch_actual_addr_alu2),
        .pc_dispatch_o(pc_dispatch_alu2),

        // to ctrl
        .pause_alu_o(pause_alu[1]),
        .branch_flush_o(branch_flush_alu_o[1]),
        .branch_target_addr_o(branch_target_addr_alu2),
        
        // to dispatch
        .pre_ex_aluop_o(pre_ex_aluop2_o),
        
        /* to Cache*****锟斤拷锟矫恍�???***********************************************************

        .is_cacop_o(is_cacop_alu[1]),
        .cacop_code_o(cacop_code_alu[1]),
        .is_preld_o(is_preld_alu[1]),
        .hint_o(hint_alu[1]),
        .addr_o(addr_alu[1]),

        ***************************************************************************/
        // to mem
        .pc_mem(pc2),
        .inst_mem(inst2),

        .is_exception_o(is_exception2),
        .pc_exception_cause_o(pc_exception_cause2),
        .instbuffer_exception_cause_o(instbuffer_exception_cause2),
        .decoder_exception_cause_o(decoder_exception_cause2),
        .dispatch_exception_cause_o(dispatch_exception_cause2),
        .execute_exception_cause_o(execute_exception_cause2),

        .is_privilege_mem(is_privilege[1]),
        .is_ertn_mem(is_ert[1]),
        .is_idle_mem(is_idle[1]),
        .valid_mem(valid_mem_o[1]),
        .reg_write_en_mem(reg_write_en[1]),
        .reg_write_addr_mem(reg_write_addr2),
        .reg_write_data_mem(reg_write_data2),
        .aluop_mem(aluop2),
        .addr_mem(addr2),
        .data_mem(data2),
        .csr_write_en_mem(csr_write_en[1]),
        .csr_addr_mem(csr_addr2),
        .csr_write_data_mem(csr_write_data2),
        .is_llw_scw_mem(is_llw_scw[1])
    );

    // 锟斤拷锟斤拷锟斤拷前锟剿碉拷锟斤�??????
    assign ex_bpu_is_bj[0] = alusel1_i == `ALU_SEL_JUMP_BRANCH;
    assign ex_bpu_is_bj[1] = alusel2_i == `ALU_SEL_JUMP_BRANCH;
    assign ex_pc1 = pc1_i;
    assign ex_pc2 = pc2_i;
    assign ex_bpu_taken_or_not_actual = taken_or_not_actual_alu;
    assign ex_bpu_branch_actual_addr1 = branch_actual_addr_alu1;
    assign ex_bpu_branch_actual_addr2 = branch_actual_addr_alu2;
    assign ex_bpu_branch_pred_addr1   = pre_branch_addr1_i;
    assign ex_bpu_branch_pred_addr2   = pre_branch_addr2_i;


    // �??????锟斤�??? dispatch 锟斤拷锟斤拷???
    assign reg_write_en_o[0] = reg_write_en[0];
//    assign reg_write_en_o[1] = (branch_flush_alu[0] | (taken_or_not_actual_alu[0] & (pc2 != branch_target_addr_alu1))) ? 1'b0 : reg_write_en[1];
    assign reg_write_en_o[1] = (branch_actual_addr_alu1 != pc2) ? 1'b0 : reg_write_en[1];
    assign reg_write_addr1_o   = reg_write_addr1;
    assign reg_write_addr2_o   = reg_write_addr2;
    assign reg_write_data1_o   = reg_write_data1;
    assign reg_write_data2_o   = reg_write_data2;


    //cacop
    assign icacop_en         = icacop_en1_i | icacop_en2_i;
    assign dcacop_en         = dcacop_en1_i | dcacop_en2_i;
    assign cacop_mode        = (icacop_en1_i | dcacop_en1_i) ? cacop_opcode1_i[4:3] : cacop_opcode2_i[4:3];
    assign cache_cacop_vaddr = (icacop_en1_i | dcacop_en1_i) ? reg_write_data1 : reg_write_data2;


    // 锟斤拷锟�?????? ctrl 锟斤拷锟斤拷???
    assign branch_flush_alu = dcacop_en ? 2'b0 : branch_flush_alu_o;

    assign pause_ex_o = |pause_alu;
    /*
    assign branch_flush_o = (((!soft2_i & taken_or_not_actual_alu[1]) | ((valid_i == 2'b01) && taken_or_not_actual_alu[0]) | branch_flush_alu[0] | (branch_flush_alu == 2'b10 & (pc2 == branch_target_addr_alu1)))) && !pause_ex_o && !pause_mem_i;

    assign branch_target_o =  (branch_flush_alu_o[0] | ((valid_i == 2'b01) && taken_or_not_actual_alu[0])) ? branch_target_addr_alu1 : branch_target_addr_alu2;
    */
    assign branch_flush_o = |branch_flush_alu && !pause_ex_o && !pause_mem_i;

    assign branch_target_o = branch_flush_alu[0] ? branch_target_addr_alu1 : branch_target_addr_alu2;
/*
    always @(*)
    begin
        case({taken_or_not_actual_alu,pre_is_branch_taken_i})
        4'b0000:begin
            branch_target_o = 32'b0;
            branch_flush_o = 1'b0;
        end
        4'b0001:begin
            branch_target_o = branch_target_addr_alu1;
            branch_flush_o = !pause_ex_o && !pause_mem_i;
        end
        4'b0010:begin
            branch_target_o = branch_target_addr_alu2;
            branch_flush_o = !pause_ex_o && !pause_mem_i;
        end
        4'b0100:begin
            branch_target_o = branch_target_addr_alu1;
            branch_flush_alu_o = !pause_ex_o && !pause_mem_i;
        end
        4'b0101:begin
            branch_target_o = branch_target_addr_alu1;
            branch_flush_alu_o = (pre_branch_addr1_i != branch_target_addr_alu1) && !pause_ex_o && !pause_mem_i;
        end
        4'b0110:begin
            branch_target_o = branch_target_addr_alu1;
            branch_flush_alu_o = !pause_ex_o && !pause_mem_i;
        end
        4'b0111:begin
            branch_target_o = pre_branch_addr1_i == branch_target_addr_alu1 ? branch_target_addr_alu2 : branch_target_addr_alu1;
            branch_flush_alu_o = (pre_branch_addr1_i != branch_target_addr_alu1) || () && !pause_ex_o && !pause_mem_i
        end
        4'b1000:branch_target_o = 32'b0;
        4'b1001:branch_target_o = branch_target_addr_alu1;
        4'b1010:branch_target_o = branch_target_addr_alu2;
        4'b1011:branch_target_o = branch_target_addr_alu1;

        4'b1100:branch_target_o = 32'b0;
        4'b1101:branch_target_o = branch_target_addr_alu1;
        4'b1110:branch_target_o = branch_target_addr_alu2;
        4'b1111:branch_target_o = branch_target_addr_alu1;
        endcase
    end
*/


/*********************************************************************
    always @(posedge clk) begin
        if (branch_flush_alu[0]) begin      
            update_en_o <= update_en_alu[0];
            taken_or_not_actual_o <= taken_or_not_actual_alu[0];
            branch_actual_addr_o <= branch_actual_addr_alu[0];
            pc_dispatch_o <= pc_dispatch_alu[0];
        end 
        else begin
            update_en_o <= update_en_alu[1];
            taken_or_not_actual_o <= taken_or_not_actual_alu[1];
            branch_actual_addr_o <= branch_actual_addr_alu[1];
            pc_dispatch_o <= pc_dispatch_alu[1];
        end
    end
*********************************************************************/
    wire [4:0] is_exception2_temp = branch_actual_addr_alu1 != pc2 ? 0 : is_exception2;
    assign ex_excp_flush_o = (is_exception1 != 0 || is_exception2_temp != 0 
                            || csr_write_en[0] || csr_write_en[1]
                            || aluop1 == `ALU_ERTN || aluop2 == `ALU_ERTN) 
                            && !pause_ex_o && !pause_mem_i;

    wire ex_mem_pause;
    assign ex_mem_pause = pause_ex_o && !pause_mem_i;

    // to mem
    always @(posedge clk) begin
        if (rst || ex_mem_pause || flush) 
        begin
            pc1_mem <= 32'b0;
            pc2_mem <= 32'b0;
            inst1_mem <= 32'b0;
            inst2_mem <= 32'b0;
            is_exception1_o <= 5'b0;
            is_exception2_o <= 5'b0;
            pc_exception_cause1_o <= 7'b0;    
            pc_exception_cause2_o <= 7'b0;
            instbuffer_exception_cause1_o <= 7'b0;
            instbuffer_exception_cause2_o <= 7'b0;
            decoder_exception_cause1_o <= 7'b0;
            decoder_exception_cause2_o <= 7'b0;
            dispatch_exception_cause1_o <= 7'b0;
            dispatch_exception_cause2_o <= 7'b0;
            execute_exception_cause1_o <= 7'b0;
            execute_exception_cause2_o <= 7'b0; 
            is_privilege_mem <= 2'b0;
            is_ertn_mem      <= 2'b0;
            is_idle_mem      <= 2'b0;
            valid_mem        <= 2'b0;
            reg_write_en_mem <= 2'b0;
            reg_write_addr1_mem <= 5'b0;
            reg_write_addr2_mem <= 5'b0;
            reg_write_data1_mem <= 32'b0;
            reg_write_data2_mem <= 32'b0;
            aluop1_mem <= 8'b0;
            aluop2_mem <= 8'b0;
            addr1_mem  <= 32'b0;
            addr2_mem  <= 32'b0;
            data1_mem  <= 32'b0;
            data2_mem  <= 32'b0;
            csr_write_en_mem <= 2'b0;
            csr_addr1_mem <= 14'b0;
            csr_addr2_mem <= 14'b0;
            csr_write_data1_mem <= 32'b0;
            csr_write_data2_mem <= 32'b0;
            is_llw_scw_mem <= 2'b0;
            icacop_en_mem  <= 2'b0;
        end 
        else if (!pause) 
        begin
            if (branch_flush_alu[0] | branch_actual_addr_alu1!=pc2)   //branch_flush_alu[0] can be deleted?
            begin
                pc1_mem <= pc1;
                inst1_mem <= inst1;
                is_exception1_o <= is_exception1;
                pc_exception_cause1_o<= pc_exception_cause1;
                instbuffer_exception_cause1_o <= instbuffer_exception_cause1;
                decoder_exception_cause1_o <= decoder_exception_cause1;
                dispatch_exception_cause1_o <= decoder_exception_cause1;
                execute_exception_cause1_o <= execute_exception_cause1;
                is_privilege_mem[0] <= is_privilege[0];
                is_ertn_mem[0] <= aluop1 == `ALU_ERTN;
                is_idle_mem[0] <= aluop2 == `ALU_IDLE;
                valid_mem[0] <= valid_mem_o[0];
                reg_write_en_mem[0] <= reg_write_en[0];
                reg_write_addr1_mem <= reg_write_addr1;
                reg_write_data1_mem <= reg_write_data1;
                aluop1_mem <= aluop1;
                addr1_mem <= addr1;
                data1_mem <= data1;
                csr_write_en_mem[0] <= csr_write_en[0];
                csr_addr1_mem <= csr_addr1;
                csr_write_data1_mem <= csr_write_data1;
                is_llw_scw_mem[0] <= is_llw_scw[0];
                icacop_en_mem[0]  <= icacop_en1_i;

                pc2_mem <= 32'b0;
                inst2_mem <= 32'b0;
                is_exception2_o <= 5'b0;
                pc_exception_cause2_o <= 7'b0;
                instbuffer_exception_cause2_o <= 7'b0;
                decoder_exception_cause2_o <= 7'b0;
                dispatch_exception_cause2_o <= 7'b0;
                execute_exception_cause2_o <= 7'b0;
                is_privilege_mem[1] <= 1'b0;
                is_ertn_mem[1] <= 1'b0;
                is_idle_mem[1] <= 1'b0;
                valid_mem[1] <= 1'b0;
                reg_write_en_mem[1] <= 1'b0;
                reg_write_addr2_mem <= 5'b0;
                reg_write_data2_mem <= 32'b0;
                aluop2_mem <= 8'b0;
                addr2_mem <= 32'b0;
                data2_mem <= 32'b0;
                csr_write_en_mem[1] <= 1'b0;
                csr_addr2_mem <= 14'b0;
                csr_write_data2_mem <= 32'b0;
                is_llw_scw_mem[1] <= 1'b0;
                icacop_en_mem[1]  <= 1'b0;
            end 
            else 
            begin
                pc1_mem <= pc1;
                pc2_mem <= pc2;
                inst1_mem <= inst1;
                inst2_mem <= inst2;
                is_exception1_o <= is_exception1;
                is_exception2_o <= is_exception2;
                pc_exception_cause1_o <= pc_exception_cause1;
                pc_exception_cause2_o <= pc_exception_cause2;
                instbuffer_exception_cause1_o <= instbuffer_exception_cause1;
                instbuffer_exception_cause2_o <= instbuffer_exception_cause2;
                decoder_exception_cause1_o <= decoder_exception_cause1;
                decoder_exception_cause2_o <= decoder_exception_cause2;
                dispatch_exception_cause1_o <= dispatch_exception_cause1;
                dispatch_exception_cause2_o <= dispatch_exception_cause2;
                execute_exception_cause1_o <= execute_exception_cause1;
                execute_exception_cause2_o <= execute_exception_cause2;
                is_privilege_mem[0] <= is_privilege[0];
                is_privilege_mem[1] <= is_privilege[1];
                is_ertn_mem[0] <= aluop1 == `ALU_ERTN;
                is_ertn_mem[1] <= aluop2 == `ALU_ERTN;
                is_idle_mem[0] <= aluop1 == `ALU_IDLE;
                is_idle_mem[1] <= aluop2 == `ALU_IDLE;
                valid_mem[0] <= valid_mem_o[0];
                valid_mem[1] <= valid_mem_o[1];
                reg_write_en_mem[0] <= reg_write_en[0];
                reg_write_en_mem[1] <= reg_write_en[1];
                reg_write_addr1_mem <= reg_write_addr1;
                reg_write_addr2_mem <= reg_write_addr2;
                reg_write_data1_mem <= reg_write_data1;
                reg_write_data2_mem <= reg_write_data2;
                aluop1_mem <= aluop1;
                aluop2_mem <= aluop2;
                addr1_mem <= addr1;
                addr2_mem <= addr2;
                data1_mem <= data1;
                data2_mem <= data2;
                csr_write_en_mem[0] <= csr_write_en[0];
                csr_write_en_mem[1] <= csr_write_en[1];
                csr_addr1_mem <= csr_addr1;
                csr_addr2_mem <= csr_addr2;
                csr_write_data1_mem <= csr_write_data1;
                csr_write_data2_mem <= csr_write_data2;
                is_llw_scw_mem[0] <= is_llw_scw[0];
                is_llw_scw_mem[1] <= is_llw_scw[1];
                icacop_en_mem[0]  <= icacop_en1_i;
                icacop_en_mem[1]  <= icacop_en2_i;
            end
        end 
        else 
        begin
            pc1_mem <= pc1_mem;
            pc2_mem <= pc2_mem;
            inst1_mem <= inst1_mem;
            inst2_mem <= inst2_mem;
            is_exception1_o <= is_exception1_o;
            is_exception2_o <= is_exception2_o;
            pc_exception_cause1_o <= pc_exception_cause1_o;
            pc_exception_cause2_o <= pc_exception_cause2_o;
            instbuffer_exception_cause1_o <= instbuffer_exception_cause1_o;
            instbuffer_exception_cause2_o <= instbuffer_exception_cause2_o;
            decoder_exception_cause1_o <= decoder_exception_cause1_o;
            decoder_exception_cause2_o <= decoder_exception_cause2_o;
            dispatch_exception_cause1_o <= dispatch_exception_cause1_o;
            dispatch_exception_cause2_o <= dispatch_exception_cause2_o;
            execute_exception_cause1_o <= execute_exception_cause1_o;
            execute_exception_cause2_o <= execute_exception_cause2_o;
            is_privilege_mem[0] <= is_privilege_mem[0];
            is_privilege_mem[1] <= is_privilege_mem[1];
            is_ertn_mem[0] <= is_ertn_mem[0];
            is_ertn_mem[1] <= is_ertn_mem[1];
            is_idle_mem[0] <= is_idle_mem[0];
            is_idle_mem[1] <= is_idle_mem[1];
            valid_mem[0] <= valid_mem[0];
            valid_mem[1] <= valid_mem[1];
            reg_write_en_mem[0] <= reg_write_en_mem[0];
            reg_write_en_mem[1] <= reg_write_en_mem[1];
            reg_write_addr1_mem <= reg_write_addr1_mem;
            reg_write_addr2_mem <= reg_write_addr2_mem;
            reg_write_data1_mem <= reg_write_data1_mem;
            reg_write_data2_mem <= reg_write_data2_mem;
            aluop1_mem <= aluop1_mem;
            aluop2_mem <= aluop2_mem;
            addr1_mem <= addr1_mem;
            addr2_mem <= addr2_mem;
            data1_mem <= data1_mem;
            data2_mem <= data2_mem;
            csr_write_en_mem[0] <= csr_write_en_mem[0];
            csr_write_en_mem[1] <= csr_write_en_mem[1];
            csr_addr1_mem <= csr_addr1_mem;
            csr_addr2_mem <= csr_addr2_mem;
            csr_write_data1_mem <= csr_write_data1_mem;
            csr_write_data2_mem <= csr_write_data2_mem;
            is_llw_scw_mem[0] <= is_llw_scw_mem[0];
            is_llw_scw_mem[1] <= is_llw_scw_mem[1];
            icacop_en_mem <= icacop_en_mem;
        end
    end
endmodule