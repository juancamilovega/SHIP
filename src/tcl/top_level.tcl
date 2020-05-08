#build the top level

#create external pins
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_clk
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_ref
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 init

create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 gt_rx
create_bd_intf_port -mode Master -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 gt_tx

#configure external ports

set_property CONFIG.FREQ_HZ 322265625 [get_bd_intf_ports /gt_ref]

create_bd_port -dir I -from 3 -to 0 pci_exp_rxn
create_bd_port -dir I -from 3 -to 0 pci_exp_rxp
create_bd_port -dir O -from 3 -to 0 pci_exp_txn
create_bd_port -dir O -from 3 -to 0 pci_exp_txp

#create the cells
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 base_address
create_bd_cell -type hier Shell
create_bd_cell -type hier read_sector
create_bd_cell -type hier write_sector
create_bd_cell -type hier ack_handler
create_bd_cell -type hier roce_sector

#make pins in hierarcy cells

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 Shell/pcie_clk

create_bd_pin -dir I -from 3 -to 0 Shell/pci_exp_rxn
create_bd_pin -dir I -from 3 -to 0 Shell/pci_exp_rxp

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/rrh_to_mem
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/data_storer_write_port

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/rx_non_roce_meta
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/rx_non_roce_data
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/mem_transfer_out
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/sw_request_rx
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/sw_request_tx
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/mem_pages_free

create_bd_pin -dir O -from 3 -to 0 Shell/pci_exp_txn
create_bd_pin -dir O -from 3 -to 0 Shell/pci_exp_txp
create_bd_pin -dir O Shell/pl_reset
create_bd_pin -dir O Shell/reset_266mhz
create_bd_pin -dir O Shell/clk_266mhz
create_bd_pin -dir I Shell/clk_network
create_bd_pin -dir I Shell/reset_network

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/tx_non_roce_meta
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/tx_non_roce_data
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/change_queue_tx
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/change_queue_rx
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/done_sig
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/PS_ACK_port
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 Shell/malloc_port

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/tx_interpreter_config
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/Gulf_Stream_config

connect_bd_intf_net [get_bd_intf_ports pcie_clk] -boundary_type upper [get_bd_intf_pins Shell/pcie_clk]

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ack_handler/ack_flags
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ack_handler/ack

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 ack_handler/read_ack
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 ack_handler/write_ack
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 ack_handler/ps_ack

create_bd_pin -dir I ack_handler/clk_266mhz
create_bd_pin -dir I ack_handler/reset_266mhz

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 roce_sector/gt_ref
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 roce_sector/init

create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 roce_sector/gt_rx
create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cmac_usplus:gt_ports:2.0 roce_sector/gt_tx

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 roce_sector/tx_interpreter_config
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 roce_sector/Gulf_Stream_config

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/rx_non_roce_meta
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/rx_non_roce_data
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/read_request_data
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/read_request_flag
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/write_reth
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/write_flags
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/write_data

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/tx_non_roce_data
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/tx_non_roce_meta
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/read_flags
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/read_aeth
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/read_payload
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/ack_flags
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 roce_sector/ack

create_bd_pin -dir O roce_sector/clk_network
create_bd_pin -dir O roce_sector/reset_network

create_bd_pin -dir I roce_sector/clk_266mhz
create_bd_pin -dir I roce_sector/reset_266mhz
create_bd_pin -dir I roce_sector/reset_global

create_bd_pin -dir I write_sector/clk_266mhz
create_bd_pin -dir I write_sector/reset_266mhz
create_bd_pin -dir I -from 31 -to 0 write_sector/base_address

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 write_sector/malloc
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 write_sector/change_queue
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 write_sector/reth
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 write_sector/flags
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 write_sector/data

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 write_sector/mem_transfer
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 write_sector/sw_request
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 write_sector/ack

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 write_sector/memory_write_port

create_bd_pin -dir I read_sector/clk_266mhz
create_bd_pin -dir I read_sector/reset_266mhz
create_bd_pin -dir I -from 31 -to 0 read_sector/base_address

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 read_sector/request
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 read_sector/flags
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 read_sector/change_queue
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 read_sector/done

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 read_sector/read_payload
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 read_sector/read_aeth
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 read_sector/read_flags
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 read_sector/ack
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 read_sector/sw_request
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 read_sector/mem_free

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 read_sector/rrh_to_mem

#configure blocks
set_property -dict [list CONFIG.CONST_WIDTH {32} CONFIG.CONST_VAL {0}] [get_bd_cells base_address]

