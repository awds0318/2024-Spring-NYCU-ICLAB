module FIFO_syn #(parameter WIDTH=8, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
	flag_clk1_to_fifo
);

//---------------------------------------------------------------------
//   Input & Output Declaration
//---------------------------------------------------------------------	
input                  wclk, rclk;
input                  rst_n;
input                  winc;        // MM_module's out_valid
input      [WIDTH-1:0] wdata;       // MM_module's out_matrix
output reg             wfull;
input                  rinc;
output reg [WIDTH-1:0] rdata;
output reg             rempty;

// * You can change the input / output of the custom flag ports
output reg flag_fifo_to_clk2;  // when 1, clk2 module can write next data into FIFO
input      flag_clk2_to_fifo;  // unuse

output reg flag_fifo_to_clk1;  // when 1, clk1 module can read next data from FIFO
input      flag_clk1_to_fifo;  // unuse

wire [WIDTH-1:0] rdata_r;

// ! Remember: Don't modify the signal name
// wptr and rptr should be gray coded
parameter N = $clog2(WORDS);
reg [N:0] wptr, rq2_wptr;
reg [N:0] rptr, wq2_rptr;

// rdata
// Add one more register stage to rdata
always @(posedge rclk, negedge rst_n) 
begin
    if(!rst_n)              rdata <= 0;
    else if(rinc & !rempty) rdata <= rdata_r;
end

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
integer     i;

reg [N+1:0] w_addr;
reg [N+1:0] r_addr;
reg [N:0]   rq2_wptr_bin;

reg [2:0]   wflag_cnt;
reg [2:0]   rflag_cnt;

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

NDFF_BUS_syn #(N+1) sync_r2w (.D(rptr), .Q(wq2_rptr), .clk(wclk), .rst_n(rst_n));
NDFF_BUS_syn #(N+1) sync_w2r (.D(wptr), .Q(rq2_wptr), .clk(rclk), .rst_n(rst_n));

// -------------------------------------- flag_fifo_to_clk2 ----------------------------------- //
always @(posedge wclk or negedge rst_n) 
begin
    if(!rst_n) wflag_cnt <= 0;
    else       wflag_cnt <= (!wfull && !winc)? wflag_cnt + 1 : 0;
end

always @(*) 
begin
    if(wfull)
        flag_fifo_to_clk2 = 0;
    else if(wptr == wq2_rptr && w_addr != 0)
        flag_fifo_to_clk2 = 1;
    else if(w_addr[6:0] == 0 || w_addr[6:0] == 16 || w_addr[6:0] == 32 || w_addr[6:0] == 48 || w_addr[6:0] == 64 || w_addr[6:0] == 80 || w_addr[6:0] == 96 || w_addr[6:0] == 112)
        flag_fifo_to_clk2 = 0;
    else if(wflag_cnt == 1 || wflag_cnt == 2) // after two cycle, address in NDFF will be static
        flag_fifo_to_clk2 = 1;
    else       
        flag_fifo_to_clk2 = 0;
end
// -------------------------------------- flag_fifo_to_clk1 ----------------------------------- //
// convert gray code to binary
always @(*) 
begin
	rq2_wptr_bin[N]	= rq2_wptr[N];		
	for(i=N-1;i>=0;i=i-1) 
		rq2_wptr_bin[i] = rq2_wptr_bin[i+1] ^ rq2_wptr[i];
end

always @(posedge rclk or negedge rst_n) 
begin
    if(!rst_n) rflag_cnt <= 0;
    else       rflag_cnt <= (!rempty && !rinc)? rflag_cnt + 1 : 0;
end

