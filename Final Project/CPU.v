//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

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
       bready_m_inf,
                    
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
       rready_m_inf 

);

//---------------------------------------------------------------------
//   Input & Output Declaration
//---------------------------------------------------------------------	
input  wire clk, rst_n;
output reg  IO_stall;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/

parameter ID_WIDTH = 4, ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER = 2, WRIT_NUMBER = 1;

// axi write address channel 
output wire [WRIT_NUMBER * ID_WIDTH-1:0]      awid_m_inf;
output wire [WRIT_NUMBER * ADDR_WIDTH-1:0]  awaddr_m_inf;
output wire [WRIT_NUMBER * 3 -1:0]          awsize_m_inf;
output wire [WRIT_NUMBER * 2 -1:0]         awburst_m_inf;
output wire [WRIT_NUMBER * 7 -1:0]           awlen_m_inf;
output wire [WRIT_NUMBER-1:0]              awvalid_m_inf;
input  wire [WRIT_NUMBER-1:0]              awready_m_inf;

// axi write data channel 
output wire [WRIT_NUMBER * DATA_WIDTH-1:0]   wdata_m_inf;
output wire [WRIT_NUMBER-1:0]                wlast_m_inf;
output wire [WRIT_NUMBER-1:0]               wvalid_m_inf;
input  wire [WRIT_NUMBER-1:0]               wready_m_inf;

// axi write response channel
input  wire [WRIT_NUMBER * ID_WIDTH-1:0]       bid_m_inf;
input  wire [WRIT_NUMBER * 2 -1:0]           bresp_m_inf;
input  wire [WRIT_NUMBER-1:0]               bvalid_m_inf;
output wire [WRIT_NUMBER-1:0]               bready_m_inf;

//---------------------------------------------------------------------
// axi read address channel 
output wire [DRAM_NUMBER * ID_WIDTH-1:0]      arid_m_inf; // const
output wire [DRAM_NUMBER * ADDR_WIDTH-1:0]  araddr_m_inf;
output wire [DRAM_NUMBER * 7 -1:0]           arlen_m_inf; // const
output wire [DRAM_NUMBER * 3 -1:0]          arsize_m_inf; // const
output wire [DRAM_NUMBER * 2 -1:0]         arburst_m_inf; // const
output wire [DRAM_NUMBER-1:0]              arvalid_m_inf;
input  wire [DRAM_NUMBER-1:0]              arready_m_inf;

// axi read data channel 
input  wire [DRAM_NUMBER * ID_WIDTH-1:0]       rid_m_inf;
input  wire [DRAM_NUMBER * DATA_WIDTH-1:0]   rdata_m_inf;
input  wire [DRAM_NUMBER * 2 -1:0]           rresp_m_inf;
input  wire [DRAM_NUMBER-1:0]                rlast_m_inf;
input  wire [DRAM_NUMBER-1:0]               rvalid_m_inf;
output wire [DRAM_NUMBER-1:0]               rready_m_inf; // const

//---------------------------------------------------------------------

/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;

//---------------------------------------------------------------------
//   Wrtie down your design below
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
localparam IF  = 2'd0; 
localparam EXE = 2'd1;
localparam MEM = 2'd2;
localparam DET = 2'd3;
reg [1:0] cs, ns;

// Cache's FSM
localparam S_IDLE   = 3'd0;
localparam S_READ   = 3'd1;
localparam S_DELAY  = 3'd2;
localparam S_OUTPUT = 3'd3;
localparam S_FETCH  = 3'd4;
localparam S_WRITE  = 3'd5;
reg [2:0] S_cs, S_ns;

reg [15:0] CACHE_DO;  //output data only 1 cycle

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------

//instruction (use it in EXE & MEM)
reg         [15:0] instruction;
wire        [2:0]  op_code;
wire signed [3:0]  rs, rt, rd;
wire               func;
wire signed [4:0]  imm_br;

