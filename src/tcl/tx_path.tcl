#TX Path

#create the cells

create_bd_cell -type ip -vlnv xilinx.com:hls:udp_non_roce_tx_interpreter:1.0 Shell/pl_ps_bridge/tx_path/tx_interpreter_ps_pl
create_bd_cell -type ip -vlnv xilinx.com:hls:data_stream_expander:1.0 Shell/pl_ps_bridge/tx_path/data_stream_expander_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/tx_path/axis_data_fifo_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/tx_path/axis_data_fifo_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/tx_path/axis_data_fifo_2
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/tx_path/axis_data_fifo_3
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/tx_path/axis_data_fifo_4
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/tx_path/axis_data_fifo_5
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/tx_path/axis_data_fifo_6

#configure the cells

set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_0]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_1]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_2]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_3]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_4]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_5]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_6]
set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_0]
set_property -dict [list CONFIG.IS_ACLK_ASYNC {1} CONFIG.SYNCHRONIZATION_STAGES {4}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_1]
set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_2]
set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_3]
set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_4]
set_property -dict [list CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells Shell/pl_ps_bridge/tx_path/axis_data_fifo_5]

#connect the interfaces

connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_interpreter_ps_pl/change_queue_tx_V] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_interpreter_ps_pl/change_queue_rx_V] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_interpreter_ps_pl/ack_out_V] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_2/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/data_stream_expander_0/data_out_V] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_3/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_interpreter_ps_pl/tx_nonroce_data_V] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/data_stream_expander_0/data_in_V]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_interpreter_ps_pl/done_sig_V] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_4/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_interpreter_ps_pl/tx_nonroce_meta_V] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_5/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_interpreter_ps_pl/sw_fifo_request_V_V] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_6/S_AXIS]

connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_data_in] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_interpreter_ps_pl/tx_data_in_V]

connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/ps_ack] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_2/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/change_queue_rx] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_1/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/change_queue_tx] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_0/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/free] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_interpreter_ps_pl/cont_fifo_data_V_V]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/done] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_4/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/sw_fifo_req] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_6/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_non_roce_data] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_3/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_non_roce_meta] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_5/M_AXIS]

#other connections

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_266mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_0/m_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_266mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_1/m_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_266mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_2/m_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_266mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_3/m_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_266mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_4/m_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_266mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_5/m_axis_aclk]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_2/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_3/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_4/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_5/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_6/s_axis_aclk]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_0/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_1/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_2/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_3/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_4/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_5/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/axis_data_fifo_6/s_axis_aresetn]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/tx_interpreter_ps_pl/aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/data_stream_expander_0/aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/data_stream_expander_0/aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/tx_path/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/tx_interpreter_ps_pl/aresetn]
