module SNN(
	// Input signals
	clk,
	rst_n,
	in_valid,
	img,
	ker,
	weight,
	// Output signals
	out_valid,
	out_data
);

//---------------------------------------------------------------------
//   Input & Output Declaration
//---------------------------------------------------------------------	
input       clk;
input       rst_n;
input       in_valid;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg       out_valid;
output reg [9:0] out_data;

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
localparam IDLE      = 0;
localparam INPUT     = 1;
localparam CONV1     = 2;
localparam CONV2     = 3;
localparam WAIT1     = 4;  // after calculate conv result, next cycle will do quan, as a result we need one more cycle to quan
localparam MPFC      = 5;  // Max pooling + Fully connect
localparam WAIT2     = 6;
localparam WAIT_IMG  = 7;
localparam OUTPUT    = 8;
reg [3:0] cs, ns;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
genvar  a;
integer i, j;

reg [3:0] cnt;
reg [6:0] in_cnt;                 // in_valid 72 cycles

reg [7:0] img_reg    [0:5][0:5];
reg [7:0] ker_reg    [0:8];
reg [7:0] weight_reg [0:3];

reg       output_flag;

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

// ------------------------------------------ counter ----------------------------------------- //

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) in_cnt <= 0;
    else       in_cnt <= (cs == OUTPUT)? 0 : (in_valid && in_cnt != 72)? in_cnt + 1 : in_cnt;
end

always @(posedge clk or negedge rst_n) cnt <= (!rst_n)? 0 : ((cs == ns)? cnt + 1 : 0);

// -------------------------------------------- FSM ------------------------------------------- //
always @(posedge clk or negedge rst_n) output_flag <= (!rst_n)? 0 : ((cs == IDLE)? 0 : ((cs == CONV2)? 1 : output_flag));

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) cs <= IDLE;
    else       cs <= ns;
end

always @(*)
begin
    case (cs)
        IDLE:     ns = (in_valid)? INPUT : IDLE;
        INPUT:    ns = (in_cnt == 21)? CONV1 : INPUT;
        CONV1:    ns = (cnt == 15)? WAIT1 : CONV1;
        WAIT1:    ns = (cnt == 0)? MPFC : WAIT1;
        MPFC:     ns = (cnt == 5)? WAIT2 : MPFC;
		WAIT2:    ns = (output_flag)? OUTPUT : WAIT_IMG;
		WAIT_IMG: ns = (cnt == 10)? CONV2 : WAIT_IMG;
		CONV2:    ns = (cnt == 15)? WAIT1 : CONV2;
        OUTPUT:   ns = IDLE;
        default:  ns = cs;
    endcase
end

// ---------------------------------------- Store Input ---------------------------------------- //
// Use mux to store input data, instead of using shift register will result in Extra area, but save power.

// Store Img1
// generate
//     for(a=0;a<36;a=a+1) always @(posedge CG_input_clk[a]) if(in_cnt == a) img1_reg[a / 6][a % 6] <= img;
// endgenerate

// Store Img2
// generate
//     for(a=36;a<72;a=a+1) always @(posedge CG_input_clk[a]) if(in_cnt == a) img2_reg[(a - 36) / 6][(a - 36) % 6] <= img;
// endgenerate

