#set variables

set project_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set project_name "SHIP_driver"
set script_dir [file dirname [file normalize [info script]]]
proc addip {ipName displayName} {
	set vlnv_version_independent [lindex [get_ipdefs -all -filter "NAME == $ipName"] end]
	create_bd_cell -type ip -vlnv $vlnv_version_independent $displayName
}

#create the project

create_project $project_name $project_dir/$project_name -part xczu19eg-ffvc1760-2-i
create_bd_design $project_name

#import dependencies
file copy -force ${project_dir}/src/vhdl/meta_intf_to_ports.vhd ${project_dir}/SHIP_driver/meta_intf_to_ports.vhd
set_property  ip_repo_paths  {"${project_dir}/../ip_repo" "${project_dir}/../repos/GULF-Stream"} [current_project]
update_ip_catalog -rebuild
add_files -norecurse ${project_dir}/SHIP_driver/meta_intf_to_ports.vhd
update_compile_order -fileset sources_1
open_bd_design {${project_dir}/SHIP_driver.srcs/sources_1/bd/SHIP_driver/SHIP_driver.bd}

#add cores
addip driver_rx driver_rx
addip driver_tx driver_tx
addip write_core write_core
addip stream_meta_to_gulf stream_meta_to_gulf
create_bd_cell -type module -reference meta_intf_to_ports meta_intf_to_ports
addip xlconcat ip_addr

#configure the cores
set_property -dict [list CONFIG.NUM_PORTS {4}] [get_bd_cells ip_addr]

#create interface ports

create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 rx_payload_in
create_bd_intf_port -mode Slave -vlnv clarkshen.com:user:GULF_stream_meta_rtl:1.0 rx_meta_in

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 acknowledgements
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 sw_acknowledgements
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 other_packets_data_rx
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 other_packets_meta_rx
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 read_info
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 read_data

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 tx_payload_out
create_bd_intf_port -mode Master -vlnv clarkshen.com:user:GULF_stream_meta_rtl:1.0 tx_meta_out

create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 open_close_instructions
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 file_name
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 other_packets_data_tx
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 other_packets_meta_tx
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 read_requests
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 seek_requests
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 write_requests
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 write_data

#create pin ports

create_bd_port -dir I -type clk clk
set_property CONFIG.FREQ_HZ 266000000 [get_bd_ports clk]

create_bd_port -dir I -type rst resetn
set_property CONFIG.ASSOCIATED_RESET {resetn} [get_bd_ports /clk]
set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_ports resetn]

create_bd_port -dir I -from 7 -to 0 IP_0
create_bd_port -dir I -from 7 -to 0 IP_1
create_bd_port -dir I -from 7 -to 0 IP_2
create_bd_port -dir I -from 7 -to 0 IP_3

create_bd_port -dir I -from 1 -to 0 roce_flags_congestion
create_bd_port -dir I -from 15 -to 0 partition
create_bd_port -dir I solicited
create_bd_port -dir I migration_request
create_bd_port -dir I -from 3 -to 0 transport_header_version
create_bd_port -dir I acknowledge_request

create_bd_port -dir I -from 15 -to 0 storage_device_port_roce
create_bd_port -dir I -from 15 -to 0 storage_device_port_sw
create_bd_port -dir I -from 15 -to 0 port_local_roce
create_bd_port -dir I -from 15 -to 0 port_local_sw
#connect interfaces

connect_bd_intf_net [get_bd_intf_ports tx_payload_out] [get_bd_intf_pins stream_meta_to_gulf/tx_payload_out_V]
connect_bd_intf_net [get_bd_intf_ports rx_payload_in] [get_bd_intf_pins stream_meta_to_gulf/rx_payload_in_V]

connect_bd_intf_net [get_bd_intf_ports file_name] [get_bd_intf_pins driver_tx/file_name_in_V]
connect_bd_intf_net [get_bd_intf_ports open_close_instructions] [get_bd_intf_pins driver_tx/open_close_instructions_V]
connect_bd_intf_net [get_bd_intf_ports other_packets_data_tx] [get_bd_intf_pins driver_tx/other_packets_in_V]
connect_bd_intf_net [get_bd_intf_ports other_packets_meta_tx] [get_bd_intf_pins driver_tx/other_packets_meta_in_V]
connect_bd_intf_net [get_bd_intf_ports read_requests] [get_bd_intf_pins driver_tx/param_in_V]
connect_bd_intf_net [get_bd_intf_ports seek_requests] [get_bd_intf_pins driver_tx/seek_info_in_V]

