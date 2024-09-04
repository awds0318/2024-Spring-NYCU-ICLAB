/**************************************************************************/
// Copyright (c) 2023, OASIS Lab
// MODULE: TESTBED
// FILE NAME: TESTBED.v
// VERSRION: 1.0
// DATE: Feb 8, 2023
// AUTHOR: Kuan-Wei Chen, NYCU IEE
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2023 Spring IC Lab / Exersise Lab03 / SUBWAY
// MODIFICATION HISTORY:
// Date                 Description
//
/**************************************************************************/
`timescale 1ns/10ps

`include "PATTERN.v"
`ifdef RTL
`include "BRIDGE.v"
// `include "BRIDGE_encrypted.v"  //When you want to check your pattern
`endif
`ifdef GATE
    `include "BRIDGE_SYN.v"
`endif

module TESTBED;

// Inputs
wire        clk, rst_n;
wire        in_valid;
wire        direction;
wire [12:0] addr_dram;
wire [15:0] addr_sd;

// Outputs
wire        out_valid;
wire [7:0]  out_data;

// DRAM
wire        AR_VALID;
wire [31:0] AR_ADDR;
wire        R_READY;
wire        AW_VALID;
wire [31:0] AW_ADDR;
wire        W_VALID;
wire [63:0] W_DATA;
wire        B_READY;
wire        AR_READY;
wire        R_VALID;
wire [1:0]  R_RESP;
wire [63:0] R_DATA;
wire        AW_READY;
wire        W_READY;
wire        B_VALID;
wire [1:0]  B_RESP;

// SD
wire        MISO;
wire        MOSI;

initial
begin
`ifdef RTL
    $fsdbDumpfile("BRIDGE.fsdb");
    $fsdbDumpvars(0,"+mda");
`endif

`ifdef GATE

    $sdf_annotate("BRIDGE_SYN.sdf", u_BRIDGE);
    $fsdbDumpfile("BRIDGE_SYN.fsdb");
    $fsdbDumpvars(0,"+mda");
`endif
end

BRIDGE u_BRIDGE(
           // Inputs
           .clk(clk),
           .rst_n(rst_n),
           .in_valid(in_valid),
           .direction(direction),
           .addr_dram(addr_dram),
           .addr_sd(addr_sd),
           // Outputs
           .out_valid(out_valid),
           .out_data(out_data),
           // DRAM
           .AR_VALID(AR_VALID),
           .AR_ADDR(AR_ADDR),
           .R_READY(R_READY),
           .AW_VALID(AW_VALID),
           .AW_ADDR(AW_ADDR),
           .W_VALID(W_VALID),
           .W_DATA(W_DATA),
           .B_READY(B_READY),
           .AR_READY(AR_READY),
           .R_VALID(R_VALID),
           .R_RESP(R_RESP),
           .R_DATA(R_DATA),
           .AW_READY(AW_READY),
           .W_READY(W_READY),
           .B_VALID(B_VALID),
           .B_RESP(B_RESP),
           // SD
           .MISO(MISO),
           .MOSI(MOSI)
       );

PATTERN u_PATTERN(
            // Inputs
            .clk(clk),
            .rst_n(rst_n),
            .in_valid(in_valid),
            .direction(direction),
            .addr_dram(addr_dram),
            .addr_sd(addr_sd),
            // Outputs
            .out_valid(out_valid),
            .out_data(out_data),
            // DRAM
            .AR_VALID(AR_VALID),
            .AR_ADDR(AR_ADDR),
            .R_READY(R_READY),
            .AW_VALID(AW_VALID),
            .AW_ADDR(AW_ADDR),
            .W_VALID(W_VALID),
            .W_DATA(W_DATA),
            .B_READY(B_READY),
            .AR_READY(AR_READY),
            .R_VALID(R_VALID),
            .R_RESP(R_RESP),
            .R_DATA(R_DATA),
            .AW_READY(AW_READY),
            .W_READY(W_READY),
            .B_VALID(B_VALID),
            .B_RESP(B_RESP),
            // SD
            .MISO(MISO),
            .MOSI(MOSI)
        );

endmodule
