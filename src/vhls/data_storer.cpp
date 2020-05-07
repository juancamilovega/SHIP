#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"

//#define DEBUG

#define INITIALIZING 0
#define WAITING_FOR_INSTRUCTIONS 1
#define DROPPING_PACKET 2
#define PASSING_PACKET 3
#define SECONDARY_INSTRUCTIONS 4
#define DISALLIGNED_PASSING_PACKET 5
#define READING_TOP 6
#define PRE_SECONDARY_DISALLIGNED 7
#define DISALLIGNED_SECONDARY_INSTRUCTIONS 8
#define PRE_WAITING_FOR_INSTRUCTIONS 9

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

struct dataword
{
	ap_uint<512> data;
	ap_uint<64> keep;
	ap_uint<1> last;
};

struct data_write_instructions_type
{
	ap_uint<1> drop_packet;
	ap_uint<32> max_write_size;
	ap_uint<64> mem_write_start_addr;
};

void data_storer(
	hls::stream<dataword>& data_in,
	hls::stream<ap_uint<1> >& done,
	hls::stream<data_write_instructions_type>& instructions,
	ap_uint<512> *mem,
	ap_uint<32> BASE_ADDR
#ifdef DEBUG
	,
	ap_uint<64> *BASE_ADDR_OUT,
	ap_uint<64> *address_out,
	ap_uint<32> *space_left_out,
	ap_uint<32> * offset_out,
	ap_uint<1> *storing_out,
	ap_uint<64> *data_address_out,
	ap_uint<512> *data_written_out
#endif
)
{

//#pragma HLS DATAFLOW

#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = done

#pragma HLS resource core=AXI4Stream variable = data_in
#pragma HLS DATA_PACK variable=data_in

#pragma HLS resource core=AXI4Stream variable = instructions
#pragma HLS DATA_PACK variable=instructions

#pragma HLS INTERFACE ap_bus depth=1024 port=mem

#pragma HLS resource variable=mem core=AXI4M

	dataword data_read;
	data_write_instructions_type inst;
	static ap_uint<8> disalignment=0;
	static ap_uint<8> stage = WAITING_FOR_INSTRUCTIONS;
	static ap_uint<64> address=0;
	static ap_uint<512> data_to_write = 0;
	static ap_uint<32> space_left=0;
	static ap_uint<64> offset = 0;
	static ap_uint<32> end_range;
	static ap_uint<512> old_data = 0;
#ifdef DEBUG
	static ap_uint<1> storing=0;
	static ap_uint<512> data_written=0;
	static ap_uint<64> data_address=0;
	*storing_out = storing;
	*data_written_out=data_written;
	*data_address_out=data_address;
	*offset_out = offset;
	*BASE_ADDR_OUT=BASE_ADDR;
	*address_out = address;
	*space_left_out = space_left;
#endif
	switch (stage)
	{
	case WAITING_FOR_INSTRUCTIONS:
#ifdef DEBUG
		storing=0;
#endif
		if (!instructions.empty())
		{
			inst = instructions.read();
			if (inst.drop_packet == 1)
			{
				stage = DROPPING_PACKET;
			}
			else
			{
				address=(BASE_ADDR+inst.mem_write_start_addr)/64;
				space_left = inst.max_write_size;
				disalignment= inst.mem_write_start_addr%64;
				if (inst.mem_write_start_addr%64==0)
				{
					stage = PASSING_PACKET;
				}
				else
				{
					stage = READING_TOP;
				}
			}
			offset = 0;
		}
		break;
	case READING_TOP:
		end_range = 8*disalignment-1;
		data_to_write = reverseEndian512_data(mem[address]);
		old_data.range(0,end_range)=data_to_write.range(511-end_range,511);
		stage = DISALLIGNED_PASSING_PACKET;
#ifdef DEBUG
		storing = 0;
#endif
		break;
	case PRE_WAITING_FOR_INSTRUCTIONS:
		data_to_write.range(511-end_range,511)= old_data.range(0,end_range);
		data_to_write.range(0,510-end_range)= 0;
		mem[address+offset]=reverseEndian512_data(data_to_write);
		offset += 1;
		stage = WAITING_FOR_INSTRUCTIONS;
		done.write(1);
#ifdef DEBUG
		storing=1;
		data_written=data_to_write;
		data_address=address+offset-1;
#endif
		break;
	case DISALLIGNED_PASSING_PACKET:
		if (!data_in.empty())
		{
			data_read=data_in.read();
			data_to_write.range(511-end_range,511)= old_data.range(0,end_range);
			data_to_write.range(0,510-end_range)= data_read.data.range(8*disalignment,511);
			old_data = data_read.data;
			mem[address+offset]=reverseEndian512_data(data_to_write);
			offset += 1;
			space_left = space_left - 64;
			if (data_read.last == 1)
			{
				stage = PRE_WAITING_FOR_INSTRUCTIONS;
			}
			else if (space_left == 64-disalignment)
			{
				stage = PRE_SECONDARY_DISALLIGNED;
			}
			else
			{
				stage = DISALLIGNED_PASSING_PACKET;
			}
#ifdef DEBUG
			storing=1;
			data_written=data_to_write;
			data_address=address+offset-1;
		}
		else
		{
			storing=0;
#endif
		}
		break;
	case PRE_SECONDARY_DISALLIGNED:
		if (!data_in.empty())
		{
			done.write(1);
			data_read=data_in.read();
			data_to_write.range(511-end_range,511)= old_data.range(0,end_range);
			data_to_write.range(0,510-end_range)= data_read.data.range(8*disalignment,511);
			old_data = data_read.data;
			mem[address+offset]=reverseEndian512_data(data_to_write);
			offset += 1;
			if (data_read.last == 1)
			{
				stage = WAITING_FOR_INSTRUCTIONS;
			}
			else
			{
				stage = DISALLIGNED_SECONDARY_INSTRUCTIONS;
			}
#ifdef DEBUG
			storing=1;
			data_written=data_to_write;
			data_address=address+offset-1;
		}
		else
		{
			storing=0;
#endif
		}

		break;
	case DISALLIGNED_SECONDARY_INSTRUCTIONS:
		if (!instructions.empty())
		{
			inst = instructions.read();
			address=(BASE_ADDR+inst.mem_write_start_addr)/64;
			space_left = inst.max_write_size-disalignment;
			stage = DISALLIGNED_PASSING_PACKET;
			offset = 0;
		}
#ifdef DEBUG
		storing = 0;
#endif
		break;
	case DROPPING_PACKET:
		if (!data_in.empty())
		{
			data_read=data_in.read();
			if (data_read.last==1)
			{
				done.write(1);
				stage = WAITING_FOR_INSTRUCTIONS;
			}
		}
#ifdef DEBUG
		storing = 0;
#endif
		break;
	case PASSING_PACKET:
		if (!data_in.empty())
		{
			data_read=data_in.read();
			mem[address+offset]=reverseEndian512_data(data_read.data);
			offset += 1;
			space_left = space_left - 64;
			if (data_read.last == 1)
			{
				done.write(1);
				stage = WAITING_FOR_INSTRUCTIONS;
			}
			else if (space_left == 0)
			{
				done.write(1);
				stage = SECONDARY_INSTRUCTIONS;
			}
			else
			{
				stage = PASSING_PACKET;
			}
#ifdef DEBUG
			storing=1;
			data_written=data_read.data;
			data_address=address+offset-1;
		}
		else
		{
			storing=0;
#endif
		}
		break;
	case SECONDARY_INSTRUCTIONS:
		if (!instructions.empty())
		{
			inst = instructions.read();
			address=(BASE_ADDR+inst.mem_write_start_addr)/64;
			space_left = inst.max_write_size;
			stage = PASSING_PACKET;
			offset = 0;
		}
#ifdef DEBUG
		storing = 0;
#endif
		break;
	}
}
