`ifdef RTL
	`define CYCLE_TIME_clk1 47.1
	`define CYCLE_TIME_clk2 10.1
`endif
`ifdef GATE
	`define CYCLE_TIME_clk1 47.1
	`define CYCLE_TIME_clk2 10.1
`endif

module PATTERN(
	clk1,
	clk2,
	rst_n,
	in_valid,
	in_matrix_A,
	in_matrix_B,
	out_valid,
	out_matrix
);

output reg clk1, clk2;
output reg rst_n;
output reg in_valid;
output reg [3:0] in_matrix_A;
output reg [3:0] in_matrix_B;

input out_valid;
input [7:0] out_matrix;

//---------------------------------------------------------------------
//   PARAMETERS & INTEGER                         
//---------------------------------------------------------------------		
real	CYCLE_clk1 = `CYCLE_TIME_clk1;
real	CYCLE_clk2 = `CYCLE_TIME_clk2;

integer i, j;

integer total_latency;
integer patnum, PATNUM = 100;

integer A [0:15], B [0:15], C[0:15][0:15];

integer output_cycle;
integer overall_latency;

//---------------------------------------------------------------------
//   LOGIC                         
//---------------------------------------------------------------------	
reg [31:0] X [0:256];

//---------------------------------------------------------------------
//   CLOCK                         
//---------------------------------------------------------------------	
always #(CYCLE_clk1/2.0) clk1 = ~clk1;
always #(CYCLE_clk2/2.0) clk2 = ~clk2;

//---------------------------------------------------------------------
//   INITIAL                         
//---------------------------------------------------------------------	
initial 
begin
	$display("*                Your clock period = %.1f ns"			, CYCLE_clk1);
	overall_latency = 0;
	reset_task;
	
	@(negedge clk1);
	for (patnum = 0; patnum < PATNUM ; patnum ++) 
	begin
		random_input;
		total_latency = 0;
		send_input;
		check_output;
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m latency: %3d\033[m", patnum ,total_latency);
		// $display("**************************");
		// $display("*pass pattern %d", patnum);
		// $display("*latency: %5d", total_latency);
		// $display("**************************");
		overall_latency = overall_latency + total_latency;
		repeat($urandom_range(1,3))@(negedge clk1);
	end
	YOU_PASS_task;
end

initial 
begin
	wait (in_valid === 1 && out_valid === 1) 
	begin
		$display("*************************************************************************");
		$display("*FAIL! ! !");
    	$display("*in_valid and out_valid cannot overlap!");
		$display("*************************************************************************");
		$finish;
	end
end

// initial begin
// 	wait (output_cycle == 256 && out_valid === 1)begin
// 		$display("*************************************************************************");
// 		$display("*FAIL! ! !");
//         $display("*output cycles should be equal to 256");
// 		$display("*************************************************************************");
// 		$finish;
// 	end
// end

//---------------------------------------------------------------------
//   TASK                         
//---------------------------------------------------------------------	
task reset_task; 
begin 
    rst_n 		<= 'b1;
    in_valid 	<= 'b0;
	in_matrix_A <= 'hx;
	in_matrix_B <= 'hx;

    force clk1 = 0;
	force clk2 = 0;

    #CYCLE_clk1; rst_n = 0; 
    #CYCLE_clk1; rst_n = 1;
    
    if(out_valid !== 1'b0 || out_matrix !== 0 ) 
	begin //out!==0
		$display("*************************************************************************");
        $display("*FAIL! ! !");   
        $display("*Output signal should be 0 after initial RESET  at %8t",$time);
		$display("*************************************************************************");
        $finish;
    end
	#CYCLE_clk1; release clk1;
	#CYCLE_clk1; release clk2;
end 
endtask

task random_input; 
begin
	for (i=0; i<16; i=i+1) 
	begin
		A[i] = $urandom_range(0, 4'b1111);
		B[i] = $urandom_range(0, 4'b1111);
	end

	for (i=0; i<16; i=i+1) 
	begin
		for (j=0; j<16; j=j+1) 
		begin
			C[i][j] = A[i] * B[j];
		end
	end

	// $write("A: ");
	// for (i=0; i<16; i=i+1) begin
	// 	$write("%4d ", A[i]);	
	// end
	// $write("\n");

	// $write("B: ");
	// for (i=0; i<16; i=i+1) begin
	// 	$write("%4d ", B[i]);	
	// end
	// $write("\n");

	// $display("C: ");
	// for (i=0; i<16; i=i+1) begin
	// 	for (j=0; j<16; j=j+1) begin
	// 		$write("%2h ", C[i][j]);
	// 	end
	// 	$write("\n");
	// end
	// $write("\n");
end endtask

task send_input; 
begin
	for (i=0; i<16; i=i+1) 
	begin
		in_valid	<= 1;
		in_matrix_A <= A[i];
		in_matrix_B <= B[i];
		@(negedge clk1);
	end
	in_valid <= 0;
	in_matrix_A <= 'hx;
	in_matrix_B <= 'hx;
end 
endtask


task check_output;
begin
	output_cycle = 0;
	while(output_cycle < 256)
	begin
		if(out_valid === 1)
		begin
			if(out_matrix !== C[output_cycle / 16][output_cycle % 16])
			begin
				$display("*************************************************************************");
				$display("time:	", $time());
				$display("*FAIL! ! !*");
				$display("*wrong output at C[%2d][%2d]", output_cycle / 16, output_cycle % 16);
				$display("*golden answer : %h", C[output_cycle / 16][output_cycle % 16]);
				$display("*Your answer : %h", out_matrix);
				$display("*************************************************************************");
				$finish;
			end

			output_cycle = output_cycle + 1;
		end
		total_latency = total_latency + 1;
		@(negedge clk1);

		if(total_latency > 5000)
		begin
			$display("output_cycle = %d", output_cycle);
			$display("*************************************************************************");
			$display("*FAIL! ! !");
			$display("*latency is larger than 5000 cycle in clk1!");
			$display("*************************************************************************");
			$finish;
		end
	end
end
endtask

task YOU_PASS_task; 
begin
	display_pass_task;
    $display("*************************************************************************");
    $display("*                         Congratulations!                              ");
    $display("*                Your execution cycles = %5d cycles"	, overall_latency);
    $display("*                clk1 period = %.1f ns"			, CYCLE_clk1);
    $display("*                Total Latency = %.1f ns          "	, overall_latency*CYCLE_clk1);
    $display("*************************************************************************");
    $finish;
end 
endtask

task display_pass_task; 
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
end 
endtask

endmodule
