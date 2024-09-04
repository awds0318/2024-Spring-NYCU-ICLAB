module CAD(
           // input signals
           clk,
           rst_n,
           in_valid,
           in_valid2,
           mode,
           matrix_size,
           matrix,
           matrix_idx,
           // output signals
           out_valid,
           out_value
       );

input       clk;
input       rst_n;
input       mode;
input       in_valid;
input       in_valid2;
input [7:0] matrix;
input [3:0] matrix_idx;
input [1:0] matrix_size;

output reg  out_valid;
output reg  out_value;

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
localparam IDLE   = 0;
localparam STORE  = 1;
localparam IN_2   = 2;   // in_valid_2
localparam READ   = 3;   // reading from SRAM
localparam CNN    = 4;   // CNN
localparam MP     = 5;   // Max Pooling
localparam PAD    = 6;
localparam DECNN  = 7;   // Deconvolution
localparam WAIT   = 8;   // Wait the value be stable
localparam OUTPUT = 9;
reg [3:0]  cs, ns;

//  8 x 8  ---CNN-->  4 x 4  ---MP-->  2 x 2
// 16 x 16 ---CNN--> 12 x 12 ---MP-->  6 x 6
// 32 x 32 ---CNN--> 28 x 28 ---MP--> 14 x 14


// https://www.youtube.com/watch?v=EOX-xFLZzJg
// for 5 x 5 kernel to deconvolution, we need to zero padding 4 stages and multiply with the reverse kernel
//  8 x 8  ---padd--> 16 x 16 ---CNN--> 12 x 12
// 16 x 16 ---padd--> 24 x 24 ---CNN--> 20 x 20
// 32 x 32 ---padd--> 40 x 40 ---CNN--> 36 x 36

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
integer a, b;
genvar  c;

reg [14:0] cnt;
reg [8:0]  k_cnt;          // for storing kernel 2^9 = 512 (need 400)
reg [4:0]  out_20_cnt;     // for output 20 cycle

wire       k_web;          // signal to control SRAM
reg        i_web, a_web;   // signal to control SRAM

reg        mode_reg;
reg        valid1_delay, valid2_delay;
reg [1:0]  matrix_size_reg;
reg [3:0]  img_index, kernel_index;
reg [19:0] ans_r;
reg [10:0] A_A;

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

// counter
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        k_cnt      <= 0;
        out_20_cnt <= 0;
    end
    else
    begin
        k_cnt      <= (i_web)? k_cnt + 1 : 0;
        out_20_cnt <= (cs == OUTPUT)? ((out_20_cnt == 19)? 0 : out_20_cnt + 1) : 0;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n) cnt <= 0;
    else
    begin
        if(cs == IDLE)        cnt <= 0;
        else if(cs == OUTPUT) cnt <= (out_20_cnt == 19)? cnt + 1 : cnt;
        else if(cs == ns)     cnt <= cnt + 1;
        else                  cnt <= 0;
    end
end

// delay valid for storing first or second cycle's value
always @(posedge clk) 
begin
    valid1_delay <= in_valid;
    valid2_delay <= in_valid2;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        mode_reg        <= 0;
        img_index       <= 0;
        kernel_index    <= 0;
        matrix_size_reg <= 0;
    end
    else
    begin
        mode_reg        <= (in_valid2 && !valid2_delay)? mode : mode_reg;
        img_index       <= (in_valid2 && !valid2_delay)? matrix_idx : img_index;
        kernel_index    <= (in_valid2 &&  valid2_delay)? matrix_idx : kernel_index;
        matrix_size_reg <= (in_valid  && !valid1_delay)? matrix_size : matrix_size_reg;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) cs <= IDLE;
    else       cs <= ns;
end

