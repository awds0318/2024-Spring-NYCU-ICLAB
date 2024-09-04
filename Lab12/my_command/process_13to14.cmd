saveDesign ./DBS/CHIP_placement.inn

#====================================================================
#  Clock Tree Synthesis (CTS)
#====================================================================
update_constraint_mode -name func_mode -sdc_files CHIP_cts.sdc
set_ccopt_property update_io_latency false
create_ccopt_clock_tree_spec -file CHIP.CCOPT.spec -keep_all_sdc_clocks
source CHIP.CCOPT.spec
ccopt_design


#=================
#  Optimize
#=================
# === check setup timing ===
timeDesign -postCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports

setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -postCTS

# === check hold timing ===
timeDesign -postCTS -hold -pathReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -postCTS -hold

