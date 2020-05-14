#ROOT COMPLEX
#create the blocks
create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 Shell/pcie_root_complex/xdma_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 Shell/pcie_root_complex/PCIe_hub
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 Shell/pcie_root_complex/cdma_interconnect
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 Shell/pcie_root_complex/mem_access
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 Shell/pcie_root_complex/axi_cdma_0
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 Shell/pcie_root_complex/util_ds_buf_0


#configure the blocks

set_property -dict [list CONFIG.C_M_AXI_DATA_WIDTH {128} CONFIG.C_M_AXI_MAX_BURST_LEN {4} CONFIG.C_INCLUDE_SG {0} CONFIG.C_ADDR_WIDTH {40}] [get_bd_cells Shell/pcie_root_complex/axi_cdma_0]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {2}] [get_bd_cells Shell/pcie_root_complex/cdma_interconnect]
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1} CONFIG.ENABLE_ADVANCED_OPTIONS {1} CONFIG.XBAR_DATA_WIDTH {64}] [get_bd_cells Shell/pcie_root_complex/mem_access]
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {2}] [get_bd_cells Shell/pcie_root_complex/PCIe_hub]
set_property -dict [list CONFIG.functional_mode {AXI_Bridge} CONFIG.mode_selection {Advanced} CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} CONFIG.pl_link_cap_max_link_width {X4} CONFIG.pl_link_cap_max_link_speed {5.0_GT/s} CONFIG.axi_addr_width {64} CONFIG.axi_data_width {64_bit} CONFIG.axisten_freq {250} CONFIG.pf0_device_id {9124} CONFIG.pf0_base_class_menu {Bridge_device} CONFIG.pf0_class_code_base {06} CONFIG.pf0_sub_class_interface_menu {PCI_to_PCI_bridge} CONFIG.pf0_class_code_sub {04} CONFIG.pf0_class_code_interface {00} CONFIG.pf0_class_code {060400} CONFIG.xdma_axilite_slave {true} CONFIG.en_gt_selection {true} CONFIG.select_quad {GTY_Quad_128} CONFIG.plltype {QPLL1} CONFIG.type1_membase_memlimit_enable {Enabled} CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} CONFIG.BASEADDR {0x00000000} CONFIG.HIGHADDR {0x001FFFFF} CONFIG.pf0_bar0_enabled {false} CONFIG.pf1_class_code {060700} CONFIG.pf1_base_class_menu {Bridge_device} CONFIG.pf1_class_code_base {06} CONFIG.pf1_class_code_sub {07} CONFIG.pf1_sub_class_interface_menu {CardBus_bridge} CONFIG.pf1_class_code_interface {00} CONFIG.pf1_bar2_enabled {false} CONFIG.pf1_bar2_64bit {false} CONFIG.pf1_bar4_enabled {false} CONFIG.pf1_bar4_64bit {false} CONFIG.dma_reset_source_sel {Phy_Ready} CONFIG.pf0_bar0_type_mqdma {Memory} CONFIG.pf1_bar0_type_mqdma {Memory} CONFIG.pf2_bar0_type_mqdma {Memory} CONFIG.pf3_bar0_type_mqdma {Memory} CONFIG.pf0_sriov_bar0_type {Memory} CONFIG.pf1_sriov_bar0_type {Memory} CONFIG.pf2_sriov_bar0_type {Memory} CONFIG.pf3_sriov_bar0_type {Memory} CONFIG.PF0_DEVICE_ID_mqdma {9134} CONFIG.PF2_DEVICE_ID_mqdma {9134} CONFIG.PF3_DEVICE_ID_mqdma {9134} CONFIG.pf0_base_class_menu_mqdma {Bridge_device} CONFIG.pf0_class_code_base_mqdma {06} CONFIG.pf0_class_code_mqdma {068000} CONFIG.pf1_base_class_menu_mqdma {Bridge_device} CONFIG.pf1_class_code_base_mqdma {06} CONFIG.pf1_class_code_mqdma {068000} CONFIG.pf2_base_class_menu_mqdma {Bridge_device} CONFIG.pf2_class_code_base_mqdma {06} CONFIG.pf2_class_code_mqdma {068000} CONFIG.pf3_base_class_menu_mqdma {Bridge_device} CONFIG.pf3_class_code_base_mqdma {06} CONFIG.pf3_class_code_mqdma {068000} CONFIG.c_s_axi_supports_narrow_burst {true} CONFIG.msi_rx_pin_en {TRUE} CONFIG.mpsoc_pl_rp_enable {true} CONFIG.enable_pcie_debug {True}] [get_bd_cells Shell/pcie_root_complex/xdma_0]
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] [get_bd_cells Shell/pcie_root_complex/util_ds_buf_0]


