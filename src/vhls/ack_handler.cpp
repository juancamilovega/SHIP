#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"

struct aeth
{
	ap_uint<8> syndrome;//0 = NACK, If ACK syndrome = Limit Sequence Number (Flow Control Credits)
	ap_uint<24> MSN;//Packet Sequence number of the previous sent request (for flow control) (see flags)
};

struct flags
{
	ap_uint<32> ip_addr;
	ap_uint<1> first;
	ap_uint<1> last;
	ap_uint<1> solicited_event;//indicates the requester wants an acknowledgement when the work is done
	ap_uint<1> mig_req;//indicates migration state (1 => EE context has migrated)
	ap_uint<24> dest_qp;//the queue targeted
	ap_uint<1> ack_req;//indicates the requester wants an acknowledgement when the packet is received
	ap_uint<16> payload_length;//length of payload in bytes, must be multiple of 4
	ap_uint<2> padding; //number of bytes that padded the payload (0-3),
						//this allows for any actual payload size
};

struct ack_type
{
	ap_uint<1> ack_or_nack;
	ap_uint<5> reason;
	ap_uint<24> psn;
	ap_uint<32> ip_addr;
	ap_uint<24> queue;
};

void ack_handler
(
	hls::stream<flags> ack_flags,
	hls::stream<aeth> ack_data,
	hls::stream<ack_type> ack_requests
)
{
#pragma HLS DATAFLOW

#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = ack_flags
#pragma HLS DATA_PACK variable=ack_flags

#pragma HLS resource core=AXI4Stream variable = ack_data
#pragma HLS DATA_PACK variable=ack_data

#pragma HLS resource core=AXI4Stream variable = ack_requests
#pragma HLS DATA_PACK variable=ack_requests
	ack_type ack_in;
	aeth aeth_out;
	flags flags_out;
	if (!ack_requests.empty())
	{
		ack_in=ack_requests.read();
		aeth_out.MSN=ack_in.psn;
		aeth_out.syndrome.range(4,0)=ack_in.reason;
		aeth_out.syndrome.range(7,5)= (ack_in.ack_or_nack==1) ? 0 : 3;
		flags_out.ack_req=0;
		flags_out.dest_qp=ack_in.queue;
		flags_out.first=1;
		flags_out.last=1;
		flags_out.mig_req=0;
		flags_out.padding=0;
		flags_out.payload_length=0;
		flags_out.solicited_event=0;
		flags_out.ip_addr=ack_in.ip_addr;
		ack_data.write(aeth_out);
		ack_flags.write(flags_out);
	}
}
