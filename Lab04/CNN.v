//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network
//   Author     		: Cheng-Te Chang (chengdez.ee12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
           //Input Port
           clk,
           rst_n,
           in_valid,
           Img,
           Kernel,
           Weight,
           Opt,

           //Output Port
           out_valid,
           out
       );

// IEEE 754 floating point parameter
parameter inst_sig_width       = 23;
parameter inst_exp_width       = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type       = 0;
parameter inst_extra_prec      = 0;
parameter inst_arch            = 0;
parameter inst_faithful_round  = 0;

input       rst_n, clk, in_valid;
input [1:0] Opt;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
localparam IDLE      = 0;
localparam INPUT     = 1;
localparam CONV1     = 2;
localparam CONV2     = 3;
localparam CONV3     = 4;
localparam WAIT      = 5;
localparam MPFC      = 6;  // Max pooling + Fully connect
localparam NORMALIZE = 7;
localparam ACTIVATE  = 8;
localparam OUTPUT    = 9;
reg [3:0] cs, ns;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
integer i, j;

reg [3:0]  cnt;
reg [5:0]  in_cnt;  // in_valid 48 cycles
reg [3:0]  normalize_cnt;

reg [1:0]  Opt_reg;
reg [31:0] Img_reg    [0:5][0:5];  // 4x4 --> padding : 6x6
reg [31:0] Kernel_reg [0:26];
reg [31:0] Weight_reg [0:3];

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) Opt_reg <= 0;
    else       Opt_reg <= (in_valid && in_cnt == 0)? Opt : Opt_reg;
end

// counter
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        cnt           <= 0;
        in_cnt        <= 0;
        normalize_cnt <= 0;
    end
    else
    begin
        cnt           <= (cs == ns)?    cnt + 1 : 0;
        in_cnt        <= (in_valid)? in_cnt + 1 : 0;
        normalize_cnt <= (cs == NORMALIZE || ns == ACTIVATE || ns == OUTPUT)? normalize_cnt + 1 : 0;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) cs <= IDLE;
    else       cs <= ns;
end

always @(*)
begin
    case (cs)
        IDLE:      ns = (in_valid)? INPUT : IDLE;
        INPUT:     ns = (in_cnt == 8)? CONV1 : INPUT;
        CONV1:     ns = (cnt == 15)? CONV2 : CONV1;
        CONV2:     ns = (cnt == 15)? CONV3 : CONV2;
        CONV3:     ns = (cnt == 15)? WAIT : CONV3;
        WAIT:      ns = (cnt == 2)? MPFC : WAIT;
        MPFC:      ns = (cnt == 5)? NORMALIZE : MPFC;
        NORMALIZE: ns = (cnt == 2)? ((Opt_reg == 0)? OUTPUT : ACTIVATE) : NORMALIZE;
        ACTIVATE:
        begin
            case (Opt_reg)
                0:       ns = OUTPUT;
                1, 2:    ns = (cnt == 3)? OUTPUT : ACTIVATE;
                3:       ns = (cnt == 2)? OUTPUT : ACTIVATE;
                default: ns = OUTPUT;
            endcase
        end
        OUTPUT:    ns = (cnt == 3)? IDLE : OUTPUT;
        default:   ns = IDLE;
    endcase
end
// ----------------------------------------- Store Img ----------------------------------------- //

always @(posedge clk)
begin
    if(in_valid)
    begin
        case(in_cnt[3:0]) // in_cnt % 16
            0:  Img_reg[1][1] <= Img;
            1:  Img_reg[1][2] <= Img;
            2:  Img_reg[1][3] <= Img;
            3:  Img_reg[1][4] <= Img;
            4:  Img_reg[2][1] <= Img;
            5:  Img_reg[2][2] <= Img;
            6:  Img_reg[2][3] <= Img;
            7:  Img_reg[2][4] <= Img;
            8:  Img_reg[3][1] <= Img;
            9:  Img_reg[3][2] <= Img;
            10: Img_reg[3][3] <= Img;
            11: Img_reg[3][4] <= Img;
            12: Img_reg[4][1] <= Img;
            13: Img_reg[4][2] <= Img;
            14: Img_reg[4][3] <= Img;
            15: Img_reg[4][4] <= Img;
            default:
                for(i=1; i<5; i=i+1)
                begin
                    for(j=1; j<5; j=j+1)
                        Img_reg[i][j] <= 0;
                end
        endcase
    end
end