connect_bd_intf_net [get_bd_intf_ports write_data] [get_bd_intf_pins write_core/data_to_write_V]
connect_bd_intf_net [get_bd_intf_ports write_requests] [get_bd_intf_pins write_core/param_in_V]

connect_bd_intf_net [get_bd_intf_ports rx_meta_in] [get_bd_intf_pins meta_intf_to_ports/meta_rx]
connect_bd_intf_net [get_bd_intf_ports tx_meta_out] [get_bd_intf_pins meta_intf_to_ports/meta_tx]

connect_bd_intf_net [get_bd_intf_ports acknowledgements] [get_bd_intf_pins driver_rx/acknowledgements_V]
connect_bd_intf_net [get_bd_intf_ports other_packets_data_rx] [get_bd_intf_pins driver_rx/other_packets_data_V]
connect_bd_intf_net [get_bd_intf_ports other_packets_meta_rx] [get_bd_intf_pins driver_rx/other_packets_meta_V]
connect_bd_intf_net [get_bd_intf_ports read_data] [get_bd_intf_pins driver_rx/read_packets_data_V]
connect_bd_intf_net [get_bd_intf_ports read_info] [get_bd_intf_pins driver_rx/read_packets_info_V]
connect_bd_intf_net [get_bd_intf_ports sw_acknowledgements] [get_bd_intf_pins driver_rx/sw_acknowledgements_V]

connect_bd_intf_net [get_bd_intf_pins write_core/payload_out_V] [get_bd_intf_pins driver_tx/write_core_V]

connect_bd_intf_net [get_bd_intf_pins driver_tx/meta_out_V] [get_bd_intf_pins stream_meta_to_gulf/tx_meta_in_V]
connect_bd_intf_net [get_bd_intf_pins driver_tx/payload_out_V] [get_bd_intf_pins stream_meta_to_gulf/tx_payload_in_V]

connect_bd_intf_net [get_bd_intf_pins stream_meta_to_gulf/rx_meta_out_V] [get_bd_intf_pins driver_rx/meta_in_V]
connect_bd_intf_net [get_bd_intf_pins stream_meta_to_gulf/rx_payload_out_V] [get_bd_intf_pins driver_rx/data_in_V]

#connect ports

connect_bd_net [get_bd_ports clk] [get_bd_pins write_core/aclk]
connect_bd_net [get_bd_ports clk] [get_bd_pins driver_tx/aclk]
connect_bd_net [get_bd_ports clk] [get_bd_pins driver_rx/aclk]
connect_bd_net [get_bd_ports clk] [get_bd_pins stream_meta_to_gulf/aclk]

connect_bd_net [get_bd_ports resetn] [get_bd_pins write_core/aresetn]
connect_bd_net [get_bd_ports resetn] [get_bd_pins driver_tx/aresetn]
connect_bd_net [get_bd_ports resetn] [get_bd_pins driver_rx/aresetn]
connect_bd_net [get_bd_ports resetn] [get_bd_pins stream_meta_to_gulf/aresetn]

connect_bd_net [get_bd_pins stream_meta_to_gulf/tx_meta_out_port_remote_V] [get_bd_pins meta_intf_to_ports/tx_remote_pin_port]
connect_bd_net [get_bd_pins stream_meta_to_gulf/tx_meta_out_port_local_V] [get_bd_pins meta_intf_to_ports/tx_local_pin_port]
connect_bd_net [get_bd_pins stream_meta_to_gulf/tx_meta_out_ip_remote_V] [get_bd_pins meta_intf_to_ports/tx_remote_pin_ip]
connect_bd_net [get_bd_pins stream_meta_to_gulf/rx_meta_in_port_remote_V] [get_bd_pins meta_intf_to_ports/rx_remote_pin_port]
connect_bd_net [get_bd_pins stream_meta_to_gulf/rx_meta_in_port_local_V] [get_bd_pins meta_intf_to_ports/rx_local_pin_port]
connect_bd_net [get_bd_pins stream_meta_to_gulf/rx_meta_in_ip_remote_V] [get_bd_pins meta_intf_to_ports/rx_remote_pin_ip]

connect_bd_net [get_bd_ports IP_0] [get_bd_pins ip_addr/In3]
connect_bd_net [get_bd_ports IP_1] [get_bd_pins ip_addr/In2]
connect_bd_net [get_bd_ports IP_2] [get_bd_pins ip_addr/In1]
connect_bd_net [get_bd_ports IP_3] [get_bd_pins ip_addr/In0]

connect_bd_net [get_bd_pins ip_addr/dout] [get_bd_pins driver_tx/storage_device_ip_V]
connect_bd_net [get_bd_pins ip_addr/dout] [get_bd_pins driver_rx/storage_ip_addr_V]

