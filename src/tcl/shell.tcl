#######################################################################build the SHELL
#create the hierarchies in SHELL

#create the cells
create_bd_cell -type hier Shell/pcie_root_complex
create_bd_cell -type hier Shell/main_shell
create_bd_cell -type hier Shell/shared_memory_subsystem
create_bd_cell -type hier Shell/pl_ps_bridge
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 Shell/PS_DDR_INTERCONNECT
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 Shell/ps_interrupts
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 Shell/PS_Master

#make pins in hierarcy cells

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/pcie_root_complex/pcie_dma

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/pcie_root_complex/PCIe_ctrl

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 Shell/pcie_root_complex/pcie_clk

create_bd_pin -dir I -from 3 -to 0 Shell/pcie_root_complex/pci_exp_rxn
create_bd_pin -dir I -from 3 -to 0 Shell/pcie_root_complex/pci_exp_rxp
create_bd_pin -dir I Shell/pcie_root_complex/clk_100mhz
create_bd_pin -dir I Shell/pcie_root_complex/reset_100mhz
create_bd_pin -dir I Shell/pcie_root_complex/global_reset

create_bd_pin -dir O -from 3 -to 0 Shell/pcie_root_complex/pci_exp_txn
create_bd_pin -dir O -from 3 -to 0 Shell/pcie_root_complex/pci_exp_txp
create_bd_pin -dir O Shell/pcie_root_complex/interrupt_out
create_bd_pin -dir O Shell/pcie_root_complex/interrupt_msi_low
create_bd_pin -dir O Shell/pcie_root_complex/interrupt_msi_high
create_bd_pin -dir O Shell/pcie_root_complex/cdma_interrupt

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/main_shell/PS_Controller

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/main_shell/PS_DDR_Memory

create_bd_pin -dir I -from 5 -to 0 Shell/main_shell/pl_ps_irq0

create_bd_pin -dir O Shell/main_shell/clk_100mhz
create_bd_pin -dir O Shell/main_shell/reset_100mhz
create_bd_pin -dir O Shell/main_shell/clk_266mhz
create_bd_pin -dir O Shell/main_shell/reset_266mhz
create_bd_pin -dir O Shell/main_shell/global_reset

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/pl_ps_bridge/ps_pl_data
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/pl_ps_bridge/ps_pl_control

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/pl_ps_bridge/pl_ps_sg
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/pl_ps_bridge/pl_ps_non_sg

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/tx_non_roce_meta
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/tx_non_roce_data
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/change_queue_tx
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/change_queue_rx
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/done
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/ps_ack
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/free

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/rx_non_roce_meta
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/rx_non_roce_data
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/sw_request_tx
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/sw_request_rx
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/mem_transfer
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/pl_ps_bridge/malloc

create_bd_pin -dir I Shell/pl_ps_bridge/clk_100mhz
create_bd_pin -dir I Shell/pl_ps_bridge/reset_100mhz
create_bd_pin -dir I Shell/pl_ps_bridge/clk_266mhz
create_bd_pin -dir I Shell/pl_ps_bridge/reset_266mhz

create_bd_pin -dir O Shell/pl_ps_bridge/PS_PL_interrupt
create_bd_pin -dir O Shell/pl_ps_bridge/PL_PS_interrupt

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/shared_memory_subsystem/free1
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/shared_memory_subsystem/free2

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/shared_memory_subsystem/malloc1
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/shared_memory_subsystem/malloc2

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/shared_memory_subsystem/adjusted_read
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/shared_memory_subsystem/adjusted_write

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/shared_memory_subsystem/unadjusted_read
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/shared_memory_subsystem/unadjusted_write

create_bd_pin -dir I Shell/shared_memory_subsystem/clk_100mhz
create_bd_pin -dir I Shell/shared_memory_subsystem/reset_100mhz
create_bd_pin -dir I Shell/shared_memory_subsystem/clk_266mhz
create_bd_pin -dir I Shell/shared_memory_subsystem/reset_266mhz

#configure the cells

set_property -dict [list CONFIG.NUM_SI {5} CONFIG.NUM_MI {1} CONFIG.ENABLE_ADVANCED_OPTIONS {1} CONFIG.XBAR_DATA_WIDTH {128} CONFIG.SYNCHRONIZATION_STAGES {5} CONFIG.S00_HAS_REGSLICE {1} CONFIG.M00_HAS_REGSLICE {1}] [get_bd_cells Shell/PS_DDR_INTERCONNECT]
set_property -dict [list CONFIG.NUM_PORTS {6}] [get_bd_cells Shell/ps_interrupts]
set_property -dict [list CONFIG.NUM_MI {5} CONFIG.ENABLE_ADVANCED_OPTIONS {1} CONFIG.XBAR_DATA_WIDTH {128} CONFIG.SYNCHRONIZATION_STAGES {5} CONFIG.M00_HAS_REGSLICE {1} CONFIG.M01_HAS_REGSLICE {1} CONFIG.M02_HAS_REGSLICE {1} CONFIG.M03_HAS_REGSLICE {1} CONFIG.S00_HAS_REGSLICE {3} CONFIG.M00_HAS_REGSLICE {1} CONFIG.M04_HAS_REGSLICE {1}] [get_bd_cells Shell/PS_Master]

