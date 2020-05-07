/*
 * The job of the container_organiser_write is to manage where the data writer is writing to and
 * orchestrate memory to SSD transfers.
 *
 * Requests come in from the Write Signal Handler whenever a new packet comes in
 *
 * The judger decides whether this packet is allowed or rejected (handles security)
 *
 * If Rejected a "Drop" instruction is sent to the data writer which drops the whole packet
 *
 * If success then we find the open container and tell the writer to write up to size left bytes to it
 * 	- Eventually we get the size of the request and can check if it will fit
 * 	- If the request does not fit, we continue sending instructions
 * 	- If it does fit we can move on to the next request
 *
 * The data writer sends a reply after it is done every instruction.
 * 	- Reply goes to the verifier
 * 	- For every instruction, this IP also sends a request to the verifier
 * 	- By matching the two, we can figure out when each write is finished.
 */

//#define DEBUG
//#define DEBUG_CONT_SIZE



#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"
#define AWAITING_ORDERS 1
#define HANDLING_REQUEST_1 2
#define WAITING_FOR_REPLY 3
#define SPILL_OVER 4
#define WAITING_FOR_DROPPED_REPLY 5
#define HANDLING_CONTAINER_END_AFTER_REPLY 6
#define SENDING_OUT_TRAILING_ 7
#define SENDING_OUT_TRAILING_MEM_TRANSFER_INST_LAST 8
#define SENDING_OUT_TRAILING_MEM_TRANSFER_INST 9
#define SENDING_ACK_PACKET 10

#define CONT_FIFO_DATA_WIDTH 16
#define MAX_NUM_OF_QUEUES 0x800
#if MAX_NUM_OF_QUEUES%0x10!=0
#error "MAX_NUM_OF_QUEUES must be multiple of 0x10 (16)"
#endif
#define CONTAINER_OFFSET_SIZE 20
const ap_uint<32> CONTAINER_SIZE = 1<<20;
struct queue_object_type
{
	ap_uint<CONT_FIFO_DATA_WIDTH> current_container;
	ap_uint<32> current_offset;
	ap_uint<32> password;
	ap_uint<32> ip_number;
	ap_uint<1> valid;
	ap_uint<1> container_has_space;
	ap_uint<1> in_progress;
};

struct sw_request_type
{
	ap_uint<24> queue;
	ap_uint<3> request_type;//0 = read request, 1 = close_reply
							//2 = write request, 3= open_reply
							//4 = write ack
	ap_uint<32> ip_addr;
};