wire        [3:0]  coeff_a;
wire        [8:0]  coeff_b;

wire signed [4:0]  imm;

//ALU
reg  signed [15:0] alu_in_1, alu_in_2, alu_out;
reg  signed [15:0] wb_data;
reg  signed [15:0] rs_data, rt_data;
reg  signed [15:0] st_data;          //Store's value
reg  signed [15:0] br_rs, br_rt;
wire signed [31:0] mult_out;

reg         [10:0] pc;                   // PC (not include pc's last bit because last bit always equal to 0, means this pc is SRAM's address)
wire signed [10:0] pc_add = pc + 11'd1;  // imm_br might be negative, so write another wire in signed is needed.

reg                delay_io_stall;       // output (if instruction is ADD, SUB, SLT, Mult, Det io_stall will delay 1 cycle)
reg                out_valid_data;       // read / write data END

reg         [2:0]  det_cnt;
//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

always @(posedge clk or negedge rst_n) det_cnt <= (!rst_n)? 0 : ((ns == DET)? det_cnt + 1 : 0);

// -------------------------------------------- FSM ------------------------------------------- //
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) cs <= IF;
    else       cs <= ns;
end

always @(*)
begin
    ns = cs;
    case (cs)
        IF:  ns = (S_cs == S_OUTPUT)? EXE : IF;                                          // read instructure END   
        EXE: ns = (op_code[2:1] == 2'b01)? MEM : ((op_code[2:1] == 2'b11)? DET : IF);    // op_code[2:1] means Load, Store
        MEM: ns = (!out_valid_data)? MEM : IF;
        DET: ns = (det_cnt == 4)? IF : DET;
    endcase
end

