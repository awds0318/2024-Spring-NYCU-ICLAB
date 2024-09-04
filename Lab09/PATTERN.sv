/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2024 Spring IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Apr-2024)
Author : Jui-Huang Tsai (erictsai.ee12@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//---------------------------------------------------------------------
//   PARAMETERS & INTEGER                         
//---------------------------------------------------------------------
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";

parameter PAT_NUM  = 4200;
// parameter PAT_NUM  = 3600;
parameter CLK_TIME = 2.2;

integer N;
integer SEED = 42;
integer total_lat, lat;
integer i, i_pat;

//---------------------------------------------------------------------
//   LOGIC                         
//---------------------------------------------------------------------	
logic [7:0]  golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box

Action       given_action;
Order_Info   given_bev;
Date         given_date;
Barrel_No    given_box_no;
ING          given_black, given_green, given_milk, given_pineapple;
ING          black, green, milk, pineapple;                         // for make drinnk
logic [12:0] black_temp, green_temp, milk_temp, pineapple_temp;     // for supply

logic [63:0] bal_temp;
Bev_Bal      golden_bal;

Error_Msg    golden_err_msg;
logic        golden_complete;

//---------------------------------------------------------------------
//   CLASS RANDOM                         
//---------------------------------------------------------------------
class random_action;
	randc Action action;

	function new (int seed);
		this.srandom(seed);
	endfunction

	constraint limit{
        action inside{Make_drink, Supply, Check_Valid_Date};
    }
endclass

class random_beverage;
    randc Order_Info bev;

	function new (int seed);
		this.srandom(seed);
	endfunction

    constraint limit{
        bev.Bev_Size_O inside{L, M, S};
        (bev.Bev_Size_O == L) -> bev.Bev_Type_O inside{Black_Tea, Milk_Tea, Extra_Milk_Tea, Green_Tea, Green_Milk_Tea, Pineapple_Juice, Super_Pineapple_Tea, Super_Pineapple_Milk_Tea};
        (bev.Bev_Size_O == M) -> bev.Bev_Type_O inside{Black_Tea, Milk_Tea, Extra_Milk_Tea, Green_Tea, Green_Milk_Tea, Pineapple_Juice, Super_Pineapple_Tea, Super_Pineapple_Milk_Tea};
        (bev.Bev_Size_O == S) -> bev.Bev_Type_O inside{Black_Tea, Milk_Tea, Extra_Milk_Tea, Green_Tea, Green_Milk_Tea, Pineapple_Juice, Super_Pineapple_Tea, Super_Pineapple_Milk_Tea};
    }
endclass

class random_date;
	randc Date date;

	function new (int seed);
		this.srandom(seed);
	endfunction

	constraint limit{
		date.M inside{[1:12]};
        (date.M == 1 || date.M == 3 || date.M == 5 || date.M == 7 || date.M == 8 || date.M == 10 || date.M == 12) -> date.D inside{[1:31]};
		(date.M == 4 || date.M == 6 || date.M == 9 || date.M == 11)                                               -> date.D inside{[1:30]};
		(date.M == 2)                                                                                             -> date.D inside{[1:28]};
	}
endclass

class random_box_no;
	randc Barrel_No box_no;

	function new (int seed);
		this.srandom(seed);
	endfunction

	constraint limit{
		box_no inside{[0:255]};
	}
endclass

class random_box_sup;
	randc ING box_ing;

	function new (int seed);
		this.srandom(seed);
	endfunction

	constraint limit{
		box_ing inside{[0:4095]};
	}
endclass

random_action   r_action;
random_beverage r_beverage;
random_date     r_date;
random_box_no   r_box_no;
random_box_sup  r_box_sup;

//---------------------------------------------------------------------
//   INITIAL                         
//---------------------------------------------------------------------	
initial 
begin
    r_action   = new(SEED);
    r_beverage = new(SEED);
    r_date     = new(SEED);
    r_box_no   = new(SEED);
    r_box_sup  = new(SEED);

    $readmemh(DRAM_p_r, golden_DRAM);
    reset_signal_task;

    for (i_pat=0;i_pat<PAT_NUM;i_pat++) 
	begin
        input_task;
        wait_out_valid_task;  
        check_ans_task;      
        total_lat += lat;
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m latency: %3d\033[m", i_pat, lat);
    end
    YOU_PASS_task;
end

//---------------------------------------------------------------------
//   TASK                         
//---------------------------------------------------------------------	
task reset_signal_task; 
begin 
    inf.rst_n            = 1;
    inf.sel_action_valid = 0;
	inf.type_valid       = 0;
	inf.size_valid       = 0;
	inf.date_valid       = 0;
	inf.box_no_valid     = 0;
	inf.box_sup_valid    = 0;
    inf.D                = 'bx;
	total_lat            = 0;

    #5;  inf.rst_n = 0; 
    #20; inf.rst_n = 1;
end 
endtask

// ----------------------------------------- input task --------------------------------------- //
task input_task; 
begin
    // repeat($urandom_range(1, 4)) @(negedge clk);
	@(negedge clk)

    give_action;

    if(given_action == Make_drink)
    begin
        give_beverage;
        give_date;
        give_box_no;
    end
    else if(given_action == Supply)
    begin
        give_date;
        give_box_no;
        give_box_sup;
    end
    else
    begin
        give_date;
        give_box_no;
    end

    // case (given_action)
    //     Make_drink:
    //     begin
    //         give_beverage;
    //         give_date;
    //         give_box_no;
    //     end
    //     Supply:
    //     begin
    //         give_date;
    //         give_box_no;
    //         give_box_sup;
    //     end
    //     Check_Valid_Date:
    //     begin
    //         give_date;
	// 		give_box_no;
    //     end
    // endcase
end 
endtask

task give_action; 
begin 
    // i = r_action.randomize(); given_action = r_action.action;

    inf.sel_action_valid = 1;
	// inf.D.d_act[0]       = given_action;

    if(i_pat < 1200)
    begin
        case(i_pat % 6)
            0: inf.D.d_act[0] = Make_drink;
            1: inf.D.d_act[0] = Supply;
            2: inf.D.d_act[0] = Check_Valid_Date;
            3: inf.D.d_act[0] = Make_drink;
            4: inf.D.d_act[0] = Check_Valid_Date;
            5: inf.D.d_act[0] = Supply;
        endcase
    end
    else if(i_pat < 1401) inf.D.d_act[0] = Check_Valid_Date;
    else if(i_pat < 1602) inf.D.d_act[0] = Supply;
    else                  inf.D.d_act[0] = Make_drink;

    given_action = inf.D.d_act[0];

	@(negedge clk); 
	inf.sel_action_valid = 0;
	inf.D = 'bx;
end 
endtask

task give_beverage; 
begin 
    i = r_beverage.randomize(); given_bev = r_beverage.bev;
	
	inf.type_valid  = 1;
	inf.D.d_type[0] = given_bev.Bev_Type_O;

	@(negedge clk); 
	inf.type_valid  = 0;
	inf.D           = 'bx;

	// repeat($urandom_range(1, 4)) @(negedge clk);
	inf.size_valid  = 1;
	inf.D.d_size[0] = given_bev.Bev_Size_O;

	@(negedge clk); 
	inf.size_valid  = 0;
	inf.D           = 'bx;
end 
endtask

task give_date; 
begin 
    i = r_date.randomize(); given_date = r_date.date;

	inf.date_valid  = 1;
    inf.D.d_date[0] = given_date;

	@(negedge clk); 
	inf.date_valid  = 0;
	inf.D           = 'bx;
end 
endtask

task give_box_no; 
begin 
    i = r_box_no.randomize(); given_box_no = r_box_no.box_no;
	
	inf.box_no_valid  = 1;
    inf.D.d_box_no[0] = given_box_no;

	@(negedge clk); 
	inf.box_no_valid  = 0;
	inf.D             = 'bx;
end 
endtask

task give_box_sup; 
begin 
    i = r_box_sup.randomize(); given_black     = r_box_sup.box_ing;
    i = r_box_sup.randomize(); given_green     = r_box_sup.box_ing;
    i = r_box_sup.randomize(); given_milk      = r_box_sup.box_ing;
    i = r_box_sup.randomize(); given_pineapple = r_box_sup.box_ing;
	
	inf.box_sup_valid = 1;
	inf.D.d_ing[0]    = given_black;

	@(negedge clk); 
	inf.box_sup_valid = 0;
	inf.D             = 'bx;
	
	// repeat($urandom_range(0, 3)) @(negedge clk);

	inf.box_sup_valid = 1;
	inf.D.d_ing[0]    = given_green;

	@(negedge clk); 
	inf.box_sup_valid = 0;
	inf.D             = 'bx;
	
	// repeat($urandom_range(0, 3)) @(negedge clk);
	
	inf.box_sup_valid = 1;
	inf.D.d_ing[0]    = given_milk;

	@(negedge clk); 
	inf.box_sup_valid = 0;
	inf.D             = 'bx;
		
	// repeat($urandom_range(0, 3)) @(negedge clk);

	inf.box_sup_valid = 1;
	inf.D.d_ing[0]    = given_pineapple;

	@(negedge clk); 
	inf.box_sup_valid = 0;
	inf.D             = 'bx;
end 
endtask

// ------------------------------------- wait out_valid task ---------------------------------- //
task wait_out_valid_task; 
begin
    lat = 0;
    while(inf.out_valid !== 1) 
    begin
        lat += 1;
        if(lat === 1000) 
        begin
            $display("--------------------------------------------------------------------------------------------------------------------------------------------");
            // $display("                                                                 FAIL!                                                                      ");
            $display("                                                              Wrong Answer!                                                                 ");
            $display("                                                             PATTERN NO.%4d 	                                                              ", i_pat);
            $display("                                             The execution latency should not over 1000 cycle                                               ");
            $display("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
        end
        @(negedge clk);
    end
end
endtask

// --------------------------------------- check ans task ------------------------------------- //
task check_ans_task;
begin
    N = 65536 + 8 * given_box_no;
    bal_temp = {golden_DRAM[N+7], golden_DRAM[N+6], golden_DRAM[N+5], golden_DRAM[N+4], golden_DRAM[N+3], golden_DRAM[N+2], golden_DRAM[N+1], golden_DRAM[N]};

	golden_bal.black_tea       = bal_temp[63:52];
	golden_bal.green_tea       = bal_temp[51:40];
	golden_bal.M               = bal_temp[39:32];
	golden_bal.milk            = bal_temp[31:20];
	golden_bal.pineapple_juice = bal_temp[19: 8];
	golden_bal.D               = bal_temp[ 7: 0];

	case(given_action)
		Make_drink:       make_drink_task;
		Supply:           supply_task;
		Check_Valid_Date: check_date_task;
	endcase
end
endtask 

task make_drink_task; 
begin
    black     = 0;
    green     = 0;
    milk      = 0;
    pineapple = 0;

    case (given_bev.Bev_Type_O)
        Black_Tea:                black = (given_bev.Bev_Size_O == L)? 960 : ((given_bev.Bev_Size_O == M)? 720 : 480);
        Milk_Tea:                 black = (given_bev.Bev_Size_O == L)? 720 : ((given_bev.Bev_Size_O == M)? 540 : 360); 
        Extra_Milk_Tea:           black = (given_bev.Bev_Size_O == L)? 480 : ((given_bev.Bev_Size_O == M)? 360 : 240);
        Super_Pineapple_Tea:      black = (given_bev.Bev_Size_O == L)? 480 : ((given_bev.Bev_Size_O == M)? 360 : 240);
        Super_Pineapple_Milk_Tea: black = (given_bev.Bev_Size_O == L)? 480 : ((given_bev.Bev_Size_O == M)? 360 : 240);
    endcase

    case (given_bev.Bev_Type_O)
        Green_Tea:      green = (given_bev.Bev_Size_O == L)? 960 : ((given_bev.Bev_Size_O == M)? 720 : 480);
        Green_Milk_Tea: green = (given_bev.Bev_Size_O == L)? 480 : ((given_bev.Bev_Size_O == M)? 360 : 240);
    endcase

    case (given_bev.Bev_Type_O)
        Milk_Tea:                 milk = (given_bev.Bev_Size_O == L)? 240 : ((given_bev.Bev_Size_O == M)? 180 : 120);
        Extra_Milk_Tea:           milk = (given_bev.Bev_Size_O == L)? 480 : ((given_bev.Bev_Size_O == M)? 360 : 240);
        Green_Milk_Tea:           milk = (given_bev.Bev_Size_O == L)? 480 : ((given_bev.Bev_Size_O == M)? 360 : 240);
        Super_Pineapple_Milk_Tea: milk = (given_bev.Bev_Size_O == L)? 240 : ((given_bev.Bev_Size_O == M)? 180 : 120);
    endcase

    case (given_bev.Bev_Type_O)
        Pineapple_Juice:          pineapple = (given_bev.Bev_Size_O == L)? 960 : ((given_bev.Bev_Size_O == M)? 720 : 480);
        Super_Pineapple_Tea:      pineapple = (given_bev.Bev_Size_O == L)? 480 : ((given_bev.Bev_Size_O == M)? 360 : 240);
        Super_Pineapple_Milk_Tea: pineapple = (given_bev.Bev_Size_O == L)? 240 : ((given_bev.Bev_Size_O == M)? 180 : 120);
    endcase

    if(given_date.M > golden_bal.M || (given_date.M === golden_bal.M && given_date.D > golden_bal.D))
        golden_err_msg = No_Exp;
    else if(black > golden_bal.black_tea || green > golden_bal.green_tea || milk > golden_bal.milk || pineapple > golden_bal.pineapple_juice) 
        golden_err_msg = No_Ing;
    else 
        golden_err_msg = No_Err;

    if(golden_err_msg === No_Err) golden_complete = 1;
	else                          golden_complete = 0;

    bal_temp[63:52] = golden_bal.black_tea       - black;    
    bal_temp[51:40] = golden_bal.green_tea       - green;    
    bal_temp[31:20] = golden_bal.milk            - milk;     
    bal_temp[19: 8] = golden_bal.pineapple_juice - pineapple;

    if(golden_err_msg === No_Err) {golden_DRAM[N+7], golden_DRAM[N+6], golden_DRAM[N+5], golden_DRAM[N+4], golden_DRAM[N+3], golden_DRAM[N+2], golden_DRAM[N+1], golden_DRAM[N]} = bal_temp;

    check_task;
end 
endtask

task supply_task; 
begin

    black_temp     = golden_bal.black_tea       + given_black;  
    green_temp     = golden_bal.green_tea       + given_green;    
    milk_temp      = golden_bal.milk            + given_milk;     
    pineapple_temp = golden_bal.pineapple_juice + given_pineapple;

    if(black_temp > 4095 || green_temp > 4095 || milk_temp > 4095 || pineapple_temp > 4095) golden_err_msg = Ing_OF;
    else                                                                                    golden_err_msg = No_Err;

    if(golden_err_msg === No_Err) golden_complete = 1;
	else                          golden_complete = 0;

    bal_temp[39:32] = given_date.M;
    bal_temp[ 7: 0] = given_date.D;
    bal_temp[63:52] = (black_temp     > 4095)? 4095 : black_temp;   
    bal_temp[51:40] = (green_temp     > 4095)? 4095 : green_temp;   
    bal_temp[31:20] = (milk_temp      > 4095)? 4095 : milk_temp;     
    bal_temp[19: 8] = (pineapple_temp > 4095)? 4095 : pineapple_temp;

    {golden_DRAM[N+7], golden_DRAM[N+6], golden_DRAM[N+5], golden_DRAM[N+4], golden_DRAM[N+3], golden_DRAM[N+2], golden_DRAM[N+1], golden_DRAM[N]} = bal_temp;

    check_task;
end 
endtask

task check_date_task; 
begin
    if(given_date.M > golden_bal.M || (given_date.M === golden_bal.M && given_date.D > golden_bal.D)) golden_err_msg = No_Exp;
    else                                                                                              golden_err_msg = No_Err;

    if(golden_err_msg === No_Err) golden_complete = 1;
	else                          golden_complete = 0;

    check_task;
end 
endtask

task check_task; 
begin
    if((inf.err_msg !== golden_err_msg) || (inf.complete !== golden_complete)) 
    begin
        $display("-----------------------------------------------------------------------------------------------------------------------------------------");
        // $display("                                                                 FAIL!                                                                   ");
        $display("                                                              Wrong Answer                                                               ");
        $display("                                                             PATTERN NO.%4d 	                                                           ", i_pat);
        $display("                                              err_msg should be : %d , your answer is : %d                                               ", golden_err_msg, inf.err_msg);
        $display("                                             complete should be : %d , your answer is : %d                                               ", golden_complete, inf.complete);
        $display("-----------------------------------------------------------------------------------------------------------------------------------------");
        $finish;
    end
end 
endtask

task YOU_PASS_task; 
begin
	display_pass_task;
    $display("-----------------------------------------------------------------------------------------------------------------------------------------");
    $display("                                                               Congratulations                 						                   ");
    $display("                                                         Your execution cycles = %5d cycles                                              ", total_lat);
    $display("                                                         Your clock period = %.1f ns                                                     ", CLK_TIME);
    $display("                                                         Total Latency = %.1f ns                                                         ", total_lat * CLK_TIME);
    $display("-----------------------------------------------------------------------------------------------------------------------------------------"); 
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

endprogram