struct memory_transfer_type
{
	ap_uint<24> queue;
	ap_uint<CONT_FIFO_DATA_WIDTH> container_number;
	ap_uint<32> size;
	ap_uint<1> transfer_req;
	ap_uint<1> last;
	ap_uint<1> skip;
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

struct data_write_instructions_type
{
	ap_uint<1> drop_packet;
	ap_uint<32> max_write_size;
	ap_uint<64> mem_write_start_addr;
};

struct add_queue_type
{
	ap_uint<24> queue;
	ap_uint<32> password;
	ap_uint<1> add1_or_remove0;
};

struct ack_type
{
	ap_uint<1> ack1_or_nack0;
	ap_uint<5> reason;
	ap_uint<24> packet_sequence_number;
	ap_uint<32> ip_addr;
	ap_uint<24> queue;
};

void write_organizer(
	//incoming request stream

	hls::stream<request_type>& request,
	//tells us how big the packet is to organize large packets to multiple containers
	hls::stream<ap_uint<64> >& pkt_size,
	//output request to software
	hls::stream<sw_request_type>& sw_request,
	//nack for dropped packets
	hls::stream<ack_type>& acknowledgement,
	//to verifier to send out container movements
	hls::stream<memory_transfer_type>& mem_transfer,
	//Used to allocate a new container
	hls::stream<ap_uint<CONT_FIFO_DATA_WIDTH> >& cont_fifo_data,
	//Signals from SW to add or remove a queue, might combine them?
	hls::stream<add_queue_type>& change_queue,
	//Instructions to data writer on how to write the data
	hls::stream<data_write_instructions_type>& instructions
#ifdef DEBUG
	ap_uint<24> *req_size_left_out,
	ap_uint<32> *max_size_allowed_out,
	queue_object_type *queue_out
#endif
)
{
	//setup pragmas
#pragma HLS DATAFLOW

#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable=mem_transfer
#pragma HLS DATA_PACK variable=mem_transfer

#pragma HLS resource core=AXI4Stream variable=request
#pragma HLS DATA_PACK variable=request

#pragma HLS resource core=AXI4Stream variable=pkt_size

#pragma HLS resource core=AXI4Stream variable=acknowledgement
#pragma HLS DATA_PACK variable=acknowledgement

#pragma HLS resource core=AXI4Stream variable=sw_request
#pragma HLS DATA_PACK variable=sw_request

#pragma HLS resource core=AXI4Stream variable=cont_fifo_data

#pragma HLS resource core=AXI4Stream variable=change_queue
#pragma HLS DATA_PACK variable=change_queue

#pragma HLS resource core=AXI4Stream variable=instructions
#pragma HLS DATA_PACK variable=instructions

	static queue_object_type queues[MAX_NUM_OF_QUEUES];
#pragma HLS DATA_PACK variable=queues
	static ap_uint<4> stage = AWAITING_ORDERS;
	static ap_uint<64> request_size_left=0;
	static request_type queue_request_inst;
	static queue_object_type current_queue;
	static ap_uint<1> INIT = 0;
	ap_uint<32> current_container_number;
	ack_type ack_out;
	static ap_uint<32> max_size_allowed=0;
#ifdef DEBUG
	*req_size_left_out = request_size_left;
	*max_size_allowed_out = max_size_allowed;
	*queue_out = current_queue;
#endif
	add_queue_type add_queue_inst;
	data_write_instructions_type data_write_instructions_inst;
	queue_object_type queue_object_inst;
	memory_transfer_type mem_transfer_inst;
	sw_request_type sw_req_inst;
	ap_uint<24> req_queue_for_del;
	switch(stage)
	{
	case AWAITING_ORDERS:
		//add or remove queues
		if (!change_queue.empty())
		{
			add_queue_inst=change_queue.read();
			if (add_queue_inst.add1_or_remove0==1)
			{
				sw_req_inst.queue=add_queue_inst.queue;
				sw_req_inst.request_type=3;
				sw_req_inst.ip_addr=0;
				sw_request.write(sw_req_inst);
				queue_object_inst.container_has_space=0;
				queue_object_inst.password=add_queue_inst.password;
				queue_object_inst.valid = 1;
				queue_object_inst.in_progress=0;
				queues[add_queue_inst.queue]=queue_object_inst;
			}
			else
			{
				queue_object_inst.valid = 0;
				queues[add_queue_inst.queue]=queue_object_inst;
				sw_req_inst.ip_addr=0;
				sw_req_inst.queue=add_queue_inst.queue;
				sw_req_inst.request_type=1;
				sw_request.write(sw_req_inst);
			}
		}
		else if (!request.empty())
		{
			//read the request and load the queue data of that request
			queue_request_inst=request.read();
			current_queue=queues[queue_request_inst.queue];
			stage = HANDLING_REQUEST_1;
		}
		break;
	case HANDLING_REQUEST_1:
		if (current_queue.valid==0)
		{
			data_write_instructions_inst.drop_packet = 1;
			instructions.write(data_write_instructions_inst);
			mem_transfer_inst.transfer_req=0;
			mem_transfer_inst.skip=0;
			mem_transfer.write(mem_transfer_inst);
			stage = WAITING_FOR_DROPPED_REPLY;
			if (queue_request_inst.solicited==1)
			{
				ack_out.ack1_or_nack0=0;
				ack_out.reason=1;
				ack_out.ip_addr=queue_request_inst.ip_addr;
				ack_out.queue=queue_request_inst.queue;
				ack_out.packet_sequence_number=queue_request_inst.packet_sequence_number;
				acknowledgement.write(ack_out);
			}
		}
		else if(queue_request_inst.first==1)
		{
			if ((current_queue.password!=queue_request_inst.password)||current_queue.in_progress==1)
			{
				data_write_instructions_inst.drop_packet = 1;
				instructions.write(data_write_instructions_inst);
				mem_transfer_inst.transfer_req=0;
				mem_transfer_inst.skip=0;
				mem_transfer.write(mem_transfer_inst);
				stage = WAITING_FOR_DROPPED_REPLY;
				if (queue_request_inst.solicited==1)
				{
					ack_out.ack1_or_nack0=0;
					ack_out.reason=2;
					ack_out.ip_addr=queue_request_inst.ip_addr;
					ack_out.queue=queue_request_inst.queue;
					ack_out.packet_sequence_number=queue_request_inst.packet_sequence_number;
					acknowledgement.write(ack_out);
				}
			}
			else if (!cont_fifo_data.empty())
			{
				sw_req_inst.queue=queue_request_inst.queue;
				sw_req_inst.ip_addr=0;
				sw_req_inst.request_type=2;
				sw_request.write(sw_req_inst);
				current_queue.ip_number=queue_request_inst.ip_addr;
				current_container_number=cont_fifo_data.read();
				current_queue.container_has_space=1;
				current_queue.current_container=current_container_number;
				current_queue.current_offset=0;
				current_queue.in_progress = 1;
				data_write_instructions_inst.drop_packet=0;
				data_write_instructions_inst.max_write_size=CONTAINER_SIZE;
				max_size_allowed = CONTAINER_SIZE;
				data_write_instructions_inst.mem_write_start_addr.range(63,CONTAINER_OFFSET_SIZE)=current_queue.current_container;
				data_write_instructions_inst.mem_write_start_addr.range(CONTAINER_OFFSET_SIZE-1,0)=0;
				instructions.write(data_write_instructions_inst);
				mem_transfer_inst.transfer_req=0;
				mem_transfer_inst.skip=0;
				mem_transfer.write(mem_transfer_inst);
				if (queue_request_inst.last == 1)
				{
					stage = HANDLING_CONTAINER_END_AFTER_REPLY;//possible 2 requests needed if reply is large
				}
				else
				{
					stage = WAITING_FOR_REPLY;
				}
			}
		}
		else if(queue_request_inst.last == 1)
		{
			if ((current_queue.ip_number!=queue_request_inst.ip_addr)||current_queue.in_progress==0)
			{
				data_write_instructions_inst.drop_packet = 1;
				instructions.write(data_write_instructions_inst);
				mem_transfer_inst.transfer_req=0;
				mem_transfer_inst.skip=0;
				mem_transfer.write(mem_transfer_inst);
				stage = WAITING_FOR_DROPPED_REPLY;
			}
			else if (current_queue.container_has_space==1)
			{
				data_write_instructions_inst.drop_packet=0;
				data_write_instructions_inst.mem_write_start_addr.range(63,CONTAINER_OFFSET_SIZE)=current_queue.current_container;
				data_write_instructions_inst.mem_write_start_addr.range(CONTAINER_OFFSET_SIZE-1,0)=current_queue.current_offset;
				max_size_allowed=CONTAINER_SIZE-current_queue.current_offset;
				data_write_instructions_inst.max_write_size=max_size_allowed;
				instructions.write(data_write_instructions_inst);
				mem_transfer_inst.transfer_req=0;
				mem_transfer_inst.skip=0;
				mem_transfer.write(mem_transfer_inst);
				stage = HANDLING_CONTAINER_END_AFTER_REPLY;
			}
			else if (!cont_fifo_data.empty())
			{
				current_container_number=cont_fifo_data.read();
				current_queue.container_has_space=1;
				current_queue.current_container=current_container_number;
				current_queue.current_offset=0;
				current_queue.in_progress = 1;
				sw_req_inst.queue=queue_request_inst.queue;
				sw_req_inst.request_type=2;
				sw_req_inst.ip_addr=0;
				data_write_instructions_inst.mem_write_start_addr.range(63,CONTAINER_OFFSET_SIZE)=current_queue.current_container;
				data_write_instructions_inst.mem_write_start_addr.range(CONTAINER_OFFSET_SIZE-1,0)=0;
				sw_request.write(sw_req_inst);
				data_write_instructions_inst.drop_packet=0;
				data_write_instructions_inst.max_write_size=CONTAINER_SIZE;
				max_size_allowed = CONTAINER_SIZE;
				data_write_instructions_inst.mem_write_start_addr=current_container_number<<CONTAINER_OFFSET_SIZE;
				instructions.write(data_write_instructions_inst);
				mem_transfer_inst.transfer_req=0;
				mem_transfer_inst.skip=0;
				mem_transfer.write(mem_transfer_inst);
				stage = HANDLING_CONTAINER_END_AFTER_REPLY;//possible 2 requests needed if reply is large
			}
		}
		else
		{
			if ((current_queue.ip_number!=queue_request_inst.ip_addr)||current_queue.in_progress==0)
			{
				data_write_instructions_inst.drop_packet = 1;
				instructions.write(data_write_instructions_inst);
				mem_transfer_inst.transfer_req=0;
				mem_transfer_inst.skip=0;
				mem_transfer.write(mem_transfer_inst);
				stage = WAITING_FOR_DROPPED_REPLY;
			}
			else if (current_queue.container_has_space==1)
			{
				data_write_instructions_inst.drop_packet=0;
				data_write_instructions_inst.mem_write_start_addr.range(63,CONTAINER_OFFSET_SIZE)=current_queue.current_container;
				data_write_instructions_inst.mem_write_start_addr.range(CONTAINER_OFFSET_SIZE-1,0)=current_queue.current_offset;
				max_size_allowed=CONTAINER_SIZE-current_queue.current_offset;
				data_write_instructions_inst.max_write_size=max_size_allowed;
				instructions.write(data_write_instructions_inst);
				mem_transfer_inst.transfer_req=0;
				mem_transfer_inst.skip=0;
				mem_transfer.write(mem_transfer_inst);
				stage = WAITING_FOR_REPLY;
			}
			else if (!cont_fifo_data.empty())
			{
				current_container_number=cont_fifo_data.read();
				sw_req_inst.queue=queue_request_inst.queue;
				sw_req_inst.request_type=2;
				sw_req_inst.ip_addr=0;
				sw_request.write(sw_req_inst);
				current_queue.container_has_space=1;
				current_queue.current_container=current_container_number;
				current_queue.current_offset=0;
				current_queue.in_progress = 1;
				data_write_instructions_inst.drop_packet=0;
				data_write_instructions_inst.max_write_size=CONTAINER_SIZE;
				max_size_allowed = CONTAINER_SIZE;
				data_write_instructions_inst.mem_write_start_addr.range(63,CONTAINER_OFFSET_SIZE)=current_queue.current_container;
				data_write_instructions_inst.mem_write_start_addr.range(CONTAINER_OFFSET_SIZE-1,0)=0;
				instructions.write(data_write_instructions_inst);
				mem_transfer_inst.transfer_req=0;
				mem_transfer_inst.skip = 0;
				mem_transfer.write(mem_transfer_inst);
				stage = WAITING_FOR_REPLY;//possible 2 requests needed if reply is large
			}
		}
		break;
	case WAITING_FOR_DROPPED_REPLY:
		if (!pkt_size.empty())
		{
			request_size_left=pkt_size.read();
			stage = AWAITING_ORDERS;
		}
		break;
	case WAITING_FOR_REPLY:
		if (!pkt_size.empty())
		{
			request_size_left=pkt_size.read();
			if (max_size_allowed > request_size_left)
			{
				current_queue.current_offset+=request_size_left;
				queues[queue_request_inst.queue]=current_queue;
				stage=AWAITING_ORDERS;
			}
			else if (max_size_allowed == request_size_left)
			{
				current_queue.container_has_space=0;
				queues[queue_request_inst.queue]=current_queue;
				mem_transfer_inst.container_number=current_queue.current_container;
				mem_transfer_inst.size=CONTAINER_SIZE;
				mem_transfer_inst.last=0;
				mem_transfer_inst.skip=1;
				mem_transfer_inst.queue=queue_request_inst.queue;
				mem_transfer_inst.transfer_req=1;
				mem_transfer.write(mem_transfer_inst);
				stage=AWAITING_ORDERS;
			}
			else
			{
				current_queue.container_has_space=0;
				queues[queue_request_inst.queue]=current_queue;
				mem_transfer_inst.container_number=current_queue.current_container;
				mem_transfer_inst.size=CONTAINER_SIZE;
				mem_transfer_inst.last=0;
				mem_transfer_inst.skip=1;
				mem_transfer_inst.queue=queue_request_inst.queue;
				mem_transfer_inst.transfer_req=1;
				mem_transfer.write(mem_transfer_inst);
				request_size_left=request_size_left-max_size_allowed;
				stage=SENDING_OUT_TRAILING_MEM_TRANSFER_INST;
			}
		}
		break;
	case SENDING_OUT_TRAILING_MEM_TRANSFER_INST:
		if (request_size_left == 0)
		{
			stage = AWAITING_ORDERS;
		}
		else if (CONTAINER_SIZE > request_size_left && !cont_fifo_data.empty())
		{
			current_queue.container_has_space=1;
			current_container_number=cont_fifo_data.read();
			sw_req_inst.queue=queue_request_inst.queue;
			sw_req_inst.request_type=2;
			sw_req_inst.ip_addr=0;
			sw_request.write(sw_req_inst);
			current_queue.current_offset=request_size_left;
			current_queue.current_container=current_container_number;
			data_write_instructions_inst.mem_write_start_addr.range(63,CONTAINER_OFFSET_SIZE)=current_queue.current_container;
			data_write_instructions_inst.mem_write_start_addr.range(CONTAINER_OFFSET_SIZE-1,0)=0;
			data_write_instructions_inst.max_write_size=CONTAINER_SIZE;
			data_write_instructions_inst.drop_packet=0;
			instructions.write(data_write_instructions_inst);
			queues[queue_request_inst.queue]=current_queue;
			mem_transfer_inst.transfer_req=0;
			mem_transfer_inst.skip=0;
			mem_transfer.write(mem_transfer_inst);
			stage=AWAITING_ORDERS;
		}
		else if (!cont_fifo_data.empty())
		{
			current_queue.container_has_space=0;
			current_container_number=cont_fifo_data.read();
			sw_req_inst.queue=queue_request_inst.queue;
			sw_req_inst.request_type=2;
			sw_req_inst.ip_addr=0;
			sw_request.write(sw_req_inst);
			mem_transfer_inst.container_number=current_container_number;
			mem_transfer_inst.size=CONTAINER_SIZE;
			mem_transfer_inst.last=0;
			mem_transfer_inst.skip=0;
			mem_transfer_inst.queue=queue_request_inst.queue;
			mem_transfer_inst.transfer_req=1;
			data_write_instructions_inst.mem_write_start_addr.range(63,CONTAINER_OFFSET_SIZE)=current_queue.current_container;
			data_write_instructions_inst.mem_write_start_addr.range(CONTAINER_OFFSET_SIZE-1,0)=0;
			data_write_instructions_inst.max_write_size=CONTAINER_SIZE;
			data_write_instructions_inst.drop_packet=0;
			instructions.write(data_write_instructions_inst);
			queues[queue_request_inst.queue]=current_queue;
			mem_transfer.write(mem_transfer_inst);
			request_size_left = request_size_left-CONTAINER_SIZE;
		}
		break;
	case HANDLING_CONTAINER_END_AFTER_REPLY:
		if (!pkt_size.empty())
		{
			request_size_left=pkt_size.read();
			current_queue.in_progress=0;
			if (max_size_allowed >= request_size_left)
			{
				current_queue.container_has_space=0;
				queues[queue_request_inst.queue]=current_queue;
				mem_transfer_inst.container_number=current_queue.current_container;
				mem_transfer_inst.size=current_queue.current_offset+request_size_left;
				mem_transfer_inst.last=1;
				mem_transfer_inst.skip=1;
				mem_transfer_inst.queue=queue_request_inst.queue;
				mem_transfer_inst.transfer_req=1;
				mem_transfer.write(mem_transfer_inst);
				sw_req_inst.ip_addr=queue_request_inst.ip_addr;
				sw_req_inst.queue=queue_request_inst.queue;
				sw_req_inst.request_type=4;
				if (queue_request_inst.solicited==1)
				{
					sw_request.write(sw_req_inst);
				}
				stage=AWAITING_ORDERS;
			}
			else
			{
				current_queue.container_has_space=0;
				queues[queue_request_inst.queue]=current_queue;
				mem_transfer_inst.container_number=current_queue.current_container;
				mem_transfer_inst.size=CONTAINER_SIZE;
				mem_transfer_inst.last=0;
				mem_transfer_inst.skip=1;
				mem_transfer_inst.queue=queue_request_inst.queue;
				mem_transfer_inst.transfer_req=1;
				mem_transfer.write(mem_transfer_inst);
				request_size_left=request_size_left-max_size_allowed;
				stage=SENDING_OUT_TRAILING_MEM_TRANSFER_INST_LAST;
			}
		}
		break;
	case SENDING_ACK_PACKET:
		sw_req_inst.ip_addr=queue_request_inst.ip_addr;
		sw_req_inst.queue=queue_request_inst.queue;
		sw_req_inst.request_type=4;
		sw_request.write(sw_req_inst);
		stage=AWAITING_ORDERS;
		break;
	case SENDING_OUT_TRAILING_MEM_TRANSFER_INST_LAST:
		if (request_size_left == 0)
		{
			sw_req_inst.ip_addr=queue_request_inst.ip_addr;
			sw_req_inst.queue=queue_request_inst.queue;
			sw_req_inst.request_type=4;
			sw_request.write(sw_req_inst);
			stage = AWAITING_ORDERS;
		}
		else if (CONTAINER_SIZE > request_size_left && !cont_fifo_data.empty())
		{
			current_queue.container_has_space=0;
			current_container_number=cont_fifo_data.read();
			sw_req_inst.queue=queue_request_inst.queue;
			sw_req_inst.request_type=2;
			sw_req_inst.ip_addr=0;
			sw_request.write(sw_req_inst);
			mem_transfer_inst.container_number=current_container_number;
			mem_transfer_inst.size=request_size_left;
			mem_transfer_inst.last=1;
			mem_transfer_inst.skip=0;
			mem_transfer_inst.queue=queue_request_inst.queue;
			mem_transfer_inst.transfer_req=1;
			mem_transfer.write(mem_transfer_inst);
			data_write_instructions_inst.mem_write_start_addr.range(63,CONTAINER_OFFSET_SIZE)=current_queue.current_container;
			data_write_instructions_inst.mem_write_start_addr.range(CONTAINER_OFFSET_SIZE-1,0)=0;
			data_write_instructions_inst.max_write_size=CONTAINER_SIZE;
			data_write_instructions_inst.drop_packet=0;
			instructions.write(data_write_instructions_inst);
			queues[queue_request_inst.queue]=current_queue;
			stage= queue_request_inst.solicited==1 ? SENDING_ACK_PACKET : AWAITING_ORDERS;
		}
		else if (!cont_fifo_data.empty())
		{
			current_queue.container_has_space=0;
			current_container_number=cont_fifo_data.read();
			sw_req_inst.queue=queue_request_inst.queue;
			sw_req_inst.request_type=2;
			sw_req_inst.ip_addr=0;
			sw_request.write(sw_req_inst);
			mem_transfer_inst.container_number=current_container_number;
			mem_transfer_inst.size=CONTAINER_SIZE;
			if (request_size_left == CONTAINER_SIZE)
			{
				mem_transfer_inst.last=1;
				request_size_left = 0;
			}
			else
			{
				mem_transfer_inst.last=0;
				request_size_left = request_size_left-CONTAINER_SIZE;
			}
			mem_transfer_inst.skip=0;
			mem_transfer_inst.queue=queue_request_inst.queue;
			mem_transfer_inst.transfer_req=1;
			data_write_instructions_inst.mem_write_start_addr.range(63,CONTAINER_OFFSET_SIZE)=current_queue.current_container;
			data_write_instructions_inst.mem_write_start_addr.range(CONTAINER_OFFSET_SIZE-1,0)=0;
			data_write_instructions_inst.max_write_size=CONTAINER_SIZE;
			data_write_instructions_inst.drop_packet=0;
			instructions.write(data_write_instructions_inst);
			queues[queue_request_inst.queue]=current_queue;
			mem_transfer.write(mem_transfer_inst);
		}
		break;

	}
}

