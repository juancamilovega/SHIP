#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"
#define CONT_FIFO_DATA_WIDTH 16

#define INITIAL 0
#define WAITING_FOR_B 1
#define READY_TO_SEND 2
#define MEM_WAITING 3
#define MEM_AND_B_WAITING 4

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

struct B_datastructure
{
	ap_uint<2> response;
	ap_uint<1> id;
	ap_uint<5> junk;
};

struct done_controller
{
	ap_uint<1> expect_done_sig;
	ap_uint<1> send_done_sig;
};

void verifier_advanced(
	hls::stream<B_datastructure>& MEM_B,
	hls::stream<done_controller>& done_req,
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

#pragma HLS resource core=AXI4Stream variable=done_in
#pragma HLS DATA_PACK variable=done_in

#pragma HLS resource core=AXI4Stream variable=MEM_B
#pragma HLS DATA_PACK variable=MEM_B
	static ap_uint<8> stage = INITIAL;
	static ap_uint<32> b_count = 0;
	static done_controller done_rec;
	static memory_transfer_type mem_rec;
	ap_uint<1> inc_b = MEM_B.empty() ? 0 : 1;
	ap_uint<1> dec_b;
	ap_uint<1> is_blocked;
	done_controller done_in;
	memory_transfer_type mem_temp;
	memory_transfer_type_fwd mem_out;
	B_datastructure B_in;
	if (inc_b==1)
	{
		//Read b in if we can, inc_b is 1 if this is done
		B_in = MEM_B.read();
	}
	switch(stage)
	{
	case INITIAL:
		//Initial stage, nothing is stored or waiting
		if (!done_req.empty())
		{
			//A done request was received
			done_in=done_req.read();
			if (inc_b == 0 && b_count == 0 && done_in.expect_done_sig == 1)
			{
				//We can not process the done request until the corresponding B arrives
				stage = WAITING_FOR_B;
				//We will decrease b_count when we process it
				dec_b = 0;
			}
			else
			{
				//We can process this done request as a corresponding B was found
				if (done_in.send_done_sig == 1)
				{
					//We have permission to send the next unskipable mem_transfer request
					stage = READY_TO_SEND;
				}
				else
				{
					//We processed the done request but it did not require us to grant permission to the next mem transfer so we go back to initial
					stage = INITIAL;
				}
				//Only decrement b if it is "consumed" i.e. that this done request required a matching b
				dec_b = done_in.expect_done_sig;
			}
			//store this done request for the future
			done_rec = done_in;
		}
		else if (!mem_transfer.empty())
		{
			//A mem transfer came in and no done request came in
			mem_temp = mem_transfer.read();
			if (mem_temp.skip==1)
			{
				//A done is not needed, we can process right away
				//Our stage did not change
				stage = INITIAL;
				if (mem_temp.transfer_req==1)
				{
					//We need to send a message so send it
					mem_out.last=mem_temp.last;
					mem_out.queue=mem_temp.queue;
					mem_out.container_number=mem_temp.container_number;
					mem_out.size=mem_temp.size;
					mem_transfer_out.write(mem_out);
				}
			}
			else
			{
				//We can not skip the done signal so now we are waiting for it. B waiting is not true since there are no buffered unprocessed dones
				stage = MEM_WAITING;
			}
			//store the mem request for the future
			mem_rec = mem_temp;
			//no done processed therefore no b consumed
			dec_b = 0;
		}
		else
		{
			//We did nothing so don't consume a b
			dec_b = 0;
		}
		break;
	case MEM_WAITING:
		//We can not skip the done signal so now we are waiting for it. B waiting is not true since there are no buffered unprocessed dones
		if (!done_req.empty())
		{
			//Done signal came! read it.
			done_in=done_req.read();
			if (inc_b == 0 && b_count == 0 && done_in.expect_done_sig == 1)
			{
				//We can not process it until a b comes so now we are waiting for b with also a mem on hold
				stage = MEM_AND_B_WAITING;
				dec_b = 0;
			}
			else
			{
				//We can process the done signal
				if (done_in.send_done_sig == 1)
				{
					//done signal lets us process the MEM too
					//Go back to initial stage
					stage = INITIAL;
					if (mem_rec.transfer_req==1)
					{
						//Send it out if we can
						mem_out.last=mem_rec.last;
						mem_out.queue=mem_rec.queue;
						mem_out.container_number=mem_rec.container_number;
						mem_out.size=mem_rec.size;
						mem_transfer_out.write(mem_out);
					}
				}
				else
				{
					//done signal did not let us process the mem so go back to waiting for the mem with no done pending so no B waiting
					stage = MEM_WAITING;
				}
				//if a b was consumed, decrement it from the pool
				dec_b = done_in.expect_done_sig;
			}
			//record the done signal for the future
			done_rec = done_in;
		}
		else
		{
			//we did nothing so don't consume a b
			dec_b = 0;
		}
		break;
	case READY_TO_SEND:
		//We have the done authorization for a mem transfer that hasn't been executed
		if (!mem_transfer.empty())
		{
			//read the mem transfer
			mem_temp = mem_transfer.read();
			if (mem_temp.transfer_req==1)
			{
				//Send it out if required
				mem_out.last=mem_temp.last;
				mem_out.queue=mem_temp.queue;
				mem_out.container_number=mem_temp.container_number;
				mem_out.size=mem_temp.size;
				mem_transfer_out.write(mem_out);
			}
			if (mem_temp.skip==1)
			{
				//skip is 1 so we still have the authorization to send something
				stage = READY_TO_SEND;
			}
			else
			{
				//skip is 0 so we spent the authorization and go back to the initial stage
				stage = INITIAL;
			}
		}
		dec_b = 0;//no b is ever consumed in this state since a done was not read
		break;
	case MEM_AND_B_WAITING:
		//The mem needs a done signal and a done came but was halted by the need of a b signal
		if (inc_b != 0 || b_count != 0)
		{
			//We can process the done since a b came
			//decrement the b since the halt meant that it was going to consume it.
			dec_b=1;
			if (done_rec.send_done_sig == 1)
			{
				//we have the authorization to send out the mem
				if (mem_temp.transfer_req==1)
				{
					//send out the mem if needed
					mem_out.last=mem_rec.last;
					mem_out.queue=mem_rec.queue;
					mem_out.container_number=mem_rec.container_number;
					mem_out.size=mem_rec.size;
					mem_transfer_out.write(mem_out);
				}
				//No longer waiting to process the done or the mem transfer request so we go back to the initial state
				stage = INITIAL;
			}
			else
			{
				//The done signal did not let us process the mem but we are no longer waiting for the B to process the done signal so we go to mem waiting
				stage = MEM_WAITING;
			}
		}
		else
		{
			//We did nothing so don't decrement b
			dec_b = 0;
		}
		break;
	case WAITING_FOR_B:
		//We can not process the previous done request until the corresponding B arrives and no mem request is waiting
		if (inc_b != 0 || b_count != 0)
		{
			//Decrement b to process the done signal
			dec_b=1;
			if (done_rec.send_done_sig == 1)
			{
				//go to stage indicating we have permission to send an unskipable mem transfer request
				stage = READY_TO_SEND;
			}
			else
			{
				//the done signal we were waiting for gave us no permission so go back to the initial stage to process the next one
				stage = INITIAL;
			}
		}
		else if (!mem_transfer.empty())
		{
			//That done signal is still pending but now a mem request also came
			//don't decrement b since it is not consumed (none is available)
			dec_b = 0;
			mem_temp = mem_transfer.read();
			if (mem_temp.skip==1)
			{
				//If it is skipable we can process it even if a done is stuck
				//We stay in this stage since that done is still waiting for a b
				stage = WAITING_FOR_B;
				if (mem_temp.transfer_req==1)
				{
					//Send out the request if required
					mem_out.last=mem_temp.last;
					mem_out.queue=mem_temp.queue;
					mem_out.container_number=mem_temp.container_number;
					mem_out.size=mem_temp.size;
					mem_transfer_out.write(mem_out);
				}
			}
			else
			{
				//The mem request is not skipable, now we have a pending mem and a pending done signal where B is not processed
				stage = MEM_AND_B_WAITING;
			}
			//record this mem that came in for the future
			mem_rec = mem_temp;
		}
		else
		{
			//we did nothing so don't consume a b
			dec_b = 0;
		}
		break;
	}
	if (inc_b == 1 && dec_b == 0)
	{
		//A b was added and not consumed, b count goes up
		b_count = b_count + 1;
	}
	else if (inc_b == 0 && dec_b == 1)
	{
		//A b was consumed which was not added previously, b count goes down
		b_count = b_count - 1;
	}
	//if inc_b and dec_b are both 0 then no b was added and none was consumed, the count stays the same so case is not needed
	//if inc_b and dec_b are both 1 then the b which was added was immediately consumed, the count stays the same so case is not needed
}