// --------------------------------------------- PC ------------------------------------------- //
//PC change when next cycle is new instructure
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)                    pc <= 0;
    else if(ns == IF && cs != ns) pc <= (instruction[15:14] == 2'b10 && br_rs == br_rt)? pc_add + imm_br : pc_add;   //branch on equal
end
// ---------------------------------------- INSTRUCTION --------------------------------------- //

always @(posedge clk) instruction <= (ns == EXE)? CACHE_DO : instruction; //no need reset

assign op_code  = instruction[15:13];
assign rs       = instruction[12:9];
assign rt       = instruction[8:5];
assign rd       = instruction[4:1];
assign func     = instruction[0];
assign imm_br   = instruction[4:0];  // for branch use
assign coeff_a  = instruction[12:9];
assign coeff_b  = instruction[8:0];

assign imm      = CACHE_DO[4:0];     // for Load Store use

// -------------------------------------------- ALU ------------------------------------------- //
always @(posedge clk) alu_in_1 <= (ns == EXE)? rs_data : alu_in_1;
always @(posedge clk) alu_in_2 <= (ns == EXE)? ((CACHE_DO[14])? imm : rt_data) : alu_in_2;

DW02_mult_2_stage #(16, 16) mult_inst(.A(alu_in_1), .B(alu_in_2), .TC(1'b1), .CLK(clk), .PRODUCT(mult_out)); // Mult(pipline)

always @(posedge clk) alu_out <= (op_code == 0 && func)? alu_in_1 - alu_in_2 : alu_in_1 + alu_in_2; // SUB OTHER 

// Determinant (same cycle as Mult)
wire signed [31:0] r10_r15, r11_r14;
wire signed [31:0] r6_r15, r7_r14;
wire signed [31:0] r6_r11, r7_r10;
wire signed [31:0] r2_r15, r3_r14;
wire signed [31:0] r2_r7, r3_r6;
wire signed [31:0] r2_r11, r3_r10;

DW02_mult_2_stage #(16, 16) r0_0(.A(core_r10), .B(core_r15), .TC(1'b1), .CLK(clk), .PRODUCT(r10_r15)); 
DW02_mult_2_stage #(16, 16) r0_1(.A(core_r11), .B(core_r14), .TC(1'b1), .CLK(clk), .PRODUCT(r11_r14));

DW02_mult_2_stage #(16, 16) r1_0(.A(core_r6),  .B(core_r15), .TC(1'b1), .CLK(clk), .PRODUCT(r6_r15)); 
DW02_mult_2_stage #(16, 16) r1_1(.A(core_r7),  .B(core_r14), .TC(1'b1), .CLK(clk), .PRODUCT(r7_r14)); 

DW02_mult_2_stage #(16, 16) r2_0(.A(core_r6),  .B(core_r11), .TC(1'b1), .CLK(clk), .PRODUCT(r6_r11)); 
DW02_mult_2_stage #(16, 16) r2_1(.A(core_r7),  .B(core_r10), .TC(1'b1), .CLK(clk), .PRODUCT(r7_r10)); 

DW02_mult_2_stage #(16, 16) r3_0(.A(core_r2),  .B(core_r15), .TC(1'b1), .CLK(clk), .PRODUCT(r2_r15)); 
DW02_mult_2_stage #(16, 16) r3_1(.A(core_r3),  .B(core_r14), .TC(1'b1), .CLK(clk), .PRODUCT(r3_r14)); 

DW02_mult_2_stage #(16, 16) r4_0(.A(core_r2),  .B(core_r7),  .TC(1'b1), .CLK(clk), .PRODUCT(r2_r7)); 
DW02_mult_2_stage #(16, 16) r4_1(.A(core_r3),  .B(core_r6),  .TC(1'b1), .CLK(clk), .PRODUCT(r3_r6)); 

DW02_mult_2_stage #(16, 16) r5_0(.A(core_r2),  .B(core_r11), .TC(1'b1), .CLK(clk), .PRODUCT(r2_r11)); 
DW02_mult_2_stage #(16, 16) r5_1(.A(core_r3),  .B(core_r10), .TC(1'b1), .CLK(clk), .PRODUCT(r3_r10)); 

reg  signed [32:0] sub0, sub1, sub2, sub3, sub4, sub5;
wire signed [32:0] sub0_r, sub1_r, sub2_r, sub3_r, sub4_r, sub5_r;

assign sub0_r = r10_r15 - r11_r14;
assign sub1_r = r6_r15 - r7_r14;
assign sub2_r = r6_r11 - r7_r10;
assign sub3_r = r2_r15 - r3_r14;
assign sub4_r = r2_r7 - r3_r6;
assign sub5_r = r2_r11 - r3_r10;

always @(posedge clk) sub0 <= sub0_r;
always @(posedge clk) sub1 <= sub1_r;
always @(posedge clk) sub2 <= sub2_r;
always @(posedge clk) sub3 <= sub3_r;
always @(posedge clk) sub4 <= sub4_r;
always @(posedge clk) sub5 <= sub5_r;

wire signed [48:0] tmp0, tmp1, tmp2;
wire signed [48:0] tmp3, tmp4, tmp5;
wire signed [48:0] tmp6, tmp7, tmp8;
wire signed [48:0] tmp9, tmpa, tmpb;

DW02_mult_2_stage #(16, 33) t0_0(.A(core_r5),  .B(sub0), .TC(1'b1), .CLK(clk), .PRODUCT(tmp0)); 
DW02_mult_2_stage #(16, 33) t0_1(.A(core_r9),  .B(sub1), .TC(1'b1), .CLK(clk), .PRODUCT(tmp1)); 
DW02_mult_2_stage #(16, 33) t0_2(.A(core_r13), .B(sub2), .TC(1'b1), .CLK(clk), .PRODUCT(tmp2)); 

DW02_mult_2_stage #(16, 33) t1_0(.A(core_r1),  .B(sub0), .TC(1'b1), .CLK(clk), .PRODUCT(tmp3)); 
DW02_mult_2_stage #(16, 33) t1_1(.A(core_r9),  .B(sub3), .TC(1'b1), .CLK(clk), .PRODUCT(tmp4)); 
DW02_mult_2_stage #(16, 33) t1_2(.A(core_r13), .B(sub5), .TC(1'b1), .CLK(clk), .PRODUCT(tmp5)); 

DW02_mult_2_stage #(16, 33) t2_0(.A(core_r1),  .B(sub1), .TC(1'b1), .CLK(clk), .PRODUCT(tmp6)); 
DW02_mult_2_stage #(16, 33) t2_1(.A(core_r5),  .B(sub3), .TC(1'b1), .CLK(clk), .PRODUCT(tmp7)); 
DW02_mult_2_stage #(16, 33) t2_2(.A(core_r13), .B(sub4), .TC(1'b1), .CLK(clk), .PRODUCT(tmp8)); 

DW02_mult_2_stage #(16, 33) t3_0(.A(core_r1),  .B(sub2), .TC(1'b1), .CLK(clk), .PRODUCT(tmp9)); 
DW02_mult_2_stage #(16, 33) t3_1(.A(core_r5),  .B(sub5), .TC(1'b1), .CLK(clk), .PRODUCT(tmpa)); 
DW02_mult_2_stage #(16, 33) t3_2(.A(core_r9),  .B(sub4), .TC(1'b1), .CLK(clk), .PRODUCT(tmpb));

reg  signed [49:0] rank0, rank1, rank2, rank3;
wire signed [49:0] rank0_r, rank1_r, rank2_r, rank3_r;

assign rank0_r = tmp0 - tmp1 + tmp2;
assign rank1_r = tmp3 - tmp4 + tmp5;
assign rank2_r = tmp6 - tmp7 + tmp8;
assign rank3_r = tmp9 - tmpa + tmpb;

always @(posedge clk) rank0 <= rank0_r;
always @(posedge clk) rank1 <= rank1_r;
always @(posedge clk) rank2 <= rank2_r;
always @(posedge clk) rank3 <= rank3_r;

wire signed [65:0] det_tmp0, det_tmp1, det_tmp2, det_tmp3;

DW02_mult_3_stage #(16, 50) d0_0(.A(core_r0),  .B(rank0), .TC(1'b1), .CLK(clk), .PRODUCT(det_tmp0)); 
DW02_mult_3_stage #(16, 50) d0_1(.A(core_r4),  .B(rank1), .TC(1'b1), .CLK(clk), .PRODUCT(det_tmp1)); 
DW02_mult_3_stage #(16, 50) d0_2(.A(core_r8),  .B(rank2), .TC(1'b1), .CLK(clk), .PRODUCT(det_tmp2)); 
DW02_mult_3_stage #(16, 50) d0_3(.A(core_r12), .B(rank3), .TC(1'b1), .CLK(clk), .PRODUCT(det_tmp3)); 

reg  signed [67:0] det_res;
wire signed [67:0] det_res_r = det_tmp0 - det_tmp1 + det_tmp2 - det_tmp3;

always @(posedge clk) det_res <= det_res_r;

wire signed [67:0] det_rll = det_res >>> (2 * coeff_a);
wire signed [68:0] det_add = det_rll + $signed({1'b0, coeff_b});

reg  signed [15:0] det;

always @(*) 
begin
    if(det_add > 32767)       det = 32767;
    else if(det_add < -32768) det = -32768;
    else                      det = det_add;
end

// ----------------------------------------- WRITE BACK --------------------------------------- //
always @(*)
begin
    if(op_code[0] && !func)       wb_data = (alu_in_1 < alu_in_2)? 1 : 0;  // SLT   
    else if(op_code == 1 && func) wb_data = mult_out;                      // Mult
    else                          wb_data = alu_out;                       // ADD, SUB
end

// ----------------------------------------- RS RT RD ----------------------------------------- //
//core
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        core_r0  <= 'b0;
        core_r1  <= 'b0;
        core_r2  <= 'b0;
        core_r3  <= 'b0;
        core_r4  <= 'b0;
        core_r5  <= 'b0;
        core_r6  <= 'b0;
        core_r7  <= 'b0;
        core_r8  <= 'b0;
        core_r9  <= 'b0;
        core_r10 <= 'b0;
        core_r11 <= 'b0;
        core_r12 <= 'b0;
        core_r13 <= 'b0;
        core_r14 <= 'b0;
        core_r15 <= 'b0;
    end
    else if(!delay_io_stall && op_code[2:1] == 3) core_r0 <= det; // Det
    else if(!delay_io_stall) // WB stage
    begin
        case (rd)
            'd0:  core_r0  <= wb_data;
            'd1:  core_r1  <= wb_data;
            'd2:  core_r2  <= wb_data;
            'd3:  core_r3  <= wb_data;
            'd4:  core_r4  <= wb_data;
            'd5:  core_r5  <= wb_data;
            'd6:  core_r6  <= wb_data;
            'd7:  core_r7  <= wb_data;
            'd8:  core_r8  <= wb_data;
            'd9:  core_r9  <= wb_data;
            'd10: core_r10 <= wb_data;
            'd11: core_r11 <= wb_data;
            'd12: core_r12 <= wb_data;
            'd13: core_r13 <= wb_data;
            'd14: core_r14 <= wb_data;
            'd15: core_r15 <= wb_data;
        endcase
    end
    else if(out_valid_data && !op_code[0]) // Load
    begin 
        case (rt)
            'd0:  core_r0  <= CACHE_DO;
            'd1:  core_r1  <= CACHE_DO;
            'd2:  core_r2  <= CACHE_DO;
            'd3:  core_r3  <= CACHE_DO;
            'd4:  core_r4  <= CACHE_DO;
            'd5:  core_r5  <= CACHE_DO;
            'd6:  core_r6  <= CACHE_DO;
            'd7:  core_r7  <= CACHE_DO;
            'd8:  core_r8  <= CACHE_DO;
            'd9:  core_r9  <= CACHE_DO;
            'd10: core_r10 <= CACHE_DO;
            'd11: core_r11 <= CACHE_DO;
            'd12: core_r12 <= CACHE_DO;
            'd13: core_r13 <= CACHE_DO;
            'd14: core_r14 <= CACHE_DO;
            'd15: core_r15 <= CACHE_DO;
        endcase
    end
end

//rs_data(for alu_in_1)
always @(*)
begin
    rs_data = 0;
    case (CACHE_DO[12:9])
        'd0:  rs_data = core_r0;
        'd1:  rs_data = core_r1;
        'd2:  rs_data = core_r2;
        'd3:  rs_data = core_r3;
        'd4:  rs_data = core_r4;
        'd5:  rs_data = core_r5;
        'd6:  rs_data = core_r6;
        'd7:  rs_data = core_r7;
        'd8:  rs_data = core_r8;
        'd9:  rs_data = core_r9;
        'd10: rs_data = core_r10;
        'd11: rs_data = core_r11;
        'd12: rs_data = core_r12;
        'd13: rs_data = core_r13;
        'd14: rs_data = core_r14;
        'd15: rs_data = core_r15;
    endcase
end

// rt_data(for alu_in_2)
always @(*)
begin
    rt_data = 0;
    case (CACHE_DO[8:5])
        'd0:  rt_data = core_r0;
        'd1:  rt_data = core_r1;
        'd2:  rt_data = core_r2;
        'd3:  rt_data = core_r3;
        'd4:  rt_data = core_r4;
        'd5:  rt_data = core_r5;
        'd6:  rt_data = core_r6;
        'd7:  rt_data = core_r7;
        'd8:  rt_data = core_r8;
        'd9:  rt_data = core_r9;
        'd10: rt_data = core_r10;
        'd11: rt_data = core_r11;
        'd12: rt_data = core_r12;
        'd13: rt_data = core_r13;
        'd14: rt_data = core_r14;
        'd15: rt_data = core_r15;
    endcase
end

// st_data(for store in SRAM & DRAM)
always @(posedge clk)
begin
    case (rt)
        'd0:  st_data <= core_r0;
        'd1:  st_data <= core_r1;
        'd2:  st_data <= core_r2;
        'd3:  st_data <= core_r3;
        'd4:  st_data <= core_r4;
        'd5:  st_data <= core_r5;
        'd6:  st_data <= core_r6;
        'd7:  st_data <= core_r7;
        'd8:  st_data <= core_r8;
        'd9:  st_data <= core_r9;
        'd10: st_data <= core_r10;
        'd11: st_data <= core_r11;
        'd12: st_data <= core_r12;
        'd13: st_data <= core_r13;
        'd14: st_data <= core_r14;
        'd15: st_data <= core_r15;
    endcase
end

//for branch use
//br_rs
always @(posedge clk)
begin
    case (CACHE_DO[12:9])
        'd0:  br_rs <= core_r0;
        'd1:  br_rs <= core_r1;
        'd2:  br_rs <= core_r2;
        'd3:  br_rs <= core_r3;
        'd4:  br_rs <= core_r4;
        'd5:  br_rs <= core_r5;
        'd6:  br_rs <= core_r6;
        'd7:  br_rs <= core_r7;
        'd8:  br_rs <= core_r8;
        'd9:  br_rs <= core_r9;
        'd10: br_rs <= core_r10;
        'd11: br_rs <= core_r11;
        'd12: br_rs <= core_r12;
        'd13: br_rs <= core_r13;
        'd14: br_rs <= core_r14;
        'd15: br_rs <= core_r15;
    endcase
end

//br_rt
always @(posedge clk) br_rt <= rt_data;

// ------------------------------------------ OUTPUT ------------------------------------------ //
//Write Back instructure IO_stall will delay 1 cycle because need wait write back
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) delay_io_stall <= 1;
    else       delay_io_stall <= (ns == IF && cs != ns && (op_code[2:1] == 0 || op_code[2:1] == 3))? 0 : 1;
end

// IO_stall
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)                    IO_stall <= 1;
    else if(ns == IF && cs != ns) IO_stall <= (op_code[2:1] == 0 || op_code[2:1] == 3)? 1 : 0;
    else                          IO_stall <= delay_io_stall;               //for WB
end

// ---------------------------------------- VALID & TAG --------------------------------------- //
// Cache size: 256 (line) x 16 (bits)
// lines   0 ~ 127: store data 
// lines 128 ~ 256: store instruction

// 128 cache line:                      log2(128) = 7 ->  index 7 bits
// each cache line 16 bits (2 bytes):   log2(2)   = 1 -> offset 1 bits
// memory address 12 bits:    12 - index - offset = tag = 4 bits

reg       valid_inst, valid_data;                     // have load SRAM ? (first load)
reg [3:0] tag_inst, tag_data;

always @(posedge clk or negedge rst_n) valid_inst <= (!rst_n)? 0 : ((rlast_m_inf[1])?        1 : valid_inst);
always @(posedge clk or negedge rst_n) tag_inst   <= (!rst_n)? 0 : ((rlast_m_inf[1])? pc[10:7] : tag_inst);

//data
always @(posedge clk or negedge rst_n) valid_data <= (!rst_n)? 0 : ((rlast_m_inf[0])?             1 : valid_data);
always @(posedge clk or negedge rst_n) tag_data   <= (!rst_n)? 0 : ((rlast_m_inf[0])? alu_out[10:7] : tag_data);

// -------------------------------------------- FSM ------------------------------------------- //
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) S_cs <= S_IDLE;
    else       S_cs <= S_ns;