always @(*)
begin
    ns = IDLE; // write default to the top, else it will have latch in this always block
    case (cs)
        IDLE:  ns = (in_valid)?  STORE : ((in_valid2)? IN_2 : IDLE);
        STORE: ns = (!in_valid)?  IDLE : STORE;
        IN_2:  ns = (!in_valid2)? READ : IN_2;
        READ:
        begin
            case ({matrix_size_reg})
                0: ns = (cnt[6]  == 1)? ((mode_reg)? PAD : CNN) : READ; //  8 x 8 = 64
                1: ns = (cnt[8]  == 1)? ((mode_reg)? PAD : CNN) : READ; // 16 x 16 = 256
                2: ns = (cnt[10] == 1)? ((mode_reg)? PAD : CNN) : READ; // 32 x 32 = 1024
            endcase
        end
        CNN:
        begin
            case ({matrix_size_reg})
                0: ns = (cnt == 18)?  MP : CNN;  // SRAM delay (1 cycle) + CNN (2 cycle) + get all need value --> 3 + 16 cycle
                1: ns = (cnt == 146)? MP : CNN;  // 3 + 144
                2: ns = (cnt == 786)? MP : CNN;  // 3 + 784
            endcase
        end
        MP:   ns = (cnt == 5)? OUTPUT : MP;
        PAD:  ns = DECNN;
        DECNN:
        begin
            case ({matrix_size_reg})
                0: ns = (cnt == 145)?  WAIT : DECNN;   //  8 + 5 - 1 = 12 (before DECNN, I do padding, so 3 + 144 - 1 cycle )
                1: ns = (cnt == 401)?  WAIT : DECNN;   // 16 + 5 - 1 = 20
                2: ns = (cnt == 1297)? WAIT : DECNN;   // 32 + 5 - 1 = 36
            endcase
        end
        WAIT: ns = (cnt == 1)? OUTPUT : WAIT;
        OUTPUT:
        begin
            if(out_20_cnt == 19)
            begin
                case (mode_reg)
                    0:
                    begin
                        case ({matrix_size_reg})
                            0: ns = (cnt == 3)?   IDLE : OUTPUT;  //  8 x 8  -->  4 x 4  -->  2 x 2  = 4   ; 4 x 20 = 80
                            1: ns = (cnt == 35)?  IDLE : OUTPUT;  // 16 x 16 --> 12 x 12 -->  6 x 6  = 36  ; 36 x 20 = 720
                            2: ns = (cnt == 195)? IDLE : OUTPUT;  // 32 x 32 --> 28 x 28 --> 14 x 14 = 196 ; 196 x 20 = 3920
                        endcase
                    end
                    1:
                    begin
                        case ({matrix_size_reg})
                            0: ns = (cnt == 143)?  IDLE : OUTPUT;  //  8 + 5 - 1 = 12 ; 12 x 12 x 20 = 2880
                            1: ns = (cnt == 399)?  IDLE : OUTPUT;  // 16 + 5 - 1 = 20 ; 20 x 20 x 20 = 8000
                            2: ns = (cnt == 1295)? IDLE : OUTPUT;  // 32 + 5 - 1 = 36 ; 36 x 36 x 20 = 25919
                        endcase
                    end
                endcase
            end
            else
                ns = OUTPUT;
        end
    endcase
end

// ----------------------------------------- READ DATA ----------------------------------------- //
// IMAGE
reg [14:0] i_addr;             // image's addr from SRAM
reg [7:0]  img [0:39][0:39];   // the value of image in seq
reg [7:0]  img_r;              // the value of image from SRAM in comb

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        i_addr <= 0;
    else if(cs == IN_2)
    begin
        case ({matrix_size_reg})
            0: i_addr <= img_index << 6;
            1: i_addr <= img_index << 8;
            2: i_addr <= img_index << 10;
        endcase
    end
    else
        i_addr <= (cs == READ)? i_addr + 1 : 0;
end

// store image
wire [10:0] cnt_1 = (cnt == 0)? 0 : cnt - 1;

