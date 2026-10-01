set root [file normalize [file join [file dirname [info script]] ..]]
set report_dir [file join $root report project7]

open_checkpoint [file join $report_dir implemented.dcp]
write_bitstream -force [file join $report_dir NEXYS_A7.bit]
puts "PROJECT7_BITSTREAM_COMPLETE"
close_design
