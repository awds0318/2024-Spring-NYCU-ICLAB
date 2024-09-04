module BEV(input clk, INF.BEV_inf inf);
import usertype::*;
// This file contains the definition of several state machines used in the BEV (Beverage) System RTL design.
// The state machines are defined using SystemVerilog enumerated types.
// The state machines are:
// - state_t: used to represent the overall state of the BEV system
//
// Each enumerated type defines a set of named states that the corresponding process can be in.

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
typedef enum logic [2:0] {IDLE, MAKE_DRINK, SUPPLY, CHECK_DATE, WAIT_BUSY, WAIT_OUT} state_t;
state_t cs;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [1:0] cnt;  // inf.box_sup_valid will high 4 times

logic [7:0] black, green, milk, pineapple;

logic [1:0] action;
logic [2:0] bev_type;
logic [1:0] bev_size;
logic [8:0] date;      // Month 4 bits + Day 5 bits

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

// -------------------------------------------- FSM ------------------------------------------- //
always_ff @(posedge clk) cnt <= (cs == SUPPLY)? ((inf.box_sup_valid)? cnt + 1 : cnt) : 0;

always_ff @(posedge clk or negedge inf.rst_n) 
begin: FSM
    if(!inf.rst_n) cs <= IDLE;
    else 
    begin
        case(cs)
            IDLE: 
            begin
                if(inf.sel_action_valid) 
                begin
                    case(inf.D.d_act[0])
                        Make_drink:       cs <= MAKE_DRINK;
                        Supply:           cs <= SUPPLY;
                        Check_Valid_Date: cs <= CHECK_DATE;
                    endcase
                end
            end
            MAKE_DRINK: if(inf.box_no_valid)              cs <= WAIT_BUSY;
            SUPPLY:     if(inf.box_sup_valid && cnt == 3) cs <= WAIT_BUSY;
            CHECK_DATE: if(inf.box_no_valid)              cs <= WAIT_BUSY; 
            WAIT_BUSY:  if(!inf.C_data_r[2])              cs <= WAIT_OUT;    // wait until c_data_r[2] down
            WAIT_OUT:   if(inf.C_out_valid)               cs <= IDLE;
        endcase
    end
end

// -------------------------------------- store input data ------------------------------------ //
always_ff @(posedge clk or negedge inf.rst_n) action   <= (!inf.rst_n)? 0 : ((inf.sel_action_valid)? inf.D.d_act [0] : action  );
always_ff @(posedge clk or negedge inf.rst_n) bev_type <= (!inf.rst_n)? 0 : ((inf.type_valid)?       inf.D.d_type[0] : bev_type);
always_ff @(posedge clk or negedge inf.rst_n) bev_size <= (!inf.rst_n)? 0 : ((inf.size_valid)?       inf.D.d_size[0] : bev_size);
always_ff @(posedge clk or negedge inf.rst_n) date     <= (!inf.rst_n)? 0 : ((inf.date_valid)?       inf.D.d_date[0] : date    );

// divide 4 for every volume
always_comb
begin
    black = 0;
    case (bev_type)
        Black_Tea:                black = (bev_size == L)? 240 : ((bev_size == M)? 180 : 120);
        Milk_Tea:                 black = (bev_size == L)? 180 : ((bev_size == M)? 135 : 90 ); 
        Extra_Milk_Tea:           black = (bev_size == L)? 120 : ((bev_size == M)? 90  : 60 );
        Super_Pineapple_Tea:      black = (bev_size == L)? 120 : ((bev_size == M)? 90  : 60 );
        Super_Pineapple_Milk_Tea: black = (bev_size == L)? 120 : ((bev_size == M)? 90  : 60 );
    endcase
end

always_comb
begin
    green = 0;
    case (bev_type)
        Green_Tea:      green = (bev_size == L)? 240 : ((bev_size == M)? 180 : 120);
        Green_Milk_Tea: green = (bev_size == L)? 120 : ((bev_size == M)? 90  : 60 );
    endcase
end

always_comb
begin
    milk = 0;
    case (bev_type)
        Milk_Tea:                 milk = (bev_size == L)? 60  : ((bev_size == M)? 45 : 30);
        Extra_Milk_Tea:           milk = (bev_size == L)? 120 : ((bev_size == M)? 90 : 60);
        Green_Milk_Tea:           milk = (bev_size == L)? 120 : ((bev_size == M)? 90 : 60);
        Super_Pineapple_Milk_Tea: milk = (bev_size == L)? 60  : ((bev_size == M)? 45 : 30);
    endcase
end

always_comb
begin
    pineapple = 0;
    case (bev_type)
        Pineapple_Juice:          pineapple = (bev_size == L)? 240 : ((bev_size == M)? 180 : 120);
        Super_Pineapple_Tea:      pineapple = (bev_size == L)? 120 : ((bev_size == M)? 90  : 60 );
        Super_Pineapple_Milk_Tea: pineapple = (bev_size == L)? 60  : ((bev_size == M)? 45  : 30 );
    endcase
end

// -------------------------------------- Output to User -------------------------------------- //
// out_valid, err_msg, complete

always_ff @(posedge clk or negedge inf.rst_n) 
begin: USR_OUTPUT
    if(!inf.rst_n)
    begin
        inf.out_valid <= 0;
        inf.err_msg   <= 0;   
        inf.complete  <= 0;
    end
    else
    begin
        inf.out_valid <= (inf.C_out_valid)? 1 : 0;
        inf.err_msg   <= (inf.C_out_valid)?  inf.C_data_r[1:0] : 0;
        inf.complete  <= (inf.C_out_valid)? !inf.C_data_r[1:0] : 0;
    end    
end

// -------------------------------------- Output to AXI --------------------------------------- //
// C_addr, C_data_w, C_in_valid, C_r_wb

always_comb inf.C_r_wb = 0;

always_ff @(posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) inf.C_in_valid <= 0;
    else           inf.C_in_valid <= (cs == WAIT_BUSY && !inf.C_data_r[2])? 1 : 0;    // wait until c_data_r[2] down  
end

always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n) inf.C_addr <= 0;
    else           inf.C_addr <= (inf.box_no_valid)? inf.D.d_box_no[0] : inf.C_addr;
end

always_comb inf.C_data_w[63:62] = action;
always_comb inf.C_data_w[61:59] = bev_type;
always_comb inf.C_data_w[58:57] = bev_size;
always_comb inf.C_data_w[56:48] = date;
always_comb inf.C_data_w[47:40] = 0;

always_ff @(posedge clk or negedge inf.rst_n) 
begin
    if(!inf.rst_n) 
        inf.C_data_w[39: 0] <= 0;
    else if(inf.box_sup_valid) 
    begin
        inf.C_data_w[ 9: 0] <= inf.D.d_ing[0][11:2];
        inf.C_data_w[39:10] <= inf.C_data_w[29:0];   
    end
    else if(cs == MAKE_DRINK)
    begin
        inf.C_data_w[39:30] <= black;
        inf.C_data_w[29:20] <= green;
        inf.C_data_w[19:10] <= milk;
        inf.C_data_w[ 9: 0] <= pineapple;
    end
end

endmodule 

// Cycle: 2.20
// Area: 8543.203225
// Gate count: 856