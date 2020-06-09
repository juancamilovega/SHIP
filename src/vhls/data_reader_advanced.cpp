#include "hls_stream.h"
#include "ap_int.h"
#include "ap_utils.h"
//#define DEBUG
//#define DEBUG_CONT_SIZE
#define CONT_FIFO_DATA_WIDTH 16
#define FLIT_ADDR_WIDTH 6 //2^FLIT_ADDR_WIDTH is the bytes per AXI flit
#define AXI_ADDR_WIDTH 64
#define EXT_WIDTH 512
#define EXT_KEEP 64
#define AXI4_LEN_BITS 8
//#define FULL_KEEP (1<<(EXT_KEEP)) - 1
#define FULL_KEEP 0xFFFFFFFFFFFFFFFF
#define CONTAINER_SHIFT 20
#define TOP_WIDTH (AXI_ADDR_WIDTH-CONT_FIFO_DATA_WIDTH-CONTAINER_SHIFT)
#define WAITING_FOR_INSTRUCTIONS 0
#define SENDING_REQUEST 1
#define TRANSFERING 2

#define FLIT_SIZE (2^FLIT_ADDR_WIDTH)
#define BIGGEST_BURST (FLIT_ADDR_WIDTH+AXI4_LEN_BITS) // 2^BIGGEST_BURST_POSSIBLE is the bytes in the biggest burst given this width

struct read_dataword
{
	ap_uint<512> data;
	ap_uint<2> dest;
	ap_uint<1> last;
};

