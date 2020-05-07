//select which features you want enabled for this IP, at least 1 must be selected, comment out unwanted



#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"

/*
 * Op Code Map for RoCE:
 *
 * These are the Supported Op Codes, all others will be sent out through the unhandled_payload output
 *
 * 0:
 * First Packet in Stream of Send
 * Contains: Payload + flags
 *
 * 1:
 * Middle Packet in Stream of Send
 * Contains: Payload + flags
 *
 * 2:
 * Last Packet in Stream of Send
 * Contains: Payload + flags
 *
 * 3:
 * Last Packet in Stream of Send
 * Contains: Immediate + Payload + flags <= immediate travels as first 4 bytes of data
 *
 * 4:
 * First and Last (Only) Packet in Stream of Send
 * Contains: Payload + flags
 *
 * 5:
 * First and Last Packet in Stream of Send
 * Contains: Immediate + Payload + flags <= immediate travels as first 4 bytes of data
 *
 * 22:
 * Last Packet in Stream of Send with Invalidate
 * Contains: R_KEY + Payload + flags <= R_KEY travels as first 4 bytes of data payload
 *
 * 23:
 * First and Last (Only) Packet in Stream of Send with Invalidate
 * Contains: R_KEY + Payload + flags <= R_KEY travels as first 4 bytes of data payload
 *
 * 6:
 * First Packet in Stream of Write
 * Contains: RETH + PAYLOAD + flags <= output as different stream lines
 *
 * 7:
 * Middle Packet in Stream of Write
 * Contains: Payload + flags
 *
 * 8:
 * Last Packet in Stream of Write
 * Contains: Payload + flags
 *
 * 9:
 * Last Packet in Stream of Write
 * Contains: Immediate + Payload + flags <= immediate travels as first 4 bytes of data
 *
 * 10:
 * First and Last (Only) Packet in Stream of Write
 * Contains: RETH + PAYLOAD + flags <= output as different stream lines
 *
 * 11:
 * First and Last (Only) Packet in Stream of Write
 * Contains: Immediate + RETH + PAYLOAD + flags <= output as different stream lines
 * 												<= immediate travels as first 4 bytes of data
 *
 * 12:
 * Read Request
 * Contains: RETH + flags
 *
 * 13:
 * First Packet in Stream of Read Response
 * Contains: AETH + Payload + flags
 *
 * 14:
 * Middle Packet in Stream of Read Response
 * Contains: Payload + flags
 *
 * 15:
 * Last Packet in Stream of Read Response
 * Contains: AETH + Payload + flags
 *
 * 16:
 * First and Last (only) packet in stream of Read Response
 * Contains: AETH + Payload + flags
 *
 * 17:
 * Acknowledgement
 * Contains: AETH + flags
 */

#define INITIALIZING 					0
#define AWAITING_PACKET 				1
#define WRITE_CARRY_OVER_OFFSET_36		2
#define WRITE_DATA_OFFSET_36			3
#define WRITE_DATA_OFFSET_52			4
#define WRITE_CARRY_OVER_OFFSET_52		5
#define HANDLE_THE_UNHANDLED			6

struct dataword
{
	ap_uint<512> data;
	ap_uint<64> keep;
	ap_uint<1> last;
};

struct reth
{
	ap_uint<64> virtual_address;//address offset
	ap_uint<32> remote_key;//password
	ap_uint<32> DMA_length;//full length of transaction
};

