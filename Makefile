all: hls gulf_stream storage_server

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

clean:
	$(MAKE) -C ip_repo/hls_ips clean
	rm -rf repos
	rm -rf SHIP_hardware
