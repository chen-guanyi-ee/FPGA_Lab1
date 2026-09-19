set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root report nexys_current]
file mkdir $out
set_param general.maxThreads 4
create_project -in_memory -part xc7a100tcsg324-1
foreach src [glob [file join $root team01_lab1 NEXYS_A7 *.sv]] {read_verilog -sv $src}
read_xdc [file join $root team01_lab1 NEXYS_A7 Nexys-A7-100T-Master.xdc]
proc reports {stage} {
    global out
    report_utilization -file [file join $out ${stage}_utilization.rpt]
    report_utilization -hierarchical -hierarchical_depth 10 -file [file join $out ${stage}_hierarchy.rpt]
    set f [open [file join $out ${stage}_cells.tsv] w]
    puts $f "name\tref_name\tloc\tbel"
    foreach c [lsort [get_cells -hier -filter {IS_PRIMITIVE == 1}]] {
        puts $f "$c\t[get_property REF_NAME $c]\t[get_property LOC $c]\t[get_property BEL $c]"
    }
    close $f
}
synth_design -top NEXYS_A7 -part xc7a100tcsg324-1 -flatten_hierarchy rebuilt
reports synthesis
write_checkpoint -force [file join $out synthesis.dcp]
opt_design
place_design
phys_opt_design
route_design
reports implementation
report_timing_summary -delay_type min_max -report_unconstrained -max_paths 10 -file [file join $out timing_summary.rpt]
report_drc -file [file join $out drc.rpt]
report_route_status -file [file join $out route_status.rpt]
report_control_sets -verbose -file [file join $out control_sets.rpt]
check_timing -verbose -file [file join $out check_timing.rpt]
write_checkpoint -force [file join $out implemented.dcp]
write_bitstream -force [file join $out NEXYS_A7.bit]
puts "ANALYSIS_COMPLETE"
