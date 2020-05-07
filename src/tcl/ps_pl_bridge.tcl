#PS PL Bridge

#create the cells

create_bd_cell -type hier Shell/pl_ps_bridge/rx_path
create_bd_cell -type hier Shell/pl_ps_bridge/axi_dma
create_bd_cell -type hier Shell/pl_ps_bridge/tx_path

#add ports to the hierarchies

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/pl_ps_bridge/axi_dma/ps_pl_data
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/pl_ps_bridge/axi_dma/ps_pl_ctrl

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/pl_ps_bridge/axi_dma/sg_mem_port
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/pl_ps_bridge/axi_dma/non_sg_mem_port

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/axi_dma/rx_data_in

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/axi_dma/tx_data_out

create_bd_pin -dir I Shell/pl_ps_bridge/axi_dma/clk_100mhz
create_bd_pin -dir I Shell/pl_ps_bridge/axi_dma/reset_100mhz

create_bd_pin -dir O Shell/pl_ps_bridge/axi_dma/ps_pl_int
create_bd_pin -dir O Shell/pl_ps_bridge/axi_dma/pl_ps_int

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/rx_path/sw_request_rx
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/rx_path/sw_request_tx
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/rx_path/rx_non_roce_data
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/rx_path/rx_non_roce_meta
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/rx_path/sw_fifo_req
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/rx_path/mem_transfer
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/rx_path/malloc

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/rx_path/rx_data_out

create_bd_pin -dir I Shell/pl_ps_bridge/rx_path/clk_100mhz
create_bd_pin -dir I Shell/pl_ps_bridge/rx_path/reset_100mhz
create_bd_pin -dir I Shell/pl_ps_bridge/rx_path/clk_266mhz
create_bd_pin -dir I Shell/pl_ps_bridge/rx_path/reset_266mhz

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/tx_path/tx_data_in

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/tx_path/change_queue_rx
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/tx_path/change_queue_tx
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/tx_path/done
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/tx_path/tx_non_roce_data
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/tx_path/tx_non_roce_meta
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/tx_path/ps_ack
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/tx_path/sw_fifo_req
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/pl_ps_bridge/tx_path/free

create_bd_pin -dir I Shell/pl_ps_bridge/tx_path/clk_100mhz
create_bd_pin -dir I Shell/pl_ps_bridge/tx_path/reset_100mhz
create_bd_pin -dir I Shell/pl_ps_bridge/tx_path/clk_266mhz

#connect interfaces

connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/ps_pl_data] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/ps_pl_data]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/ps_pl_control] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/ps_pl_ctrl]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/rx_data_in] [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_data_out]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/tx_data_out] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_data_in]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/pl_ps_sg] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/sg_mem_port]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/pl_ps_non_sg] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/axi_dma/non_sg_mem_port]

connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/sw_request_rx] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/sw_request_rx]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/sw_request_tx] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/sw_request_tx]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_non_roce_meta] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_non_roce_meta]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/rx_non_roce_data] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/rx_non_roce_data]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/mem_transfer] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/mem_transfer]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/malloc] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/malloc]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/rx_path/sw_fifo_req] [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/sw_fifo_req]

connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/change_queue_rx] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/change_queue_rx]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/change_queue_tx] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/change_queue_tx]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/done] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/done]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_non_roce_data] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_non_roce_data]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/tx_non_roce_meta] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/tx_non_roce_meta]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/ps_ack] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/ps_ack]
connect_bd_intf_net [get_bd_intf_pins Shell/pl_ps_bridge/free] -boundary_type upper [get_bd_intf_pins Shell/pl_ps_bridge/tx_path/free]

#other ports

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_100mhz]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/clk_100mhz]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/clk_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_100mhz]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/clk_266mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/clk_266mhz]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/clk_266mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/clk_266mhz]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_100mhz]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/axi_dma/reset_100mhz]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/reset_100mhz] [get_bd_pins Shell/pl_ps_bridge/tx_path/reset_100mhz]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/reset_266mhz] [get_bd_pins Shell/pl_ps_bridge/rx_path/reset_266mhz]

connect_bd_net [get_bd_pins Shell/pl_ps_bridge/PS_PL_interrupt] [get_bd_pins Shell/pl_ps_bridge/axi_dma/ps_pl_int]
connect_bd_net [get_bd_pins Shell/pl_ps_bridge/PL_PS_interrupt] [get_bd_pins Shell/pl_ps_bridge/axi_dma/pl_ps_int]
