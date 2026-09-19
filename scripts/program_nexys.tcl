set root [file normalize [file join [file dirname [info script]] ..]]
set bitfile [file join $root report nexys_current NEXYS_A7.bit]

open_hw_manager
connect_hw_server
open_hw_target
set devices [get_hw_devices]
puts "HW_DEVICES: $devices"
if {[llength $devices] != 1} {
    error "Expected exactly one JTAG device; found [llength $devices]"
}
set device [lindex $devices 0]
puts "HW_PART: [get_property PART $device]"
if {[get_property PART $device] ne "xc7a100t_0"} {
    error "Expected Nexys A7-100T (xc7a100t_0)"
}
set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device
refresh_hw_device $device
puts "PROGRAM_COMPLETE"
close_hw_manager