connect_bd_net [get_bd_ports port_local_roce] [get_bd_pins driver_tx/port_local_roce_V]
connect_bd_net [get_bd_ports port_local_roce] [get_bd_pins driver_rx/roce_port_number_V]

connect_bd_net [get_bd_ports port_local_sw] [get_bd_pins driver_tx/port_local_sw_V]
connect_bd_net [get_bd_ports port_local_sw] [get_bd_pins driver_rx/port_local_sw_V]

connect_bd_net [get_bd_ports storage_device_port_roce] [get_bd_pins driver_tx/storage_device_port_roce_V]
connect_bd_net [get_bd_ports storage_device_port_sw] [get_bd_pins driver_tx/storage_device_port_sw_V]

connect_bd_net [get_bd_ports roce_flags_congestion] [get_bd_pins write_core/roce_flags_conjestion_V]
connect_bd_net [get_bd_ports partition] [get_bd_pins write_core/roce_flags_partition_V]
connect_bd_net [get_bd_ports solicited] [get_bd_pins write_core/roce_flags_solicited_event_V]
connect_bd_net [get_bd_ports migration_request] [get_bd_pins write_core/roce_flags_mig_req_V]
connect_bd_net [get_bd_ports transport_header_version] [get_bd_pins write_core/roce_flags_transport_header_version_V]
connect_bd_net [get_bd_ports acknowledge_request] [get_bd_pins write_core/roce_flags_ack_req_V]

connect_bd_net [get_bd_ports roce_flags_congestion] [get_bd_pins driver_tx/roce_flags_conjestion_V]
connect_bd_net [get_bd_ports partition] [get_bd_pins driver_tx/roce_flags_partition_V]
connect_bd_net [get_bd_ports solicited] [get_bd_pins driver_tx/roce_flags_solicited_event_V]
connect_bd_net [get_bd_ports migration_request] [get_bd_pins driver_tx/roce_flags_mig_req_V]
connect_bd_net [get_bd_ports transport_header_version] [get_bd_pins driver_tx/roce_flags_transport_header_version_V]
connect_bd_net [get_bd_ports acknowledge_request] [get_bd_pins driver_tx/roce_flags_ack_req_V]

#finalize

