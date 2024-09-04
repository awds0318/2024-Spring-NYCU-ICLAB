//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Midterm Proejct            : MRA  
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
	     arid_m_inf,
	   araddr_m_inf,
	    arlen_m_inf,
	   arsize_m_inf,
	  arburst_m_inf,
	  arvalid_m_inf,
	  arready_m_inf,
	
	      rid_m_inf,
	    rdata_m_inf,
	    rresp_m_inf,
	    rlast_m_inf,
	   rvalid_m_inf,
	   rready_m_inf,
	
	     awid_m_inf,
	   awaddr_m_inf,
	   awsize_m_inf,
	  awburst_m_inf,
	    awlen_m_inf,
	  awvalid_m_inf,
	  awready_m_inf,
	
	    wdata_m_inf,
	    wlast_m_inf,
	   wvalid_m_inf,
	   wready_m_inf,
	
	      bid_m_inf,
	    bresp_m_inf,
	   bvalid_m_inf,
	   bready_m_inf 
);
//---------------------------------------------------------------------
//   Input & Output Declaration
//---------------------------------------------------------------------
// << CHIP io port with system >>
input 			  clk, rst_n;
input 			  in_valid;
input      [4:0]  frame_id;
input      [3:0]  net_id;     
input      [5:0]  loc_x; 
input      [5:0]  loc_y; 
output reg [13:0] cost;
output reg        busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

parameter ID_WIDTH = 4, ADDR_WIDTH = 32, DATA_WIDTH = 128;  // ! DONT MODIFY
// ----------------------------------------- AXI READ ----------------------------------------- //
// (1)	axi read address channel (AR)
output wire [ID_WIDTH-1:0]   arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]            arsize_m_inf;
output wire [7:0]            arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0] araddr_m_inf;

// (2)	axi read data channel (R)
input  wire [ID_WIDTH-1:0]   rid_m_inf;
input  wire                  rvalid_m_inf;
output wire                  rready_m_inf;
input  wire [DATA_WIDTH-1:0] rdata_m_inf;
input  wire                  rlast_m_inf;
input  wire [1:0]            rresp_m_inf;

// ----------------------------------------- AXI WRITE ---------------------------------------- //
// (1) 	axi write address channel (AW)
output wire [ID_WIDTH-1:0]   awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]            awsize_m_inf;
output wire [7:0]            awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0] awaddr_m_inf;

// (2)	axi write data channel (W)
output wire                  wvalid_m_inf;
input  wire                  wready_m_inf;
output wire [DATA_WIDTH-1:0] wdata_m_inf;
output wire                  wlast_m_inf;

// (3)	axi write response channel (B)
input  wire  [ID_WIDTH-1:0] bid_m_inf;
input  wire                 bvalid_m_inf;
output wire                 bready_m_inf;
input  wire  [1:0]          bresp_m_inf;

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
localparam IDLE          = 0;
localparam INPUT         = 1;   // for getting frame_id, net_id, loc_x, loc_y
localparam R_WEIGHT      = 2;   // read weight from DRAM through AXI
localparam WAIT_AR       = 3;   
localparam R_MAP         = 4;   // read map from DRAM through AXI
localparam MAP_START     = 5;   // for setting source & sink's value
localparam PROPAGATE     = 6;   // by using algorithm 2233
localparam RETRACE_READ  = 7;   // read the value in SRAM, and change specific 4 bits in RETRACE_WRITE
localparam RETRACE_WRITE = 8;   // write retrace path into map SRAM
localparam MAP_CLEAR     = 9;   // clear the propagate value (2233)
localparam WAIT_AW       = 10;
localparam W_MAP         = 11;  // write map into DRAM through AXI
localparam WAIT_B        = 12;
reg [3:0] cs, ns;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
integer i, j;

reg       delay_valid;
reg [4:0] frame_id_reg;
reg [3:0] net_id_reg [0:14];  // may conntain 1 ~ 15 targets
reg [5:0] loc_x_reg  [0:29];  // 15 targets * 2 (1 for source & 1 for sink) = 30
reg [5:0] loc_y_reg  [0:29]; 

reg [1:0] map [0:63][0:63];

reg [4:0] in_cnt;             // need storing 30 different value
// reg [3:0] net_cnt;            // for storing net_id
reg [1:0] cnt_4;
reg [6:0] cnt_128;

reg  [5:0] retrace_x, retrace_x_r;
reg  [5:0] retrace_y, retrace_y_r;
wire [5:0] retrace_x_add, retrace_x_sub;
wire [5:0] retrace_y_add, retrace_y_sub;