always @(posedge clk) if(in_cnt ==  0 || in_cnt == 36) img_reg[0][0] <= img;
always @(posedge clk) if(in_cnt ==  1 || in_cnt == 37) img_reg[0][1] <= img;
always @(posedge clk) if(in_cnt ==  2 || in_cnt == 38) img_reg[0][2] <= img;
always @(posedge clk) if(in_cnt ==  3 || in_cnt == 39) img_reg[0][3] <= img;
always @(posedge clk) if(in_cnt ==  4 || in_cnt == 40) img_reg[0][4] <= img;
always @(posedge clk) if(in_cnt ==  5 || in_cnt == 41) img_reg[0][5] <= img;
always @(posedge clk) if(in_cnt ==  6 || in_cnt == 42) img_reg[1][0] <= img;
always @(posedge clk) if(in_cnt ==  7 || in_cnt == 43) img_reg[1][1] <= img;
always @(posedge clk) if(in_cnt ==  8 || in_cnt == 44) img_reg[1][2] <= img;
always @(posedge clk) if(in_cnt ==  9 || in_cnt == 45) img_reg[1][3] <= img;
always @(posedge clk) if(in_cnt == 10 || in_cnt == 46) img_reg[1][4] <= img;
always @(posedge clk) if(in_cnt == 11 || in_cnt == 47) img_reg[1][5] <= img;
always @(posedge clk) if(in_cnt == 12 || in_cnt == 48) img_reg[2][0] <= img;
always @(posedge clk) if(in_cnt == 13 || in_cnt == 49) img_reg[2][1] <= img;
always @(posedge clk) if(in_cnt == 14 || in_cnt == 50) img_reg[2][2] <= img;
always @(posedge clk) if(in_cnt == 15 || in_cnt == 51) img_reg[2][3] <= img;
always @(posedge clk) if(in_cnt == 16 || in_cnt == 52) img_reg[2][4] <= img;
always @(posedge clk) if(in_cnt == 17 || in_cnt == 53) img_reg[2][5] <= img;
always @(posedge clk) if(in_cnt == 18 || in_cnt == 54) img_reg[3][0] <= img;
always @(posedge clk) if(in_cnt == 19 || in_cnt == 55) img_reg[3][1] <= img;
always @(posedge clk) if(in_cnt == 20 || in_cnt == 56) img_reg[3][2] <= img;
always @(posedge clk) if(in_cnt == 21 || in_cnt == 57) img_reg[3][3] <= img;
always @(posedge clk) if(in_cnt == 22 || in_cnt == 58) img_reg[3][4] <= img;
always @(posedge clk) if(in_cnt == 23 || in_cnt == 59) img_reg[3][5] <= img;
always @(posedge clk) if(in_cnt == 24 || in_cnt == 60) img_reg[4][0] <= img;
always @(posedge clk) if(in_cnt == 25 || in_cnt == 61) img_reg[4][1] <= img;
always @(posedge clk) if(in_cnt == 26 || in_cnt == 62) img_reg[4][2] <= img;
always @(posedge clk) if(in_cnt == 27 || in_cnt == 63) img_reg[4][3] <= img;
always @(posedge clk) if(in_cnt == 28 || in_cnt == 64) img_reg[4][4] <= img;
always @(posedge clk) if(in_cnt == 29 || in_cnt == 65) img_reg[4][5] <= img;
always @(posedge clk) if(in_cnt == 30 || in_cnt == 66) img_reg[5][0] <= img;
always @(posedge clk) if(in_cnt == 31 || in_cnt == 67) img_reg[5][1] <= img;
always @(posedge clk) if(in_cnt == 32 || in_cnt == 68) img_reg[5][2] <= img;
always @(posedge clk) if(in_cnt == 33 || in_cnt == 69) img_reg[5][3] <= img;
always @(posedge clk) if(in_cnt == 34 || in_cnt == 70) img_reg[5][4] <= img;
always @(posedge clk) if(in_cnt == 35 || in_cnt == 71) img_reg[5][5] <= img;

// Store kernel
generate
	for(a=0;a<9;a=a+1) always @(posedge clk) if(in_cnt == a) ker_reg[a] <= ker;       
endgenerate

// Store weight
generate
	for(a=0;a<4;a=a+1) always @(posedge clk) if(in_cnt == a) weight_reg[a] <= weight; 
endgenerate

// ---------------------------------------- Convolution ----------------------------------------- //
// 2 cycles

reg [7:0] mul_reg [0:8];

wire [1:0] m, n;
reg  [1:0] m_d1, n_d1;  // delay 1 cycle

assign m = cnt[3:2];
assign n = cnt[1:0];