always @(posedge clk)
begin
    if(cs == IDLE)
    begin
        for(a=0;a<40;a=a+1)
        begin
            for (b=0;b<40;b=b+1)
                img[a][b] <= 0;
        end
    end
    else if(cs == READ && cnt > 0)
    begin
        case (matrix_size_reg)
            0:
            begin
                if(cnt_1[2:0] == 0) // img[cnt_1[5:3] + 4][cnt_1[2:0] + 4] <= img_r; //  8 x 8
                begin
                    for(a=0;a<7;a=a+1)
                    begin
                        img[4 + a][4:11] <= img[5 + a][4:11];
                    end
                    img[11][11]   <= img_r;
                end
                else
                begin
                    img[11][4:10] <= img[11][5:11];
                    img[11][11]   <= img_r;
                end
            end
            1: 
            begin
                if(cnt_1[3:0] == 0) // img[cnt_1[7:4] + 4][cnt_1[3:0] + 4] <= img_r; // 16 x 16
                begin
                    for(a=0;a<15;a=a+1)
                    begin
                        img[4 + a][4:19] <= img[5 + a][4:19];
                    end
                    img[19][19]   <= img_r;
                end
                else
                begin
                    img[19][4:18] <= img[19][5:19];
                    img[19][19]   <= img_r;
                end   
            end
            2:
            begin
                if(cnt_1[4:0] == 0) // img[cnt_1[9:5] + 4][cnt_1[4:0] + 4] <= img_r; // 32 x 32
                begin
                    for(a=0;a<31;a=a+1)
                    begin
                        img[4 + a][4:35] <= img[5 + a][4:35];
                    end
                    img[35][35]   <= img_r;
                end
                else
                begin
                    img[35][4:34] <= img[35][5:35];
                    img[35][35]   <= img_r;
                end                 
            end
        endcase
    end
end

// KERNEL
reg        [8:0] k_addr;    // kernel's addr
reg        [7:0] k_r;       // the value of kernel from SRAM in comb
reg signed [7:0] k [0:24];  // the value of kernel in seq

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        k_addr <= 0;
    else if(cs == IN_2)
    begin
        case (kernel_index)  // kernel_index * 25
            0:  k_addr <=   0;
            1:  k_addr <=  25;
            2:  k_addr <=  50;
            3:  k_addr <=  75;
            4:  k_addr <= 100;
            5:  k_addr <= 125;
            6:  k_addr <= 150;
            7:  k_addr <= 175;
            8:  k_addr <= 200;
            9:  k_addr <= 225;
            10: k_addr <= 250;
            11: k_addr <= 275;
            12: k_addr <= 300;
            13: k_addr <= 325;
            14: k_addr <= 350;
            15: k_addr <= 375;
        endcase
    end
    else
        k_addr <= (cs == READ)? ((k_addr == 399)? k_addr : k_addr + 1) : 0;
end

// store kernel
always @(posedge clk)
begin
    if(cs == READ && cnt > 0 && cnt < 26)
    begin
        case (mode_reg)
            0:
            begin
                k[0:23] <= k[1:24];
                k[24]   <= k_r;
            end
            1:
            begin
                k[1:24] <= k[0:23];
                k[0]    <= k_r;
            end
        endcase
    end
end

// --------------------------------------- CNN (&DECNN)---------------------------------------- //
reg [5:0] m, n;
reg [5:0] m_d1, n_d1;
reg [5:0] m_d2, n_d2;

// m & n
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        m <= 0;
        n <= 0; 
    end
    else if(cs == DECNN || cs == CNN)
    begin
        case (mode_reg)
            0:
            begin
                case ({matrix_size_reg})
                    0:
                    begin
                        m <= cnt[3:2];
                        n <= cnt[1:0];
                    end
                    1:
                    begin
                        m <= (n == 11)? m + 1 : m;
                        n <= (n == 11)? 0 : n + 1;
                    end
                    2:
                    begin
                        m <= (n == 27)? m + 1 : m;
                        n <= (n == 27)? 0 : n + 1;
                    end
                endcase
            end
            1:
            begin
                case ({matrix_size_reg})
                    0:
                    begin
                        m <= (n == 11)? m + 1 : m;
                        n <= (n == 11)? 0 : n + 1;
                    end
                    1:
                    begin
                        m <= (n == 19)? m + 1 : m;
                        n <= (n == 19)? 0 : n + 1;
                    end
                    2:
                    begin
                        m <= (n == 35)? m + 1 : m;
                        n <= (n == 35)? 0 : n + 1;
                    end
                endcase
            end
        endcase
    end
    else 
    begin
        m <= 0;
        n <= 0;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        m_d1 <= 0;
        n_d1 <= 0;
        m_d2 <= 0;
        n_d2 <= 0;
    end
    else
    begin
        m_d1 <= m;
        n_d1 <= n;
        m_d2 <= m_d1;
        n_d2 <= n_d1;
    end
end

reg signed [7:0] i [0:24];                 // for CNN
wire       [2:0] f = (!mode_reg)? 4 : 0;   // for Deconnvolution, we need padding 4 stages