#connect interfaces
connect_bd_intf_net [get_bd_intf_pins Shell/pcie_root_complex/xdma_0/pcie_mgt] -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/pcie_ports]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/PCIe_hub/M00_AXI] [get_bd_intf_pins Shell/pcie_root_complex/xdma_0/S_AXI_B]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/PCIe_hub/M01_AXI] [get_bd_intf_pins Shell/pcie_root_complex/xdma_0/S_AXI_LITE]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/cdma_interconnect/M00_AXI] [get_bd_intf_pins Shell/pcie_root_complex/mem_access/S00_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/cdma_interconnect/M01_AXI] [get_bd_intf_pins Shell/pcie_root_complex/PCIe_hub/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins Shell/pcie_root_complex/xdma_0/M_AXI_B] -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/mem_access/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins Shell/pcie_root_complex/axi_cdma_0/S_AXI_LITE] -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/CDMA_ctrl]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/cdma_interconnect/S00_AXI] [get_bd_intf_pins Shell/pcie_root_complex/axi_cdma_0/M_AXI]
connect_bd_intf_net [get_bd_intf_pins Shell/pcie_root_complex/pcie_clk] [get_bd_intf_pins Shell/pcie_root_complex/util_ds_buf_0/CLK_IN_D]
connect_bd_intf_net [get_bd_intf_pins Shell/pcie_root_complex/PCIe_ctrl] -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/PCIe_hub/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins Shell/pcie_root_complex/pcie_dma] -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/mem_access/M00_AXI]

#make other connections
connect_bd_net [get_bd_pins Shell/pcie_root_complex/xdma_0/axi_aclk] [get_bd_pins Shell/pcie_root_complex/mem_access/S01_ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/xdma_0/axi_aclk] [get_bd_pins Shell/pcie_root_complex/PCIe_Hub/ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/xdma_0/axi_aclk] [get_bd_pins Shell/pcie_root_complex/PCIe_Hub/M00_ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/xdma_0/axi_aclk] [get_bd_pins Shell/pcie_root_complex/PCIe_Hub/M01_ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/xdma_0/axi_aresetn] [get_bd_pins Shell/pcie_root_complex/mem_access/S01_ARESETN]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/xdma_0/axi_aresetn] [get_bd_pins Shell/pcie_root_complex/PCIe_Hub/M00_ARESETN]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/xdma_0/axi_aresetn] [get_bd_pins Shell/pcie_root_complex/PCIe_Hub/M01_ARESETN]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/xdma_0/axi_aresetn] [get_bd_pins Shell/pcie_root_complex/PCIe_Hub/ARESETN]

connect_bd_net [get_bd_pins Shell/pcie_root_complex/clk_100mhz] [get_bd_pins Shell/pcie_root_complex/PCIe_Hub/S00_ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/clk_100mhz] [get_bd_pins Shell/pcie_root_complex/PCIe_Hub/S01_ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/clk_100mhz] [get_bd_pins Shell/pcie_root_complex/cdma_interconnect/ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/clk_100mhz] [get_bd_pins Shell/pcie_root_complex/cdma_interconnect/S00_ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/clk_100mhz] [get_bd_pins Shell/pcie_root_complex/cdma_interconnect/M00_ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/clk_100mhz] [get_bd_pins Shell/pcie_root_complex/cdma_interconnect/M01_ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/clk_100mhz] [get_bd_pins Shell/pcie_root_complex/mem_access/ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/clk_100mhz] [get_bd_pins Shell/pcie_root_complex/mem_access/S00_ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/clk_100mhz] [get_bd_pins Shell/pcie_root_complex/mem_access/M00_ACLK]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/clk_100mhz] [get_bd_pins Shell/pcie_root_complex/axi_cdma_0/m_axi_aclk]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/clk_100mhz] [get_bd_pins Shell/pcie_root_complex/axi_cdma_0/s_axi_lite_aclk]

