//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Ting-Yu Chang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : BRIDGE_encrypted.v
//   Module Name : BRIDGE
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module BRIDGE(
           // Input Signals
           clk,
           rst_n,
           in_valid,
           direction,
           addr_dram,
           addr_sd,
           // Output Signals
           out_valid,
           out_data,
           // DRAM Signals
           AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
           AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
           // SD Signals
           MISO,
           MOSI
       );
// Input Signals
input             clk, rst_n;
input             in_valid;
input             direction;
input      [12:0] addr_dram;
input      [15:0] addr_sd;

// Output Signals
output reg        out_valid;
output reg [7:0]  out_data;

// DRAM Signals
// write address channel
output reg [31:0] AW_ADDR;
output reg        AW_VALID;
input             AW_READY;
// write data channel
output reg        W_VALID;
output reg [63:0] W_DATA;
input             W_READY;
// write response channel
input             B_VALID;
input      [1:0]  B_RESP;
output reg        B_READY;

// read address channel
output reg [31:0] AR_ADDR;
output reg        AR_VALID;
input             AR_READY;
// read data channel
input      [63:0] R_DATA;
input             R_VALID;
input      [1:0]  R_RESP;
output reg        R_READY;

// SD Signals
input             MISO;
output reg        MOSI;

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
localparam IDLE           = 0;
localparam AW             = 1;
localparam W              = 2;
localparam B              = 3;
localparam AR             = 4;
localparam R              = 5;
localparam COMMAND        = 6;
localparam WAIT_RESP      = 7;
localparam WAIT_TOKEN     = 8;
localparam WAIT_UNIT      = 9;
localparam DATA           = 10;
localparam DATA_RESP      = 11;
localparam WAIT_DATA_RESP = 12;
localparam WAIT_BUSY      = 13;
localparam OUTPUT         = 14;
reg [3:0]  cs, ns;
// DRAM --> SD : IDLE -> AR -> R -> COMMAND -> WAIT_RESP -> WAIT_UNIT -> DATA -> DATA_RESP -> WAIT_DATA_RESP -> WAIT_BUSY -> OUTPUT
// SD --> DRAM : IDLE -> COMMAND -> WAIT_RESP -> WAIT_TOKEN -> DATA -> AW -> W -> B -> OUTPUT

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
reg  [6:0]  cnt; // 88

reg         direction_reg;
reg  [31:0] addr_dram_reg;
reg  [31:0] addr_sd_reg;

reg  [63:0] R_DATA_reg; // the data read from AXIL
reg  [79:0] SD_R_DATA;  // the data read from SD card
wire [87:0] SD_W_DATA;  // the data write into SD card

wire [6:0]  crc7;
wire [47:0] command;
reg  [7:0]  response, token, data_response;

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------
always @(posedge clk) direction_reg <= (in_valid)? direction : direction_reg;
always @(posedge clk) addr_dram_reg <= (in_valid)? addr_dram : addr_dram_reg;
always @(posedge clk) addr_sd_reg   <= (in_valid)? addr_sd   : addr_sd_reg;
always @(posedge clk) R_DATA_reg    <= (R_VALID)? R_DATA : R_DATA_reg;

always @(posedge clk) response      <= (cs == WAIT_RESP)? {response[6:0], MISO} : 255; // 8'b11111111
always @(posedge clk) token         <= (cs == WAIT_TOKEN)? {token[6:0], MISO} : 0;
always @(posedge clk) data_response <= (cs == WAIT_DATA_RESP)? {data_response[6:0], MISO} : 255;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) cs <= IDLE;
    else       cs <= ns;
end

