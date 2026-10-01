set root [file normalize [file join [file dirname [info script]] ..]]
set project_file [file join $root team04_lab1 NEXYS_A7 NEXYS_A7.xpr]
set report_dir [file join $root report project7]

file mkdir $report_dir
set_param general.maxThreads 4

open_project $project_file
synth_design -top NEXYS_A7 -part xc7a100tcsg324-1 -flatten_hierarchy rebuilt
report_utilization -file [file join $report_dir synthesis_utilization.rpt]
write_checkpoint -force [file join $report_dir synthesis.dcp]

opt_design
place_design
phys_opt_design
route_design
report_utilization -file [file join $report_dir implementation_utilization.rpt]
report_timing_summary -file [file join $report_dir timing_summary.rpt]
report_drc -file [file join $report_dir drc.rpt]
write_checkpoint -force [file join $report_dir implemented.dcp]
puts "PROJECT7_BUILD_COMPLETE"
close_project
