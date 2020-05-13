#main shell

#create the cells
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 Shell/main_shell/proc_sys_reset_0
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 Shell/main_shell/proc_sys_reset_1
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.2 Shell/main_shell/zynq_ultra_ps_e_0

#configure the ps_pl connection

set_property -dict [apply_preset SHIP_hardware] [get_bd_cells Shell/main_shell/zynq_ultra_ps_e_0]


#apply interface connections
connect_bd_intf_net [get_bd_intf_pins Shell/main_shell/PS_DDR_Memory] [get_bd_intf_pins Shell/main_shell/zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
connect_bd_intf_net [get_bd_intf_pins Shell/main_shell/PS_Controller] [get_bd_intf_pins Shell/main_shell/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD]

#other connections
connect_bd_net [get_bd_pins Shell/main_shell/proc_sys_reset_0/slowest_sync_clk] [get_bd_pins Shell/main_shell/zynq_ultra_ps_e_0/pl_clk0]
connect_bd_net [get_bd_pins Shell/main_shell/proc_sys_reset_1/slowest_sync_clk] [get_bd_pins Shell/main_shell/zynq_ultra_ps_e_0/pl_clk1]
connect_bd_net [get_bd_pins Shell/main_shell/zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins Shell/main_shell/proc_sys_reset_1/ext_reset_in]
connect_bd_net [get_bd_pins Shell/main_shell/proc_sys_reset_0/ext_reset_in] [get_bd_pins Shell/main_shell/zynq_ultra_ps_e_0/pl_resetn0]

connect_bd_net [get_bd_pins Shell/main_shell/zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] [get_bd_pins Shell/main_shell/zynq_ultra_ps_e_0/pl_clk0]
connect_bd_net [get_bd_pins Shell/main_shell/zynq_ultra_ps_e_0/saxihp0_fpd_aclk] [get_bd_pins Shell/main_shell/zynq_ultra_ps_e_0/pl_clk0]

connect_bd_net [get_bd_pins Shell/main_shell/clk_100mhz] [get_bd_pins Shell/main_shell/zynq_ultra_ps_e_0/pl_clk0]
connect_bd_net [get_bd_pins Shell/main_shell/clk_266mhz] [get_bd_pins Shell/main_shell/zynq_ultra_ps_e_0/pl_clk1]
connect_bd_net [get_bd_pins Shell/main_shell/global_reset] [get_bd_pins Shell/main_shell/zynq_ultra_ps_e_0/pl_resetn0]
connect_bd_net [get_bd_pins Shell/main_shell/reset_100mhz] [get_bd_pins Shell/main_shell/proc_sys_reset_0/interconnect_aresetn]
connect_bd_net [get_bd_pins Shell/main_shell/reset_266mhz] [get_bd_pins Shell/main_shell/proc_sys_reset_1/interconnect_aresetn]
connect_bd_net [get_bd_pins Shell/main_shell/pl_ps_irq0] [get_bd_pins Shell/main_shell/zynq_ultra_ps_e_0/pl_ps_irq0]