#connect the interfaces

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/main_shell/PS_Controller] [get_bd_intf_pins Shell/PS_Master/S00_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/main_shell/PS_DDR_Memory] [get_bd_intf_pins Shell/PS_DDR_INTERCONNECT/M00_AXI]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/main_shell/PS_Controller] [get_bd_intf_pins Shell/PS_Master/S00_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/main_shell/PS_DDR_Memory] [get_bd_intf_pins Shell/PS_DDR_INTERCONNECT/M00_AXI]

connect_bd_intf_net [get_bd_intf_pins Shell/pcie_clk] -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/pcie_clk]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/PCIe_ctrl] [get_bd_intf_pins Shell/PS_Master/M02_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pcie_root_complex/pcie_dma] [get_bd_intf_pins Shell/PS_DDR_INTERCONNECT/S02_AXI]

connect_bd_intf_net [get_bd_intf_pins Shell/mem_pages_free] -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/free1]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/free2] [get_bd_intf_pins Shell/pl_ps_bridge/free]
connect_bd_intf_net [get_bd_intf_pins Shell/malloc_port] -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/malloc1]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/malloc2] [get_bd_intf_pins Shell/pl_ps_bridge/malloc]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/adjusted_read] [get_bd_intf_pins Shell/PS_DDR_INTERCONNECT/S01_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/adjusted_write] [get_bd_intf_pins Shell/PS_DDR_INTERCONNECT/S04_AXI]
connect_bd_intf_net [get_bd_intf_pins Shell/rrh_to_mem] -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/unadjusted_read]
connect_bd_intf_net [get_bd_intf_pins Shell/data_storer_write_port] -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/unadjusted_write]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/pl_ps_sg] [get_bd_intf_pins Shell/PS_DDR_INTERCONNECT/S00_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/pl_ps_non_sg] [get_bd_intf_pins Shell/PS_DDR_INTERCONNECT/S03_AXI]
connect_bd_intf_net [get_bd_intf_pins Shell/tx_non_roce_meta] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/tx_non_roce_meta]
connect_bd_intf_net [get_bd_intf_pins Shell/tx_non_roce_data] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/tx_non_roce_data]
connect_bd_intf_net [get_bd_intf_pins Shell/change_queue_tx] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/change_queue_tx]
connect_bd_intf_net [get_bd_intf_pins Shell/change_queue_rx] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/change_queue_rx]
connect_bd_intf_net [get_bd_intf_pins Shell/done_sig] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/done]
connect_bd_intf_net [get_bd_intf_pins Shell/PS_ACK_port] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/ps_ack]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/ps_pl_data] [get_bd_intf_pins Shell/PS_Master/M00_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/ps_pl_control] [get_bd_intf_pins Shell/PS_Master/M01_AXI]
connect_bd_intf_net [get_bd_intf_pins Shell/rx_non_roce_meta] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/rx_non_roce_meta]
connect_bd_intf_net [get_bd_intf_pins Shell/rx_non_roce_data] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/rx_non_roce_data]
connect_bd_intf_net [get_bd_intf_pins Shell/sw_request_tx] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/sw_request_tx]
connect_bd_intf_net [get_bd_intf_pins Shell/sw_request_rx] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/sw_request_rx]
connect_bd_intf_net [get_bd_intf_pins Shell/mem_transfer_out] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/mem_transfer]

connect_bd_intf_net [get_bd_intf_pins Shell/tx_interpreter_config] -boundary_type upper [get_bd_intf_pins Shell/PS_Master/M03_AXI]
connect_bd_intf_net [get_bd_intf_pins Shell/Gulf_Stream_config] -boundary_type upper [get_bd_intf_pins Shell/PS_Master/M04_AXI]

#other connections

connect_bd_net [get_bd_pins Shell/clk_network] [get_bd_pins Shell/PS_Master/M04_ACLK]

connect_bd_net [get_bd_pins Shell/reset_network] [get_bd_pins Shell/PS_Master/M04_ARESETN]

connect_bd_net [get_bd_pins Shell/main_shell/clk_266mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/ACLK] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_266mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/M00_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_266mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/S01_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_266mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/S04_ACLK] -boundary_type upper

