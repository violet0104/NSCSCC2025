`include "defines.vh"
`timescale 1ns / 1ps

module mem
(
    input  wire clk,
    input  wire rst,
    input  wire [31:0] pc,
    input  wire [31:0] inst,

    // 执行阶段的信号
    input  wire [1:0][4:0] is_exception,   //异常标志
    input  wire [1:0][4:0][6:0] exception_cause, //异常原因
    input  wire [1:0]is_privilege, //特权指令标志
    input  wire [1:0]is_ertn, //是否是异常返回指令
    input  wire [1:0]is_idle, //是否是空闲指令
    input  wire [1:0]valid, //指令是否有效
    input  wire [1:0]reg_write_en,  //寄存器写使能信号
    input  wire [1:0][4:0]reg_write_addr,
    input  wire [1:0][31:0] reg_write_data, //寄存器写数据
    input  wire [1:0][7:0]aluop,
    input  wire [1:0][31:0]mem_addr, //内存地址
    input  wire [1:0][31:0]mem_write_data, //内存写数据
    input  wire [1:0]csr_write_en, //CSR寄存器写使能
    input  wire [1:0][13:0] csr_addr, //CSR寄存器地址
    input  wire [1:0]is_llw_scw, //是否是LLW/SCW指令

    //dcache的信号
    input  wire [31:0] dcache_read_data, 
    input  wire addr_ok,
    input  wire data_ok, //数据访问完成信号
    input  wire [31:0] dcache_P_addr,
    
    output wire valid,
    output wire op,//操作类型
    output wire [31:0] dcache_V_addr, //内存读数据
    output wire wstrb, //写使能信号
    output wire [31:0] dcache_write_data, //内存写数据


    // 输出给dispatcher的信号
    output reg  [1:0]mem_pf_reg_write_en, 
    output reg  [1:0][4:0] mem_pf_reg_write_addr,
    output reg  [1:0][31:0] mem_pf_reg_write_data,

    // 输出给ctrl的信号
    output reg   pause_mem, //通知暂停内存访问信号

    //输出给wb的信号
    output reg  [1:0]wb_reg_write_en, 
    output reg  [1:0][4:0] wb_reg_write_addr,
    output reg  [1:0][31:0] wb_reg_write_data,

    output reg  [1:0]wb_csr_write_en, //CSR寄存器写使能
    output reg  [1:0][13:0] wb_csr_addr, //CSR寄存器地址
    output reg  [1:0][31:0] wb_csr_write_data,
    output reg  [1:0]wb_is_llw_scw, //是否是LLW/SCW指令

    //commit_ctrl的信号
    output reg  [1:0] commit_valid, //指令是否有效
    output reg  [1:0][5:0]  commit_is_exception,
    output reg  [1:0][5:0][6:0] commit_exception_cause, //异常原因
    output reg  [1:0][31:0] commit_pc,
    output reg  [1:0][31:0] commit_addr, //内存地址
    output reg  [1:0] commit_idle, //是否是空闲指令
    output reg  [1:0] commit_ertn, //是否是异常返回指令
    output reg  [1:0] commit_is_privilege //特权指令

   `ifdef DIFF
    // diff
    output reg  [1:0][31:0] debug_wb_pc, // debug信息：写回阶段的PC
    output reg  [1:0][31:0] debug_wb_inst, 
    output reg  [1:0][3:0] debug_wb_rf_we, 
    output reg  [1:0][4:0] debug_wb_rf_wnum, // debug信息：寄存器写地址
    output reg  [1:0][31:0] debug_wb_rf_wdata, // debug信息：寄存器写数据
    output reg  [1:0] inst_valid, // debug信息：指令是否有效
    output reg  [1:0] cnt_inst,
    output reg  [1:0] csr_rstat_en,
    output reg  [1:0][31:0] csr_data,
    output reg  [1:0]excp_flush,
    output reg  [1:0]ertn_flush,
    output reg  [1:0][5:0] ecode,
    output reg  [1:0][7:0] inst_st_en,
    output reg  [1:0][31:0] st_paddr, //存储器地址
    output reg  [1:0][31:0] st_vaddr, //虚拟地址
    output reg  [1:0][31:0] st_data, //存储器写数据
    output reg  [1:0][7:0] inst_ld_en, //加载指令使能
    output reg  [1:0][31:0] ld_paddr, //加载指令地址
    output reg  [1:0][31:0] ld_vaddr, //加载指令虚拟地址
    output reg  [1:0] tlbfill_en, //TLB填充使能
    `endif 
);

    assign mem_pf_reg_write_en[0] = reg_write_en[0];
    assign mem_pf_reg_write_en[1] = reg_write_en[1];
    assign mem_pf_reg_write_addr[0] = reg_write_addr[0];
    assign mem_pf_reg_write_addr[1] = reg_write_addr[1];
    assign mem_pf_reg_write_data[0] = reg_write_data[0];
    assign mem_pf_reg_write_data[1] = reg_write_data[1];

    assign wb_reg_write_en[0] = reg_write_en[0];
    assign wb_reg_write_en[1] = reg_write_en[1];
    assign wb_reg_write_addr[0] = reg_write_addr[0];
    assign wb_reg_write_addr[1] = reg_write_addr[1];
    assign wb_is_llw_scw[0] = is_llw_scw[0];
    assign wb_is_llw_scw[1] = is_llw_scw[1];
    assign wb_csr_write_en[0] = csr_write_en[0];
    assign wb_csr_write_en[1] = csr_write_en[1];
    assign wb_csr_addr[0] = csr_addr[0];
    assign wb_csr_addr[1] = csr_addr[1];
    assign wb_csr_write_data[0] = reg_write_data[0];
    assign wb_csr_write_data[1] = reg_write_data[1];

    reg [1:0][5:0] mem_is_exception_reg;
    reg [1:0][5:0][6:0] mem_exception_cause_reg;

    assign mem_is_exception_reg[0] = {is_exception[0],1'b0};
    assign mem_is_exception_reg[1] = {is_exception[1],1'b0};
    assign mem_exception_cause_reg[0] = {exception_cause[0],`EXCEPTION_NOP};
    assign mem_exception_cause_reg[1] = {exception_cause[1],`EXCEPTION_NOP};

    assign commit_is_exception[0] = mem_is_exception_reg[0];
    assign commit_is_exception[1] = mem_is_exception_reg[1];
    assign commit_pc[0] = pc;
    assign commit_pc[1] = pc;
    assign commit_addr[0] = mem_addr[0];
    assign commit_addr[1] = mem_addr[1];
    assign commit_is_privilege[0] = is_privilege[0];
    assign commit_is_privilege[1] = is_privilege[1];
    assign commit_valid[0] = valid[0];
    assign commit_valid[1] = valid[1];
    assign commit_ertn[0] = is_ertn[0];
    assign commit_ertn[1] = is_ertn[1];
    assign commit_idle[0] = is_idle[0];
    assign commit_idle[1] = is_idle[1];

    reg [1:0] pause_uncache;

    always @(*) begin
        case(aluop[0])
            `ALU_LDB:begin
                if(data_ok) begin
                    pause_uncache[0] = 1'b0;
                    case(mem_addr[0][1:0])
                        2'b00: begin
                            wb_reg_write_data[0] = {{24{dcache_read_data[7]}},dcache_read_data[7:0]};
                        end
                        2'b01: begin
                            wb_reg_write_data[0] = {{24{dcache_read_data[15]}},dcache_read_data[15:8]};
                        end
                        2'b10: begin
                            wb_reg_write_data[0] = {{24{dcache_read_data[23]}},dcache_read_data[23:16]};
                        end
                        2'b11: begin
                            wb_reg_write_data[0] = {{24{dcache_read_data[31]}},dcache_read_data[31:24]};
                        end
                        default: begin
                            wb_reg_write_data[0] = 32'b0;
                        end
                    endcase
                end
                else begin
                    pause_uncache[0] = 1'b1;
                    wb_reg_write_data[0] = 32'b0;
                end
            end
            `ALU_LDBU:begin
                if(data_ok) begin
                    pause_uncache[0] = 1'b0;
                    case(mem_addr[0][1:0])
                        2'b00: begin
                            wb_reg_write_data[0] = {24'b0,dcache_read_data[7:0]};
                        end
                        2'b01: begin
                            wb_reg_write_data[0] = {24'b0,dcache_read_data[15:8]};
                        end
                        2'b10: begin
                            wb_reg_write_data[0] = {24'b0,dcache_read_data[23:16]};
                        end
                        2'b11: begin
                            wb_reg_write_data[0] = {24'b0,dcache_read_data[31:24]};
                        end
                        default: begin
                            wb_reg_write_data[0] = 32'b0;
                        end
                    endcase
                end
                else begin
                    pause_uncache[0] = 1'b1;
                    wb_reg_write_data[0] = 32'b0;
                end
            end
            `ALU_LDH:begin
                if(data_ok) begin
                    pause_uncache[0] = 1'b0;
                    case(mem_addr[0][1:0])
                        2'b00: begin
                            wb_reg_write_data[0] = {{16{dcache_read_data[15]}},dcache_read_data[15:0]};
                        end
                        2'b10: begin
                            wb_reg_write_data[0] = {{16{dcache_read_data[31]}},dcache_read_data[31:16]};
                        end
                        default: begin
                            wb_reg_write_data[0] = 32'b0;
                        end
                    endcase
                end
                else begin
                    pause_uncache[0] = 1'b1;
                    wb_reg_write_data[0] = 32'b0;
                end
            end
            `ALU_LDHU:begin
                if(data_ok) begin
                    pause_uncache[0] = 1'b0;
                    case(mem_addr[0][1:0])
                        2'b00: begin
                            wb_reg_write_data[0] = {16'b0,dcache_read_data[15:0]};
                        end
                        2'b10: begin
                            wb_reg_write_data[0] = {16'b0,dcache_read_data[31:16]};
                        end
                        default: begin
                            wb_reg_write_data[0] = 32'b0;
                        end
                    endcase
                end
                else begin
                    pause_uncache[0] = 1'b1;
                    wb_reg_write_data[0] = 32'b0;
                end
            end
            `ALU_LDW:begin
                if(data_ok) begin
                    pause_uncache[0] = 1'b0;
                    wb_reg_write_data[0] = dcache_read_data;
                end
                else begin
                    pause_uncache[0] = 1'b1;
                    wb_reg_write_data[0] = 32'b0;
                end
            end
            `ALU_LLW:begin
                if(data_ok) begin
                    pause_uncache[0] = 1'b0;
                    wb_reg_write_data[0] = dcache_read_data;
                end
                else begin
                    pause_uncache[0] = 1'b1;
                    wb_reg_write_data[0] = 32'b0;
                end
            end
            default: begin
                pause_uncache[0] = 1'b0;
                wb_reg_write_data[0] = 32'b0;
            end
        endcase
    end


    always @(*) begin
        case(aluop[1])
            `ALU_LDB:begin
                if(data_ok) begin
                    pause_uncache[1] = 1'b0;
                    case(mem_addr[1][1:0])
                        2'b00: begin
                            wb_reg_write_data[1] = {{24{dcache_read_data[7]}},dcache_read_data[7:0]};
                        end
                        2'b01: begin
                            wb_reg_write_data[1] = {{24{dcache_read_data[15]}},dcache_read_data[15:8]};
                        end
                        2'b10: begin
                            wb_reg_write_data[1] = {{24{dcache_read_data[23]}},dcache_read_data[23:16]};
                        end
                        2'b11: begin
                            wb_reg_write_data[1] = {{24{dcache_read_data[31]}},dcache_read_data[31:24]};
                        end
                        default: begin
                            wb_reg_write_data[1] = 32'b0;
                        end
                    endcase
                end
                else begin
                    pause_uncache[1] = 1'b1;
                    wb_reg_write_data[1] = 32'b0;
                end
            end
            `ALU_LDBU:begin
                if(data_ok) begin
                    pause_uncache[1] = 1'b0;
                    case(mem_addr[1][1:0])
                        2'b00: begin
                            wb_reg_write_data[1] = {24'b0,dcache_read_data[7:0]};
                        end
                        2'b01: begin
                            wb_reg_write_data[1] = {24'b0,dcache_read_data[15:8]};
                        end
                        2'b10: begin
                            wb_reg_write_data[1] = {24'b0,dcache_read_data[23:16]};
                        end
                        2'b11: begin
                            wb_reg_write_data[1] = {24'b0,dcache_read_data[31:24]};
                        end
                        default: begin
                            wb_reg_write_data[1] = 32'b0;
                        end
                    endcase
                end
                else begin
                    pause_uncache[1] = 1'b1;
                    wb_reg_write_data[1] = 32'b0;
                end
            end
            `ALU_LDH:begin
                if(data_ok) begin
                    pause_uncache[1] = 1'b0;
                    case(mem_addr[1][1:0])
                        2'b00: begin
                            wb_reg_write_data[1] = {{16{dcache_read_data[15]}},dcache_read_data[15:0]};
                        end
                        2'b10: begin
                            wb_reg_write_data[1] = {{16{dcache_read_data[31]}},dcache_read_data[31:16]};
                        end
                        default: begin
                            wb_reg_write_data[1] = 32'b0;
                        end
                    endcase
                end
                else begin
                    pause_uncache[1] = 1'b1;
                    wb_reg_write_data[1] = 32'b0;
                end
            end
            `ALU_LDHU:begin
                if(data_ok) begin
                    pause_uncache[1] = 1'b0;
                    case(mem_addr[1][1:0])
                        2'b00: begin
                            wb_reg_write_data[1] = {16'b0,dcache_read_data[15:0]};
                        end
                        2'b10: begin
                            wb_reg_write_data[1] = {16'b0,dcache_read_data[31:16]};
                        end
                        default: begin
                            wb_reg_write_data[1] = 32'b0;
                        end
                    endcase
                end
                else begin
                    pause_uncache[1] = 1'b1;
                    wb_reg_write_data[1] = 32'b0;
                end
            end
            `ALU_LDW:begin
                if(data_ok) begin
                    pause_uncache[1] = 1'b0;
                    wb_reg_write_data[1] = dcache_read_data;
                end
                else begin
                    pause_uncache[1] = 1'b1;
                    wb_reg_write_data[1] = 32'b0;
                end
            end
            `ALU_LLW:begin
                if(data_ok) begin
                    pause_uncache[1] = 1'b0;
                    wb_reg_write_data[1] = dcache_read_data;
                end
                else begin
                    pause_uncache[1] = 1'b1;
                    wb_reg_write_data[1] = 32'b0;
                end
            end
            default: begin
                pause_uncache[1] = 1'b0;
                wb_reg_write_data[1] = 32'b0;
            end
        endcase
    end

    assign pause_mem = (pause_uncache[0] || pause_uncache[1]) && (is_exception[0] == 0 && is_exception[1] == 0);

    `ifdef DIFF
    always @(*) begin
        debug_wb_pc[0] = pc;
        debug_wb_pc[1] = pc;
        debug_wb_inst[0] = inst;
        debug_wb_inst[1] = inst;
        debug_wb_rf_we[0] = 4'b0;
        debug_wb_rf_we[1] = 4'b0;
        debug_wb_rf_wnum[0] = 5'b0;
        debug_wb_rf_wnum[1] = 5'b0;
        debug_wb_rf_wdata[0] = 32'b0;
        debug_wb_rf_wdata[1] = 32'b0;

        inst_valid[0] = valid[0];
        inst_valid[1] = valid[1];
        cnt_inst[0] = (aluop[0] == `ALU_RDCNTID || aluop[0] == `ALU_RDCNTVLW || aluop[0] == `ALU_RDCNTVHW);
        cnt_inst[1] = (aluop[1] == `ALU_RDCNTID || aluop[1] == `ALU_RDCNTVLW || aluop[1] == `ALU_RDCNTVHW);

        csr_rstat_en[0] = 1'b0;
        csr_rstat_en[1] = 1'b0;
        csr_data[0] = 32'b0;
        csr_data[1] = 32'b0;

        excp_flush[0] = 1'b0;
        excp_flush[1] = 1'b0;
        ertn_flush[0] = 1'b0;
        ertn_flush[1] = 1'b0;
        ecode[0] = 6'b0;
        ecode[1] = 6'b0;

        inst_st_en[0] = {4'b0, (is_llw_scw && (aluop == `ALU_SCW)),aluop == `ALU_STW, aluop == `ALU_STH, aluop == `ALU_STB};
        inst_st_en[1] = {4'b0, (is_llw_scw && (aluop == `ALU_SCW)),aluop == `ALU_STW, aluop == `ALU_STH, aluop == `ALU_STB};
        st_paddr[0] = dcache_P_addr;
        st_paddr[1] = dcache_P_addr;
        st_vaddr[0] = mem_addr[0];
        st_vaddr[1] = mem_addr[1];
        st_data[0] = mem_write_data[0];
        st_data[1] = mem_write_data[1];

        inst_ld_en[0] = {2'b0, aluop[0] == `ALU_LDW, aluop[0] == `ALU_LDHU, aluop[0] == `ALU_LDH, aluop[0] == `ALU_LDBU, aluop[0] == `ALU_LDB};
        inst_ld_en[1] = {2'b0, aluop[1] == `ALU_LDW, aluop[1] == `ALU_LDHU, aluop[1] == `ALU_LDH, aluop[1] == `ALU_LDBU, aluop[1] == `ALU_LDB};
        ld_paddr[0] = dcache_P_addr;
        ld_paddr[1] = dcache_P_addr;
        ld_vaddr[0] = mem_addr[0];
        ld_vaddr[1] = mem_addr[1];
        tlbfill_en[0] = (aluop == `ALU_TLBFILL) ;
        tlbfill_en[1] = (aluop == `ALU_TLBFILL) ;
    end
    `endif
endmodule