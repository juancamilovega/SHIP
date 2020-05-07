#create the cores

create_bd_cell -type ip -vlnv xilinx.com:ip:cmac_usplus:2.5 roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_1
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_2
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_3
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_4
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_5
create_bd_cell -type ip -vlnv clarkshen.com:user:lbus_axis_converter:1.0 roce_sector/udp_parser/GULF_Stream/ethernet/lbus_axis_converter
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 roce_sector/udp_parser/GULF_Stream/ethernet/util_ds_buf_0


#configure the cores

set_property -dict [list CONFIG.CMAC_CAUI4_MODE {1} CONFIG.NUM_LANES {4} CONFIG.GT_REF_CLK_FREQ {322.265625} CONFIG.GT_DRP_CLK {200} CONFIG.TX_FLOW_CONTROL {0} CONFIG.RX_FLOW_CONTROL {0} CONFIG.CMAC_CORE_SELECT {CMACE4_X0Y1} CONFIG.GT_GROUP_SELECT {X0Y12~X0Y15} CONFIG.LANE1_GT_LOC {X0Y12} CONFIG.LANE2_GT_LOC {X0Y13} CONFIG.LANE3_GT_LOC {X0Y14} CONFIG.LANE4_GT_LOC {X0Y15} CONFIG.LANE5_GT_LOC {NA} CONFIG.LANE6_GT_LOC {NA} CONFIG.LANE7_GT_LOC {NA} CONFIG.LANE8_GT_LOC {NA} CONFIG.LANE9_GT_LOC {NA} CONFIG.LANE10_GT_LOC {NA}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0]

set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0]
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {1}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_1]
set_property -dict [list CONFIG.CONST_WIDTH {10} CONFIG.CONST_VAL {0}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_2]
set_property -dict [list CONFIG.CONST_WIDTH {16} CONFIG.CONST_VAL {0}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_3]
set_property -dict [list CONFIG.CONST_WIDTH {12} CONFIG.CONST_VAL {0}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_4]
set_property -dict [list CONFIG.CONST_WIDTH {56} CONFIG.CONST_VAL {0}] [get_bd_cells roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_5]

#connect the interfaces

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/network_tx] [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/lbus_axis_converter/s_axis]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/network_rx] [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/lbus_axis_converter/m_axis]

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/lbus_axis_converter/lbus_tx] [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/lbus_tx]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/lbus_axis_converter/lbus_rx] [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/lbus_rx]

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/gt_ref] [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/gt_ref_clk]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/init] [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/util_ds_buf_0/CLK_IN_D]

connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/gt_rx] [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/gt_rx]
connect_bd_intf_net [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/gt_tx] [get_bd_intf_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/gt_tx]

#other connections

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/util_ds_buf_0/IBUF_OUT] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/init_clk]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/gt_txusrclk2] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/network_clocks]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/gt_txusrclk2] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/rx_clk]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/gt_txusrclk2] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/lbus_axis_converter/clk]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/lbus_axis_converter/rst]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/ctl_tx_test_pattern]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/ctl_tx_send_idle]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/ctl_tx_send_lfi]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/ctl_tx_send_rfi]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/ctl_rx_force_resync]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/ctl_rx_test_pattern]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/drp_en]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/drp_we]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/gtwiz_reset_tx_datapath]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/gtwiz_reset_rx_datapath]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/sys_reset]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/core_rx_reset]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/core_tx_reset]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/core_drp_reset]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_0/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/drp_clk]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_1/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/ctl_tx_enable]
connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_1/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/ctl_rx_enable]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_2/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/drp_addr]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_3/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/drp_di]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_4/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/gt_loopback_in]

connect_bd_net [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/xlconstant_5/dout] [get_bd_pins roce_sector/udp_parser/GULF_Stream/ethernet/cmac_usplus_0/tx_preamblein]


