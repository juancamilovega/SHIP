#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"
//Note requires 200MHz clock or slower, to improve if needed change fifo function
#define awaiting_metadata				0
#define metadata_part_2 				1
#define transfering_payload 			2
#define mem_transfer_out_part_2			3
#define transfering_length				4
#define transfering_queue				5
#define transfering_packet_info			6
#define transfering_buffer				7
#define transfering_index				8
#define sw_req_rx_1						9
#define sw_req_tx_1						10
#define sw_req_tx_2						11
#define sending_unbuffered_fifos		12
#define sending_buffered_fifos			13
#define mem_transfer_out_1				14
#define mem_transfer_out_2				15
#define mem_transfer_out_3				16
#define awaiting_init					17
#define sw_req_rx_2						18

#define CONT_FIFO_DATA_WIDTH 16

struct connection
{
	ap_uint<16> port;
	ap_uint<32> ip;
};

struct metadata_512
{
	ap_uint<16> port_remote;
	ap_uint<16> port_local;
	ap_uint<32> ip_remote;
};

struct metadata
{
	connection source;
	connection dest;
};

struct dataword
{
	ap_uint<64> data;
	ap_uint<8> keep;
	ap_uint<1> last;
};

struct tx_sw_request_type
{
	ap_uint<24> queue;
	ap_uint<2> request_type;//0 = read request, 1 = close_reply
							//2 = write request
	ap_uint<32> DMA_length;
};

struct rx_sw_request_type
{
	ap_uint<24> queue;
	ap_uint<3> request_type;//0 = read request, 1 = close_reply
							//2 = write request, 3= open_reply
							//4 = write ack
	ap_uint<32> ip_addr;
};

struct memory_transfer_type_fwd
{
	ap_uint<24> queue;
	ap_uint<CONT_FIFO_DATA_WIDTH> container_number;
	ap_uint<32> size;
	ap_uint<1> last;

};

