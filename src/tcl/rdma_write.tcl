#write sector

#create blocks

create_bd_cell -type ip -vlnv xilinx.com:hls:packet_length_counter_advanced:1.0 write_sector/packet_length_counter
create_bd_cell -type ip -vlnv xilinx.com:hls:write_signal_handler:1.0 write_sector/write_signal_handler
create_bd_cell -type ip -vlnv xilinx.com:hls:write_organizer:1.0 write_sector/write_organizer
create_bd_cell -type ip -vlnv xilinx.com:hls:verifier_advanced:1.0 write_sector/verifier
create_bd_cell -type ip -vlnv xilinx.com:hls:data_storer_advanced:1.0 write_sector/data_storer
create_bd_cell -type module -reference AXIF_TO_AXIS write_sector/AXIF_TO_AXIS
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 write_sector/length_fifo
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 write_sector/request_fifo
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 write_sector/data_in_fifo
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 write_sector/instructions_fifo
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 write_sector/mem_transfer_fifo
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 write_sector/done_fifo
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 write_sector/ack_fifo
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 write_sector/batch_fifo

#configure blocks

set_property -dict [list CONFIG.FIFO_DEPTH {256}] [get_bd_cells write_sector/length_fifo]
set_property -dict [list CONFIG.FIFO_DEPTH {256}] [get_bd_cells write_sector/request_fifo]
set_property -dict [list CONFIG.FIFO_DEPTH {8192}] [get_bd_cells write_sector/data_in_fifo]
set_property -dict [list CONFIG.FIFO_DEPTH {256}] [get_bd_cells write_sector/instructions_fifo]
set_property -dict [list CONFIG.FIFO_DEPTH {256}] [get_bd_cells write_sector/mem_transfer_fifo]
set_property -dict [list CONFIG.FIFO_DEPTH {256}] [get_bd_cells write_sector/done_fifo]
set_property -dict [list CONFIG.FIFO_DEPTH {256}] [get_bd_cells write_sector/ack_fifo]
set_property -dict [list CONFIG.FIFO_DEPTH {256}] [get_bd_cells write_sector/batch_fifo]

#connect interfaces

connect_bd_intf_net [get_bd_intf_pins write_sector/data] [get_bd_intf_pins write_sector/packet_length_counter/data_in_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/flags] [get_bd_intf_pins write_sector/write_signal_handler/write_flags_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/reth] [get_bd_intf_pins write_sector/write_signal_handler/rdma_write_reth_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/malloc] [get_bd_intf_pins write_sector/write_organizer/cont_fifo_data_V_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/change_queue] [get_bd_intf_pins write_sector/write_organizer/change_queue_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/ack] [get_bd_intf_pins write_sector/ack_fifo/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins write_sector/mem_transfer] [get_bd_intf_pins write_sector/verifier/mem_transfer_out_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/sw_request] [get_bd_intf_pins write_sector/write_organizer/sw_request_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/memory_write_port] [get_bd_intf_pins write_sector/AXIF_TO_AXIS/m_axi]

connect_bd_intf_net [get_bd_intf_pins write_sector/data_storer/mem_ar_V] [get_bd_intf_pins write_sector/AXIF_TO_AXIS/AR]
connect_bd_intf_net [get_bd_intf_pins write_sector/data_storer/mem_aw_V] [get_bd_intf_pins write_sector/AXIF_TO_AXIS/AW]
connect_bd_intf_net [get_bd_intf_pins write_sector/data_storer/mem_w_V] [get_bd_intf_pins write_sector/AXIF_TO_AXIS/W]
connect_bd_intf_net [get_bd_intf_pins write_sector/data_storer/mem_r_V] [get_bd_intf_pins write_sector/AXIF_TO_AXIS/R]
connect_bd_intf_net [get_bd_intf_pins write_sector/verifier/MEM_B_V] [get_bd_intf_pins write_sector/AXIF_TO_AXIS/B]

connect_bd_intf_net [get_bd_intf_pins write_sector/batch_fifo/M_AXIS] [get_bd_intf_pins write_sector/data_storer/batch_in_V_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/packet_length_counter/burst_info_V_V] [get_bd_intf_pins write_sector/batch_fifo/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins write_sector/packet_length_counter/length_V_V] [get_bd_intf_pins write_sector/length_fifo/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins write_sector/data_in_fifo/S_AXIS] [get_bd_intf_pins write_sector/packet_length_counter/data_out_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/length_fifo/M_AXIS] [get_bd_intf_pins write_sector/write_organizer/pkt_size_V_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/write_signal_handler/request_V] [get_bd_intf_pins write_sector/request_fifo/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins write_sector/request_fifo/M_AXIS] [get_bd_intf_pins write_sector/write_organizer/request_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/write_organizer/acknowledgement_V] [get_bd_intf_pins write_sector/ack_fifo/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins write_sector/write_organizer/instructions_V] [get_bd_intf_pins write_sector/instructions_fifo/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins write_sector/write_organizer/mem_transfer_V] [get_bd_intf_pins write_sector/mem_transfer_fifo/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins write_sector/done_fifo/M_AXIS] [get_bd_intf_pins write_sector/verifier/done_req_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/mem_transfer_fifo/M_AXIS] [get_bd_intf_pins write_sector/verifier/mem_transfer_V]

connect_bd_intf_net [get_bd_intf_pins write_sector/data_storer/done_V] [get_bd_intf_pins write_sector/done_fifo/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins write_sector/data_in_fifo/M_AXIS] [get_bd_intf_pins write_sector/data_storer/data_in_V]
connect_bd_intf_net [get_bd_intf_pins write_sector/instructions_fifo/M_AXIS] [get_bd_intf_pins write_sector/data_storer/instructions_V]


#other connections

connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/packet_length_counter/aclk]
connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/write_signal_handler/aclk]
connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/write_organizer/aclk]
connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/verifier/aclk]
connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/AXIF_TO_AXIS/aclk]
connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/data_storer/aclk]

connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/packet_length_counter/aresetn]
connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/write_signal_handler/aresetn]
connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/write_organizer/aresetn]
connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/verifier/aresetn]
connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/AXIF_TO_AXIS/aresetn]
connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/data_storer/aresetn]

connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/length_fifo/s_axis_aclk]
connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/request_fifo/s_axis_aclk]
connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/data_in_fifo/s_axis_aclk]
connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/instructions_fifo/s_axis_aclk]
connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/mem_transfer_fifo/s_axis_aclk]
connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/done_fifo/s_axis_aclk]
connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/ack_fifo/s_axis_aclk]
connect_bd_net [get_bd_pins write_sector/clk_200mhz] [get_bd_pins write_sector/batch_fifo/s_axis_aclk]

connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/length_fifo/s_axis_aresetn]
connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/request_fifo/s_axis_aresetn]
connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/data_in_fifo/s_axis_aresetn]
connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/instructions_fifo/s_axis_aresetn]
connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/mem_transfer_fifo/s_axis_aresetn]
connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/done_fifo/s_axis_aresetn]
connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/ack_fifo/s_axis_aresetn]
connect_bd_net [get_bd_pins write_sector/reset_200mhz] [get_bd_pins write_sector/batch_fifo/s_axis_aresetn]

connect_bd_net [get_bd_pins write_sector/base_address] [get_bd_pins write_sector/data_storer/TOP_ADDR_V]


#set the address

assign_bd_address [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW }]
assign_bd_address [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_QSPI Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_HIGH Shell/ddr4/ddr4_hub/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK Shell/ddr4/ddr4_hub/C0_DDR4_MEMORY_MAP_CTRL/C0_REG }]

