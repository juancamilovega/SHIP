#read sector

#create blocks

create_bd_cell -type ip -vlnv xilinx.com:hls:rrrh:1.0 read_sector/rrrh_0
create_bd_cell -type ip -vlnv xilinx.com:hls:data_reader:1.0 read_sector/data_reader_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 read_sector/axis_data_fifo_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 read_sector/axis_data_fifo_1

#connect interfaces

connect_bd_intf_net [get_bd_intf_pins read_sector/rrrh_0/to_data_writer_V] [get_bd_intf_pins read_sector/axis_data_fifo_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins read_sector/axis_data_fifo_1/M_AXIS] [get_bd_intf_pins read_sector/data_reader_0/from_rrrh_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/axis_data_fifo_0/M_AXIS] [get_bd_intf_pins read_sector/rrrh_0/un_satisfied_fifo_in_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/rrrh_0/un_satisfied_fifo_out_V] [get_bd_intf_pins read_sector/axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins read_sector/ack] [get_bd_intf_pins read_sector/rrrh_0/ack_out_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/sw_request] [get_bd_intf_pins read_sector/rrrh_0/sw_request_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/change_queue] [get_bd_intf_pins read_sector/rrrh_0/change_queue_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/done] [get_bd_intf_pins read_sector/rrrh_0/done_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/flags] [get_bd_intf_pins read_sector/rrrh_0/flags_in_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/request] [get_bd_intf_pins read_sector/rrrh_0/request_in_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/mem_free] [get_bd_intf_pins read_sector/data_reader_0/cont_fifo_data_V_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/read_aeth] [get_bd_intf_pins read_sector/data_reader_0/rdma_read_aeth_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/read_flags] [get_bd_intf_pins read_sector/data_reader_0/read_flags_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/read_payload] [get_bd_intf_pins read_sector/data_reader_0/rdma_read_payload_V]
connect_bd_intf_net [get_bd_intf_pins read_sector/rrh_to_mem] [get_bd_intf_pins read_sector/data_reader_0/M_AXI_MEM_V]

#other connections

connect_bd_net [get_bd_pins read_sector/clk_266mhz] [get_bd_pins read_sector/data_reader_0/aclk]
connect_bd_net [get_bd_pins read_sector/clk_266mhz] [get_bd_pins read_sector/rrrh_0/aclk]
connect_bd_net [get_bd_pins read_sector/clk_266mhz] [get_bd_pins read_sector/axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_pins read_sector/clk_266mhz] [get_bd_pins read_sector/axis_data_fifo_0/s_axis_aclk]

connect_bd_net [get_bd_pins read_sector/reset_266mhz] [get_bd_pins read_sector/data_reader_0/aresetn]
connect_bd_net [get_bd_pins read_sector/reset_266mhz] [get_bd_pins read_sector/rrrh_0/aresetn]
connect_bd_net [get_bd_pins read_sector/reset_266mhz] [get_bd_pins read_sector/axis_data_fifo_1/s_axis_aresetn]
connect_bd_net [get_bd_pins read_sector/reset_266mhz] [get_bd_pins read_sector/axis_data_fifo_0/s_axis_aresetn]

connect_bd_net [get_bd_pins read_sector/base_address] [get_bd_pins read_sector/data_reader_0/BASE_ADDR_V]

#set the addresses

assign_bd_address [get_bd_addr_segs {Shell/shared_memory_subsystem/address_offset_application/add_top_32_addr_0/s_axi/reg0 }]
set_property offset 0x00000000 [get_bd_addr_segs {read_sector/data_reader_0/Data_M_AXI_MEM_V/SEG_add_top_32_addr_0_reg0}]
set_property range 4G [get_bd_addr_segs {read_sector/data_reader_0/Data_M_AXI_MEM_V/SEG_add_top_32_addr_0_reg0}]