end

always @(*)
begin
    case (S_cs)
        S_IDLE: 
        begin
            if(cs == IF)                      S_ns = (valid_inst && tag_inst ==      pc[10:7])? S_DELAY : S_FETCH;
            else if(cs == MEM && !op_code[0]) S_ns = (valid_data && tag_data == alu_out[10:7])? S_DELAY : S_FETCH; // Load
            else if(cs == MEM &&  op_code[0]) S_ns = S_WRITE;                                                      // Store
            else                              S_ns = S_IDLE;
        end
        S_READ:   S_ns = S_DELAY;
        S_DELAY:  S_ns = S_OUTPUT;
        S_OUTPUT: S_ns = S_IDLE;
        S_FETCH:  S_ns = (|rlast_m_inf)? S_READ : S_FETCH; // rlast_m_inf[0] == 1 || rlast_m_inf[1] == 1
        S_WRITE:  S_ns = (bvalid_m_inf)? S_IDLE : S_WRITE;
        default:  S_ns = S_cs;
    endcase
end

// ------------------------------------------- SRAM -------------------------------------------- //
//SRAM
wire [15:0] CACHE_DO_tmp; //SRAM's output value
reg         CACHE_WEB;
reg  [6:0]  addr;
//addr(when DRAM put to SRAM use 0 -> 127)
always @(posedge clk or negedge rst_n) addr <= (!rst_n)? 0 : ((|rvalid_m_inf)? addr + 1 : addr);

