#RX Path

#create the cells

create_bd_cell -type ip -vlnv xilinx.com:hls:udp_non_roce_rx_interpreter:1.0 Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl
create_bd_cell -type ip -vlnv xilinx.com:hls:packet_length_counter:1.0 Shell/pl_ps_bridge/rx_path/packet_length_counter
create_bd_cell -type ip -vlnv xilinx.com:hls:data_stream_compressor:1.0 Shell/pl_ps_bridge/rx_path/ds_compress
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/rx_path/axis_data_fifo_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/rx_path/axis_data_fifo_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/rx_path/axis_data_fifo_2
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/rx_path/axis_data_fifo_3
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/rx_path/axis_data_fifo_4
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/rx_path/axis_data_fifo_5
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/rx_path/axis_data_fifo_6
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/rx_path/axis_data_fifo_7
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 Shell/pl_ps_bridge/rx_path/xlconstant_0

#configure the cells

set_property -dict [list CONFIG.FIFO_DEPTH {16}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_0]
set_property -dict [list CONFIG.FIFO_DEPTH {16}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_1]
set_property -dict [list CONFIG.FIFO_DEPTH {16}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_2]
set_property -dict [list CONFIG.FIFO_DEPTH {16}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_3]
set_property -dict [list CONFIG.FIFO_DEPTH {16}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_4]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_5]
set_property -dict [list CONFIG.FIFO_DEPTH {16}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_6]
set_property -dict [list CONFIG.FIFO_DEPTH {16}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_7]
set_property -dict [list CONFIG.CONST_WIDTH {16} CONFIG.CONST_VAL {0x2345}] [get_bd_cells Shell/pl_ps_bridge/rx_path/xlconstant_0]
set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_0]
set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_2]
set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_3]
set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_6]
set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells Shell/pl_ps_bridge/rx_path/axis_data_fifo_7]

#connect the interfaces

connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_0/M_AXIS] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/packet_length_counter/data_in_V]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/packet_length_counter/data_out_V] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/packet_length_counter/length_V_V] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_4/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_1/M_AXIS] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/ds_compress/data_in_V]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/ds_compress/data_out_V] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_5/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_2/M_AXIS] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl/mem_transfer_out_V]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_3/M_AXIS] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl/rx_nonroce_meta_V]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_4/M_AXIS] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl/length_V_V]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_5/M_AXIS] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl/rx_nonroce_data_V]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_6/M_AXIS] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl/sw_request_tx_V]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_7/M_AXIS] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl/sw_request_rx_V]

connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/malloc] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl/cont_fifo_data_V_V]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/mem_transfer] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_2/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_non_roce_data] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_non_roce_meta] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_3/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/sw_fifo_req] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl/sw_fifo_request_V_V]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/sw_request_rx] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_7/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/sw_request_tx] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_6/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_data_out] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl/data_to_send_V]

#other connections

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_200mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_0/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_200mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_200mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_2/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_200mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_2/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_200mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_3/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_200mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_3/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_200mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_6/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_200mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_6/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_200mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_7/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_200mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_7/s_axis_aclk]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_0/m_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_2/m_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_3/m_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_6/m_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_7/m_axis_aclk]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_4/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_5/s_axis_aclk]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_1/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_4/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/axis_data_fifo_5/s_axis_aresetn]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/packet_length_counter/aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/packet_length_counter/aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/ds_compress/aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/ds_compress/aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl/aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl/aresetn]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/rx_path/xlconstant_0/dout] [get_bd_pins Shell/pl_ps_bridge/rx_path/rx_interpreter_ps_pl/RDMA_PORT_V]
