`timescale 1ns / 1ps

module dispatch
(
    input wire clk,
    input wire clk,

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

    //输出
    output reg [1:0] [31:0] pc_o,  
    output reg [1:0] [31:0] inst_o,
    output reg [1:0]        valid_o,

    output reg [1:0]        reg_read_en_o0,     //第0条指令的两个源寄存器读使能   
    output reg [1:0]        reg_read_en_o1,     //第1条指令的两个源寄存器读使能
    output reg [1:0] [4:0]  reg_read_addr_o0,   //第0条指令的两个源寄存器地址
    output reg [1:0] [4:0]  reg_read_addr_o1,   //第1条指令的两个源寄存器地址

    output reg [1:0]        reg_write_en_o,    //目的寄存器写使能
    output reg [1:0] [4:0]  reg_write_addr_o,  //目的寄存器地址
    
    output reg [1:0] [31:0] reg_read_data_o0, //寄存器堆给出的第0条指令的两个源操作数
    output reg [1:0] [31:0] reg_read_data_o1, //寄存器堆给出的第1条指令的两个源操作数

    output reg [1:0] [4:0]  imm_o,
    output reg [1:0] [7:0]  alu_op_o,
    output reg [1:0] [2:0]  alu_sel_o,

    output wire       [1:0]  invalid_en //指令发射控制信号

    //与寄存器之间的输入与输出
    input wire [1:0] [31:0]  from_reg_read_data_i0;//寄存器给出的第0条指令的源操作数，这么写可能存在问题？？？
    input wire [1:0] [31:0]  from_reg_read_data_i1;//寄存器给出的第1条指令的源操作数，这么写可能存在问题？？？

);

    wire [1:0] send_en;     //内部发射信号，给invalid_en赋值
    wire       send_double; //判断是否为双发射的信号 
    
    wire [1:0] inst_valid;  //内部指令有效标志

    wire       mem_inst;//访存信号标志，判断发射的两条指令中有没有load和store类型
    wire       data_hazard_inst;//数据冒险标志，判断是否出现了数据冒险

    assign invalid_en = pause ? 2'b00 : send_en;//发射控制信号赋值

    assign inst_valid = {valid_i[1] , valid_i[0]};//内部有效标志赋值
    
    assign mem_inst = (alu_sel_i[0] == `ALU_SEL_LOAD_STORE || alu_sel_i[1] == `ALU_SEL_LOAD_STORE);//判断发射的两条指令中有没有load和store类型的指令
    //下面这条语句，检验了将要双发射的这两条指令间是否存在数据相关冒险
    assign data_hazard_inst = (reg_write_en_i[0] == 1'b1 && reg_write_addr_i[o] != 5'b0)//第0条指令有写寄存器的功能
                            &&((reg_write_addr_i[0] == reg_read_addr_i1[0] && reg_read_en_i1[0])//第0条指令的写寄存器的地址与第1条指令第1个源寄存器相同
                            ||(reg_write_addr_i[0] == reg_read_addr_i1[0] && reg_read_en_i1[1]));//第0条指令的写寄存器的地址与第1条指令第2个源寄存器相同

    assign send_double = (!mem_inst) && (!data_hazard_inst); //判断这两条指令能否同时发射
    assign send_en = (send_double == 1'b1) ? 2'b11 : (inst_valid[0] ? 2'b01 : (inst_valid[1] ? 2'b10 : 2'b00));//当指令不能双发射时优先发第一条

    //信号传输(指令的读数据怎么办)？？？？？？？
    always @(*) begin
        for (integer i = 0; i < 2 ; i++) begin
            pc_o[i] = pc_i[i];
            inst_o[i] = inst_i[i];
            valid_o[i] = valid_i[i];
            alu_op_o[i] = alu_op_i[i];
            alu_sel_o[i] = alu_sel_i[i];
            reg_write_en_o[i] = reg_write_en_i[i];
            reg_write_addr_o[i] = reg_write_addr_i[i];
            reg_read_en_o0[i] = reg_read_en_i0[i];
            reg_read_en_o1[i] = reg_read_en_i1[i];
            reg_read_addr_o0[i] = reg_read_addr_i0[i];
            reg_read_addr_o1[i] = reg_read_addr_i1[i];
            imm_o[i] = imm_i[i];
        end
    end
    
    always @(*) begin
        //正常的读数据
        for(integer i = 0 ; i < 2 ; i++)begin//两个源寄存器
            if(reg_read_en_i0[i] == 1'b1) begin
                reg_read_data_o0[i] = from_reg_read_data_i0[i];
            end else begin
                reg_read_data_o0[i] = imm_i[0]; //如果没有读使能，则赋值立即数
            end
            if(reg_read_en_i1[i] == 1'b1) begin
                reg_read_data_o1[i] = from_reg_read_data_i1[i];
            end else begin
                reg_read_data_o1[i] = imm_i[1]; //如果没有读使能，则赋值立即数
            end
        end
        //与写回阶段有数据冲突进行数据前递
        for (integer i = 0 ; i < 2 ; i++) begin//两个源寄存器
            for(integer j = 0 ; j < 2 ; j++)begin//wb阶段的前递回的两条指令
                if(wb_pf_write_en[j] == 1'b1 && reg_read_en_i0[i] == 1'b1) begin
                    if(reg_read_addr_i0[i] == wb_pf_write_addr[j]) begin
                        reg_read_data_o0[i] = wb_pf_write_data[j];
                    end
                end
                if(wb_pf_write_en[j] == 1'b1 && reg_read_en_i1[i] == 1'b1) begin
                    if(reg_read_addr_i1[i] == wb_pf_write_addr[j]) begin
                        reg_read_data_o1[i] = wb_pf_write_data[j];
                    end
                end
            end
        end
        //与访存阶段有数据冲突进行数据前递
        for (integer i = 0 ; i < 2 ; i++) begin//两个源寄存器
            for(integer j = 0 ; j < 2 ; j++)begin//mem阶段的前递回的两条指令
                if(mem_pf_write_en[j] == 1'b1 && reg_read_en_i0[i] == 1'b1) begin
                    if(reg_read_addr_i0[i] == mem_pf_write_addr[j]) begin
                        reg_read_data_o0[i] = mem_pf_write_data[j];
                    end
                end
                if(mem_pf_write_en[j] == 1'b1 && reg_read_en_i1[i] == 1'b1) begin
                    if(reg_read_addr_i1[i] == mem_pf_write_addr[j]) begin
                        reg_read_data_o1[i] = mem_pf_write_data[j];
                    end
                end
            end
        end
        //与执行阶段有数据冲突进行数据前递
        for (integer i = 0 ; i < 2 ; i++) begin//两个源寄存器
            for(integer j = 0 ; j < 2 ; j++)begin//ex阶段的前递回的两条指令
                if(ex_pf_write_en[j] == 1'b1 && reg_read_en_i0[i] == 1'b1) begin
                    if(reg_read_addr_i0[i] == ex_pf_write_addr[j]) begin
                        reg_read_data_o0[i] = ex_pf_write_data[j];
                    end
                end
                if(ex_pf_write_en[j] == 1'b1 && reg_read_en_i1[i] == 1'b1) begin
                    if(reg_read_addr_i1[i] == ex_pf_write_addr[j]) begin
                        reg_read_data_o1[i] = ex_pf_write_data[j];
                    end
                end
            end
        end
        for (integer i = 0 ; i < 2 ; i++) begin
            if(reg_read_en_i0[i] == 1'b1 && reg_read_addr_i0[i] == 5'b0) begin
                reg_read_data_o0[i] = 32'b0; //如果源寄存器地址为0，则赋值为0
            end
            if(reg_read_en_i1[i] == 1'b1 && reg_read_addr_i1[i] == 5'b0) begin
                reg_read_data_o1[i] = 32'b0; //如果源寄存器地址为0，则赋值为0
            end
        end
        for(integer i = 0 ; i < 2 ; i++) begin
            if(alu_op_i[0] == `ALU_PCADDU12I && reg_read_en_i0[i] == 1'b1) begin
                reg_read_data_o0[i] = pc_i[0]; 
            end
            if(alu_op_i[1] == `ALU_PCADDU12I && reg_read_en_i1[i] == 1'b1) begin
                reg_read_data_o1[i] = pc_i[1]; 
            end
        end
    end
    


    
endmodule