always @(*)
begin
    for(a=0;a<25;a=a+1)
        i[a] = 0;

    i[ 0] = img[f +     m][f +     n];
    i[ 1] = img[f +     m][f + 1 + n];
    i[ 2] = img[f +     m][f + 2 + n];
    i[ 3] = img[f +     m][f + 3 + n];
    i[ 4] = img[f +     m][f + 4 + n];

    i[ 5] = img[f + 1 + m][f +     n];
    i[ 6] = img[f + 1 + m][f + 1 + n];
    i[ 7] = img[f + 1 + m][f + 2 + n];
    i[ 8] = img[f + 1 + m][f + 3 + n];
    i[ 9] = img[f + 1 + m][f + 4 + n];

    i[10] = img[f + 2 + m][f +     n];
    i[11] = img[f + 2 + m][f + 1 + n];
    i[12] = img[f + 2 + m][f + 2 + n];
    i[13] = img[f + 2 + m][f + 3 + n];
    i[14] = img[f + 2 + m][f + 4 + n];

    i[15] = img[f + 3 + m][f +     n];
    i[16] = img[f + 3 + m][f + 1 + n];
    i[17] = img[f + 3 + m][f + 2 + n];
    i[18] = img[f + 3 + m][f + 3 + n];
    i[19] = img[f + 3 + m][f + 4 + n];

    i[20] = img[f + 4 + m][f +     n];
    i[21] = img[f + 4 + m][f + 1 + n];
    i[22] = img[f + 4 + m][f + 2 + n];
    i[23] = img[f + 4 + m][f + 3 + n];
    i[24] = img[f + 4 + m][f + 4 + n];
end

reg signed [15:0] mul_res  [0:24];  // signed 8 bits x 8 bits = 16 bits, 15 bits will got error
reg signed [19:0] add;

generate
    for (c=0;c<25;c=c+1) 
    begin
        always @(posedge clk) mul_res[c] <= i[c] * k[c];
    end
endgenerate

always @(posedge clk) add <= mul_res[ 0] + mul_res[ 1] + mul_res[ 2] + mul_res[ 3] + mul_res[ 4]
                           + mul_res[ 5] + mul_res[ 6] + mul_res[ 7] + mul_res[ 8] + mul_res[ 9]
                           + mul_res[10] + mul_res[11] + mul_res[12] + mul_res[13] + mul_res[14]
                           + mul_res[15] + mul_res[16] + mul_res[17] + mul_res[18] + mul_res[19]
                           + mul_res[20] + mul_res[21] + mul_res[22] + mul_res[23] + mul_res[24]; 

// ---------------------------------------- Max Pooling ---------------------------------------- //

reg  signed [19:0] mp_in0, mp_in1, mp_in2, mp_in3;
wire signed [19:0] mp_out_r;

reg [5:0] r, j, index, index2;

always @(posedge clk)
begin
    if(ns == IDLE)
    begin
        r <= 0;
        j <= 0;
        index  <= 0;
        index2 <= 0;
    end
    else if(mode_reg == 0 && (cs == MP || cs == OUTPUT))
    begin
        r <= (out_20_cnt > 0 && out_20_cnt <= 13)? 0 : (j == 1)? r + 1 : r;
        j <= (out_20_cnt > 0 && out_20_cnt <= 13)? 0 : (j == 1)? 0 : j + 1;
        case (matrix_size_reg)
            0:
            begin
                index  <= (out_20_cnt == 11)? ((index == 1)? 0 : index + 1) : index;
                index2 <= (out_20_cnt == 11)? ((index == 1)? index2 + 2 : index2) : index2;
            end
            1:
            begin
                index  <= (out_20_cnt == 11)? ((index == 5)? 0 : index + 1) : index;
                index2 <= (out_20_cnt == 11)? ((index == 5)? index2 + 2 : index2) : index2;
            end
            2:
            begin
                index  <= (out_20_cnt == 11)? ((index == 13)? 0 : index + 1) : index;
                index2 <= (out_20_cnt == 11)? ((index == 13)? index2 + 2 : index2) : index2;
            end
        endcase
    end
    else if(mode_reg == 1 && (cs == WAIT || cs == OUTPUT))
    begin
        case (matrix_size_reg)
            0:
            begin
                r <= (out_20_cnt == 17)? ((j == 11)? r + 1 : r) : r;
                j <= (out_20_cnt == 17)? ((j == 11)? 0 : j + 1) : j;
            end
            1:
            begin
                r <= (out_20_cnt == 17)? ((j == 19)? r + 1 : r) : r;
                j <= (out_20_cnt == 17)? ((j == 19)? 0 : j + 1) : j;
            end
            2:
            begin
                r <= (out_20_cnt == 17)? ((j == 35)? r + 1 : r) : r;
                j <= (out_20_cnt == 17)? ((j == 35)? 0 : j + 1) : j;
            end
        endcase
    end
