#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"

#define MAX_NUM_OF_QUEUES 0x800
#define CONT_FIFO_DATA_WIDTH 16

#define AWAITING_REQUEST 			0
#define AWAITING_RETH 				1
#define VERIFYING_CUR_DATA 			2
#define DROP_PACKET 				3
#define DECREMENT_QUEUE 			5
#define INITIALIZING				6
#define CONTAINER_OFFSET_SIZE 20
#define offset_mask 0xFFFFF
struct sw_request_type
{
	ap_uint<24> queue;
	ap_uint<2> request_type;//0 = read request, 1 = close_reply
							//2 = write request
	ap_uint<32> DMA_length;
};

struct to_ack
{
	ap_uint<1> ack1_or_nack0;
	ap_uint<5> reason;
	ap_uint<24> packet_sequence_number;
	ap_uint<32> ip_addr;
	ap_uint<24> queue;
};

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
	ap_uint<4> transport_header_version;//version of IBA transport  --constant (send via axi lite)
	ap_uint<16> partition;//The partition that the dest QP is inside of --constant (send via axi lite)
	ap_uint<24> dest_qp;//the queue targeted
	ap_uint<2> conjestion;//bit 0 is forward congestion, 1 is backwards congestion
	ap_uint<1> ack_req;//indicates the requester wants an acknowledgement when the packet is received
	ap_uint<24> packet_sequence_number;
};

struct data_needed
{
	ap_uint<32> DMA_length;//full length of transaction
	//ap_uint<64> virtual_address;
	ap_uint<32> ip_addr;
	ap_uint<24> dest_qp;
	ap_uint<24> packet_sequence_number;
};

struct done_signal_format
{
	ap_uint<1> success;
	ap_uint<24> queue;
	ap_uint<CONT_FIFO_DATA_WIDTH> container_number;
	ap_uint<64> read_size;
};

struct queue_object_type
{
	ap_uint<32> password;
	ap_uint<1> valid;
	ap_uint<1> in_progress;
	ap_uint<1> first;
	ap_uint<1> solicited;
	ap_uint<16> num_of_writes;
	ap_uint<24> packet_sequence_number;
	ap_uint<32> ip_addr;
};

struct add_queue_type
{
	ap_uint<24> queue;
	ap_uint<32> password;
	ap_uint<1> add1_or_remove0;
};

struct data_info_out
{
	ap_uint<CONT_FIFO_DATA_WIDTH> container_number;
	ap_uint<32> ip_addr;
	ap_uint<24> dest_qp;
	ap_uint<24> packet_sequence_number;
	ap_uint<1> first;
	ap_uint<1> last;
	ap_uint<64> size;
};

