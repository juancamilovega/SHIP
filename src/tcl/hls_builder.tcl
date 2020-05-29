set infile [open "Namefile.txt" r]
set ip_name [gets $infile]
close $infile
set infile [open "Speed_grade.txt" r]
set speed [gets $infile]
close $infile
set root_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set module_name $ip_name
cd $module_name
open_project $module_name
set_top $module_name
add_files $root_dir/src/vhls/$module_name.cpp
open_solution "solution1"
set_part {xczu19eg-ffvc1760-2-i} -tool vivado
create_clock -period $speed -name default
config_rtl -reset all -reset_level low
csynth_design
export_design -rtl verilog
