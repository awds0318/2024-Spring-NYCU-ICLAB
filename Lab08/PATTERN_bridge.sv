/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2024 Spring IC Design Laboratory 
Lab08: SystemVerilog Design and Verification 
File Name   : PATTERN_bridge.sv
Module Name : PATTERN_bridge
Release version : v1.0 (Release Date: Apr-2024)
Author : Jui-Huang Tsai (erictsai.ee12@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"

program automatic PATTERN_bridge(input clk, INF.PATTERN_bridge inf);
import usertype::*;

initial 
begin
    wait(inf.rst_n == 0)
    #10;
    reset_signal_task;
end

task reset_signal_task; 
begin 
	if(inf.C_out_valid !== 0 || inf.C_data_r !== 0 || inf.AR_VALID !== 0 || inf.AR_ADDR !== 0 || inf.R_READY !== 0 || inf.AW_VALID !== 0 || inf.AW_ADDR !== 0 || inf.W_VALID !== 0 || inf.W_DATA !== 0 || inf.B_READY !== 0) 
	begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                        FAIL!                                                               ");
		$display ("                                                  Output signal should be 0 after initial RESET at %8t                                      ",$time);
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
	    $finish ;
	end
end 
endtask

endprogram