#apply interface connections
connect_bd_intf_net [get_bd_intf_ports gt_ref] -boundary_type upper [get_bd_intf_pins roce_sector/gt_ref]
connect_bd_intf_net [get_bd_intf_ports init] -boundary_type upper [get_bd_intf_pins roce_sector/init]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/tx_interpreter_config] [get_bd_intf_pins Shell/tx_interpreter_config]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/Gulf_Stream_config] [get_bd_intf_pins Shell/Gulf_Stream_config]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/tx_non_roce_data] [get_bd_intf_pins Shell/tx_non_roce_data]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/tx_non_roce_meta] [get_bd_intf_pins Shell/tx_non_roce_meta]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/read_flags] [get_bd_intf_pins read_sector/read_flags]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/read_aeth] [get_bd_intf_pins read_sector/read_aeth]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/read_payload] [get_bd_intf_pins read_sector/read_payload]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/ack_flags] [get_bd_intf_pins ack_handler/ack_flags]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/ack] [get_bd_intf_pins ack_handler/ack]
connect_bd_intf_net [get_bd_intf_ports gt_rx] -boundary_type upper [get_bd_intf_pins roce_sector/gt_rx]
connect_bd_intf_net [get_bd_intf_ports gt_tx] -boundary_type upper [get_bd_intf_pins roce_sector/gt_tx]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/rx_non_roce_meta] [get_bd_intf_pins Shell/rx_non_roce_meta]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/rx_non_roce_data] [get_bd_intf_pins Shell/rx_non_roce_data]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/read_request_data] [get_bd_intf_pins read_sector/request]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/read_request_flag] [get_bd_intf_pins read_sector/flags]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/write_reth] [get_bd_intf_pins write_sector/reth]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/write_flags] [get_bd_intf_pins write_sector/flags]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins roce_sector/write_data] [get_bd_intf_pins write_sector/data]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins write_sector/malloc] [get_bd_intf_pins Shell/malloc_port]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins write_sector/change_queue] [get_bd_intf_pins Shell/change_queue_rx]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins write_sector/mem_transfer] [get_bd_intf_pins Shell/mem_transfer_out]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins write_sector/sw_request] [get_bd_intf_pins Shell/sw_request_rx]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins write_sector/ack] [get_bd_intf_pins ack_handler/write_ack]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins write_sector/memory_write_port] [get_bd_intf_pins Shell/data_storer_write_port]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ack_handler/read_ack] [get_bd_intf_pins read_sector/ack]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ack_handler/ps_ack] [get_bd_intf_pins Shell/PS_ACK_port]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins read_sector/change_queue] [get_bd_intf_pins Shell/change_queue_tx]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins read_sector/done] [get_bd_intf_pins Shell/done_sig]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins read_sector/sw_request] [get_bd_intf_pins Shell/sw_request_tx]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins read_sector/mem_free] [get_bd_intf_pins Shell/mem_pages_free]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins read_sector/rrh_to_mem] [get_bd_intf_pins Shell/rrh_to_mem]
#apply other connections

connect_bd_net [get_bd_ports pci_exp_rxn] [get_bd_pins Shell/pci_exp_rxn]
connect_bd_net [get_bd_ports pci_exp_rxp] [get_bd_pins Shell/pci_exp_rxp]
connect_bd_net [get_bd_ports pci_exp_txn] [get_bd_pins Shell/pci_exp_txn]
connect_bd_net [get_bd_ports pci_exp_txp] [get_bd_pins Shell/pci_exp_txp]

connect_bd_net [get_bd_pins roce_sector/clk_network] [get_bd_pins Shell/clk_network] -boundary_type upper
connect_bd_net [get_bd_pins roce_sector/reset_network] [get_bd_pins Shell/reset_network] -boundary_type upper

connect_bd_net [get_bd_pins base_address/dout] [get_bd_pins read_sector/base_address]
connect_bd_net [get_bd_pins base_address/dout] [get_bd_pins write_sector/base_address]

connect_bd_net [get_bd_pins Shell/pl_reset] [get_bd_pins roce_sector/reset_global] -boundary_type upper

connect_bd_net [get_bd_pins Shell/clk_266mhz] [get_bd_pins roce_sector/clk_266mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/clk_266mhz] [get_bd_pins read_sector/clk_266mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/clk_266mhz] [get_bd_pins write_sector/clk_266mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/clk_266mhz] [get_bd_pins ack_handler/clk_266mhz] -boundary_type upper

connect_bd_net [get_bd_pins Shell/reset_266mhz] [get_bd_pins roce_sector/reset_266mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/reset_266mhz] [get_bd_pins read_sector/reset_266mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/reset_266mhz] [get_bd_pins write_sector/reset_266mhz] -boundary_type upper
connect_bd_net [get_bd_pins Shell/reset_266mhz] [get_bd_pins ack_handler/reset_266mhz] -boundary_type upper

