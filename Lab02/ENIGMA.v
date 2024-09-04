//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab02 Exercise		: Enigma
//   Author     		: Yi-Xuan, Ran
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ENIGMA.v
//   Module Name : ENIGMA
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module ENIGMA(
           // Input Ports
           clk,
           rst_n,
           in_valid,
           in_valid_2,
           crypt_mode,
           code_in,

           // Output Ports
           out_code,
           out_valid
       );

//---------------------------------------------------------------------
// Input & Output Declaration
//---------------------------------------------------------------------
input            clk;         // clock input
input            rst_n;       // asynchronous reset (active low)
input            in_valid;    // code_in valid signal for rotor (level sensitive). 0/1: inactive/active
input            in_valid_2;  // code_in valid signal for code  (level sensitive). 0/1: inactive/active
input            crypt_mode;  // 0: encrypt; 1:decrypt; only valid for 1 cycle when in_valid is active

input      [5:0] code_in;	  // When in_valid   is active, then code_in is input of rotors.
// When in_valid_2 is active, then code_in is input of code words.

output reg       out_valid;   // 0: out_code is not valid; 1: out_code is valid
output reg [5:0] out_code;	  // encrypted/decrypted code word

//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
reg        mode, valid_reg, cnt;
reg  [5:0] decode_A, decode_B, crypt_word;
reg  [5:0] B_out;
wire [5:0] A_out, ans;

reg  [5:0] rotor [0:127];  // 0 ~ 63 for rotor A ; 64 ~ 127 for rotor B
integer i;
//---------------------------------------------------------------------
// Design
//---------------------------------------------------------------------

always @(posedge clk) mode <= (in_valid && cnt == 0)? crypt_mode : mode;

always @(posedge clk) valid_reg <= in_valid_2;

// counter
always@(posedge clk) cnt <= (in_valid)? 1 : 0;

// calculate ans
// always @(posedge clk) crypt_word <= (in_valid_2)? code_in : crypt_word;
always @(posedge clk) crypt_word <= (in_valid_2)? code_in : 0;

assign A_out = rotor[crypt_word];
// assign B_out = rotor[rotor[crypt_word] + 64];
assign ans = 63 - B_out;

always @(*) begin // replace B_out with using table...... 
    case (A_out)
        0:  B_out = rotor[64];
        1:  B_out = rotor[65];
        2:  B_out = rotor[66];
        3:  B_out = rotor[67];
        4:  B_out = rotor[68];
        5:  B_out = rotor[69];
        6:  B_out = rotor[70];
        7:  B_out = rotor[71];
        8:  B_out = rotor[72];
        9:  B_out = rotor[73];
        10: B_out = rotor[74];
        11: B_out = rotor[75];
        12: B_out = rotor[76];
        13: B_out = rotor[77];
        14: B_out = rotor[78];
        15: B_out = rotor[79];
        16: B_out = rotor[80];
        17: B_out = rotor[81];
        18: B_out = rotor[82];
        19: B_out = rotor[83];
        20: B_out = rotor[84];
        21: B_out = rotor[85];
        22: B_out = rotor[86];
        23: B_out = rotor[87];
        24: B_out = rotor[88];
        25: B_out = rotor[89];
        26: B_out = rotor[90];
        27: B_out = rotor[91];
        28: B_out = rotor[92];
        29: B_out = rotor[93];
        30: B_out = rotor[94];
        31: B_out = rotor[95];
        32: B_out = rotor[96];
        33: B_out = rotor[97];
        34: B_out = rotor[98];
        35: B_out = rotor[99];
        36: B_out = rotor[100];
        37: B_out = rotor[101];
        38: B_out = rotor[102];
        39: B_out = rotor[103];
        40: B_out = rotor[104];
        41: B_out = rotor[105];
        42: B_out = rotor[106];
        43: B_out = rotor[107];
        44: B_out = rotor[108];
        45: B_out = rotor[109];
        46: B_out = rotor[110];
        47: B_out = rotor[111];
        48: B_out = rotor[112];
        49: B_out = rotor[113];
        50: B_out = rotor[114];
        51: B_out = rotor[115];
        52: B_out = rotor[116];
        53: B_out = rotor[117];
        54: B_out = rotor[118];
        55: B_out = rotor[119];
        56: B_out = rotor[120];
        57: B_out = rotor[121];
        58: B_out = rotor[122];
        59: B_out = rotor[123];
        60: B_out = rotor[124];
        61: B_out = rotor[125];
        62: B_out = rotor[126];
        63: B_out = rotor[127]; 
        default: B_out = rotor[0]; 
    endcase