always @(posedge clk) if(cs == CONV1 || cs == CONV2) m_d1 <= m;
always @(posedge clk) if(cs == CONV1 || cs == CONV2) n_d1 <= n;

always @(*)
begin
    mul_reg[0] = img_reg[m    ][n    ];
    mul_reg[1] = img_reg[m    ][n + 1];
    mul_reg[2] = img_reg[m    ][n + 2];
    mul_reg[3] = img_reg[m + 1][n    ];
    mul_reg[4] = img_reg[m + 1][n + 1];
    mul_reg[5] = img_reg[m + 1][n + 2];
    mul_reg[6] = img_reg[m + 2][n    ];
    mul_reg[7] = img_reg[m + 2][n + 1];
    mul_reg[8] = img_reg[m + 2][n + 2];
end

reg  [19:0] temp;
reg  [7:0]  Feature_Map [0:3][0:3];

// cycle 1: mult & add
always @(posedge clk) if(cs == CONV1 || cs == CONV2) temp <= mul_reg[0] * ker_reg[0] + mul_reg[1] * ker_reg[1] + mul_reg[2] * ker_reg[2] 
                                                           + mul_reg[3] * ker_reg[3] + mul_reg[4] * ker_reg[4] + mul_reg[5] * ker_reg[5] 
                                                           + mul_reg[6] * ker_reg[6] + mul_reg[7] * ker_reg[7] + mul_reg[8] * ker_reg[8];

// cycle 2: put into feature map
always @(posedge clk)
begin
    if(ns == IDLE)
    begin
        for(i=0;i<4;i=i+1)
        begin
            for(j=0;j<4;j=j+1)
                Feature_Map[i][j] <= 0;
        end
    end
    else if(cs == CONV1 || cs == CONV2 || cs == WAIT1) Feature_Map[m_d1][n_d1] <= temp / 12'd2295;
end

// -------------------------------- Max Pooling + Fully Connect --------------------------------- //

reg  [7:0] M0_in0, M0_in1, M1_in0, M1_in1;
wire [7:0] M0_temp, M1_temp;
wire [7:0] mp_out;

always @(*)
begin
    case (cnt)
        0:
        begin
            M0_in0 = Feature_Map[0][0];
            M0_in1 = Feature_Map[0][1];
            M1_in0 = Feature_Map[1][0];
            M1_in1 = Feature_Map[1][1];
        end
        1:
        begin
            M0_in0 = Feature_Map[0][2];
            M0_in1 = Feature_Map[0][3];
            M1_in0 = Feature_Map[1][2];
            M1_in1 = Feature_Map[1][3];
        end
        2:
        begin
            M0_in0 = Feature_Map[2][0];
            M0_in1 = Feature_Map[2][1];
            M1_in0 = Feature_Map[3][0];
            M1_in1 = Feature_Map[3][1];
        end
        3:
        begin
            M0_in0 = Feature_Map[2][2];
            M0_in1 = Feature_Map[2][3];
            M1_in0 = Feature_Map[3][2];
            M1_in1 = Feature_Map[3][3];
        end
        default:
        begin
            M0_in0 = 0;
            M0_in1 = 0;
            M1_in0 = 0;
            M1_in1 = 0;
        end
    endcase
end

reg  [7:0]  F0_in, F1_in;
wire [15:0] F0_out_r, F1_out_r;

always @(*)
begin
    case (cnt)
        0, 2:
        begin
            F0_in = weight_reg[0];
            F1_in = weight_reg[1];
        end
        1, 3:
        begin
            F0_in = weight_reg[2];
            F1_in = weight_reg[3];
        end
        default:
        begin
            F0_in = 0;
            F1_in = 0;
        end
    endcase
end

reg [15:0] r0_0, r0_1, r0_2, r0_3;
reg [15:0] r1_0, r1_1, r1_2, r1_3;

assign M0_temp = (M0_in0  > M0_in1 )? M0_in0  : M0_in1;
assign M1_temp = (M1_in0  > M1_in1 )? M1_in0  : M1_in1;
assign mp_out  = (M0_temp > M1_temp)? M0_temp : M1_temp;