always @(*) 
begin
    if(rempty)
        flag_fifo_to_clk1 = 0;
    else if((rq2_wptr_bin - r_addr[6:0] == 16) || (rq2_wptr_bin == 0 && r_addr[6:0] == 112))
        flag_fifo_to_clk1 = 1;
    else if(r_addr[6:0] == 0 || r_addr[6:0] == 16 || r_addr[6:0] == 32 || r_addr[6:0] == 48 || r_addr[6:0] == 64 || r_addr[6:0] == 80 || r_addr[6:0] == 96 || r_addr[6:0] == 112)
        flag_fifo_to_clk1 = 0;
    else if(rflag_cnt == 1 || rflag_cnt == 2) // after two cycle, address in NDFF will be static
        flag_fifo_to_clk1 = 1;
    else       
        flag_fifo_to_clk1 = 0;
end

// ---------------------------------------- empty & full -------------------------------------- //
always @(posedge rclk or negedge rst_n)
begin
    if(!rst_n) rempty <= 1;
    else       rempty <= (rptr == rq2_wptr); 
end

always @(posedge wclk or negedge rst_n) 
begin
    if(!rst_n) wfull <= 0;
    else       wfull <= (wptr == {~wq2_rptr[N:N-1], wq2_rptr[N-2:0]}); // when full, highest two bits will invert to wptr
end

// --------------------------------------- SRAM's address ------------------------------------- //
always @(posedge wclk or negedge rst_n) 
begin
    if(!rst_n) w_addr <= 0;
    else       w_addr <= w_addr + (!wfull && winc);
end

always @(posedge rclk or negedge rst_n) 
begin
    if(!rst_n) r_addr <= 0;
    else       r_addr <= r_addr + (!rempty && rinc);
end

// address in gray code
always @(*) 
begin
    wptr = (w_addr[N:0] >> 1) ^ w_addr[N:0];
    rptr = (r_addr[N:0] >> 1) ^ r_addr[N:0];
end

// always @(*) 
// begin
//     wptr[6] = w_addr[6];
//     wptr[5] = w_addr[5] ^ w_addr[6];
//     wptr[4] = w_addr[4] ^ w_addr[5];
//     wptr[3] = w_addr[3] ^ w_addr[4];
//     wptr[2] = w_addr[2] ^ w_addr[3];
//     wptr[1] = w_addr[1] ^ w_addr[2];
//     wptr[0] = w_addr[0] ^ w_addr[1];
// end

// always @(*) 
// begin
//     rptr[6] = r_addr[6];
//     rptr[5] = r_addr[5] ^ r_addr[6];
//     rptr[4] = r_addr[4] ^ r_addr[5];
//     rptr[3] = r_addr[3] ^ r_addr[4];
//     rptr[2] = r_addr[2] ^ r_addr[3];
//     rptr[1] = r_addr[1] ^ r_addr[2];
//     rptr[0] = r_addr[0] ^ r_addr[1];
// end

// --------------------------------------- dual port SRAM ------------------------------------- //
// A for write, B for read
wire WEAN = ~(winc && !wfull);

DUAL_64X8X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(WEAN),
    .WEBN(1'b1),
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(w_addr[0]),
    .A1(w_addr[1]),
    .A2(w_addr[2]),
    .A3(w_addr[3]),
    .A4(w_addr[4]),
    .A5(w_addr[5]),
    .B0(r_addr[0]),
    .B1(r_addr[1]),
    .B2(r_addr[2]),
    .B3(r_addr[3]),
    .B4(r_addr[4]),
    .B5(r_addr[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIB0(1'b0),
    .DIB1(1'b0),
    .DIB2(1'b0),
    .DIB3(1'b0),
    .DIB4(1'b0),
    .DIB5(1'b0),
    .DIB6(1'b0),
    .DIB7(1'b0),
    .DOB0(rdata_r[0]),
    .DOB1(rdata_r[1]),
    .DOB2(rdata_r[2]),
    .DOB3(rdata_r[3]),
    .DOB4(rdata_r[4]),
    .DOB5(rdata_r[5]),
    .DOB6(rdata_r[6]),
    .DOB7(rdata_r[7])
);

endmodule
