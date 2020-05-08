#create cells

create_bd_cell -type ip -vlnv clarkshen.com:user:GULF_Stream:1.0 roce_sector/udp_parser/GULF_Stream/GULF_Stream
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 roce_sector/udp_parser/GULF_Stream/xlslice_0
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 roce_sector/udp_parser/GULF_Stream/xlslice_1
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 roce_sector/udp_parser/GULF_Stream/xlslice_2
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 roce_sector/udp_parser/GULF_Stream/xlslice_3
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 roce_sector/udp_parser/GULF_Stream/xlslice_4
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 roce_sector/udp_parser/GULF_Stream/xlslice_5
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 roce_sector/udp_parser/GULF_Stream/sideband_data_concat
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/udp_parser/GULF_Stream/axis_data_fifo_1
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 roce_sector/udp_parser/GULF_Stream/seven_bit_zero
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 roce_sector/udp_parser/GULF_Stream/network_reset_sync
create_bd_cell -type hier roce_sector/udp_parser/GULF_Stream/ethernet

#add ports to hierarchies

create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 roce_sector/udp_parser/GULF_Stream/ethernet/gt_rx

create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 roce_sector/udp_parser/GULF_Stream/ethernet/gt_tx

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 roce_sector/udp_parser/GULF_Stream/ethernet/init
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 roce_sector/udp_parser/GULF_Stream/ethernet/gt_ref

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/udp_parser/GULF_Stream/ethernet/network_tx

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/udp_parser/GULF_Stream/ethernet/network_rx

create_bd_pin -dir O roce_sector/udp_parser/GULF_Stream/ethernet/network_clocks

#configure blocks

set_property -dict [list CONFIG.CONST_WIDTH {7} CONFIG.CONST_VAL {0}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/seven_bit_zero]

set_property -dict [list CONFIG.DIN_TO {0} CONFIG.DIN_FROM {511} CONFIG.DIN_WIDTH {648}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/xlslice_0]
set_property -dict [list CONFIG.DIN_TO {512} CONFIG.DIN_FROM {527} CONFIG.DIN_WIDTH {648}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/xlslice_1]
set_property -dict [list CONFIG.DIN_TO {528} CONFIG.DIN_FROM {543} CONFIG.DIN_WIDTH {648}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/xlslice_2]
set_property -dict [list CONFIG.DIN_TO {544} CONFIG.DIN_FROM {575} CONFIG.DIN_WIDTH {648}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/xlslice_3]
set_property -dict [list CONFIG.DIN_TO {576} CONFIG.DIN_FROM {639} CONFIG.DIN_WIDTH {648}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/xlslice_4]
set_property -dict [list CONFIG.DIN_TO {640} CONFIG.DIN_FROM {640} CONFIG.DIN_WIDTH {648}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/xlslice_5]

set_property -dict [list CONFIG.FIFO_DEPTH {512} CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0]
set_property -dict [list CONFIG.FIFO_DEPTH {1024} CONFIG.IS_ACLK_ASYNC {1} CONFIG.TDATA_NUM_BYTES {81}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/axis_data_fifo_1]
set_property -dict [list CONFIG.NUM_PORTS {7}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/sideband_data_concat]

set_property -dict [list CONFIG.HAS_AXIL {true} CONFIG.IP_ADDR $ip_addr CONFIG.GATEWAY $gateway_addr CONFIG.MAC_ADDR $mac_addr CONFIG.NETMASK $subnet] [get_bd_cells roce_sector/udp_parser/GULF_Stream/GULF_Stream]

#connect Interfaces

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/Gulf_Stream_config] [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/s_axictl]

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/network_tx] [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/network_rx] [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_1/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/gt_tx] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/gt_tx]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/gt_rx] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/gt_rx]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/init] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/init]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/gt_ref] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/gt_ref]

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/m_axis] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/network_tx]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/network_rx] [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/s_axis]

#connect clocks and resets

#network domain

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/global_reset] [get_bd_pins roce_sector/udp_parser/GULF_Stream/network_reset_sync/ext_reset_in]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/network_clocks] [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/network_clocks] [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0/m_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/network_clocks] [get_bd_pins roce_sector/udp_parser/GULF_Stream/network_reset_sync/slowest_sync_clk]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/network_clocks] [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/clk]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/network_clocks] [get_bd_pins roce_sector/udp_parser/GULF_Stream/clk_network]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/network_reset_sync/interconnect_aresetn] [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_1/s_axis_aresetn]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/network_reset_sync/interconnect_aresetn] [get_bd_pins roce_sector/udp_parser/GULF_Stream/reset_network]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/network_reset_sync/peripheral_reset] [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/rst]

#266mhz domain

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/clk_266mhz] [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/clk_266mhz] [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_1/m_axis_aclk]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/reset_266mhz] [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0/s_axis_aresetn]

#connect input to gulf stream

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0/m_axis_tdata] [get_bd_pins roce_sector/udp_parser/GULF_Stream/xlslice_0/Din]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0/m_axis_tdata] [get_bd_pins roce_sector/udp_parser/GULF_Stream/xlslice_1/Din]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0/m_axis_tdata] [get_bd_pins roce_sector/udp_parser/GULF_Stream/xlslice_2/Din]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0/m_axis_tdata] [get_bd_pins roce_sector/udp_parser/GULF_Stream/xlslice_3/Din]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0/m_axis_tdata] [get_bd_pins roce_sector/udp_parser/GULF_Stream/xlslice_4/Din]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0/m_axis_tdata] [get_bd_pins roce_sector/udp_parser/GULF_Stream/xlslice_5/Din]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/xlslice_0/Dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/payload_from_user_data]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/xlslice_1/Dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/remote_port_tx]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/xlslice_2/Dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/local_port_tx]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/xlslice_3/Dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/remote_ip_tx]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/xlslice_4/Dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/payload_from_user_keep]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/xlslice_5/Dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/payload_from_user_last]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/payload_from_user_valid] [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0/m_axis_tvalid]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/payload_from_user_ready] [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_0/m_axis_tready]

#connect output of gulf stream

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/payload_to_user_data] [get_bd_pins roce_sector/udp_parser/GULF_Stream/sideband_data_concat/In0]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/remote_port_rx] [get_bd_pins roce_sector/udp_parser/GULF_Stream/sideband_data_concat/In1]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/local_port_rx] [get_bd_pins roce_sector/udp_parser/GULF_Stream/sideband_data_concat/In2]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/remote_ip_rx] [get_bd_pins roce_sector/udp_parser/GULF_Stream/sideband_data_concat/In3]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/payload_to_user_keep] [get_bd_pins roce_sector/udp_parser/GULF_Stream/sideband_data_concat/In4]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/payload_to_user_last] [get_bd_pins roce_sector/udp_parser/GULF_Stream/sideband_data_concat/In5]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/seven_bit_zero/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/sideband_data_concat/In6]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/sideband_data_concat/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_1/s_axis_tdata]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/GULF_Stream/payload_to_user_valid] [get_bd_pins roce_sector/udp_parser/GULF_Stream/axis_data_fifo_1/s_axis_tvalid]

#configure addresses

assign_bd_address [get_bd_addr_segs {roce_sector/udp_parser/GULF_Stream/GULF_Stream/s_axictl/reg0 }]
set_property offset 0x00A0060000 [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_GULF_Stream_reg0}]

