/*This IP will serve as the free list for the shared memory. To free a data frame, the user must
 * write that data frame to one of the slave AXIS ports. To allocate a data frame, the user must
 * read from one of the master AXIS ports. The allocator is initiated to have available the data
 * frames in the range [START_VAL_LOW, START_VAL_HIGH) while excluding the range
 * [EXCLUDED_1_L,EXCLUDED_1_H). If exclusions are not desired, comment out ACTIVATE_EXCLUSIONS.
 * Therefore the total number of frames available at startup is
 * START_VAL_HIGH-START_VAL_LOW-(EXCLUDED_1_H-EXCLUDED_1_L).
 *
 * FAST_FIFO is used whenever multiple memory types are provided and a small range of data frames are
 * to be prioritized (allocate these first if they are available). To enable this feature, comment
 * out DEACTIVATE_FAST_FIFO and set the high priority frames as the range [FAST_FIFO_LOW,FAST_FIFO_HIGH)
 *
*/
#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"
// put very shallow output fifos (8 depth maybe)
//#define ACTIVATE_EXCLUSIONS
#define DATA_WIDTH 16
#define START_VAL_LOW 0
#define START_VAL_HIGH 2000
#define NUMBER_OF_OUT_PORTS 2 //supports up to 10 out ports
#if NUMBER_OF_OUT_PORTS>10
#error "Number of out ports exceeds maximum (10)"
#endif
//in ports can be selected as a parameter

