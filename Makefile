all: set_parameters hls gulf_stream storage_server bit_file binary device_tree

no_outputs: set_half_parameters hls gulf_stream storage_server

hls: 
	$(MAKE) -C ip_repo/hls_ips

set_half_parameters:
	python ship_params.py

gulf_stream:
	rm -rf repos/GULF-Stream
	mkdir repos
	git clone https://github.com/QianfengClarkShen/GULF-Stream.git
	mv GULF-Stream repos/
	$(MAKE) -C repos/GULF-Stream clean_all
	$(MAKE) -C repos/GULF-Stream GULF_Stream_IPCore

set_parameters:
	python ship_params.py
	python num_cores_only.py

storage_server:
	rm -rf SHIP_hardware
	if [ ! -f ip_addr.txt ]; then python ship_params.py; fi
	if [ ! -f gateway_addr.txt ]; then python ship_params.py; fi
	if [ ! -f mac_addr.txt ]; then python ship_params.py; fi
	if [ ! -f subnet.txt ]; then python ship_params.py; fi
	vivado -mode tcl -source src/tcl/ship.tcl -nolog -nojournal

bit_file:
	if [ ! -d output_products ]; then	mkdir output_products; fi
	if [ ! -f num_cores.txt ]; then python num_cores_only.py; fi
	vivado -mode tcl -source src/tcl/make_output.tcl -nolog -nojournal
	rm num_cores.txt

binary:
	if [ ! -d output_products ]; then	mkdir output_products; fi
	bootgen -arch zynqmp -image src/compilation_files/ship.bif -o output_products/storage.bin -w

device_tree:
	if [ ! -d output_products ]; then	mkdir output_products; fi
	dtc -O dtb -o output_products/storage.dtbo -b 0 -@ src/compilation_files/ship.dtsi

clean:
	$(MAKE) -C ip_repo/hls_ips clean
	rm -f ip_addr.txt
	rm -f gateway_addr.txt
	rm -f mac_addr.txt
	rm -f subnet.txt
	rm -f num_cores.txt
	rm -rf repos
	rm -rf SHIP_hardware
	rm -rf output_products
