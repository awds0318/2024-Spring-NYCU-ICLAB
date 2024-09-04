//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : HT_TOP.v
//   	Module Name : HT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "SORT_IP.v"
//synopsys translate_on

module HT_TOP(
           // Input signals
           clk,
           rst_n,
           in_valid,
           in_weight,
           out_mode,
           // Output signals
           out_valid,
           out_code
       );

//---------------------------------------------------------------------
//   Input & Output Declaration
//---------------------------------------------------------------------
input            clk, rst_n, in_valid, out_mode;
input      [2:0] in_weight;

output reg       out_valid, out_code;

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
localparam IDLE = 0;
localparam IN   = 1;
localparam CAL  = 2;
localparam OUT1 = 3;
localparam OUT2 = 4;
localparam OUT3 = 5;
localparam OUT4 = 6;
localparam OUT5 = 7;
reg [2:0] cs, ns;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
integer i, j;

reg       mode_reg, valid_delay;

reg [3:0] new_c;  
reg [3:0] store_c [0:7];
reg [7:0] code    [0:7]; // huffman code
reg [3:0] cnt     [0:7];
//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) cs <= IDLE;
    else       cs <= ns;
end

always @(posedge clk) valid_delay <= in_valid;
always @(posedge clk) mode_reg    <= (in_valid && !valid_delay)? out_mode : mode_reg;
always @(posedge clk) new_c       <= (cs == CAL)? new_c + 1 : 8;                        // assume the combine weight's character is 8

always @(*) 
begin
    case (cs)
        IDLE: ns = (in_valid)? IN : IDLE;
        IN:   ns = (!in_valid)? CAL : IN;
        CAL:  ns = (new_c == 14)? OUT1 : CAL;
        OUT1: ns = (cnt[3] == 1)? OUT2 : OUT1;
        OUT2: ns = (!mode_reg)? ((cnt[2] == 1)? OUT3 : OUT2) : ((cnt[5] == 1)? OUT3 : OUT2);
        OUT3: ns = (!mode_reg)? ((cnt[1] == 1)? OUT4 : OUT3) : ((cnt[2] == 1)? OUT4 : OUT3);
        OUT4: ns = (!mode_reg)? ((cnt[0] == 1)? OUT5 : OUT4) : ((cnt[7] == 1)? OUT5 : OUT4);
        OUT5: ns = (!mode_reg)? ((cnt[4] == 1)? IDLE : OUT5) : ((cnt[6] == 1)? IDLE : OUT5);
        default: ns = IDLE;
    endcase
end

wire [39:0] IN_weight, OUT_weight;
wire [31:0] IN_character, OUT_character;

reg  [4:0] w   [0:7];
wire [4:0] w_r [0:7]; // weight in combinational (after sorting)
reg  [3:0] c   [0:7];
wire [3:0] c_r [0:7]; // character in combinational (after sorting)

assign IN_weight    = {w[7], w[6], w[5], w[4], w[3], w[2], w[1], w[0]};
assign IN_character = {c[7], c[6], c[5], c[4], c[3], c[2], c[1], c[0]};

assign {w_r[7], w_r[6], w_r[5], w_r[4], w_r[3], w_r[2], w_r[1], w_r[0]} = OUT_weight;
assign {c_r[7], c_r[6], c_r[5], c_r[4], c_r[3], c_r[2], c_r[1], c_r[0]} = OUT_character;

SORT_IP #(.IP_WIDTH(8)) u_SORT_IP(.IN_character(IN_character), .IN_weight(IN_weight), .OUT_character(OUT_character), .OUT_weight(OUT_weight));

// In spec, if A and I have same weight, after sorting, A should still be larger. 
// As a result, we need to store first input(A) in w[0], then shift.
// Moveover, when output A's huffman code, we need to output code[7], not code[0]
// w{0, 1, 2, 3, 4, 5, 6, 7} = {V, O, L, I, E, C, B, A}

always @(posedge clk) 
begin
    if(in_valid)
    begin
        w[1:7] <= w[0:6];
        w[0] <= in_weight; 
    end
    else if(cs == CAL) 
    begin
        w[7] <= w_r[7];    
        w[6] <= w_r[6];
        w[5] <= w_r[5];
        w[4] <= w_r[4];
        w[3] <= w_r[3];
        w[2] <= w_r[2];
        w[1] <= w_r[0] + w_r[1];
        w[0] <= 31;   // 5'b1_1111  
    end
end

always @(posedge clk) 
begin
    if(cs == IDLE)
    begin
        c[7] <= 7;
        c[6] <= 6;
        c[5] <= 5;
        c[4] <= 4;
        c[3] <= 3;
        c[2] <= 2;
        c[1] <= 1;
        c[0] <= 0;
    end
    else if(cs == CAL) 
    begin
        c[7] <= c_r[7];     
        c[6] <= c_r[6];
        c[5] <= c_r[5];
        c[4] <= c_r[4];
        c[3] <= c_r[3];
        c[2] <= c_r[2];
        c[1] <= new_c;
        c[0] <= 15;  // 4'b1111
    end
