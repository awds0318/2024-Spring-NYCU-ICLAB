#======================================================
#  Global Parameters
#======================================================
set DESIGN "SORT_IP_demo"
set CYCLE 20
set INPUT_DLY [expr 0.5*$CYCLE]
set OUTPUT_DLY [expr 0.5*$CYCLE]
#======================================================
#  Read RTL Code
#======================================================
# (B-1) analyze + elaborate
set hdlin_auto_save_templates TRUE
analyze -f sverilog $DESIGN\.v 
analyze -f sverilog SORT_IP.v 
elaborate $DESIGN  

# (B-2) read_sverilog
#read_sverilog $DESIGN\.v

# (B-3) set current design
current_design $DESIGN
link
#======================================================
#  Global Setting
#======================================================
set_wire_load_mode top
#set_wire_load_model -name umc18_wl10 -library slow
#set_operating_conditions -min fast  -max slow
#======================================================
#  Set Design Constraints
#======================================================
set_max_delay $CYCLE -from [all_inputs] -to [all_outputs]
set_load 0.05 [all_outputs]
#======================================================
#  Optimization
#======================================================
check_design > Report/$DESIGN\.check
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

compile_ultra
#======================================================
#  Output Reports 
#======================================================
report_design  >  Report/$DESIGN\.design
report_resource >  Report/$DESIGN\.resource
report_timing -max_paths 3 >  Report/$DESIGN\.timing
report_area >  Report/$DESIGN\.area
report_power > Report/$DESIGN\.power
report_clock > Report/$DESIGN\.clock
report_port >  Report/$DESIGN\.port
report_power >  Report/$DESIGN\.power
#======================================================
#  Change Naming Rule
#======================================================
set bus_inference_style "%s\[%d\]"
set bus_naming_style "%s\[%d\]"
set hdlout_internal_busses true
change_names -hierarchy -rule verilog
define_name_rules name_rule -allowed "a-z A-Z 0-9 _" -max_length 255 -type cell
define_name_rules name_rule -allowed "a-z A-Z 0-9 _[]" -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
define_name_rules name_rule -case_insensitive
change_names -hierarchy -rules name_rule
#======================================================
#  Output Results
#======================================================
set verilogout_higher_designs_first true
write -format verilog -output Netlist/$DESIGN\_SYN.v -hierarchy
write -format ddc     -hierarchy -output $DESIGN\_SYN.ddc
write_sdf -version 3.0 -context verilog -load_delay cell Netlist/$DESIGN\_SYN.sdf -significant_digits 6
write_sdc Netlist/$DESIGN\_SYN.sdc
#======================================================
#  Finish and Quit
#======================================================
report_area -designware -hierarchy
report_timing 
exit
