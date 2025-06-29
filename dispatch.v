`timescale 1ns / 1ps

module dispatch
(
    input wire clk,
    input wire clk,

    //控制单元的暂停和刷新信号
    input wire pause,
    input wire flush,

    //数据信息
    input [1:0] [31:0] pc_i,      //指令地址
    input [1:0] [31:0] inst_i,    //指令编码
    input [1:0]        valid_i,   //指令有效标志

    input [1:0]        reg_read_en_i,     //源寄存器读使能   
    input [1:0] [4:0]  reg_read_addr_i,   //源寄存器地址
    
    input [1:0]        reg_write_en_i,    //目的寄存器写使能
    input [1:0] [4:0]  reg_write_addr_i,  //目的寄存器地址
     
    input [1:0] [4:0]  imm_i,     //立即数值
    input [1:0] [7:0]  alu_op_i,  //ALU操作码
    input [1:0] [2:0]  alu_sel_i, //ALU功能选择

    //前递数据
    input [1:0]         ex_pf_write_en,     //从ex阶段前递出来的使能
    input [1:0] [4:0]   ex_pf_write_addr,   //从ex阶段前递出来的地址
    input [1:0] [31:0]  ex_pf_write_data,   //从ex阶段前递出来的数据

    input [1:0]         mem_pf_write_en,    //从mem阶段前递出来的使能
    input [1:0] [4:0]   mem_pf_write_addr,  //从mem阶段前递出来的地址
    input [1:0] [31:0]  mem_pf_write_data,  //从mem阶段前递出来的数据

    input [1:0]         wb_pf_write_en,     //从wb阶段前递出来的使能
    input [1:0] [4:0]   wb_pf_write_addr,   //从wb阶段前递出来的地址
    input [1:0] [31:0]  wb_pf_write_data,   //从wb阶段前递出来的数据

    //???要输出什么呢
    output [1:0] [31:0] pc_o,  
    output [1:0] [31:0] inst_o,
    output [1:0]        valid_o,

    output [1:0]        reg_read_en_o,
    output [1:0] [4:0]  reg_read_addr_o,
    
    output [1:0]        reg_write_en_o,
    output [1:0] [4:0]  reg_write_addr_o,
     
    output [1:0] [4:0]  imm_o,
    output [1:0] [7:0]  alu_op_o,
    output [1:0] [2:0]  alu_sel_o,

    output       [1:0]  invalid_en //指令发射控制信号
);

    wire [1:0] send_en;     //内部发射信号
    wire       send_double; //判断是否为双发射的信号 
    
    wire [1:0] inst_valid;  //内部指令有效标志
    
endmodule