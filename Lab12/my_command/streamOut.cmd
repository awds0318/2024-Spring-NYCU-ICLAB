#====================================================================
#   Add CORE Filler Cells
#====================================================================
getFillerMode -quiet
addFiller -cell FILLER1 FILLER2 FILLER4 FILLER8 FILLER16 FILLER32 FILLER64 -prefix FILLER

#====================================================================
# Stream Out and Write Netlist
# Don't save in "/DBS" folder because the 09_submit fetch the current folder
#====================================================================

saveDesign CHIP.inn
write_sdf CHIP.sdf
saveNetlist CHIP.v

summaryReport -noHtml -outfile summaryReport.rpt
