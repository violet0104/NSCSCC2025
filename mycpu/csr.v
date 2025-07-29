module csr (
    input wire clk,
    input wire rst,

    // 和dispatch的接�?
    input wire [1:0]  csr_read_en_i,
    input wire [13:0] csr_read_addr_i1,
    input wire [13:0] csr_read_addr_i2,
    
    output reg [31:0] csr_read_data_o1,
    output reg [31:0] csr_read_data_o2,

    // 来自wb的信�?
    input wire        is_llw_scw_i,
    input wire        csr_write_en_i,
    input wire [13:0] csr_write_addr_i,
    input wire [31:0] csr_write_data_i,

    //tlb相关输入
    input wire        search_tlb_found_i,
    input wire [4:0]  search_tlb_index_i,
    input wire        tlbrd_valid_i,
    input wire [31:0] tlbehi_out_i,
    input wire [31:0] tlbelo0_out_i,
    input wire [31:0] tlbelo1_out_i,
    input wire [31:0] tlbidx_out_i,
    input wire [9:0]  asid_out_i,
    input wire        tlbsrch_ret_i,
    input wire        tlbrd_ret_i,

    //tlb相关输出
    output wire [31:0] tlbidx_o,  //7.5.1TLB索引寄存器，包含[4:0]为index,[29:24]为PS，[31]为NE
    output wire [31:0] tlbehi_o,  //7.5.2TLB表项高位，包含[31:13]为VPPN
    output wire [31:0] tlbelo0_o,   //7.5.3TLB表项低位，包含写入TLB表项的内�?
    output wire [31:0] tlbelo1_o,
    output wire [9:0]  asid_o,  //7.5.4ASID的低9�?
    //TLBFILL和TLBWR指令
    output wire [5:0]  ecode_o,//7.5.1对于NE变量的描述中讲到，CSR.ESTAT.Ecode   (大概使能信号，若�?111111则写使能，否则根据tlbindex_in.NE判断是否写使能？
    //CSR信号
    output wire [31:0] csr_dmw0_o,//dmw0，有效位是[27:25]，可能会作为�?后转换出来的地址的最高三�?
    output wire [31:0] csr_dmw1_o,//dmw1，有效位是[27:25]，可能会作为�?后转换出来的地址的最高三�?
    output wire        csr_da_o,
    output wire        csr_pg_o,
    output wire [1:0]  csr_plv_o,
    output wire [1:0]  csr_datf_o,
    output wire [1:0]  csr_datm_o,
    
    
    // from outer（不知道是什么）
    input wire        is_ipi, //�?0
    input wire [7:0]  is_hwi,//mytop输入�?


    // 和ctrl的接�?
    input wire        is_exception_i, //是否是异�?
    input wire [6:0]  exception_cause_i, //异常原因
    input wire [31:0] exception_pc_i, //异常PC地址
    input wire [31:0] exception_addr_i, //异常地址
    input wire [5:0]  ecode_i, //异常ecode
    input wire [8:0]  esubcode_i, //异常子码
    input wire        is_ertn_i,
    input wire        is_inst_tlb_exception_i, //是否是指令TLB异常
    input wire        is_tlb_exception_i,

    output wire [31:0] eentry_o, //异常入口地址
    output wire [31:0] era_o, //异常返回地址
    output wire [31:0] crmd_o, //控制寄存�? 
    output wire        is_interrupt_o, //是否是中�?
    output wire [31:0] tlbrentry_o
);
    
    reg [31:0] crmd; 
    reg [31:0] prmd; 
    reg [31:0] ecfg;
    reg [31:0] estat;
    reg [31:0] era;
    reg [31:0] badv;
    reg [31:0] eentry;
    reg [31:0] tlbidx;
    reg [31:0] tlbehi;
    reg [31:0] tlbelo0;
    reg [31:0] tlbelo1;
    reg [31:0] asid;
    reg [31:0] pgdl;
    reg [31:0] pgdh;
    wire [31:0] pgd;
    reg [31:0] cpuid;
    reg [31:0] save0;
    reg [31:0] save1;
    reg [31:0] save2;
    reg [31:0] save3;
    reg [31:0] tid;
    reg [31:0] tcfg;
    reg [31:0] tval;
    reg [31:0] ticlr;
    reg [31:0] llbctl;
    reg [31:0] tlbrentry;
    reg [31:0] dmw0;
    reg [31:0] dmw1;
    reg [31:0] cpucfg1;
    reg [31:0] cpucfg2;
    reg [31:0] cpucfg10;
    reg [31:0] cpucfg11;
    reg [31:0] cpucfg12;
    reg [31:0] cpucfg13;

    reg llbit;

    wire crmd_wen;
    wire prmd_wen;
    wire ecfg_wen;
    wire estat_wen;
    wire era_wen;
    wire badv_wen;
    wire eentry_wen;
    wire tlbidx_wen;
    wire tlbehi_wen;
    wire tlbelo0_wen;
    wire tlbelo1_wen;
    wire asid_wen;
    wire pgdl_wen;
    wire pgdh_wen;
    wire pgd_wen;
    wire cpuid_wen;
    wire save0_wen;
    wire save1_wen;
    wire save2_wen;
    wire save3_wen;
    wire tid_wen;
    wire tcfg_wen;
    wire tval_wen;
    wire ticlr_wen;
    wire llbctl_wen;
    wire tlbrentry_wen;
    wire dmw0_wen;
    wire dmw1_wen;


    assign crmd_wen   = csr_write_en_i & (csr_write_addr_i == `CSR_CRMD);
    assign prmd_wen   = csr_write_en_i & (csr_write_addr_i == `CSR_PRMD);
    assign ecfg_wen   = csr_write_en_i & (csr_write_addr_i == `CSR_ECFG);
    assign estat_wen  = csr_write_en_i & (csr_write_addr_i == `CSR_ESTAT);
    assign era_wen    = csr_write_en_i & (csr_write_addr_i == `CSR_ERA);
    assign badv_wen   = csr_write_en_i & (csr_write_addr_i == `CSR_BADV);
    assign eentry_wen = csr_write_en_i & (csr_write_addr_i == `CSR_EENTRY);
    assign tlbidx_wen = csr_write_en_i & (csr_write_addr_i == `CSR_TLBIDX);
    assign tlbehi_wen = csr_write_en_i & (csr_write_addr_i == `CSR_TLBEHI);
    assign tlbelo0_wen= csr_write_en_i & (csr_write_addr_i == `CSR_TLBELO0);
    assign tlbelo1_wen= csr_write_en_i & (csr_write_addr_i == `CSR_TLBELO1);
    assign asid_wen   = csr_write_en_i & (csr_write_addr_i == `CSR_ASID);
    assign pgdl_wen   = csr_write_en_i & (csr_write_addr_i == `CSR_PGDL);
    assign pgdh_wen   = csr_write_en_i & (csr_write_addr_i == `CSR_PGDH);
    assign pgd_wen    = csr_write_en_i & (csr_write_addr_i == `CSR_PGD);
    assign cpuid_wen  = csr_write_en_i & (csr_write_addr_i == `CSR_CPUID);
    assign save0_wen  = csr_write_en_i & (csr_write_addr_i == `CSR_SAVE0);
    assign save1_wen  = csr_write_en_i & (csr_write_addr_i == `CSR_SAVE1);
    assign save2_wen  = csr_write_en_i & (csr_write_addr_i == `CSR_SAVE2);
    assign save3_wen  = csr_write_en_i & (csr_write_addr_i == `CSR_SAVE3);
    assign tid_wen    = csr_write_en_i & (csr_write_addr_i == `CSR_TID);
    assign tcfg_wen   = csr_write_en_i & (csr_write_addr_i == `CSR_TCFG);
    assign tval_wen   = csr_write_en_i & (csr_write_addr_i == `CSR_TVAL);
    assign ticlr_wen  = csr_write_en_i & (csr_write_addr_i == `CSR_TICLR);
    assign llbctl_wen = csr_write_en_i & (csr_write_addr_i == `CSR_LLBCTL);
    assign tlbrentry_wen = csr_write_en_i & (csr_write_addr_i == `CSR_TLBRENTRY);
    assign dmw0_wen   = csr_write_en_i & (csr_write_addr_i == `CSR_DMW0);
    assign dmw1_wen   = csr_write_en_i & (csr_write_addr_i == `CSR_DMW1);

    assign crmd_o = crmd;
    assign eentry_o = eentry;
    assign era_o = era;
    assign tlbrentry_o = tlbrentry;
    assign is_interrupt_o = ((ecfg[12:0] & estat[12:0]) != 13'b0) & crmd[2];
    
    assign tlbidx_o = tlbidx;
    assign tlbehi_o = tlbehi;
    assign tlbelo0_o = tlbelo0;
    assign tlbelo1_o = tlbelo1;
    assign asid_o = asid[9:0];
    assign ecode_o = estat[21:16];
    assign csr_dmw0_o = dmw0;
    assign csr_dmw1_o = dmw1;
    assign csr_da_o = crmd[3];
    assign csr_pg_o = crmd[4];
    assign csr_plv_o = crmd[1:0];
    assign csr_datf_o = crmd[6:5];
    assign csr_datm_o = crmd[8:7];

    reg timer_en;
    wire eret_tlbrefill_excp;
    assign eret_tlbrefill_excp = (estat[21:16] == 6'h3f);

    //crmd
    always @(posedge clk) begin
        if(rst) begin
            crmd <= {{23{1'b0}}, 9'b000001000};
        end
        else if(is_exception_i) begin
            crmd[1:0] <= 2'b0;  // PLV
            crmd[2]   <= 1'b0;  // IE
            if (exception_cause_i == `EXCEPTION_TLBR) begin
                crmd[3] <= 1'b1;  // DA
                crmd[4] <= 1'b0;  // PG
            end
        end
        else if(is_ertn_i) begin
            crmd[1:0] <= prmd[1:0];  // PLV
            crmd[2]   <= prmd[2];  // IE
            if (eret_tlbrefill_excp) begin
                crmd[3] <= 1'b0;  // DA
                crmd[4] <= 1'b1;  // PG
            end
        end
        else if(crmd_wen) begin
            crmd[8:0] <= csr_write_data_i[8:0];
        end
    end

    //prmd
    always @(posedge clk) begin
         if (rst) begin
            prmd <= 32'b0;
        end else if (is_exception_i) begin
            prmd[1:0] <= crmd[1:0];  // PPLV
            prmd[2]   <= crmd[2];  // PIE
        end else if (prmd_wen) begin
            prmd[2:0] <= csr_write_data_i[2:0];
        end
    end

    //ecfg
    always @(posedge clk) begin
         if (rst) begin
            ecfg <= 32'b0;
        end 
        else if (ecfg_wen) begin
            ecfg[9:0]   <= csr_write_data_i[9:0];
            ecfg[12:11] <= csr_write_data_i[12:11];
        end 
        else begin
            ecfg <= ecfg;
        end
    end

    //estat
    always @(posedge clk) begin
         if (rst) begin
            estat <= 32'b0;
            timer_en <= 1'b0;
        end 
        else begin
            estat[9:2] <= is_hwi;
            if (ticlr_wen && csr_write_data_i[0]) begin
                estat[11] <= 1'b0;
            end 
            else if (tcfg_wen) begin
                timer_en <= csr_write_data_i[0];
            end 
            else if (timer_en && tval == 32'h0) begin
                estat[11] <= 1'b1;
                timer_en <= tcfg[1];
            end
            if (is_exception_i) begin
                estat[21:16] <= ecode_i;
                estat[30:22] <= esubcode_i;
            end 
            else if (estat_wen) begin
                estat[1:0] <= csr_write_data_i[1:0];
            end
        end
    end

    //era
    always @(posedge clk) begin
        if (rst) begin
            era <= 32'b0;
        end 
        else if (is_exception_i) begin
            era <= exception_pc_i;
        end 
        else if (era_wen) begin
            era <= csr_write_data_i;
        end
    end

    //badv
    always @(posedge clk) begin
        if (rst) begin
            badv <= 32'b0;
        end 
        else if (is_exception_i) begin
            case (exception_cause_i)
                `EXCEPTION_TLBR, `EXCEPTION_ALE, `EXCEPTION_PIL, `EXCEPTION_PIS, 
                `EXCEPTION_PIF, `EXCEPTION_PME, `EXCEPTION_PPI: begin
                    if (is_inst_tlb_exception_i) begin
                        badv <= exception_pc_i;
                    end 
                    else begin
                        badv <= exception_addr_i;
                    end
                end
                `EXCEPTION_ADEF: begin
                    badv <= exception_pc_i;
                end
                default: begin
                    badv <= badv; //其他异常不处�???????????????
                end
            endcase
        end 
        else if (badv_wen) begin
            badv <= csr_write_data_i;
        end 
        else begin
            badv <= badv;
        end
    end

    //eentry
    always @(posedge clk) begin
        if (rst) begin
            eentry <= 32'b0;
        end
        else if (eentry_wen) begin
            eentry[31:6] <= csr_write_data_i[31:6];
        end 
        else begin
            eentry <= eentry;
        end
    end

    //elbidx
    always @(posedge clk) begin
        if (rst) begin
            tlbidx <= 32'b0;
        end else if (tlbidx_wen) begin
            tlbidx[4:0] <= csr_write_data_i[4:0];  // index
            tlbidx[29:24] <= csr_write_data_i[29:24];  // ps
            tlbidx[31] <= csr_write_data_i[31];  // ne
        end else if (tlbsrch_ret_i) begin
            if (search_tlb_found_i) begin
                tlbidx[4:0] <= search_tlb_index_i;
                tlbidx[31]  <= 1'b0;
            end else begin
                tlbidx[31] <= 1'b1;
            end
        end else if (tlbrd_ret_i) begin
            if (tlbrd_valid_i) begin
                tlbidx[29:24] <= tlbidx_out_i[29:24];
                tlbidx[31] <= tlbidx_out_i[31];
            end else begin
                tlbidx[29:24] <= 6'b0;
                tlbidx[31] <= tlbidx_out_i[31];
            end
        end 
    end

    //tlbehi
    always @(posedge clk) begin
        if (rst) begin
            tlbehi <= 32'b0;
        end 
        else if (tlbehi_wen) begin
            tlbehi[31:13] <= csr_write_data_i[31:13];  // vppn
        end 
        else if (tlbrd_ret_i) begin
            if (tlbrd_valid_i) begin
                tlbehi[31:13] <= tlbehi_out_i[31:13];
            end 
            else begin
                tlbehi[31:13] <= 19'b0;
            end
        end 
        else if (is_tlb_exception_i) begin
            if (is_inst_tlb_exception_i) begin
                tlbehi[31:13] <= exception_pc_i[31:13];
            end 
            else begin
                tlbehi[31:13] <= exception_addr_i[31:13];
            end
        end 
    end

    //tlbelo0
    always @(posedge clk) begin
        if (rst) begin
            tlbelo0 <= 32'b0;
        end 
        else if (tlbelo0_wen) begin
            tlbelo0[0] <= csr_write_data_i[0];  // V
            tlbelo0[1] <= csr_write_data_i[1];  // D
            tlbelo0[3:2] <= csr_write_data_i[3:2];  // PLV
            tlbelo0[5:4] <= csr_write_data_i[5:4];  // MAT
            tlbelo0[6] <= csr_write_data_i[6];  // G
            tlbelo0[31:8] <= csr_write_data_i[31:8];  // PPN
        end 
        else if (tlbrd_ret_i) begin
            if (tlbrd_valid_i) begin
                tlbelo0[0] <= tlbelo0_out_i[0];
                tlbelo0[1] <= tlbelo0_out_i[1];
                tlbelo0[3:2] <= tlbelo0_out_i[3:2];
                tlbelo0[5:4] <= tlbelo0_out_i[5:4];
                tlbelo0[6] <= tlbelo0_out_i[6];
                tlbelo0[31:8] <= tlbelo0_out_i[31:8];
            end 
            else begin
                tlbelo0[0] <= 1'b0;
                tlbelo0[1] <= 1'b0;
                tlbelo0[3:2] <= 2'b0;
                tlbelo0[5:4] <= 2'b0;
                tlbelo0[6] <= 1'b0;
                tlbelo0[31:8] <= 24'b0;
            end
        end 
    end

    //tlbelo1
    always @(posedge clk) begin
        if (rst) begin
            tlbelo1 <= 32'b0;
        end else if (tlbelo1_wen) begin
            tlbelo1[0] <= csr_write_data_i[0];  // V
            tlbelo1[1] <= csr_write_data_i[1];  // D
            tlbelo1[3:2] <= csr_write_data_i[3:2];  // PLV
            tlbelo1[5:4] <= csr_write_data_i[5:4];  // MAT
            tlbelo1[6] <= csr_write_data_i[6];  // G
            tlbelo1[31:8] <= csr_write_data_i[31:8];  // PPN
        end 
        else if (tlbrd_ret_i) begin
            if (tlbrd_valid_i) begin
                tlbelo1[0] <= tlbelo1_out_i[0];
                tlbelo1[1] <= tlbelo1_out_i[1];
                tlbelo1[3:2] <= tlbelo1_out_i[3:2];
                tlbelo1[5:4] <= tlbelo1_out_i[5:4];
                tlbelo1[6] <= tlbelo1_out_i[6];
                tlbelo1[31:8] <= tlbelo1_out_i[31:8];
            end 
            else begin
                tlbelo1[0] <= 1'b0;
                tlbelo1[1] <= 1'b0;
                tlbelo1[3:2] <= 2'b0;
                tlbelo1[5:4] <= 2'b0;
                tlbelo1[6] <= 1'b0;
                tlbelo1[31:8] <= 24'b0;
            end
        end 
    end

    //asid
    always @(posedge clk) begin
        if (rst) begin
            asid[15:0]  <= 16'b0;
            asid[23:16] <= 8'd10;
            asid[31:24] <= 8'b0;
        end else if (asid_wen) begin
            asid[9:0] <= csr_write_data_i[9:0];
        end else if (tlbrd_ret_i) begin
            if (tlbrd_valid_i) begin
                asid[9:0] <= asid_out_i;
            end else begin
                asid[9:0] <= 10'b0;
            end
        end 
    end

    //pgdl
    always @(posedge clk) begin
        if (rst) begin
            pgdl <= 32'b0;
        end 
        else if (pgdl_wen) begin
            pgdl[31:12] <= csr_write_data_i[31:12];  // BASE
        end
    end

    //pdgh
    always @(posedge clk) begin
        if (rst) begin
            pgdh <= 32'b0;
        end else if (pgdh_wen) begin
            pgdh[31:12] <= csr_write_data_i[31:12];  // BASE
        end
    end

    //pgd
    assign pgd = badv[31] ? pgdh : pgdl;

    //tlbrentry
    always @(posedge clk) begin
        if (rst) begin
            tlbrentry <= 32'b0;
        end else if (tlbrentry_wen) begin
            tlbrentry[31:6] <= csr_write_data_i[31:6];  // PA
        end
    end

    //dmw0
    always @(posedge clk) begin
        if (rst) begin
            dmw0 <= 32'b0;
        end else if (dmw0_wen) begin
            dmw0[0] <= csr_write_data_i[0];  // PLV0
            dmw0[3] <= csr_write_data_i[3];  // PLV3
            dmw0[5:4] <= csr_write_data_i[5:4];  // MAT
            dmw0[27:25] <= csr_write_data_i[27:25];  // PSEG
            dmw0[31:29] <= csr_write_data_i[31:29];  // VSEG
        end
    end

    //dmw1
    always @(posedge clk) begin
        if (rst) begin
            dmw1 <= 32'b0;
        end 
        else if (dmw1_wen) begin
            dmw1[0] <= csr_write_data_i[0];  // PLV0
            dmw1[3] <= csr_write_data_i[3];  // PLV3
            dmw1[5:4] <= csr_write_data_i[5:4];  // MAT
            dmw1[27:25] <= csr_write_data_i[27:25];  // PSEG
            dmw1[31:29] <= csr_write_data_i[31:29];  // VSEG
        end
    end

    //cpucfg1
    always @(posedge clk) begin
        if (rst) begin
            cpucfg1 <= 32'h1f1f4;
        end 
    end

    //cpucfg2
    always @(posedge clk) begin
        if (rst) begin
            cpucfg2 <= 32'h0;
        end 
    end

    //cpucfg10
    always @(posedge clk) begin
        if (rst) begin
            cpucfg10 <= 32'h5;
        end 
    end

    //cpucfg11
    always @(posedge clk) begin
        if (rst) begin
            cpucfg11 <= 32'h04080001;
        end 
    end

    //cpucfg12
    always @(posedge clk) begin
        if (rst) begin
            cpucfg12 <= 32'h04080001;
        end 
    end

    //cpucfg13
    always @(posedge clk) begin
        if (rst) begin
            cpucfg13 <= 32'h0;
        end 
    end

    //cpuid
    always @(posedge clk) begin
        if (rst) begin
            cpuid <= 32'b0;
        end
    end

    //save0
    always @(posedge clk) begin
        if (rst) begin
            save0 <= 32'b0;
        end else if (save0_wen) begin
            save0 <= csr_write_data_i;
        end
    end

    //save1
    always @(posedge clk) begin
        if (rst) begin
            save1 <= 32'b0;
        end else if (save1_wen) begin
            save1 <= csr_write_data_i;
        end
    end

    //save2
    always @(posedge clk) begin
        if (rst) begin
            save2 <= 32'b0;
        end else if (save2_wen) begin
            save2 <= csr_write_data_i;
        end
    end

    //save3
    always @(posedge clk) begin
        if (rst) begin
            save3 <= 32'b0;
        end else if (save3_wen) begin
            save3 <= csr_write_data_i;
        end
    end

    //llbctl
    always @(posedge clk) begin
        if (rst) begin
            llbctl <= 32'b0;
            llbit <= 1'b0;
        end else if (is_ertn_i) begin
            if (llbctl[2]) begin
                llbctl[2] <= 1'b0; // KLO
            end else begin
                llbit <= 1'b0; // ROLLB
            end
        end else if (llbctl_wen) begin
            llbctl[2] <= csr_write_data_i[2];
            if (is_llw_scw_i) begin
                llbit <= csr_write_data_i[0];
            end else if (csr_write_data_i[1]) begin
                llbit <= 1'b0;
            end
        end
    end

    //tid
    always @(posedge clk) begin
        if (rst) begin
            tid <= 32'b0;
        end 
        else if (tid_wen) begin
            tid <= csr_write_data_i;
        end
    end

    //tcfg
    always @(posedge clk) begin
        if (rst) begin
            tcfg <= 32'b0;
        end else if (tcfg_wen) begin
            tcfg <= csr_write_data_i;
        end
    end

    //tval（这个不知道要不要复位？？）
    always @(posedge clk) begin
        if (tcfg_wen) begin
            tval <= {csr_write_data_i[31:2], 2'b0};
        end else if (timer_en) begin
            if (tval != 32'b0) begin
                tval <= tval - 32'b1;
            end else if (tval == 32'b0) begin
                tval <= tcfg[1]? {tcfg[31:2], 2'b0}: 32'hffffffff;
            end
        end
    end

    //ticlr
    always @(posedge clk) begin
        if (rst) begin
            ticlr <= 32'b0;
        end
    end

    //read
    always @(*) begin
        if(rst) begin
            csr_read_data_o1 = 0;
            csr_read_data_o2 = 0;
        end
        else if(csr_read_en_i[0])begin
            case (csr_read_addr_i1)
                    `CSR_CRMD: begin
                        csr_read_data_o1 = crmd;
                    end
                    `CSR_PRMD: begin
                        csr_read_data_o1 = prmd;
                    end
                    `CSR_ECFG: begin
                        csr_read_data_o1 = ecfg;
                    end
                    `CSR_ESTAT: begin
                        csr_read_data_o1 = estat;
                    end
                    `CSR_ERA: begin
                        csr_read_data_o1 = era;
                    end
                    `CSR_BADV: begin
                        csr_read_data_o1 = badv;
                    end
                    `CSR_EENTRY: begin
                        csr_read_data_o1 = eentry;
                    end
                    `CSR_TLBIDX: begin
                        csr_read_data_o1 = tlbidx;
                    end
                    `CSR_TLBEHI: begin
                        csr_read_data_o1 = tlbehi;
                    end
                    `CSR_TLBELO0: begin
                        csr_read_data_o1 = tlbelo0;
                    end
                    `CSR_TLBELO1: begin
                        csr_read_data_o1 = tlbelo1;
                    end
                    `CSR_ASID: begin
                        csr_read_data_o1 = asid;
                    end
                    `CSR_PGDL: begin
                        csr_read_data_o1 = pgdl;
                    end
                    `CSR_PGDH: begin
                        csr_read_data_o1 = pgdh;
                    end
                    `CSR_PGD: begin
                        csr_read_data_o1 = pgd;
                    end
                    `CSR_CPUID: begin
                        csr_read_data_o1 = cpuid;
                    end
                    `CSR_SAVE0: begin
                        csr_read_data_o1 = save0;
                    end
                    `CSR_SAVE1: begin
                        csr_read_data_o1 = save1;
                    end
                    `CSR_SAVE2: begin
                        csr_read_data_o1 = save2;
                    end
                    `CSR_SAVE3: begin
                        csr_read_data_o1 = save3;
                    end
                    `CSR_LLBCTL: begin
                        csr_read_data_o1 = {llbctl[31:1], llbit};
                    end
                    `CSR_TID: begin
                        csr_read_data_o1 = tid;
                    end
                    `CSR_TCFG: begin
                        csr_read_data_o1 = tcfg;
                    end
                    `CSR_TVAL: begin
                        csr_read_data_o1 = tval;
                    end
                    `CSR_TICLR: begin
                        csr_read_data_o1 = 32'b0;
                    end
                    `CSR_TLBRENTRY: begin
                        csr_read_data_o1 = tlbrentry;
                    end
                    `CSR_DMW0: begin
                        csr_read_data_o1 = dmw0;
                    end
                    `CSR_DMW1: begin
                        csr_read_data_o1 = dmw1;
                    end
                    `CSR_CPUCFG1: begin
                        csr_read_data_o1 = cpucfg1;
                    end
                    `CSR_CPUCFG2: begin
                        csr_read_data_o1 = cpucfg2;
                    end
                    `CSR_CPUCFG10: begin
                        csr_read_data_o1 = cpucfg10;
                    end
                    `CSR_CPUCFG11: begin
                        csr_read_data_o1 = cpucfg11;
                    end
                    `CSR_CPUCFG12: begin
                        csr_read_data_o1 = cpucfg12;
                    end
                    `CSR_CPUCFG13: begin
                        csr_read_data_o1 = cpucfg13;
                    end
                    default: begin
                        csr_read_data_o1 = 32'b0;
                    end 
            endcase
        end 
        else if(csr_read_en_i[0] == 1'b0) begin
            csr_read_data_o1 = 32'b0;
        end
        if(csr_read_en_i[1]) begin
            case (csr_read_addr_i2)
                    `CSR_CRMD: begin
                        csr_read_data_o2 = crmd;
                    end
                    `CSR_PRMD: begin
                        csr_read_data_o2 = prmd;
                    end
                    `CSR_ECFG: begin
                        csr_read_data_o2 = ecfg;
                    end
                    `CSR_ESTAT: begin
                        csr_read_data_o2 = estat;
                    end
                    `CSR_ERA: begin
                        csr_read_data_o2 = era;
                    end
                    `CSR_BADV: begin
                        csr_read_data_o2 = badv;
                    end
                    `CSR_EENTRY: begin
                        csr_read_data_o2 = eentry;
                    end
                    `CSR_TLBIDX: begin
                        csr_read_data_o2 = tlbidx;
                    end
                    `CSR_TLBEHI: begin
                        csr_read_data_o2 = tlbehi;
                    end
                    `CSR_TLBELO0: begin
                        csr_read_data_o2 = tlbelo0;
                    end
                    `CSR_TLBELO1: begin
                        csr_read_data_o2 = tlbelo1;
                    end
                    `CSR_ASID: begin
                        csr_read_data_o2 = asid;
                    end
                    `CSR_PGDL: begin
                        csr_read_data_o2 = pgdl;
                    end
                    `CSR_PGDH: begin
                        csr_read_data_o2 = pgdh;
                    end
                    `CSR_PGD: begin
                        csr_read_data_o2 = pgd;
                    end
                    `CSR_CPUID: begin
                        csr_read_data_o2 = cpuid;
                    end
                    `CSR_SAVE0: begin
                        csr_read_data_o2 = save0;
                    end
                    `CSR_SAVE1: begin
                        csr_read_data_o2 = save1;
                    end
                    `CSR_SAVE2: begin
                        csr_read_data_o2 = save2;
                    end
                    `CSR_SAVE3: begin
                        csr_read_data_o2 = save3;
                    end
                    `CSR_LLBCTL: begin 
                        csr_read_data_o2 = {llbctl[31:1], llbit};
                    end 
                    `CSR_TID: begin 
                        csr_read_data_o2 = tid; 
                    end 
                    `CSR_TCFG: begin 
                        csr_read_data_o2 = tcfg; 
                    end
                    `CSR_TVAL: begin 
                        csr_read_data_o2 = tval; 
                    end
                    `CSR_TICLR: begin 
                        csr_read_data_o2 = 32'b0; 
                    end
                    `CSR_TLBRENTRY: begin 
                        csr_read_data_o2 = tlbrentry; 
                    end
                    `CSR_DMW0: begin 
                        csr_read_data_o2 = dmw0; 
                    end
                    `CSR_DMW1: begin 
                        csr_read_data_o2 = dmw1; 
                    end
                    `CSR_CPUCFG1: begin
                        csr_read_data_o1 = cpucfg1;
                    end
                    `CSR_CPUCFG2: begin
                        csr_read_data_o1 = cpucfg2;
                    end
                    `CSR_CPUCFG10: begin
                        csr_read_data_o1 = cpucfg10;
                    end
                    `CSR_CPUCFG11: begin
                        csr_read_data_o1 = cpucfg11;
                    end
                    `CSR_CPUCFG12: begin
                        csr_read_data_o1 = cpucfg12;
                    end
                    `CSR_CPUCFG13: begin
                        csr_read_data_o1 = cpucfg13;
                    end
                    default: begin
                        csr_read_data_o2 = 32'b0;
                    end
            endcase
        end
        else if(csr_read_en_i[1] == 1'b0) begin
            csr_read_data_o2 = 32'b0;
        end
    end
endmodule