always @(posedge clk)
begin
    case (Opt_reg[1])
        0: // zero padding
        begin
            Img_reg[0][0] <= 0;
            Img_reg[0][1] <= 0;
            Img_reg[0][2] <= 0;
            Img_reg[0][3] <= 0;
            Img_reg[0][4] <= 0;
            Img_reg[0][5] <= 0;
            Img_reg[1][0] <= 0;
            Img_reg[1][5] <= 0;
            Img_reg[2][0] <= 0;
            Img_reg[2][5] <= 0;
            Img_reg[3][0] <= 0;
            Img_reg[3][5] <= 0;
            Img_reg[4][0] <= 0;
            Img_reg[4][5] <= 0;
            Img_reg[5][0] <= 0;
            Img_reg[5][1] <= 0;
            Img_reg[5][2] <= 0;
            Img_reg[5][3] <= 0;
            Img_reg[5][4] <= 0;
            Img_reg[5][5] <= 0;
        end
        1: // replication padding
        begin
            Img_reg[0][0] <= Img_reg[1][1];
            Img_reg[0][1] <= Img_reg[1][1];
            Img_reg[0][2] <= Img_reg[1][2];
            Img_reg[0][3] <= Img_reg[1][3];
            Img_reg[0][4] <= Img_reg[1][4];
            Img_reg[0][5] <= Img_reg[1][4];
            Img_reg[1][0] <= Img_reg[1][1];
            Img_reg[1][5] <= Img_reg[1][4];
            Img_reg[2][0] <= Img_reg[2][1];
            Img_reg[2][5] <= Img_reg[2][4];
            Img_reg[3][0] <= Img_reg[3][1];
            Img_reg[3][5] <= Img_reg[3][4];
            Img_reg[4][0] <= Img_reg[4][1];
            Img_reg[4][5] <= Img_reg[4][4];
            Img_reg[5][0] <= Img_reg[4][1];
            Img_reg[5][1] <= Img_reg[4][1];
            Img_reg[5][2] <= Img_reg[4][2];
            Img_reg[5][3] <= Img_reg[4][3];
            Img_reg[5][4] <= Img_reg[4][4];
            Img_reg[5][5] <= Img_reg[4][4];
        end
        default:
        begin
            Img_reg[0][0] <= 0;
            Img_reg[0][1] <= 0;
            Img_reg[0][2] <= 0;
            Img_reg[0][3] <= 0;
            Img_reg[0][4] <= 0;
            Img_reg[0][5] <= 0;
            Img_reg[1][0] <= 0;
            Img_reg[1][5] <= 0;
            Img_reg[2][0] <= 0;
            Img_reg[2][5] <= 0;
            Img_reg[3][0] <= 0;
            Img_reg[3][5] <= 0;
            Img_reg[4][0] <= 0;
            Img_reg[4][5] <= 0;
            Img_reg[5][0] <= 0;
            Img_reg[5][1] <= 0;
            Img_reg[5][2] <= 0;
            Img_reg[5][3] <= 0;
            Img_reg[5][4] <= 0;
            Img_reg[5][5] <= 0;
        end
    endcase
end

// ---------------------------------------- Store kernel ----------------------------------------- //

always @(posedge clk)
begin
    if(in_valid && in_cnt < 27)
        Kernel_reg[in_cnt] <= Kernel;
end

// ---------------------------------------- Store weight ----------------------------------------- //

always @(posedge clk)
begin
    if(in_valid && in_cnt < 4)
        Weight_reg[in_cnt] <= Weight;
end

// ---------------------------------------- Convolution ----------------------------------------- //
// 3 cycles

reg [31:0] i0, i1, i2, i3, i4, i5, i6, i7, i8;
reg [31:0] k0, k1, k2, k3, k4, k5, k6, k7, k8;

wire [1:0] m, n;
reg  [1:0] m_d1, n_d1;  // delay 1 cycle
reg  [1:0] m_d2, n_d2;  // delay 2 cycle

assign m = cnt[3:2];
assign n = cnt[1:0];

always @(posedge clk)
begin
    m_d1 <= m;
    n_d1 <= n;
    m_d2 <= m_d1;
    n_d2 <= n_d1;
end

always @(*)
begin
    case (cs)
        CONV1, CONV2, CONV3:
        begin
            i0 = Img_reg[m    ][n    ];
            i1 = Img_reg[m    ][n + 1];
            i2 = Img_reg[m    ][n + 2];
            i3 = Img_reg[m + 1][n    ];
            i4 = Img_reg[m + 1][n + 1];
            i5 = Img_reg[m + 1][n + 2];
            i6 = Img_reg[m + 2][n    ];
            i7 = Img_reg[m + 2][n + 1];
            i8 = Img_reg[m + 2][n + 2];
        end
        default:
        begin
            i0 = 0;
            i1 = 0;
            i2 = 0;
            i3 = 0;
            i4 = 0;
            i5 = 0;
            i6 = 0;
            i7 = 0;
            i8 = 0;
        end
    endcase