end

always @(posedge clk)
begin
    mp_in3 <= ans_r;
    mp_in2 <= mp_in3;
    mp_in1 <= mp_in2;
    mp_in0 <= mp_in1;
end

wire signed [19:0] temp0, temp1;

assign temp0 = (mp_in0 > mp_in1)? mp_in0 : mp_in1;
assign temp1 = (mp_in2 > mp_in3)? mp_in2 : mp_in3;

assign mp_out_r = (temp0 > temp1)? temp0 : temp1;

// ------------------------------------------ Output ------------------------------------------- //

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) out_valid <= 0;
    else       out_valid <= (cs == OUTPUT)? 1 : 0;
end

reg [19:0] out_value_r;

always @(posedge clk)
begin
    case (mode_reg)
        0: out_value_r <= (cs == MP   || out_20_cnt == 19)? mp_out_r : out_value_r;
        1: out_value_r <= (cs == WAIT || out_20_cnt == 19)?    ans_r : out_value_r;
    endcase
end

reg [19:0] out_value_comb;

always @(*) 
begin
    case (out_20_cnt)
        0:   out_value_comb = out_value_r[0];
        1:   out_value_comb = out_value_r[1];
        2:   out_value_comb = out_value_r[2];
        3:   out_value_comb = out_value_r[3];
        4:   out_value_comb = out_value_r[4];
        5:   out_value_comb = out_value_r[5];
        6:   out_value_comb = out_value_r[6];
        7:   out_value_comb = out_value_r[7];
        8:   out_value_comb = out_value_r[8];
        9:   out_value_comb = out_value_r[9];
        10:  out_value_comb = out_value_r[10];
        11:  out_value_comb = out_value_r[11];
        12:  out_value_comb = out_value_r[12];
        13:  out_value_comb = out_value_r[13];
        14:  out_value_comb = out_value_r[14];
        15:  out_value_comb = out_value_r[15];
        16:  out_value_comb = out_value_r[16];
        17:  out_value_comb = out_value_r[17];
        18:  out_value_comb = out_value_r[18];
        19:  out_value_comb = out_value_r[19];
        default: out_value_comb = 0;
    endcase
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) out_value <= 0;
    else       out_value <= (cs == OUTPUT)? out_value_comb : 0;
end

// ------------------------------------------- SRAM -------------------------------------------- //

wire [13:0] i_A;
wire [8:0]  k_A;

assign i_A = (cs == STORE)? cnt + 1 : i_addr;   // address for IMAGE  SRAM
assign k_A = (cs == STORE)?  k_cnt : k_addr;    // address for KERNEL SRAM

always @(*)
begin
    if(ns == STORE)
    begin
        case ({matrix_size_reg})
            0: i_web = (cnt > 1022)?  1 : 0;  // in_cnt > 1023
            1: i_web = (cnt > 4094)?  1 : 0;
            2: i_web = (cnt > 16382)? 1 : 0;
            default: i_web = 1;
        endcase
    end
    else i_web = 1;
end

assign k_web = (ns == STORE)? ~i_web : 1;

always @(*)
begin
    a_web = 1;
    case (mode_reg)
        0: a_web = (cs == CNN)?   0 : 1;
        1: a_web = (cs == DECNN)? 0 : 1;
    endcase
end