//WEB(use seq. because have hold time violtion)
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) CACHE_WEB <= 1;
    else
    begin 
        if(|arready_m_inf)                                 CACHE_WEB <= 0;  // DRAM put to SRAM (start)
        else if(addr == 127)                               CACHE_WEB <= 1;  // DRAM put to SRAM (end)
        else if(tag_data == alu_out[10:7] && wvalid_m_inf) CACHE_WEB <= 0;  // store (start)
        else if(tag_data == alu_out[10:7] && bvalid_m_inf) CACHE_WEB <= 1;  // store (end)
    end
end

wire [6:0] sram_addr; // SRAM's addr

assign sram_addr = (S_cs == S_FETCH)? addr : ((cs == IF)? pc : alu_out[10:0]); // DRAM put to SRAM ? or instruction? or Load/Store?

/*
when DRAM put to SRAM, only 16 bit have value so can use or (|) merge rdata_m_inf(0~15 & 16~31)
when task is instruction only one possible -> rdata_m_inf[16~31]
when task is Load/store have 2 possible -> Load(rdata_m_inf[0~15]) -> Store(st_data)(when S_cs == S_WRITE)
instruction: rdata_m_inf[31:16]
data:        rdata_m_inf[15:0]
*/

wire [15:0] CACHE_DI;
assign CACHE_DI = (rdata_m_inf[31:16] | ({16{S_cs != S_WRITE}} & rdata_m_inf[15:0] | {16{S_cs == S_WRITE}} & st_data));

