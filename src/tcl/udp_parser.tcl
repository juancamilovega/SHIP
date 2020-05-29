#create the cores

create_bd_cell -type hier roce_sector/udp_parser/GULF_Stream
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/udp_parser/axis_data_fifo_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/udp_parser/axis_data_fifo_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/udp_parser/axis_data_fifo_2
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/udp_parser/axis_data_fifo_3
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/udp_parser/axis_data_fifo_4
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/udp_parser/axis_data_fifo_5
create_bd_cell -type ip -vlnv xilinx.com:hls:udp_roce_tx_engine:1.0 roce_sector/udp_parser/udp_tx_engine
create_bd_cell -type ip -vlnv xilinx.com:hls:udp_roce_rx_engine:1.0 roce_sector/udp_parser/udp_rx_engine

#add ports to hierarchies

create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 roce_sector/udp_parser/GULF_Stream/gt_rx

create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 roce_sector/udp_parser/GULF_Stream/gt_tx

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 roce_sector/udp_parser/GULF_Stream/init
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 roce_sector/udp_parser/GULF_Stream/gt_ref

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 roce_sector/udp_parser/GULF_Stream/Gulf_Stream_config

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/udp_parser/GULF_Stream/network_tx

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/udp_parser/GULF_Stream/network_rx

create_bd_pin -dir I roce_sector/udp_parser/GULF_Stream/clk_200mhz
create_bd_pin -dir I roce_sector/udp_parser/GULF_Stream/reset_200mhz
create_bd_pin -dir I roce_sector/udp_parser/GULF_Stream/global_reset

create_bd_pin -dir O roce_sector/udp_parser/GULF_Stream/clk_network
create_bd_pin -dir O roce_sector/udp_parser/GULF_Stream/reset_network

#configure the cores

set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells roce_sector/udp_parser/axis_data_fifo_0]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells roce_sector/udp_parser/axis_data_fifo_1]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells roce_sector/udp_parser/axis_data_fifo_2]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells roce_sector/udp_parser/axis_data_fifo_3]
set_property -dict [list CONFIG.FIFO_DEPTH {128}] [get_bd_cells roce_sector/udp_parser/axis_data_fifo_4]
set_property -dict [list CONFIG.FIFO_DEPTH {1024}] [get_bd_cells roce_sector/udp_parser/axis_data_fifo_5]

#connect the interfaces

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/Gulf_Stream_config] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/Gulf_Stream_config]

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/gt_ref] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/gt_ref]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/gt_rx] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/gt_rx]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/gt_tx] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/gt_tx]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/init] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/init]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/network_tx] [get_bd_intf_pins roce_sector/udp_parser/udp_tx_engine/udp_txData_converged_V_V]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/network_rx] [get_bd_intf_pins roce_sector/udp_parser/udp_rx_engine/udp_rxData_converged_V_V]

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/udp_tx_engine/tx_nonroce_data_V] [get_bd_intf_pins roce_sector/udp_parser/axis_data_fifo_0/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/udp_tx_engine/tx_nonroce_meta_V] [get_bd_intf_pins roce_sector/udp_parser/axis_data_fifo_1/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/udp_tx_engine/tx_roce_data_V] [get_bd_intf_pins roce_sector/udp_parser/axis_data_fifo_2/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/udp_tx_engine/tx_roce_meta_V] [get_bd_intf_pins roce_sector/udp_parser/axis_data_fifo_3/M_AXIS]

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/axis_data_fifo_4/S_AXIS] [get_bd_intf_pins roce_sector/udp_parser/udp_rx_engine/rx_roce_meta_V_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/axis_data_fifo_5/S_AXIS] [get_bd_intf_pins roce_sector/udp_parser/udp_rx_engine/rx_roce_data_V]

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/rx_nr_data] [get_bd_intf_pins roce_sector/udp_parser/udp_rx_engine/rx_nonroce_data_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/rx_nr_meta] [get_bd_intf_pins roce_sector/udp_parser/udp_rx_engine/rx_nonroce_meta_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/rx_meta] [get_bd_intf_pins roce_sector/udp_parser/axis_data_fifo_4/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/rx_data] [get_bd_intf_pins roce_sector/udp_parser/axis_data_fifo_5/M_AXIS]

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/tx_nr_data] [get_bd_intf_pins roce_sector/udp_parser/axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/tx_nr_meta] [get_bd_intf_pins roce_sector/udp_parser/axis_data_fifo_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/tx_data] [get_bd_intf_pins roce_sector/udp_parser/axis_data_fifo_2/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/tx_meta] [get_bd_intf_pins roce_sector/udp_parser/axis_data_fifo_3/S_AXIS]

