#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"
//#define DEBUG
//#define DEBUG_CONT_SIZE
#define CONT_FIFO_DATA_WIDTH 16
#define EXT_WIDTH 512
#define EXT_KEEP 64
//#define FULL_KEEP (1<<(EXT_KEEP)) - 1
#define FULL_KEEP 0xFFFFFFFFFFFFFFFF
#define DIVIDING_FACTOR 64
#define CONTAINER_SHIFT 20
#define INITIALIZING 0
#define WAITING_FOR_INSTRUCTIONS 1
#define TRANSFERING 2

ap_uint <64> reverseEndian64_data(ap_uint <64> X) {
#pragma HLS INLINE
    ap_uint <64> x;
    x.range(7,0)=X.range(63,56);
    x.range(15,8)=X.range(55,48);
    x.range(23,16)=X.range(47,40);
    x.range(31,24)=X.range(39,32);
    x.range(39,32)=X.range(31,24);
    x.range(47,40)=X.range(23,16);
    x.range(55,48)=X.range(15,8);
    x.range(63,56)=X.range(7,0);
 return x;
}
ap_uint<512> reverseEndian512_data(ap_uint<512> X){
#pragma HLS INLINE
    ap_uint <512> x;
    x.range(63,0)=reverseEndian64_data(X.range(511,448));
    x.range(127,64)=reverseEndian64_data(X.range(447,384));
    x.range(191,128)=reverseEndian64_data(X.range(383,320));
    x.range(255,192)=reverseEndian64_data(X.range(319,256));
    x.range(319,256)=reverseEndian64_data(X.range(255,192));
    x.range(383,320)=reverseEndian64_data(X.range(191,128));
    x.range(447,384)=reverseEndian64_data(X.range(127,64));
    x.range(511,448)=reverseEndian64_data(X.range(63,0));
    return x;
}

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

struct dataword_ext
{
	ap_uint<EXT_WIDTH> data;
	ap_uint<EXT_KEEP> keep;
	ap_uint<1> last;
};

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
void data_reader(
	hls::stream<data_info_out>& from_rrrh,
	hls::stream<dataword_ext>& rdma_read_payload,
	hls::stream<flags>& read_flags,
	hls::stream<aeth>& rdma_read_aeth,
	//ap_uint<6> CONTAINER_SHIFT,
	ap_uint<EXT_WIDTH> *mem,
	ap_uint<32> BASE_ADDR,
	hls::stream<ap_uint<CONT_FIFO_DATA_WIDTH> >& cont_fifo_data
#ifdef DEBUG
	,ap_uint<64> *data_reader_address_out,
	ap_uint<32> *data_reader_current_offset_out,
	ap_uint<64> *address_out
#endif
)
{

//#pragma HLS DATAFLOW

#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = cont_fifo_data

#pragma HLS resource core=AXI4Stream variable = from_rrrh
#pragma HLS DATA_PACK variable=from_rrrh

#pragma HLS resource core=AXI4Stream variable = rdma_read_payload
#pragma HLS DATA_PACK variable=rdma_read_payload

#pragma HLS resource core=AXI4Stream variable = read_flags
#pragma HLS DATA_PACK variable=read_flags

#pragma HLS resource core=AXI4Stream variable = rdma_read_aeth
#pragma HLS DATA_PACK variable=rdma_read_aeth

#pragma HLS INTERFACE ap_bus depth=512 port=mem

#pragma HLS resource variable=mem core=AXI4M


	static ap_uint<8> stage = WAITING_FOR_INSTRUCTIONS;
	static data_info_out data_info_in;
	flags flags_out;
	aeth aeth_out;
	dataword_ext data_out;
	static ap_uint<64> current_offset = 0;
	static ap_uint<64> num_slices = 0;
	ap_uint<64> num_slices_temp;
	ap_uint<64> address_temp;
	ap_uint<64> remainder = 0;
	ap_uint<64> true_size;
	ap_uint<2> temp_padding;
	static ap_uint<EXT_KEEP> last_keep=0;
	static ap_uint<64> address=0;
	switch(stage)
	{
	case WAITING_FOR_INSTRUCTIONS:
		if (!from_rrrh.empty())
		{
			data_info_in=from_rrrh.read();
			address_temp.range(63,CONTAINER_SHIFT-6)= data_info_in.container_number;
			address_temp.range(CONTAINER_SHIFT-7,0)= 0;
			current_offset = 0;
			flags_out.ack_req=0;
			flags_out.dest_qp=data_info_in.dest_qp;
			flags_out.first=data_info_in.first;
			flags_out.last=data_info_in.last;
			flags_out.mig_req=0;
			flags_out.ip_addr=data_info_in.ip_addr;
			temp_padding=4-(data_info_in.size%4);
			if (temp_padding==4)
			{
				true_size = data_info_in.size;
				flags_out.padding=0;
				flags_out.payload_length=data_info_in.size;
			}
			else
			{
				true_size = data_info_in.size+temp_padding;
				flags_out.padding=temp_padding;
				flags_out.payload_length=data_info_in.size+temp_padding;
			}
			remainder=true_size%DIVIDING_FACTOR;
			flags_out.solicited_event=0;
			aeth_out.MSN=data_info_in.packet_sequence_number;
			aeth_out.syndrome=0x1F;
			read_flags.write(flags_out);
			num_slices_temp=(true_size/DIVIDING_FACTOR);
			if (remainder==0)
			{
				last_keep=FULL_KEEP;
				num_slices=num_slices_temp;
			}
			else
			{
				last_keep=FULL_KEEP<<(64-remainder);
				num_slices=num_slices_temp+1;
			}
			if (data_info_in.first||data_info_in.last)
			{
				rdma_read_aeth.write(aeth_out);
			}
			stage=TRANSFERING;
			address=BASE_ADDR/DIVIDING_FACTOR+address_temp;
		}
		break;
	case TRANSFERING:
		data_out.data=reverseEndian512_data(mem[address+current_offset]);
		current_offset += 1;
		if (current_offset==num_slices)
		{
			data_out.keep=last_keep;
			data_out.last = 1;
			stage = WAITING_FOR_INSTRUCTIONS;
			cont_fifo_data.write(data_info_in.container_number);
		}
		else
		{
			data_out.keep=FULL_KEEP;
			data_out.last = 0;
			stage = TRANSFERING;
		}
		rdma_read_payload.write(data_out);
		break;
	}
}
