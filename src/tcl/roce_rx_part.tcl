#create the cells

create_bd_cell -type ip -vlnv xilinx.com:hls:roce_rx_interpreter:1.0 roce_sector/roce_rx/roce_rx_interpreter
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/roce_rx/axis_data_fifo_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/roce_rx/axis_data_fifo_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/roce_rx/axis_data_fifo_2
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/roce_rx/axis_data_fifo_3
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/roce_rx/axis_data_fifo_4
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/roce_rx/axis_data_fifo_5
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/roce_rx/axis_data_fifo_6
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 roce_sector/roce_rx/one_bit_one


#configure the cells

set_property -dict [list CONFIG.CONST_VAL {1}] [get_bd_cells roce_sector/roce_rx/one_bit_one]
set_property -dict [list CONFIG.FIFO_DEPTH {16}] [get_bd_cells roce_sector/roce_rx/axis_data_fifo_0]
set_property -dict [list CONFIG.FIFO_DEPTH {16}] [get_bd_cells roce_sector/roce_rx/axis_data_fifo_1]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells roce_sector/roce_rx/axis_data_fifo_2]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells roce_sector/roce_rx/axis_data_fifo_3]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells roce_sector/roce_rx/axis_data_fifo_4]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells roce_sector/roce_rx/axis_data_fifo_5]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells roce_sector/roce_rx/axis_data_fifo_6]

#connect the interfaces

connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/axis_data_fifo_0/S_AXIS] [get_bd_intf_pins roce_sector/roce_rx/roce_rx_interpreter/ack_flags_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/axis_data_fifo_1/S_AXIS] [get_bd_intf_pins roce_sector/roce_rx/roce_rx_interpreter/acknowledgement_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/axis_data_fifo_2/S_AXIS] [get_bd_intf_pins roce_sector/roce_rx/roce_rx_interpreter/rdma_read_request_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/axis_data_fifo_3/S_AXIS] [get_bd_intf_pins roce_sector/roce_rx/roce_rx_interpreter/rdma_write_payload_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/axis_data_fifo_4/S_AXIS] [get_bd_intf_pins roce_sector/roce_rx/roce_rx_interpreter/rdma_write_reth_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/axis_data_fifo_5/S_AXIS] [get_bd_intf_pins roce_sector/roce_rx/roce_rx_interpreter/read_req_flags_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/axis_data_fifo_6/S_AXIS] [get_bd_intf_pins roce_sector/roce_rx/roce_rx_interpreter/write_flags_V]

connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/rx_data] [get_bd_intf_pins roce_sector/roce_rx/roce_rx_interpreter/rx_roce_data_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/rx_meta] [get_bd_intf_pins roce_sector/roce_rx/roce_rx_interpreter/rx_roce_meta_V_V]

connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/read_req_data] [get_bd_intf_pins roce_sector/roce_rx/axis_data_fifo_2/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/read_req_flag] [get_bd_intf_pins roce_sector/roce_rx/axis_data_fifo_5/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/write_data] [get_bd_intf_pins roce_sector/roce_rx/axis_data_fifo_3/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/write_flag] [get_bd_intf_pins roce_sector/roce_rx/axis_data_fifo_6/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_rx/write_reth] [get_bd_intf_pins roce_sector/roce_rx/axis_data_fifo_4/M_AXIS]

#tie off unused ports for future extensions

connect_bd_net [get_bd_pins roce_sector/roce_rx/axis_data_fifo_0/m_axis_tready] [get_bd_pins roce_sector/roce_rx/one_bit_one/dout]
connect_bd_net [get_bd_pins roce_sector/roce_rx/axis_data_fifo_1/m_axis_tready] [get_bd_pins roce_sector/roce_rx/one_bit_one/dout]

#other connection

connect_bd_net [get_bd_pins roce_sector/roce_rx/clk_266mhz] [get_bd_pins roce_sector/roce_rx/roce_rx_interpreter/aclk]
connect_bd_net [get_bd_pins roce_sector/roce_rx/clk_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/roce_rx/clk_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/roce_rx/clk_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_2/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/roce_rx/clk_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_3/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/roce_rx/clk_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_4/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/roce_rx/clk_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_5/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/roce_rx/clk_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_6/s_axis_aclk]

connect_bd_net [get_bd_pins roce_sector/roce_rx/reset_266mhz] [get_bd_pins roce_sector/roce_rx/roce_rx_interpreter/aresetn]
connect_bd_net [get_bd_pins roce_sector/roce_rx/reset_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_0/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/roce_rx/reset_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_1/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/roce_rx/reset_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_2/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/roce_rx/reset_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_3/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/roce_rx/reset_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_4/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/roce_rx/reset_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_5/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/roce_rx/reset_266mhz] [get_bd_pins roce_sector/roce_rx/axis_data_fifo_6/s_axis_aresetn]
