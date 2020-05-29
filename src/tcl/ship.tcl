#get parameters
set infile [open "ip_addr.txt" r]
set ip_addr [gets $infile]
close $infile

set infile [open "gateway_addr.txt" r]
set gateway_addr [gets $infile]
close $infile

set infile [open "mac_addr.txt" r]
set mac_addr [gets $infile]
close $infile

set infile [open "subnet.txt" r]
set subnet [gets $infile]
close $infile

#set variables

set project_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set project_name "SHIP_hardware"
set script_dir [file dirname [file normalize [info script]]]
proc addip {ipName displayName} {
	set vlnv_version_independent [lindex [get_ipdefs -all -filter "NAME == $ipName"] end]
	create_bd_cell -type ip -vlnv $vlnv_version_independent $displayName
}

#create the project

create_project $project_name $project_dir/$project_name -part xczu19eg-ffvc1760-2-i
create_bd_design $project_name

#import dependencies

add_files -fileset constrs_1 -norecurse ${project_dir}/src/xdc/ship.xdc
set_property  ip_repo_paths  {"${project_dir}/../ip_repo" "${project_dir}/../repos/GULF-Stream"} [current_project]
update_ip_catalog -rebuild
#add_files -norecurse ${project_dir}/src/vhdl/add_top_32_addr.vhd
add_files -norecurse ${project_dir}/src/vhdl/AXIF_TO_AXIS.vhd
add_files -norecurse ${project_dir}/src/vhdl/AXIF_TO_AXIS_READ_ONLY.vhd
#add_files -norecurse ${project_dir}/src/vhdl/AXIF_TO_AXIS_WRITE_ONLY.vhd
update_compile_order -fileset sources_1
open_bd_design {${project_dir}/SHIP_hardware.srcs/sources_1/bd/SHIP_hardware/SHIP_hardware.bd}
source $project_dir/src/tcl/ps_pl_config.tcl

#TREE of hierarchies in project:
#main
#--->Shell
#--------->main_shell
#--------->pl_ps_bridge
#------------->tx_path
#------------->rx_path
#------------->axi_dma
#--------->shared_memory_subsystem
#------------->shared_memory_allocator
#------------->address_offset_application
#--------->pcie_root_complex
#--->read_sector
#--->write_sector
#--->ack_handler
#--->roce_sector
#--------->roce_tx_part
#--------->roce_rx_part
#--------->udp_parser
#------------->gulf_stream
#---------------->ethernet

#build each hierarchy 

source $project_dir/src/tcl/top_level.tcl

source $project_dir/src/tcl/shell.tcl

source $project_dir/src/tcl/main_shell.tcl

source $project_dir/src/tcl/ddr4.tcl

source $project_dir/src/tcl/root_complex.tcl

#source $project_dir/src/tcl/shared_memory_subsystem.tcl

source $project_dir/src/tcl/shared_memory_allocator.tcl

#source $project_dir/src/tcl/address_offset_adder.tcl

source $project_dir/src/tcl/ps_pl_bridge.tcl

source $project_dir/src/tcl/rx_path.tcl

source $project_dir/src/tcl/tx_path.tcl

source $project_dir/src/tcl/ack.tcl

source $project_dir/src/tcl/rdma_read.tcl

source $project_dir/src/tcl/rdma_write.tcl

source $project_dir/src/tcl/roce_sector.tcl

source $project_dir/src/tcl/roce_tx_part.tcl

source $project_dir/src/tcl/roce_rx_part.tcl

source $project_dir/src/tcl/udp_parser.tcl

source $project_dir/src/tcl/gulf_stream.tcl

source $project_dir/src/tcl/ethernet.tcl

source $project_dir/src/tcl/axi_dma.tcl

#finalize
validate_bd_design
make_wrapper -files [get_files ${project_dir}/SHIP_hardware/SHIP_hardware.srcs/sources_1/bd/SHIP_hardware/SHIP_hardware.bd] -top
add_files -norecurse ${project_dir}/SHIP_hardware/SHIP_hardware.srcs/sources_1/bd/SHIP_hardware/hdl/SHIP_hardware_wrapper.v

save_bd_design
exit