reg         w_WEB, m_WEB;
reg [6:0]   w_addr, m_addr;
reg [127:0] w_DI, w_DO, m_DI, m_DO;
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
    case(cs)
        IDLE:          ns = (in_valid)? INPUT : IDLE;
        INPUT:         ns = (arready_m_inf)? R_WEIGHT : INPUT;
        R_WEIGHT:      ns = (rlast_m_inf)? WAIT_AR : R_WEIGHT;
        WAIT_AR:       ns = (arready_m_inf)? R_MAP : WAIT_AR;
        R_MAP:         ns = (rlast_m_inf)? MAP_START : R_MAP;
        MAP_START:     ns = PROPAGATE;
        PROPAGATE:     ns = (map[loc_y_reg[1]][loc_x_reg[1]][1] == 1)? RETRACE_READ : PROPAGATE; // sink's value become 2 or 3
        RETRACE_READ:  ns = RETRACE_WRITE;
        RETRACE_WRITE: ns = (retrace_x == loc_x_reg[0] && retrace_y == loc_y_reg[0])? ((net_id_reg[1] == 0)? WAIT_AW : MAP_CLEAR) : RETRACE_READ;
        MAP_CLEAR:     ns = MAP_START;
        WAIT_AW:       ns = (awready_m_inf)? W_MAP : WAIT_AW;
        W_MAP:         ns = (cnt_128 == 127)? WAIT_B : W_MAP;
        WAIT_B:        ns = (bvalid_m_inf)? IDLE : WAIT_B;
        default:       ns = IDLE;
    endcase
end

// ---------------------------------------- Storing Input -------------------------------------- //
always @(posedge clk) in_cnt  <= (in_valid)? in_cnt + 1 : 0;
// always @(posedge clk) net_cnt <= (in_valid)? ((in_cnt[0] == 1)? net_cnt + 1 : net_cnt) : 0;

always @(posedge clk)
begin
	if(ns == IDLE)
	begin
		for(i=0;i<15;i=i+1)
			net_id_reg[i] <= 0;
	end
	else if(in_valid)
	begin
		case (in_cnt)  // net_id_reg[net_cnt] <= net_id;
			0:  net_id_reg[0]  <= net_id;
			2:  net_id_reg[1]  <= net_id;
			4:  net_id_reg[2]  <= net_id;
			6:  net_id_reg[3]  <= net_id;
			8:  net_id_reg[4]  <= net_id;
			10: net_id_reg[5]  <= net_id;
			12: net_id_reg[6]  <= net_id;
			14: net_id_reg[7]  <= net_id;
			16: net_id_reg[8]  <= net_id;
			18: net_id_reg[9]  <= net_id;
			20: net_id_reg[10] <= net_id;
			22: net_id_reg[11] <= net_id;
			24: net_id_reg[12] <= net_id;
			26: net_id_reg[13] <= net_id;
			28: net_id_reg[14] <= net_id;
		endcase
	end
	else if(cs == MAP_CLEAR)
	begin
		net_id_reg[0:13] <= net_id_reg[1:14];
		net_id_reg[14]   <= 0;
	end
end

always @(posedge clk) frame_id_reg <= (in_valid)? frame_id : frame_id_reg;

always @(posedge clk)
begin
	if(in_valid)
	begin
		loc_x_reg[in_cnt] <= loc_x;
		loc_y_reg[in_cnt] <= loc_y;
	end
	else if(cs == MAP_CLEAR)
	begin
		loc_x_reg[0:27] <= loc_x_reg[2:29];
		loc_y_reg[0:27] <= loc_y_reg[2:29];

		loc_x_reg[28] <= 0;
		loc_y_reg[28] <= 0;
		loc_x_reg[29] <= 0;
		loc_y_reg[29] <= 0;
	end
end

// ------------------------------------- Propagate & Retrace ----------------------------------- //
// counter for 2233
always @(posedge clk)
begin
	case (cs)
		PROPAGATE:     cnt_4 <= (ns == RETRACE_READ)? cnt_4 - 2 : cnt_4 + 1;
		RETRACE_WRITE: cnt_4 <= cnt_4 - 1; 
		RETRACE_READ:  cnt_4 <= cnt_4;
		default:       cnt_4 <= 0;
	endcase
end

wire   prop; // the value for propagating
assign prop = (cnt_4[1])? 1 : 0;

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cnt_128 <= 0;
	else
	begin
		case (cs)
			R_WEIGHT, R_MAP: cnt_128 <= (rvalid_m_inf)? cnt_128 + 1 : cnt_128;
			W_MAP:           cnt_128 <= cnt_128 + wready_m_inf;
			// W_MAP:           cnt_128 <= (wvalid_m_inf && !wready_m_inf)? cnt_128 : cnt_128 + 1;
			// W_MAP:           cnt_128 <= (wready_m_inf)? cnt_128 + 1 : cnt_128;
			default:         cnt_128 <= 0;
		endcase
	end
end

assign retrace_x_add = retrace_x + 1;
assign retrace_x_sub = retrace_x - 1;
assign retrace_y_add = retrace_y + 1;
assign retrace_y_sub = retrace_y - 1;