end

// ----------------------------------------- character ----------------------------------------- //
// store character
// We must store the character which will combine after sorting
always @(posedge clk) 
begin
    if(cs == IDLE) 
    begin
        store_c[7] <= 7; 
        store_c[6] <= 6; 
        store_c[5] <= 5; 
        store_c[4] <= 4; 
        store_c[3] <= 3; 
        store_c[2] <= 2; 
        store_c[1] <= 1; 
        store_c[0] <= 0; 
    end
    else if(cs == CAL) 
    begin
        for(i=0;i<8;i=i+1) 
            store_c[i] <= (store_c[i] == c_r[0] || store_c[i] == c_r[1])? new_c : store_c[i]; // change the combine character to new_c
    end
end

// ------------------------------------------- code -------------------------------------------- //
// store huffman code
// c_r[0] is the smallest value, store its huffman code to 1
// Some value may have been combined, so we need to confirm that we have stored its huffman code to correct space
always @(posedge clk) 
begin
    case (cs)
        IDLE:
        begin
            for(i=0;i<8;i=i+1) 
                code[i] <= 0; 
        end
        CAL:
        begin
            for(i=0;i<8;i=i+1) 
            begin
                for(j=0;j<8;j=j+1) 
                    code[i][j] <= (store_c[i] == c_r[0] && cnt[i] == j)? 1 : code[i][j];
            end
        end
    endcase
end

// ----------------------------------------- counter ------------------------------------------- //
// store cnt
// If the characters have been combined, its huffman code will add one bit
// As a result, we calculate its have been added how many times
always @(posedge clk) 
begin
    case (cs)
        IDLE:
        begin
            for(i=0;i<8;i=i+1) 
                cnt[i] <= 0; 
        end
        CAL:
        begin
            for(i=0;i<8;i=i+1) 
                cnt[i] <= (store_c[i] == c_r[0] || store_c[i] == c_r[1])? cnt[i] + 1 : cnt[i];
        end
        OUT1: cnt[3] <= cnt[3] - 1;
        OUT2:
        begin
            if(!mode_reg) cnt[2] <= cnt[2] - 1;
            else          cnt[5] <= cnt[5] - 1;
        end
        OUT3:
        begin
            if(!mode_reg) cnt[1] <= cnt[1] - 1;
            else          cnt[2] <= cnt[2] - 1;   
        end
        OUT4:
        begin
            if(!mode_reg) cnt[0] <= cnt[0] - 1;
            else          cnt[7] <= cnt[7] - 1; 
        end
        OUT5:
        begin
            if(!mode_reg) cnt[4] <= cnt[4] - 1;
            else          cnt[6] <= cnt[6] - 1;     
        end
    endcase
end


// ------------------------------------------ Output ------------------------------------------- //

// always @(posedge clk or negedge rst_n) 
// begin
//     if(!rst_n)
//         out_valid <= 0;
//     else
//         out_valid <= (cs != IDLE && cs != IN && cs != CAL)? 1 : 0;
// end

// always @(posedge clk or negedge rst_n) 
// begin
//     if(!rst_n)
//     begin
//         out_code <= 0;
//     end
//     else
//     begin
//         case (cs)
//             OUT1: out_code <= code[3][cnt[3] - 1];
//             OUT2: out_code <= (!mode_reg)? code[2][cnt[2] - 1] : code[5][cnt[5] - 1];
//             OUT3: out_code <= (!mode_reg)? code[1][cnt[1] - 1] : code[2][cnt[2] - 1];
//             OUT4: out_code <= (!mode_reg)? code[0][cnt[0] - 1] : code[7][cnt[7] - 1];
//             OUT5: out_code <= (!mode_reg)? code[4][cnt[4] - 1] : code[6][cnt[6] - 1];
//             default: out_code <= 0;
//         endcase
//     end
// end

always @(*) out_valid = (cs != IDLE && cs != IN && cs != CAL)? 1 : 0;

always @(*) 
begin
    case (cs)
        OUT1: out_code = code[3][cnt[3] - 1];
        OUT2: out_code = (!mode_reg)? code[2][cnt[2] - 1] : code[5][cnt[5] - 1];
        OUT3: out_code = (!mode_reg)? code[1][cnt[1] - 1] : code[2][cnt[2] - 1];
        OUT4: out_code = (!mode_reg)? code[0][cnt[0] - 1] : code[7][cnt[7] - 1];
        OUT5: out_code = (!mode_reg)? code[4][cnt[4] - 1] : code[6][cnt[6] - 1];
        default: out_code = 0;
    endcase
end
endmodule

// Cycle: 5.10
// Area: 53443.454536
// Gate count: 5355
