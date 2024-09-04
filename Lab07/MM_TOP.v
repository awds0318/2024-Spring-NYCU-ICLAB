`include "DESIGN_module.v"
`include "synchronizer/Handshake_syn.v"
`include "synchronizer/FIFO_syn.v"
`include "synchronizer/NDFF_syn.v"
`include "synchronizer/NDFF_BUS_syn.v"

module MM_TOP (
	// Input signals
	clk1,
	clk2,
	rst_n,
	in_valid,
	in_matrix_A,
	in_matrix_B,
	//  Output signals
	out_valid,
	out_matrix
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input        clk1; 
input        clk2;		
input        rst_n;
input        in_valid;
input  [3:0] in_matrix_A;
input  [3:0] in_matrix_B;

output       out_valid;
output [7:0] out_matrix; 	

// --------------------------------------------------------------------
//   SIGNAL DECLARATION
// --------------------------------------------------------------------
wire       sidle;
wire       matrix_valid_clk1;
wire [7:0] matrix_clk1;
wire       in_matrix_valid_clk2;
wire [7:0] in_matrix_clk2;
wire       mm_busy;
wire       out_matrix_valid_clk2;
wire [7:0] out_matrix_clk2;
wire       fifo_full;
wire       fifo_empty;
wire       fifo_rinc;
wire [7:0] fifo_rdata; 

// Custom flags to use if needed
wire flag_handshake_to_clk1;
wire flag_clk1_to_handshake;

wire flag_handshake_to_clk2;
wire flag_clk2_to_handshake;

wire flag_fifo_to_clk2;
wire flag_clk2_to_fifo;

wire flag_fifo_to_clk1;
wire flag_clk1_to_fifo;

CLK_1_MODULE u_input_output (
    .clk (clk1),
    .rst_n (rst_n),
    .in_valid (in_valid),
	.in_matrix_A (in_matrix_A),
	.in_matrix_B (in_matrix_B),
    .out_idle (sidle),
    .handshake_sready (matrix_valid_clk1),
    .handshake_din (matrix_clk1),
    .flag_handshake_to_clk1(flag_handshake_to_clk1),
    .flag_clk1_to_handshake(flag_clk1_to_handshake),
	

	.fifo_empty (fifo_empty),
    .fifo_rdata (fifo_rdata),
    .fifo_rinc (fifo_rinc),
    .out_valid (out_valid),
    .out_matrix (out_matrix),
    .flag_fifo_to_clk1(flag_fifo_to_clk1),
	.flag_clk1_to_fifo(flag_clk1_to_fifo)
);


Handshake_syn #(8) u_Handshake_syn (
    .sclk (clk1),
    .dclk (clk2),
    .rst_n (rst_n),
    .sready (matrix_valid_clk1),
    .din (matrix_clk1),
    .dbusy (mm_busy),
    .sidle (sidle),
    .dvalid (in_matrix_valid_clk2),
    .dout (in_matrix_clk2),

    .flag_handshake_to_clk1(flag_handshake_to_clk1),
    .flag_clk1_to_handshake(flag_clk1_to_handshake),

    .flag_handshake_to_clk2(flag_handshake_to_clk2),
    .flag_clk2_to_handshake(flag_clk2_to_handshake)
);

CLK_2_MODULE u_MM (
	.clk (clk2),
    .rst_n (rst_n),
    .in_valid (in_matrix_valid_clk2),
    .in_matrix (in_matrix_clk2),
	.fifo_full (fifo_full),
    .out_valid (out_matrix_valid_clk2),
    .out_matrix (out_matrix_clk2),
    .busy (mm_busy),

    .flag_handshake_to_clk2(flag_handshake_to_clk2),
    .flag_clk2_to_handshake(flag_clk2_to_handshake),

    .flag_fifo_to_clk2(flag_fifo_to_clk2),
    .flag_clk2_to_fifo(flag_clk2_to_fifo)
);

FIFO_syn #(.WIDTH(8), .WORDS(64)) u_FIFO_syn (
    .wclk (clk2),
    .rclk (clk1),
    .rst_n (rst_n),
    .winc (out_matrix_valid_clk2),
    .wdata (out_matrix_clk2),
    .wfull (fifo_full),
    .rinc (fifo_rinc),
    .rdata (fifo_rdata),
    .rempty (fifo_empty),

    .flag_fifo_to_clk2(flag_fifo_to_clk2),
    .flag_clk2_to_fifo(flag_clk2_to_fifo),

    .flag_fifo_to_clk1(flag_fifo_to_clk1),
	.flag_clk1_to_fifo(flag_clk1_to_fifo)
);

endmodule