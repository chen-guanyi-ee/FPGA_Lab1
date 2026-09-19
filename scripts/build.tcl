set root [file normalize [file join [file dirname [info script]] ..]]
set report_dir [file join $root report]

file mkdir $report_dir

create_project NEXYS_A7 [file join $root team01_lab1 NEXYS_A7 vivado] -part xc7a100tcsg324-1 -force

add_files [glob [file join $root team01_lab1 NEXYS_A7 *.sv]]

add_files -fileset constrs_1 [file join $root team01_lab1 NEXYS_A7 Nexys-A7-100T-Master.xdc]

set_property top NEXYS_A7 [current_fileset]

update_compile_order -fileset sources_1

launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
    error "Synthesis failed"
}

open_run synth_1

report_utilization -file [file join $report_dir synthesis_utilization.rpt]

launch_runs impl_1 -to_step route_design -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
    error "Implementation failed"
}

open_run impl_1

report_utilization -file [file join $report_dir implementation_utilization.rpt]
report_timing_summary -file [file join $report_dir timing_summary.rpt]
report_drc -file [file join $report_dir drc.rpt]