end

always @(*)
begin
    case (cs)
        CONV1:
        begin
            k0 = Kernel_reg[0];
            k1 = Kernel_reg[1];
            k2 = Kernel_reg[2];
            k3 = Kernel_reg[3];
            k4 = Kernel_reg[4];
            k5 = Kernel_reg[5];
            k6 = Kernel_reg[6];
            k7 = Kernel_reg[7];
            k8 = Kernel_reg[8];
        end
        CONV2:
        begin
            k0 = Kernel_reg[ 9];
            k1 = Kernel_reg[10];
            k2 = Kernel_reg[11];
            k3 = Kernel_reg[12];
            k4 = Kernel_reg[13];
            k5 = Kernel_reg[14];
            k6 = Kernel_reg[15];
            k7 = Kernel_reg[16];
            k8 = Kernel_reg[17];
        end
        CONV3:
        begin
            k0 = Kernel_reg[18];
            k1 = Kernel_reg[19];
            k2 = Kernel_reg[20];
            k3 = Kernel_reg[21];
            k4 = Kernel_reg[22];
            k5 = Kernel_reg[23];
            k6 = Kernel_reg[24];
            k7 = Kernel_reg[25];
            k8 = Kernel_reg[26];
        end
        default:
        begin
            k0 = 0;
            k1 = 0;
            k2 = 0;
            k3 = 0;
            k4 = 0;
            k5 = 0;
            k6 = 0;
            k7 = 0;
            k8 = 0;
        end
    endcase
end


reg [31:0] conv_out;

reg [31:0] c00, c01, c02, c03, c04, c05, c06, c07, c08, c09, c10, c11;
reg [31:0] c00_r, c01_r, c02_r, c03_r, c04_r, c05_r, c06_r, c07_r, c08_r, c09_r, c10_r, c11_r;
reg [31:0] t0, t1, t2, t3, t4;  // temp

reg [31:0] Feature_Map [0:3][0:3];

always @(posedge clk)
begin
    c00 <= c00_r;
    c01 <= c01_r;
    c02 <= c02_r;
    c03 <= c03_r;
    c04 <= c04_r;
    c05 <= c05_r;
    c06 <= c06_r;
    c07 <= c07_r;
    c08 <= c08_r;
    c09 <= c09_r;
    c10 <= c10_r;
    c11 <= c11_r;
end