validate_bd_design
make_wrapper -files [get_files ${project_dir}/SHIP_driver/SHIP_driver.srcs/sources_1/bd/SHIP_driver/SHIP_driver.bd] -top
add_files -norecurse ${project_dir}/SHIP_driver/SHIP_driver.srcs/sources_1/bd/SHIP_driver/hdl/SHIP_driver_wrapper.v
update_compile_order -fileset sources_1
save_bd_design
if 0 {
#setup packaging

ipx::package_project -root_dir ${project_dir}/ip_repo/generated_ips -vendor user.org -library user -taxonomy /UserIP -module SHIP_driver -import_files
ipx::package_project -root_dir ${project_dir}/SHIP_driver -vendor user.org -library user -taxonomy /UserIP

#add customization parameters

ipx::add_user_parameter IP_0 [ipx::current_core]
set_property value_resolve_type user [ipx::get_user_parameters IP_0 -of_objects [ipx::current_core]]
ipgui::add_param -name {IP_0} -component [ipx::current_core]
set_property show_range {false} [ipgui::get_guiparamspec -name "IP_0" -component [ipx::current_core] ]
set_property display_name {IP} [ipgui::get_guiparamspec -name "IP_0" -component [ipx::current_core] ]
set_property tooltip {IP address} [ipgui::get_guiparamspec -name "IP_0" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "IP_0" -component [ipx::current_core] ]
set_property value 10 [ipx::get_user_parameters IP_0 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters IP_0 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type range_long [ipx::get_user_parameters IP_0 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters IP_0 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_maximum 255 [ipx::get_user_parameters IP_0 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipx::add_user_parameter IP_1 [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters IP_1 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipgui::add_param -name {IP_1} -component [ipx::current_core]
set_property show_range {false} [ipgui::get_guiparamspec -name "IP_1" -component [ipx::current_core] ]
set_property display_name {.} [ipgui::get_guiparamspec -name "IP_1" -component [ipx::current_core] ]
set_property tooltip {} [ipgui::get_guiparamspec -name "IP_1" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "IP_1" -component [ipx::current_core] ]
set_property value 10 [ipx::get_user_parameters IP_1 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters IP_1 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type range_long [ipx::get_user_parameters IP_1 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters IP_1 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_maximum 255 [ipx::get_user_parameters IP_1 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipx::add_user_parameter IP_2 [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters IP_2 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipgui::add_param -name {IP_2} -component [ipx::current_core]
set_property show_range {false} [ipgui::get_guiparamspec -name "IP_2" -component [ipx::current_core] ]
set_property display_name {.} [ipgui::get_guiparamspec -name "IP_2" -component [ipx::current_core] ]
set_property tooltip {} [ipgui::get_guiparamspec -name "IP_2" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "IP_2" -component [ipx::current_core] ]
set_property value 10 [ipx::get_user_parameters IP_2 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters IP_2 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type range_long [ipx::get_user_parameters IP_2 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters IP_2 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_maximum 255 [ipx::get_user_parameters IP_2 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipx::add_user_parameter IP_3 [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters IP_3 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipgui::add_param -name {IP_3} -component [ipx::current_core]
set_property show_range {false} [ipgui::get_guiparamspec -name "IP_3" -component [ipx::current_core] ]
set_property display_name {.} [ipgui::get_guiparamspec -name "IP_3" -component [ipx::current_core] ]
set_property tooltip {} [ipgui::get_guiparamspec -name "IP_3" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "IP_3" -component [ipx::current_core] ]
set_property value 10 [ipx::get_user_parameters IP_3 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters IP_3 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type range_long [ipx::get_user_parameters IP_3 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters IP_3 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_maximum 255 [ipx::get_user_parameters IP_3 -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipx::add_user_parameter acknowledge_request [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters acknowledge_request -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipgui::add_param -name {acknowledge_request} -component [ipx::current_core]
set_property display_name {Acknowledge Request} [ipgui::get_guiparamspec -name "acknowledge_request" -component [ipx::current_core] ]
set_property widget {radioGroup} [ipgui::get_guiparamspec -name "acknowledge_request" -component [ipx::current_core] ]
set_property layout {horizontal} [ipgui::get_guiparamspec -name "acknowledge_request" -component [ipx::current_core] ]
set_property value 1 [ipx::get_user_parameters acknowledge_request -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters acknowledge_request -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type pairs [ipx::get_user_parameters acknowledge_request -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_pairs {enable 1 disable 0} [ipx::get_user_parameters acknowledge_request -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipx::add_user_parameter Enable_Debug [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters Enable_Debug -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipgui::add_param -name {Enable_Debug} -component [ipx::current_core]
set_property display_name {Edit Debug Parameters} [ipgui::get_guiparamspec -name "Enable_Debug" -component [ipx::current_core] ]
set_property tooltip {Edit Debug Parameters} [ipgui::get_guiparamspec -name "Enable_Debug" -component [ipx::current_core] ]
set_property widget {checkBox} [ipgui::get_guiparamspec -name "Enable_Debug" -component [ipx::current_core] ]
set_property value false [ipx::get_user_parameters Enable_Debug -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format bool [ipx::get_user_parameters Enable_Debug -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipx::add_user_parameter migration_request [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters migration_request -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipgui::add_param -name {migration_request} -component [ipx::current_core]
set_property display_name {Migration Request} [ipgui::get_guiparamspec -name "migration_request" -component [ipx::current_core] ]
set_property widget {radioGroup} [ipgui::get_guiparamspec -name "migration_request" -component [ipx::current_core] ]
set_property layout {horizontal} [ipgui::get_guiparamspec -name "migration_request" -component [ipx::current_core] ]
set_property value 0 [ipx::get_user_parameters migration_request -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property enablement_tcl_expr {expr $Enable_Debug} [ipx::get_user_parameters migration_request -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters migration_request -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type pairs [ipx::get_user_parameters migration_request -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_pairs {enable 1 disable 0} [ipx::get_user_parameters migration_request -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipx::add_user_parameter partition [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters partition -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipgui::add_param -name {partition} -component [ipx::current_core]
set_property display_name {Partition} [ipgui::get_guiparamspec -name "partition" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "partition" -component [ipx::current_core] ]
set_property value 0 [ipx::get_user_parameters partition -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property enablement_tcl_expr {expr $Enable_Debug} [ipx::get_user_parameters partition -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters partition -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type range_long [ipx::get_user_parameters partition -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters partition -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_maximum 65535 [ipx::get_user_parameters partition -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipx::add_user_parameter port_local_roce [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters port_local_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipgui::add_param -name {port_local_roce} -component [ipx::current_core]
set_property display_name {Port Local Roce} [ipgui::get_guiparamspec -name "port_local_roce" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "port_local_roce" -component [ipx::current_core] ]
set_property value 4791 [ipx::get_user_parameters port_local_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property enablement_tcl_expr {expr $Enable_Debug} [ipx::get_user_parameters port_local_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters port_local_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type range_long [ipx::get_user_parameters port_local_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters port_local_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_maximum 65535 [ipx::get_user_parameters port_local_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipx::add_user_parameter port_local_sw [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters port_local_sw -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipgui::add_param -name {port_local_sw} -component [ipx::current_core]
set_property display_name {Port Local Sw} [ipgui::get_guiparamspec -name "port_local_sw" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "port_local_sw" -component [ipx::current_core] ]
set_property value 9029 [ipx::get_user_parameters port_local_sw -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters port_local_sw -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type range_long [ipx::get_user_parameters port_local_sw -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters port_local_sw -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_maximum 65535 [ipx::get_user_parameters port_local_sw -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipx::add_user_parameter roce_flags_congestion [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters roce_flags_congestion -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipgui::add_param -name {roce_flags_congestion} -component [ipx::current_core]
set_property display_name {Roce Flags Congestion} [ipgui::get_guiparamspec -name "roce_flags_congestion" -component [ipx::current_core] ]
set_property widget {radioGroup} [ipgui::get_guiparamspec -name "roce_flags_congestion" -component [ipx::current_core] ]
set_property layout {horizontal} [ipgui::get_guiparamspec -name "roce_flags_congestion" -component [ipx::current_core] ]
set_property value 0 [ipx::get_user_parameters roce_flags_congestion -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property enablement_tcl_expr {expr $Enable_Debug} [ipx::get_user_parameters roce_flags_congestion -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters roce_flags_congestion -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type list [ipx::get_user_parameters roce_flags_congestion -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_list {0 1 2 3} [ipx::get_user_parameters roce_flags_congestion -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipx::add_user_parameter solicited [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters solicited -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipgui::add_param -name {solicited} -component [ipx::current_core]
set_property display_name {Solicited} [ipgui::get_guiparamspec -name "solicited" -component [ipx::current_core] ]
set_property widget {radioGroup} [ipgui::get_guiparamspec -name "solicited" -component [ipx::current_core] ]
set_property layout {horizontal} [ipgui::get_guiparamspec -name "solicited" -component [ipx::current_core] ]
set_property value 1 [ipx::get_user_parameters solicited -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters solicited -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type pairs [ipx::get_user_parameters solicited -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_pairs {enable 1 disable 0} [ipx::get_user_parameters solicited -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipx::add_user_parameter storage_device_port_roce [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters storage_device_port_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipgui::add_param -name {storage_device_port_roce} -component [ipx::current_core]
set_property display_name {Storage Device Port Roce} [ipgui::get_guiparamspec -name "storage_device_port_roce" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "storage_device_port_roce" -component [ipx::current_core] ]
set_property value 4791 [ipx::get_user_parameters storage_device_port_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property enablement_tcl_expr {expr $Enable_Debug} [ipx::get_user_parameters storage_device_port_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters storage_device_port_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type range_long [ipx::get_user_parameters storage_device_port_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters storage_device_port_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_maximum 65535 [ipx::get_user_parameters storage_device_port_roce -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipx::add_user_parameter storage_device_port_sw [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters storage_device_port_sw -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipgui::add_param -name {storage_device_port_sw} -component [ipx::current_core]
set_property display_name {Storage Device Port Sw} [ipgui::get_guiparamspec -name "storage_device_port_sw" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "storage_device_port_sw" -component [ipx::current_core] ]
set_property value 9029 [ipx::get_user_parameters storage_device_port_sw -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters storage_device_port_sw -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type range_long [ipx::get_user_parameters storage_device_port_sw -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters storage_device_port_sw -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_maximum 65535 [ipx::get_user_parameters storage_device_port_sw -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]

ipx::add_user_parameter transport_header_version [ipx::find_open_core user.org:user:SHIP_driver:1.0]
set_property value_resolve_type user [ipx::get_user_parameters transport_header_version -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
ipgui::add_param -name {transport_header_version} -component [ipx::current_core]
set_property display_name {Transport Header Version} [ipgui::get_guiparamspec -name "transport_header_version" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "transport_header_version" -component [ipx::current_core] ]
set_property value 0 [ipx::get_user_parameters transport_header_version -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property enablement_tcl_expr {expr $Enable_Debug} [ipx::get_user_parameters transport_header_version -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_format long [ipx::get_user_parameters transport_header_version -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_type range_long [ipx::get_user_parameters transport_header_version -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters transport_header_version -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
set_property value_validation_range_maximum 65535 [ipx::get_user_parameters transport_header_version -of_objects [ipx::find_open_core user.org:user:SHIP_driver:1.0]]
}

exit