#other connections

connect_bd_net [get_bd_pins roce_sector/udp_parser/clk_network] [get_bd_pins roce_sector/udp_parser/GULF_Stream/clk_network]

connect_bd_net [get_bd_pins roce_sector/udp_parser/reset_network] [get_bd_pins roce_sector/udp_parser/GULF_Stream/reset_network]

connect_bd_net [get_bd_pins roce_sector/udp_parser/clk_200mhz] [get_bd_pins roce_sector/udp_parser/udp_tx_engine/aclk]
connect_bd_net [get_bd_pins roce_sector/udp_parser/clk_200mhz] [get_bd_pins roce_sector/udp_parser/udp_rx_engine/aclk]
connect_bd_net [get_bd_pins roce_sector/udp_parser/clk_200mhz] [get_bd_pins roce_sector/udp_parser/GULF_Stream/clk_200mhz]
connect_bd_net [get_bd_pins roce_sector/udp_parser/clk_200mhz] [get_bd_pins roce_sector/udp_parser/axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/udp_parser/clk_200mhz] [get_bd_pins roce_sector/udp_parser/axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/udp_parser/clk_200mhz] [get_bd_pins roce_sector/udp_parser/axis_data_fifo_2/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/udp_parser/clk_200mhz] [get_bd_pins roce_sector/udp_parser/axis_data_fifo_3/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/udp_parser/clk_200mhz] [get_bd_pins roce_sector/udp_parser/axis_data_fifo_4/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/udp_parser/clk_200mhz] [get_bd_pins roce_sector/udp_parser/axis_data_fifo_5/s_axis_aclk]

connect_bd_net [get_bd_pins roce_sector/udp_parser/reset_200mhz] [get_bd_pins roce_sector/udp_parser/udp_tx_engine/aresetn]
connect_bd_net [get_bd_pins roce_sector/udp_parser/reset_200mhz] [get_bd_pins roce_sector/udp_parser/udp_rx_engine/aresetn]
connect_bd_net [get_bd_pins roce_sector/udp_parser/reset_200mhz] [get_bd_pins roce_sector/udp_parser/GULF_Stream/reset_200mhz]
connect_bd_net [get_bd_pins roce_sector/udp_parser/reset_200mhz] [get_bd_pins roce_sector/udp_parser/axis_data_fifo_0/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/udp_parser/reset_200mhz] [get_bd_pins roce_sector/udp_parser/axis_data_fifo_1/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/udp_parser/reset_200mhz] [get_bd_pins roce_sector/udp_parser/axis_data_fifo_2/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/udp_parser/reset_200mhz] [get_bd_pins roce_sector/udp_parser/axis_data_fifo_3/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/udp_parser/reset_200mhz] [get_bd_pins roce_sector/udp_parser/axis_data_fifo_4/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/udp_parser/reset_200mhz] [get_bd_pins roce_sector/udp_parser/axis_data_fifo_5/s_axis_aresetn]

connect_bd_net [get_bd_pins roce_sector/udp_parser/global_reset] [get_bd_pins roce_sector/udp_parser/GULF_Stream/global_reset]

connect_bd_net [get_bd_pins roce_sector/udp_parser/roce_port] [get_bd_pins roce_sector/udp_parser/udp_rx_engine/ROCE_PORT_NUM_V]
