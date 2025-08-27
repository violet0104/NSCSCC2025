`timescale 1ns / 1ps
`include "defines.vh"
`include "csr_defines.vh"

module dispatch
(
    input wire clk,
    input wire rst,

    //控制单元的暂停和刷新信号
    input wire pause,
    input wire flush,


    // 来自dispatch的输入信�???
    input wire [31:0] pc1_i,      //指令地址
    input wire [31:0] pc2_i,      //指令地址
    input wire [1:0] soft_i,

    input wire [31:0] inst1_i,    //指令编码
    input wire [31:0] inst2_i,    //指令编码
    input wire [1:0]  valid_i,   //指令有效标志

    input wire [2:0]  is_exception_i1, //�???1条指令的异常标志
    input wire [2:0]  is_exception_i2, //�???2条指令的异常标志
    
    input wire [6:0] pc_exception_cause_i1,
    input wire [6:0] instbuffer_exception_cause_i1,
    input wire [6:0] decoder_exception_cause_i1,
    input wire [6:0] pc_exception_cause_i2,
    input wire [6:0] instbuffer_exception_cause_i2,
    input wire [6:0] decoder_exception_cause_i2,

    input wire [1:0]  is_privilege_i, //两条指令的特权指令标�???
    input wire [1:0]  is_cnt_i,       //两条指令的计数器指令标志

    input wire [7:0]  alu_op_i1,  //ALU操作�???
    input wire [7:0]  alu_op_i2,  //ALU操作�???
    input wire [2:0]  alu_sel_i1, //ALU功能选择
    input wire [2:0]  alu_sel_i2, //ALU功能选择
    input wire [31:0] imm_i1,     //立即数�??
    input wire [31:0] imm_i2,     //立即数�??

    input wire [1:0]   is_div_i,
    input wire [1:0]   is_mul_i,

    input wire [4:0]  invtlb_op_i1,   //�???1条指令的分支指令标志
    input wire [4:0]  invtlb_op_i2,   //�???2条指令的分支指令标志

    input wire [1:0]  reg_read_en_i1,     //�???1条指令的两个源寄存器源寄存器读使�???
    input wire [1:0]  reg_read_en_i2,     //�???2条指令的两个源寄存器源寄存器读使�???   
    input wire [4:0]  reg_read_addr_i1_1, //�???1条指令的�???1个源寄存器地�???
    input wire [4:0]  reg_read_addr_i1_2, //�???1条指令的�???2个源寄存器地�???
    input wire [4:0]  reg_read_addr_i2_1, //�???2条指令的�???1个源寄存器地�???
    input wire [4:0]  reg_read_addr_i2_2, //�???2条指令的�???2个源寄存器地�???

    input wire [1:0]  reg_write_en_i,    //两条指令目的寄存器写使能
    input wire [4:0]  reg_write_addr_i1,  //指令1目的寄存器地�???
    input wire [4:0]  reg_write_addr_i2,  //指令2目的寄存器地�???

    input wire [1:0]   csr_read_en_i,   //csr读使�???
    input wire [13:0]  csr_addr_i1,     //�???1条指令csr地址
    input wire [13:0]  csr_addr_i2,     //�???2条指令csr地址
    input wire [1:0]   csr_write_en_i,  //csr写使�???
    input wire [1:0]   pre_is_branch_taken_i,//前一条指令是否是分支指令
    input wire [31:0]  pre_branch_addr_i1, 
    input wire [31:0]  pre_branch_addr_i2, 


    // 来自ex和mem的前递数�???
    input wire [1:0]   ex_pf_write_en,     //从ex阶段前�?�出来的使能
    input wire [4:0]   ex_pf_write_addr1,   //从ex阶段前�?�出来的地址
    input wire [4:0]   ex_pf_write_addr2,   //从ex阶段前�?�出来的地址
    input wire [31:0]  ex_pf_write_data1,   //从ex阶段前�?�出来的数据
    input wire [31:0]  ex_pf_write_data2,   //从ex阶段前�?�出来的数据

    input wire [1:0]   mem_pf_write_en,    //从mem阶段前�?�出来的使能
    input wire [4:0]   mem_pf_write_addr1,  //从mem阶段前�?�出来的地址
    input wire [4:0]   mem_pf_write_addr2,  //从mem阶段前�?�出来的地址
    input wire [31:0]  mem_pf_write_data1,  //从mem阶段前�?�出来的数据
    input wire [31:0]  mem_pf_write_data2,  //从mem阶段前�?�出来的数据

    input wire [1:0]   wb_pf_write_en,     //从wb阶段前�?�出来的使能
    input wire [4:0]   wb_pf_write_addr1,   //从wb阶段前�?�出来的地址
    input wire [4:0]   wb_pf_write_addr2,   //从wb阶段前�?�出来的地址
    input wire [31:0]  wb_pf_write_data1,   //从wb阶段前�?�出来的数据
    input wire [31:0]  wb_pf_write_data2,   //从wb阶段前�?�出来的数据

    //来自ex阶段的，用于判断ex运行的指令是否是load指令
    input wire [7:0]   ex_pre_aluop1,       //ex阶段的load指令标志
    input wire [7:0]   ex_pre_aluop2,       //ex阶段的load指令标志
    //来自ex阶段的，可能由于乘除法等指令引起的暂停信�???
    input wire         ex_pause,           //ex阶段的暂停信�???


    // 输出给execute的数�???
    output reg [31:0] pc1_o,  
    output reg [31:0] pc2_o,  
    output reg      soft1_o, //软中断标志
    output reg      soft2_o,
    output reg [31:0] inst1_o,
    output reg [31:0] inst2_o,
    output reg [1:0]  valid_o,

    output reg [3:0]  is_exception_o1, //�???1条指令的异常标志
    output reg [3:0]  is_exception_o2, //�???2条指令的异常�???

    output reg [6:0] pc_exception_cause_o1,
    output reg [6:0] instbuffer_exception_cause_o1,
    output reg [6:0] decoder_exception_cause_o1,
    output reg [6:0] dispatch_exception_cause_o1,
    output reg [6:0] pc_exception_cause_o2,
    output reg [6:0] instbuffer_exception_cause_o2,
    output reg [6:0] decoder_exception_cause_o2,
    output reg [6:0] dispatch_exception_cause_o2,

    output reg [1:0]  is_privilege_o, //两条指令的特权指令标�???

    output reg icacop_en_o1,
    output reg icacop_en_o2,
    output reg dcacop_en_o1,
    output reg dcacop_en_o2,
    output reg [4:0] cacop_opcode_o1,
    output reg [4:0] cacop_opcode_o2,

    output reg [7:0]  alu_op_o1,
    output reg [7:0]  alu_op_o2,
    output reg [2:0]  alu_sel_o1,
    output reg [2:0]  alu_sel_o2,

    output reg [1:0]   is_div_o, //两条指令的除法标�?
    output reg [1:0]   is_mul_o, //两条指令的乘法标�?

    output reg [31:0] reg_read_data_o1_1, //寄存器堆给出的第1条指令的�???1个源操作�???
    output reg [31:0] reg_read_data_o1_2, //寄存器堆给出的第1条指令的�???2个源操作�???
    output reg [31:0] reg_read_data_o2_1, //寄存器堆给出的第2条指令的�???1个源操作�???
    output reg [31:0] reg_read_data_o2_2, //寄存器堆给出的第2条指令的�???2个源操作�???
    
    output reg [1:0]  reg_write_en_o,     //目的寄存器写使能
    output reg [4:0]  reg_write_addr_o1,  //目的寄存器地�???
    output reg [4:0]  reg_write_addr_o2,  //目的寄存器地�???

    output reg [31:0]  csr_read_data_o1, //寄存器堆的csr读数�???
    output reg [31:0]  csr_read_data_o2, //寄存器堆的csr读数�???
    output reg [1:0]   csr_write_en_o, //寄存器堆的csr写使�???
    output reg [13:0]  csr_addr_o1,     //寄存器堆的csr地址
    output reg [13:0]  csr_addr_o2,     //寄存器堆的csr地址
    
    output reg [4:0]  invtlb_op_o1,   //�???1条指令的分支指令标志
    output reg [4:0]  invtlb_op_o2,   //�???2条指令的分支指令标志
    
    output reg [1:0]   pre_is_branch_taken_o, //前一条指令是否是分支指令
    output reg [31:0]  pre_branch_addr_o1, //前一条指令的分支地址
    output reg [31:0]  pre_branch_addr_o2,  //前一条指令的分支地址


    
    // 输出�??? id 阶段的信�???
    output wire [1:0] invalid_en, //指令发射控制信号

    //与寄存器的接�???
    input wire [31:0] from_reg_read_data_i1_1, //寄存器给出的�???1条指令的�???1个源操作�???
    input wire [31:0] from_reg_read_data_i1_2, //寄存器给出的�???1条指令的�???2个源操作�???
    input wire [31:0] from_reg_read_data_i2_1, //寄存器给出的�???2条指令的�???1个源操作�???
    input wire [31:0] from_reg_read_data_i2_2, //寄存器给出的�???2条指令的�???2个源操作�???

    output wire dispatch_pause ,//发射器暂停信�???,当发生load-use冒险时需要暂�???


    // 和csr的接�???
    input wire  [31:0]  csr_read_data_i1,   // csr读数�???
    input wire  [31:0]  csr_read_data_i2,   // csr读数�???

    output wire [1:0]   csr_read_en_o,      // csr读使�???
    output wire [13:0]   csr_read_addr_o1,   // csr读地�???
    output wire [13:0]   csr_read_addr_o2   // csr读地�???
);

    wire [1:0] send_en;     //内部发射信号，给invalid_en赋�??
    wire       send_double; //判断是否为双发射的信�??? 
    
    wire [1:0] inst_valid;  //内部指令有效标志

    wire       cnt_inst; //计数器指令标志，判断发射的两条指令中有没有计数器指令
    wire       privilege_inst; //特权指令标志，判断发射的两条指令中有没有特权指令
    wire       mem_inst;//访存信号标志，判断发射的两条指令中有没有load和store类型
    wire       data_hazard_inst;//数据冒险标志，判断是否出现了数据冒险

    reg  [31:0] pc1_temp;       //临时寄存器，存储指令地址
    reg  [31:0] pc2_temp;       //临时寄存器，存储指令地址
    reg  [31:0] inst1_temp;     //临时寄存器，存储指令编码
    reg  [31:0] inst2_temp;     //临时寄存器，存储指令编码
    reg  [1:0]  valid_temp;     //临时寄存器，存储指令有效标志
    reg  [7:0]  alu_op1_temp;   //临时寄存器，存储ALU操作�???
    reg  [7:0]  alu_op2_temp;   //临时寄存器，存储ALU操作�???
    reg  [2:0]  alu_sel1_temp;  //临时寄存器，存储ALU功能选择
    reg  [2:0]  alu_sel2_temp;  //临时寄存器，存储ALU功能选择
    reg  [1:0]  is_div_temp; //临时寄存器，存储两条指令的除法标�?
    reg  [1:0]  is_mul_temp; //临时寄存器，存储两条指令的乘法标�?
    reg  [1:0]  reg_write_en_temp; //临时寄存器，存储目的寄存器写使能
    reg  [4:0]  reg_write_addr1_temp; //临时寄存器，存储目的寄存器地�???
    reg  [4:0]  reg_write_addr2_temp; //临时寄存器，存储目的寄存器地�???
    reg  [31:0] reg_read_data1_1_temp; //寄存器堆给出的第1条指令的�???1个源操作�???
    reg  [31:0] reg_read_data1_2_temp; //寄存器堆给出的第1条指令的�???2个源操作�???
    reg  [31:0] reg_read_data2_1_temp; //寄存器堆给出的第2条指令的�???1个源操作�???
    reg  [31:0] reg_read_data2_2_temp; //寄存器堆给出的第2条指令的�???2个源操作�???
    reg  [1:0]  is_privilege_temp; //临时寄存器，存储特权指令标志
    reg  [3:0]  is_exception1_temp; //�???1条指令的异常标志
    reg  [3:0]  is_exception2_temp; //�???2条指令的异常标志

    reg  [6:0] pc_exception_cause1_temp; //�???1条指令的异常原因
    reg  [6:0] instbuffer_exception_cause1_temp; //�???1条指令的异常原因
    reg  [6:0] id_exception_cause1_temp; //�???1条指令的异常原因
    reg  [6:0] dispatch_exception_cause1_temp; //�???1条指令的异常原因
    reg  [6:0] pc_exception_cause2_temp; //�???2条指令的异常原因
    reg  [6:0] instbuffer_exception_cause2_temp; //�???2条指令的异常原因
    reg  [6:0] id_exception_cause2_temp; //�???2条指令的异常原因
    reg  [6:0] dispatch_exception_cause2_temp; //�???2条指令的异常原因

    reg  [4:0]  invtlb_op1_temp;   //�???1条指令的分支指令标志
    reg  [4:0]  invtlb_op2_temp;   //�???2条指令的分支指令标志
    reg  [1:0]  csr_write_en_temp; //临时寄存器，存储csr写使�???
    reg  [13:0] csr_addr1_temp; //临时寄存器，存储csr写地�???
    reg  [13:0] csr_addr2_temp; //临时寄存器，存储csr写地�???
    reg  [1:0]  pre_is_branch_taken_temp; //临时寄存器，存储前一条指令是否是分支指令
    reg  [31:0] pre_branch_addr1_temp; //临时寄存器，存储前一条指令的分支地址
    reg  [31:0] pre_branch_addr2_temp; //临时寄存器，存储前一条指令的分支地址
    reg  [31:0] csr_read_data1_temp; //临时寄存器，存储csr读数�???
    reg  [31:0] csr_read_data2_temp; //临时寄存器，存储csr读数�???

    assign invalid_en = pause ? 2'b00 : send_en;//发射控制信号赋�??

    assign inst_valid = valid_i;//内部有效标志赋�??
    

    assign privilege_inst = (is_privilege_i[0] || is_privilege_i[1]);//判断发射的两条指令中有没有特权指�???
    assign mem_inst = (alu_sel_i1 == `ALU_SEL_LOAD_STORE || alu_sel_i2 == `ALU_SEL_LOAD_STORE);//判断发射的两条指令中有没有load和store类型的指�???
    //下面这条语句，检验了将要双发射的这两条指令间是否存在数据相关冒险
    assign data_hazard_inst = (reg_write_en_i[0] && reg_write_addr_i1 != 5'b0) //�???1条指令有写寄存器的功�???
                            &&((reg_write_addr_i1 == reg_read_addr_i2_1 && reg_read_en_i2[0]) //�???1条指令的写寄存器的地�???与第2条指令第1个源寄存器相�???
                            ||(reg_write_addr_i1 == reg_read_addr_i2_2 && reg_read_en_i2[1])); //�???1条指令的写寄存器的地�???与第2条指令第2个源寄存器相�???
    assign cnt_inst = (is_cnt_i[0] || is_cnt_i[1]);//判断发射的两条指令中有没有计数器指令

    assign send_double = (!mem_inst) && (!data_hazard_inst) && (!cnt_inst) && (!privilege_inst) && (&inst_valid); //判断这两条指令能否同时发�???
    assign send_en = (send_double == 1'b1) ? 2'b11 : (inst_valid[0] ? 2'b01 : (inst_valid[1] ? 2'b10 : 2'b00));//当指令不能双发射时优先发第一�???

    reg soft1_temp;
    reg soft2_temp;
    //信号传输
    always @(*) begin
        pc1_temp = pc1_i;
        pc2_temp = pc2_i;
        soft1_temp = soft_i[0];
        soft2_temp = soft_i[1];
        inst1_temp = inst1_i;
        inst2_temp = inst2_i;
        valid_temp = valid_i;
        alu_op1_temp = alu_op_i1;
        alu_op2_temp = alu_op_i2;
        alu_sel1_temp = alu_sel_i1;
        alu_sel2_temp = alu_sel_i2;
        is_div_temp = is_div_i;
        is_mul_temp = is_mul_i;
        reg_write_en_temp = reg_write_en_i;
        reg_write_addr1_temp = reg_write_addr_i1;
        reg_write_addr2_temp = reg_write_addr_i2;
        is_privilege_temp = is_privilege_i;
        is_exception1_temp = {is_exception_i1, 1'b0};
        is_exception2_temp = {is_exception_i2, 1'b0};
        pc_exception_cause1_temp = pc_exception_cause_i1;
        instbuffer_exception_cause1_temp = instbuffer_exception_cause_i1;
        id_exception_cause1_temp = decoder_exception_cause_i1;
        dispatch_exception_cause1_temp = `EXCEPTION_NOP;
        pc_exception_cause2_temp = pc_exception_cause_i2;
        instbuffer_exception_cause2_temp = instbuffer_exception_cause_i2;
        id_exception_cause2_temp = decoder_exception_cause_i2;
        dispatch_exception_cause2_temp = `EXCEPTION_NOP;
        invtlb_op1_temp = invtlb_op_i1;
        invtlb_op2_temp = invtlb_op_i2;
        csr_write_en_temp = csr_write_en_i;
        csr_addr1_temp = csr_addr_i1;
        csr_addr2_temp = csr_addr_i2;
        pre_is_branch_taken_temp = pre_is_branch_taken_i;
        pre_branch_addr1_temp = pre_branch_addr_i1;
        pre_branch_addr2_temp = pre_branch_addr_i2;
    end
    
    always @(*) begin
        //正常的读数据
        //�???1条指�???
        if(reg_read_en_i1[0]) begin
            reg_read_data1_1_temp = from_reg_read_data_i1_1;
        end else begin
            reg_read_data1_1_temp = imm_i1; //如果没有读使能，则赋值立即数
        end
        if(reg_read_en_i1[1]) begin
            reg_read_data1_2_temp = from_reg_read_data_i1_2;
        end else begin
            reg_read_data1_2_temp = imm_i1; //如果没有读使能，则赋值立即数
        end
        
        //�???2条指�???
        if(reg_read_en_i2[0]) begin
            reg_read_data2_1_temp = from_reg_read_data_i2_1;
        end else begin
            reg_read_data2_1_temp = imm_i2; //如果没有读使能，则赋值立即数
        end
        if(reg_read_en_i2[1]) begin
            reg_read_data2_2_temp = from_reg_read_data_i2_2;
        end else begin
            reg_read_data2_2_temp = imm_i2; //如果没有读使能，则赋值立即数
        end
        
        //与写回阶段有数据冲突进行数据前�??
        //�???1条指令的�???1
        if(wb_pf_write_en[0] && reg_read_en_i1[0] && (reg_read_addr_i1_1 == wb_pf_write_addr1)) 
            reg_read_data1_1_temp = wb_pf_write_data1;
        else if(wb_pf_write_en[1] && reg_read_en_i1[0] && (reg_read_addr_i1_1 == wb_pf_write_addr2)) 
            reg_read_data1_1_temp = wb_pf_write_data2;
        
        //�???1条指令的�???2
        if(wb_pf_write_en[0] && reg_read_en_i1[1] && (reg_read_addr_i1_2 == wb_pf_write_addr1)) 
            reg_read_data1_2_temp = wb_pf_write_data1;
        else if(wb_pf_write_en[1] && reg_read_en_i1[1] && (reg_read_addr_i1_2 == wb_pf_write_addr2)) 
            reg_read_data1_2_temp = wb_pf_write_data2;
        
        //�???2条指令的�???1
        if(wb_pf_write_en[0] && reg_read_en_i2[0] && (reg_read_addr_i2_1 == wb_pf_write_addr1)) 
            reg_read_data2_1_temp = wb_pf_write_data1;
        else if(wb_pf_write_en[1] && reg_read_en_i2[0] && (reg_read_addr_i2_1 == wb_pf_write_addr2)) 
            reg_read_data2_1_temp = wb_pf_write_data2;
        
        //�???2条指令的�???2
        if(wb_pf_write_en[0] && reg_read_en_i2[1] && (reg_read_addr_i2_2 == wb_pf_write_addr1)) 
            reg_read_data2_2_temp = wb_pf_write_data1;
        else if(wb_pf_write_en[1] && reg_read_en_i2[1] && (reg_read_addr_i2_2 == wb_pf_write_addr2)) 
            reg_read_data2_2_temp = wb_pf_write_data2;
        
        //与访存阶段有数据冲突进行数据前�??
        //�???1条指令的�???1
        if(mem_pf_write_en[0] && reg_read_en_i1[0] && (reg_read_addr_i1_1 == mem_pf_write_addr1)) 
            reg_read_data1_1_temp = mem_pf_write_data1;
        else if(mem_pf_write_en[1] && reg_read_en_i1[0] && (reg_read_addr_i1_1 == mem_pf_write_addr2)) 
            reg_read_data1_1_temp = mem_pf_write_data2;
        
        //�???1条指令的�???2
        if(mem_pf_write_en[0] && reg_read_en_i1[1] && (reg_read_addr_i1_2 == mem_pf_write_addr1)) 
            reg_read_data1_2_temp = mem_pf_write_data1;
        else if(mem_pf_write_en[1] && reg_read_en_i1[1] && (reg_read_addr_i1_2 == mem_pf_write_addr2)) 
            reg_read_data1_2_temp = mem_pf_write_data2;
        
        //�???2条指令的�???1
        if(mem_pf_write_en[0] && reg_read_en_i2[0] && (reg_read_addr_i2_1 == mem_pf_write_addr1)) 
            reg_read_data2_1_temp = mem_pf_write_data1;
        else if(mem_pf_write_en[1] && reg_read_en_i2[0] && (reg_read_addr_i2_1 == mem_pf_write_addr2)) 
            reg_read_data2_1_temp = mem_pf_write_data2;
        
        //�???2条指令的�???2
        if(mem_pf_write_en[0] && reg_read_en_i2[1] && (reg_read_addr_i2_2 == mem_pf_write_addr1)) 
            reg_read_data2_2_temp = mem_pf_write_data1;
        else if(mem_pf_write_en[1] && reg_read_en_i2[1] && (reg_read_addr_i2_2 == mem_pf_write_addr2)) 
            reg_read_data2_2_temp = mem_pf_write_data2;
        
        //与执行阶段有数据冲突进行数据前�??
        //�???1条指令的�???1
        if(ex_pf_write_en[0] && reg_read_en_i1[0] && (reg_read_addr_i1_1 == ex_pf_write_addr1)) 
            reg_read_data1_1_temp = ex_pf_write_data1;
        else if(ex_pf_write_en[1] && reg_read_en_i1[0] && (reg_read_addr_i1_1 == ex_pf_write_addr2)) 
            reg_read_data1_1_temp = ex_pf_write_data2;
        
        //�???1条指令的�???2
        if(ex_pf_write_en[0] && reg_read_en_i1[1] && (reg_read_addr_i1_2 == ex_pf_write_addr1)) 
            reg_read_data1_2_temp = ex_pf_write_data1;
        else if(ex_pf_write_en[1] && reg_read_en_i1[1] && (reg_read_addr_i1_2 == ex_pf_write_addr2)) 
            reg_read_data1_2_temp = ex_pf_write_data2;
        
        //�???2条指令的�???1
        if(ex_pf_write_en[0] && reg_read_en_i2[0] && (reg_read_addr_i2_1 == ex_pf_write_addr1)) 
            reg_read_data2_1_temp = ex_pf_write_data1;
        else if(ex_pf_write_en[1] && reg_read_en_i2[0] && (reg_read_addr_i2_1 == ex_pf_write_addr2)) 
            reg_read_data2_1_temp = ex_pf_write_data2;
        
        //�???2条指令的�???2
        if(ex_pf_write_en[0] && reg_read_en_i2[1] && (reg_read_addr_i2_2 == ex_pf_write_addr1)) 
            reg_read_data2_2_temp = ex_pf_write_data1;
        else if(ex_pf_write_en[1] && reg_read_en_i2[1] && (reg_read_addr_i2_2 == ex_pf_write_addr2)) 
            reg_read_data2_2_temp = ex_pf_write_data2;
        
        //如果源寄存器地址�???0，则赋�?�为0
        if(reg_read_en_i1[0] && reg_read_addr_i1_1 == 5'b0) 
            reg_read_data1_1_temp = 32'b0;
        if(reg_read_en_i1[1] && reg_read_addr_i1_2 == 5'b0) 
            reg_read_data1_2_temp = 32'b0;
        if(reg_read_en_i2[0] && reg_read_addr_i2_1 == 5'b0) 
            reg_read_data2_1_temp = 32'b0;
        if(reg_read_en_i2[1] && reg_read_addr_i2_2 == 5'b0) 
            reg_read_data2_2_temp = 32'b0;
        
        //处理PCADDU12I指令
        if(alu_op_i1 == `ALU_PCADDU12I) begin
            if(reg_read_en_i1[0]) reg_read_data1_1_temp = pc1_i;
            if(reg_read_en_i1[1]) reg_read_data1_2_temp = pc1_i;
        end
        if(alu_op_i2 == `ALU_PCADDU12I) begin
            if(reg_read_en_i2[0]) reg_read_data2_1_temp = pc2_i;
            if(reg_read_en_i2[1]) reg_read_data2_2_temp = pc2_i;
        end
    end

    reg [13:0] cpucfg_addr1;
    reg [13:0] cpucfg_addr2;
    always @(*) begin
        if (alu_op_i1 == `ALU_CPUCFG) begin
            case (reg_read_data1_1_temp) 
                    32'h1:       cpucfg_addr1 = `CSR_CPUCFG1;
                    32'h2:       cpucfg_addr1 = `CSR_CPUCFG2;
                    32'h10:      cpucfg_addr1 = `CSR_CPUCFG10;
                    32'h11:      cpucfg_addr1 = `CSR_CPUCFG11;
                    32'h12:      cpucfg_addr1 = `CSR_CPUCFG12;
                    32'h13:      cpucfg_addr1 = `CSR_CPUCFG13;
                    default:     cpucfg_addr1 = 14'b0;
            endcase
        end
        else if (alu_op_i2 == `ALU_CPUCFG) begin
            case (reg_read_data2_1_temp) 
                    32'h1:       cpucfg_addr2 = `CSR_CPUCFG1;
                    32'h2:       cpucfg_addr2 = `CSR_CPUCFG2;
                    32'h10:      cpucfg_addr2 = `CSR_CPUCFG10;
                    32'h11:      cpucfg_addr2 = `CSR_CPUCFG11;
                    32'h12:      cpucfg_addr2 = `CSR_CPUCFG12;
                    32'h13:      cpucfg_addr2 = `CSR_CPUCFG13;
                    default:     cpucfg_addr2 = 14'b0;
            endcase
        end
    end
    assign csr_read_en_o = csr_read_en_i;
    assign csr_read_addr_o1 = (alu_op_i1 == `ALU_CPUCFG) ? cpucfg_addr1 : csr_addr_i1;
    assign csr_read_addr_o2 = (alu_op_i2 == `ALU_CPUCFG) ? cpucfg_addr2 : csr_addr_i2;


    // cacop
    wire [4:0] cacop_opcode1;
    wire [4:0] cacop_opcode2;
    assign cacop_opcode1 = reg_write_addr_i1;
    assign cacop_opcode2 = reg_write_addr_i2;

    wire cacop_valid1;
    wire cacop_valid2;
    assign cacop_valid1 = (alu_op_i1 == `ALU_CACOP) & valid_i[0];
    assign cacop_valid2 = (alu_op_i2 == `ALU_CACOP) & valid_i[1];

    wire icacop_en1;
    wire dcacop_en1;
    wire icacop_en2;
    wire dcacop_en2;
    assign icacop_en1  = (cacop_opcode1[2:0] == 3'b000) & cacop_valid1;
    assign dcacop_en1  = (cacop_opcode1[2:0] == 3'b001) & cacop_valid1;
    assign icacop_en2  = (cacop_opcode2[2:0] == 3'b000) & cacop_valid2;
    assign dcacop_en2  = (cacop_opcode2[2:0] == 3'b001) & cacop_valid2;


    //csr
    always @(*) begin
        if(csr_read_en_i[0]) 
            csr_read_data1_temp = csr_read_data_i1;
        else 
            csr_read_data1_temp = 32'b0;
            
        if(csr_read_en_i[1]) 
            csr_read_data2_temp = csr_read_data_i2;
        else 
            csr_read_data2_temp = 32'b0;
    end


    //load-use冒险比起�???般的数据冒险更严重�??
    //�???般的数据冒险在执行阶段就可得到结�???
    //load-use冒险则需要在访存阶段后才能结�???

    wire        pre_load; //判断先前的指令是否是load指令
    wire        reg_relate_i1_1;//�???1条指令的�???1与前�???条load指令相关
    wire        reg_relate_i1_2;//�???1条指令的�???2与前�???条load指令相关
    wire        reg_relate_i2_1;//�???2条指令的�???1与前�???条load指令相关
    wire        reg_relate_i2_2;//�???2条指令的�???2与前�???条load指令相关

    //判断这时候在ex阶段的指令是否是load指令
    assign pre_load = (ex_pre_aluop1 == `ALU_LDB) 
                    || (ex_pre_aluop1 == `ALU_LDH) 
                    || (ex_pre_aluop1 == `ALU_LDW) 
                    || (ex_pre_aluop1 == `ALU_LDBU) 
                    || (ex_pre_aluop1 == `ALU_LDHU) 
                    || (ex_pre_aluop1 == `ALU_LLW)
                    || (ex_pre_aluop1 == `ALU_SCW)
                    || (ex_pre_aluop2 == `ALU_LDB) 
                    || (ex_pre_aluop2 == `ALU_LDH) 
                    || (ex_pre_aluop2 == `ALU_LDW) 
                    || (ex_pre_aluop2 == `ALU_LDBU) 
                    || (ex_pre_aluop2 == `ALU_LDHU) 
                    || (ex_pre_aluop2 == `ALU_LLW)
                    || (ex_pre_aluop2 == `ALU_SCW);

    //判断发射器中的两条指令是否与当前ex阶段的load指令相关（load指令�???次只发一条）
    assign reg_relate_i1_1 = pre_load && reg_read_en_i1[0] && (reg_read_addr_i1_1 == ex_pf_write_addr1);
    assign reg_relate_i1_2 = pre_load && reg_read_en_i1[1] && (reg_read_addr_i1_2 == ex_pf_write_addr1);
    assign reg_relate_i2_1 = pre_load && reg_read_en_i2[0] && (reg_read_addr_i2_1 == ex_pf_write_addr1);
    assign reg_relate_i2_2 = pre_load && reg_read_en_i2[1] && (reg_read_addr_i2_2 == ex_pf_write_addr1);

    assign dispatch_pause = reg_relate_i1_1 | reg_relate_i1_2 | reg_relate_i2_1 | reg_relate_i2_2; //若存在load-use冒险，则暂停发射�???

    reg [31:0] ex_pc1_temp;             
    reg [31:0] ex_pc2_temp;   
    reg        ex_soft1_temp;
    reg        ex_soft2_temp;          
    reg [31:0] ex_inst1_temp;           
    reg [31:0] ex_inst2_temp;           
    reg        ex_valid1_temp;          
    reg        ex_valid2_temp;          
    reg [7:0]  ex_alu_op1_temp;         
    reg [7:0]  ex_alu_op2_temp;         
    reg [2:0]  ex_alu_sel1_temp;        
    reg [2:0]  ex_alu_sel2_temp;   
    reg [1:0]  ex_is_div_temp; 
    reg [1:0]  ex_is_mul_temp;      
    reg        ex_reg_write_en1_temp; 
    reg        ex_reg_write_en2_temp; 
    reg [4:0]  ex_reg_write_addr1_temp; 
    reg [4:0]  ex_reg_write_addr2_temp; 
    reg [31:0] ex_reg_read_data1_1_temp; 
    reg [31:0] ex_reg_read_data1_2_temp; 
    reg [31:0] ex_reg_read_data2_1_temp; 
    reg [31:0] ex_reg_read_data2_2_temp; 
    reg        ex_is_privilege1_temp; 
    reg        ex_is_privilege2_temp; 

    reg        ex_icacop_en1_temp;
    reg        ex_icacop_en2_temp;
    reg        ex_dcacop_en1_temp;
    reg        ex_dcacop_en2_temp;
    reg [4:0]  ex_cacop_opcode1_temp;
    reg [4:0]  ex_cacop_opcode2_temp;

    reg [3:0]  ex_is_exception1_temp; 
    reg [3:0]  ex_is_exception2_temp; 

    reg [6:0] ex_pc_exception_cause1_temp; 
    reg [6:0] ex_instbuffer_exception_cause1_temp;
    reg [6:0] ex_id_exception_cause1_temp;
    reg [6:0] ex_dispatch_exception_cause1_temp;
    reg [6:0] ex_pc_exception_cause2_temp;
    reg [6:0] ex_instbuffer_exception_cause2_temp;
    reg [6:0] ex_id_exception_cause2_temp;
    reg [6:0] ex_dispatch_exception_cause2_temp;

    reg [4:0]  ex_invtlb_op1_temp;   
    reg [4:0]  ex_invtlb_op2_temp;   
    reg        ex_csr_write_en1_temp; 
    reg        ex_csr_write_en2_temp; 
    reg [13:0] ex_csr_addr1_temp; 
    reg [13:0] ex_csr_addr2_temp; 
    reg        ex_pre_is_branch_taken1_temp; 
    reg        ex_pre_is_branch_taken2_temp; 
    reg [31:0] ex_pre_branch_addr1_temp; 
    reg [31:0] ex_pre_branch_addr2_temp; 
    reg [31:0] ex_csr_read_data1_temp; 
    reg [31:0] ex_csr_read_data2_temp; 

    always @(*) begin
        if(send_en[0])begin
            ex_pc1_temp = pc1_temp;
            ex_soft1_temp = soft1_temp;
            ex_inst1_temp = inst1_temp;
            ex_valid1_temp = valid_temp[0];
            ex_alu_op1_temp = alu_op1_temp;
            ex_alu_sel1_temp = alu_sel1_temp;
            ex_is_div_temp[0] = is_div_temp[0];
            ex_is_mul_temp[0] = is_mul_temp[0];
            ex_reg_write_en1_temp = reg_write_en_temp[0];
            ex_reg_write_addr1_temp = reg_write_addr1_temp;
            ex_reg_read_data1_1_temp = reg_read_data1_1_temp;
            ex_reg_read_data1_2_temp = reg_read_data1_2_temp;
            ex_is_privilege1_temp = is_privilege_temp[0];

            ex_icacop_en1_temp    = icacop_en1;
            ex_dcacop_en1_temp    = dcacop_en1;
            ex_cacop_opcode1_temp = cacop_opcode1;

            ex_is_exception1_temp = is_exception1_temp;

            ex_pc_exception_cause1_temp = pc_exception_cause1_temp;
            ex_instbuffer_exception_cause1_temp = instbuffer_exception_cause1_temp;
            ex_id_exception_cause1_temp = id_exception_cause1_temp;
            ex_dispatch_exception_cause1_temp = dispatch_exception_cause1_temp;

            ex_invtlb_op1_temp = invtlb_op1_temp;
            ex_csr_write_en1_temp = csr_write_en_temp[0];
            ex_csr_addr1_temp = csr_addr1_temp;
            ex_pre_is_branch_taken1_temp = pre_is_branch_taken_temp[0];
            ex_pre_branch_addr1_temp = pre_branch_addr1_temp;
            ex_csr_read_data1_temp = csr_read_data1_temp;
        end 
        else begin
            ex_pc1_temp = 32'b0;
            ex_soft1_temp = 1'b0;
            ex_inst1_temp = 32'b0;    
            ex_valid1_temp = 1'b0;
            ex_alu_op1_temp = 8'b0;
            ex_alu_sel1_temp = 3'b0;
            ex_is_div_temp[0] = 1'b0;
            ex_is_mul_temp[0] = 1'b0;
            ex_reg_write_en1_temp = 1'b0;
            ex_reg_write_addr1_temp = 5'b0;
            ex_reg_read_data1_1_temp = 32'b0;
            ex_reg_read_data1_2_temp = 32'b0;
            ex_is_privilege1_temp = 1'b0;

            ex_icacop_en1_temp    = 1'b0;
            ex_dcacop_en1_temp    = 1'b0;
            ex_cacop_opcode1_temp = 5'b0;

            
            ex_is_exception1_temp = 4'b0;

            ex_pc_exception_cause1_temp = 7'b0;
            ex_instbuffer_exception_cause1_temp = 7'b0;
            ex_id_exception_cause1_temp = 7'b0;
            ex_dispatch_exception_cause1_temp = 7'b0;

            ex_invtlb_op1_temp = 5'b0;
            ex_csr_write_en1_temp = 1'b0;
            ex_csr_addr1_temp = 14'b0;
            ex_pre_is_branch_taken1_temp = 1'b0;
            ex_pre_branch_addr1_temp = 32'b0;
            ex_csr_read_data1_temp = 32'b0;
        end
        if(send_en[1]) begin
            ex_pc2_temp = pc2_temp;
            ex_soft2_temp = soft2_temp; 
            ex_inst2_temp = inst2_temp;
            ex_valid2_temp = valid_temp[1];
            ex_alu_op2_temp = alu_op2_temp;
            ex_alu_sel2_temp = alu_sel2_temp;
            ex_is_div_temp[1] = is_div_temp[1];
            ex_is_mul_temp[1] = is_mul_temp[1];
            ex_reg_write_en2_temp = reg_write_en_temp[1];
            ex_reg_write_addr2_temp = reg_write_addr2_temp;
            ex_reg_read_data2_1_temp = reg_read_data2_1_temp;
            ex_reg_read_data2_2_temp = reg_read_data2_2_temp;
            ex_is_privilege2_temp = is_privilege_temp[1];

            ex_icacop_en2_temp    = icacop_en2;
            ex_dcacop_en2_temp    = dcacop_en2;
            ex_cacop_opcode2_temp = cacop_opcode2;

            ex_is_exception2_temp = is_exception2_temp;

            ex_pc_exception_cause2_temp = pc_exception_cause2_temp;
            ex_instbuffer_exception_cause2_temp = instbuffer_exception_cause2_temp;
            ex_id_exception_cause2_temp = id_exception_cause2_temp;
            ex_dispatch_exception_cause2_temp = dispatch_exception_cause2_temp;

            ex_invtlb_op2_temp = invtlb_op2_temp;
            ex_csr_write_en2_temp = csr_write_en_temp[1];
            ex_csr_addr2_temp = csr_addr2_temp;
            ex_pre_is_branch_taken2_temp = pre_is_branch_taken_temp[1];
            ex_pre_branch_addr2_temp = pre_branch_addr2_temp;
            ex_csr_read_data2_temp = csr_read_data2_temp;
        end
        else begin
            ex_pc2_temp = 32'b0;
            ex_soft2_temp = 1'b0;
            ex_inst2_temp = 32'b0;    
            ex_valid2_temp = 1'b0;
            ex_alu_op2_temp = 8'b0;
            ex_alu_sel2_temp = 3'b0;
            ex_is_div_temp[1] = 1'b0;
            ex_is_mul_temp[1] = 1'b0;
            ex_reg_write_en2_temp = 1'b0;
            ex_reg_write_addr2_temp = 5'b0;
            ex_reg_read_data2_1_temp = 32'b0;
            ex_reg_read_data2_2_temp = 32'b0;
            ex_is_privilege2_temp = 1'b0;

            ex_icacop_en2_temp    = 1'b0;
            ex_dcacop_en2_temp    = 1'b0;
            ex_cacop_opcode2_temp = 5'b0;

            ex_is_exception2_temp = 4'b0;

            ex_pc_exception_cause2_temp = 7'b0;
            ex_instbuffer_exception_cause2_temp = 7'b0;
            ex_id_exception_cause2_temp = 7'b0;
            ex_dispatch_exception_cause2_temp = 7'b0;

            ex_invtlb_op2_temp = 5'b0;
            ex_csr_write_en2_temp = 1'b0;
            ex_csr_addr2_temp = 14'b0;
            ex_pre_is_branch_taken2_temp = 1'b0;
            ex_pre_branch_addr2_temp = 32'b0;
            ex_csr_read_data2_temp = 32'b0;
        end
    end
    
    wire dispatch_current_pause;//当前发射器的暂停信号
    assign dispatch_current_pause =  !ex_pause && dispatch_pause;//如果ex阶段没有暂停且发生load-use冒险，则发射器暂�??? 

    always @(posedge clk) begin
        if(rst || flush || dispatch_current_pause) begin
            pc1_o <= 32'b0;
            pc2_o <= 32'b0;
            inst1_o <= 32'b0;
            inst2_o <= 32'b0;
            valid_o <= 2'b0;
            reg_write_en_o <= 2'b0;
            reg_write_addr_o1 <= 5'b0;
            reg_write_addr_o2 <= 5'b0;
            alu_op_o1 <= 8'b0;
            alu_op_o2 <= 8'b0;
            alu_sel_o1 <= 3'b0;
            alu_sel_o2 <= 3'b0;
            is_div_o <= 2'b0;
            is_mul_o <= 2'b0;
            reg_read_data_o1_1 <= 32'b0;
            reg_read_data_o1_2 <= 32'b0;
            reg_read_data_o2_1 <= 32'b0;
            reg_read_data_o2_2 <= 32'b0;

            is_privilege_o <= 2'b0;

            icacop_en_o1 <= 1'b0;
            icacop_en_o2 <= 1'b0;
            dcacop_en_o1 <= 1'b0;
            dcacop_en_o2 <= 1'b0;
            cacop_opcode_o1 <= 5'b0;
            cacop_opcode_o2 <= 5'b0;

            is_exception_o1 <= 4'b0;
            is_exception_o2 <= 4'b0;

            pc_exception_cause_o1 <= 7'b0;
            instbuffer_exception_cause_o1 <= 7'b0;
            decoder_exception_cause_o1 <= 7'b0;
            dispatch_exception_cause_o1 <= 7'b0;
            pc_exception_cause_o2 <= 7'b0;
            instbuffer_exception_cause_o2 <= 7'b0;
            decoder_exception_cause_o2 <= 7'b0;
            dispatch_exception_cause_o2 <= 7'b0;

            invtlb_op_o1 <= 5'b0;
            invtlb_op_o2 <= 5'b0;
            csr_write_en_o <= 2'b0;
            csr_addr_o1 <= 14'b0;
            csr_addr_o2 <= 14'b0;
            csr_read_data_o1 <= 32'b0;
            csr_read_data_o2 <= 32'b0;
            pre_is_branch_taken_o <= 2'b0;
            pre_branch_addr_o1 <= 32'b0;
            pre_branch_addr_o2 <= 32'b0;
        end 
        else if( !pause ) begin
            pc1_o <= ex_pc1_temp;
            pc2_o <= ex_pc2_temp;
            soft1_o <= ex_soft1_temp;
            soft2_o <= ex_soft2_temp;
            inst1_o <= ex_inst1_temp;
            inst2_o <= ex_inst2_temp;
            valid_o <= {ex_valid2_temp, ex_valid1_temp};
            reg_write_en_o <= {ex_reg_write_en2_temp, ex_reg_write_en1_temp};
            reg_write_addr_o1 <= ex_reg_write_addr1_temp;
            reg_write_addr_o2 <= ex_reg_write_addr2_temp;
            alu_op_o1 <= ex_alu_op1_temp;
            alu_op_o2 <= ex_alu_op2_temp;
            alu_sel_o1 <= ex_alu_sel1_temp;
            alu_sel_o2 <= ex_alu_sel2_temp;
            is_div_o <= {ex_is_div_temp[1], ex_is_div_temp[0]};
            is_mul_o <= {ex_is_mul_temp[1], ex_is_mul_temp[0]};
            reg_read_data_o1_1 <= ex_reg_read_data1_1_temp;
            reg_read_data_o1_2 <= ex_reg_read_data1_2_temp;
            reg_read_data_o2_1 <= ex_reg_read_data2_1_temp;
            reg_read_data_o2_2 <= ex_reg_read_data2_2_temp;
            is_privilege_o <= {ex_is_privilege2_temp, ex_is_privilege1_temp};

            icacop_en_o1 <= ex_icacop_en1_temp;
            icacop_en_o2 <= ex_icacop_en2_temp;
            dcacop_en_o1 <= ex_dcacop_en1_temp;
            dcacop_en_o2 <= ex_dcacop_en2_temp;
            cacop_opcode_o2 <= ex_cacop_opcode2_temp;

            is_exception_o1 <= ex_is_exception1_temp;
            is_exception_o2 <= ex_is_exception2_temp;

            pc_exception_cause_o1 <= ex_pc_exception_cause1_temp;
            instbuffer_exception_cause_o1 <= ex_instbuffer_exception_cause1_temp;
            decoder_exception_cause_o1  <= ex_id_exception_cause1_temp;
            dispatch_exception_cause_o1 <= ex_dispatch_exception_cause1_temp;
            pc_exception_cause_o2 <= ex_pc_exception_cause2_temp;
            instbuffer_exception_cause_o2 <= ex_instbuffer_exception_cause2_temp;
            decoder_exception_cause_o2  <= ex_id_exception_cause2_temp;
            dispatch_exception_cause_o2 <= ex_dispatch_exception_cause2_temp;

            invtlb_op_o1 <= ex_invtlb_op1_temp;
            invtlb_op_o2 <= ex_invtlb_op2_temp;
            csr_write_en_o <= {ex_csr_write_en2_temp, ex_csr_write_en1_temp};
            csr_addr_o1 <= ex_csr_addr1_temp;
            csr_addr_o2 <= ex_csr_addr2_temp;
            csr_read_data_o1 <= ex_csr_read_data1_temp;
            csr_read_data_o2 <= ex_csr_read_data2_temp;
            pre_is_branch_taken_o <= {ex_pre_is_branch_taken2_temp, ex_pre_is_branch_taken1_temp};
            pre_branch_addr_o1 <= ex_pre_branch_addr1_temp;
            pre_branch_addr_o2 <= ex_pre_branch_addr2_temp;
        end
        else begin
            //暂停时不做任何操�???
            //保留�???有输出不�???
            pc1_o <= pc1_o;
            pc2_o <= pc2_o;
            soft1_o <= soft1_o;
            soft2_o <= soft2_o;
            inst1_o <= inst1_o;
            inst2_o <= inst2_o;
            valid_o <= valid_o;
            reg_write_en_o <= reg_write_en_o;
            reg_write_addr_o1 <= reg_write_addr_o1;
            reg_write_addr_o2 <= reg_write_addr_o2;
            alu_op_o1 <= alu_op_o1;
            alu_op_o2 <= alu_op_o2;
            alu_sel_o1 <= alu_sel_o1;
            alu_sel_o2 <= alu_sel_o2;
            is_div_o <= is_div_o;
            is_mul_o <= is_mul_o;
            reg_read_data_o1_1 <= reg_read_data_o1_1;
            reg_read_data_o1_2 <= reg_read_data_o1_2;
            reg_read_data_o2_1 <= reg_read_data_o2_1;
            reg_read_data_o2_2 <= reg_read_data_o2_2;
            is_privilege_o <= is_privilege_o;

            icacop_en_o1 <= icacop_en_o1;
            icacop_en_o2 <= icacop_en_o2;
            dcacop_en_o1 <= dcacop_en_o1;
            dcacop_en_o2 <= dcacop_en_o2;
            cacop_opcode_o1 <= cacop_opcode_o1;
            cacop_opcode_o2 <= cacop_opcode_o2;

            is_exception_o1 <= is_exception_o1;
            is_exception_o2 <= is_exception_o2;

            pc_exception_cause_o1 <= pc_exception_cause_o1;
            instbuffer_exception_cause_o1 <= instbuffer_exception_cause_o1;
            decoder_exception_cause_o1  <= decoder_exception_cause_o1;
            dispatch_exception_cause_o1 <= dispatch_exception_cause_o1;
            pc_exception_cause_o2 <= pc_exception_cause_o2;
            instbuffer_exception_cause_o2 <= instbuffer_exception_cause_o2;
            decoder_exception_cause_o2  <= decoder_exception_cause_o2;
            dispatch_exception_cause_o2 <= dispatch_exception_cause_o2;
            invtlb_op_o1 <= invtlb_op_o1;
            invtlb_op_o2 <= invtlb_op_o2;
            
            csr_write_en_o <= csr_write_en_o;
            csr_addr_o1 <= csr_addr_o1;
            csr_addr_o2 <= csr_addr_o2;
            csr_read_data_o1 <= csr_read_data_o1;
            csr_read_data_o2 <= csr_read_data_o2;
            pre_is_branch_taken_o <= pre_is_branch_taken_o;
            pre_branch_addr_o1 <= pre_branch_addr_o1;
            pre_branch_addr_o2 <= pre_branch_addr_o2;
        end
    end
    
endmodule