#read sector

#create blocks

create_bd_cell -type ip -vlnv xilinx.com:hls:rrrh:1.0 read_sector/rrrh
create_bd_cell -type ip -vlnv xilinx.com:hls:data_reader_advanced:1.0 read_sector/data_reader
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 read_sector/axis_data_fifo_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 read_sector/axis_data_fifo_1
create_bd_cell -type module -reference AXIF_TO_AXIS_READ_ONLY read_sector/AXIF_TO_AXIS

#configure the cells

set_property -dict [list CONFIG.FIFO_DEPTH {512}] [get_bd_cells read_sector/axis_data_fifo_0]
set_property -dict [list CONFIG.FIFO_DEPTH {512}] [get_bd_cells read_sector/axis_data_fifo_1]

#connect interfaces

connect_bd_intf_net [get_bd_intf_pins read_sector/rrrh/to_data_writer_V] [get_bd_intf_pins read_sector/axis_data_fifo_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins read_sector/axis_data_fifo_0/M_AXIS] [get_bd_intf_pins read_sector/rrrh/un_satisfied_fifo_in_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/rrrh/un_satisfied_fifo_out_V] [get_bd_intf_pins read_sector/axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins read_sector/ack] [get_bd_intf_pins read_sector/rrrh/ack_out_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/sw_request] [get_bd_intf_pins read_sector/rrrh/sw_request_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/change_queue] [get_bd_intf_pins read_sector/rrrh/change_queue_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/done] [get_bd_intf_pins read_sector/rrrh/done_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/flags] [get_bd_intf_pins read_sector/rrrh/flags_in_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/request] [get_bd_intf_pins read_sector/rrrh/request_in_V]

connect_bd_intf_net [get_bd_intf_pins read_sector/axis_data_fifo_1/M_AXIS] [get_bd_intf_pins read_sector/data_reader/from_rrrh_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/mem_free] [get_bd_intf_pins read_sector/data_reader/cont_fifo_data_V_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/read_aeth] [get_bd_intf_pins read_sector/data_reader/rdma_read_aeth_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/read_payload] [get_bd_intf_pins read_sector/data_reader/rdma_read_payload_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/read_flags] [get_bd_intf_pins read_sector/data_reader/read_flags_V]

connect_bd_intf_net [get_bd_intf_pins read_sector/data_reader/mem_ar_V] [get_bd_intf_pins read_sector/AXIF_TO_AXIS/AR]
connect_bd_intf_net [get_bd_intf_pins read_sector/data_reader/mem_r_V] [get_bd_intf_pins read_sector/AXIF_TO_AXIS/R]

connect_bd_intf_net [get_bd_intf_pins read_sector/rrh_to_mem] [get_bd_intf_pins read_sector/AXIF_TO_AXIS/m_axi]

#other connections

connect_bd_net [get_bd_pins read_sector/clk_200mhz] [get_bd_pins read_sector/rrrh/aclk]
connect_bd_net [get_bd_pins read_sector/clk_200mhz] [get_bd_pins read_sector/data_reader/aclk]
connect_bd_net [get_bd_pins read_sector/clk_200mhz] [get_bd_pins read_sector/AXIF_TO_AXIS/aclk]

connect_bd_net [get_bd_pins read_sector/clk_200mhz] [get_bd_pins read_sector/axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_pins read_sector/clk_200mhz] [get_bd_pins read_sector/axis_data_fifo_0/s_axis_aclk]

connect_bd_net [get_bd_pins read_sector/reset_200mhz] [get_bd_pins read_sector/rrrh/aresetn]
connect_bd_net [get_bd_pins read_sector/reset_200mhz] [get_bd_pins read_sector/data_reader/aresetn]
connect_bd_net [get_bd_pins read_sector/reset_200mhz] [get_bd_pins read_sector/AXIF_TO_AXIS/aresetn]

connect_bd_net [get_bd_pins read_sector/reset_200mhz] [get_bd_pins read_sector/axis_data_fifo_1/s_axis_aresetn]
connect_bd_net [get_bd_pins read_sector/reset_200mhz] [get_bd_pins read_sector/axis_data_fifo_0/s_axis_aresetn]

connect_bd_net [get_bd_pins read_sector/base_address] [get_bd_pins read_sector/data_reader/BASE_ADDR_V]

#set the addresses

assign_bd_address [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_QSPI Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_HIGH Shell/ddr4/ddr4_hub/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK Shell/ddr4/ddr4_hub/C0_DDR4_MEMORY_MAP_CTRL/C0_REG }]

