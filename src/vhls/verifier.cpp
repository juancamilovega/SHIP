#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"
#define CONT_FIFO_DATA_WIDTH 16
struct memory_transfer_type
{
	ap_uint<24> queue;
	ap_uint<CONT_FIFO_DATA_WIDTH> container_number;
	ap_uint<32> size;
	ap_uint<1> transfer_req;
	ap_uint<1> last;
	ap_uint<1> skip;
};

struct memory_transfer_type_fwd
{
	ap_uint<24> queue;
	ap_uint<CONT_FIFO_DATA_WIDTH> container_number;
	ap_uint<32> size;
	ap_uint<1> last;

};

void verifier(
	hls::stream<ap_uint<1> >& done,
	hls::stream<memory_transfer_type>& mem_transfer,
	hls::stream<memory_transfer_type_fwd>& mem_transfer_out
)

{
#pragma HLS DATAFLOW

#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable=mem_transfer
#pragma HLS DATA_PACK variable=mem_transfer

#pragma HLS resource core=AXI4Stream variable=mem_transfer_out
#pragma HLS DATA_PACK variable=mem_transfer_out

#pragma HLS resource core=AXI4Stream variable=done

	static ap_uint<2> stage =0;
	static memory_transfer_type mem_in;
	memory_transfer_type_fwd mem_out;
	switch(stage)
	{
	case 0:
		if (!done.empty())
		{
			//We have a done for something that hasn't been requested
			//essentially we have a pre-credited done, call that stage 1
			done.read();
			stage = 1;
		}
		else if (!mem_transfer.empty())
		{
			mem_in=mem_transfer.read();
			if (mem_in.skip==1)
			{
				//since skip=1 do it right away
				stage = 0;
				if (mem_in.transfer_req==1)
				{
					mem_out.last=mem_in.last;
					mem_out.queue=mem_in.queue;
					mem_out.container_number=mem_in.container_number;
					mem_out.size=mem_in.size;
					mem_transfer_out.write(mem_out);
				}
			}
			else
			{
				//wait until done arrives to do it
				stage = 2;
			}
		}
		break;
	case 1:
		if (!mem_transfer.empty())
		{
			mem_in=mem_transfer.read();
			if (mem_in.transfer_req==1)
			{
				mem_out.last=mem_in.last;
				mem_out.queue=mem_in.queue;
				mem_out.container_number=mem_in.container_number;
				mem_out.size=mem_in.size;
				mem_transfer_out.write(mem_out);
			}
			if (mem_in.skip==1)
			{
				//didn't need a done, still have a pre credited done
				stage = 1;
			}
			else
			{
				//this consumes the pre credited done.
				stage = 0;
			}
		}
		break;
	case 2:
		if (!done.empty())
		{
			//the awaited done arrived, process it now
			done.read();
			if (mem_in.transfer_req==1)
			{
				mem_out.last=mem_in.last;
				mem_out.queue=mem_in.queue;
				mem_out.container_number=mem_in.container_number;
				mem_out.size=mem_in.size;
				mem_transfer_out.write(mem_out);
			}
			stage = 0;
		}
		break;
	}
}
