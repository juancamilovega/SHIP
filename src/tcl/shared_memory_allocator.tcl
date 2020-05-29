#Shared Memory Allocator

#create the blocks

create_bd_cell -type ip -vlnv xilinx.com:hls:fpga_malloc_free:1.0 Shell/shared_memory_allocator/fpga_malloc_free_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch:1.1 Shell/shared_memory_allocator/axis_switch_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/shared_memory_allocator/axis_data_fifo_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/shared_memory_allocator/axis_data_fifo_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/shared_memory_allocator/axis_data_fifo_2
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/shared_memory_allocator/axis_data_fifo_3
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/shared_memory_allocator/axis_data_fifo_4
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/shared_memory_allocator/axis_data_fifo_5

#configure the blocks

set_property -dict [list CONFIG.FIFO_DEPTH {4096}] [get_bd_cells Shell/shared_memory_allocator/axis_data_fifo_0]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells Shell/shared_memory_allocator/axis_data_fifo_1]
set_property -dict [list CONFIG.FIFO_DEPTH {16} CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells Shell/shared_memory_allocator/axis_data_fifo_2]
set_property -dict [list CONFIG.FIFO_DEPTH {16}] [get_bd_cells Shell/shared_memory_allocator/axis_data_fifo_3]
set_property -dict [list CONFIG.FIFO_DEPTH {16} CONFIG.HAS_PROG_FULL {1} CONFIG.PROG_FULL_THRESH {10}] [get_bd_cells Shell/shared_memory_allocator/axis_data_fifo_4]
set_property -dict [list CONFIG.FIFO_DEPTH {16} CONFIG.IS_ACLK_ASYNC {1} CONFIG.HAS_PROG_FULL {1} CONFIG.PROG_FULL_THRESH {10}] [get_bd_cells Shell/shared_memory_allocator/axis_data_fifo_5]

#connect the interfaces

connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_allocator/free2] [get_bd_intf_pins Shell/shared_memory_allocator/axis_data_fifo_2/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_allocator/free1] [get_bd_intf_pins Shell/shared_memory_allocator/axis_data_fifo_3/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_allocator/axis_data_fifo_2/M_AXIS] [get_bd_intf_pins Shell/shared_memory_allocator/axis_switch_0/S00_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_allocator/axis_data_fifo_3/M_AXIS] [get_bd_intf_pins Shell/shared_memory_allocator/axis_switch_0/S01_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_allocator/axis_switch_0/M00_AXIS] [get_bd_intf_pins Shell/shared_memory_allocator/axis_data_fifo_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_allocator/axis_data_fifo_1/M_AXIS] [get_bd_intf_pins Shell/shared_memory_allocator/fpga_malloc_free_0/data_in_port_V_V]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_allocator/fpga_malloc_free_0/data_out_port_1_V_V] [get_bd_intf_pins Shell/shared_memory_allocator/axis_data_fifo_4/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_allocator/fpga_malloc_free_0/data_out_port_2_V_V] [get_bd_intf_pins Shell/shared_memory_allocator/axis_data_fifo_5/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_allocator/fpga_malloc_free_0/fifo_out_V_V] [get_bd_intf_pins Shell/shared_memory_allocator/axis_data_fifo_0/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_allocator/fpga_malloc_free_0/fifo_in_V_V] [get_bd_intf_pins Shell/shared_memory_allocator/axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_allocator/malloc1] [get_bd_intf_pins Shell/shared_memory_allocator/axis_data_fifo_4/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_allocator/malloc2] [get_bd_intf_pins Shell/shared_memory_allocator/axis_data_fifo_5/M_AXIS]

#connect the others

connect_bd_net [get_bd_pins Shell/shared_memory_allocator/clk_100mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_2/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/shared_memory_allocator/clk_100mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_5/m_axis_aclk]

connect_bd_net [get_bd_pins Shell/shared_memory_allocator/reset_100mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_2/s_axis_aresetn]

connect_bd_net [get_bd_pins Shell/shared_memory_allocator/clk_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_2/m_axis_aclk]

connect_bd_net [get_bd_pins Shell/shared_memory_allocator/clk_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/shared_memory_allocator/clk_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/shared_memory_allocator/clk_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_3/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/shared_memory_allocator/clk_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_4/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/shared_memory_allocator/clk_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_5/s_axis_aclk]

connect_bd_net [get_bd_pins Shell/shared_memory_allocator/reset_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_0/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/shared_memory_allocator/reset_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_1/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/shared_memory_allocator/reset_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_3/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/shared_memory_allocator/reset_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_4/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/shared_memory_allocator/reset_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_5/s_axis_aresetn]

connect_bd_net [get_bd_pins Shell/shared_memory_allocator/clk_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_switch_0/aclk]
connect_bd_net [get_bd_pins Shell/shared_memory_allocator/clk_200mhz] [get_bd_pins Shell/shared_memory_allocator/fpga_malloc_free_0/aclk]

connect_bd_net [get_bd_pins Shell/shared_memory_allocator/reset_200mhz] [get_bd_pins Shell/shared_memory_allocator/fpga_malloc_free_0/aresetn]
connect_bd_net [get_bd_pins Shell/shared_memory_allocator/reset_200mhz] [get_bd_pins Shell/shared_memory_allocator/axis_switch_0/aresetn]

connect_bd_net [get_bd_pins Shell/shared_memory_allocator/fpga_malloc_free_0/data_out_port_1_almost_full_V] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_4/prog_full]
connect_bd_net [get_bd_pins Shell/shared_memory_allocator/fpga_malloc_free_0/data_out_port_2_almost_full_V] [get_bd_pins Shell/shared_memory_allocator/axis_data_fifo_5/prog_full]