CACHE_SRAM u_CACHE_SRAM(.A({(cs == IF), sram_addr}), .DI(CACHE_DI), .DO(CACHE_DO_tmp), .CK(clk), .WEB(CACHE_WEB));
always @(posedge clk) CACHE_DO <= CACHE_DO_tmp;

always @(*) out_valid_data = ((S_cs == S_OUTPUT || bvalid_m_inf) && cs != IF)? 1 : 0; // cs != IF is to check this tesk is Load / Store task

// ----------------------------------------- AXI WRITE ----------------------------------------- //
// data DRAM's write
reg DATA_wvalid;
reg DATA_awvalid;

// axi write address channel (AW)
assign awid_m_inf    = 0;
assign awburst_m_inf = 1;
assign awsize_m_inf  = 1;
assign awlen_m_inf   = 0;
assign awaddr_m_inf  = {20'd1, alu_out[10:0], 1'd0};  // write back DRAM address
assign awvalid_m_inf = DATA_awvalid;

// axi write data channel (W)
assign wlast_m_inf  = DATA_wvalid;   // only write 1 value
assign wdata_m_inf  = st_data;              
assign wvalid_m_inf = DATA_wvalid;

// axi write response channel (B)
assign bready_m_inf  = 1;

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)                               DATA_awvalid <= 0;
	else if(S_ns == S_WRITE && S_cs != S_ns) DATA_awvalid <= 1;
    else if(awready_m_inf)                   DATA_awvalid <= 0;
    // else                                     DATA_awvalid <= DATA_awvalid;
