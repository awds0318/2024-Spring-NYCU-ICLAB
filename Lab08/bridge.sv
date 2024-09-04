module bridge(input clk, INF.bridge_inf inf);

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
typedef enum logic [3:0] {S_IDLE, S_RDATA, S_RADDR, S_EXP, S_ADD1, S_ADD2, S_ADD3, S_OF, S_SUB1, S_SUB2, S_ING, S_WADDR, S_WDATA, S_WB} state_t;
state_t cs;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [9:0] dram;  // ingredient's amount in DRAM
logic [9:0] user;  // ingredient's amount from user

logic [10:0] add;
logic [10:0] sub;

logic [7:0]  addr;

logic        no_ing, overflow, expired;

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

// -------------------------------------------- Flag ------------------------------------------ //
// month = inf.C_data_w[56:53], exp_month = inf.R_DATA[35:32]
// date  = inf.C_data_w[52:48], exp_date  = inf.R_DATA[ 4: 0]

always_ff @(posedge clk) expired  <= (inf.C_data_w[56:53] > inf.R_DATA[35:32]) || (inf.C_data_w[56:53] == inf.R_DATA[35:32] && inf.C_data_w[52:48] > inf.R_DATA[4:0]);
always_ff @(posedge clk) overflow <= (cs == S_IDLE)? 0 : ((cs == S_ADD1 || cs == S_ADD2 || cs == S_ADD3)? (overflow || add[10]) : overflow);
always_ff @(posedge clk) no_ing   <= (cs == S_IDLE)? 0 : ((cs == S_EXP  || cs == S_SUB1 || cs == S_SUB2)? (no_ing   || sub[10]) : no_ing  );

// -------------------------------------------- FSM ------------------------------------------- //
always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n) cs <= S_IDLE;
    else 
    begin
        case(cs)
            S_IDLE:  cs <= (inf.C_in_valid)? S_RADDR : cs;
            S_RADDR: cs <= (inf.AR_READY)?   S_RDATA : cs;
            S_RDATA: cs <= (inf.R_VALID)? ((inf.C_data_w[62])? S_ADD1 : S_EXP) : cs;  // Make_drink & Check_Valid_Date will go to S_EXP
            S_ADD1:  cs <= S_ADD2;
            S_ADD2:  cs <= S_ADD3;
            S_ADD3:  cs <= S_OF;
            S_OF:    cs <= S_WADDR;                                                   // overflow check
            S_EXP:   cs <= (!expired && !inf.C_data_w[63])? S_SUB1 : S_IDLE;          // S_EXP (expire check): only not expired and Make_drink will go to S_SUB1
            S_SUB1:  cs <= S_SUB2;
            S_SUB2:  cs <= S_ING;
            S_ING:   cs <= (no_ing || sub[10])? S_IDLE : S_WADDR;                     // ingredient check
            S_WADDR: cs <= (inf.AW_READY)? S_WDATA : cs;
            S_WDATA: cs <= (inf.W_READY)?  S_WB    : cs;
            S_WB:    cs <= (inf.B_VALID)?  S_IDLE  : cs;
        endcase
    end
end

always_ff @(posedge clk)
begin
    case(cs)
        S_RDATA:        dram <= inf.R_DATA[63:54];
        S_ADD1, S_EXP:  dram <= inf.W_DATA[51:42]; 
        S_ADD2, S_SUB1: dram <= inf.W_DATA[31:22];
        S_ADD3, S_SUB2: dram <= inf.W_DATA[19:10];
    endcase
end

always_ff @(posedge clk)
begin
    case(cs)
        S_RDATA:        user <= inf.C_data_w[39:30];
        S_ADD1, S_EXP:  user <= inf.C_data_w[29:20];
        S_ADD2, S_SUB1: user <= inf.C_data_w[19:10];
        S_ADD3, S_SUB2: user <= inf.C_data_w[ 9: 0];
    endcase
end

always_comb add = dram + user;
always_comb sub = dram - user[7:0];

// -------------------------------------- signal to DRAM -------------------------------------- //
always_ff @(posedge clk or negedge inf.rst_n) addr <= (!inf.rst_n)? 0 : inf.C_addr;