end

always @(*)
begin
    decode_A = 0;
    decode_B = 0;
    for (i=64;i<128;i=i+1)
    begin
        if(rotor[i] == ans) decode_B = i;
    end
    for (i=0;i<64;i=i+1)
    begin
        if(rotor[i] == decode_B) decode_A = i;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) out_code <= 0;
    else       out_code <= (valid_reg)? decode_A : 0;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) out_valid <= 0;
    else       out_valid <= valid_reg;
end

// store roter for using shift register

// roter A's shift
wire [1:0] s;
assign s = (!mode)? A_out[1:0] : decode_B[1:0];

// roter B's permutation
wire [2:0] p;
assign p = (!mode)? B_out[2:0] : ans[2:0];

always @(posedge clk)
begin
    if(in_valid)
    begin
        rotor[127] <= code_in;
        for (i=127;i>0;i=i-1) rotor[i-1] <= rotor[i];
    end
    else if(valid_reg)
    begin
        // rotor A
        for (i=0;i<61;i=i+1) rotor[i + s] <= rotor[i];

        case (s)
            0:
            begin
                rotor[61] <= rotor[61];
                rotor[62] <= rotor[62];
                rotor[63] <= rotor[63];
            end
            1:
            begin
                rotor[62] <= rotor[61];
                rotor[63] <= rotor[62];
                rotor[0]  <= rotor[63];
            end
            2:
            begin
                rotor[63] <= rotor[61];
                rotor[0]  <= rotor[62];
                rotor[1]  <= rotor[63];
            end
            3:
            begin
                rotor[0]  <= rotor[61];
                rotor[1]  <= rotor[62];
                rotor[2]  <= rotor[63];
            end
            default:
            begin
                rotor[61] <= rotor[61];
                rotor[62] <= rotor[62];
                rotor[63] <= rotor[63];
            end
        endcase
        // rotor B
        case (p)
            0:  for (i=64;i<128;i=i+1) rotor[i] <= rotor[i];
            1:
            begin
                for (i=0;i<8;i=i+1)
                begin
                    rotor[64 + (i << 3)] <= rotor[65 + (i << 3)];
                    rotor[65 + (i << 3)] <= rotor[64 + (i << 3)];
                    rotor[66 + (i << 3)] <= rotor[67 + (i << 3)];
                    rotor[67 + (i << 3)] <= rotor[66 + (i << 3)];
                    rotor[68 + (i << 3)] <= rotor[69 + (i << 3)];
                    rotor[69 + (i << 3)] <= rotor[68 + (i << 3)];
                    rotor[70 + (i << 3)] <= rotor[71 + (i << 3)];
                    rotor[71 + (i << 3)] <= rotor[70 + (i << 3)];
                end
            end
            2:
            begin
                for (i=0;i<8;i=i+1)
                begin
                    rotor[64 + (i << 3)] <= rotor[66 + (i << 3)];
                    rotor[65 + (i << 3)] <= rotor[67 + (i << 3)];
                    rotor[66 + (i << 3)] <= rotor[64 + (i << 3)];
                    rotor[67 + (i << 3)] <= rotor[65 + (i << 3)];
                    rotor[68 + (i << 3)] <= rotor[70 + (i << 3)];
                    rotor[69 + (i << 3)] <= rotor[71 + (i << 3)];
                    rotor[70 + (i << 3)] <= rotor[68 + (i << 3)];
                    rotor[71 + (i << 3)] <= rotor[69 + (i << 3)];
                end
            end
            3:
            begin
                for (i=0;i<8;i=i+1)
                begin
                    rotor[64 + (i << 3)] <= rotor[64 + (i << 3)];
                    rotor[65 + (i << 3)] <= rotor[68 + (i << 3)];
                    rotor[66 + (i << 3)] <= rotor[69 + (i << 3)];
                    rotor[67 + (i << 3)] <= rotor[70 + (i << 3)];
                    rotor[68 + (i << 3)] <= rotor[65 + (i << 3)];
                    rotor[69 + (i << 3)] <= rotor[66 + (i << 3)];
                    rotor[70 + (i << 3)] <= rotor[67 + (i << 3)];
                    rotor[71 + (i << 3)] <= rotor[71 + (i << 3)];
                end
            end
            4:
            begin
                for (i=0;i<8;i=i+1)
                begin
                    rotor[64 + (i << 3)] <= rotor[68 + (i << 3)];
                    rotor[65 + (i << 3)] <= rotor[69 + (i << 3)];
                    rotor[66 + (i << 3)] <= rotor[70 + (i << 3)];
                    rotor[67 + (i << 3)] <= rotor[71 + (i << 3)];
                    rotor[68 + (i << 3)] <= rotor[64 + (i << 3)];
                    rotor[69 + (i << 3)] <= rotor[65 + (i << 3)];
                    rotor[70 + (i << 3)] <= rotor[66 + (i << 3)];
                    rotor[71 + (i << 3)] <= rotor[67 + (i << 3)];
                end
            end
            5:
            begin
                for (i=0;i<8;i=i+1)
                begin
                    rotor[64 + (i << 3)] <= rotor[69 + (i << 3)];
                    rotor[65 + (i << 3)] <= rotor[70 + (i << 3)];
                    rotor[66 + (i << 3)] <= rotor[71 + (i << 3)];
                    rotor[67 + (i << 3)] <= rotor[67 + (i << 3)];
                    rotor[68 + (i << 3)] <= rotor[68 + (i << 3)];
                    rotor[69 + (i << 3)] <= rotor[64 + (i << 3)];
                    rotor[70 + (i << 3)] <= rotor[65 + (i << 3)];
                    rotor[71 + (i << 3)] <= rotor[66 + (i << 3)];
                end
            end
            6:
            begin
                for (i=0;i<8;i=i+1)
                begin
                    rotor[64 + (i << 3)] <= rotor[70 + (i << 3)];
                    rotor[65 + (i << 3)] <= rotor[71 + (i << 3)];
                    rotor[66 + (i << 3)] <= rotor[67 + (i << 3)];
                    rotor[67 + (i << 3)] <= rotor[66 + (i << 3)];
                    rotor[68 + (i << 3)] <= rotor[69 + (i << 3)];
                    rotor[69 + (i << 3)] <= rotor[68 + (i << 3)];
                    rotor[70 + (i << 3)] <= rotor[64 + (i << 3)];
                    rotor[71 + (i << 3)] <= rotor[65 + (i << 3)];
                end
            end
            7:
            begin
                for (i=0;i<8;i=i+1)
                begin
                    rotor[64 + (i << 3)] <= rotor[71 + (i << 3)];
                    rotor[65 + (i << 3)] <= rotor[70 + (i << 3)];
                    rotor[66 + (i << 3)] <= rotor[69 + (i << 3)];
                    rotor[67 + (i << 3)] <= rotor[68 + (i << 3)];
                    rotor[68 + (i << 3)] <= rotor[67 + (i << 3)];
                    rotor[69 + (i << 3)] <= rotor[66 + (i << 3)];
                    rotor[70 + (i << 3)] <= rotor[65 + (i << 3)];
                    rotor[71 + (i << 3)] <= rotor[64 + (i << 3)];
                end
            end
            default: for (i=64;i<128;i=i+1) rotor[i] <= rotor[i];
        endcase
    end
end
endmodule

// Area: 146823.971091 (without locking signal: 145939.148589)
