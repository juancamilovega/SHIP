#include "hls_stream.h"
#include "ap_int.h"
#include "ap_utils.h"

struct B_datastructure
{
	ap_uint<2> response;
	ap_uint<1> id;
	ap_uint<5> junk;
};

struct address_axi_chan
{
	ap_uint<64> address;
	ap_uint<8> length;
};
struct dataword
{
	ap_uint<512> data;
	ap_uint<64> keep;
	ap_uint<1> last;
};

#define NO_B 0
#define GOOD_B 1
#define BAD_B 2

#define WAITING_FOR_REQUEST_OR_B 0
#define WAITING_FOR_REQUEST_SUCCESS 1
#define WAITING_FOR_REQUEST_FAILED 2
#define WAITING_FOR_B 3
#define DROPPING_PACKET 4
#define RETRANS_DATA_SEND 5
#define WAITING_FOR_RETRANS_B 6
#define SENDING_FROM_RETRANS_FIFO 7

void retransmit_memory_core(
	hls::stream<dataword>& data_in,
	hls::stream<dataword>& retrans_fifo_out,
	hls::stream<dataword>& retrans_fifo_in,
	hls::stream<address_axi_chan>& req_in,
	hls::stream<address_axi_chan>& mem_aw,
	hls::stream<dataword>& mem_w,
	hls::stream<B_datastructure>& mem_b,
	hls::stream<B_datastructure>& parent_b,
	hls::stream<B_datastructure>& child_b
)
{

#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = data_in
#pragma HLS DATA_PACK variable=data_in

#pragma HLS resource core=AXI4Stream variable = retrans_fifo_out
#pragma HLS DATA_PACK variable=retrans_fifo_out

#pragma HLS resource core=AXI4Stream variable = retrans_fifo_in
#pragma HLS DATA_PACK variable=retrans_fifo_in

#pragma HLS resource core=AXI4Stream variable = req_in
#pragma HLS DATA_PACK variable=req_in

#pragma HLS resource core=AXI4Stream variable = mem_aw
#pragma HLS DATA_PACK variable=mem_aw

#pragma HLS resource core=AXI4Stream variable = mem_w
#pragma HLS DATA_PACK variable=mem_w

#pragma HLS resource core=AXI4Stream variable = mem_b
#pragma HLS DATA_PACK variable=mem_b

#pragma HLS resource core=AXI4Stream variable = parent_b
#pragma HLS DATA_PACK variable=parent_b

#pragma HLS resource core=AXI4Stream variable = child_b
#pragma HLS DATA_PACK variable=child_b

	static ap_uint<1> dropping_retrans = 0; //Indicates there is junk in the retransmission fifo that needs to be discarted
	static ap_uint<8> stage = WAITING_FOR_REQUEST_OR_B; //state machine stage
	static B_datastructure stored_B; //The last B read on file
	static ap_uint<1> got_req = 0; //Indicates a request has been received and is stored
	static ap_uint<2> got_b = NO_B;//Indicates a B has been received and is stored
	static address_axi_chan stored_addr; //Address stored on file
	
	B_datastructure B_temp;
	address_axi_chan addr_temp;
	dataword temp_dataword;
	dataword temp_retrans_dataword;
	ap_uint<1> got_req_temp;
	ap_uint<2> got_b_temp;
	switch(stage)
	{
	case WAITING_FOR_REQUEST_OR_B:
		//main start stage, nothing is stored
		if (!parent_b.empty() && !req_in.empty())
		{
			//There is both a B and a request available so read both
			addr_temp=req_in.read();
			B_temp=parent_b.read();
			if (B_temp.response>1)
			{
				//AXI transaction had an error, let us resend the address to try again
				mem_aw.write(addr_temp);
				stage = RETRANS_DATA_SEND;
			}
			else
			{
				//AXI transaction went well, forward the success respond to the requester and drop the packet on file
				child_b.write(B_temp);
				stage = DROPPING_PACKET;
			}
			//store the B and request received on the record
			stored_B = B_temp;
			stored_addr = addr_temp;
		}
		else if (!req_in.empty())
		{
			//A request is here but not a B, just read it and store it and flag the stage to one where the request is known
			stage = WAITING_FOR_B;
			stored_addr = req_in.read();
		}
		else if (parent_b.empty())
		{
			//A B is here but not the request read it
			B_temp=parent_b.read();
			if (B_temp.response>1)
			{
				//Request has failed. Put it in the stage
				stage = WAITING_FOR_REQUEST_FAILED;
			}
			else
			{
				//Success! forward the success response to the requester and drop the packet as soon as the request comes in.
				child_b.write(B_temp);
				stage = WAITING_FOR_REQUEST_SUCCESS;
			}
			//Store the received B
			stored_B = B_temp;
		}
		if (dropping_retrans==1 && !retrans_fifo_in.empty())
		{
			//There is garbage in the retransmission buffer, drop it until the last flit is reached
			temp_retrans_dataword= retrans_fifo_in.read();
			if (temp_retrans_dataword.last==1)
			{
				dropping_retrans = 0;
			}
		}
		break;
	case WAITING_FOR_REQUEST_FAILED:
		if (!req_in.empty())
		{
			//The awaited request has come which we know has failed. Resend it to the mem and store the request
			addr_temp=req_in.read();
			stored_addr = addr_temp;
			mem_aw.write(addr_temp);
			stage = RETRANS_DATA_SEND;
		}
		if (dropping_retrans==1 && !retrans_fifo_in.empty())
		{
			//There is garbage in the retransmission buffer, drop it until the last flit is reached
			temp_retrans_dataword= retrans_fifo_in.read();
			if (temp_retrans_dataword.last==1)
			{
				dropping_retrans = 0;
			}
		}
		break;
	case WAITING_FOR_REQUEST_SUCCESS:
		if (!req_in.empty())
		{
			//The request we know succeeded has come. Signal the packet to drop and store the request
			stored_addr=req_in.read();
			stage = DROPPING_PACKET;
		}
		if (dropping_retrans==1 && !retrans_fifo_in.empty())
		{
			//There is garbage in the retransmission buffer, drop it until the last flit is reached
			temp_retrans_dataword= retrans_fifo_in.read();
			if (temp_retrans_dataword.last==1)
			{
				dropping_retrans = 0;
			}
		}
		break;
	case WAITING_FOR_B:
		//The B has come for a previously received request (this should be a common stage all things considered)
		if (parent_b.empty())
		{
			B_temp=parent_b.read();
			if (B_temp.response>1)
			{
				//Request has failed. Retransmit it
				mem_aw.write(stored_addr);
				stage = RETRANS_DATA_SEND;
			}
			else
			{
				//Success! tell the requester the transaction is done and drop the packet from the buffer
				child_b.write(B_temp);
				stage = DROPPING_PACKET;
			}
			stored_B = B_temp;
		}
		if (dropping_retrans==1 && !retrans_fifo_in.empty())
		{
			//There is garbage in the retransmission buffer, drop it until the last flit is reached
			temp_retrans_dataword= retrans_fifo_in.read();
			if (temp_retrans_dataword.last==1)
			{
				dropping_retrans = 0;
			}
		}
		break;
	case RETRANS_DATA_SEND:
		//Sending the data part of a failed request
		if (!data_in.empty() && !mem_w.full())
		{
			//Read in the data
			temp_dataword=data_in.read();
			//Write the data to the memory and to the retransmission buffer
			mem_w.write(temp_dataword);
			retrans_fifo_out.write(temp_dataword);
			if (temp_dataword.last==1)
			{
				//The request is done, lets see what the B looks like now
				stage = WAITING_FOR_RETRANS_B;
			}
			else
			{
				//We are not done yet so stay here
				stage = RETRANS_DATA_SEND;
			}
		}
		if (dropping_retrans==1 && !retrans_fifo_in.empty())
		{
			//There is garbage in the retransmission buffer, drop it until the last flit is reached
			temp_retrans_dataword= retrans_fifo_in.read();
			if (temp_retrans_dataword.last==1)
			{
				dropping_retrans = 0;
			}
		}
		break;
	case SENDING_FROM_RETRANS_FIFO:
		//Same thing but now the data comes from the retransmission buffer since the first re-attempt failed
		if (!retrans_fifo_in.empty() && !mem_w.full())
		{
			//TODO: maybe add a timeout if many attempts fail.
			temp_dataword=retrans_fifo_in.read();
			mem_w.write(temp_dataword);
			retrans_fifo_out.write(temp_dataword);
			if (temp_dataword.last==1)
			{
				//We are at the end of the request, lets check again with the memory response
				stage = WAITING_FOR_RETRANS_B;
			}
			else
			{
				//We are not done yet so stay here
				stage = SENDING_FROM_RETRANS_FIFO;
			}
		}
		break;
	case WAITING_FOR_RETRANS_B:
		if (dropping_retrans==1)
		{
			//Need to clean up the garbage in front of the good data, continue until the last signal is seen
			if (!retrans_fifo_in.empty())
			{
				temp_retrans_dataword= retrans_fifo_in.read();
				if (temp_retrans_dataword.last==1)
				{
					dropping_retrans = 0;
				}
			}
			stage = WAITING_FOR_RETRANS_B;
		}
		else if (!mem_b.empty())
		{
			if(mem_b.read().response > 1)
			{
				mem_aw.write(stored_addr);
				stage = SENDING_FROM_RETRANS_FIFO;
			}
			else
			{
				child_b.write(stored_B);
				stage = WAITING_FOR_REQUEST_OR_B;
				dropping_retrans = 1;
			}
		}
		break;
	case DROPPING_PACKET:
		if (!data_in.empty())
		{
			temp_dataword=data_in.read();
			if (temp_dataword.last == 1)
			{
				if (got_b != NO_B)
				{
					got_b_temp = got_b;
				}
				else if (!parent_b.empty())
				{
					B_temp = parent_b.read();
					if (B_temp.response > 1)
					{
						got_b_temp = BAD_B;
					}
					else
					{
						child_b.write(B_temp);
						got_b_temp = GOOD_B;

					}
					stored_B = B_temp;
				}
				else
				{
					got_b_temp = NO_B;
				}
				if (got_req != 0)
				{
					got_req_temp = 1;
				}
				else if (!req_in.empty())
				{
					got_req_temp = 1;
					addr_temp=req_in.read();
					stored_addr=addr_temp;
				}
				else
				{
					got_req_temp = 0;
				}
				if (got_b_temp == BAD_B && got_req_temp==1)
				{
					mem_aw.write(addr_temp);
					stage = RETRANS_DATA_SEND;
				}
				else if (got_b_temp == GOOD_B && got_req_temp==1)
				{
					stage = DROPPING_PACKET;
				}
				else if (got_b_temp == NO_B && got_req_temp == 1)
				{
					stage = WAITING_FOR_B;
				}
				else if (got_b_temp == BAD_B && got_req_temp==0)
				{
					stage = WAITING_FOR_REQUEST_FAILED;
				}
				else if (got_b_temp == GOOD_B && got_req_temp==0)
				{
					stage = WAITING_FOR_REQUEST_SUCCESS;
				}
				else
				{
					stage = WAITING_FOR_REQUEST_OR_B;
				}
			}
			else
			{
				if (!req_in.empty() && got_req_temp == 0)
				{
					stored_addr=req_in.read();
					got_req_temp  = 1;
				}
				if (!parent_b.empty() && got_b == NO_B)
				{
					B_temp = parent_b.read();
					if (B_temp.response > 1)
					{
						got_b = BAD_B;
					}
					else
					{
						got_b = GOOD_B;
						child_b.write(B_temp);
					}
					stored_B = B_temp;
				}
				stage = DROPPING_PACKET;
			}
		}
		if (dropping_retrans==1 && !retrans_fifo_in.empty())
		{
			temp_retrans_dataword= retrans_fifo_in.read();
			if (temp_retrans_dataword.last==1)
			{
				dropping_retrans = 0;
			}
		}
		break;
	}
}
