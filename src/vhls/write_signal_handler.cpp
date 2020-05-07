#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"

#define AWAITING_FLAGS		0
#define EXTENDED_REQUEST	1

struct reth
{
	ap_uint<64> virtual_address;//address offset
	ap_uint<32> remote_key;//password
	ap_uint<32> DMA_length;//full length of transaction
};

struct flags
{
	ap_uint<5> op_code_short;//lower 5 bits of the op code
	ap_uint<32> ip_addr;
	ap_uint<1> solicited_event;//indicates the requester wants an acknowledgement when the work is done
	ap_uint<1> mig_req;//indicates migration state (1 => EE context has migrated)
	ap_uint<4> transport_header_version;//version of IBA transport
	ap_uint<16> partition;//The partition that the dest QP is inside of
	ap_uint<24> dest_qp;//the queue targeted
	ap_uint<2> conjestion;//bit 0 is forward congestion, 1 is backwards congestion
	ap_uint<1> ack_req;//indicates the requester wants an acknowledgement when the packet is received
	ap_uint<24> packet_sequence_number;
};

struct request_type
{
	ap_uint<24> queue;
	ap_uint<1> first;
	ap_uint<1> last;
	ap_uint<32> password;//0 if first == 0
	ap_uint<64> internal_offset;//remove this eventually (not currently supported)
	ap_uint<32> ip_addr;
	ap_uint<24> packet_sequence_number;
	ap_uint<1> solicited;
};

void write_signal_handler
(
	//from Interpreter
	hls::stream<flags>& write_flags,
	hls::stream<reth>& rdma_write_reth,


	//to judger
	hls::stream<request_type> request
)
{
#pragma HLS DATAFLOW

#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = write_flags
#pragma HLS DATA_PACK variable=write_flags

#pragma HLS resource core=AXI4Stream variable = rdma_write_reth
#pragma HLS DATA_PACK variable=rdma_write_reth

#pragma HLS resource core=AXI4Stream variable = request
#pragma HLS DATA_PACK variable=request
	static ap_uint<1> stage = AWAITING_FLAGS;
	flags flag_in;
	reth reth_in;
	static request_type request_out;
	switch (stage)
	{
	case AWAITING_FLAGS:
		if (!write_flags.empty())
		{
			flag_in=write_flags.read();
			request_out.ip_addr=flag_in.ip_addr;
			request_out.packet_sequence_number=flag_in.packet_sequence_number;
			request_out.queue=flag_in.dest_qp;
			request_out.solicited=flag_in.solicited_event;
			if (flag_in.op_code_short==6)
			{
				if (!rdma_write_reth.empty())
				{
					reth_in=rdma_write_reth.read();
					request_out.internal_offset=reth_in.virtual_address;
					request_out.password=reth_in.remote_key;
					request_out.first=1;
					request_out.last=0;
					request.write(request_out);
					stage = AWAITING_FLAGS;
				}
				else
				{
					request_out.first=1;
					request_out.last=0;
					stage = EXTENDED_REQUEST;
				}
			}
			else if (flag_in.op_code_short==10)
			{
				if (!rdma_write_reth.empty())
				{
					reth_in=rdma_write_reth.read();
					request_out.internal_offset=reth_in.virtual_address;
					request_out.password=reth_in.remote_key;
					request_out.first=1;
					request_out.last=1;
					request.write(request_out);
					stage = AWAITING_FLAGS;
				}
				else
				{
					request_out.first=1;
					request_out.last=1;
					stage = EXTENDED_REQUEST;
				}
			}
			else if (flag_in.op_code_short==7)
			{
				stage = AWAITING_FLAGS;
				request_out.first=0;
				request_out.last=0;
				request_out.internal_offset=0;
				request_out.password=0;
				request.write(request_out);
			}
			else if (flag_in.op_code_short==8)
			{
				stage = AWAITING_FLAGS;
				request_out.first=0;
				request_out.last=1;
				request_out.internal_offset=0;
				request_out.password=0;
				request.write(request_out);
			}
		}
		break;
	case EXTENDED_REQUEST:
		if (!rdma_write_reth.empty())
		{
			reth_in=rdma_write_reth.read();
			request_out.internal_offset=reth_in.virtual_address;
			request_out.password=reth_in.remote_key;
			request.write(request_out);
			stage = AWAITING_FLAGS;
		}
		break;
	}
}
