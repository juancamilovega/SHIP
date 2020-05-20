##ddr4 sub_hierarchy

#create the cells

create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 Shell/ddr4/ddr4_hub
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 Shell/ddr4/ddr_inter
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 Shell/ddr4/polarity_flipper
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 Shell/ddr4/ddr_rst_hub

#configure the cells

set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells Shell/ddr4/polarity_flipper]

set_property -dict [list CONFIG.C0.DDR4_TimePeriod {938} CONFIG.C0.DDR4_InputClockPeriod {3001} CONFIG.C0.DDR4_CLKOUT0_DIVIDE {5} CONFIG.C0.DDR4_MemoryType {SODIMMs} CONFIG.C0.DDR4_MemoryPart {MTA18ASF1G72HZ-2G3} CONFIG.C0.DDR4_DataWidth {72} CONFIG.C0.DDR4_DataMask {NO_DM_NO_DBI} CONFIG.C0.DDR4_Ecc {true} CONFIG.C0.DDR4_CasLatency {15} CONFIG.C0.DDR4_AxiDataWidth {512} CONFIG.C0.DDR4_AxiAddressWidth {33} CONFIG.C0.CK_WIDTH {2} CONFIG.C0.CKE_WIDTH {2} CONFIG.C0.CS_WIDTH {2} CONFIG.C0.ODT_WIDTH {2}] [get_bd_cells Shell/ddr4/ddr4_hub]

set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {2} CONFIG.ENABLE_ADVANCED_OPTIONS {1} CONFIG.XBAR_DATA_WIDTH {128} CONFIG.SYNCHRONIZATION_STAGES {5} CONFIG.S00_HAS_REGSLICE {1} CONFIG.M00_HAS_REGSLICE {1} CONFIG.M01_HAS_REGSLICE {1} CONFIG.S01_HAS_REGSLICE {1}] [get_bd_cells Shell/ddr4/ddr_inter]


#connect the hierarchies

connect_bd_intf_net [get_bd_intf_pins Shell/ddr4/pcie_clk] [get_bd_intf_pins Shell/ddr4/ddr4_hub/C0_SYS_CLK]
connect_bd_intf_net [get_bd_intf_pins Shell/ddr4/ddr4] [get_bd_intf_pins Shell/ddr4/ddr4_hub/C0_DDR4]

connect_bd_intf_net [get_bd_intf_pins Shell/ddr4/mem_1] -boundary_type upper [get_bd_intf_pins Shell/ddr4/ddr_inter/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins Shell/ddr4/mem_2] -boundary_type upper [get_bd_intf_pins Shell/ddr4/ddr_inter/S01_AXI]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/ddr4/ddr_inter/M00_AXI] [get_bd_intf_pins Shell/ddr4/ddr4_hub/C0_DDR4_S_AXI_CTRL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/ddr4/ddr_inter/M01_AXI] [get_bd_intf_pins Shell/ddr4/ddr4_hub/C0_DDR4_S_AXI]

#connect the other pins

connect_bd_net [get_bd_pins Shell/ddr4/global_reset] [get_bd_pins Shell/ddr4/polarity_flipper/Op1]
connect_bd_net [get_bd_pins Shell/ddr4/global_reset] [get_bd_pins Shell/ddr4/ddr_rst_hub/ext_reset_in]

connect_bd_net [get_bd_pins Shell/ddr4/polarity_flipper/Res] [get_bd_pins Shell/ddr4/ddr4_hub/sys_rst]

connect_bd_net [get_bd_pins Shell/ddr4/ddr4_hub/c0_ddr4_ui_clk] [get_bd_pins Shell/ddr4/clk_ddr]
connect_bd_net [get_bd_pins Shell/ddr4/ddr4_hub/c0_ddr4_ui_clk] [get_bd_pins Shell/ddr4/ddr_rst_hub/slowest_sync_clk]
connect_bd_net [get_bd_pins Shell/ddr4/ddr4_hub/c0_ddr4_ui_clk] [get_bd_pins Shell/ddr4/ddr_inter/ACLK]
connect_bd_net [get_bd_pins Shell/ddr4/ddr4_hub/c0_ddr4_ui_clk] [get_bd_pins Shell/ddr4/ddr_inter/S00_ACLK]
connect_bd_net [get_bd_pins Shell/ddr4/ddr4_hub/c0_ddr4_ui_clk] [get_bd_pins Shell/ddr4/ddr_inter/S01_ACLK]
connect_bd_net [get_bd_pins Shell/ddr4/ddr4_hub/c0_ddr4_ui_clk] [get_bd_pins Shell/ddr4/ddr_inter/M00_ACLK]
connect_bd_net [get_bd_pins Shell/ddr4/ddr4_hub/c0_ddr4_ui_clk] [get_bd_pins Shell/ddr4/ddr_inter/M01_ACLK]

connect_bd_net [get_bd_pins Shell/ddr4/ddr_rst_hub/interconnect_aresetn] [get_bd_pins Shell/ddr4/ddr4_hub/c0_ddr4_aresetn]
connect_bd_net [get_bd_pins Shell/ddr4/ddr_rst_hub/interconnect_aresetn] [get_bd_pins Shell/ddr4/ddr_inter/ARESETN]
connect_bd_net [get_bd_pins Shell/ddr4/ddr_rst_hub/interconnect_aresetn] [get_bd_pins Shell/ddr4/ddr_inter/S00_ARESETN]
connect_bd_net [get_bd_pins Shell/ddr4/ddr_rst_hub/interconnect_aresetn] [get_bd_pins Shell/ddr4/ddr_inter/M00_ARESETN]
connect_bd_net [get_bd_pins Shell/ddr4/ddr_rst_hub/interconnect_aresetn] [get_bd_pins Shell/ddr4/ddr_inter/M01_ARESETN]
connect_bd_net [get_bd_pins Shell/ddr4/ddr_rst_hub/interconnect_aresetn] [get_bd_pins Shell/ddr4/ddr_inter/S01_ARESETN]
connect_bd_net [get_bd_pins Shell/ddr4/ddr_rst_hub/interconnect_aresetn] [get_bd_pins Shell/ddr4/reset_ddr]

#set the addresses

assign_bd_address [get_bd_addr_segs {Shell/ddr4/ddr4_hub/C0_DDR4_MEMORY_MAP_CTRL/C0_REG }]
assign_bd_address [get_bd_addr_segs {Shell/ddr4/ddr4_hub/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK }]
set_property offset 0x00A0100000 [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_ddr4_hub_C0_REG}]
set_property offset 0x1000000000 [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_ddr4_hub_C0_DDR4_ADDRESS_BLOCK}]
set_property range 4K [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_ddr4_hub_C0_REG}]
set_property range 8G [get_bd_addr_segs {Shell/main_shell/zynq_ultra_ps_e_0/Data/SEG_ddr4_hub_C0_DDR4_ADDRESS_BLOCK}]