struct address_axi_chan
{
	ap_uint<AXI_ADDR_WIDTH> address;
	ap_uint<AXI4_LEN_BITS> length;
};

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
void data_reader_advanced(
	hls::stream<data_info_out>& from_rrrh,
	hls::stream<dataword_ext>& rdma_read_payload,
	hls::stream<flags>& read_flags,
	hls::stream<aeth>& rdma_read_aeth,
	//ap_uint<6> CONTAINER_SHIFT,
	ap_uint<TOP_WIDTH> TOP_ADDR,
	hls::stream<address_axi_chan>& mem_ar,
	hls::stream<read_dataword>& mem_r,
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

#pragma HLS resource core=AXI4Stream variable = mem_ar
#pragma HLS DATA_PACK variable=mem_ar

#pragma HLS resource core=AXI4Stream variable = mem_r
#pragma HLS DATA_PACK variable=mem_r

#pragma HLS resource core=AXI4Stream variable = rdma_read_payload
#pragma HLS DATA_PACK variable=rdma_read_payload

#pragma HLS resource core=AXI4Stream variable = read_flags
#pragma HLS DATA_PACK variable=read_flags

#pragma HLS resource core=AXI4Stream variable = rdma_read_aeth
#pragma HLS DATA_PACK variable=rdma_read_aeth


	static ap_uint<8> stage = WAITING_FOR_INSTRUCTIONS;
	static data_info_out data_info_in;
	static ap_uint<64> current_offset = 0;
	static ap_uint<AXI4_LEN_BITS> length_left = 0;
	static ap_uint<AXI_ADDR_WIDTH-FLIT_ADDR_WIDTH> num_slices = 0;
	static ap_uint<AXI_ADDR_WIDTH> offset;
	static ap_uint<CONT_FIFO_DATA_WIDTH> container_addr;
	static ap_uint<64> true_size;
	static ap_uint<EXT_KEEP> last_keep=0;
	flags flags_out;
	address_axi_chan temp_addr;
	aeth aeth_out;
	dataword_ext data_out;
	read_dataword data_in;
	ap_uint<AXI_ADDR_WIDTH-FLIT_ADDR_WIDTH> num_slices_temp;
	ap_uint<CONT_FIFO_DATA_WIDTH+CONTAINER_SHIFT> address_temp;
	ap_uint<FLIT_ADDR_WIDTH> remainder;
	ap_uint<64> size_left;
	ap_uint<2> temp_padding;
	switch(stage)
	{
	case WAITING_FOR_INSTRUCTIONS:
		if (!from_rrrh.empty())
		{
			//get the instruction
			data_info_in=from_rrrh.read();
			//Find the start address of the container
			aeth_out.MSN=data_info_in.packet_sequence_number;
			aeth_out.syndrome=0x1F;


			current_offset = 0;//Number of flits written in transaction
			flags_out.ack_req=0;
			flags_out.dest_qp=data_info_in.dest_qp;
			flags_out.first=data_info_in.first;
			flags_out.last=data_info_in.last;
			flags_out.mig_req=0;
			flags_out.ip_addr=data_info_in.ip_addr;
			temp_padding=4-(data_info_in.size%4);//Add Artificial padding
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
			flags_out.solicited_event=0;
			container_addr= data_info_in.container_number;
			stage = SENDING_REQUEST;
			offset = 0;
			read_flags.write(flags_out);
			if (data_info_in.first||data_info_in.last)
			{
				//Send an aeth since this is the first or last message
				rdma_read_aeth.write(aeth_out);
			}
		}
		break;
	case SENDING_REQUEST:
		if (!mem_ar.full())
		{
			size_left = true_size - offset;//calculate the number of bytes left to write
			num_slices_temp=true_size.range(AXI_ADDR_WIDTH-1,FLIT_ADDR_WIDTH);//Number of flits in the whole transaction rounded down
			remainder=true_size.range(FLIT_ADDR_WIDTH-1,0);//Number of extra bytes in the last flit
			temp_addr.address.range(AXI_ADDR_WIDTH-1,AXI_ADDR_WIDTH-TOP_WIDTH)=TOP_ADDR;//address of the next burst
			temp_addr.address.range(AXI_ADDR_WIDTH-TOP_WIDTH-1,AXI_ADDR_WIDTH-TOP_WIDTH-CONT_FIFO_DATA_WIDTH)=container_addr;
			temp_addr.address.range(AXI_ADDR_WIDTH-TOP_WIDTH-CONT_FIFO_DATA_WIDTH-1,0)=offset;
			if (size_left.range(AXI_ADDR_WIDTH-1,BIGGEST_BURST) != 0)
			{
				//size left is greater than the max burst size
				//Set values to max possible
				temp_addr.length=255;
				length_left = 255;
			}
			else if (remainder == 0)
			{
				//No remainder so number of flits is what's left
				temp_addr.length=size_left.range(BIGGEST_BURST-1,FLIT_ADDR_WIDTH)-1;
				length_left= size_left.range(BIGGEST_BURST-1,FLIT_ADDR_WIDTH)-1;
			}
			else
			{
				//remainder means we need one more flit than we would like
				temp_addr.length=size_left.range(BIGGEST_BURST-1,FLIT_ADDR_WIDTH);
				length_left= size_left.range(BIGGEST_BURST-1,FLIT_ADDR_WIDTH);
			}
			if (remainder==0)
			{
				last_keep=FULL_KEEP;//No wierd keeps at the end and the number of slices are as expected
				num_slices=num_slices_temp;
			}
			else
			{
				last_keep=FULL_KEEP<<(AXI_ADDR_WIDTH-remainder);//We need an extra flit with smaller keep to accomodate the remaining packet
				num_slices=num_slices_temp+1;
			}
			//Write out the burst request and start transferring
			mem_ar.write(temp_addr);
			stage=TRANSFERING;
		}
		break;
	case TRANSFERING:
		if (!mem_r.empty())
		{
			//read in the read response flit
			data_in = mem_r.read();
			//record the data
			data_out.data = reverseEndian512_data(data_in.data);
			if (data_in.dest>1)
			{
				//error state, request was bad, let us try again
				stage = SENDING_REQUEST;
			}
			else if (current_offset==num_slices-1)
			{
				//This is the last flit, mark it with the special keep and the last flag
				data_out.keep=last_keep;
				data_out.last = 1;
				stage = WAITING_FOR_INSTRUCTIONS;
				cont_fifo_data.write(data_info_in.container_number);
			}
			else if (length_left == 0)
			{
				//This is the end of the burst
				data_out.keep=FULL_KEEP;
				data_out.last = 0;
				stage = SENDING_REQUEST;
			}
			else if (data_in.last==1)
			{
				//error state since the burst should be longer, regardless lets go back and fix it.
				data_out.keep=FULL_KEEP;
				data_out.last = 0;
				stage = SENDING_REQUEST;
			}
			else
			{
				data_out.keep=FULL_KEEP;
				data_out.last = 0;
				stage = TRANSFERING;
			}
			if (data_in.dest <2)
			{
				rdma_read_payload.write(data_out);
				current_offset += 1;
				offset += FLIT_SIZE;
				length_left -= 1;
			}
		}
		break;
	}
}
