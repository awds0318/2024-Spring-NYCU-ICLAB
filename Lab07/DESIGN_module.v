module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_matrix_A,
    in_matrix_B,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_matrix,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);

//---------------------------------------------------------------------
//   Input & Output Declaration
//---------------------------------------------------------------------	
input            clk;
input            rst_n;
input            in_valid;
input      [3:0] in_matrix_A;
input      [3:0] in_matrix_B;
input            out_idle;      // Handshake module's sidle, when sreq && sack both low, we can send next data to handshake

output reg       handshake_sready;
output reg [7:0] handshake_din;

// * You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;  // unuse
output flag_clk1_to_handshake;  // unuse

input            fifo_empty;
input      [7:0] fifo_rdata;

output reg       fifo_rinc;
output reg       out_valid;
output reg [7:0] out_matrix;

// * You can use the the custom flag ports for your design
output flag_clk1_to_fifo;  // unuse
input  flag_fifo_to_clk1;  // when 1, we can add rinc, read next data from FIFO

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
localparam IDLE   = 0;
localparam INPUT  = 1; // send data to Handshale_syn module
localparam WAIT   = 2; // wait clk2 module write data into FIFO
localparam R_FIFO = 3; // read data from FIFO
reg [1:0] cs, ns;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
reg       delay_sready;
reg       delay_fifo_to_clk1;

reg [3:0] in_cnt;
reg [4:0] out_cnt;
reg [4:0] idle_cnt;
reg [4:0] hd_cnt;    // handshake's cnt

reg [7:0] in_matrix_reg [0:15];

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

// -------------------------------------------- FSM ------------------------------------------- //
always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n) cs <= IDLE;
    else       cs <= ns;    
end

always @(*) 
begin
    case (cs)
        IDLE:    ns = (in_valid)? INPUT : IDLE;
        INPUT:   ns = (hd_cnt == 16)? WAIT : INPUT;
        WAIT:    ns = (flag_fifo_to_clk1)? R_FIFO : WAIT;
        R_FIFO:  ns = (idle_cnt == 16)? IDLE : ((out_cnt == 16)? WAIT : R_FIFO); 
        default: ns = cs;
    endcase
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)                          idle_cnt <= 0;
    else if(cs == IDLE)                 idle_cnt <= 0;
    else if(out_cnt == 15 && out_valid) idle_cnt <= idle_cnt + 1;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)          out_cnt <= 0;
    else if(cs == WAIT) out_cnt <= 0;
    else if(out_valid)  out_cnt <= out_cnt + 1;
end

// ---------------------------------------- store input --------------------------------------- //
// control the input store in matrix
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) in_cnt <= 0;
    else       in_cnt <= (in_valid)? in_cnt + 1 : 0;
end

always @(posedge clk) 
begin
    if(in_valid)
        in_matrix_reg[in_cnt] <= {in_matrix_A, in_matrix_B};
end

// ----------------------------------- send data to handshake --------------------------------- //
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) delay_sready <= 0;
    else       delay_sready <= handshake_sready;
end 

// control the data to handshake
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)                                 hd_cnt <= 0;
    else if(hd_cnt == 16)                      hd_cnt <= 0;
    else if(delay_sready && !handshake_sready) hd_cnt <= hd_cnt + 1;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
    begin
        handshake_sready <= 0;
        handshake_din    <= 0;
    end
    else
    begin
        handshake_sready <= (cs == INPUT && out_idle)? 1: 0;  // when out_idle is 1, we can send next data to handshake
        handshake_din    <= (cs == INPUT && out_idle)? in_matrix_reg[hd_cnt] : handshake_din;       
    end
end


// ------------------------------------ read data from FIFO ----------------------------------- //
always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n) delay_fifo_to_clk1 <= 0;
    else       delay_fifo_to_clk1 <= flag_fifo_to_clk1;
end

// Jasper Gold's spec: POP_ON_EMPTY, rempty & rinc cannot high in same cycle
always @(*) fifo_rinc = (!delay_fifo_to_clk1 && flag_fifo_to_clk1 && !fifo_empty)? 1 : 0;

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n) out_valid  <= 0;
    else       out_valid  <= (fifo_rinc)? 1 : 0;
end

always @(*) out_matrix = (out_valid)? fifo_rdata : 0;

endmodule


module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_matrix,
    out_valid,
    out_matrix,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

