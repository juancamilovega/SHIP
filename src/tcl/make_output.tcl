set infile [open "num_cores.txt" r]
set cores [gets $infile]
close $infile

set project_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]

open_project $project_dir/SHIP_hardware/SHIP_hardware.xpr

set_property strategy Performance_Explore [get_runs impl_1]

launch_runs impl_1 -to_step write_bitstream -jobs $cores

wait_on_run impl_1

file copy -force $project_dir/SHIP_hardware/SHIP_hardware.runs/impl_1/SHIP_hardware_wrapper.bit $project_dir/output_products/storage.bit

exit
