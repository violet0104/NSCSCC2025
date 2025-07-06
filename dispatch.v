`timescale 1ns / 1ps
//csr还没写


module dispatch
(
    input wire clk,
    input wire rst,

    //控制单元的暂停和刷新信号
    input wire pause,
    input wire flush,

    //数据信息
    input wire [1:0] [31:0] pc_i,      //指令地址
    input wire [1:0] [31:0] inst_i,    //指令编码
    input wire [1:0]        valid_i,   //指令有效标志

    //读使能和地址要同时传输给寄存器堆和ex阶段
    input wire [1:0]        reg_read_en_i0,     //第0条指令的两个源寄存器源寄存器读使能
    input wire [1:0]        reg_read_en_i1,     //第1条指令的两个源寄存器源寄存器读使能   
    input wire [1:0] [4:0]  reg_read_addr_i0,   //第0条指令的两个源寄存器地址
    input wire [1:0] [4:0]  reg_read_addr_i1,   //第1条指令的两个源寄存器地址

    input wire [1:0]        is_privilege_i, //两条指令的特权指令标志
    input wire [1:0]        is_cnt_i,       //两条指令的计数器指令标志
    input wire [1:0] [2:0]  is_exception_i, //两条指令的异常标志
    input wire [1:0] [2:0] [6:0]  exception_cause_i, //两条指令的异常原因,会变长
    input wire [1:0] [4:0]  invtlb_op_i,   //两条指令的分支指令标志

    input wire [1:0]        reg_write_en_i,    //目的寄存器写使能
    input wire [1:0] [4:0]  reg_write_addr_i,  //目的寄存器地址
     
    input wire [1:0] [31:0]  imm_i,     //立即数值
    input wire [1:0] [7:0]  alu_op_i,  //ALU操作码
    input wire [1:0] [2:0]  alu_sel_i, //ALU功能选择

    //前递数据
    input wire [1:0]         ex_pf_write_en,     //从ex阶段前递出来的使能
    input wire [1:0] [4:0]   ex_pf_write_addr,   //从ex阶段前递出来的地址
    input wire [1:0] [31:0]  ex_pf_write_data,   //从ex阶段前递出来的数据

    input wire [1:0]         mem_pf_write_en,    //从mem阶段前递出来的使能
    input wire [1:0] [4:0]   mem_pf_write_addr,  //从mem阶段前递出来的地址
    input wire [1:0] [31:0]  mem_pf_write_data,  //从mem阶段前递出来的数据

    input wire [1:0]         wb_pf_write_en,     //从wb阶段前递出来的使能
    input wire [1:0] [4:0]   wb_pf_write_addr,   //从wb阶段前递出来的地址
    input wire [1:0] [31:0]  wb_pf_write_data,   //从wb阶段前递出来的数据

    //来自ex阶段的，用于判断ex运行的指令是否是load指令
    input wire [1:0]         ex_pre_aluop,       //ex阶段的load指令标志

    //来自ex阶段的，可能由于乘除法等指令引起的暂停信号
    input wire               ex_pause,           //ex阶段的暂停信号

    //输出
    output reg [1:0] [31:0] pc_o,  
    output reg [1:0] [31:0] inst_o,
    output reg [1:0]        valid_o,

    output reg [1:0]        is_privilege_o, //两条指令的特权指令标志
    output reg [1:0] [3:0]  is_exception_o, //两条指令的异常标志
    output reg [1:0] [3:0] [6:0]  exception_cause_o, //两条指令的异常原因,会变长
    output reg [1:0] [4:0]  invtlb_op_o,   //两条指令的分支指令标志

    output reg [1:0]        reg_write_en_o,    //目的寄存器写使能
    output reg [1:0] [4:0]  reg_write_addr_o,  //目的寄存器地址
    
    output reg [1:0] [31:0] reg_read_data_o0, //寄存器堆给出的第0条指令的两个源操作数
    output reg [1:0] [31:0] reg_read_data_o1, //寄存器堆给出的第1条指令的两个源操作数

    output reg [1:0] [7:0]  alu_op_o,
    output reg [1:0] [2:0]  alu_sel_o,

    output wire      [1:0]  invalid_en, //指令发射控制信号

    //与寄存器之间的输入与输出
    input wire [1:0] [31:0]  from_reg_read_data_i0,//寄存器给出的第0条指令的源操作数，这么写可能存在问题？？？
    input wire [1:0] [31:0]  from_reg_read_data_i1,//寄存器给出的第1条指令的源操作数，这么写可能存在问题？？？

    output wire dispatch_pause ,//发射器暂停信号,当发生load-use冒险时需要暂停

    //给csr模块的读使能和读地址
    input wire [1:0]         csr_read_en_i,//csr写使能
    input wire [1:0] [13:0]  csr_addr_i,//寄csr写地址
    input wire [1:0]         csr_write_en_i,//csr写数据
    input wire [1:0]         pre_is_branch_taken_i,// //前一条指令是否是分支指令
    input wire [1:0] [31:0]  pre_branch_addr_i, //前一条指令的分支地址

    input wire [1:0] [31:0]  csr_read_data_i,//csr读数据

    output reg [1:0]        csr_write_en_o, //寄存器堆的csr读使能
    output reg [1:0] [13:0] csr_addr_o, //寄存器堆的csr写地址

    output reg [1:0] [31:0] csr_read_data_o, //寄存器堆的csr写数据
    
    output reg [1:0]        pre_is_branch_taken_o, //前一条指令是否是分支指令
    output reg [1:0] [31:0] pre_branch_addr_o //前一条指令的分支地址
);

    wire [1:0] send_en;     //内部发射信号，给invalid_en赋值
    wire       send_double; //判断是否为双发射的信号 
    
    wire [1:0] inst_valid;  //内部指令有效标志

    wire       cnt_inst; //计数器指令标志，判断发射的两条指令中有没有计数器指令
    wire       privilege_inst; //特权指令标志，判断发射的两条指令中有没有特权指令
    wire       mem_inst;//访存信号标志，判断发射的两条指令中有没有load和store类型
    wire       data_hazard_inst;//数据冒险标志，判断是否出现了数据冒险

    reg  [31:0] pc_temp[1:0]      ; //临时寄存器，存储指令地址
    reg  [31:0] inst_temp[1:0]    ; //临时寄存器，存储指令编码
    reg         valid_temp[1:0];          //临时寄存器，存储指令有效标志
    reg  [7:0]  alu_op_temp [1:0] ; //临时寄存器，存储ALU操作码
    reg  [2:0]  alu_sel_temp[1:0] ; //临时寄存器，存储ALU功能选择
    reg  [1:0]  reg_write_en_temp; //临时寄存器，存储目的寄存器写使能
    reg  [4:0]  reg_write_addr_temp[1:0] ; //临时寄存器，存储目的寄存器地址
    reg  [31:0] reg_read_data_temp0[1:0] ; //寄存器堆给出的第0条指令的两个源操作数
    reg  [31:0] reg_read_data_temp1[1:0] ; //寄存器堆给出的第1条指令的两个源操作数
    reg  [1:0]  is_privilege_temp; //临时寄存器，存储特权指令标志
    reg  [3:0]  is_exception_temp[1:0]; //两条指令的异常标志
    reg  [3:0] [6:0]  exception_cause_temp[1:0]; //两条指令的异常原因,会变长
    reg  [4:0]  invtlb_op_temp[1:0];   //两条指令的分支指令标志
    reg  [1:0]  csr_write_en_temp; //临时寄存器，存储csr写使能
    reg  [13:0] csr_addr_temp[1:0]; //临时寄存器，存储csr写地址
    reg  [1:0]  pre_is_branch_taken_temp; //临时寄存器，存储前一条指令是否是分支指令
    reg  [31:0] pre_branch_addr_temp[1:0]; //临时寄存器，存储前一条指令的分支地址
    reg  [31:0] csr_read_data_temp[1:0]; //临时寄存器，存储csr读数据

    assign invalid_en = pause ? 2'b00 : send_en;//发射控制信号赋值

    assign inst_valid = {valid_i[1] , valid_i[0]};//内部有效标志赋值
    

    assign privilege_inst = (is_privilege_i[0] == 1'b1 || is_privilege_i[1] == 1'b1);//判断发射的两条指令中有没有特权指令
    assign mem_inst = (alu_sel_i[0] == `ALU_SEL_LOAD_STORE || alu_sel_i[1] == `ALU_SEL_LOAD_STORE);//判断发射的两条指令中有没有load和store类型的指令
    //下面这条语句，检验了将要双发射的这两条指令间是否存在数据相关冒险
    assign data_hazard_inst = (reg_write_en_i[0] == 1'b1 && reg_write_addr_i[0] != 5'b0)//第0条指令有写寄存器的功能
                            &&((reg_write_addr_i[0] == reg_read_addr_i1[0] && reg_read_en_i1[0])//第0条指令的写寄存器的地址与第1条指令第1个源寄存器相同
                            ||(reg_write_addr_i[0] == reg_read_addr_i1[0] && reg_read_en_i1[1]));//第0条指令的写寄存器的地址与第1条指令第2个源寄存器相同
    assign cnt_inst = (is_cnt_i[0] == 1'b1 || is_cnt_i[1] == 1'b1);//判断发射的两条指令中有没有计数器指令

    assign send_double = (!mem_inst) && (!data_hazard_inst) && (!cnt_inst) && (!privilege_inst) && (&inst_valid); //判断这两条指令能否同时发射
    assign send_en = (send_double == 1'b1) ? 2'b11 : (inst_valid[0] ? 2'b01 : (inst_valid[1] ? 2'b10 : 2'b00));//当指令不能双发射时优先发第一条

    integer i;
    integer j;

    //信号传输(指令的读数据怎么办)？？？？？？？
    always @(*) begin
        for ( i = 0; i < 2 ; i = i + 1) begin
            pc_temp[i] = pc_i[i];
            inst_temp[i] = inst_i[i];
            valid_temp[i] = valid_i[i];
            alu_op_temp[i] = alu_op_i[i];
            alu_sel_temp[i] = alu_sel_i[i];
            reg_write_en_temp[i] = reg_write_en_i[i];
            reg_write_addr_temp[i] = reg_write_addr_i[i];
            is_privilege_temp[i] = is_privilege_i[i];
            is_exception_temp[i] = {is_exception_i[i],1'b0};
            exception_cause_temp[i] = {exception_cause_i[i],`EXCEPTION_NOP};
            invtlb_op_temp[i] = invtlb_op_i[i];
            csr_write_en_temp[i] = csr_write_en_i[i];
            csr_addr_temp[i] = csr_addr_i[i];
            pre_is_branch_taken_temp[i] = pre_is_branch_taken_i[i];
            pre_branch_addr_temp[i] = pre_branch_addr_i[i];
        end
    end
    
    always @(*) begin
        //正常的读数据
        for( i = 0 ; i < 2 ; i = i + 1)begin//两个源寄存器
            if(reg_read_en_i0[i] == 1'b1) begin
                reg_read_data_temp0[i] = from_reg_read_data_i0[i];
            end else begin
                reg_read_data_temp0[i] = imm_i[0]; //如果没有读使能，则赋值立即数
            end
            if(reg_read_en_i1[i] == 1'b1) begin
                reg_read_data_temp1[i] = from_reg_read_data_i1[i];
            end else begin
                reg_read_data_temp1[i] = imm_i[1]; //如果没有读使能，则赋值立即数
            end
        end
        //与写回阶段有数据冲突进行数据前递
        for ( i = 0 ; i < 2 ; i = i + 1) begin//两个源寄存器
            for( j = 0 ; j < 2 ; j = j + 1)begin//wb阶段的前递回的两条指令
                if(wb_pf_write_en[j] == 1'b1 && reg_read_en_i0[i] == 1'b1) begin
                    if(reg_read_addr_i0[i] == wb_pf_write_addr[j]) begin
                        reg_read_data_temp0[i] = wb_pf_write_data[j];
                    end
                end
                if(wb_pf_write_en[j] == 1'b1 && reg_read_en_i1[i] == 1'b1) begin
                    if(reg_read_addr_i1[i] == wb_pf_write_addr[j]) begin
                        reg_read_data_temp1[i] = wb_pf_write_data[j];
                    end
                end
            end
        end
        //与访存阶段有数据冲突进行数据前递
        for ( i = 0 ; i < 2 ; i = i + 1) begin//两个源寄存器
            for( j = 0 ; j < 2 ; j = j + 1)begin//mem阶段的前递回的两条指令
                if(mem_pf_write_en[j] == 1'b1 && reg_read_en_i0[i] == 1'b1) begin
                    if(reg_read_addr_i0[i] == mem_pf_write_addr[j]) begin
                        reg_read_data_temp0[i] = mem_pf_write_data[j];
                    end
                end
                if(mem_pf_write_en[j] == 1'b1 && reg_read_en_i1[i] == 1'b1) begin
                    if(reg_read_addr_i1[i] == mem_pf_write_addr[j]) begin
                        reg_read_data_temp1[i] = mem_pf_write_data[j];
                    end
                end
            end
        end
        //与执行阶段有数据冲突进行数据前递
        for ( i = 0 ; i < 2 ; i = i + 1) begin//两个源寄存器
            for( j = 0 ; j < 2 ; j = j + 1)begin//ex阶段的前递回的两条指令
                if(ex_pf_write_en[j] == 1'b1 && reg_read_en_i0[i] == 1'b1) begin
                    if(reg_read_addr_i0[i] == ex_pf_write_addr[j]) begin
                        reg_read_data_temp0[i] = ex_pf_write_data[j];
                    end
                end
                if(ex_pf_write_en[j] == 1'b1 && reg_read_en_i1[i] == 1'b1) begin
                    if(reg_read_addr_i1[i] == ex_pf_write_addr[j]) begin
                        reg_read_data_temp1[i] = ex_pf_write_data[j];
                    end
                end
            end
        end
        for ( i = 0 ; i < 2 ; i = i + 1) begin
            if(reg_read_en_i0[i] == 1'b1 && reg_read_addr_i0[i] == 5'b0) begin
                reg_read_data_temp0[i] = 32'b0; //如果源寄存器地址为0，则赋值为0
            end
            if(reg_read_en_i1[i] == 1'b1 && reg_read_addr_i1[i] == 5'b0) begin
                reg_read_data_temp1[i] = 32'b0; //如果源寄存器地址为0，则赋值为0
            end
        end
        for( i = 0 ; i < 2 ; i = i + 1) begin
            if(alu_op_i[0] == `ALU_PCADDU12I && reg_read_en_i0[i] == 1'b1) begin
                reg_read_data_temp0[i] = pc_i[0]; 
            end
            if(alu_op_i[1] == `ALU_PCADDU12I && reg_read_en_i1[i] == 1'b1) begin
                reg_read_data_temp1[i] = pc_i[1]; 
            end
        end
    end

    //csr
        always @(*) begin
            for( i = 0 ; i < 2 ; i = i + 1) begin
                if(csr_read_en_i[i] == 1'b1) begin
                    csr_read_data_temp[i] = csr_read_data_i[i];
                end else begin
                    csr_read_data_temp[i] = 32'b0; //如果没有读使能，则赋值为0
                end
            end
        end


    //load-use冒险比起一般的数据冒险更严重。
    //一般的数据冒险在执行阶段就可得到结果
    //load-use冒险则需要在访存阶段后才能结束

    wire        pre_load; //判断先前的指令是否是load指令
    wire [1:0]  reg_relate_i0;//第0条指令的源寄存器与前一条load指令相关
    wire [1:0]  reg_relate_i1;//第1条指令的源寄存器与前一条load指令相关

    //判断这时候在ex阶段的指令是否是load指令
    assign pre_load = (ex_pre_aluop[0] == `ALU_LDB) 
                    || (ex_pre_aluop[0] == `ALU_LDH) 
                    || (ex_pre_aluop[0] == `ALU_LDW) 
                    || (ex_pre_aluop[0] == `ALU_LDBU) 
                    || (ex_pre_aluop[0] == `ALU_LDHU) 
                    || (ex_pre_aluop[0] == `ALU_LLW)
                    || (ex_pre_aluop[0] == `ALU_SCW)
                    || (ex_pre_aluop[1] == `ALU_LDB) 
                    || (ex_pre_aluop[1] == `ALU_LDH) 
                    || (ex_pre_aluop[1] == `ALU_LDW) 
                    || (ex_pre_aluop[1] == `ALU_LDBU) 
                    || (ex_pre_aluop[1] == `ALU_LDHU) 
                    || (ex_pre_aluop[1] == `ALU_LLW)
                    || (ex_pre_aluop[1] == `ALU_SCW);

    //判断发射器中的两条指令是否与当前ex阶段的load指令相关（load指令一次只发一条）
    assign    reg_relate_i0[0] = (pre_load && reg_read_en_i0[0] == 1'b1 && reg_read_addr_i0[0] == ex_pf_write_addr[0]);
    assign    reg_relate_i1[0] = (pre_load && reg_read_en_i1[0] == 1'b1 && reg_read_addr_i1[0] == ex_pf_write_addr[0]);
    assign    reg_relate_i0[1] = (pre_load && reg_read_en_i0[1] == 1'b1 && reg_read_addr_i0[1] == ex_pf_write_addr[0]);
    assign    reg_relate_i1[1] = (pre_load && reg_read_en_i1[1] == 1'b1 && reg_read_addr_i1[1] == ex_pf_write_addr[0]);

    assign dispatch_pause = | (reg_relate_i0 | reg_relate_i1); //若存在load-use冒险，则暂停发射器

    reg [1:0][31:0] ex_pc_temp             ; 
    reg [1:0][31:0] ex_inst_temp           ; 
    reg [1:0]  ex_valid_temp;          
    reg [1:0][7:0]  ex_alu_op_temp         ; 
    reg [1:0][2:0]  ex_alu_sel_temp        ; 
    reg [1:0]  ex_reg_write_en_temp; 
    reg [1:0][4:0]  ex_reg_write_addr_temp ; 
    reg [1:0][31:0] ex_reg_read_data_temp0 ; 
    reg [1:0][31:0] ex_reg_read_data_temp1 ; 
    reg [1:0]  ex_is_privilege_temp; //临时寄存器，存储特权指令标志
    reg [1:0] [3:0]  ex_is_exception_temp; //两条指令的异常标志
    reg [1:0] [3:0] [6:0]  ex_exception_cause_temp; //两条指令的异常原因,会变长
    reg [1:0] [4:0]  ex_invtlb_op_temp;   //两条指令的分支指令标志
    reg [1:0]  ex_csr_write_en_temp; //临时寄存器，存储csr写使能
    reg [1:0] [13:0] ex_csr_addr_temp; //临时寄存器，存储csr写地址
    reg [1:0]        ex_pre_is_branch_taken_temp; //临时寄存器，存储前一条指令是否是分支指令
    reg [1:0] [31:0] ex_pre_branch_addr_temp; //临时寄存器，存储前一条指令的分支地址
    reg [1:0] [31:0] ex_csr_read_data_temp; //临时寄存器，存储csr读数据

    always @(*) begin
        if(send_en[0])begin
            ex_pc_temp[0] = pc_temp[0];
            ex_inst_temp[0] = inst_temp[0];
            ex_valid_temp[0] = valid_temp[0];
            ex_alu_op_temp[0] = alu_op_temp[0];
            ex_alu_sel_temp[0] = alu_sel_temp[0];
            ex_reg_write_en_temp[0] = reg_write_en_temp[0];
            ex_reg_write_addr_temp[0] = reg_write_addr_temp[0];
            ex_reg_read_data_temp0[0] = reg_read_data_temp0[0];
            ex_reg_read_data_temp0[1] = reg_read_data_temp0[1];
            ex_is_privilege_temp[0] = is_privilege_temp[0];
            ex_is_exception_temp[0] = is_exception_temp[0];
            ex_exception_cause_temp[0] = exception_cause_temp[0];
            ex_invtlb_op_temp[0] = invtlb_op_temp[0];
            ex_csr_write_en_temp[0] = csr_write_en_temp[0];
            ex_csr_addr_temp[0] = csr_addr_temp[0];
            ex_pre_is_branch_taken_temp[0] = pre_is_branch_taken_temp[0];
            ex_pre_branch_addr_temp[0] = pre_branch_addr_temp[0];
            ex_csr_read_data_temp[0] = csr_read_data_temp[0];
        end 
        else begin
            ex_pc_temp[0] = 32'b0;
            ex_inst_temp[0] = 32'b0;    
            ex_valid_temp[0] = 1'b0;
            ex_alu_op_temp[0] = 8'b0;
            ex_alu_sel_temp[0] = 3'b0;
            ex_reg_write_en_temp[0] = 1'b0;
            ex_reg_write_addr_temp[0] = 5'b0;
            ex_reg_read_data_temp0[0] = 32'b0;
            ex_reg_read_data_temp0[1] = 32'b0;
            ex_is_privilege_temp[0] = 1'b0;
            ex_is_exception_temp[0] = 4'b0;
            ex_exception_cause_temp[0] = 7'b0;
            ex_invtlb_op_temp[0] = 5'b0;
            ex_csr_write_en_temp[0] = 1'b0;
            ex_csr_addr_temp[0] = 14'b0;
            ex_pre_is_branch_taken_temp[0] = 1'b0;
            ex_pre_branch_addr_temp[0] = 32'b0;
            ex_csr_read_data_temp[0] = 32'b0;
        end
        if(send_en[1]) begin
             ex_pc_temp[1] = pc_temp[1];
            ex_inst_temp[1] = inst_temp[1];
            ex_valid_temp[1] = valid_temp[1];
            ex_alu_op_temp[1] = alu_op_temp[1];
            ex_alu_sel_temp[1] = alu_sel_temp[1];
            ex_reg_write_en_temp[1] = reg_write_en_temp[1];
            ex_reg_write_addr_temp[1] = reg_write_addr_temp[1];
            ex_reg_read_data_temp1[0] = reg_read_data_temp1[0];
            ex_reg_read_data_temp1[1] = reg_read_data_temp1[1];
            ex_is_privilege_temp[1] = is_privilege_temp[1];
            ex_is_exception_temp[1] = is_exception_temp[1];
            ex_exception_cause_temp[1] = exception_cause_temp[1];
            ex_invtlb_op_temp[1] = invtlb_op_temp[1];
            ex_csr_write_en_temp[1] = csr_write_en_temp[1];
            ex_csr_addr_temp[1] = csr_addr_temp[1];
            ex_pre_is_branch_taken_temp[1] = pre_is_branch_taken_temp[1];
            ex_pre_branch_addr_temp[1] = pre_branch_addr_temp[1];
            ex_csr_read_data_temp[1] = csr_read_data_temp[1];
        end
        else begin
            ex_pc_temp[1] = 32'b0;
            ex_inst_temp[1] = 32'b0;    
            ex_valid_temp[1] = 1'b0;
            ex_alu_op_temp[1] = 8'b0;
            ex_alu_sel_temp[1] = 3'b0;
            ex_reg_write_en_temp[1] = 1'b0;
            ex_reg_write_addr_temp[1] = 5'b0;
            ex_reg_read_data_temp1[0] = 32'b0;
            ex_reg_read_data_temp1[1] = 32'b0;
            ex_is_privilege_temp[1] = 1'b0;
            ex_is_exception_temp[1] = 4'b0;
            ex_exception_cause_temp[1] = 7'b0;
            ex_invtlb_op_temp[1] = 5'b0;
            ex_csr_write_en_temp[1] = 1'b0;
            ex_csr_addr_temp[1] = 14'b0;
            ex_pre_is_branch_taken_temp[1] = 1'b0;
            ex_pre_branch_addr_temp[1] = 32'b0;
            ex_csr_read_data_temp[1] = 32'b0;
        end
    end
    wire dispatch_current_pause;//当前发射器的暂停信号
    assign dispatch_current_pause =  !ex_pause && dispatch_pause;//如果ex阶段没有暂停且发生load-use冒险，则发射器暂停 
    //上面那句代码有疑问

    always @(posedge clk) begin
        if(rst || flush || dispatch_current_pause) begin
            pc_o <= 2'b0;
            inst_o <= 2'b0;
            valid_o <= 2'b0;
            reg_write_en_o <= 2'b0;
            reg_write_addr_o <= 2'b0;
            alu_op_o <= 2'b0;
            alu_sel_o <= 2'b0;
            reg_read_data_o0 <= 2'b0;
            reg_read_data_o1 <= 2'b0;
            is_privilege_o <= 2'b0;
            is_exception_o <= 2'b0;
            exception_cause_o <= 2'b0;
            invtlb_op_o <= 2'b0;
            csr_write_en_o <= 2'b0;
            csr_addr_o <= 2'b0;
            csr_read_data_o <= 2'b0;
            pre_is_branch_taken_o <= 2'b0;
            pre_branch_addr_o <= 2'b0;
        end 
        else if( !pause ) begin
            pc_o <= ex_pc_temp;
            inst_o <= ex_inst_temp;
            valid_o <= ex_valid_temp;
            reg_write_en_o <= ex_reg_write_en_temp;
            reg_write_addr_o <= ex_reg_write_addr_temp;
            alu_op_o <= ex_alu_op_temp;
            alu_sel_o <= ex_alu_sel_temp;
            reg_read_data_o0 <= ex_reg_read_data_temp0;
            reg_read_data_o1 <= ex_reg_read_data_temp1;
            is_privilege_o <= ex_is_privilege_temp;
            is_exception_o <= ex_is_exception_temp;
            exception_cause_o <= ex_exception_cause_temp;
            invtlb_op_o <= ex_invtlb_op_temp;
            csr_write_en_o <= ex_csr_write_en_temp;
            csr_addr_o <= ex_csr_addr_temp;
            csr_read_data_o <= ex_csr_read_data_temp;
            pre_is_branch_taken_o <= ex_pre_is_branch_taken_temp;
            pre_branch_addr_o <= ex_pre_branch_addr_temp;
        end
        else begin
            //暂停时不做任何操作
            pc_o <= pc_o;
            inst_o <= inst_o;
            valid_o <= valid_o;
            reg_write_en_o <= reg_write_en_o;
            reg_write_addr_o <= reg_write_addr_o;
            alu_op_o <= alu_op_o;
            alu_sel_o <= alu_sel_o;
            reg_read_data_o0 <= reg_read_data_o0;
            reg_read_data_o1 <= reg_read_data_o1;
            is_privilege_o <= is_privilege_o;
            is_exception_o <= is_exception_o;
            exception_cause_o <= exception_cause_o;
            invtlb_op_o <= invtlb_op_o;
            csr_write_en_o <= csr_write_en_o;
            csr_addr_o <= csr_addr_o;
            csr_read_data_o <= csr_read_data_o;
            pre_is_branch_taken_o <= pre_is_branch_taken_o;
            pre_branch_addr_o <= pre_branch_addr_o;
        end
    end
    
endmodule