assign F0_out_r = mp_out * F0_in;
assign F1_out_r = mp_out * F1_in;

always @(posedge clk) if(ns == MPFC && cnt == 0) r0_0 <= F0_out_r;
always @(posedge clk) if(ns == MPFC && cnt == 0) r0_1 <= F1_out_r;
always @(posedge clk) if(ns == MPFC && cnt == 2) r0_2 <= F0_out_r;
always @(posedge clk) if(ns == MPFC && cnt == 2) r0_3 <= F1_out_r;
always @(posedge clk) if(ns == MPFC && cnt == 1) r1_0 <= F0_out_r;
always @(posedge clk) if(ns == MPFC && cnt == 1) r1_1 <= F1_out_r;
always @(posedge clk) if(ns == MPFC && cnt == 3) r1_2 <= F0_out_r;
always @(posedge clk) if(ns == MPFC && cnt == 3) r1_3 <= F1_out_r;

reg [16:0] fc_out [0:3];

always @(posedge clk) if(ns == WAIT2) fc_out[0] <= r0_0 + r1_0;
always @(posedge clk) if(ns == WAIT2) fc_out[1] <= r0_1 + r1_1;
always @(posedge clk) if(ns == WAIT2) fc_out[2] <= r0_2 + r1_2;
always @(posedge clk) if(ns == WAIT2) fc_out[3] <= r0_3 + r1_3;

// -------------------------------------- Quantization --------------------------------------- //
reg [7:0] q_in1 [0:3];
reg [7:0] q_in2 [0:3];

always @(posedge clk) for(i=0;i<4;i=i+1) if(cs == WAIT2 && !output_flag) q_in1[i] <= fc_out[i] / 9'd510;
always @(posedge clk) for(i=0;i<4;i=i+1) if(cs == WAIT2 &&  output_flag) q_in2[i] <= fc_out[i] / 9'd510;

wire [8:0] sub1 [0:3];
wire [7:0] sub2 [0:3];

assign sub1[0] = q_in1[0] - q_in2[0]; 
assign sub1[1] = q_in1[1] - q_in2[1]; 
assign sub1[2] = q_in1[2] - q_in2[2]; 
assign sub1[3] = q_in1[3] - q_in2[3]; 

assign sub2[0] = q_in2[0] - q_in1[0]; 
assign sub2[1] = q_in2[1] - q_in1[1]; 
assign sub2[2] = q_in2[2] - q_in1[2]; 
assign sub2[3] = q_in2[3] - q_in1[3]; 

wire [7:0] L1_temp [0:3];
wire [9:0] L1_distance;

assign L1_temp[0] = (sub1[0][8])? sub2[0] : sub1[0];
assign L1_temp[1] = (sub1[1][8])? sub2[1] : sub1[1];
assign L1_temp[2] = (sub1[2][8])? sub2[2] : sub1[2];
assign L1_temp[3] = (sub1[3][8])? sub2[3] : sub1[3];

assign L1_distance = L1_temp[0] + L1_temp[1] + L1_temp[2] + L1_temp[3];

// ----------------------------------------- Output ------------------------------------------ //
// always @(posedge CG_output_clk or negedge rst_n)
// begin
//     if(!rst_n) out_valid <= 0;
//     else       out_valid <= (cs == OUTPUT)? 1 : 0;
// end

// always @(posedge CG_output_clk or negedge rst_n)
// begin
//     if(!rst_n)            out_data <= 0;
//     else if(cs == OUTPUT) out_data <= (L1_distance[9:4] < 1)? 0 : L1_distance;
//     else                  out_data <= 0;
// end

always @(*) out_valid = (cs == OUTPUT)? 1 : 0;
always @(*) out_data  = (cs == OUTPUT)? ((L1_distance[9:4] < 1)? 0 : L1_distance) : 0;

endmodule

// Cycle: 15.00
// Area: 161074.067008
// Gate count: 16141
