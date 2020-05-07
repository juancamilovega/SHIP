# SHIP

 
This is the SHIP Storage Server Github repository

This repo makes use of the GULF Stream project which is imported from the GIT
https://github.com/QianfengClarkShen/GULF-Stream

# Make

to make everything from scratch run:

make

to compile the hls files into verilog run:

make hls

to add the gulf stream repo and compile its IPs run:

make gulf_stream

to create the SHIP system, assuming the hls is compiled and gulf stream is imported and compiled run:

make storage_server

to clean the project run:

make clean

# Output products

A folder called repos contains the gulf stream project, it is created.
compiled HLS projects are added to the folder ip_repo
The final vivado project is built in the folder SHIP_hardware that is created.