void udp_non_roce_rx_interpreter(
	hls::stream<metadata_512>& rx_nonroce_meta,
	hls::stream<dataword>& rx_nonroce_data,
	hls::stream<ap_uint<64> >& sw_fifo_request,
	hls::stream<ap_uint<CONT_FIFO_DATA_WIDTH> >& cont_fifo_data,
	hls::stream<dataword>& data_to_send,
	hls::stream<rx_sw_request_type>& sw_request_rx,
	hls::stream<tx_sw_request_type>& sw_request_tx,
	hls::stream<memory_transfer_type_fwd>& mem_transfer_out,
	hls::stream<ap_uint<64> > &length,
	ap_uint<16> RDMA_PORT
)
{
#pragma HLS DATAFLOW
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = sw_fifo_request

#pragma HLS resource core=AXI4Stream variable = length

#pragma HLS resource core=AXI4Stream variable = cont_fifo_data

#pragma HLS resource core=AXI4Stream variable = rx_nonroce_meta
#pragma HLS DATA_PACK variable=rx_nonroce_meta

#pragma HLS resource core=AXI4Stream variable = rx_nonroce_data
#pragma HLS DATA_PACK variable=rx_nonroce_data

#pragma HLS resource core=AXI4Stream variable = data_to_send
#pragma HLS DATA_PACK variable=data_to_send

#pragma HLS resource core=AXI4Stream variable = mem_transfer_out
#pragma HLS DATA_PACK variable=mem_transfer_out

#pragma HLS resource core=AXI4Stream variable = sw_request_rx
#pragma HLS DATA_PACK variable=sw_request_rx

#pragma HLS resource core=AXI4Stream variable = sw_request_tx
#pragma HLS DATA_PACK variable=sw_request_tx

	static ap_uint<5> buffer_length = 0;
	static ap_uint<5> req_type  = 0;
	static ap_uint<8> stage = awaiting_metadata;
	dataword outgoing_data;
	dataword incoming_data;
	static ap_uint<64> num_of_fifos_requested=0;
	static tx_sw_request_type tx_sw_request_inst;
	static rx_sw_request_type rx_sw_request_inst;
	static metadata_512 meta_in;
	static ap_uint<5> fifos_to_send = 0;
	static memory_transfer_type_fwd memory_transfer_inst;
	switch(stage)
	{
	case awaiting_metadata:
		if ((!rx_nonroce_meta.empty()) && (!length.empty()) && (!rx_nonroce_data.empty()))
		{
			meta_in=rx_nonroce_meta.read();
			outgoing_data.data.range(63,32)=0;//The source of this is 0 (network)
			outgoing_data.data.range(31,0)=meta_in.ip_remote;
			outgoing_data.keep=0xFF;
			outgoing_data.last=0;
			data_to_send.write(outgoing_data);
			stage = metadata_part_2;
		}
		else if (!sw_fifo_request.empty() && !cont_fifo_data.empty())
		{
			num_of_fifos_requested += sw_fifo_request.read();
			outgoing_data.data.range(63,59) = 2;
			outgoing_data.data.range(58,3) = 0;
			outgoing_data.keep=0xFF;
			outgoing_data.last = 0;
			if (num_of_fifos_requested > 3)
			{
				outgoing_data.data.range(2,0) = 4;
				fifos_to_send = 4;
				buffer_length = 0;
				//num_of_fifos_requested = num_of_fifos_requested - 4;
				stage = sending_unbuffered_fifos;
			}
			else
			{
				outgoing_data.data.range(2,0) = num_of_fifos_requested;
				fifos_to_send = num_of_fifos_requested;
				//num_of_fifos_requested = 0;//reduce with each fifo to send
				buffer_length = 4;//reduce with each fifo to send
				stage = sending_buffered_fifos;
			}
			data_to_send.write(outgoing_data);
		}
		else if (!mem_transfer_out.empty())
		{
			memory_transfer_inst=mem_transfer_out.read();
			outgoing_data.data.range(63,59)=3;
			outgoing_data.data.range(58,1)=0;
			outgoing_data.data.range(0,0)=memory_transfer_inst.last;
			outgoing_data.keep=0xFF;
			outgoing_data.last=0;
			data_to_send.write(outgoing_data);
			stage = mem_transfer_out_1;
		}
		else if (!sw_request_rx.empty())
		{
			rx_sw_request_inst=sw_request_rx.read();
			outgoing_data.data.range(63,59)=1;
			outgoing_data.data.range(58,3)=0;
			outgoing_data.data.range(2,0)=rx_sw_request_inst.request_type;
			outgoing_data.keep=0xFF;
			outgoing_data.last=0;
			data_to_send.write(outgoing_data);
			stage = sw_req_rx_1;
		}
		else if (!sw_request_tx.empty())
		{
			tx_sw_request_inst=sw_request_tx.read();
			outgoing_data.data.range(63,59)=1;
			outgoing_data.data.range(58,58)=1;
			outgoing_data.data.range(57,2)=0;
			outgoing_data.data.range(1,0)=tx_sw_request_inst.request_type;
			outgoing_data.keep=0xFF;
			outgoing_data.last=0;
			data_to_send.write(outgoing_data);
			stage = sw_req_tx_1;
		}
		else if (num_of_fifos_requested > 0 && !cont_fifo_data.empty())
		{
			outgoing_data.data.range(63,59) = 2;
			outgoing_data.data.range(58,3) = 0;
			outgoing_data.keep=0xFF;
			outgoing_data.last = 0;
			if (num_of_fifos_requested > 3)
			{
				outgoing_data.data.range(2,0) = 4;
				fifos_to_send = 4;
				buffer_length = 0;
				//num_of_fifos_requested = num_of_fifos_requested - 4;
				stage = sending_unbuffered_fifos;
			}
			else
			{
				outgoing_data.data.range(2,0) = num_of_fifos_requested;
				fifos_to_send = num_of_fifos_requested;
				//num_of_fifos_requested = 0;
				buffer_length = 4;//reduce with each fifo to send
				stage = sending_buffered_fifos;
			}
			data_to_send.write(outgoing_data);
		}
		break;
	case sending_unbuffered_fifos:
		if (!cont_fifo_data.empty())
		{
			outgoing_data.data=cont_fifo_data.read();
			outgoing_data.keep = 0xFF;
			outgoing_data.last = (fifos_to_send==1) ? 1 : 0;
			stage = (fifos_to_send==1) ? awaiting_metadata : sending_unbuffered_fifos;
			fifos_to_send--;
			num_of_fifos_requested --;
			data_to_send.write(outgoing_data);
		}
		break;
	case sending_buffered_fifos:
		if (!cont_fifo_data.empty())
		{
			outgoing_data.data=cont_fifo_data.read();
			outgoing_data.keep = 0xFF;
			outgoing_data.last = 0;
			stage = (fifos_to_send==1) ? transfering_buffer : sending_buffered_fifos;
			fifos_to_send--;
			num_of_fifos_requested --;
			buffer_length--;
			data_to_send.write(outgoing_data);
		}
		break;
	case sw_req_rx_1:
		outgoing_data.data = rx_sw_request_inst.queue;
		outgoing_data.keep = 0xFF;
		outgoing_data.last = 0;
		data_to_send.write(outgoing_data);
		buffer_length = 2;
		stage = sw_req_rx_2;
		break;
	case sw_req_rx_2:
		outgoing_data.data = rx_sw_request_inst.ip_addr;
		outgoing_data.keep = 0xFF;
		outgoing_data.last = 0;
		data_to_send.write(outgoing_data);
		buffer_length = 2;
		stage = transfering_buffer;
		break;
	case sw_req_tx_1:
		outgoing_data.data = tx_sw_request_inst.queue;
		outgoing_data.keep = 0xFF;
		outgoing_data.last = 0;
		data_to_send.write(outgoing_data);
		stage = sw_req_tx_2;
		break;
	case sw_req_tx_2:
		outgoing_data.data = tx_sw_request_inst.DMA_length;
		outgoing_data.keep = 0xFF;
		outgoing_data.last = 0;
		data_to_send.write(outgoing_data);
		buffer_length = 2;
		stage = transfering_buffer;
		break;
	case mem_transfer_out_1:
		outgoing_data.data=memory_transfer_inst.queue;
		outgoing_data.keep = 0xFF;
		outgoing_data.last = 0;
		data_to_send.write(outgoing_data);
		stage = mem_transfer_out_2;
		break;
	case mem_transfer_out_2:
		outgoing_data.data=memory_transfer_inst.container_number;
		outgoing_data.keep = 0xFF;
		outgoing_data.last = 0;
		data_to_send.write(outgoing_data);
		stage = mem_transfer_out_3;
		break;
	case mem_transfer_out_3:
		outgoing_data.data=memory_transfer_inst.size;
		outgoing_data.keep = 0xFF;
		outgoing_data.last = 0;
		data_to_send.write(outgoing_data);
		buffer_length = 1;
		stage = transfering_buffer;
		break;
	case metadata_part_2:
		outgoing_data.data.range(63,32)=0;//The source of this is 0 (network)
		outgoing_data.data.range(31,16)=meta_in.port_remote;
		outgoing_data.data.range(15,0)=meta_in.port_local;
		outgoing_data.keep=0xFF;
		outgoing_data.last=0;
		data_to_send.write(outgoing_data);
		stage = meta_in.port_local==RDMA_PORT ? transfering_packet_info : transfering_length;
		buffer_length = 2;
		break;
	case transfering_packet_info:
		if (!rx_nonroce_data.empty())
		{
			outgoing_data=rx_nonroce_data.read();
			data_to_send.write(outgoing_data);
			req_type=outgoing_data.data.range(63,60);
			stage= (req_type==1||req_type==3 || req_type == 5) ? transfering_length : transfering_queue;
			buffer_length = 1;
		}
		break;
	case transfering_queue:
		if (!rx_nonroce_data.empty() && !length.empty())
		{
			length.read();
			incoming_data=rx_nonroce_data.read();
			outgoing_data.data=incoming_data.data;
			outgoing_data.keep=0xFF;
			outgoing_data.last = 0;
			data_to_send.write(outgoing_data);
			buffer_length = 1;
			stage= (req_type==4) ? transfering_index : transfering_buffer;
		}
		break;
	case transfering_index:
		if (!rx_nonroce_data.empty())
		{
			incoming_data=rx_nonroce_data.read();
			outgoing_data.data=incoming_data.data;
			outgoing_data.keep=0xFF;
			outgoing_data.last = 1;
			data_to_send.write(outgoing_data);
			stage= awaiting_metadata;
		}
		break;
	case transfering_buffer:
		outgoing_data.data=0;
		outgoing_data.keep=0xFF;
		if (buffer_length==1)
		{
			outgoing_data.last = 1;
			stage = awaiting_metadata;
		}
		else
		{
			buffer_length--;
			outgoing_data.last = 0;
			stage = transfering_buffer;
		}
		data_to_send.write(outgoing_data);
		break;
	case transfering_length:
		if (!length.empty())
		{
			outgoing_data.data=length.read();
			outgoing_data.keep=0xFF;
			outgoing_data.last=0;
			data_to_send.write(outgoing_data);
			stage = transfering_payload;
		}
		break;
	case transfering_payload:
		if (!rx_nonroce_data.empty())
		{
			incoming_data=rx_nonroce_data.read();
			outgoing_data.data = incoming_data.data;
			outgoing_data.keep = incoming_data.keep;
			if (incoming_data.last==0)
			{
				if (buffer_length == 1)
				{
					buffer_length = 5;
					outgoing_data.last = 1;
				}
				else
				{
					buffer_length --;
					outgoing_data.last = 0;
				}
			}
			else if (buffer_length == 1)
			{
				stage = awaiting_metadata;
				outgoing_data.last = 1;
			}
			else
			{
				buffer_length --;
				stage = transfering_buffer;
				outgoing_data.last = 0;
			}
			data_to_send.write(outgoing_data);
		}
		break;
	}
}