always @(*)
begin
    case (cs)
        IDLE:           ns = (in_valid)? ((direction)? COMMAND : AR) : IDLE;
        AW:             ns = (AW_READY)? W : AW;
        W:              ns = (W_READY)? B : W;
        B:              ns = (B_VALID)? OUTPUT : B;
        AR:             ns = (AR_READY)? R : AR;
        R:              ns = (R_VALID)? COMMAND : R;
        COMMAND:        ns = (cnt == 47)? WAIT_RESP : COMMAND;
        WAIT_RESP:      ns = (response == 0)? ((direction_reg)? WAIT_TOKEN : WAIT_UNIT) : WAIT_RESP;
        WAIT_TOKEN:     ns = (token == 8'hFE)? DATA : WAIT_TOKEN;
        WAIT_UNIT:      ns = (cnt == 22)? DATA : WAIT_UNIT;
        DATA:           ns = (direction_reg)? ((cnt == 80)? AW : DATA) : ((cnt == 87)? DATA_RESP : DATA);
        DATA_RESP:      ns = (cnt == 7)? OUTPUT : WAIT_DATA_RESP;
        WAIT_DATA_RESP: ns = (data_response == 8'b00000101)? WAIT_BUSY : WAIT_DATA_RESP;
        WAIT_BUSY:      ns = (MISO)? OUTPUT : WAIT_BUSY;
        OUTPUT:         ns = (cnt == 7)? IDLE : OUTPUT;
        default:        ns = IDLE;
    endcase
end

always @(posedge clk) cnt <= ((cs == COMMAND) || (ns == WAIT_UNIT) || (token == 8'hFE) || (cs == DATA) || (cs == DATA_RESP) || (cs == OUTPUT))? cnt + 1 : 0;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        out_valid <= 0;
        out_data  <= 0;
    end
    else if(cs == OUTPUT)
    begin
        out_valid <= 1;
        if(direction_reg)
        begin // SD_R_DATA[79:16]
            case (cnt)
                0: out_data <= SD_R_DATA[79:72];
                1: out_data <= SD_R_DATA[71:64];
                2: out_data <= SD_R_DATA[63:56];
                3: out_data <= SD_R_DATA[55:48];
                4: out_data <= SD_R_DATA[47:40];
                5: out_data <= SD_R_DATA[39:32];
                6: out_data <= SD_R_DATA[31:24];
                7: out_data <= SD_R_DATA[23:16];
                default: out_data <= 0;
            endcase
        end
        else
        begin
            case (cnt)
                0: out_data <= R_DATA_reg[63:56];
                1: out_data <= R_DATA_reg[55:48];
                2: out_data <= R_DATA_reg[47:40];
                3: out_data <= R_DATA_reg[39:32];
                4: out_data <= R_DATA_reg[31:24];
                5: out_data <= R_DATA_reg[23:16];
                6: out_data <= R_DATA_reg[15:8];
                7: out_data <= R_DATA_reg[7:0];
                default: out_data <= 0;
            endcase
        end
    end
    else
    begin
        out_data  <= 0;
        out_valid <= 0;
    end


end

// ----------------------------------------- AXIL WRITE ----------------------------------------- //
// write address channel
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        AW_ADDR  <= 0;
        AW_VALID <= 0;
    end
    else
    begin
        AW_ADDR  <= (ns == AW)? addr_dram_reg : 0;
        AW_VALID <= (ns == AW)? 1 : 0;
    end
end

// write data channel
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        W_VALID <= 0;
        W_DATA  <= 0;
    end
    else
    begin
        W_VALID <= (ns == W)? 1 : 0;
        W_DATA  <= (ns == W)? SD_R_DATA[79:16] : 0;
    end
end

// write response channel
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) B_READY <= 0;
    else       B_READY <= (ns == B)? 1 : 0;
end

// ----------------------------------------- AXIL READ ----------------------------------------- //
// read address channel
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        AR_ADDR  <= 0;
        AR_VALID <= 0;
    end
    else
    begin
        AR_ADDR  <= (ns == AR)? ((in_valid)? addr_dram : addr_dram_reg) : 0;
        AR_VALID <= (ns == AR)? 1 : 0;
    end
end

// read data channel
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) R_READY <= 0;
    else       R_READY <= (ns == R)? 1 : 0;
end

// -----------------------------------------    SD    ----------------------------------------- //
// direction 1: read from SD ; 0: write into SD
assign crc7      = (direction_reg)? CRC7({2'b01, 6'd17, addr_sd_reg}) : CRC7({2'b01, 6'd24, addr_sd_reg});
assign command   = (direction_reg)? {2'b01, 6'd17, addr_sd_reg, crc7, 1'b1} : {2'b01, 6'd24, addr_sd_reg, crc7, 1'b1};

assign SD_W_DATA = {8'hFE, R_DATA_reg, CRC16_CCITT(R_DATA_reg)};

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)             MOSI <= 1;
    else if(cs == COMMAND) MOSI <= command[47 - cnt];
    else if(cs == DATA)    MOSI <= (direction_reg)? 1 : SD_W_DATA[87 - cnt];
    else                   MOSI <= 1;
end


always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)                           SD_R_DATA           <= 0;
    else if(ns == DATA && direction_reg) SD_R_DATA[79 - cnt] <= MISO;
end

// -----------------------------------------   CRC   ----------------------------------------- //

function automatic [6:0] CRC7;       // Return 7-bit result
    input [39:0] data;               // 40-bit data input
    reg   [6:0]  crc;
    integer      i;
    reg          data_in, data_out;
    parameter    polynomial = 7'h9;  // x^7 + x^3 + 1

    begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1)
        begin
            data_in  = data[39-i];
            data_out = crc[6];
            crc      = crc << 1;  // Shift the CRC
            if (data_in ^ data_out)
            begin
                crc  = crc ^ polynomial;
            end
        end
        CRC7 = crc;
    end
endfunction

function automatic [15:0] CRC16_CCITT;   // Return 16-bit result
    input [63:0] data;                   // 64-bit data input
    reg   [15:0] crc;
    integer      i;
    reg          data_in, data_out;
    parameter    polynomial = 16'h1021;  // x^16 + x^12 + x^5 + 1

    begin
        crc = 16'd0;
        for (i = 0; i < 64; i = i + 1)
        begin
            data_in  = data[63-i];
            data_out = crc[15];
            crc      = crc << 1;  // Shift the CRC
            if (data_in ^ data_out)
            begin
                crc  = crc ^ polynomial;
            end
        end
        CRC16_CCITT = crc;
    end
endfunction

endmodule