end

//wvalid
always @(posedge clk)
begin
    if(S_cs == S_WRITE) DATA_wvalid <= (awready_m_inf)? 1 : ((wready_m_inf)? 0 : DATA_wvalid);
    else                DATA_wvalid <= 0;
end

// ----------------------------------------- AXI READ ----------------------------------------- //
wire [31:0] DATA_araddr, INST_araddr;
reg         DATA_arvalid, INST_arvalid;
wire        DATA_arready = arready_m_inf[0];
wire        INST_arready = arready_m_inf[1];

// axi read address channel (AR)
assign arid_m_inf    = 0;                              // 8'b0; 
assign arburst_m_inf = 5;                              // 4'b0101;
assign arsize_m_inf  = 9;                              // 6'b001001;
assign arlen_m_inf   = 16383;                          // 14'b11_1111_1111_1111;
assign araddr_m_inf  = {INST_araddr, DATA_araddr};     // {instructure, data}
assign arvalid_m_inf = {INST_arvalid, DATA_arvalid};

// axi read data channel (R)
assign rready_m_inf  = 3;                              // 2'b11;

assign DATA_araddr = {20'd1, alu_out[10:7], 8'd0};
assign INST_araddr = {20'd1, pc[10:7], 8'd0};

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)                                           INST_arvalid <= 0;
	else if(cs == IF && S_ns == S_FETCH && S_cs != S_ns) INST_arvalid <= 1;  // read start
	else if(INST_arready)                                INST_arvalid <= 0;  // read end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)                                           DATA_arvalid <= 0;
	else if(cs != IF && S_ns == S_FETCH && S_cs != S_ns) DATA_arvalid <= 1; // read start
	else if(DATA_arready)                                DATA_arvalid <= 0; // read end