void rrrh(
	hls::stream<add_queue_type>& change_queue,
	hls::stream<reth>& request_in,
	hls::stream<flags>& flags_in,
	hls::stream<data_needed>& un_satisfied_fifo_out,
	hls::stream<data_needed>& un_satisfied_fifo_in,
	hls::stream<sw_request_type>& sw_request,
	hls::stream<done_signal_format>& done,
	hls::stream<to_ack>& ack_out,
	hls::stream<data_info_out>& to_data_writer
)
{
#pragma HLS DATAFLOW

#pragma HLS INTERFACE ap_ctrl_none port=return


#pragma HLS resource core=AXI4Stream variable = request_in
#pragma HLS DATA_PACK variable=request_in

#pragma HLS resource core=AXI4Stream variable = ack_out
#pragma HLS DATA_PACK variable=ack_out

#pragma HLS resource core=AXI4Stream variable = flags_in
#pragma HLS DATA_PACK variable=flags_in

#pragma HLS resource core=AXI4Stream variable = change_queue
#pragma HLS DATA_PACK variable=change_queue

#pragma HLS resource core=AXI4Stream variable = un_satisfied_fifo_out
#pragma HLS DATA_PACK variable=un_satisfied_fifo_out

#pragma HLS resource core=AXI4Stream variable = un_satisfied_fifo_in
#pragma HLS DATA_PACK variable=un_satisfied_fifo_in

#pragma HLS resource core=AXI4Stream variable = sw_request
#pragma HLS DATA_PACK variable=sw_request

#pragma HLS resource core=AXI4Stream variable = done
#pragma HLS DATA_PACK variable=done

#pragma HLS resource core=AXI4Stream variable = to_data_writer
#pragma HLS DATA_PACK variable=to_data_writer


	static ap_uint<8> stage = AWAITING_REQUEST;
	flags cur_flags;
	reth cur_reth;
	static data_needed data_on_hold;
	static data_info_out data_info_inst;
	static data_needed cur_data;
	static ap_uint<1> on_hold = 0;
	ap_uint<32> length_less_1;
	to_ack ack_out_inst;
	static ap_uint<1> on_hold_change = 0;
	static done_signal_format done_in;
	static ap_uint<1> checking_hold = 0;
	sw_request_type sw_inst;
	static queue_object_type queues[MAX_NUM_OF_QUEUES];
#pragma HLS DATA_PACK variable = queues
	static ap_uint<24> on_hold_queue = 0;
	static queue_object_type cur_queue;
	add_queue_type add_queue_inst;
	switch(stage)
	{
	case AWAITING_REQUEST:
		if (!done.empty())
		{
			done_in = done.read();
			cur_queue=queues[done_in.queue];
			data_info_inst.size=done_in.read_size;
			if (done_in.queue==on_hold_queue && on_hold == 1)
			{
				on_hold_change = 1;
			}
			if (done_in.success==0 && (cur_queue.solicited==1))
			{
				ack_out_inst.ack1_or_nack0=0;
				ack_out_inst.reason = 4; //TODO: right now we report the error but do nothing about it
				ack_out_inst.ip_addr=cur_queue.ip_addr;
				ack_out_inst.packet_sequence_number=cur_queue.packet_sequence_number;
				ack_out_inst.queue = done_in.queue;
				ack_out.write(ack_out_inst);
			}
			stage = DECREMENT_QUEUE;
		}
		else if (!change_queue.empty())
		{
			add_queue_inst=change_queue.read();
			if (add_queue_inst.add1_or_remove0==0)
			{
				cur_queue.valid=0;
				queues[add_queue_inst.queue]=cur_queue;
				sw_inst.queue=add_queue_inst.queue;
				sw_inst.request_type=1;
				sw_request.write(sw_inst);
			}
			else
			{
				cur_queue.in_progress=0;
				cur_queue.password=add_queue_inst.password;
				cur_queue.valid=1;
				cur_queue.num_of_writes = 0;
				cur_queue.packet_sequence_number = 0;
				cur_queue.ip_addr = 0;
				cur_queue.solicited=0;
				queues[add_queue_inst.queue]=cur_queue;
				sw_inst.queue=add_queue_inst.queue;
				sw_inst.request_type=3;
				sw_request.write(sw_inst);
			}
		}
		else if (on_hold==0&&!un_satisfied_fifo_in.empty())
		{
			on_hold = 1;
			data_on_hold=un_satisfied_fifo_in.read();
			on_hold_queue=data_on_hold.dest_qp;
			on_hold_change = 1;
			stage = AWAITING_REQUEST;
		}
		else if (on_hold==1 && on_hold_change == 1)
		{
			on_hold_change = 0;
			on_hold = 0;
			cur_queue=queues[on_hold_queue];
			checking_hold = 1;
			cur_data = data_on_hold;
			stage = VERIFYING_CUR_DATA;
		}
		else if (!flags_in.empty())
		{
			cur_flags=flags_in.read();
			cur_data.dest_qp = cur_flags.dest_qp;
			cur_data.ip_addr=cur_flags.ip_addr;
			cur_data.packet_sequence_number=cur_flags.packet_sequence_number;
			cur_queue=queues[cur_flags.dest_qp];
			cur_queue.solicited=cur_flags.solicited_event;
			//I assume a queue has all solicited or all unsolicited here
			stage = AWAITING_RETH;
		}
		break;
	case DECREMENT_QUEUE:
		data_info_inst.first=cur_queue.first;
		cur_queue.first = 0;
		data_info_inst.container_number=done_in.container_number;
		data_info_inst.dest_qp=done_in.queue;
		data_info_inst.packet_sequence_number=cur_queue.packet_sequence_number;
		data_info_inst.ip_addr=cur_queue.ip_addr;
		stage = AWAITING_REQUEST;
		if (cur_queue.num_of_writes == 1)
		{
			data_info_inst.last=1;
			cur_queue.in_progress = 0;
			cur_queue.num_of_writes = 0;
		}
		else
		{
			data_info_inst.last = 0;
			cur_queue.num_of_writes = cur_queue.num_of_writes - 1;
		}
		queues[done_in.queue]=cur_queue;
		to_data_writer.write(data_info_inst);
		break;
	case AWAITING_RETH:
		if (!request_in.empty())
		{
			cur_reth=request_in.read();
			cur_data.DMA_length=cur_reth.DMA_length;
			//cur_data.virtual_address=cur_reth.virtual_address;
			if (cur_queue.valid==0 || (cur_queue.password != cur_reth.remote_key))
			{
				stage = DROP_PACKET;
			}
			else
			{
				stage = VERIFYING_CUR_DATA;
			}
		}
		break;
	case VERIFYING_CUR_DATA:
		if (cur_queue.valid == 0)
		{
			stage = DROP_PACKET;
		}
		else if (cur_queue.in_progress==1)
		{
			stage = AWAITING_REQUEST;
			if (checking_hold == 1)
			{
				checking_hold = 0;
				on_hold = 1;
				on_hold_change = 0;
			}
			else if (on_hold == 1)
			{
				un_satisfied_fifo_out.write(cur_data);
			}
			else
			{
				on_hold = 1;
				on_hold_change = 0;
				on_hold_queue=cur_data.dest_qp;
				data_on_hold = cur_data;
			}
		}
		else
		{
			checking_hold = 0;
			sw_inst.queue=cur_data.dest_qp;
			sw_inst.request_type=0;
			sw_inst.DMA_length = cur_data.DMA_length;
			length_less_1 = (cur_data.DMA_length-1);
			cur_queue.num_of_writes=length_less_1.range(32,CONTAINER_OFFSET_SIZE);
			cur_queue.num_of_writes++;
			cur_queue.in_progress=1;
			cur_queue.first = 1;
			cur_queue.packet_sequence_number=cur_data.packet_sequence_number;
			cur_queue.ip_addr=cur_data.ip_addr;
			queues[cur_data.dest_qp]= cur_queue;
			sw_request.write(sw_inst);
			stage = AWAITING_REQUEST;
		}
		break;
	case DROP_PACKET:
		//Send an ACK
		if (cur_queue.solicited==1)
		{
			ack_out_inst.ack1_or_nack0=0;
			ack_out_inst.reason = 1; //TODO: update this
			ack_out_inst.ip_addr=cur_data.ip_addr;
			ack_out_inst.packet_sequence_number=cur_data.packet_sequence_number;
			ack_out_inst.queue = cur_data.dest_qp;
			ack_out.write(ack_out_inst);
		}
		stage = AWAITING_REQUEST;
		break;
	}
}
