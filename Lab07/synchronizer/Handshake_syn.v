module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

//---------------------------------------------------------------------
//   Input & Output Declaration
//---------------------------------------------------------------------	
input                  sclk, dclk; // source & destination
input                  rst_n;
input                  sready;
input      [WIDTH-1:0] din;
input                  dbusy;

output                 sidle;
output reg             dvalid;
output reg [WIDTH-1:0] dout;

// * You can change the input / output of the custom flag ports
output reg flag_handshake_to_clk1;  // unuse
input      flag_clk1_to_handshake;  // unuse

output flag_handshake_to_clk2;      // unuse
input  flag_clk2_to_handshake;      // unuse

// ! Remember: Don't modify the signal name 
// request / acknowledge
// sreq = 1 --> dreq = 1 --> dack = 1 --> sack = 1 --> sreq = 0 --> dreq = 0 --> dack =0 --> sack = 0
reg  sreq; 
wire dreq;
reg  dack;
wire sack;

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
reg [WIDTH-1:0] data;

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

// NDFF_SYN0: source's      req --> NDFF --> destination's req
// NDFF_SYN1: destination's ack --> NDFF --> source's      ack
NDFF_syn NDFF_SYN0 (.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn NDFF_SYN1 (.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));
// ------------------------------------------- sclk -------------------------------------------- //
assign sidle = (sreq || sack)? 0 : 1;

always @(posedge sclk or negedge rst_n) 
begin
    if(!rst_n)      sreq <= 0;
    else if(sack)   sreq <= 0; 
    else if(sready) sreq <= 1;     
end

always @(posedge sclk or negedge rst_n)
begin
	if(!rst_n) data <= 0;
	else       data <= (sready)? din : data;
end

// ------------------------------------------- dclk -------------------------------------------- //
always @(posedge dclk or negedge rst_n) 
begin
    if(!rst_n) dack <= 0;
    else       dack <= (dreq)? 1 : 0;
end

always @(posedge dclk or negedge rst_n) 
begin
    if(!rst_n)
    begin
        dout   <= 0; 
        dvalid <= 0;
    end 
    else
    begin
        dout   <= (dreq && !dbusy)? data : dout;
        dvalid <= (dreq && !dbusy)? 1 : 0;
    end
end

endmodule