// cycle 1: mult 1 time
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C00(.a(i0), .b(k0), .rnd(3'd0), .z(c00_r));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C01(.a(i1), .b(k1), .rnd(3'd0), .z(c01_r));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C02(.a(i2), .b(k2), .rnd(3'd0), .z(c02_r));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C03(.a(i3), .b(k3), .rnd(3'd0), .z(c03_r));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C04(.a(i4), .b(k4), .rnd(3'd0), .z(c04_r));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C05(.a(i5), .b(k5), .rnd(3'd0), .z(c05_r));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C06(.a(i6), .b(k6), .rnd(3'd0), .z(c06_r));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C07(.a(i7), .b(k7), .rnd(3'd0), .z(c07_r));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C08(.a(i8), .b(k8), .rnd(3'd0), .z(c08_r));

// cycle 2: add 2 times
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C09(.a(c00), .b(c01), .rnd(3'd0), .z(t0));
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C10(.a(c02), .b(c03), .rnd(3'd0), .z(t1));
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C11(.a(c04), .b(c05), .rnd(3'd0), .z(t2));
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C12(.a(c06), .b(c07), .rnd(3'd0), .z(c09_r));
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C13(.a(c08), .b(t0) , .rnd(3'd0), .z(c10_r));
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C14(.a(t1) , .b(t2) , .rnd(3'd0), .z(c11_r));

// cycle3: add to feature map
wire [31:0] add;
assign add = Feature_Map[m_d2][n_d2];

DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C15(.a(c09), .b(c10), .rnd(3'd0), .z(t3));
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C16(.a(c11), .b(add), .rnd(3'd0), .z(t4));
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C17(.a(t3) , .b(t4) , .rnd(3'd0), .z(conv_out));

// ---------------------------------------- Feature Map ----------------------------------------- //

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
    else
        Feature_Map[m_d2][n_d2] <= (cs == CONV1 || cs == CONV2 || cs == CONV3 || cs == WAIT)? conv_out : Feature_Map[m_d2][n_d2];
end
// -------------------------------- Max Pooling + Fully Connect --------------------------------- //

//   |  A   B  |     |  w[0]   w[1]  |     |  A * w[0] + B * w[2]     A * w[1] + B * w[3] |
//   |         |  x  |               |  =  |                                              | 
//   |  C   D  |     |  w[2]   w[3]  |     |  C * w[0] + D * w[2]     C * w[1] + D * w[3] |

// First cycle we will max pooling to get first value A, and then next cycles we can multiply it with w[0] & w[1] then store to reg (r0_0, r0_1)
// After all value multiply & sotre it, we can add it and get fully connect's output.

//           |            |            |   maxpool  |  multiply  |    add     |            
//           |            |   maxpool  |  multiply  |    add     |            |         
//           |  maxpool   |  multiply  |    add     |            |            |               
//  maxpool  |  multiply  |    add     |            |            |            |                      
// 
// 3 cycles caculate first vaule, total need 3 + 3 = 6 cycles

reg [31:0] M0_in0, M0_in1, M1_in0, M1_in1, M0_temp, M1_temp;
reg [31:0] mp_out, mp_out_r;

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

reg [31:0] F0_in, F1_in, F0_out_r, F1_out_r;

always @(*)
begin
    case (cnt)
        0:
        begin
            F0_in = 0;
            F1_in = 0;
        end
        1, 3:
        begin
            F0_in = Weight_reg[0];
            F1_in = Weight_reg[1];
        end
        2, 4:
        begin
            F0_in = Weight_reg[2];
            F1_in = Weight_reg[3];
        end
        default:
        begin
            F0_in = 0;
            F1_in = 0;
        end
    endcase
end

always @(posedge clk)
begin
    mp_out <= mp_out_r;
end

reg [31:0] r0_0, r0_1, r0_2, r0_3;
reg [31:0] r1_0, r1_1, r1_2, r1_3;

DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance) M0(.a(M0_in0) , .b(M0_in1) , .zctr(1'd0), .z1(M0_temp));  // z0: min  z1:max
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance) M1(.a(M1_in0) , .b(M1_in1) , .zctr(1'd0), .z1(M1_temp));
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance) M2(.a(M0_temp), .b(M1_temp), .zctr(1'd0), .z1(mp_out_r));

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) F0(.a(mp_out), .b(F0_in) , .rnd(3'd0), .z(F0_out_r));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) F1(.a(mp_out), .b(F1_in) , .rnd(3'd0), .z(F1_out_r));

always @(posedge clk)
begin
    r0_0 <= (cnt == 1)? F0_out_r : r0_0;
    r0_1 <= (cnt == 1)? F1_out_r : r0_1;
    r0_2 <= (cnt == 3)? F0_out_r : r0_2;
    r0_3 <= (cnt == 3)? F1_out_r : r0_3;
end

always @(posedge clk)
begin
    r1_0 <= (cnt == 2)? F0_out_r : r1_0;
    r1_1 <= (cnt == 2)? F1_out_r : r1_1;
    r1_2 <= (cnt == 4)? F0_out_r : r1_2;
    r1_3 <= (cnt == 4)? F1_out_r : r1_3;
end

reg [31:0] fc_out [0:3];

DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) F2(.a(r0_0), .b(r1_0), .rnd(3'd0), .z(fc_out[0]));
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) F3(.a(r0_1), .b(r1_1), .rnd(3'd0), .z(fc_out[1]));
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) F4(.a(r0_2), .b(r1_2), .rnd(3'd0), .z(fc_out[2]));
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) F5(.a(r0_3), .b(r1_3), .rnd(3'd0), .z(fc_out[3]));

// -------------------------------------- Normalization --------------------------------------- //
// 3 cycles
// In case of DW_fp_div's area is to large 
// Normalization & Activate will share it......

reg  [31:0] n_in [0:3];
wire [31:0] div_out;

always @(posedge clk)
begin
    for (i=0;i<4;i=i+1)
        n_in[i] <= (cs == MPFC)? fc_out[i] : n_in[i];
end

reg [31:0] n_temp0, n_temp1, n_temp2, n_temp3;
reg [31:0] max, min;
reg [31:0] max_r, min_r;

reg [31:0] up, down;
reg [31:0] up_r, down_r;

reg [31:0] N05_in;

always @(posedge clk)
begin
    max  <= max_r;
    min  <= min_r;
    up   <= up_r;
    down <= down_r;
end

always @(*)
begin
    case (normalize_cnt)
        0: N05_in = 0;
        1: N05_in = n_in[0];
        2: N05_in = n_in[1];
        3: N05_in = n_in[2];
        4: N05_in = n_in[3];
        default: N05_in = 0;
    endcase
end

// Normalization & Activate share DW_fp_div......

reg  [31:0] div_in0, div_in1;
reg  [31:0] a0, a1;         // activate's value in sequentail
reg  [31:0] a0_d1, a1_d1;
reg  [31:0] a0_r, a1_r;     // activate's value in combinal

always @(*)
begin
    case (normalize_cnt)
        0, 1:
        begin
            div_in0 = 0;
            div_in1 = 0;
        end
        2, 3, 4, 5:
        begin
            div_in0 = up;
            div_in1 = down;
        end
        6, 7, 8, 9:
        begin
            div_in0 = (Opt_reg == 1)? a1_d1 : 32'h3F800000;
            div_in1 = a0_d1;
        end
        default:
        begin
            div_in0 = 0;
            div_in1 = 0;
        end
    endcase
end

DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance)    N00(.a(n_in[0]), .b(n_in[1]), .zctr(1'd0), .z0(n_temp0), .z1(n_temp1));  // z0: min  z1:max
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance)    N01(.a(n_in[2]), .b(n_in[3]), .zctr(1'd0), .z0(n_temp2), .z1(n_temp3));
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance)    N02(.a(n_temp1), .b(n_temp3), .zctr(1'd0), .z1(max_r));
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance)    N03(.a(n_temp0), .b(n_temp2), .zctr(1'd0), .z0(min_r));

DW_fp_sub #(inst_sig_width,inst_exp_width,inst_ieee_compliance)    N04(.a(max)   , .b(min), .rnd(3'd0), .z(down_r));
DW_fp_sub #(inst_sig_width,inst_exp_width,inst_ieee_compliance)    N05(.a(N05_in), .b(min), .rnd(3'd0), .z(up_r));

DW_fp_div #(inst_sig_width,inst_exp_width,inst_ieee_compliance, 0) N09(.a(div_in0), .b(div_in1), .rnd(3'd0), .z(div_out));

// ---------------------------------------- Activate ----------------------------------------- //
// 0: ReLU  1: tanh  2: sigmoid  3: softplus

// 0 cycle: RELU
// 2 cycle: softplus
// 3 cycle: tanh, sigmoid

reg  [31:0] z;
wire [31:0] sof_out;

always @(posedge clk)
begin
    case (Opt_reg)
        0: z <= 0;
        1: z <= {div_out[31] , div_out[30:23] + 8'b1, div_out[22:0]};
        2: z <= {~div_out[31], div_out[30:0]};
        3: z <= div_out;
        default: z <= 0;
    endcase
end

reg [31:0] ex, ex_r;


always @(posedge clk)
begin
    ex    <= ex_r;
    a0    <= a0_r;
    a1    <= a1_r;
    a0_d1 <= a0;
    a1_d1 <= a1;
end

DW_fp_exp #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)    A0(.a(z) , .z(ex_r));                                    // exp(z)
DW_fp_add #(inst_sig_width,inst_exp_width,inst_ieee_compliance)               A1(.a(ex), .b(32'h3F800000), .rnd(3'd0), .z(a0_r));      // exp(z)+1
DW_fp_sub #(inst_sig_width,inst_exp_width,inst_ieee_compliance)               A2(.a(ex), .b(32'h3F800000), .rnd(3'd0), .z(a1_r));      // exp(z)-1

// assign    relu_out = (div_out[31])? 0 : div_out;
// DW_fp_div #(inst_sig_width,inst_exp_width,inst_ieee_compliance, 0)            A3(.a(a1) , .b(a0), .rnd(3'd0), .z(tanh_out));           // [exp(z)-1] / [exp(z)+1]
// DW_fp_div #(inst_sig_width,inst_exp_width,inst_ieee_compliance, 0)            A4(.a(32'h3F800000), .b(a0), .rnd(3'd0), .z(sig_out));   // 1 / [exp(z)+1]
DW_fp_ln  #(inst_sig_width,inst_exp_width,inst_ieee_compliance, 0, inst_arch) A5(.a(a0) , .z(sof_out));                                   // ln[1+exp(z)]

// ----------------------------------------- Output ------------------------------------------ //

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out_valid <= 0;
    else
        out_valid <= (ns == OUTPUT)? 1 : 0;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        out <= 0;
    else if(ns == OUTPUT)
    begin
        case (Opt_reg)
            0:       out <= (div_out[31])? 0 : div_out;
            1, 2:    out <= div_out;
            3:       out <= sof_out;
            default: out <= 0;
        endcase
    end
    else
        out <= 0;
end
endmodule

// Cycle: 29.00
// Area: 1510247.099731
// Gate count: 151339