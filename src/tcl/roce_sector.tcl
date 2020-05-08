#create the cells

create_bd_cell -type hier roce_sector/roce_rx
create_bd_cell -type hier roce_sector/roce_tx
create_bd_cell -type hier roce_sector/udp_parser
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 roce_sector/roce_port

#add ports to hierarchies

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_tx/read_flags
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_tx/read_aeth
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_tx/read_payload
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_tx/ack_flags
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_tx/ack

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_tx/tx_data
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_tx/tx_meta

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 roce_sector/roce_tx/tx_interpreter_config

create_bd_pin -dir I roce_sector/roce_tx/clk_266mhz
create_bd_pin -dir I roce_sector/roce_tx/reset_266mhz
create_bd_pin -dir I -from 16 -to 0 roce_sector/roce_tx/roce_port

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_rx/rx_data
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_rx/rx_meta

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_rx/read_req_data
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_rx/read_req_flag
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_rx/write_reth
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_rx/write_flag
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/roce_rx/write_data

create_bd_pin -dir I roce_sector/roce_rx/clk_266mhz
create_bd_pin -dir I roce_sector/roce_rx/reset_266mhz

create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 roce_sector/udp_parser/gt_rx

create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 roce_sector/udp_parser/gt_tx

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 roce_sector/udp_parser/Gulf_Stream_config

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 roce_sector/udp_parser/init
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 roce_sector/udp_parser/gt_ref

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/udp_parser/tx_data
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/udp_parser/tx_meta
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/udp_parser/tx_nr_data
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/udp_parser/tx_nr_meta

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/udp_parser/rx_data
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/udp_parser/rx_meta
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/udp_parser/rx_nr_data
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/udp_parser/rx_nr_meta

create_bd_pin -dir I roce_sector/udp_parser/clk_266mhz
create_bd_pin -dir I roce_sector/udp_parser/reset_266mhz
create_bd_pin -dir I roce_sector/udp_parser/global_reset
create_bd_pin -dir I -from 16 -to 0 roce_sector/udp_parser/roce_port

create_bd_pin -dir O roce_sector/udp_parser/clk_network
create_bd_pin -dir O roce_sector/udp_parser/reset_network

#configure the cells

set_property -dict [list CONFIG.CONST_WIDTH {16} CONFIG.CONST_VAL {4791}] [get_bd_cells roce_sector/roce_port]

#connect the interfaces

connect_bd_intf_net [get_bd_intf_pins roce_sector/gt_rx] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/gt_rx]
connect_bd_intf_net [get_bd_intf_pins roce_sector/init] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/init]
connect_bd_intf_net [get_bd_intf_pins roce_sector/gt_ref] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/gt_ref]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/tx_data] [get_bd_intf_pins roce_sector/roce_tx/tx_data]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/tx_meta] [get_bd_intf_pins roce_sector/roce_tx/tx_meta]
connect_bd_intf_net [get_bd_intf_pins roce_sector/tx_non_roce_data] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/tx_nr_data]
connect_bd_intf_net [get_bd_intf_pins roce_sector/tx_non_roce_meta] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/tx_nr_meta]

connect_bd_intf_net [get_bd_intf_pins roce_sector/gt_tx] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/gt_tx]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/rx_data] [get_bd_intf_pins roce_sector/roce_rx/rx_data]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/rx_meta] [get_bd_intf_pins roce_sector/roce_rx/rx_meta]
connect_bd_intf_net [get_bd_intf_pins roce_sector/rx_non_roce_data] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/rx_nr_data]
connect_bd_intf_net [get_bd_intf_pins roce_sector/rx_non_roce_meta] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/rx_nr_meta]

connect_bd_intf_net [get_bd_intf_pins roce_sector/Gulf_Stream_config] -boundary_type upper [get_bd_intf_pins roce_sector/udp_parser/Gulf_Stream_config]

connect_bd_intf_net [get_bd_intf_pins roce_sector/read_flags] -boundary_type upper [get_bd_intf_pins roce_sector/roce_tx/read_flags]
connect_bd_intf_net [get_bd_intf_pins roce_sector/read_aeth] -boundary_type upper [get_bd_intf_pins roce_sector/roce_tx/read_aeth]
connect_bd_intf_net [get_bd_intf_pins roce_sector/read_payload] -boundary_type upper [get_bd_intf_pins roce_sector/roce_tx/read_payload]
connect_bd_intf_net [get_bd_intf_pins roce_sector/ack_flags] -boundary_type upper [get_bd_intf_pins roce_sector/roce_tx/ack_flags]
connect_bd_intf_net [get_bd_intf_pins roce_sector/ack] -boundary_type upper [get_bd_intf_pins roce_sector/roce_tx/ack]
connect_bd_intf_net [get_bd_intf_pins roce_sector/tx_interpreter_config] -boundary_type upper [get_bd_intf_pins roce_sector/roce_tx/tx_interpreter_config]

connect_bd_intf_net [get_bd_intf_pins roce_sector/read_request_data] -boundary_type upper [get_bd_intf_pins roce_sector/roce_rx/read_req_data]
connect_bd_intf_net [get_bd_intf_pins roce_sector/read_request_flag] -boundary_type upper [get_bd_intf_pins roce_sector/roce_rx/read_req_flag]
connect_bd_intf_net [get_bd_intf_pins roce_sector/write_reth] -boundary_type upper [get_bd_intf_pins roce_sector/roce_rx/write_reth]
connect_bd_intf_net [get_bd_intf_pins roce_sector/write_flags] -boundary_type upper [get_bd_intf_pins roce_sector/roce_rx/write_flag]
connect_bd_intf_net [get_bd_intf_pins roce_sector/write_data] -boundary_type upper [get_bd_intf_pins roce_sector/roce_rx/write_data]

#other connections

connect_bd_net [get_bd_pins roce_sector/clk_network] [get_bd_pins roce_sector/udp_parser/clk_network]

connect_bd_net [get_bd_pins roce_sector/reset_network] [get_bd_pins roce_sector/udp_parser/reset_network]

connect_bd_net [get_bd_pins roce_sector/clk_266mhz] [get_bd_pins roce_sector/roce_tx/clk_266mhz]
connect_bd_net [get_bd_pins roce_sector/clk_266mhz] [get_bd_pins roce_sector/roce_rx/clk_266mhz]
connect_bd_net [get_bd_pins roce_sector/clk_266mhz] [get_bd_pins roce_sector/udp_parser/clk_266mhz]

connect_bd_net [get_bd_pins roce_sector/reset_266mhz] [get_bd_pins roce_sector/roce_tx/reset_266mhz]
connect_bd_net [get_bd_pins roce_sector/reset_266mhz] [get_bd_pins roce_sector/roce_rx/reset_266mhz]
connect_bd_net [get_bd_pins roce_sector/reset_266mhz] [get_bd_pins roce_sector/udp_parser/reset_266mhz]

connect_bd_net [get_bd_pins roce_sector/roce_port/dout] [get_bd_pins roce_sector/roce_tx/roce_port]
connect_bd_net [get_bd_pins roce_sector/roce_port/dout] [get_bd_pins roce_sector/udp_parser/roce_port]

connect_bd_net [get_bd_pins roce_sector/reset_global] [get_bd_pins roce_sector/udp_parser/global_reset]