connect_bd_net [get_bd_pins Shell/pcie_root_complex/reset_100mhz] [get_bd_pins Shell/pcie_root_complex/PCIe_Hub/S00_ARESETN]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/reset_100mhz] [get_bd_pins Shell/pcie_root_complex/PCIe_Hub/S01_ARESETN]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/reset_100mhz] [get_bd_pins Shell/pcie_root_complex/cdma_interconnect/ARESETN]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/reset_100mhz] [get_bd_pins Shell/pcie_root_complex/cdma_interconnect/S00_ARESETN]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/reset_100mhz] [get_bd_pins Shell/pcie_root_complex/cdma_interconnect/M00_ARESETN]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/reset_100mhz] [get_bd_pins Shell/pcie_root_complex/cdma_interconnect/M01_ARESETN]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/reset_100mhz] [get_bd_pins Shell/pcie_root_complex/mem_access/ARESETN]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/reset_100mhz] [get_bd_pins Shell/pcie_root_complex/mem_access/S00_ARESETN]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/reset_100mhz] [get_bd_pins Shell/pcie_root_complex/mem_access/M00_ARESETN]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/reset_100mhz] [get_bd_pins Shell/pcie_root_complex/axi_cdma_0/s_axi_lite_aresetn]

connect_bd_net [get_bd_pins Shell/pcie_root_complex/util_ds_buf_0/IBUF_OUT] [get_bd_pins Shell/pcie_root_complex/xdma_0/sys_clk_gt]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/util_ds_buf_0/IBUF_DS_ODIV2] [get_bd_pins Shell/pcie_root_complex/xdma_0/sys_clk]

connect_bd_net [get_bd_pins Shell/pcie_root_complex/interrupt_out] [get_bd_pins Shell/pcie_root_complex/xdma_0/interrupt_out]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/interrupt_msi_low] [get_bd_pins Shell/pcie_root_complex/xdma_0/interrupt_out_msi_vec0to31]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/interrupt_msi_high] [get_bd_pins Shell/pcie_root_complex/xdma_0/interrupt_out_msi_vec32to63]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/cdma_interrupt] [get_bd_pins Shell/pcie_root_complex/axi_cdma_0/cdma_introut]

connect_bd_net [get_bd_pins Shell/pcie_root_complex/global_reset] [get_bd_pins Shell/pcie_root_complex/xdma_0/sys_rst_n]

#set the addresses
assign_bd_address [get_bd_addr_segs {Shell/pcie_root_complex/axi_cdma_0/S_AXI_LITE/Reg }]
assign_bd_address [get_bd_addr_segs {Shell/pcie_root_complex/xdma_0/S_AXI_B/BAR0 }]
assign_bd_address [get_bd_addr_segs {Shell/pcie_root_complex/xdma_0/S_AXI_LITE/CTL0 }]
set_property offset 0x00A0050000 [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_axi_cdma_0_Reg}]
set_property range 64K [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_axi_cdma_0_Reg}]
set_property offset 0x0480000000 [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_xdma_0_CTL0}]
set_property offset 0x0400000000 [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_xdma_0_BAR0}]
set_property range 2G [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_xdma_0_BAR0}]
set_property range 2G [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_xdma_0_CTL0}]
assign_bd_address [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW }]
assign_bd_address [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_QSPI }]
assign_bd_address [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM }]
assign_bd_address [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_HIGH }]
include_bd_addr_seg [get_bd_addr_segs -excluded Shell/pcie_root_complex/axi_cdma_0/Data/SEG_zynq_ultra_ps_e_0_HP0_LPS_OCM]
include_bd_addr_seg [get_bd_addr_segs -excluded Shell/pcie_root_complex/axi_cdma_0/Data/SEG_axi_cdma_0_Reg]
set_property offset 0x0400000000 [get_bd_addr_segs {Shell/pcie_root_complex/axi_cdma_0/Data/SEG_xdma_0_BAR0}]
set_property offset 0x0480000000 [get_bd_addr_segs {Shell/pcie_root_complex/axi_cdma_0/Data/SEG_xdma_0_CTL0}]
set_property range 2G [get_bd_addr_segs {Shell/pcie_root_complex/axi_cdma_0/Data/SEG_xdma_0_BAR0}]
set_property range 2G [get_bd_addr_segs {Shell/pcie_root_complex/axi_cdma_0/Data/SEG_xdma_0_CTL0}]
