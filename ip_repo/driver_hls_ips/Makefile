all: write_core driver_tx driver_rx stream_meta_to_gulf

write_core: ../../src/tcl/hls_builder.tcl ../../src/vhls/*
	rm -f Namefile.txt
	echo 'write_core' > Namefile.txt	
	rm -rf write_core
	mkdir write_core
	vivado_hls ../../src/tcl/hls_builder.tcl
	rm -f vivado_hls.log
	rm -f Namefile.txt

driver_tx: ../../src/tcl/hls_builder.tcl ../../src/vhls/*
	rm -f Namefile.txt
	echo 'driver_tx' > Namefile.txt
	rm -rf driver_tx
	mkdir driver_tx
	vivado_hls ../../src/tcl/hls_builder.tcl
	rm -f vivado_hls.log
	rm -f Namefile.txt

driver_rx: ../../src/tcl/hls_builder.tcl ../../src/vhls/*
	rm -f Namefile.txt
	echo 'driver_rx' > Namefile.txt
	rm -rf driver_rx
	mkdir driver_rx
	vivado_hls ../../src/tcl/hls_builder.tcl
	rm -f vivado_hls.log
	rm -f Namefile.txt

stream_meta_to_gulf:
	rm -f Namefile.txt
	echo 'stream_meta_to_gulf' > Namefile.txt
	rm -rf stream_meta_to_gulf
	mkdir stream_meta_to_gulf
	vivado_hls ../../src/tcl/hls_builder.tcl
	rm -f vivado_hls.log
	rm -f Namefile.txt

clean:
	rm -rf write_core driver_tx driver_rx stream_meta_to_gulf