connect_bd_net [get_bd_pins Shell/main_shell/reset_266mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_266mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/M00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_266mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/S01_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_266mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/S04_ARESETN] -boundary_type upper

connect_bd_net [get_bd_pins Shell/main_shell/clk_100mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/S00_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_100mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/S02_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_100mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/S03_ACLK] -boundary_type upper

connect_bd_net [get_bd_pins Shell/main_shell/reset_100mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/S00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_100mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/S02_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_100mhz] [get_bd_pins Shell/PS_DDR_INTERCONNECT/S03_ARESETN] -boundary_type upper

connect_bd_net [get_bd_pins Shell/main_shell/clk_266mhz] [get_bd_pins Shell/PS_Master/ACLK] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_266mhz] [get_bd_pins Shell/PS_Master/S00_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_266mhz] [get_bd_pins Shell/PS_Master/M03_ACLK] -boundary_type upper

connect_bd_net [get_bd_pins Shell/main_shell/reset_266mhz] [get_bd_pins Shell/PS_Master/ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_266mhz] [get_bd_pins Shell/PS_Master/S00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_266mhz] [get_bd_pins Shell/PS_Master/M03_ARESETN] -boundary_type upper

connect_bd_net [get_bd_pins Shell/main_shell/clk_100mhz] [get_bd_pins Shell/PS_Master/M00_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_100mhz] [get_bd_pins Shell/PS_Master/M01_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_100mhz] [get_bd_pins Shell/PS_Master/M02_ACLK] -boundary_type upper

connect_bd_net [get_bd_pins Shell/main_shell/reset_100mhz] [get_bd_pins Shell/PS_Master/M00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_100mhz] [get_bd_pins Shell/PS_Master/M01_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_100mhz] [get_bd_pins Shell/PS_Master/M02_ARESETN] -boundary_type upper

connect_bd_net [get_bd_pins Shell/main_shell/clk_100mhz] [get_bd_pins Shell/shared_memory_subsystem/clk_100mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_100mhz] [get_bd_pins Shell/pcie_root_complex/clk_100mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/clk_100mhz] -boundary_type upper

connect_bd_net [get_bd_pins Shell/main_shell/reset_100mhz] [get_bd_pins Shell/shared_memory_subsystem/reset_100mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_100mhz] [get_bd_pins Shell/pcie_root_complex/reset_100mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/reset_100mhz] -boundary_type upper

connect_bd_net [get_bd_pins Shell/main_shell/clk_266mhz] [get_bd_pins Shell/shared_memory_subsystem/clk_266mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_266mhz] [get_bd_pins Shell/pl_ps_bridge/clk_266mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/clk_266mhz] [get_bd_pins Shell/clk_266mhz] -boundary_type upper

connect_bd_net [get_bd_pins Shell/main_shell/reset_266mhz] [get_bd_pins Shell/shared_memory_subsystem/reset_266mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_266mhz] [get_bd_pins Shell/pl_ps_bridge/reset_266mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/reset_266mhz] [get_bd_pins Shell/reset_266mhz] -boundary_type upper

connect_bd_net [get_bd_pins Shell/main_shell/global_reset] [get_bd_pins Shell/pcie_root_complex/global_reset] -boundary_type upper
connect_bd_net [get_bd_pins Shell/main_shell/global_reset] [get_bd_pins Shell/pl_reset] -boundary_type upper

connect_bd_net [get_bd_pins Shell/pci_exp_txn] [get_bd_pins Shell/pcie_root_complex/pci_exp_txn]
connect_bd_net [get_bd_pins Shell/pci_exp_txp] [get_bd_pins Shell/pcie_root_complex/pci_exp_txp]
connect_bd_net [get_bd_pins Shell/pci_exp_rxn] [get_bd_pins Shell/pcie_root_complex/pci_exp_rxn]
connect_bd_net [get_bd_pins Shell/pci_exp_rxp] [get_bd_pins Shell/pcie_root_complex/pci_exp_rxp]

connect_bd_net [get_bd_pins Shell/ps_interrupts/dout] [get_bd_pins Shell/main_shell/pl_ps_irq0]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/PS_PL_interrupt] [get_bd_pins Shell/ps_interrupts/In0]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/PL_PS_interrupt] [get_bd_pins Shell/ps_interrupts/In1]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/interrupt_out] [get_bd_pins Shell/ps_interrupts/In2]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/interrupt_msi_low] [get_bd_pins Shell/ps_interrupts/In3]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/interrupt_msi_high] [get_bd_pins Shell/ps_interrupts/In4]
connect_bd_net [get_bd_pins Shell/pcie_root_complex/cdma_interrupt] [get_bd_pins Shell/ps_interrupts/In5]