void fpga_malloc_free(
	hls::stream<ap_uint<DATA_WIDTH> > data_in_port,
	hls::stream<ap_uint<DATA_WIDTH> > data_out_port_1,
	ap_uint<1> data_out_port_1_almost_full,
#if NUMBER_OF_OUT_PORTS>1
	hls::stream<ap_uint<DATA_WIDTH> > data_out_port_2,
	ap_uint<1> data_out_port_2_almost_full,
#if NUMBER_OF_OUT_PORTS>2
	hls::stream<ap_uint<DATA_WIDTH> > data_out_port_3,
	ap_uint<1> data_out_port_3_almost_full,
#if NUMBER_OF_OUT_PORTS>3
	hls::stream<ap_uint<DATA_WIDTH> > data_out_port_4,
	ap_uint<1> data_out_port_4_almost_full,
#if NUMBER_OF_OUT_PORTS>4
	hls::stream<ap_uint<DATA_WIDTH> > data_out_port_5,
	ap_uint<1> data_out_port_5_almost_full,
#if NUMBER_OF_OUT_PORTS>5
	hls::stream<ap_uint<DATA_WIDTH> > data_out_port_6,
	ap_uint<1> data_out_port_6_almost_full,
#if NUMBER_OF_OUT_PORTS>6
	hls::stream<ap_uint<DATA_WIDTH> > data_out_port_7,
	ap_uint<1> data_out_port_7_almost_full,
#if NUMBER_OF_OUT_PORTS>7
	hls::stream<ap_uint<DATA_WIDTH> > data_out_port_8,
	ap_uint<1> data_out_port_8_almost_full,
#if NUMBER_OF_OUT_PORTS>8
	hls::stream<ap_uint<DATA_WIDTH> > data_out_port_9,
	ap_uint<1> data_out_port_9_almost_full,
#if NUMBER_OF_OUT_PORTS>9
	hls::stream<ap_uint<DATA_WIDTH> > data_out_port_10,
	ap_uint<1> data_out_port_10_almost_full,
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#ifdef ACTIVATE_EXCLUSIONS
	ap_uint<DATA_WIDTH> EXCLUDED_1_L,
	ap_uint<DATA_WIDTH> EXCLUDED_1_H,
#endif
	hls::stream<ap_uint<DATA_WIDTH> > fifo_in,
	hls::stream<ap_uint<DATA_WIDTH> > fifo_out
)
{
#pragma HLS DATAFLOW

#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = data_in_port
#pragma HLS resource core=AXI4Stream variable = data_out_port_1
#if NUMBER_OF_OUT_PORTS>1
#pragma HLS resource core=AXI4Stream variable = data_out_port_2
#if NUMBER_OF_OUT_PORTS>2
#pragma HLS resource core=AXI4Stream variable = data_out_port_3
#if NUMBER_OF_OUT_PORTS>3
#pragma HLS resource core=AXI4Stream variable = data_out_port_4
#if NUMBER_OF_OUT_PORTS>4
#pragma HLS resource core=AXI4Stream variable = data_out_port_5
#if NUMBER_OF_OUT_PORTS>5
#pragma HLS resource core=AXI4Stream variable = data_out_port_6
#if NUMBER_OF_OUT_PORTS>6
#pragma HLS resource core=AXI4Stream variable = data_out_port_7
#if NUMBER_OF_OUT_PORTS>7
#pragma HLS resource core=AXI4Stream variable = data_out_port_8
#if NUMBER_OF_OUT_PORTS>8
#pragma HLS resource core=AXI4Stream variable = data_out_port_9
#if NUMBER_OF_OUT_PORTS>9
#pragma HLS resource core=AXI4Stream variable = data_out_port_10
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#ifdef ACTIVATE_EXCLUSIONS
#pragma HLS resource variable=EXCLUDED_1_L core=AXI4LiteS metadata={-bus_bundle BUS_A}
#pragma HLS resource variable=EXCLUDED_1_H core=AXI4LiteS metadata={-bus_bundle BUS_A}
#endif

#pragma HLS resource core=AXI4Stream variable = fifo_in
#pragma HLS resource core=AXI4Stream variable = fifo_out
	static ap_uint<DATA_WIDTH> current_val = START_VAL_LOW;
	ap_uint<DATA_WIDTH> to_put;
	//Fill in FIFOS with incoming/initialization data
	if (!data_in_port.empty())
	{
		to_put = data_in_port.read();
		fifo_in.write(to_put);
	}
#ifdef ACTIVATE_EXCLUSIONS
#if EXCLUDED_1_L<EXCLUDED_1_H
	else if (current_val==EXCLUDED_1_L)
	{
		current_val = EXCLUDED_1_H;
	}
#endif
#endif
	else if (current_val!=START_VAL_HIGH)
	{
		fifo_in.write(current_val++);
	}

	//Send FIFO data to requesters
	if ((!fifo_out.empty())&&(data_out_port_1_almost_full==0))
	{
		data_out_port_1.write(fifo_out.read());
	}
#if NUMBER_OF_OUT_PORTS>1
	else if ((!fifo_out.empty())&&(data_out_port_2_almost_full==0))
	{
		data_out_port_2.write(fifo_out.read());
	}
#if NUMBER_OF_OUT_PORTS>2
	else if ((!fifo_out.empty())&&(data_out_port_3_almost_full==0))
	{
		data_out_port_3.write(fifo_out.read());
	}
#if NUMBER_OF_OUT_PORTS>3
	else if ((!fifo_out.empty())&&(data_out_port_4_almost_full==0))
	{
		data_out_port_4.write(fifo_out.read());
	}
#if NUMBER_OF_OUT_PORTS>4
	else if ((!fifo_out.empty())&&(data_out_port_5_almost_full==0))
	{
		data_out_port_5.write(fifo_out.read());
	}
#if NUMBER_OF_OUT_PORTS>5
	else if ((!fifo_out.empty())&&(data_out_port_6_almost_full==0))
	{
		data_out_port_6.write(fifo_out.read());
	}
#if NUMBER_OF_OUT_PORTS>6
	else if ((!fifo_out.empty())&&(data_out_port_7_almost_full==0))
	{
		data_out_port_7.write(fifo_out.read());
	}
#if NUMBER_OF_OUT_PORTS>7
	else if ((!fifo_out.empty())&&(data_out_port_8_almost_full==0))
	{
		data_out_port_8.write(fifo_out.read());
	}
#if NUMBER_OF_OUT_PORTS>8
	else if ((!fifo_out.empty())&&(data_out_port_9_almost_full==0))
	{
		data_out_port_9.write(fifo_out.read());
	}
#if NUMBER_OF_OUT_PORTS>9
	else if ((!fifo_out.empty())&&(data_out_port_10_almost_full==0))
	{
		data_out_port_10.write(fifo_out.read());
	}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
}
