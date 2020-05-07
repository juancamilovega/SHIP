#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"

#define Awaiting_Sender_Info 	0
#define Passing_Network_Meta 	1
#define Passing_Network_Data 	2
#define Change_Queue_0 			3
#define Change_Queue_1 			4
#define Change_Queue_2 			5
#define Change_Queue_3 			6
#define Change_Queue_1_1 		7
#define Change_Queue_3_1 		8
#define Change_Queue_5			9
#define Change_Queue_5_1		10
#define Change_Queue_6			11
#define FIFO_REQ_1 				12
#define FIFO_REQ_2 				13
#define FIFO_REQ_CLASSIC 		14
#define Done_Signal_1 			15
#define Done_Signal_2 			16
#define Done_Signal_3 			17
#define PASSING_THE_PAD 		18
#define ACK_STAGE_1				19
#define ACK_STAGE_2				20

#define CONT_FIFO_DATA_WIDTH 16

struct metadata_512
{
	ap_uint<16> port_remote;
	ap_uint<16> port_local;
	ap_uint<32> ip_remote;
};
struct ack_type
{
	ap_uint<1> ack1_or_nack0;
	ap_uint<5> reason;
	ap_uint<24> packet_sequence_number;
	ap_uint<32> ip_addr;
	ap_uint<24> queue;
};
struct done_signal_format
{
	ap_uint<1> success;
	ap_uint<24> queue;
	ap_uint<CONT_FIFO_DATA_WIDTH> container_number;
	ap_uint<64> read_size;
};

struct dataword
{
	ap_uint<64> data;
	ap_uint<8> keep;
	ap_uint<1> last;
};

struct add_queue_type
{
	ap_uint<24> queue;
	ap_uint<32> password;
	ap_uint<1> add1_or_remove0;
};