struct aeth
{
	ap_uint<8> syndrome;//0 = NACK, If ACK syndrome = Limit Sequence Number (Flow Control Credits)
	ap_uint<24> MSN;//Packet Sequence number of the previous sent request (for flow control) (see flags)
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

void roce_rx_interpreter(
	//Note if opCode specifies Immediate, Immediate travels in first 4 bytes of payload
	//to parser
	hls::stream<ap_uint<32> >& rx_roce_meta,//contains the ip only

	hls::stream<dataword>& rx_roce_data,
	//to write handler
	hls::stream<dataword>& rdma_write_payload,
	hls::stream<flags>& write_flags,
	hls::stream<reth>& rdma_write_reth,
	//to read request handler
	hls::stream<reth>& rdma_read_request,
	hls::stream<flags>& read_req_flags,
	//to ack handler
	hls::stream<flags>& ack_flags,
	hls::stream<aeth>& acknowledgement
)
{
#pragma HLS DATAFLOW

#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = ack_flags
#pragma HLS DATA_PACK variable=ack_flags

#pragma HLS resource core=AXI4Stream variable = acknowledgement
#pragma HLS DATA_PACK variable=acknowledgement

#pragma HLS resource core=AXI4Stream variable = read_req_flags
#pragma HLS DATA_PACK variable=read_req_flags

#pragma HLS resource core=AXI4Stream variable = rdma_read_request
#pragma HLS DATA_PACK variable=rdma_read_request

#pragma HLS resource core=AXI4Stream variable = rx_roce_data
#pragma HLS DATA_PACK variable=rx_roce_data

#pragma HLS resource core=AXI4Stream variable = rx_roce_meta

#pragma HLS resource core=AXI4Stream variable = write_flags
#pragma HLS DATA_PACK variable=write_flags


#pragma HLS resource core=AXI4Stream variable = rdma_write_payload
#pragma HLS DATA_PACK variable=rdma_write_payload

#pragma HLS resource core=AXI4Stream variable = rdma_write_reth
#pragma HLS DATA_PACK variable=rdma_write_reth

	static ap_uint<8> stage = AWAITING_PACKET;
	dataword data_in;
	dataword data_out;
	static dataword carry_over_packet;
	//static ap_uint<8> op_code=0;
	flags pkt_flgs;
	static ap_uint<2> pad_count;
	reth reth_obj;
	aeth aeth_obj;
	static bool do_not_read=false;
	ap_uint<5> op_code_temp;
	switch(stage)
	{
	case AWAITING_PACKET:
		if (!rx_roce_data.empty() && !rx_roce_meta.empty())
		{
			pkt_flgs.ip_addr=rx_roce_meta.read();
			//read the data
			data_in=rx_roce_data.read();
			//populate the packet flags
			op_code_temp=data_in.data.range(508,504);
			pkt_flgs.op_code_short=data_in.data.range(508,504);
			pkt_flgs.solicited_event=data_in.data.bit(503);
			pkt_flgs.mig_req=data_in.data.bit(502);
			pad_count=data_in.data.range(501,500);
			pkt_flgs.transport_header_version=data_in.data.range(499,496);
			pkt_flgs.partition=data_in.data.range(495,480);
			pkt_flgs.conjestion=data_in.data.range(479,478);
			pkt_flgs.dest_qp=data_in.data.range(471,448);
			pkt_flgs.ack_req=data_in.data.bit(447);
			pkt_flgs.packet_sequence_number=data_in.data.range(439,416);
			if (op_code_temp==6||op_code_temp==10||op_code_temp==11)
			{
				//Write has RETH
				//read the packet flags
				write_flags.write(pkt_flgs);
				reth_obj.virtual_address=data_in.data.range(415,352);
				reth_obj.remote_key=data_in.data.range(351,320);
				reth_obj.DMA_length=data_in.data.range(319,288);
				rdma_write_reth.write(reth_obj);
				carry_over_packet=data_in;
				if(data_in.last==1 && data_in.keep.bit(35)==0)
				{
					stage = AWAITING_PACKET;
				}
				else if (data_in.last==1)
				{
					do_not_read=true;
					stage = WRITE_DATA_OFFSET_36;
				}
				else
				{
					do_not_read=false;
					stage = WRITE_DATA_OFFSET_36;
				}
			}
			else if(op_code_temp==7||op_code_temp==8||op_code_temp==9)
			{
				//Write does not have RETH
				write_flags.write(pkt_flgs);
				//next 32 bits contain useful data, save them
				carry_over_packet=data_in;
				if(data_in.last==1 && data_in.keep.bit(51)==0)
				{
					stage = AWAITING_PACKET;
				}
				else if (data_in.last==1)
				{
					do_not_read=true;
					stage = WRITE_DATA_OFFSET_52;
				}
				else
				{
					do_not_read=false;
					stage = WRITE_DATA_OFFSET_52;
				}
				break;
			}
			else if (op_code_temp==12)
			{
				//it is a read request
				read_req_flags.write(pkt_flgs);
				reth_obj.virtual_address=data_in.data.range(415,352);
				reth_obj.remote_key=data_in.data.range(351,320);
				reth_obj.DMA_length=data_in.data.range(319,288);
				rdma_read_request.write(reth_obj);
				stage = AWAITING_PACKET;
			}
			else if (op_code_temp==17)
			{
				//it is an ACK request
				ack_flags.write(pkt_flgs);
				aeth_obj.syndrome=data_in.data.range(415,408);
				aeth_obj.MSN=data_in.data.range(407,384);
				acknowledgement.write(aeth_obj);
				stage = AWAITING_PACKET;
			}
			else
			{
				if (data_in.last==1)
				{
					stage = AWAITING_PACKET;
				}
				else
				{
					stage = HANDLE_THE_UNHANDLED;
				}
			}
		}
		break;
	case HANDLE_THE_UNHANDLED:
		if (!rx_roce_data.empty())
		{
			data_in=rx_roce_data.read();
			if (data_in.last==1)
			{
				stage = AWAITING_PACKET;
			}
			else
			{
				stage = HANDLE_THE_UNHANDLED;
			}
		}
		break;
	case WRITE_DATA_OFFSET_36:
		if ((!rx_roce_data.empty() || do_not_read) && !rdma_write_payload.full())
		{
			if (do_not_read)
			{
				data_in.data=0;
				data_in.keep=0;
				data_in.last=1;
			}
			else
			{
				data_in=rx_roce_data.read();
			}
			data_out.data.range(511,224)=carry_over_packet.data.range(287,0);
			data_out.data.range(223,0)=data_in.data.range(511,288);
			data_out.keep.range(63,28)=carry_over_packet.keep.range(35,0);
			data_out.keep.range(27,0)=data_in.keep.range(63,36);
			if (do_not_read||(data_in.last==1 && data_in.keep.bit(35)==0))
			{
				data_out.last=1;
				stage=AWAITING_PACKET;
			}
			else if (data_in.last==1)
			{
				data_out.last=0;
				stage=WRITE_DATA_OFFSET_36;
				do_not_read=true;
			}
			else
			{
				data_out.last=0;
				stage=WRITE_DATA_OFFSET_36;
				do_not_read=false;
			}
			rdma_write_payload.write(data_out);
			carry_over_packet=data_in;
		}
		break;

	case WRITE_DATA_OFFSET_52:
		if ((!rx_roce_data.empty() || do_not_read) && !rdma_write_payload.full())
		{
			if (do_not_read)
			{
				data_in.data=0;
				data_in.keep=0;
				data_in.last=1;
			}
			else
			{
				data_in=rx_roce_data.read();
			}
			data_out.data.range(511,96)=carry_over_packet.data.range(415,0);
			data_out.data.range(95,0)=data_in.data.range(511,416);
			data_out.keep.range(63,12)=carry_over_packet.keep.range(51,0);
			data_out.keep.range(11,0)=data_in.keep.range(63,52);
			if (do_not_read||(data_in.last==1 && data_in.keep.bit(51)==0))
			{
				data_out.last=1;
				stage=AWAITING_PACKET;
			}
			else if (data_in.last==1)
			{
				data_out.last=0;
				stage=WRITE_DATA_OFFSET_52;
				do_not_read=true;
			}
			else
			{
				data_out.last=0;
				stage=WRITE_DATA_OFFSET_52;
				do_not_read=false;
			}
			rdma_write_payload.write(data_out);
			carry_over_packet=data_in;
		}
		break;
	}
}
