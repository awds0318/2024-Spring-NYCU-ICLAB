`ifdef RTL
	`define CYCLE_TIME 3.4 
	`define RTL_GATE
`elsif GATE
	`define CYCLE_TIME 3.4
	`define RTL_GATE
`elsif CHIP
    `define CYCLE_TIME 3.4
    `define CHIP_POST 
`elsif POST
    `define CYCLE_TIME 3.4
    `define CHIP_POST 
`endif

`ifdef FUNC
`define PAT_NUM 828
`define MAX_WAIT_READY_CYCLE 2000
`endif
`ifdef PERF
`define PAT_NUM 828
`define MAX_WAIT_READY_CYCLE 100000
`endif

`ifdef RTL
    `define PREFIX My_CPU
`elsif GATE
    `define PREFIX My_CPU
`elsif CHIP
    `define PREFIX My_CHIP
`elsif POST
    `define PREFIX My_CHIP
`endif

`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM_data.v"
`include "../00_TESTBED/pseudo_DRAM_inst.v"

module PATTERN(
// global signals 
    			clk,
			  rst_n,
		   IO_stall,

// axi write address channel 
         awid_s_inf,
       awaddr_s_inf,
       awsize_s_inf,
      awburst_s_inf,
        awlen_s_inf,
      awvalid_s_inf,
      awready_s_inf,

// axi write data channel 
        wdata_s_inf,
        wlast_s_inf,
       wvalid_s_inf,
       wready_s_inf,

// axi write response channel                  
          bid_s_inf,
        bresp_s_inf,
       bvalid_s_inf,
       bready_s_inf,

// axi read address channel                   
         arid_s_inf,
       araddr_s_inf,
        arlen_s_inf,
       arsize_s_inf,
      arburst_s_inf,
      arvalid_s_inf,

// axi read data channel          
      arready_s_inf, 
          rid_s_inf,
        rdata_s_inf,
        rresp_s_inf,
        rlast_s_inf,
       rvalid_s_inf,
       rready_s_inf 
    );

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------

output reg clk, rst_n;
input	     IO_stall;

parameter ID_WIDTH = 4, DATA_WIDTH = 32, ADDR_WIDTH = 32, DRAM_NUMBER = 2, WRIT_NUMBER = 1;

// axi write address channel 
input  wire [WRIT_NUMBER * ID_WIDTH-1:0]      awid_s_inf;
input  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]  awaddr_s_inf;
input  wire [WRIT_NUMBER * 3 -1:0]          awsize_s_inf;
input  wire [WRIT_NUMBER * 2 -1:0]         awburst_s_inf;
input  wire [WRIT_NUMBER * 7 -1:0]           awlen_s_inf;
input  wire [WRIT_NUMBER-1:0]              awvalid_s_inf;
output wire [WRIT_NUMBER-1:0]              awready_s_inf;

// axi write data channel 
input  wire [WRIT_NUMBER * DATA_WIDTH-1:0]   wdata_s_inf;
input  wire [WRIT_NUMBER-1:0]                wlast_s_inf;
input  wire [WRIT_NUMBER-1:0]               wvalid_s_inf;
output wire [WRIT_NUMBER-1:0]               wready_s_inf;

// axi write response channel
output wire [WRIT_NUMBER * ID_WIDTH-1:0]       bid_s_inf;
output wire [WRIT_NUMBER * 2 -1:0]           bresp_s_inf;
output wire [WRIT_NUMBER-1:0]               bvalid_s_inf;
input  wire [WRIT_NUMBER-1:0]               bready_s_inf;

//---------------------------------------------------------------------
// axi read address channel 
input  wire [DRAM_NUMBER * ID_WIDTH-1:0]      arid_s_inf;
input  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]  araddr_s_inf;
input  wire [DRAM_NUMBER * 7 -1:0]           arlen_s_inf;
input  wire [DRAM_NUMBER * 3 -1:0]          arsize_s_inf;
input  wire [DRAM_NUMBER * 2 -1:0]         arburst_s_inf;
input  wire [DRAM_NUMBER-1:0]              arvalid_s_inf;
output wire [DRAM_NUMBER-1:0]              arready_s_inf;

