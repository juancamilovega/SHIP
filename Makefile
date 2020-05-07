all: hls gulf_stream storage_server device_tree bit_file binary

hls: 
	$(MAKE) -C ip_repo/hls_ips

gulf_stream:
	rm -rf repos/GULF-Stream
	mkdir repos
	git clone https://github.com/QianfengClarkShen/GULF-Stream.git
	mv GULF-Stream repos/
	$(MAKE) -C repos/GULF-Stream clean_all
	$(MAKE) -C repos/GULF-Stream GULF_Stream_IPCore

storage_server:
	rm -rf SHIP_hardware
	vivado -mode tcl -source src/tcl/ship.tcl -nolog -nojournal

bit_file:
	if [ ! -d output_products ]; then	mkdir output_products; fi
	vivado -mode tcl -source src/tcl/make_output.tcl -nolog -nojournal

binary:
	if [ ! -d output_products ]; then	mkdir output_products; fi
	bootgen -arch zynqmp -image src/compilation_files/ship.bif -o output_products/storage.bin -w

device_tree:
	if [ ! -d output_products ]; then	mkdir output_products; fi
	dtc -O dtb -o output_products/storage.dtbo -b 0 -@ src/compilation_files/ship.dtsi

clean:
	$(MAKE) -C ip_repo/hls_ips clean
	rm -rf repos
	rm -rf SHIP_hardware
	rm -rf output_products
