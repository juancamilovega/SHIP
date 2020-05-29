#######################################################################Shared Memory Subsystem
#create the blocks
create_bd_cell -type hier Shell/shared_memory_subsystem/shared_memory_allocator
create_bd_cell -type hier Shell/shared_memory_subsystem/address_offset_application

#add interfaces to the hierarchies

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/shared_memory_subsystem/address_offset_application/read_out
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/shared_memory_subsystem/address_offset_application/write_out

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/shared_memory_subsystem/address_offset_application/read_in
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 Shell/shared_memory_subsystem/address_offset_application/write_in

create_bd_pin -dir I Shell/shared_memory_subsystem/address_offset_application/clk_200mhz
create_bd_pin -dir I Shell/shared_memory_subsystem/address_offset_application/reset_200mhz

create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/shared_memory_subsystem/shared_memory_allocator/malloc1
create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/shared_memory_subsystem/shared_memory_allocator/malloc2

create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/shared_memory_subsystem/shared_memory_allocator/free1
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0  Shell/shared_memory_subsystem/shared_memory_allocator/free2

create_bd_pin -dir I Shell/shared_memory_subsystem/shared_memory_allocator/clk_200mhz
create_bd_pin -dir I Shell/shared_memory_subsystem/shared_memory_allocator/reset_200mhz
create_bd_pin -dir I Shell/shared_memory_subsystem/shared_memory_allocator/clk_100mhz
create_bd_pin -dir I Shell/shared_memory_subsystem/shared_memory_allocator/reset_100mhz

#connect the interfaces

connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_subsystem/free1] -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/shared_memory_allocator/free1]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_subsystem/free2] -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/shared_memory_allocator/free2]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_subsystem/malloc1] -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/shared_memory_allocator/malloc1]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_subsystem/malloc2] -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/shared_memory_allocator/malloc2]

connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_subsystem/unadjusted_read] -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/address_offset_application/read_in]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_subsystem/unadjusted_write] -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/address_offset_application/write_in]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_subsystem/adjusted_read] -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/address_offset_application/read_out]
connect_bd_intf_net [get_bd_intf_pins Shell/shared_memory_subsystem/adjusted_write] -boundary_type upper [get_bd_intf_pins Shell/shared_memory_subsystem/address_offset_application/write_out]

#connect the other ports

connect_bd_net [get_bd_pins Shell/shared_memory_subsystem/clk_200mhz] [get_bd_pins Shell/shared_memory_subsystem/address_offset_application/clk_200mhz]
connect_bd_net [get_bd_pins Shell/shared_memory_subsystem/clk_200mhz] [get_bd_pins Shell/shared_memory_subsystem/shared_memory_allocator/clk_200mhz]

connect_bd_net [get_bd_pins Shell/shared_memory_subsystem/reset_200mhz] [get_bd_pins Shell/shared_memory_subsystem/shared_memory_allocator/reset_200mhz]
connect_bd_net [get_bd_pins Shell/shared_memory_subsystem/reset_200mhz] [get_bd_pins Shell/shared_memory_subsystem/address_offset_application/reset_200mhz]

connect_bd_net [get_bd_pins Shell/shared_memory_subsystem/clk_100mhz] [get_bd_pins Shell/shared_memory_subsystem/shared_memory_allocator/clk_100mhz]

connect_bd_net [get_bd_pins Shell/shared_memory_subsystem/reset_100mhz] [get_bd_pins Shell/shared_memory_subsystem/shared_memory_allocator/reset_100mhz]