end

endmodule


module CACHE_SRAM(
    A, DI, DO, CK, WEB
);

// SRAM
input         CK, WEB;
input  [7:0]  A;
input  [15:0] DI;

output [15:0] DO;

SRAM_256X16 u_SRAM_256X16(
    .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .A6(A[6]), .A7(A[7]),

    .DI0 (DI[ 0]), .DI1 (DI[ 1]), .DI2 (DI[ 2]), .DI3 (DI[ 3]),
    .DI4 (DI[ 4]), .DI5 (DI[ 5]), .DI6 (DI[ 6]), .DI7 (DI[ 7]),
    .DI8 (DI[ 8]), .DI9 (DI[ 9]), .DI10(DI[10]), .DI11(DI[11]),
    .DI12(DI[12]), .DI13(DI[13]), .DI14(DI[14]), .DI15(DI[15]),
    
    .DO0 (DO[ 0]), .DO1 (DO[ 1]), .DO2 (DO[ 2]), .DO3 (DO[ 3]),
    .DO4 (DO[ 4]), .DO5 (DO[ 5]), .DO6 (DO[ 6]), .DO7 (DO[ 7]),
    .DO8 (DO[ 8]), .DO9 (DO[ 9]), .DO10(DO[10]), .DO11(DO[11]),
    .DO12(DO[12]), .DO13(DO[13]), .DO14(DO[14]), .DO15(DO[15]),
    
    .CK(CK), .CS(1'b1), .OE(1'b1), .WEB(WEB));

endmodule

// Cycle: 4.60
// Area: 1312422.642021
// Gate count: 131516
// Total area of Chip: 3326312.102 um^2  
