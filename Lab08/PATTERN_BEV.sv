`include "Usertype_BEV.sv"

program automatic PATTERN_BEV(input clk, INF.PATTERN_BEV inf);
import usertype::*;

initial 
begin
    wait(inf.rst_n == 0)
    #10;
    reset_signal_task;
end

task reset_signal_task; 
begin 
	if(inf.out_valid !== 0 || inf.err_msg !== 0 || inf.complete !== 0 || inf.C_addr !== 0 || inf.C_data_w !== 0 || inf.C_in_valid !== 0 || inf.C_r_wb !== 0)
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