always @(*)
begin
    retrace_x_r = retrace_x;
    retrace_y_r = retrace_y;

    if     ((retrace_y != 63) && (map[retrace_y_add][retrace_x    ] == {1'b1, prop})) retrace_y_r = retrace_y_add;  // down
    else if((retrace_y != 0 ) && (map[retrace_y_sub][retrace_x    ] == {1'b1, prop})) retrace_y_r = retrace_y_sub;  // up
    else if((retrace_x != 63) && (map[retrace_y    ][retrace_x_add] == {1'b1, prop})) retrace_x_r = retrace_x_add;  // right
    else                                                                              retrace_x_r = retrace_x_sub;  // left
end

always @(posedge clk) retrace_x <= (cs == RETRACE_WRITE)? retrace_x_r : ((cs == RETRACE_READ)? retrace_x : loc_x_reg[1]);
always @(posedge clk) retrace_y <= (cs == RETRACE_WRITE)? retrace_y_r : ((cs == RETRACE_READ)? retrace_y : loc_y_reg[1]);

always @(posedge clk)
begin
	case (cs)
		R_MAP:
		begin
			for(i=0;i<64;i=i+1)
				for(j=0; j<64; j=j+1)
					map[i][j] <= map[i][j];

			for(i=0; i<32; i=i+1)
				map[cnt_128[6:1]][{cnt_128[0], i[4:0]}] <= (rdata_m_inf[4*i+:4] == 0)? 0 : 1; // set the target to 1
		end
		MAP_START: // set the source & sink to 3, 0 at the first cycle of compute
		begin
			for(i=0;i<64;i=i+1)
				for(j=0;j<64;j=j+1)
					map[i][j] <= map[i][j];
			
			map[loc_y_reg[0]][loc_x_reg[0]] <= 3; // source
			map[loc_y_reg[1]][loc_x_reg[1]] <= 0; // sink
		end
		PROPAGATE:
		begin
			// In (62 x 62)
			for(i=1;i<63;i=i+1)
				for(j=1; j<63; j=j+1)
					map[i][j] <= ((map[i][j] == 0) && (map[i+1][j][1] || map[i][j+1][1] || map[i-1][j][1] || map[i][j-1][1]))? {1'b1, prop} : map[i][j];
			
			for(i=1;i<63;i=i+1)
			begin
				map[0 ][i ] <= ((map[0 ][i ] == 0) && (map[1  ][i ][1] || map[0  ][i+1][1] || map[0 ][i-1][1]))? {1'b1, prop} : map[0 ][i ];  // Up
				map[63][i ] <= ((map[63][i ] == 0) && (map[62 ][i ][1] || map[63 ][i+1][1] || map[63][i-1][1]))? {1'b1, prop} : map[63][i ];  // Down
				map[i ][0 ] <= ((map[i ][0 ] == 0) && (map[i+1][0 ][1] || map[i-1][0  ][1] || map[i ][1  ][1]))? {1'b1, prop} : map[i ][0 ];  // Left 
				map[i ][63] <= ((map[i ][63] == 0) && (map[i+1][63][1] || map[i-1][63 ][1] || map[i ][62 ][1]))? {1'b1, prop} : map[i ][63];  // Right
			end
			
			// 4 corner
			map[0 ][0 ] <= ((map[0 ][0 ] == 0) && (map[1 ][0 ][1] || map[0 ][1 ][1]))? {1'b1, prop} : map[0 ][0 ];
			map[0 ][63] <= ((map[0 ][63] == 0) && (map[1 ][63][1] || map[0 ][62][1]))? {1'b1, prop} : map[0 ][63];
			map[63][0 ] <= ((map[63][0 ] == 0) && (map[62][0 ][1] || map[63][1 ][1]))? {1'b1, prop} : map[63][0 ];
			map[63][63] <= ((map[63][63] == 0) && (map[62][63][1] || map[63][62][1]))? {1'b1, prop} : map[63][63];
		end
		RETRACE_WRITE:
		begin
			for(i=0; i<64; i=i+1)
				for(j=0; j<64; j=j+1)
					map[i][j] <= map[i][j];

			map[retrace_y][retrace_x] <= 1;
		end
		MAP_CLEAR:
		begin
			for(i=0;i<64;i=i+1)
				for(j=0;j<64;j=j+1)
					map[i][j] <= (map[i][j][1])? 0 : map[i][j];
		end
		// default:
		// begin
		// 	for(i=0; i<64; i=i+1)
		// 		for(j=0; j<64; j=j+1)
		// 			map[i][j] <= map[i][j];
		// end
	endcase
end

// ----------------------------------------- AXI READ ----------------------------------------- //
// (1)	axi read address channel (AR)
always @(posedge clk) delay_valid <= in_valid;

assign arid_m_inf    = 0;
assign arburst_m_inf = 1;
assign arsize_m_inf  = 4;
assign arlen_m_inf   = 127;
assign arvalid_m_inf = ((cs == INPUT && !delay_valid) || cs == WAIT_AR)? 1 : 0;
assign araddr_m_inf  = (cs == R_WEIGHT || cs == INPUT)? {16'h0002, frame_id_reg, 11'h000} : {16'h0001, frame_id_reg, 11'h000}; 

// (2)	axi read data channel (R)
assign rready_m_inf = (cs == R_WEIGHT || cs == R_MAP)? 1 : 0;

// ----------------------------------------- AXI WRITE ----------------------------------------- //
// (1) 	axi write address channel (AW)
assign awid_m_inf    = 0;
assign awburst_m_inf = 1;
assign awsize_m_inf  = 4;
assign awlen_m_inf   = 127;
assign awvalid_m_inf = (cs == WAIT_AW)? 1 : 0;
assign awaddr_m_inf  = {16'h0001, frame_id_reg, 11'h000}; 

// (2)	axi write data channel (W)
assign wvalid_m_inf = (cs == W_MAP)? 1 : 0;
assign wdata_m_inf  = m_DO;
assign wlast_m_inf  = (cs == W_MAP && cnt_128 == 127)? 1 : 0;

// (3)	axi write response channel (B)
assign bready_m_inf = (cs == WAIT_B)? 1 : 0;

// ------------------------------------------ Output ------------------------------------------- //
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)                            busy <= 0;
    else if(delay_valid && !in_valid)     busy <= 1;
    else if(bready_m_inf && bvalid_m_inf) busy <= 0;
end

reg [3:0] cost_r, cost_delay;

// always @(*)	cost_r = w_DO[(retrace_x[4:0] * 4) +:4]; // ! 03_gate will not pass due to unknown value...

always @(*) 
begin
	cost_r = 0;
	case(retrace_x[4:0])
		0:  cost_r = w_DO[3:0];
		1:  cost_r = w_DO[7:4];
		2:  cost_r = w_DO[11:8];
		3:  cost_r = w_DO[15:12];
		4:  cost_r = w_DO[19:16];
		5:  cost_r = w_DO[23:20];
		6:  cost_r = w_DO[27:24];
		7:  cost_r = w_DO[31:28];
		8:  cost_r = w_DO[35:32];
		9:  cost_r = w_DO[39:36];
		10: cost_r = w_DO[43:40];
		11: cost_r = w_DO[47:44];
		12: cost_r = w_DO[51:48];
		13: cost_r = w_DO[55:52];
		14: cost_r = w_DO[59:56];
		15: cost_r = w_DO[63:60];
		16: cost_r = w_DO[67:64];
		17: cost_r = w_DO[71:68];
		18: cost_r = w_DO[75:72];
		19: cost_r = w_DO[79:76];
		20: cost_r = w_DO[83:80];
		21: cost_r = w_DO[87:84];
		22: cost_r = w_DO[91:88];
		23: cost_r = w_DO[95:92];
		24: cost_r = w_DO[99:96];
		25: cost_r = w_DO[103:100];
		26: cost_r = w_DO[107:104];
		27: cost_r = w_DO[111:108];
		28: cost_r = w_DO[115:112];
		29: cost_r = w_DO[119:116];
		30: cost_r = w_DO[123:120];
		31: cost_r = w_DO[127:124];
		// default : cost_r = 0;
	endcase
end

always @(posedge clk)
begin
	if(cs == IDLE || cs == MAP_CLEAR) 	               cost_delay <= 0;
	else if(cs == RETRACE_READ || cs == RETRACE_WRITE) cost_delay <= (retrace_x != loc_x_reg[1] || retrace_y != loc_y_reg[1])? cost_r : 0;
	else                                               cost_delay <= cost_delay;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)                  cost <= 0;
	else if(cs == IDLE)         cost <= 0;
    else if(cs == RETRACE_READ) cost <= cost + cost_delay;
	else		                cost <= cost;
end

// ------------------------------------------- SRAM -------------------------------------------- //
// signal for weight SRAM
always @(*) w_addr = (cs == RETRACE_READ || cs == RETRACE_WRITE)? {retrace_y, retrace_x[5]} : cnt_128;
always @(*) w_WEB  = (cs == R_WEIGHT)? ((rvalid_m_inf)? 0 : 1) : 1;
always @(*)	w_DI   = (cs == R_WEIGHT)? rdata_m_inf : 0;

// signal for location map SRAM
// ! In write transaction, wready_m_inf might be 0...
// ! you cannot always add 1
// ! Instead, you need to add wready_m_inf to ensure that addr is correct
// always @(*) m_addr = (cs == RETRACE_READ || cs == RETRACE_WRITE)? {retrace_y, retrace_x[5]} : ((cs == W_MAP)? cnt_128 + 1: cnt_128);                  // ! 01_RTL Fail !
// always @(*) m_addr = (cs == RETRACE_READ || cs == RETRACE_WRITE)? {retrace_y, retrace_x[5]} : ((cs == W_MAP && wready_m_inf)? cnt_128 + 1 : cnt_128); // pass
always @(*) m_addr = (cs == RETRACE_READ || cs == RETRACE_WRITE)? {retrace_y, retrace_x[5]} : ((cs == W_MAP)? cnt_128 + wready_m_inf : cnt_128);         // area better

always @(*)
begin
	case (cs)
		R_MAP:         m_WEB = (rvalid_m_inf)? 0 : 1;
		RETRACE_WRITE: m_WEB = 0;
		default:       m_WEB = 1;
	endcase 
end

always @(*)
begin
	m_DI = m_DO;
	case (cs)
		R_MAP:         m_DI = rdata_m_inf;
		RETRACE_WRITE: m_DI[(retrace_x[4:0] * 4) +:4] = net_id_reg[0];
		// RETRACE_WRITE: m_DI[(retrace_x[4:0] << 2) +:4] = net_id_reg[0]; // ! using << 2 will not store to correct address. !
		RETRACE_READ:  m_DI = m_DO;
	endcase
end

// Marco Area: 334775.258 x 2
WEIGHT u_WEIGHT(
	.A0(w_addr[0]), .A1(w_addr[1]), .A2(w_addr[2]), .A3(w_addr[3]), .A4(w_addr[4]), .A5(w_addr[5]), .A6(w_addr[6]),

	.DI0  (w_DI[0  ]), .DI1  (w_DI[1  ]), .DI2  (w_DI[2  ]), .DI3  (w_DI[3  ]), .DI4  (w_DI[4  ]), .DI5  (w_DI[5  ]), .DI6  (w_DI[6  ]), .DI7  (w_DI[7  ]),
	.DI8  (w_DI[8  ]), .DI9  (w_DI[9  ]), .DI10 (w_DI[10 ]), .DI11 (w_DI[11 ]), .DI12 (w_DI[12 ]), .DI13 (w_DI[13 ]), .DI14 (w_DI[14 ]), .DI15 (w_DI[15 ]),
	.DI16 (w_DI[16 ]), .DI17 (w_DI[17 ]), .DI18 (w_DI[18 ]), .DI19 (w_DI[19 ]), .DI20 (w_DI[20 ]), .DI21 (w_DI[21 ]), .DI22 (w_DI[22 ]), .DI23 (w_DI[23 ]),
	.DI24 (w_DI[24 ]), .DI25 (w_DI[25 ]), .DI26 (w_DI[26 ]), .DI27 (w_DI[27 ]), .DI28 (w_DI[28 ]), .DI29 (w_DI[29 ]), .DI30 (w_DI[30 ]), .DI31 (w_DI[31 ]),
	.DI32 (w_DI[32 ]), .DI33 (w_DI[33 ]), .DI34 (w_DI[34 ]), .DI35 (w_DI[35 ]), .DI36 (w_DI[36 ]), .DI37 (w_DI[37 ]), .DI38 (w_DI[38 ]), .DI39 (w_DI[39 ]),
	.DI40 (w_DI[40 ]), .DI41 (w_DI[41 ]), .DI42 (w_DI[42 ]), .DI43 (w_DI[43 ]), .DI44 (w_DI[44 ]), .DI45 (w_DI[45 ]), .DI46 (w_DI[46 ]), .DI47 (w_DI[47 ]),
	.DI48 (w_DI[48 ]), .DI49 (w_DI[49 ]), .DI50 (w_DI[50 ]), .DI51 (w_DI[51 ]), .DI52 (w_DI[52 ]), .DI53 (w_DI[53 ]), .DI54 (w_DI[54 ]), .DI55 (w_DI[55 ]),
	.DI56 (w_DI[56 ]), .DI57 (w_DI[57 ]), .DI58 (w_DI[58 ]), .DI59 (w_DI[59 ]), .DI60 (w_DI[60 ]), .DI61 (w_DI[61 ]), .DI62 (w_DI[62 ]), .DI63 (w_DI[63 ]),
	.DI64 (w_DI[64 ]), .DI65 (w_DI[65 ]), .DI66 (w_DI[66 ]), .DI67 (w_DI[67 ]), .DI68 (w_DI[68 ]), .DI69 (w_DI[69 ]), .DI70 (w_DI[70 ]), .DI71 (w_DI[71 ]),
	.DI72 (w_DI[72 ]), .DI73 (w_DI[73 ]), .DI74 (w_DI[74 ]), .DI75 (w_DI[75 ]), .DI76 (w_DI[76 ]), .DI77 (w_DI[77 ]), .DI78 (w_DI[78 ]), .DI79 (w_DI[79 ]),
	.DI80 (w_DI[80 ]), .DI81 (w_DI[81 ]), .DI82 (w_DI[82 ]), .DI83 (w_DI[83 ]), .DI84 (w_DI[84 ]), .DI85 (w_DI[85 ]), .DI86 (w_DI[86 ]), .DI87 (w_DI[87 ]),
	.DI88 (w_DI[88 ]), .DI89 (w_DI[89 ]), .DI90 (w_DI[90 ]), .DI91 (w_DI[91 ]), .DI92 (w_DI[92 ]), .DI93 (w_DI[93 ]), .DI94 (w_DI[94 ]), .DI95 (w_DI[95 ]),
	.DI96 (w_DI[96 ]), .DI97 (w_DI[97 ]), .DI98 (w_DI[98 ]), .DI99 (w_DI[99 ]), .DI100(w_DI[100]), .DI101(w_DI[101]), .DI102(w_DI[102]), .DI103(w_DI[103]),
	.DI104(w_DI[104]), .DI105(w_DI[105]), .DI106(w_DI[106]), .DI107(w_DI[107]), .DI108(w_DI[108]), .DI109(w_DI[109]), .DI110(w_DI[110]), .DI111(w_DI[111]),
	.DI112(w_DI[112]), .DI113(w_DI[113]), .DI114(w_DI[114]), .DI115(w_DI[115]), .DI116(w_DI[116]), .DI117(w_DI[117]), .DI118(w_DI[118]), .DI119(w_DI[119]),
	.DI120(w_DI[120]), .DI121(w_DI[121]), .DI122(w_DI[122]), .DI123(w_DI[123]), .DI124(w_DI[124]), .DI125(w_DI[125]), .DI126(w_DI[126]), .DI127(w_DI[127]),

	.DO0  (w_DO[0  ]), .DO1  (w_DO[1  ]), .DO2  (w_DO[2  ]), .DO3  (w_DO[3  ]), .DO4  (w_DO[4  ]), .DO5  (w_DO[5  ]), .DO6  (w_DO[6  ]), .DO7  (w_DO[7  ]),
	.DO8  (w_DO[8  ]), .DO9  (w_DO[9  ]), .DO10 (w_DO[10 ]), .DO11 (w_DO[11 ]), .DO12 (w_DO[12 ]), .DO13 (w_DO[13 ]), .DO14 (w_DO[14 ]), .DO15 (w_DO[15 ]),
	.DO16 (w_DO[16 ]), .DO17 (w_DO[17 ]), .DO18 (w_DO[18 ]), .DO19 (w_DO[19 ]), .DO20 (w_DO[20 ]), .DO21 (w_DO[21 ]), .DO22 (w_DO[22 ]), .DO23 (w_DO[23 ]),
	.DO24 (w_DO[24 ]), .DO25 (w_DO[25 ]), .DO26 (w_DO[26 ]), .DO27 (w_DO[27 ]), .DO28 (w_DO[28 ]), .DO29 (w_DO[29 ]), .DO30 (w_DO[30 ]), .DO31 (w_DO[31 ]),
	.DO32 (w_DO[32 ]), .DO33 (w_DO[33 ]), .DO34 (w_DO[34 ]), .DO35 (w_DO[35 ]), .DO36 (w_DO[36 ]), .DO37 (w_DO[37 ]), .DO38 (w_DO[38 ]), .DO39 (w_DO[39 ]),
	.DO40 (w_DO[40 ]), .DO41 (w_DO[41 ]), .DO42 (w_DO[42 ]), .DO43 (w_DO[43 ]), .DO44 (w_DO[44 ]), .DO45 (w_DO[45 ]), .DO46 (w_DO[46 ]), .DO47 (w_DO[47 ]),
	.DO48 (w_DO[48 ]), .DO49 (w_DO[49 ]), .DO50 (w_DO[50 ]), .DO51 (w_DO[51 ]), .DO52 (w_DO[52 ]), .DO53 (w_DO[53 ]), .DO54 (w_DO[54 ]), .DO55 (w_DO[55 ]),
	.DO56 (w_DO[56 ]), .DO57 (w_DO[57 ]), .DO58 (w_DO[58 ]), .DO59 (w_DO[59 ]), .DO60 (w_DO[60 ]), .DO61 (w_DO[61 ]), .DO62 (w_DO[62 ]), .DO63 (w_DO[63 ]),
	.DO64 (w_DO[64 ]), .DO65 (w_DO[65 ]), .DO66 (w_DO[66 ]), .DO67 (w_DO[67 ]), .DO68 (w_DO[68 ]), .DO69 (w_DO[69 ]), .DO70 (w_DO[70 ]), .DO71 (w_DO[71 ]),
	.DO72 (w_DO[72 ]), .DO73 (w_DO[73 ]), .DO74 (w_DO[74 ]), .DO75 (w_DO[75 ]), .DO76 (w_DO[76 ]), .DO77 (w_DO[77 ]), .DO78 (w_DO[78 ]), .DO79 (w_DO[79 ]),
	.DO80 (w_DO[80 ]), .DO81 (w_DO[81 ]), .DO82 (w_DO[82 ]), .DO83 (w_DO[83 ]), .DO84 (w_DO[84 ]), .DO85 (w_DO[85 ]), .DO86 (w_DO[86 ]), .DO87 (w_DO[87 ]),
	.DO88 (w_DO[88 ]), .DO89 (w_DO[89 ]), .DO90 (w_DO[90 ]), .DO91 (w_DO[91 ]), .DO92 (w_DO[92 ]), .DO93 (w_DO[93 ]), .DO94 (w_DO[94 ]), .DO95 (w_DO[95 ]),
	.DO96 (w_DO[96 ]), .DO97 (w_DO[97 ]), .DO98 (w_DO[98 ]), .DO99 (w_DO[99 ]), .DO100(w_DO[100]), .DO101(w_DO[101]), .DO102(w_DO[102]), .DO103(w_DO[103]),
	.DO104(w_DO[104]), .DO105(w_DO[105]), .DO106(w_DO[106]), .DO107(w_DO[107]), .DO108(w_DO[108]), .DO109(w_DO[109]), .DO110(w_DO[110]), .DO111(w_DO[111]),
	.DO112(w_DO[112]), .DO113(w_DO[113]), .DO114(w_DO[114]), .DO115(w_DO[115]), .DO116(w_DO[116]), .DO117(w_DO[117]), .DO118(w_DO[118]), .DO119(w_DO[119]),
	.DO120(w_DO[120]), .DO121(w_DO[121]), .DO122(w_DO[122]), .DO123(w_DO[123]), .DO124(w_DO[124]), .DO125(w_DO[125]), .DO126(w_DO[126]), .DO127(w_DO[127]),

	.CK(clk), .WEB(w_WEB), .OE(1'b1), .CS(1'b1));

MAP u_MAP(
	.A0(m_addr[0]), .A1(m_addr[1]), .A2(m_addr[2]), .A3(m_addr[3]), .A4(m_addr[4]), .A5(m_addr[5]), .A6(m_addr[6]),

	.DI0  (m_DI[0  ]), .DI1  (m_DI[1  ]), .DI2  (m_DI[2  ]), .DI3  (m_DI[3  ]), .DI4  (m_DI[4  ]), .DI5  (m_DI[5  ]), .DI6  (m_DI[6  ]), .DI7  (m_DI[7  ]),
	.DI8  (m_DI[8  ]), .DI9  (m_DI[9  ]), .DI10 (m_DI[10 ]), .DI11 (m_DI[11 ]), .DI12 (m_DI[12 ]), .DI13 (m_DI[13 ]), .DI14 (m_DI[14 ]), .DI15 (m_DI[15 ]),
	.DI16 (m_DI[16 ]), .DI17 (m_DI[17 ]), .DI18 (m_DI[18 ]), .DI19 (m_DI[19 ]), .DI20 (m_DI[20 ]), .DI21 (m_DI[21 ]), .DI22 (m_DI[22 ]), .DI23 (m_DI[23 ]),
	.DI24 (m_DI[24 ]), .DI25 (m_DI[25 ]), .DI26 (m_DI[26 ]), .DI27 (m_DI[27 ]), .DI28 (m_DI[28 ]), .DI29 (m_DI[29 ]), .DI30 (m_DI[30 ]), .DI31 (m_DI[31 ]),
	.DI32 (m_DI[32 ]), .DI33 (m_DI[33 ]), .DI34 (m_DI[34 ]), .DI35 (m_DI[35 ]), .DI36 (m_DI[36 ]), .DI37 (m_DI[37 ]), .DI38 (m_DI[38 ]), .DI39 (m_DI[39 ]),
	.DI40 (m_DI[40 ]), .DI41 (m_DI[41 ]), .DI42 (m_DI[42 ]), .DI43 (m_DI[43 ]), .DI44 (m_DI[44 ]), .DI45 (m_DI[45 ]), .DI46 (m_DI[46 ]), .DI47 (m_DI[47 ]),
	.DI48 (m_DI[48 ]), .DI49 (m_DI[49 ]), .DI50 (m_DI[50 ]), .DI51 (m_DI[51 ]), .DI52 (m_DI[52 ]), .DI53 (m_DI[53 ]), .DI54 (m_DI[54 ]), .DI55 (m_DI[55 ]),
	.DI56 (m_DI[56 ]), .DI57 (m_DI[57 ]), .DI58 (m_DI[58 ]), .DI59 (m_DI[59 ]), .DI60 (m_DI[60 ]), .DI61 (m_DI[61 ]), .DI62 (m_DI[62 ]), .DI63 (m_DI[63 ]),
	.DI64 (m_DI[64 ]), .DI65 (m_DI[65 ]), .DI66 (m_DI[66 ]), .DI67 (m_DI[67 ]), .DI68 (m_DI[68 ]), .DI69 (m_DI[69 ]), .DI70 (m_DI[70 ]), .DI71 (m_DI[71 ]),
	.DI72 (m_DI[72 ]), .DI73 (m_DI[73 ]), .DI74 (m_DI[74 ]), .DI75 (m_DI[75 ]), .DI76 (m_DI[76 ]), .DI77 (m_DI[77 ]), .DI78 (m_DI[78 ]), .DI79 (m_DI[79 ]),
	.DI80 (m_DI[80 ]), .DI81 (m_DI[81 ]), .DI82 (m_DI[82 ]), .DI83 (m_DI[83 ]), .DI84 (m_DI[84 ]), .DI85 (m_DI[85 ]), .DI86 (m_DI[86 ]), .DI87 (m_DI[87 ]),
	.DI88 (m_DI[88 ]), .DI89 (m_DI[89 ]), .DI90 (m_DI[90 ]), .DI91 (m_DI[91 ]), .DI92 (m_DI[92 ]), .DI93 (m_DI[93 ]), .DI94 (m_DI[94 ]), .DI95 (m_DI[95 ]),
	.DI96 (m_DI[96 ]), .DI97 (m_DI[97 ]), .DI98 (m_DI[98 ]), .DI99 (m_DI[99 ]), .DI100(m_DI[100]), .DI101(m_DI[101]), .DI102(m_DI[102]), .DI103(m_DI[103]),
	.DI104(m_DI[104]), .DI105(m_DI[105]), .DI106(m_DI[106]), .DI107(m_DI[107]), .DI108(m_DI[108]), .DI109(m_DI[109]), .DI110(m_DI[110]), .DI111(m_DI[111]),
	.DI112(m_DI[112]), .DI113(m_DI[113]), .DI114(m_DI[114]), .DI115(m_DI[115]), .DI116(m_DI[116]), .DI117(m_DI[117]), .DI118(m_DI[118]), .DI119(m_DI[119]),
	.DI120(m_DI[120]), .DI121(m_DI[121]), .DI122(m_DI[122]), .DI123(m_DI[123]), .DI124(m_DI[124]), .DI125(m_DI[125]), .DI126(m_DI[126]), .DI127(m_DI[127]),

	.DO0  (m_DO[0  ]), .DO1  (m_DO[1  ]), .DO2  (m_DO[2  ]), .DO3  (m_DO[3  ]), .DO4  (m_DO[4  ]), .DO5  (m_DO[5  ]), .DO6  (m_DO[6  ]), .DO7  (m_DO[7  ]),
	.DO8  (m_DO[8  ]), .DO9  (m_DO[9  ]), .DO10 (m_DO[10 ]), .DO11 (m_DO[11 ]), .DO12 (m_DO[12 ]), .DO13 (m_DO[13 ]), .DO14 (m_DO[14 ]), .DO15 (m_DO[15 ]),
	.DO16 (m_DO[16 ]), .DO17 (m_DO[17 ]), .DO18 (m_DO[18 ]), .DO19 (m_DO[19 ]), .DO20 (m_DO[20 ]), .DO21 (m_DO[21 ]), .DO22 (m_DO[22 ]), .DO23 (m_DO[23 ]),
	.DO24 (m_DO[24 ]), .DO25 (m_DO[25 ]), .DO26 (m_DO[26 ]), .DO27 (m_DO[27 ]), .DO28 (m_DO[28 ]), .DO29 (m_DO[29 ]), .DO30 (m_DO[30 ]), .DO31 (m_DO[31 ]),
	.DO32 (m_DO[32 ]), .DO33 (m_DO[33 ]), .DO34 (m_DO[34 ]), .DO35 (m_DO[35 ]), .DO36 (m_DO[36 ]), .DO37 (m_DO[37 ]), .DO38 (m_DO[38 ]), .DO39 (m_DO[39 ]),
	.DO40 (m_DO[40 ]), .DO41 (m_DO[41 ]), .DO42 (m_DO[42 ]), .DO43 (m_DO[43 ]), .DO44 (m_DO[44 ]), .DO45 (m_DO[45 ]), .DO46 (m_DO[46 ]), .DO47 (m_DO[47 ]),
	.DO48 (m_DO[48 ]), .DO49 (m_DO[49 ]), .DO50 (m_DO[50 ]), .DO51 (m_DO[51 ]), .DO52 (m_DO[52 ]), .DO53 (m_DO[53 ]), .DO54 (m_DO[54 ]), .DO55 (m_DO[55 ]),
	.DO56 (m_DO[56 ]), .DO57 (m_DO[57 ]), .DO58 (m_DO[58 ]), .DO59 (m_DO[59 ]), .DO60 (m_DO[60 ]), .DO61 (m_DO[61 ]), .DO62 (m_DO[62 ]), .DO63 (m_DO[63 ]),
	.DO64 (m_DO[64 ]), .DO65 (m_DO[65 ]), .DO66 (m_DO[66 ]), .DO67 (m_DO[67 ]), .DO68 (m_DO[68 ]), .DO69 (m_DO[69 ]), .DO70 (m_DO[70 ]), .DO71 (m_DO[71 ]),
	.DO72 (m_DO[72 ]), .DO73 (m_DO[73 ]), .DO74 (m_DO[74 ]), .DO75 (m_DO[75 ]), .DO76 (m_DO[76 ]), .DO77 (m_DO[77 ]), .DO78 (m_DO[78 ]), .DO79 (m_DO[79 ]),
	.DO80 (m_DO[80 ]), .DO81 (m_DO[81 ]), .DO82 (m_DO[82 ]), .DO83 (m_DO[83 ]), .DO84 (m_DO[84 ]), .DO85 (m_DO[85 ]), .DO86 (m_DO[86 ]), .DO87 (m_DO[87 ]),
	.DO88 (m_DO[88 ]), .DO89 (m_DO[89 ]), .DO90 (m_DO[90 ]), .DO91 (m_DO[91 ]), .DO92 (m_DO[92 ]), .DO93 (m_DO[93 ]), .DO94 (m_DO[94 ]), .DO95 (m_DO[95 ]),
	.DO96 (m_DO[96 ]), .DO97 (m_DO[97 ]), .DO98 (m_DO[98 ]), .DO99 (m_DO[99 ]), .DO100(m_DO[100]), .DO101(m_DO[101]), .DO102(m_DO[102]), .DO103(m_DO[103]),
	.DO104(m_DO[104]), .DO105(m_DO[105]), .DO106(m_DO[106]), .DO107(m_DO[107]), .DO108(m_DO[108]), .DO109(m_DO[109]), .DO110(m_DO[110]), .DO111(m_DO[111]),
	.DO112(m_DO[112]), .DO113(m_DO[113]), .DO114(m_DO[114]), .DO115(m_DO[115]), .DO116(m_DO[116]), .DO117(m_DO[117]), .DO118(m_DO[118]), .DO119(m_DO[119]),
	.DO120(m_DO[120]), .DO121(m_DO[121]), .DO122(m_DO[122]), .DO123(m_DO[123]), .DO124(m_DO[124]), .DO125(m_DO[125]), .DO126(m_DO[126]), .DO127(m_DO[127]),

	.CK(clk), .WEB(m_WEB), .OE(1'b1), .CS(1'b1));

endmodule

// Cycle: 7.20
// Area: 2498452.191412
// Gate count: 250366