void udp_non_roce_tx_interpreter(
	hls::stream<add_queue_type>& change_queue_rx,
	hls::stream<add_queue_type>& change_queue_tx,
	hls::stream<metadata_512>& tx_nonroce_meta,
	hls::stream<dataword>& tx_nonroce_data,
	hls::stream<ap_uint<CONT_FIFO_DATA_WIDTH> >& cont_fifo_data,
	hls::stream<ap_uint<64> >& sw_fifo_request,
	hls::stream<done_signal_format> done_sig,
	hls::stream<dataword>& tx_data_in,
	hls::stream<ack_type>& ack_out
	)
{
#pragma HLS DATAFLOW
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = cont_fifo_data

#pragma HLS resource core=AXI4Stream variable = sw_fifo_request

#pragma HLS resource core=AXI4Stream variable = change_queue_rx
#pragma HLS DATA_PACK variable=change_queue_rx

#pragma HLS resource core=AXI4Stream variable = ack_out
#pragma HLS DATA_PACK variable=ack_out

#pragma HLS resource core=AXI4Stream variable = done_sig
#pragma HLS DATA_PACK variable=done_sig

#pragma HLS resource core=AXI4Stream variable = change_queue_tx
#pragma HLS DATA_PACK variable=change_queue_tx

#pragma HLS resource core=AXI4Stream variable = tx_nonroce_meta
#pragma HLS DATA_PACK variable=tx_nonroce_meta

#pragma HLS resource core=AXI4Stream variable = tx_nonroce_data
#pragma HLS DATA_PACK variable=tx_nonroce_data

#pragma HLS resource core=AXI4Stream variable = tx_data_in
#pragma HLS DATA_PACK variable=tx_data_in

	static ap_uint<8> stage = Awaiting_Sender_Info;
	static ap_uint<16> local_port_number = 0;
	dataword data_in_buffer;
	dataword data_out_buffer;
	static ap_uint<64> type_0_pad_count = 0;
	static ap_uint<64> length = 0;
	static ap_uint<3> num_to_return =0;
	static done_signal_format done_signal_inst;
	metadata_512 meta_out;
	static add_queue_type add_queue_inst;
	static ack_type ack_inst;
	switch(stage)
	{
	case Awaiting_Sender_Info:
		if (!tx_data_in.empty())
		{
			data_in_buffer=tx_data_in.read();
			if (data_in_buffer.data.range(63,59)==0)
			{
				stage = Passing_Network_Meta;
				local_port_number=data_in_buffer.data.range(15,0);
			}
			else if (data_in_buffer.data.range(63,59)==1 && data_in_buffer.data.range(7,0)==1)
			{
				stage = Change_Queue_1;
				add_queue_inst.add1_or_remove0=1;
			}
			else if (data_in_buffer.data.range(63,59)==1 && data_in_buffer.data.range(7,0)==3)
			{
				stage = Change_Queue_3;
				add_queue_inst.add1_or_remove0=1;
			}
			else if (data_in_buffer.data.range(63,59)==1 && data_in_buffer.data.range(7,0)==5)
			{
				stage = Change_Queue_5;
				add_queue_inst.add1_or_remove0=1;
			}
			else if (data_in_buffer.data.range(63,59)==1 && data_in_buffer.data.range(7,0)==6)
			{
				stage = Change_Queue_6;
				add_queue_inst.add1_or_remove0=1;
			}
			else if (data_in_buffer.data.range(63,59)==1 && data_in_buffer.data.range(7,0)==0)
			{
				add_queue_inst.add1_or_remove0=0;
				add_queue_inst.password=0;
				stage = Change_Queue_0;
			}
			else if (data_in_buffer.data.range(63,59)==1 && data_in_buffer.data.range(7,0)==2)
			{
				add_queue_inst.add1_or_remove0=0;
				add_queue_inst.password=0;
				stage = Change_Queue_2;
			}
			else if (data_in_buffer.data.range(63,59)==2 && data_in_buffer.data.range(0,0)==1)
			{
				num_to_return=data_in_buffer.data.range(3,1);
				type_0_pad_count=1+data_in_buffer.data.range(3,1);
				stage = data_in_buffer.data.range(3,1)==0? FIFO_REQ_CLASSIC: FIFO_REQ_1 ;
			}
			else if (data_in_buffer.data.range(63,59)==2 && data_in_buffer.data.range(0,0)==0)
			{
				stage = FIFO_REQ_2;
			}
			else if (data_in_buffer.data.range(63,59)==3)
			{
				stage = Done_Signal_1;
				done_signal_inst.success=data_in_buffer.data.range(0,0);
			}
			else if (data_in_buffer.data.range(63,59)==4)
			{
				ack_inst.ack1_or_nack0=data_in_buffer.data.bit(58);
				ack_inst.reason=data_in_buffer.data.range(57,53);
				ack_inst.ip_addr=data_in_buffer.data.range(31,0);
				stage = ACK_STAGE_1;
			}
			else
			{
				stage = Awaiting_Sender_Info;
			}
		}
		break;
	case ACK_STAGE_1:
		if (!tx_data_in.empty() && !cont_fifo_data.full())
		{
			data_in_buffer=tx_data_in.read();
			ack_inst.packet_sequence_number=data_in_buffer.data;
			stage = ACK_STAGE_2;
		}
		break;
	case ACK_STAGE_2:
		if (!tx_data_in.empty() && !cont_fifo_data.full())
		{
			data_in_buffer=tx_data_in.read();
			ack_inst.queue=data_in_buffer.data;
			type_0_pad_count=3;
			ack_out.write(ack_inst);
			stage = PASSING_THE_PAD;
		}
		break;
	case FIFO_REQ_CLASSIC:
		if (!tx_data_in.empty() && !cont_fifo_data.full())
		{
			data_in_buffer=tx_data_in.read();
			cont_fifo_data.write(data_in_buffer.data);
			type_0_pad_count = 2;
			stage = PASSING_THE_PAD;
		}
		break;
	case FIFO_REQ_1:
		if (!tx_data_in.empty() && !cont_fifo_data.full())
		{
			data_in_buffer=tx_data_in.read();
			cont_fifo_data.write(data_in_buffer.data);
			if (num_to_return==1 && type_0_pad_count==5)
			{
				stage = Awaiting_Sender_Info;
			}
			else if (num_to_return==1)
			{
				stage = PASSING_THE_PAD;
			}
			else
			{
				num_to_return--;
				stage = FIFO_REQ_1;
			}
		}
		break;
	case FIFO_REQ_2:
		if (!tx_data_in.empty() && !sw_fifo_request.full())
		{
			data_in_buffer=tx_data_in.read();
			sw_fifo_request.write(data_in_buffer.data);
			type_0_pad_count=2;
			stage = PASSING_THE_PAD;
		}
		break;
	case Done_Signal_1:
		if (!tx_data_in.empty())
		{
			data_in_buffer=tx_data_in.read();
			done_signal_inst.queue=data_in_buffer.data;
			stage = Done_Signal_2;
		}
		break;
	case Done_Signal_2:
		if (!tx_data_in.empty())
		{
			data_in_buffer=tx_data_in.read();
			done_signal_inst.read_size=data_in_buffer.data;
			stage = Done_Signal_3;
		}
		break;
	case Done_Signal_3:
		if (!tx_data_in.empty())
		{
			data_in_buffer=tx_data_in.read();
			done_signal_inst.container_number=data_in_buffer.data;
			done_sig.write(done_signal_inst);
			type_0_pad_count=4;
			stage = PASSING_THE_PAD;
		}
		break;
	case Change_Queue_6:
		if (!tx_data_in.empty() && !change_queue_rx.full() && !change_queue_tx.full())
		{
			data_in_buffer=tx_data_in.read();
			add_queue_inst.queue=data_in_buffer.data.range(23,0);
			type_0_pad_count=2;
			change_queue_rx.write(add_queue_inst);
			change_queue_tx.write(add_queue_inst);
			stage = PASSING_THE_PAD;
		}
		break;
	case Change_Queue_0:
		if (!tx_data_in.empty() && !change_queue_rx.full())
		{
			data_in_buffer=tx_data_in.read();
			add_queue_inst.queue=data_in_buffer.data.range(23,0);
			type_0_pad_count=2;
			change_queue_rx.write(add_queue_inst);
			stage = PASSING_THE_PAD;
		}
		break;
	case Change_Queue_5:
		if (!tx_data_in.empty())
		{
			data_in_buffer=tx_data_in.read();
			stage = Change_Queue_5_1;
			add_queue_inst.queue=data_in_buffer.data.range(23,0);
		}
		break;
	case Change_Queue_1:
		if (!tx_data_in.empty())
		{
			data_in_buffer=tx_data_in.read();
			stage = Change_Queue_1_1;
			add_queue_inst.queue=data_in_buffer.data.range(23,0);
		}
		break;
	case Change_Queue_5_1:
		if (!tx_data_in.empty() && !change_queue_rx.full() && !change_queue_tx.full())
		{
			data_in_buffer=tx_data_in.read();
			add_queue_inst.password=data_in_buffer.data.range(63,32);
			change_queue_rx.write(add_queue_inst);
			change_queue_tx.write(add_queue_inst);
			type_0_pad_count=3;
			stage = PASSING_THE_PAD;
		}
		break;
	case Change_Queue_1_1:
		if (!tx_data_in.empty() && !change_queue_rx.full() )
		{
			data_in_buffer=tx_data_in.read();
			add_queue_inst.password=data_in_buffer.data.range(63,32);
			change_queue_rx.write(add_queue_inst);
			type_0_pad_count=3;
			stage = PASSING_THE_PAD;
		}
		break;
	case Change_Queue_2:
		if (!tx_data_in.empty() && !change_queue_tx.full())
		{
			data_in_buffer=tx_data_in.read();
			add_queue_inst.queue=data_in_buffer.data.range(23,0);
			type_0_pad_count=2;
			change_queue_tx.write(add_queue_inst);
			stage = PASSING_THE_PAD;
		}
		break;
	case Change_Queue_3:
		if (!tx_data_in.empty())
		{
			data_in_buffer=tx_data_in.read();
			stage = Change_Queue_3_1;
			add_queue_inst.queue=data_in_buffer.data.range(23,0);
		}
		break;
	case Change_Queue_3_1:
		if (!tx_data_in.empty() && !change_queue_tx.full())
		{
			data_in_buffer=tx_data_in.read();
			add_queue_inst.password=data_in_buffer.data.range(63,32);
			type_0_pad_count=3;
			stage = PASSING_THE_PAD;
			change_queue_tx.write(add_queue_inst);
		}
		break;
	case Passing_Network_Meta:
		if (!tx_data_in.empty() && !tx_nonroce_meta.full())
		{
			data_in_buffer=tx_data_in.read();
			meta_out.ip_remote=data_in_buffer.data.range(63,32);
			meta_out.port_local=local_port_number;
			length=data_in_buffer.data.range(31,16);
			meta_out.port_remote=data_in_buffer.data.range(15,0);
			stage = Passing_Network_Data;
			tx_nonroce_meta.write(meta_out);
			type_0_pad_count=2;
		}
		break;
	case Passing_Network_Data:
		if (!tx_data_in.empty() & !tx_nonroce_data.full())
		{
			data_in_buffer=tx_data_in.read();
			data_out_buffer.data=data_in_buffer.data;
			switch (length)
			{
			case 1:
				data_out_buffer.keep=0x80;
				data_out_buffer.last=0x1;
				stage = type_0_pad_count==4 ? Awaiting_Sender_Info: PASSING_THE_PAD;
				break;
			case 2:
				data_out_buffer.keep=0xC0;
				data_out_buffer.last=0x1;
				stage = type_0_pad_count==4 ? Awaiting_Sender_Info: PASSING_THE_PAD;
				break;
			case 3:
				data_out_buffer.keep=0xE0;
				data_out_buffer.last=0x1;
				stage = type_0_pad_count==4 ? Awaiting_Sender_Info: PASSING_THE_PAD;
				break;
			case 4:
				data_out_buffer.keep=0xF0;
				data_out_buffer.last=0x1;
				stage = type_0_pad_count==4 ? Awaiting_Sender_Info: PASSING_THE_PAD;
				break;
			case 5:
				data_out_buffer.keep=0xF8;
				data_out_buffer.last=0x1;
				stage = type_0_pad_count==4 ? Awaiting_Sender_Info: PASSING_THE_PAD;
				break;
			case 6:
				data_out_buffer.keep=0xFC;
				data_out_buffer.last=0x1;
				stage = type_0_pad_count==4 ? Awaiting_Sender_Info: PASSING_THE_PAD;
				break;
			case 7:
				data_out_buffer.keep=0xFE;
				data_out_buffer.last=0x1;
				stage = type_0_pad_count==4 ? Awaiting_Sender_Info: PASSING_THE_PAD;
				break;
			case 8:
				data_out_buffer.keep=0xFF;
				data_out_buffer.last=0x1;
				stage = type_0_pad_count==4 ? Awaiting_Sender_Info: PASSING_THE_PAD;
				break;
			default:
				data_out_buffer.keep=0xFF;
				data_out_buffer.last=0;
				stage = Passing_Network_Data;
				length =length - 8;
				break;
			}
			tx_nonroce_data.write(data_out_buffer);
			if (type_0_pad_count==4)
			{
				type_0_pad_count=0;
			}
			else
			{
				type_0_pad_count++;
			}
		}
		break;
	case PASSING_THE_PAD:
		if (!tx_data_in.empty())
		{
			data_in_buffer=tx_data_in.read();
			if (type_0_pad_count==4)
			{
				stage = Awaiting_Sender_Info;
				type_0_pad_count=0;
			}
			else
			{
				stage = PASSING_THE_PAD;
				type_0_pad_count ++;
			}
		}
		break;
	}
}
