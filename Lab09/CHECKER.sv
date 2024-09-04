/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2024 Spring IC Design Laboratory 
Lab09: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Apr-2024)
Author : Jui-Huang Tsai (erictsai.ee12@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//---------------------------------------------------------------------
//   MESSAGE
//---------------------------------------------------------------------
// Should use %0s
logic [46*8:1] MESSAGE1 = "\033[31m--- Assertion 1 is violated ---\033[0m";
logic [46*8:1] MESSAGE2 = "\033[31m--- Assertion 2 is violated ---\033[0m";
logic [46*8:1] MESSAGE3 = "\033[31m--- Assertion 3 is violated ---\033[0m";
logic [46*8:1] MESSAGE4 = "\033[31m--- Assertion 4 is violated ---\033[0m";
logic [46*8:1] MESSAGE5 = "\033[31m--- Assertion 5 is violated ---\033[0m";
logic [46*8:1] MESSAGE6 = "\033[31m--- Assertion 6 is violated ---\033[0m";
logic [46*8:1] MESSAGE7 = "\033[31m--- Assertion 7 is violated ---\033[0m";
logic [46*8:1] MESSAGE8 = "\033[31m--- Assertion 8 is violated ---\033[0m";
logic [46*8:1] MESSAGE9 = "\033[31m--- Assertion 9 is violated ---\033[0m";

//---------------------------------------------------------------------
//   COVERAGE PART
//---------------------------------------------------------------------
class BEV;
    Bev_Type bev_type;
    Bev_Size bev_size;
endclass

BEV bev_info = new();
always_ff @(posedge clk) if(inf.type_valid) bev_info.bev_type = inf.D.d_type[0];
always_ff @(posedge clk) if(inf.size_valid) bev_info.bev_size = inf.D.d_size[0];

// 1. Each case of Beverage_Type should be select at least 100 times.
covergroup Spec1 @(posedge clk iff(inf.type_valid));
    option.per_instance = 1;
    option.at_least     = 100;
    coverpoint bev_info.bev_type{
        bins type_bin [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
endgroup

// 2. Each case of Bererage_Size should be select at least 100 times.
covergroup Spec2 @(posedge clk iff(inf.size_valid));
    option.per_instance = 1;
    option.at_least     = 100;
    coverpoint bev_info.bev_size{
        bins size_bin [] = {[L:S]};
    }
endgroup

// 3. Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times. 
// (Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
covergroup Spec3 @(posedge clk iff(inf.size_valid));
    option.per_instance = 1;
    option.at_least     = 100;
    coverpoint bev_info.bev_type;
    coverpoint bev_info.bev_size;
	cross bev_info.bev_type, bev_info.bev_size;
endgroup

// 4. Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
covergroup Spec4 @(posedge clk iff(inf.out_valid));
    option.per_instance = 1;
    option.at_least     = 20;
    coverpoint inf.err_msg{
        bins err_msg_bin [] = {[No_Err:Ing_OF]};
    }
endgroup

// 5. Create the transitions bin for the inf.D.act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
covergroup Spec5 @(posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1;
    option.at_least     = 200;
    coverpoint inf.D.d_act[0]{
        bins action_bin [] = ([Make_drink:Check_Valid_Date]=>[Make_drink:Check_Valid_Date]);
    }
endgroup

// 6. Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
covergroup Spec6 @(posedge clk iff(inf.box_sup_valid));
    option.per_instance = 1;
    option.at_least     = 1;
    coverpoint inf.D.d_ing[0]{
        option.auto_bin_max = 32;
    }
endgroup

// Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
Spec1 spec1 = new();
Spec2 spec2 = new();
Spec3 spec3 = new();
Spec4 spec4 = new();
Spec5 spec5 = new();
Spec6 spec6 = new();

//---------------------------------------------------------------------
//   ASSERATION
//---------------------------------------------------------------------
logic       rst_n_delay;
Action      action;
logic [2:0] total_num_of_valid;
logic       busy;

// 1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
assign #(0.5) rst_n_delay = inf.rst_n; // always_comb doesn't support delay

assertion1: assert property (reset_check) else $fatal(0, "%0s", MESSAGE1);

property reset_check;
	@(negedge rst_n_delay) inf.rst_n === 0 |-> inf.out_valid === 0 && inf.err_msg === 0 && inf.complete === 0 && inf.C_addr === 0 && inf.C_data_w === 0 && inf.C_in_valid === 0 && inf.C_r_wb === 0 && inf.C_out_valid === 0 && inf.C_data_r === 0 && inf.AR_VALID === 0 && inf.AR_ADDR === 0 && inf.R_READY === 0 && inf.AW_VALID === 0 && inf.AW_ADDR === 0 && inf.W_VALID === 0 && inf.W_DATA === 0 && inf.B_READY === 0;
endproperty

// 2. Latency should be less than 1000 cycles for each operation.
assertion2: assert property (latency_check) else $fatal(0, "%0s", MESSAGE2);

property latency_check;
	@(posedge clk) inf.sel_action_valid |-> ##[1:1000] inf.out_valid;
endproperty

// 3. If out_valid does not pull up, complete should be 0. (If complete == 1, err_msg should be No_Err.)
assertion3: assert property (complete_check) else $fatal(0, "%0s", MESSAGE3);

property complete_check;
	@(negedge clk) (inf.complete && inf.out_valid) |-> inf.err_msg === No_Err;
endproperty

// 4. Next input valid will be valid 1-4 cycles after previous input valid fall.
always_ff @(posedge clk) if(inf.sel_action_valid) action = inf.D.d_act[0];

assertion4: assert property (action_check and make_drink_check and supply_check and date_check) else $fatal(0, "%0s", MESSAGE4);

property action_check;
	@(posedge clk) inf.sel_action_valid |-> ##[1:4] (inf.type_valid || inf.date_valid);
endproperty

property make_drink_check;
	@(posedge clk) (action === Make_drink && inf.type_valid) |-> ##[1:4] inf.size_valid ##[1:4] inf.date_valid ##[1:4] inf.box_no_valid;
endproperty

property supply_check;
	@(posedge clk) (action === Supply && inf.date_valid) |-> ##[1:4] inf.box_no_valid ##[1:4] inf.box_sup_valid ##[1:4] inf.box_sup_valid ##[1:4] inf.box_sup_valid ##[1:4] inf.box_sup_valid;
endproperty

property date_check;
	@(posedge clk) (action === Check_Valid_Date && inf.date_valid) |-> ##[1:4] inf.box_no_valid;
endproperty

// 5. All input valid signals won't overlap with each other. 
always_comb total_num_of_valid = inf.sel_action_valid + inf.type_valid + inf.size_valid + inf.date_valid + inf.box_no_valid + inf.box_sup_valid;

assertion5: assert property (overlap_check) else $fatal(0, "%0s", MESSAGE5);

property overlap_check;
	@(posedge clk) total_num_of_valid <= 1;
endproperty

// 6. Out_valid can only be high for exactly one cycle.
assertion6: assert property (out_valid_check) else $fatal(0, "%0s", MESSAGE6);

property out_valid_check;
	@(posedge clk) inf.out_valid |=> inf.out_valid === 0;
endproperty

// 7. Next operation will be valid 1-4 cycles after out_valid fall.
assertion7: assert property (selection_valid_check) else $fatal(0, "%0s", MESSAGE7);

property selection_valid_check;
	@(negedge clk) inf.out_valid |=> ##[1:4] inf.sel_action_valid;
endproperty

// 8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
assertion8: assert property (calendar_check) else $fatal(0, "%0s", MESSAGE8);

property calendar_check;
    @(posedge clk) inf.date_valid |-> (
        ((inf.D.d_date[0].M === 1 || inf.D.d_date[0].M === 3 || inf.D.d_date[0].M === 5 || inf.D.d_date[0].M === 7 || inf.D.d_date[0].M === 8 || inf.D.d_date[0].M === 10 || inf.D.d_date[0].M === 12) && (1 <= inf.D.d_date[0].D && inf.D.d_date[0].D <= 31)) ||
        ((inf.D.d_date[0].M === 4 || inf.D.d_date[0].M === 6 || inf.D.d_date[0].M === 9 || inf.D.d_date[0].M === 11)                                                                                   && (1 <= inf.D.d_date[0].D && inf.D.d_date[0].D <= 30)) || 
        ((inf.D.d_date[0].M === 2)                                                                                                                                                                     && (1 <= inf.D.d_date[0].D && inf.D.d_date[0].D <= 28))
     );
endproperty

// 9. C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid
always_ff @(posedge clk) 
begin
    if(inf.C_in_valid)       busy = 1;
    else if(inf.C_out_valid) busy = 0;
end

assertion9: assert property (in_valid_check) else $fatal(0, "%0s", MESSAGE9);

property in_valid_check;
	@(posedge clk) (inf.C_in_valid || busy) |=> inf.C_in_valid === 0;
endproperty

endmodule