//---------------------------------------------------------------------
//   Input & Output Declaration
//---------------------------------------------------------------------	
input            clk;
input            rst_n;
input            in_valid;      // handshake's dvalid
input            fifo_full;
input      [7:0] in_matrix;     // {in_matrix_A, in_matrix_B}

output reg       out_valid;     // FIFO's winc
output reg [7:0] out_matrix;    // FIFO's wdata 
output reg       busy;

// * You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;  // unuse
output flag_clk2_to_handshake;  // unuse

input  flag_fifo_to_clk2;       // when become 1, we can send data to FIFO
output flag_clk2_to_fifo;       // unuse

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
localparam IDLE   = 0;
localparam INPUT  = 1; // get 16 input from handshake
localparam MUL    = 2; // multiply
localparam W_FIFO = 3; // write data into FIFO
localparam W_WAIT = 4; // wait two cycle
localparam WAIT   = 5; // wait clk1 moudule read data from FIFO
reg [2:0] cs, ns;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
integer i;

reg [4:0] in_cnt;
reg [4:0] fifo_cnt;
reg [4:0] out_cnt;
reg [4:0] mul_cnt;

reg [7:0] in_matrix_reg [0:15];
reg [7:0] C             [0:15];

reg       delay_valid;
//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

// -------------------------------------------- FSM ------------------------------------------- //
always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n) cs <= IDLE;
    else       cs <= ns;    
end

always @(*) 
begin
    ns = cs;
    case (cs)
        IDLE:    ns = (in_valid)? INPUT : IDLE;
        INPUT:   ns = (!in_valid && in_cnt == 16)? MUL : INPUT;
        MUL:     ns = W_FIFO;
        W_FIFO:  ns = (flag_fifo_to_clk2)? W_WAIT : W_FIFO; 
        W_WAIT:  ns = (out_cnt == 16 && !flag_fifo_to_clk2)? WAIT : ((!flag_fifo_to_clk2 && !out_valid)? W_FIFO : W_WAIT);
        WAIT:    ns = (mul_cnt == 16)? IDLE : ((flag_fifo_to_clk2)? MUL : WAIT); 
    endcase
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)          mul_cnt <= 0;
    else if(cs == IDLE) mul_cnt <= 0;
    else if(cs == MUL)  mul_cnt <= mul_cnt + 1;
end

// --------------------------------- store data from hanndshake ------------------------------- //
always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n) delay_valid <= 0;
    else       delay_valid <= in_valid;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)                        in_cnt <= 0;
    else if(ns == IDLE)               in_cnt <= 0;
    else if(!delay_valid && in_valid) in_cnt <= in_cnt + 1;
end

always @(posedge clk) 
begin
    if(in_valid)
        in_matrix_reg[in_cnt] <= in_matrix;
end

// ----------------------------------------- multiply ----------------------------------------- //
always @(posedge clk) 
begin
    if(cs == MUL)
    begin
        for(i=0;i<16;i=i+1)
            C[i] <= in_matrix_reg[mul_cnt][7:4] * in_matrix_reg[i][3:0];
    end
end

// ------------------------------------ write data into FIFO ----------------------------------- //
always @(posedge clk or negedge rst_n) 
begin                
    if(!rst_n)                                            fifo_cnt <= 0;
    else if(ns == WAIT || fifo_full)                      fifo_cnt <= 0;
    else if(cs == W_FIFO && flag_fifo_to_clk2)            fifo_cnt <= 0;
    else if((cs == W_FIFO || cs == W_WAIT) && !fifo_full) fifo_cnt <= fifo_cnt + 1;
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)          out_cnt <= 0;
    else if(cs == WAIT) out_cnt <= 0;
    else                out_cnt <= (fifo_cnt == 1)? out_cnt + 1 : out_cnt;
end

// FIFO's winc
// Jasper Gold's spec: PSH_ON_FULL, wfull & winc cannot high in same cycle
always @(*) out_valid = (fifo_cnt == 1 && !fifo_full)? 1 : 0;

// FIFO's wdata
always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n) out_matrix <= 0;
    else       out_matrix <= C[out_cnt];
end

// when busy (ex: write data into FIFO), handshake cannot send data into clk2
always @(*) busy = (cs == IDLE || cs == INPUT || cs == WAIT)? 0 : 1;


endmodule