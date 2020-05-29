#create the cores

create_bd_cell -type ip -vlnv xilinx.com:hls:roce_tx_interpreter:1.0 roce_sector/roce_tx/roce_tx_interpreter_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/roce_tx/axis_data_fifo_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/roce_tx/axis_data_fifo_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 roce_sector/roce_tx/axis_data_fifo_2

#configure the cores

set_property -dict [list CONFIG.FIFO_DEPTH {16}] [get_bd_cells roce_sector/roce_tx/axis_data_fifo_0]
set_property -dict [list CONFIG.FIFO_DEPTH {128}] [get_bd_cells roce_sector/roce_tx/axis_data_fifo_1]
set_property -dict [list CONFIG.FIFO_DEPTH {16}] [get_bd_cells roce_sector/roce_tx/axis_data_fifo_2]

#connect the interfaces

connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_tx/axis_data_fifo_0/M_AXIS] [get_bd_intf_pins roce_sector/roce_tx/roce_tx_interpreter_0/rdma_read_aeth_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_tx/axis_data_fifo_1/M_AXIS] [get_bd_intf_pins roce_sector/roce_tx/roce_tx_interpreter_0/rdma_read_payload_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_tx/axis_data_fifo_2/M_AXIS] [get_bd_intf_pins roce_sector/roce_tx/roce_tx_interpreter_0/read_flags_V]

connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_tx/read_flags] [get_bd_intf_pins roce_sector/roce_tx/axis_data_fifo_2/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_tx/read_payload] [get_bd_intf_pins roce_sector/roce_tx/axis_data_fifo_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_tx/read_aeth] [get_bd_intf_pins roce_sector/roce_tx/axis_data_fifo_0/S_AXIS]

connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_tx/tx_interpreter_config] [get_bd_intf_pins roce_sector/roce_tx/roce_tx_interpreter_0/S_AXI_BUS_A]

connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_tx/ack_flags] [get_bd_intf_pins roce_sector/roce_tx/roce_tx_interpreter_0/ack_flags_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_tx/ack] [get_bd_intf_pins roce_sector/roce_tx/roce_tx_interpreter_0/acknowledgement_V]

connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_tx/tx_data] [get_bd_intf_pins roce_sector/roce_tx/roce_tx_interpreter_0/tx_roce_data_V]
connect_bd_intf_net [get_bd_intf_pins roce_sector/roce_tx/tx_meta] [get_bd_intf_pins roce_sector/roce_tx/roce_tx_interpreter_0/tx_roce_meta_V]

#other connections

connect_bd_net [get_bd_pins roce_sector/roce_tx/clk_200mhz] [get_bd_pins roce_sector/roce_tx/roce_tx_interpreter_0/aclk]
connect_bd_net [get_bd_pins roce_sector/roce_tx/clk_200mhz] [get_bd_pins roce_sector/roce_tx/axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/roce_tx/clk_200mhz] [get_bd_pins roce_sector/roce_tx/axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_pins roce_sector/roce_tx/clk_200mhz] [get_bd_pins roce_sector/roce_tx/axis_data_fifo_2/s_axis_aclk]

connect_bd_net [get_bd_pins roce_sector/roce_tx/reset_200mhz] [get_bd_pins roce_sector/roce_tx/roce_tx_interpreter_0/aresetn]
connect_bd_net [get_bd_pins roce_sector/roce_tx/reset_200mhz] [get_bd_pins roce_sector/roce_tx/axis_data_fifo_0/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/roce_tx/reset_200mhz] [get_bd_pins roce_sector/roce_tx/axis_data_fifo_1/s_axis_aresetn]
connect_bd_net [get_bd_pins roce_sector/roce_tx/reset_200mhz] [get_bd_pins roce_sector/roce_tx/axis_data_fifo_2/s_axis_aresetn]

connect_bd_net [get_bd_pins roce_sector/roce_tx/roce_port] [get_bd_pins roce_sector/roce_tx/roce_tx_interpreter_0/roce_port_V]

#assign address

assign_bd_address [get_bd_addr_segs {roce_sector/roce_tx/roce_tx_interpreter_0/S_AXI_BUS_A/Reg }]
set_property offset 0x00A0030000 [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_roce_tx_interpreter_0_Reg}]
