#axi dma

#create the cells

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 Shell/pl_ps_bridge/axi_dma/axi_dma_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 Shell/pl_ps_bridge/axi_dma/axis_data_fifo_1
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 Shell/pl_ps_bridge/axi_dma/xlconcat_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 Shell/pl_ps_bridge/axi_dma/axi_gpio_0

#configure the cells

set_property -dict [list CONFIG.c_m_axi_s2mm_data_width.VALUE_SRC USER CONFIG.c_single_interface.VALUE_SRC USER] [get_bd_cells Shell/pl_ps_bridge/axi_dma/axi_dma_0]
set_property -dict [list CONFIG.c_sg_length_width {26} CONFIG.c_sg_include_stscntrl_strm {0} CONFIG.c_m_axi_mm2s_data_width {128} CONFIG.c_m_axis_mm2s_tdata_width {64} CONFIG.c_include_mm2s_dre {0} CONFIG.c_mm2s_burst_size {256} CONFIG.c_m_axi_s2mm_data_width {128} CONFIG.c_s2mm_burst_size {256} CONFIG.c_addr_width {64} CONFIG.c_single_interface {1}] [get_bd_cells Shell/pl_ps_bridge/axi_dma/axi_dma_0]
set_property -dict [list CONFIG.C_GPIO_WIDTH {2} CONFIG.C_ALL_INPUTS {1}] [get_bd_cells Shell/pl_ps_bridge/axi_dma/axi_gpio_0]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0]
set_property -dict [list CONFIG.FIFO_DEPTH {64}] [get_bd_cells Shell/pl_ps_bridge/axi_dma/axis_data_fifo_1]
set_property -dict [list CONFIG.TDATA_NUM_BYTES {8} CONFIG.HAS_TKEEP {1} CONFIG.HAS_TLAST {1}] [get_bd_cells Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0]


#connect the interfaces

connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/ps_pl_ctrl] [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/axi_gpio_0/S_AXI]

connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/M_AXIS_MM2S] [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/ps_pl_data] [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/S_AXI_LITE]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/non_sg_mem_port] [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/M_AXI]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/sg_mem_port] [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/M_AXI_SG]

connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/rx_data_in] [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/tx_data_out] [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_1/M_AXIS]

#other connections

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/axi_resetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_1/s_axis_aresetn]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_gpio_0/s_axi_aresetn]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/m_axi_s2mm_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/m_axi_mm2s_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/m_axi_sg_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/s_axi_lite_aclk]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_gpio_0/s_axi_aclk]


connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0/m_axis_tvalid] [get_bd_pins Shell/pl_ps_bridge/axi_dma/xlconcat_0/In0]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/xlconcat_0/In1] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/s_axis_s2mm_tready]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/xlconcat_0/dout] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_gpio_0/gpio_io_i]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/pl_ps_int] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/s2mm_introut]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/ps_pl_int] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/mm2s_introut]

#setup addresses
assign_bd_address [get_bd_addr_segs {Shell/pl_ps_bridge/axi_dma/axi_gpio_0/S_AXI/Reg }]
assign_bd_address [get_bd_addr_segs {Shell/pl_ps_bridge/axi_dma/axi_dma_0/S_AXI_LITE/Reg }]
set_property offset 0x00A0002000 [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_axi_gpio_0_Reg}]
set_property offset 0x00A0010000 [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_axi_dma_0_Reg}]
set_property range 64K [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_axi_dma_0_Reg}]
assign_bd_address [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW }]
assign_bd_address [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_QSPI }]
assign_bd_address [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM }]
assign_bd_address [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_HIGH }]
include_bd_addr_seg [get_bd_addr_segs -excluded Shell/pl_ps_bridge/axi_dma/axi_dma_0/Data_SG/SEG_zynq_ultra_ps_e_0_HP0_LPS_OCM]
include_bd_addr_seg [get_bd_addr_segs -excluded Shell/pl_ps_bridge/axi_dma/axi_dma_0/Data/SEG_zynq_ultra_ps_e_0_HP0_LPS_OCM]
assign_bd_address [get_bd_addr_segs {Shell/ddr4/ddr4_hub/C0_DDR4_MEMORY_MAP_CTRL/C0_REG }]
include_bd_addr_seg [get_bd_addr_segs -excluded Shell/pl_ps_bridge/axi_dma/axi_dma_0/Data_SG/SEG_ddr4_hub_C0_REG]
include_bd_addr_seg [get_bd_addr_segs -excluded Shell/pl_ps_bridge/axi_dma/axi_dma_0/Data/SEG_ddr4_hub_C0_REG]
assign_bd_address [get_bd_addr_segs {Shell/ddr4/ddr4_hub/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK }]

#patch the axidma bug of propagation, connect it like an interface, validate, and then connect it as individual ports so that the tdata value of 64 is propogated

connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0/M_AXIS] [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/S_AXIS_S2MM]
validate_bd_design
delete_bd_objs [get_bd_intf_nets Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0_M_AXIS]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/s_axis_s2mm_tdata] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0/m_axis_tdata]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/s_axis_s2mm_tkeep] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0/m_axis_tkeep]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/s_axis_s2mm_tvalid] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0/m_axis_tvalid]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/s_axis_s2mm_tready] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0/m_axis_tready]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/axi_dma/axi_dma_0/s_axis_s2mm_tlast] [get_bd_pins Shell/pl_ps_bridge/axi_dma/axis_data_fifo_0/m_axis_tlast]
