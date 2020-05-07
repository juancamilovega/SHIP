#ACK handler

#create blocks
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 ack_handler/three_bit_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch:1.1 ack_handler/axis_switch_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 ack_handler/axis_data_fifo_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 ack_handler/axis_data_fifo_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 ack_handler/axis_data_fifo_2
create_bd_cell -type ip -vlnv xilinx.com:hls:ack_handler:1.0 ack_handler/ack_handler_0

#configure the blocks
set_property -dict [list CONFIG.NUM_SI {3}] [get_bd_cells ack_handler/axis_switch_0]
set_property -dict [list CONFIG.FIFO_DEPTH {32}] [get_bd_cells ack_handler/axis_data_fifo_0]
set_property -dict [list CONFIG.FIFO_DEPTH {32}] [get_bd_cells ack_handler/axis_data_fifo_1]
set_property -dict [list CONFIG.FIFO_DEPTH {32}] [get_bd_cells ack_handler/axis_data_fifo_2]
set_property -dict [list CONFIG.CONST_WIDTH {3} CONFIG.CONST_VAL {0}] [get_bd_cells ack_handler/three_bit_0]

#connect the interfaces
connect_bd_intf_net [get_bd_intf_pins ack_handler/axis_switch_0/M00_AXIS] [get_bd_intf_pins ack_handler/axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins ack_handler/axis_data_fifo_0/M_AXIS] [get_bd_intf_pins ack_handler/ack_handler_0/ack_requests_V]
connect_bd_intf_net [get_bd_intf_pins ack_handler/ack_handler_0/ack_data_V] [get_bd_intf_pins ack_handler/axis_data_fifo_2/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins ack_handler/ack_handler_0/ack_flags_V] [get_bd_intf_pins ack_handler/axis_data_fifo_1/S_AXIS]

connect_bd_intf_net [get_bd_intf_pins ack_handler/read_ack] [get_bd_intf_pins ack_handler/axis_switch_0/S00_AXIS]
connect_bd_intf_net [get_bd_intf_pins ack_handler/write_ack] [get_bd_intf_pins ack_handler/axis_switch_0/S01_AXIS]
connect_bd_intf_net [get_bd_intf_pins ack_handler/ps_ack] [get_bd_intf_pins ack_handler/axis_switch_0/S02_AXIS]
connect_bd_intf_net [get_bd_intf_pins ack_handler/ack] [get_bd_intf_pins ack_handler/axis_data_fifo_2/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins ack_handler/ack_flags] [get_bd_intf_pins ack_handler/axis_data_fifo_1/M_AXIS]

#connect the other ports

connect_bd_net [get_bd_pins ack_handler/clk_266mhz] [get_bd_pins ack_handler/axis_switch_0/aclk]
connect_bd_net [get_bd_pins ack_handler/clk_266mhz] [get_bd_pins ack_handler/ack_handler_0/aclk]
connect_bd_net [get_bd_pins ack_handler/clk_266mhz] [get_bd_pins ack_handler/axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_pins ack_handler/clk_266mhz] [get_bd_pins ack_handler/axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_pins ack_handler/clk_266mhz] [get_bd_pins ack_handler/axis_data_fifo_2/s_axis_aclk]

connect_bd_net [get_bd_pins ack_handler/reset_266mhz] [get_bd_pins ack_handler/axis_switch_0/aresetn]
connect_bd_net [get_bd_pins ack_handler/reset_266mhz] [get_bd_pins ack_handler/ack_handler_0/aresetn]
connect_bd_net [get_bd_pins ack_handler/reset_266mhz] [get_bd_pins ack_handler/axis_data_fifo_0/s_axis_aresetn]
connect_bd_net [get_bd_pins ack_handler/reset_266mhz] [get_bd_pins ack_handler/axis_data_fifo_1/s_axis_aresetn]
connect_bd_net [get_bd_pins ack_handler/reset_266mhz] [get_bd_pins ack_handler/axis_data_fifo_2/s_axis_aresetn]

connect_bd_net [get_bd_pins ack_handler/three_bit_0/dout] [get_bd_pins ack_handler/axis_switch_0/s_req_suppress]