// axi read data channel 
output wire [DRAM_NUMBER * ID_WIDTH-1:0]       rid_s_inf;
output wire [DRAM_NUMBER * DATA_WIDTH-1:0]   rdata_s_inf;
output wire [DRAM_NUMBER * 2 -1:0]           rresp_s_inf;
output wire [DRAM_NUMBER-1:0]                rlast_s_inf;
output wire [DRAM_NUMBER-1:0]               rvalid_s_inf;
input  wire [DRAM_NUMBER-1:0]               rready_s_inf;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer i, j;
integer i_pat, golden_pc, golden_curr_pc, cycles, total_cycles, offset = 16'h1000;

reg signed [15:0] golden_reg       [0:15];
reg signed [15:0] golden_DRAM_data [0:2047];
// 
reg        [15:0] golden_inst;
reg        [2:0]  golden_opcode;
reg        [3:0]  golden_rs, golden_rt, golden_rd;
reg        [3:0]  golden_coeff_a;
reg        [8:0]  golden_coeff_b;
reg               golden_func;
reg signed [4:0]  golden_immediate;
reg        [15:0] temp_address;

always #(`CYCLE_TIME / 2.0) clk = ~clk;
reg [10:0] temp_address_int;

//---------------------------------------------------------------------
//   DRAM                         
//---------------------------------------------------------------------	

pseudo_DRAM_data u_DRAM_data(
// global signals 
      .clk(clk),
      .rst_n(rst_n),
// axi write address channel 
      .awid_s_inf(   awid_s_inf[3:0]  ),
    .awaddr_s_inf( awaddr_s_inf[31:0] ),
    .awsize_s_inf( awsize_s_inf[2:0]  ),
   .awburst_s_inf(awburst_s_inf[1:0]  ),
     .awlen_s_inf(  awlen_s_inf[6:0]  ),
   .awvalid_s_inf(awvalid_s_inf[0]    ),
   .awready_s_inf(awready_s_inf[0]    ),
// axi write data channel 
     .wdata_s_inf(  wdata_s_inf[15:0] ),
     .wlast_s_inf(  wlast_s_inf[0]    ),
    .wvalid_s_inf( wvalid_s_inf[0]    ),
    .wready_s_inf( wready_s_inf[0]    ),
// axi write response channel
       .bid_s_inf(    bid_s_inf[3:0]  ),
     .bresp_s_inf(  bresp_s_inf[1:0]  ),
    .bvalid_s_inf( bvalid_s_inf[0]    ),
    .bready_s_inf( bready_s_inf[0]    ),
// axi read address channel 
      .arid_s_inf(   arid_s_inf[3:0]  ),
    .araddr_s_inf( araddr_s_inf[31:0] ),
     .arlen_s_inf(  arlen_s_inf[6:0]  ),
    .arsize_s_inf( arsize_s_inf[2:0]  ),
   .arburst_s_inf(arburst_s_inf[1:0]  ),
   .arvalid_s_inf(arvalid_s_inf[0]    ),
   .arready_s_inf(arready_s_inf[0]    ), 
// axi read data channel 
       .rid_s_inf(    rid_s_inf[3:0]  ),
     .rdata_s_inf(  rdata_s_inf[15:0] ),
     .rresp_s_inf(  rresp_s_inf[1:0]  ),
     .rlast_s_inf(  rlast_s_inf[0]    ),
    .rvalid_s_inf( rvalid_s_inf[0]    ),
    .rready_s_inf( rready_s_inf[0]    ) 
);

pseudo_DRAM_inst u_DRAM_inst(
// global signals 
      .clk(clk),
      .rst_n(rst_n),
// axi read address channel 
      .arid_s_inf(   arid_s_inf[7:4]   ),
    .araddr_s_inf( araddr_s_inf[63:32] ),
    .arlen_s_inf(  arlen_s_inf[13:7]   ),
    .arsize_s_inf( arsize_s_inf[5:3]   ),
   .arburst_s_inf(arburst_s_inf[3:2]   ),
   .arvalid_s_inf(arvalid_s_inf[1]     ),
   .arready_s_inf(arready_s_inf[1]     ), 
// axi read data channel 
       .rid_s_inf(    rid_s_inf[7:4]   ),
     .rdata_s_inf(  rdata_s_inf[31:16] ),
     .rresp_s_inf(  rresp_s_inf[3:2]   ),
     .rlast_s_inf(  rlast_s_inf[1]     ),
    .rvalid_s_inf( rvalid_s_inf[1]     ),
    .rready_s_inf( rready_s_inf[1]     ) 
);

