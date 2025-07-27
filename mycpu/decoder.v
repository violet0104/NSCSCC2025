`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module decoder (
    input wire clk,
    input wire rst,

    input wire flush, //ǿ�Ƹ����ź�

    // ǰ�˴��ݵ�����
    input wire [31:0] pc1,
    input wire [31:0] pc2,
    input wire [31:0] inst1,
    input wire [31:0] inst2,
    input wire [1:0]  valid,                        //  ǰ�˴��ݵ�������Ч�ź�
    input wire [1:0]  pretaken,                     // �ǰ�˴��ݵķ�֧Ԥ�������Ƿ���ת��
    input wire [31:0] pre_addr_in1 ,           // ǰ�˴��ݵķ�֧Ԥ��Ŀ���ַ
    input wire [31:0] pre_addr_in2 ,

    input wire [1:0]  is_exception_in1 ,          // ��һ��ָ����쳣�ź�
    input wire [1:0]  is_exception_in2 ,          // �ڶ���ָ����쳣�ź�

    input wire [6:0]  pc_exception_cause_in1 ,        // �쳣ԭ��
    input wire [6:0]  pc_exception_cause_in2 ,        

    input wire [6:0]  instbuffer_exception_cause_in1 ,   
    input wire [6:0]  instbuffer_exception_cause_in2 ,

    //���� dispatch ���ź�
    input wire [1:0] invalid_en,  // ��Ч�ź�


    // �����ǰ�˵�ȡָ�����ź�
    output wire get_data_req,   
    output wire pause_decoder,


    //  ����� dispatch ���ź�
    output reg  [1:0]  dispatch_id_valid,       // pc��Ч�ź�

    output reg  [31:0] dispatch_pc_out1 ,
    output reg  [31:0] dispatch_pc_out2 ,
    output reg  [31:0] dispatch_inst_out1 ,
    output reg  [31:0] dispatch_inst_out2 ,

    output reg  [2:0]  is_exception_o1 ,            //  �Ƿ��쳣
    output reg  [2:0]  is_exception_o2 ,         
    output reg  [6:0]  pc_exception_cause_o1 ,         // ��ԭ��
    output reg  [6:0]  pc_exception_cause_o2 ,
    output reg  [6:0]  instbuffer_exception_cause_o1,
    output reg  [6:0]  instbuffer_exception_cause_o2,
    output reg  [6:0]  decoder_exception_cause_o1,
    output reg  [6:0]  decoder_exception_cause_o2, 

    output reg  [7:0]  dispatch_aluop1 ,
    output reg  [7:0]  dispatch_aluop2 ,
    output reg  [2:0]  dispatch_alusel1 ,
    output reg  [2:0]  dispatch_alusel2 ,
    output reg  [31:0] dispatch_imm1 ,
    output reg  [31:0] dispatch_imm2 ,

    output reg  [1:0]  dispatch_reg_read_en1,           // ��һ��ָ��Ķ�ʹ��
    output reg  [1:0]  dispatch_reg_read_en2,           // �ڶ���ָ��Ķ�ʹ��
    output reg  [4:0]  dispatch_reg_read_addr1_1 ,      // ��һ��ָ�����������ַ
    output reg  [4:0]  dispatch_reg_read_addr1_2 ,
    output reg  [4:0]  dispatch_reg_read_addr2_1 ,      // �ڶ���ָ�����������ַ
    output reg  [4:0]  dispatch_reg_read_addr2_2,
    output reg  [1:0]  dispatch_reg_writen_en,          // �Ĵ���дʹ���źţ�2λ��
    output reg  [4:0]  dispatch_reg_write_addr1 ,       // �Ĵ���д��ַ
    output reg  [4:0]  dispatch_reg_write_addr2 ,

    output reg  [1:0]  dispatch_id_pre_taken,           // ��֧Ԥ�������Ƿ���ת��
    output reg  [31:0] dispatch_id_pre_addr1,       // ��֧Ԥ��Ŀ���ַ
    output reg  [31:0] dispatch_id_pre_addr2,

    output reg  [1:0]  dispatch_is_privilege,           //�Ƿ�����Ȩָ��
    output reg  [1:0]  dispatch_csr_read_en,            //CSR��ʹ��
    output reg  [1:0]  dispatch_csr_write_en,           //CSRдʹ��
    output reg  [13:0] dispatch_csr_addr1,          //CSR��ַ
    output reg  [13:0] dispatch_csr_addr2,
    output reg  [1:0]  dispatch_is_cnt,                 //�Ƿ��Ǽ�����
    output reg  [4:0]  dispatch_invtlb_op1,               //TLB��Ч����
    output reg  [4:0]  dispatch_invtlb_op2
);

    //�ڲ��ź�
    wire  id_valid1;       //ID�׶���Ч�ź�
    wire  id_valid2;

    wire  valid1_i ;
    assign valid1_i = valid[0];
    wire  valid2_i ;
    assign valid2_i = valid[1];

    wire pre_taken1_i;
    assign pre_taken1_i = pretaken[0];
    wire pre_taken2_i;
    assign pre_taken2_i = pretaken[1];

    wire  [31:0] pc_out1;
    wire  [31:0] pc_out2;
    wire  [31:0] inst_out1;
    wire  [31:0] inst_out2;

    wire  [2:0] is_exception1;               //�Ƿ��쳣
    wire  [2:0] is_exception2;              
    wire  [6:0] pc_exception_cause1;         //�쳣ԭ��
    wire  [6:0] pc_exception_cause2;
    wire  [6:0] instbuffer_exception_cause1; 
    wire  [6:0] instbuffer_exception_cause2;
    wire  [6:0] decoder_exception_cause1;
    wire  [6:0] decoder_exception_cause2;

    wire  [7:0]  aluop1;
    wire  [7:0]  aluop2;
    wire  [2:0]  alusel1;
    wire  [2:0]  alusel2;
    wire  [31:0] imm1;
    wire  [31:0] imm2;

    wire  [1:0]  reg_read_en1;          // ��һ��ָ��Ķ�ʹ��
    wire  [1:0]  reg_read_en2;          // �ڶ���ָ��Ķ�ʹ��
    wire  [4:0]  reg_read_addr1_1;      // ��һ��ָ��Ķ���ַ
    wire  [4:0]  reg_read_addr1_2;
    wire  [4:0]  reg_read_addr2_1;      // �ڶ���ָ��Ķ���ַ
    wire  [4:0]  reg_read_addr2_2;
    wire  [1:0]  reg_writen_en; 
    wire  [4:0]  reg_write_addr1;
    wire  [4:0]  reg_write_addr2;

    wire  id_pre_taken1;       // ID �׶�Ԥ���֧�Ƿ���ת
    wire  id_pre_taken2;
    wire  [31:0] pre_addr1;     // ID �׶�Ԥ���֧��ת��ַ
    wire  [31:0] pre_addr2;

    wire  is_privilege1;       // �Ƿ�����Ȩָ��
    wire  is_privilege2;
    wire  csr_read_en1 ;        // CSR��ʹ��
    wire  csr_read_en2 ;
    wire  csr_write_en1;       //CSRдʹ��
    wire  csr_write_en2;
    wire  [13:0] csr_addr1;     // CSR
    wire  [13:0] csr_addr2;
    wire  is_cnt1;             // ���Ǽ�����
    wire  is_cnt2;
    wire  [4:0]  invtlb_op1;         // TLB��Ч\
    wire  [4:0]  invtlb_op2;

    id u_id_0 (
        // �����ź�
        .valid(valid1_i),

        .pre_taken(pre_taken1_i),
        .pre_addr(pre_addr_in1),

        .pc(pc1),
        .inst(inst1),
        
        .is_exception(is_exception_in1),
        .pc_exception_cause(pc_exception_cause_in1),
        .instbuffer_exception_cause(instbuffer_exception_cause_in1),


        // ����ź�
        .id_valid(id_valid1),

        .pc_out(pc_out1),
        .inst_out(inst_out1),

        .is_exception_out(is_exception1),
        .pc_exception_cause_out(pc_exception_cause1),
        .instbuffer_exception_cause_out(instbuffer_exception_cause1),
        .decoder_exception_cause_out(decoder_exception_cause1),

        .aluop(aluop1),
        .alusel(alusel1),
        .imm(imm1),

        .reg1_read_en(reg_read_en1[0]),   
        .reg2_read_en(reg_read_en1[1]),   
        .reg1_read_addr(reg_read_addr1_1),
        .reg2_read_addr(reg_read_addr1_2),
        .reg_writen_en (reg_writen_en[0]),  
        .reg_write_addr(reg_write_addr1),  

        .id_pre_taken(id_pre_taken1), 
        .id_pre_addr(pre_addr1), 

        .is_privilege(is_privilege1), 
        .csr_read_en(csr_read_en1), 
        .csr_write_en(csr_write_en1), 
        .csr_addr(csr_addr1), 
        .is_cnt(is_cnt1), 
        .invtlb_op(invtlb_op1) 
    );

    id u_id_1 (
        .valid(valid2_i),

        .pre_taken(pre_taken2_i),
        .pre_addr(pre_addr_in2),

        .pc(pc2),
        .inst(inst2),
        
        .is_exception(is_exception_in2),
        .pc_exception_cause(pc_exception_cause_in2),
        .instbuffer_exception_cause(instbuffer_exception_cause_in2),


        .id_valid(id_valid2),

        .pc_out(pc_out2),
        .inst_out(inst_out2),

        .is_exception_out(is_exception2),
        .pc_exception_cause_out(pc_exception_cause2),
        .instbuffer_exception_cause_out(instbuffer_exception_cause2),
        .decoder_exception_cause_out(decoder_exception_cause2),

        .aluop(aluop2),
        .alusel(alusel2),
        .imm(imm2),

        .reg1_read_en(reg_read_en2[0]),   
        .reg2_read_en(reg_read_en2[1]),   
        .reg1_read_addr(reg_read_addr2_1),
        .reg2_read_addr(reg_read_addr2_2),
        .reg_writen_en (reg_writen_en[1]),  
        .reg_write_addr(reg_write_addr2),  

        .id_pre_taken(id_pre_taken2), 
        .id_pre_addr(pre_addr2), 
        
        .is_privilege(is_privilege2), 
        .csr_read_en(csr_read_en2), 
        .csr_write_en(csr_write_en2), 
        .csr_addr(csr_addr2), 
        .is_cnt(is_cnt2), 
        .invtlb_op(invtlb_op2) 
    );
    /////////////////////////////////////////////
    // ������ݣ����Ҫ�����źţ����źż�����ǰ�沢���޸�`DECODE_DATA_WIDTH��ֵ
    wire [`DECODE_DATA_WIDTH - 1:0] enqueue_data1;
    wire [`DECODE_DATA_WIDTH - 1:0] enqueue_data2;
    assign  enqueue_data1 =  {
                                decoder_exception_cause1,     // 205:199     
                                instbuffer_exception_cause1,  // 198:192
                                pc_exception_cause1,          // 191:185      
                                is_exception1,    // 184:182

                                invtlb_op1,           // 181:177
                                is_cnt1,              // 176
                                csr_addr1,            // 175:162
                                csr_write_en1,        // 161
                                csr_read_en1,         // 160
                                is_privilege1,        // 159    
                                pre_addr1,            // 158:127
                                id_pre_taken1,        // 126
                                
                                reg_write_addr1,      // 125:121
                                reg_writen_en[0],     // 120
                                reg_read_addr1_2,     // 119:115
                                reg_read_addr1_1,     // 114:110
                                reg_read_en1,         // 109:108

                                imm1,                 // 107:76
                                alusel1,              // 75:73
                                aluop1,               // 72:65
                                
                                inst_out1,            // 64:33
                                pc_out1,              // 32:1

                                id_valid1};           // 0

    assign  enqueue_data2 =  {
                                decoder_exception_cause2,     // 205:199     
                                instbuffer_exception_cause2,  // 198:192
                                pc_exception_cause2,          // 191:185    
                                is_exception2,    // 184:182

                                invtlb_op2,           // 181:177
                                is_cnt2,              // 176
                                csr_addr2,            // 175:162
                                csr_write_en2,        // 161
                                csr_read_en2,         // 160
                                is_privilege2,        // 159    
                                pre_addr2,            // 158:127
                                id_pre_taken2,        // 126
                                
                                reg_write_addr2,      // 125:121
                                reg_writen_en[1],     // 120
                                reg_read_addr2_2,     // 119:115
                                reg_read_addr2_1,     // 114:110
                                reg_read_en2,         // 109:108

                                imm2,                 // 107:76
                                alusel2,              // 75:73
                                aluop2,               // 72:65
                                
                                inst_out2,            // 64:33
                                pc_out2,              // 32:1

                                id_valid2};           // 0      

    // ��������
    wire [`DECODE_DATA_WIDTH - 1:0] dequeue_data1;
    wire [`DECODE_DATA_WIDTH - 1:0] dequeue_data2;

    wire fifo_rst;
    assign fifo_rst = rst || flush;
    reg [1:0] enqueue_en;   //���ʹ���ź�
    wire get_data_req_o;
    wire full;
    wire empty;

    dram_fifo u_queue(
        .clk(clk),
        .rst(fifo_rst),
        .flush(flush),

        .enqueue_en(enqueue_en),
        .enqueue_data1(enqueue_data1),
        .enqueue_data2(enqueue_data2),

        .invalid_en(invalid_en),
        .dequeue_data1(dequeue_data1),
        .dequeue_data2(dequeue_data2),

        .get_data_req(get_data_req_o),
        .full(full),
        .empty(empty)
    );
    
    // ���ݸ�ǰ�˵�ȡָ�����ź�
    assign get_data_req = get_data_req_o;

    always @(*) begin
        enqueue_en[0] = !full && valid[0];
        enqueue_en[1] = !full && valid[1];
    end


    // �ֽ��������
    always @(*) begin
        dispatch_id_valid[0]        =   dequeue_data1[0];
        dispatch_id_valid[1]        =   dequeue_data2[0];
        dispatch_pc_out1            =   dequeue_data1[32:1];
        dispatch_pc_out2            =   dequeue_data2[32:1];
        dispatch_inst_out1          =   dequeue_data1[64:33];
        dispatch_inst_out2          =   dequeue_data2[64:33];
        dispatch_aluop1             =   dequeue_data1[72:65];
        dispatch_aluop2             =   dequeue_data2[72:65];
        dispatch_alusel1            =   dequeue_data1[75:73];
        dispatch_alusel2            =   dequeue_data2[75:73];
        dispatch_imm1               =   dequeue_data1[107:76];
        dispatch_imm2               =   dequeue_data2[107:76];
        dispatch_reg_read_en1       =   dequeue_data1[109:108];   
        dispatch_reg_read_en2       =   dequeue_data2[109:108];     
        dispatch_reg_read_addr1_1   =   dequeue_data1[114:110];
        dispatch_reg_read_addr1_2   =   dequeue_data1[119:115];
        dispatch_reg_read_addr2_1   =   dequeue_data2[114:110];
        dispatch_reg_read_addr2_2   =   dequeue_data2[119:115];
        dispatch_reg_writen_en[0]   =   dequeue_data1[120];
        dispatch_reg_writen_en[1]   =   dequeue_data2[120];  
        dispatch_reg_write_addr1    =   dequeue_data1[125:121];
        dispatch_reg_write_addr2    =   dequeue_data2[125:121];
        dispatch_id_pre_taken[0]    =   dequeue_data1[126];
        dispatch_id_pre_taken[1]    =   dequeue_data2[126];
        dispatch_id_pre_addr1       =   dequeue_data1[158:127];
        dispatch_id_pre_addr2       =   dequeue_data2[158:127];
        dispatch_is_privilege[0]    =   dequeue_data1[159];
        dispatch_is_privilege[1]    =   dequeue_data2[159];
        dispatch_csr_read_en[0]     =   dequeue_data1[160];
        dispatch_csr_read_en[1]     =   dequeue_data2[160];
        dispatch_csr_write_en[0]    =   dequeue_data1[161];
        dispatch_csr_write_en[1]    =   dequeue_data2[161];
        dispatch_csr_addr1          =   dequeue_data1[175:162];
        dispatch_csr_addr2          =   dequeue_data2[175:162];
        dispatch_is_cnt[0]          =   dequeue_data1[176];
        dispatch_is_cnt[1]          =   dequeue_data2[176];
        dispatch_invtlb_op1         =   dequeue_data1[181:177];
        dispatch_invtlb_op2         =   dequeue_data2[181:177];
        
        is_exception_o1                 =   dequeue_data1[184:182];
        is_exception_o2                 =   dequeue_data2[184:182];
        pc_exception_cause_o1           =   dequeue_data1[191:185];
        pc_exception_cause_o2           =   dequeue_data2[191:185];
        instbuffer_exception_cause_o1   =   dequeue_data1[198:192];
        instbuffer_exception_cause_o2   =   dequeue_data2[198:192];
        decoder_exception_cause_o1      =   dequeue_data1[205:199];
        decoder_exception_cause_o2      =   dequeue_data2[205:199];
    end

    assign pause_decoder = full;


endmodule