always_comb inf.AR_VALID      = (cs == S_RADDR)? 1 : 0;
always_comb inf.R_READY       = (cs == S_RDATA)? 1 : 0;
always_comb inf.AW_VALID      = (cs == S_WADDR)? 1 : 0;
always_comb inf.W_VALID       = (cs == S_WDATA)? 1 : 0;
always_comb inf.B_READY       = (cs == S_WB)?    1 : 0;
always_comb inf.AR_ADDR[15:0] = {5'd0, addr, 3'd0};
always_comb inf.AW_ADDR[15:0] = {5'd0, addr, 3'd0};
always_comb inf.AR_ADDR[16]   = (!inf.rst_n)? 0 : 1;
always_comb inf.AW_ADDR[16]   = (!inf.rst_n)? 0 : 1;

always_comb inf.W_DATA[39:36] = 0;
always_comb inf.W_DATA[ 7: 5] = 0;
always_comb inf.W_DATA[53:52] = 0;
always_comb inf.W_DATA[41:40] = 0;
always_comb inf.W_DATA[21:20] = 0;
always_comb inf.W_DATA[ 9: 8] = 0;

always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)
    begin
        inf.W_DATA[63:54] <= 0;
        inf.W_DATA[51:42] <= 0;
        inf.W_DATA[31:22] <= 0;
        inf.W_DATA[19:10] <= 0;
    end
    else 
    begin
        case(cs)
            S_RDATA: // R_DATA save in W_DATA
            begin
                inf.W_DATA[63:54] <=  inf.R_DATA[63:54];
                inf.W_DATA[51:42] <=  inf.R_DATA[51:42];
                inf.W_DATA[31:22] <=  inf.R_DATA[31:22];
                inf.W_DATA[19:10] <=  inf.R_DATA[19:10];
            end
            S_ADD1: inf.W_DATA[63:54] <= (add[10])? 1023 : add;  // update black tea
            S_ADD2: inf.W_DATA[51:42] <= (add[10])? 1023 : add;  // update green tea
            S_ADD3: inf.W_DATA[31:22] <= (add[10])? 1023 : add;  // update milk
            S_OF:   inf.W_DATA[19:10] <= (add[10])? 1023 : add;  // update pineapple juice
            S_EXP:  inf.W_DATA[63:54] <= sub;                    // update black tea
            S_SUB1: inf.W_DATA[51:42] <= sub;                    // update green tea
            S_SUB2: inf.W_DATA[31:22] <= sub;                    // update milk
            S_ING:  inf.W_DATA[19:10] <= sub;                    // update pineapple juice
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)
    begin
        inf.W_DATA[35:32] <= 0;
        inf.W_DATA[ 4: 0] <= 0;
    end
    else if(cs == S_RDATA)
    begin
        inf.W_DATA[35:32] <= inf.R_DATA[35:32];
        inf.W_DATA[ 4: 0] <= inf.R_DATA[ 4: 0];  
    end
    else if(cs == S_ADD1)
    begin
        inf.W_DATA[35:32] <= inf.C_data_w[56:53];   // update month
        inf.W_DATA[ 4: 0] <= inf.C_data_w[52:48];   // update date
    end
end

// --------------------------------------- signal to BEV -------------------------------------- //
always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n) inf.C_out_valid <= 0;
    else 
    begin
        case(cs)
            S_IDLE:  inf.C_out_valid <= 0;
            S_OF:    inf.C_out_valid <= 1;
            S_EXP:   inf.C_out_valid <= (expired || inf.C_data_w[63])? 1 : 0;
            S_ING:   inf.C_out_valid <= 1;
            S_WADDR: inf.C_out_valid <= 0;
        endcase
    end
end

// inf.C_data_r[63:3]: of no use
// inf.C_data_r[2]:    busy signal 0: not busy, 1: busy
// inf.C_data_r[1:0]:  error_msg

always_comb inf.C_data_r[63:3] = 0;

always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n)                              inf.C_data_r[2] <= 0;
    else if(cs == S_IDLE)                       inf.C_data_r[2] <= 0;
    else if(cs == S_ING && (no_ing || sub[10])) inf.C_data_r[2] <= 0;
    else                                        inf.C_data_r[2] <= 1;
end

always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n) inf.C_data_r[1:0] <= 0;
    else 
    begin
        case(cs)
            S_IDLE:                         inf.C_data_r[1:0] <= 0;     // No_Err(2'b00)
            S_ING:  if(no_ing   || sub[10]) inf.C_data_r[1:0] <= 2;     // No_Ing(2'b10)
            S_OF:   if(overflow || add[10]) inf.C_data_r[1:0] <= 3;     // Ing_OF(2'b11)
            S_EXP:  if(expired)             inf.C_data_r[1:0] <= 1;     // No_Exp(2'b01)
        endcase
    end
end

endmodule 

// Cycle: 2.20
// Area: 16980.163169
// Gate count: 935