//---------------------------------------------------------------------
//   INITIAL                         
//---------------------------------------------------------------------
initial 
begin
    force clk = 0;
    rst_n     = 1;

    // reset
    reset_task;
    read_DRAM_data_task;
    total_cycles = 0;
    //
    @(negedge clk);
    golden_pc = 16'h1000 - 2;
    for(i_pat=1; i_pat<=2048; i_pat++)
    begin
        // 
        if(golden_pc == 16'h1ffe)
        begin
            YOU_PASS_task;
            $finish;
        end
        golden_pc = golden_pc + 2;
        golden_curr_pc = golden_pc;
        golden_inst = {u_DRAM_inst.DRAM_r[golden_curr_pc+1], u_DRAM_inst.DRAM_r[golden_curr_pc]};
        // $display("DRAM_inst @%2x : %4x", golden_curr_pc, golden_inst);
        golden_opcode    = golden_inst[15:13];
        golden_rs        = golden_inst[12:9];
        golden_rt        = golden_inst[8:5];
        golden_rd        = golden_inst[4:1];
        golden_func      = golden_inst[0];
        golden_immediate = golden_inst[4:0];
        golden_coeff_a   = golden_inst[12:9];
        golden_coeff_b   = golden_inst[8:0];
        // 
        // $display("golden_opcode   = %3b", golden_opcode  );
        // $display("golden_rs       = %d", golden_rs      );
        // $display("golden_rt       = %d", golden_rt      );
        // $display("golden_rd       = %d", golden_rd      );
        // $display("golden_func     = %b", golden_func    );
        // $display("golden_immediate = %d", golden_immediate);
        // 
        temp_address = (golden_reg[golden_rs] + golden_immediate) * 2 + offset;
        temp_address_int = (temp_address - 16'h1000) / 2;
        // 
        if     (golden_opcode === 3'b000 && golden_func === 1'b0) Add_task;
        else if(golden_opcode === 3'b000 && golden_func === 1'b1) Sub_task;
        else if(golden_opcode === 3'b001 && golden_func === 1'b0) SetLessThan_task;
        else if(golden_opcode === 3'b001 && golden_func === 1'b1) Mult_task;
        else if(golden_opcode === 3'b010)                         Load_task;
        else if(golden_opcode === 3'b011)                         Store_task;
        else if(golden_opcode === 3'b100)                         BranchOnEqual_task;
        else if(golden_opcode === 3'b111)                         Determinant_task;
        else 
        begin
            $display("Error: Wrong instruection format in PATTERN NO.%4d\t\tgolden_pc NO.%4x", i_pat+1, golden_curr_pc);
            $display("%16b", golden_inst);
        end
        // SPEC: The test pattern will check the value in all registers at clock negative edge if stall is low. 
        wait_IO_stall_task;
        // 
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m golden_pc: @%4x,\033[m \033[1;33m latency: %3d\033[m", i_pat, golden_curr_pc, cycles);
        
    end
    YOU_PASS_task;
    $finish;
end

//---------------------------------------------------------------------
//   TASK                         
//---------------------------------------------------------------------	
task wait_IO_stall_task;
    begin
        cycles = 0;
        while(IO_stall === 1)
        begin
            cycles += 1;
            if(cycles === `MAX_WAIT_READY_CYCLE)
            begin
                display_fail_task;
                // Spec. 6.  
                // IO_stall signal cannot be continuous high for 2000 cycles during functionality check, 
                // cannot be continuous high for 100000 during performance check. 
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                                SPEC 6 FAIL!                                                                ");
                $display ("                                          The execution latency is limited in %d cycles.                                                    ", `MAX_WAIT_READY_CYCLE);
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $finish;
            end
            @(negedge clk);        
        end

        total_cycles += cycles;

        check_reg_task;
        // SPEC: The test pattern will check the value in data DRAM every 10 instruction at clock negative edge if IO_stall is low. 
        if(i_pat % 10 === 0) check_DRAM_data_task;
        // SPEC: Pull high when core is busy. It should be low for one cycle whenever  you  finished  an  instruction.
        @(negedge clk);
        if(IO_stall === 0)
        begin
            display_fail_task;
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC ? FAIL!                                                                ");
            $display ("                                 IO_stall should be low for ONE cycle whenever you finished an instruction.                                 ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
    end
endtask

task check_reg_task;
    begin
        // print_reg_task;
        if( `PREFIX.core_r0 !== golden_reg[0] || `PREFIX.core_r4 !== golden_reg[4] || `PREFIX.core_r8  !== golden_reg[ 8] || `PREFIX.core_r12 !== golden_reg[12] ||
            `PREFIX.core_r1 !== golden_reg[1] || `PREFIX.core_r5 !== golden_reg[5] || `PREFIX.core_r9  !== golden_reg[ 9] || `PREFIX.core_r13 !== golden_reg[13] ||
            `PREFIX.core_r2 !== golden_reg[2] || `PREFIX.core_r6 !== golden_reg[6] || `PREFIX.core_r10 !== golden_reg[10] || `PREFIX.core_r14 !== golden_reg[14] ||
            `PREFIX.core_r3 !== golden_reg[3] || `PREFIX.core_r7 !== golden_reg[7] || `PREFIX.core_r11 !== golden_reg[11] || `PREFIX.core_r15 !== golden_reg[15])
            begin
            display_fail_task;
            $display ("--------------------------------------------------------------------------------------------");
            $display ("                                           FAIL!                                            ");
            $display ("                                 core_reg is/are not equal.                                 ");        
            print_reg_task;
            $display ("--------------------------------------------------------------------------------------------");
            @(negedge clk);
            @(negedge clk);
            $finish; 
        end
    end
endtask

task check_DRAM_data_task;
    begin
        j = 0;
        for(i=16'h1000; i<16'h2000; i=i+2)
        begin
            if(golden_DRAM_data[j] !== {u_DRAM_data.DRAM_r[i+1], u_DRAM_data.DRAM_r[i]})
            begin
                display_fail_task;
                $display ("--------------------------------------------------------------------------------------------");
                $display ("                                           FAIL!                                            ");
                $display ("                                 DRAM_data is/are not equal.                                ");        
                $display ("      golden_DRAM_data[%4h(%4d)]: %4x(%8d) , your_DRAM_data[%4h(%4d)]: %4x(%8d)               ", i, j, golden_DRAM_data[j], golden_DRAM_data[j], i, j, { u_DRAM_data.DRAM_r[i+1] , u_DRAM_data.DRAM_r[i] }, { u_DRAM_data.DRAM_r[i+1] , u_DRAM_data.DRAM_r[i] });        
                $display ("--------------------------------------------------------------------------------------------");
                #(100);
                $finish; 
            end
            j += 1;
        end
    end
endtask

task print_reg_task;
    begin
        $display ("      core_r0 = %6d  golden_reg[0] = %6d,  core_r8  = %6d  golden_reg[8 ] = %6d    ", `PREFIX.core_r0,  golden_reg[0], `PREFIX.core_r8 , golden_reg[ 8]);
        $display ("      core_r1 = %6d  golden_reg[1] = %6d,  core_r9  = %6d  golden_reg[9 ] = %6d    ", `PREFIX.core_r1,  golden_reg[1], `PREFIX.core_r9 , golden_reg[ 9]);
        $display ("      core_r2 = %6d  golden_reg[2] = %6d,  core_r10 = %6d  golden_reg[10] = %6d    ", `PREFIX.core_r2,  golden_reg[2], `PREFIX.core_r10, golden_reg[10]);
        $display ("      core_r3 = %6d  golden_reg[3] = %6d,  core_r11 = %6d  golden_reg[11] = %6d    ", `PREFIX.core_r3,  golden_reg[3], `PREFIX.core_r11, golden_reg[11]);
        $display ("      core_r4 = %6d  golden_reg[4] = %6d,  core_r12 = %6d  golden_reg[12] = %6d    ", `PREFIX.core_r4,  golden_reg[4], `PREFIX.core_r12, golden_reg[12]);
        $display ("      core_r5 = %6d  golden_reg[5] = %6d,  core_r13 = %6d  golden_reg[13] = %6d    ", `PREFIX.core_r5,  golden_reg[5], `PREFIX.core_r13, golden_reg[13]);
        $display ("      core_r6 = %6d  golden_reg[6] = %6d,  core_r14 = %6d  golden_reg[14] = %6d    ", `PREFIX.core_r6,  golden_reg[6], `PREFIX.core_r14, golden_reg[14]);
        $display ("      core_r7 = %6d  golden_reg[7] = %6d,  core_r15 = %6d  golden_reg[15] = %6d    ", `PREFIX.core_r7,  golden_reg[7], `PREFIX.core_r15, golden_reg[15]);
    end
endtask

task Add_task;
    begin
        $display("Add_task");
        golden_reg[golden_rd] = golden_reg[golden_rs] + golden_reg[golden_rt];
    end
endtask

task Sub_task;
    begin
        $display("Sub_task");
        golden_reg[golden_rd] = golden_reg[golden_rs] - golden_reg[golden_rt];
    end
endtask

task SetLessThan_task;
    begin
        $display("SetLessThan_task");
        if(golden_reg[golden_rs] < golden_reg[golden_rt]) golden_reg[golden_rd] = 1;
        else                                              golden_reg[golden_rd] = 0;
    end
endtask

task Mult_task;
    begin
        $display("Mult_task");
        golden_reg[golden_rd] = golden_reg[golden_rs] * golden_reg[golden_rt];
    end
endtask

task Load_task;
    begin
        $display("Load_task");
        golden_reg[golden_rt] = golden_DRAM_data[temp_address_int];
    end
endtask

task Store_task;
    begin
        $display("Store_task");
        golden_DRAM_data[temp_address_int] = golden_reg[golden_rt];
    end
endtask

task BranchOnEqual_task;
    begin
        $display("BranchOnEqual_task");
        if(golden_reg[golden_rs] === golden_reg[golden_rt]) golden_pc = golden_curr_pc + golden_immediate * 2;        
    end
endtask

reg signed [70:0] tmp1, tmp2, tmp3, tmp4; 
reg signed [70:0] det_tmp, det; 

task Determinant_task;
    begin
        $display("Determinant_task");

        tmp1 = golden_reg[ 0] * (golden_reg[5] * (golden_reg[10] * golden_reg[15] - golden_reg[11] * golden_reg[14]) - golden_reg[9] * (golden_reg[6] * golden_reg[15] - golden_reg[7] * golden_reg[14]) + golden_reg[13] * (golden_reg[6] * golden_reg[11] - golden_reg[7] * golden_reg[10]));
        tmp2 = golden_reg[ 4] * (golden_reg[1] * (golden_reg[10] * golden_reg[15] - golden_reg[11] * golden_reg[14]) - golden_reg[9] * (golden_reg[2] * golden_reg[15] - golden_reg[3] * golden_reg[14]) + golden_reg[13] * (golden_reg[2] * golden_reg[11] - golden_reg[3] * golden_reg[10]));
        tmp3 = golden_reg[ 8] * (golden_reg[1] * (golden_reg[ 6] * golden_reg[15] - golden_reg[ 7] * golden_reg[14]) - golden_reg[5] * (golden_reg[2] * golden_reg[15] - golden_reg[3] * golden_reg[14]) + golden_reg[13] * (golden_reg[2] * golden_reg[ 7] - golden_reg[3] * golden_reg[ 6]));
        tmp4 = golden_reg[12] * (golden_reg[1] * (golden_reg[ 6] * golden_reg[11] - golden_reg[ 7] * golden_reg[10]) - golden_reg[5] * (golden_reg[2] * golden_reg[11] - golden_reg[3] * golden_reg[10]) + golden_reg[ 9] * (golden_reg[2] * golden_reg[ 7] - golden_reg[3] * golden_reg[ 6]));

        det_tmp = tmp1 - tmp2 + tmp3 - tmp4;

        det = (det_tmp >>> (2 * golden_coeff_a));
        det += $signed({1'b0, golden_coeff_b});

        if(det > 32767)       golden_reg[0] = 32767;
        else if(det < -32768) golden_reg[0] = -32768;
        else                  golden_reg[0] = det;
        end
endtask

task read_DRAM_data_task;
    begin
        j = 0;
        for(i=16'h1000; i<16'h2000; i=i+2)
        begin
            golden_DRAM_data[j] = {u_DRAM_data.DRAM_r[i+1], u_DRAM_data.DRAM_r[i]};
            // $display("%x(%4d): %4x", i, j, golden_DRAM_data[j]);
            j += 1;
        end
    end
endtask

task reset_task;
    begin
        #(5); rst_n = 0;
        // SPEC: All the registers should be zero after the reset signal is asserted. 
        #(5);
        for(i=0;i<16;i++) golden_reg[i] = 0;
        check_reg_task;
        
        if(IO_stall !== 1)
        begin
            display_fail_task;
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                        FAIL!                                                               ");
            $display ("                                                            Output signal should be reset                                                   ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end

        #(10); rst_n = 1; 
        #(100); release clk;
    end
endtask

task YOU_PASS_task;
    begin
        $display("         ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⡀⠀⠀⣠⣄                  ");     
        $display("         ⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⠋⢈⡇⠀⣾⠁⠘⡇                 ");          
        $display("         ⠀⠀⠀⠀⠀⠀⠀⠀⢰⡏⠀⢸⡇⢸⡇⠀⢸⡇                 ");      
        $display("         ⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⢸⠁⣿⠀⠀⣾                  ");
        $display("         ⠀⠀⠀⠀⠀⠀⠀⠀⠘⣇⠀⢸⠀⣿⠀⢠⡏                  ");      
        $display("         ⠀⠀⠀⠀⠀⠀⣀⣠⡄⠹⠂⠘⠶⠟⠀⠸⠁⢤⣤⣀⡀            ");      
        $display("         ⠀⠀⠀⢀⡴⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠶⣄⡀          ");     
        $display("         ⠀⢀⣴⠋⠀⠀⢀⡴⠖⠛⠀⠀⠀⠀⠀⠈⠛⠲⣤⡀⠀⠀⠈⠻⣄        ");    
        $display("         ⠀⣾⠁⠀⠀⠀⡞⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢷⠀ ⠀⠀⠀⠹⣆       ");    
        $display("         ⢸⡇⠀⠀⠀⠀⠀⠀⣴⣋⣷⠀⠀⠀⠀⣾⣹⣧⠀⠀⠀⠀⠀⠀ ⠀⣿       ");       
        $display("         ⢾⠀⠀⠀⠀⡀⣄⣄⠈⠛⠋⠀⢠⡄⢀⠉⠋⢁⣤⢦⢄⠀⠀⠀ ⢸⠆     ");              
        $display("         ⢸⡇⠀⠀⠀⠙⠘⠈⠀⠀⠀⠙⢿⠙⠉⠀⠀⠈⠚⠘⠘⠀⠀⠀⠀⣾       ");   
        $display("         ⠀⢿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⣰⠏       ");                   
        $display("         ⠀⠀⠹⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⣀⡴⠋        "); 
        $display("         ⠀⠀⠀⢀⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⣤⢹⡀         ");           
        $display("         ⠀⠀⠀⢸⡇⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣸⡇         ");            
        $display("         ⠀⠀⠀⠀⠙⠙⣧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡼⡻⡅           ");
        $display("         ⠀⠀⠀⠀⠀⠀⠈⠻⢦⣄⣀⠀⠀⠀⠀⠀⣀⣠⡴⠟⡷⠗           ");
        $display("         ⠀⠀⠀⠀⠀⠀⠀⠀⠀⣈⣉⣹⡇⣇⣸⣋⣉⡁                ");     
        $display("         ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠙⠛⠉⠉⠉⠁                ");  
        $display ("----------------------------------------------------------------------------------------------------------------------");
        $display ("                                                  Congratulations!                                                    ");
        $display ("                                           You have passed all patterns!                                              ");
        $display ("                                                                                                                      ");
        $display ("                                        Your execution cycles   = %5d cycles                                          ", total_cycles);
        $display ("                                        Your clock period       = %.1f ns                                             ", `CYCLE_TIME);
        $display ("                                        Total latency           = %.1f ns                                             ", total_cycles*`CYCLE_TIME );
        $display ("----------------------------------------------------------------------------------------------------------------------");
        $finish;    
    end
endtask

task display_fail_task;
    begin
        $display("\033[1;31m:( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( \033[m");
    end
endtask

endmodule