always @(*)
begin
    A_A = 0;
    case (mode_reg)
        0:
        begin
            case ({matrix_size_reg})
                0: A_A = (cs == MP || cs == OUTPUT)? (((r + index2) << 2) + j + (index << 1)) : (m_d2 << 2) + n_d2;
                1: A_A = (cs == MP || cs == OUTPUT)?  ((r + index2) * 12  + j + (index << 1)) : (m_d2 * 12) + n_d2;
                2: A_A = (cs == MP || cs == OUTPUT)?  ((r + index2) * 28  + j + (index << 1)) : (m_d2 * 28) + n_d2;
            endcase
        end
        1:
        begin
            case ({matrix_size_reg})
                0: A_A = (cs == WAIT || cs == OUTPUT)? (r * 12 + j) : (m_d2 * 12) + n_d2;
                1: A_A = (cs == WAIT || cs == OUTPUT)? (r * 20 + j) : (m_d2 * 20) + n_d2;
                2: A_A = (cs == WAIT || cs == OUTPUT)? (r * 36 + j) : (m_d2 * 36) + n_d2;
            endcase
        end
    endcase
end

IMAGE u_IMAGE( .A0(i_A[0]), .A1(i_A[1]), .A2(i_A[2]), .A3(i_A[3]), .A4(i_A[4]), .A5(i_A[5]), .A6(i_A[6]), .A7(i_A[7]), .A8(i_A[8]), .A9(i_A[9]),  .A10(i_A[10]),  .A11(i_A[11]), .A12(i_A[12]), .A13(i_A[13]),
               .DO0(img_r[0]), .DO1(img_r[1]), .DO2(img_r[2]), .DO3(img_r[3]), .DO4(img_r[4]), .DO5(img_r[5]), .DO6(img_r[6]), .DO7(img_r[7]),
               .DI0(matrix[0]), .DI1(matrix[1]), .DI2(matrix[2]), .DI3(matrix[3]), .DI4(matrix[4]), .DI5(matrix[5]), .DI6(matrix[6]), .DI7(matrix[7]),
               .CK(clk), .WEB(i_web),  .OE(1'b1),  .CS(1'b1));

KERNEL u_KERNEL( .A0(k_A[0]), .A1(k_A[1]), .A2(k_A[2]), .A3(k_A[3]), .A4(k_A[4]), .A5(k_A[5]), .A6(k_A[6]), .A7(k_A[7]), .A8(k_A[8]),
                 .DO0(k_r[0]), .DO1(k_r[1]), .DO2(k_r[2]), .DO3(k_r[3]), .DO4(k_r[4]), .DO5(k_r[5]), .DO6(k_r[6]), .DO7(k_r[7]),
                 .DI0(matrix[0]), .DI1(matrix[1]), .DI2(matrix[2]), .DI3(matrix[3]), .DI4(matrix[4]), .DI5(matrix[5]), .DI6(matrix[6]), .DI7(matrix[7]),
                 .CK(clk), .WEB(k_web),  .OE(1'b1),  .CS(1'b1));

ANS u_ANS( .A0(A_A[0]), .A1(A_A[1]), .A2(A_A[2]), .A3(A_A[3]), .A4(A_A[4]), .A5(A_A[5]), .A6(A_A[6]), .A7(A_A[7]), .A8(A_A[8]), .A9(A_A[9]), .A10(A_A[10]),
           .DO0(ans_r[0]), .DO1(ans_r[1]), .DO2(ans_r[2]), .DO3(ans_r[3]), .DO4(ans_r[4]), .DO5(ans_r[5]), .DO6(ans_r[6]), .DO7(ans_r[7]), .DO8(ans_r[8]), .DO9(ans_r[9]),
           .DO10(ans_r[10]), .DO11(ans_r[11]), .DO12(ans_r[12]), .DO13(ans_r[13]), .DO14(ans_r[14]), .DO15(ans_r[15]), .DO16(ans_r[16]), .DO17(ans_r[17]), .DO18(ans_r[18]), .DO19(ans_r[19]),
           .DI0(add[0]), .DI1(add[1]), .DI2(add[2]), .DI3(add[3]), .DI4(add[4]), .DI5(add[5]), .DI6(add[6]), .DI7(add[7]), .DI8(add[8]), .DI9(add[9]),
           .DI10(add[10]), .DI11(add[11]), .DI12(add[12]), .DI13(add[13]), .DI14(add[14]), .DI15(add[15]), .DI16(add[16]), .DI17(add[17]), .DI18(add[18]), .DI19(add[19]),
           .CK(clk), .WEB(a_web),  .OE(1'b1),  .CS(1'b1));

endmodule

// Cycle: 20.00
// Area: 2510945.342007
// Gate count: 251618