#include "hls_stream.h"
#include "ap_int.h"
#include "ap_utils.h"

//#define DEBUG

#define WAITING_FOR_INSTRUCTIONS 0x0
#define SECONDARY_INSTRUCTIONS_ALLIGNED 0x1
#define DISALIGNED_SECONDARY_INSTRUCTIONS 0x2

#define PASSING_PACKET_BUFFER_WAIT 0x10
#define PASSING_PACKET 0x11

#define DROPPING_PACKET_BUFFER_WAIT 0x20
#define DROPPING_PACKET_DROPPING_THIS_BURST 0x21

#define READING_REQ_SEND 0x30
#define WAITING_FOR_READ_REPLY 0x31
#define DISALIGNED_PASSING_PACKET 0x32
#define DISALIGNED_PRE_WAITING_FOR_INSTRUCTIONS 0x33

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

struct done_controller
{
	ap_uint<1> expect_done_sig;
	ap_uint<1> send_done_sig;
};

struct address_axi_chan
{
	ap_uint<64> address;
	ap_uint<8> length;
};

struct read_dataword
{
	ap_uint<512> data;
	ap_uint<2> dest;
	ap_uint<1> last;
};

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

void data_storer_advanced(
	hls::stream<dataword>& data_in,
	hls::stream<done_controller>& done,
	hls::stream<ap_uint<8> >& batch_in,
	hls::stream<data_write_instructions_type>& instructions,
	hls::stream<address_axi_chan>& mem_ar,
	hls::stream<address_axi_chan>& mem_aw,
	hls::stream<read_dataword>& mem_r,
	hls::stream<dataword>& mem_w,
	ap_uint<64> BASE_ADDR
	)
{

#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = data_in
#pragma HLS DATA_PACK variable=data_in

#pragma HLS resource core=AXI4Stream variable = done
#pragma HLS DATA_PACK variable=done

#pragma HLS resource core=AXI4Stream variable = batch_in

#pragma HLS resource core=AXI4Stream variable = instructions
#pragma HLS DATA_PACK variable=instructions

#pragma HLS resource core=AXI4Stream variable = mem_ar
#pragma HLS DATA_PACK variable=mem_ar

#pragma HLS resource core=AXI4Stream variable = mem_aw
#pragma HLS DATA_PACK variable=mem_aw

#pragma HLS resource core=AXI4Stream variable = mem_r
#pragma HLS DATA_PACK variable=mem_r

#pragma HLS resource core=AXI4Stream variable = mem_w
#pragma HLS DATA_PACK variable=mem_w

	static ap_uint<8> stage = WAITING_FOR_INSTRUCTIONS;
	static ap_uint<64> address=0;
	static ap_uint<32> space_left=0;
	static ap_uint<8> disalignment=0;
	static ap_uint<64> offset = 0;
	static ap_uint<8> number_in_buffer;
	static dataword old_data;
	static ap_uint<1> mem_is_informed = 0;
	static ap_uint<1> pre_sec_stage = 0;
	read_dataword rdw;
	data_write_instructions_type inst;
	dataword data_read;
	dataword data_to_write;
	ap_uint<512> temp_data_to_write;
	ap_uint<512> temp_data_to_write2;
	ap_uint<8> batch_read;
	done_controller done_msg;
	address_axi_chan addr_info;
	ap_uint<8> number_in_buffer_temp;
	switch(stage)
	{
	case WAITING_FOR_INSTRUCTIONS:
		if (!instructions.empty())
		{
			//Get the instruction and see if it needs the packet to drop or continue
			inst = instructions.read();
			if (inst.drop_packet == 1)
			{
				stage = DROPPING_PACKET_BUFFER_WAIT;
			}
			else
			{
				//find the address we are writing to and record the parameters. Determine if the access is disaligned
				address = BASE_ADDR+inst.mem_write_start_addr;
				space_left = inst.max_write_size;
				disalignment= inst.mem_write_start_addr%64;
				if (inst.mem_write_start_addr%64==0)
				{
					//It is not disaligned
					stage = PASSING_PACKET_BUFFER_WAIT;
				}
				else
				{
					//It is disaligned, need to read what is in the buffer to merge the two
					stage = READING_REQ_SEND;
				}
			}
		}
		offset = 0;
		break;
	case SECONDARY_INSTRUCTIONS_ALLIGNED:
		//Case when the packet is not done but the buffer we were writing to is full, awaiting further instructions
		if (!instructions.empty() && (!mem_aw.full() || number_in_buffer==0))
		{
			//Instructions are here and either we are able to initiate a new burst or we still have no data to send (last buffer was finished)
			inst = instructions.read();
			//Get omfp
			address = BASE_ADDR+inst.mem_write_start_addr;
			space_left = inst.max_write_size;
			if (number_in_buffer==0)
			{
				//Need to wait for new buffer to come in before continuing
				stage = PASSING_PACKET_BUFFER_WAIT;
			}
			else if (inst.max_write_size < 64 * number_in_buffer)
			{
				//We can not fit the full buffer, we will send a length of the max we can send
				stage = PASSING_PACKET;
				addr_info.length=inst.max_write_size/64-1;
				addr_info.address=BASE_ADDR+inst.mem_write_start_addr;
				mem_aw.write(addr_info);
			}
			else
			{
				//the full buffer can be sent so an instruction is sent for it.
				stage = PASSING_PACKET;
				addr_info.length=number_in_buffer-1;
				addr_info.address=BASE_ADDR+inst.mem_write_start_addr;
				mem_aw.write(addr_info);
			}
			offset = 0;
		}
		break;
	case DISALIGNED_SECONDARY_INSTRUCTIONS:
		if (!instructions.empty() && (!mem_aw.full() || number_in_buffer==0))
		{
			inst = instructions.read();
			address = BASE_ADDR+inst.mem_write_start_addr;
			space_left = inst.max_write_size - disalignment;//The left over from last time consumes a bit of room we need to subtract from max write size
			offset = 0;
			if (number_in_buffer != 0 && ((inst.max_write_size - disalignment) < 64 * number_in_buffer))
			{
				addr_info.length=inst.max_write_size/64-1;
				addr_info.address=BASE_ADDR+inst.mem_write_start_addr;
				mem_aw.write(addr_info);
			}
			else if (number_in_buffer != 0)
			{
				addr_info.length=number_in_buffer-1;
				addr_info.address=BASE_ADDR+inst.mem_write_start_addr;
				mem_aw.write(addr_info);
			}
			stage = DISALIGNED_PASSING_PACKET;
			pre_sec_stage=0;
		}
		break;
	case PASSING_PACKET_BUFFER_WAIT:
		if (!batch_in.empty() && !mem_aw.full() && !mem_w.full() && !data_in.empty())
		{
			//We have a new batch ready and data ready and both AXI FULL channels are ready to receive both
			data_read = data_in.read();
			data_to_write.data=reverseEndian64_data(data_read.data);
			//All the data is significant
			data_to_write.keep=0xffffffffffffffff;
			batch_read = batch_in.read();
			addr_info.address=address + offset;
			done_msg.expect_done_sig=1;
			if (data_read.last == 1)
			{
				//The end is here, signal a done and return to main stage
				stage = WAITING_FOR_INSTRUCTIONS;
				done_msg.send_done_sig=1;
				addr_info.length=0;
				data_to_write.last = 1;
				number_in_buffer=0;
			}
			else if (space_left == 64)
			{
				//We are out of space, a further instruction is needed. Signal done to say that at least this instruction is done
				number_in_buffer = batch_read-1;
				stage = SECONDARY_INSTRUCTIONS_ALLIGNED;
				addr_info.length=0;
				data_to_write.last = 1;
				done_msg.send_done_sig=1;
			}
			else if (space_left < 64 * batch_read)
			{
				//The full batch will not fit so we allocate as much as we can
				addr_info.length=space_left/64-1;
				number_in_buffer = batch_read-1;
				stage = PASSING_PACKET;
				data_to_write.last = 0;
				done_msg.send_done_sig=0;
			}
			else if (batch_read == 1)
			{
				//The batch size is 1 so we can send it but then we need to wait for the next one.
				addr_info.length=0;
				stage = PASSING_PACKET_BUFFER_WAIT;
				data_to_write.last = 1;
				done_msg.send_done_sig=0;
				number_in_buffer=0;
			}
			else
			{
				//The batch size is more than 1 it fits and its not the end (normal case). Send the length as the full buffer
				addr_info.length=batch_read-1;
				number_in_buffer = batch_read-1;
				stage = PASSING_PACKET;
				data_to_write.last = 0;
				done_msg.send_done_sig=0;
			}
			//Send the data and address info
			mem_w.write(data_to_write);
			mem_aw.write(addr_info);
			//Send the data to the done manager
			done.write(done_msg);
			//Increment the offset and decrement the space left in the container.
			space_left = space_left-64;
			offset = offset + 64;
		}
		else if (!batch_in.empty() && !mem_aw.full())
		{
			//Data is not ready to send or AXIF not ready for more. In either case just read the batch info
			batch_read = batch_in.read();
			addr_info.address=address + offset;
			//Get the smaller of space left or length as the number to send in AXIF
			if (space_left < 64 * batch_read)
			{
				addr_info.length=space_left/64-1;
			}
			else
			{
				addr_info.length=batch_read-1;
			}
			//Send the AXIF memory request
			mem_aw.write(addr_info);
			//Send the done message
			done_msg.expect_done_sig=1;
			done_msg.send_done_sig=0;
			done.write(done_msg);
			//Record the number of flits to send.
			number_in_buffer = batch_read;
			stage = PASSING_PACKET;
		}
		break;
	case PASSING_PACKET:
		//We are in the middle of sending a packet
		if (!mem_w.full() && !data_in.empty())
		{
			//get packet and forward data
			data_read = data_in.read();
			data_to_write.data=reverseEndian64_data(data_read.data);
			data_to_write.keep=0xffffffffffffffff;
			if (data_read.last == 1)
			{
				//End of packet, send a done signal and go back to start stage
				stage = WAITING_FOR_INSTRUCTIONS;
				done_msg.expect_done_sig=0;
				done_msg.send_done_sig=1;
				done.write(done_msg);
				data_to_write.last = 1;
				number_in_buffer=0;
			}
			else if (space_left == 64)
			{
				//With this packet the buffer is full, go for waiting for secondary instructions
				stage = SECONDARY_INSTRUCTIONS_ALLIGNED;
				data_to_write.last = 1;
				done_msg.expect_done_sig=0;
				done_msg.send_done_sig=1;
				done.write(done_msg);
				number_in_buffer = number_in_buffer-1;
			}
			else if (number_in_buffer==1)
			{
				//This is the end of the buffer, need to ask for more
				data_to_write.last = 1;
				number_in_buffer = 0;
				stage = PASSING_PACKET_BUFFER_WAIT;
			}
			else
			{
				//Normal case, decrease number in buffer and don't mark it like the end of a mem burst
				number_in_buffer = number_in_buffer-1;
				data_to_write.last = 0;
			}
			//Send the data, decrease space left, increase offset
			mem_w.write(data_to_write);
			offset = offset + 64;
			space_left = space_left - 64;
		}
		break;
	case DROPPING_PACKET_BUFFER_WAIT:
		if (!batch_in.empty() && !data_in.empty())
		{
			//If there is data to drop and its buffer came in
			data_read=data_in.read();
			batch_read = batch_in.read();
			if (data_read.last==1)
			{
				//Finally the end of the packet to drop. Drop it, send done, reset everything
				done_msg.expect_done_sig=0;
				done_msg.send_done_sig=1;
				done.write(done_msg);
				number_in_buffer=0;
				stage = WAITING_FOR_INSTRUCTIONS;
			}
			else if (batch_read==1)
			{
				//End of batch but not of packet, wait for next batch
				stage = DROPPING_PACKET_BUFFER_WAIT;
				number_in_buffer=0;
			}
			else
			{
				//Record number in this batch and drop the rest
				number_in_buffer = batch_read-1;
				stage = DROPPING_PACKET_DROPPING_THIS_BURST;
			}
		}
		else if (!batch_in.empty())
		{
			//Record the number in this batch but since no data is ready we can't drop anything
			batch_read = batch_in.read();
			number_in_buffer = batch_read;
			stage = DROPPING_PACKET_DROPPING_THIS_BURST;
		}
		break;
	case DROPPING_PACKET_DROPPING_THIS_BURST:
		//Drop the data
		if (!data_in.empty())
		{
			data_read=data_in.read();
			if (data_read.last==1)
			{
				//Finally done, can go back to instructions
				done_msg.expect_done_sig=0;
				done_msg.send_done_sig=1;
				done.write(done_msg);
				number_in_buffer=0;
				stage = WAITING_FOR_INSTRUCTIONS;
			}
			else if (number_in_buffer==1)
			{
				//Last flit in buffer, return to buffer wait
				stage = DROPPING_PACKET_BUFFER_WAIT;
				number_in_buffer=0;
			}
			else
			{
				//Decrement buffer and stay here
				number_in_buffer=number_in_buffer-1;
				stage = DROPPING_PACKET_DROPPING_THIS_BURST;
			}
		}
		break;
	case READING_REQ_SEND:
		if (!mem_ar.full())
		{
			//Send a read request at the aligned rounded down address so we can overwrite the end of it
			addr_info.address=address - disalignment;
			addr_info.length=0;
			mem_ar.write(addr_info);
			stage = WAITING_FOR_READ_REPLY;
			address = address - disalignment;
		}
		break;
	case WAITING_FOR_READ_REPLY:
		if (!mem_r.empty())
		{
			//Request is done, record received data as old_data
			rdw=mem_r.read();
			old_data.data = rdw.data;
			if (rdw.dest>1)
			{
				//Indicates error (recall I hacked .dest to be RResp which is 00 or 01 on success, 10 or 11 on failure. Here it failed so ask again
				addr_info.address=address;
				addr_info.length=0;
				mem_ar.write(addr_info);
				stage = WAITING_FOR_READ_REPLY;
			}
			else
			{
				//It succeeded so now go onto passing the packet
				number_in_buffer = 0;
				stage = DISALIGNED_PASSING_PACKET;
				pre_sec_stage=0;
			}
		}
		break;
	case DISALIGNED_PASSING_PACKET:
		if (data_in.empty() && number_in_buffer == 0 && !batch_in.empty() && !mem_aw.full())
		{
			//no data is ready but batch is to send request
			batch_read = batch_in.read();
			addr_info.address=address + offset;
			//Find smaller of space left or batch available and say the burst is that length
			if (space_left < 64 * batch_read - disalignment)
			{
				addr_info.length=(space_left+disalignment)/64-1;
			}
			else
			{
				addr_info.length=batch_read-1;
			}
			//Send address info and in done say we expect a reply.
			mem_aw.write(addr_info);
			done_msg.expect_done_sig=1;
			done_msg.send_done_sig=0;
			done.write(done_msg);
			number_in_buffer = batch_read;
			stage = DISALIGNED_PASSING_PACKET;
		}
		else if (!mem_w.full() && !data_in.empty() && ((number_in_buffer!=0) || (!batch_in.empty() && !mem_aw.full())))
		{
			//data is ready to be sent/received and either there is buffer available or a new batch is ready and AXI is able to receive it.
			data_read = data_in.read();
			if (number_in_buffer == 0)
			{
				//Buffer is done but a batch is ready. Read it, figure out address, and send it.
				number_in_buffer_temp = batch_in.read();
				addr_info.address=address + offset;
				if (space_left < 64 * number_in_buffer_temp - disalignment)
				{
					addr_info.length=(space_left+disalignment)/64-1;
				}
				else
				{
					addr_info.length=number_in_buffer_temp-1;
				}
				mem_aw.write(addr_info);
				done_msg.expect_done_sig=1;
			}
			else
			{
				//This is done since later we use number_in_buffer_temp instead of the register since it can be fed by the AXIS batch in or the register
				number_in_buffer_temp =  number_in_buffer;
				done_msg.expect_done_sig=0;
			}
			if (pre_sec_stage==1)
			{
				done_msg.send_done_sig=1;
			}
			else
			{
				done_msg.send_done_sig=0;
			}
			//Regardless of if its a new batch or an old one, at this point number_in_buffer_temp is a wire with the number of spaces left written on it
			//Combine the old data with the new to form a new flit called temp_data_to_write
			switch(disalignment)
			{
			case 1:
				temp_data_to_write2.range(504,511) = old_data.data.range(0,7);
				temp_data_to_write2.range(0,503)=data_read.data.range(8,511);
				break;
			case 2:
				temp_data_to_write2.range(496,511) = old_data.data.range(0,15);
				temp_data_to_write2.range(0,495)=data_read.data.range(16,511);
				break;
			case 3:
				temp_data_to_write2.range(488,511) = old_data.data.range(0,23);
				temp_data_to_write2.range(0,487)=data_read.data.range(24,511);
				break;
			case 4:
				temp_data_to_write2.range(480,511) = old_data.data.range(0,31);
				temp_data_to_write2.range(0,479)=data_read.data.range(32,511);
				break;
			case 5:
				temp_data_to_write2.range(472,511) = old_data.data.range(0,39);
				temp_data_to_write2.range(0,471)=data_read.data.range(40,511);
				break;
			case 6:
				temp_data_to_write2.range(464,511) = old_data.data.range(0,47);
				temp_data_to_write2.range(0,463)=data_read.data.range(48,511);
				break;
			case 7:
				temp_data_to_write2.range(456,511) = old_data.data.range(0,55);
				temp_data_to_write2.range(0,455)=data_read.data.range(56,511);
				break;
			case 8:
				temp_data_to_write2.range(448,511) = old_data.data.range(0,63);
				temp_data_to_write2.range(0,447)=data_read.data.range(64,511);
				break;
			case 9:
				temp_data_to_write2.range(440,511) = old_data.data.range(0,71);
				temp_data_to_write2.range(0,439)=data_read.data.range(72,511);
				break;
			case 10:
				temp_data_to_write2.range(432,511) = old_data.data.range(0,79);
				temp_data_to_write2.range(0,431)=data_read.data.range(80,511);
				break;
			case 11:
				temp_data_to_write2.range(424,511) = old_data.data.range(0,87);
				temp_data_to_write2.range(0,423)=data_read.data.range(88,511);
				break;
			case 12:
				temp_data_to_write2.range(416,511) = old_data.data.range(0,95);
				temp_data_to_write2.range(0,415)=data_read.data.range(96,511);
				break;
			case 13:
				temp_data_to_write2.range(408,511) = old_data.data.range(0,103);
				temp_data_to_write2.range(0,407)=data_read.data.range(104,511);
				break;
			case 14:
				temp_data_to_write2.range(400,511) = old_data.data.range(0,111);
				temp_data_to_write2.range(0,399)=data_read.data.range(112,511);
				break;
			case 15:
				temp_data_to_write2.range(392,511) = old_data.data.range(0,119);
				temp_data_to_write2.range(0,391)=data_read.data.range(120,511);
				break;
			case 16:
				temp_data_to_write2.range(384,511) = old_data.data.range(0,127);
				temp_data_to_write2.range(0,383)=data_read.data.range(128,511);
				break;
			case 17:
				temp_data_to_write2.range(376,511) = old_data.data.range(0,135);
				temp_data_to_write2.range(0,375)=data_read.data.range(136,511);
				break;
			case 18:
				temp_data_to_write2.range(368,511) = old_data.data.range(0,143);
				temp_data_to_write2.range(0,367)=data_read.data.range(144,511);
				break;
			case 19:
				temp_data_to_write2.range(360,511) = old_data.data.range(0,151);
				temp_data_to_write2.range(0,359)=data_read.data.range(152,511);
				break;
			case 20:
				temp_data_to_write2.range(352,511) = old_data.data.range(0,159);
				temp_data_to_write2.range(0,351)=data_read.data.range(160,511);
				break;
			case 21:
				temp_data_to_write2.range(344,511) = old_data.data.range(0,167);
				temp_data_to_write2.range(0,343)=data_read.data.range(168,511);
				break;
			case 22:
				temp_data_to_write2.range(336,511) = old_data.data.range(0,175);
				temp_data_to_write2.range(0,335)=data_read.data.range(176,511);
				break;
			case 23:
				temp_data_to_write2.range(328,511) = old_data.data.range(0,183);
				temp_data_to_write2.range(0,327)=data_read.data.range(184,511);
				break;
			case 24:
				temp_data_to_write2.range(320,511) = old_data.data.range(0,191);
				temp_data_to_write2.range(0,319)=data_read.data.range(192,511);
				break;
			case 25:
				temp_data_to_write2.range(312,511) = old_data.data.range(0,199);
				temp_data_to_write2.range(0,311)=data_read.data.range(200,511);
				break;
			case 26:
				temp_data_to_write2.range(304,511) = old_data.data.range(0,207);
				temp_data_to_write2.range(0,303)=data_read.data.range(208,511);
				break;
			case 27:
				temp_data_to_write2.range(296,511) = old_data.data.range(0,215);
				temp_data_to_write2.range(0,295)=data_read.data.range(216,511);
				break;
			case 28:
				temp_data_to_write2.range(288,511) = old_data.data.range(0,223);
				temp_data_to_write2.range(0,287)=data_read.data.range(224,511);
				break;
			case 29:
				temp_data_to_write2.range(280,511) = old_data.data.range(0,231);
				temp_data_to_write2.range(0,279)=data_read.data.range(232,511);
				break;
			case 30:
				temp_data_to_write2.range(272,511) = old_data.data.range(0,239);
				temp_data_to_write2.range(0,271)=data_read.data.range(240,511);
				break;
			case 31:
				temp_data_to_write2.range(264,511) = old_data.data.range(0,247);
				temp_data_to_write2.range(0,263)=data_read.data.range(248,511);
				break;
			case 32:
				temp_data_to_write2.range(256,511) = old_data.data.range(0,255);
				temp_data_to_write2.range(0,255)=data_read.data.range(256,511);
				break;
			case 33:
				temp_data_to_write2.range(248,511) = old_data.data.range(0,263);
				temp_data_to_write2.range(0,247)=data_read.data.range(264,511);
				break;
			case 34:
				temp_data_to_write2.range(240,511) = old_data.data.range(0,271);
				temp_data_to_write2.range(0,239)=data_read.data.range(272,511);
				break;
			case 35:
				temp_data_to_write2.range(232,511) = old_data.data.range(0,279);
				temp_data_to_write2.range(0,231)=data_read.data.range(280,511);
				break;
			case 36:
				temp_data_to_write2.range(224,511) = old_data.data.range(0,287);
				temp_data_to_write2.range(0,223)=data_read.data.range(288,511);
				break;
			case 37:
				temp_data_to_write2.range(216,511) = old_data.data.range(0,295);
				temp_data_to_write2.range(0,215)=data_read.data.range(296,511);
				break;
			case 38:
				temp_data_to_write2.range(208,511) = old_data.data.range(0,303);
				temp_data_to_write2.range(0,207)=data_read.data.range(304,511);
				break;
			case 39:
				temp_data_to_write2.range(200,511) = old_data.data.range(0,311);
				temp_data_to_write2.range(0,199)=data_read.data.range(312,511);
				break;
			case 40:
				temp_data_to_write2.range(192,511) = old_data.data.range(0,319);
				temp_data_to_write2.range(0,191)=data_read.data.range(320,511);
				break;
			case 41:
				temp_data_to_write2.range(184,511) = old_data.data.range(0,327);
				temp_data_to_write2.range(0,183)=data_read.data.range(328,511);
				break;
			case 42:
				temp_data_to_write2.range(176,511) = old_data.data.range(0,335);
				temp_data_to_write2.range(0,175)=data_read.data.range(336,511);
				break;
			case 43:
				temp_data_to_write2.range(168,511) = old_data.data.range(0,343);
				temp_data_to_write2.range(0,167)=data_read.data.range(344,511);
				break;
			case 44:
				temp_data_to_write2.range(160,511) = old_data.data.range(0,351);
				temp_data_to_write2.range(0,159)=data_read.data.range(352,511);
				break;
			case 45:
				temp_data_to_write2.range(152,511) = old_data.data.range(0,359);
				temp_data_to_write2.range(0,151)=data_read.data.range(360,511);
				break;
			case 46:
				temp_data_to_write2.range(144,511) = old_data.data.range(0,367);
				temp_data_to_write2.range(0,143)=data_read.data.range(368,511);
				break;
			case 47:
				temp_data_to_write2.range(136,511) = old_data.data.range(0,375);
				temp_data_to_write2.range(0,135)=data_read.data.range(376,511);
				break;
			case 48:
				temp_data_to_write2.range(128,511) = old_data.data.range(0,383);
				temp_data_to_write2.range(0,127)=data_read.data.range(384,511);
				break;
			case 49:
				temp_data_to_write2.range(120,511) = old_data.data.range(0,391);
				temp_data_to_write2.range(0,119)=data_read.data.range(392,511);
				break;
			case 50:
				temp_data_to_write2.range(112,511) = old_data.data.range(0,399);
				temp_data_to_write2.range(0,111)=data_read.data.range(400,511);
				break;
			case 51:
				temp_data_to_write2.range(104,511) = old_data.data.range(0,407);
				temp_data_to_write2.range(0,103)=data_read.data.range(408,511);
				break;
			case 52:
				temp_data_to_write2.range(96,511) = old_data.data.range(0,415);
				temp_data_to_write2.range(0,95)=data_read.data.range(416,511);
				break;
			case 53:
				temp_data_to_write2.range(88,511) = old_data.data.range(0,423);
				temp_data_to_write2.range(0,87)=data_read.data.range(424,511);
				break;
			case 54:
				temp_data_to_write2.range(80,511) = old_data.data.range(0,431);
				temp_data_to_write2.range(0,79)=data_read.data.range(432,511);
				break;
			case 55:
				temp_data_to_write2.range(72,511) = old_data.data.range(0,439);
				temp_data_to_write2.range(0,71)=data_read.data.range(440,511);
				break;
			case 56:
				temp_data_to_write2.range(64,511) = old_data.data.range(0,447);
				temp_data_to_write2.range(0,63)=data_read.data.range(448,511);
				break;
			case 57:
				temp_data_to_write2.range(56,511) = old_data.data.range(0,455);
				temp_data_to_write2.range(0,55)=data_read.data.range(456,511);
				break;
			case 58:
				temp_data_to_write2.range(48,511) = old_data.data.range(0,463);
				temp_data_to_write2.range(0,47)=data_read.data.range(464,511);
				break;
			case 59:
				temp_data_to_write2.range(40,511) = old_data.data.range(0,471);
				temp_data_to_write2.range(0,39)=data_read.data.range(472,511);
				break;
			case 60:
				temp_data_to_write2.range(32,511) = old_data.data.range(0,479);
				temp_data_to_write2.range(0,31)=data_read.data.range(480,511);
				break;
			case 61:
				temp_data_to_write2.range(24,511) = old_data.data.range(0,487);
				temp_data_to_write2.range(0,23)=data_read.data.range(488,511);
				break;
			case 62:
				temp_data_to_write2.range(16,511) = old_data.data.range(0,495);
				temp_data_to_write2.range(0,15)=data_read.data.range(496,511);
				break;
			case 63:
				temp_data_to_write2.range(8,511) = old_data.data.range(0,503);
				temp_data_to_write2.range(0,7)=data_read.data.range(504,511);
				break;
			}
			//Send a endian reversed temp_data_to_write to AXI
			data_to_write.data = reverseEndian512_data(temp_data_to_write2);
			data_to_write.keep=0xffffffffffffffff;
			if (pre_sec_stage==1)
			{
				if (data_read.last == 1)
				{
					stage = WAITING_FOR_INSTRUCTIONS;
					data_to_write.last=1;
				}
				else
				{
					stage = DISALIGNED_SECONDARY_INSTRUCTIONS;
					data_to_write.last=1;
				}
			}
			else if (data_read.last == 1)
			{
				//End of packet, but there may still be data in the buffer that is useful
				stage = DISALIGNED_PRE_WAITING_FOR_INSTRUCTIONS;
				mem_is_informed=0;
				data_to_write.last=1;
			}
			else if (space_left == 128-disalignment)
			{
				pre_sec_stage=1;
				//With the next transfer it will fill, since the next transfer is in old_data we need to send it out and then wait for instructions
				stage = DISALIGNED_PASSING_PACKET;
				pre_sec_stage=1;
				data_to_write.last=0;
			}
			else if (number_in_buffer_temp == 1)
			{
				//This is the end of the batch so mark it as such
				data_to_write.last = 1;
				pre_sec_stage=0;
				stage =DISALIGNED_PASSING_PACKET;
			}
			else
			{
				pre_sec_stage=0;
				//Normal case, not end of patch, and passing continues
				data_to_write.last=0;
				stage = DISALIGNED_PASSING_PACKET;
			}
			//update offset and space left
			if (number_in_buffer==0 || pre_sec_stage==1)
			{
				done.write(done_msg);
			}
			offset = offset + 64;
			space_left = space_left - 64;
			//update number_in_buffer with one less than what was calculated earlier
			number_in_buffer = number_in_buffer_temp -1;
			//Send out the data and record the old data
			mem_w.write(data_to_write);
			old_data = data_read;
		}
		break;
	case DISALIGNED_PRE_WAITING_FOR_INSTRUCTIONS:
		if (old_data.keep.bit(64-disalignment)==0)
		{
			//We came here by error as none of the old data is significant so just throw it out and go to the main stage. Also mark instruction end
			stage = WAITING_FOR_INSTRUCTIONS;
			done_msg.expect_done_sig=0;
			done_msg.send_done_sig=1;
			done.write(done_msg);
		}
		else if(!mem_w.full() && (!mem_aw.full() || mem_is_informed == 1))
		{
			//We can fit the last bit of data and AXI is either aware of this flit comming or able to get more instructions
			addr_info.address=address + offset;
			addr_info.length=0;
			//We will send a done from this mem access
			done_msg.send_done_sig=1;
			//Copy in the old data zeroing out the rest
			data_read.data = 0;
			switch(disalignment)
			{
			case 1:
				temp_data_to_write2.range(504,511) = old_data.data.range(0,7);
				temp_data_to_write2.range(0,503)=data_read.data.range(8,511);
				break;
			case 2:
				temp_data_to_write2.range(496,511) = old_data.data.range(0,15);
				temp_data_to_write2.range(0,495)=data_read.data.range(16,511);
				break;
			case 3:
				temp_data_to_write2.range(488,511) = old_data.data.range(0,23);
				temp_data_to_write2.range(0,487)=data_read.data.range(24,511);
				break;
			case 4:
				temp_data_to_write2.range(480,511) = old_data.data.range(0,31);
				temp_data_to_write2.range(0,479)=data_read.data.range(32,511);
				break;
			case 5:
				temp_data_to_write2.range(472,511) = old_data.data.range(0,39);
				temp_data_to_write2.range(0,471)=data_read.data.range(40,511);
				break;
			case 6:
				temp_data_to_write2.range(464,511) = old_data.data.range(0,47);
				temp_data_to_write2.range(0,463)=data_read.data.range(48,511);
				break;
			case 7:
				temp_data_to_write2.range(456,511) = old_data.data.range(0,55);
				temp_data_to_write2.range(0,455)=data_read.data.range(56,511);
				break;
			case 8:
				temp_data_to_write2.range(448,511) = old_data.data.range(0,63);
				temp_data_to_write2.range(0,447)=data_read.data.range(64,511);
				break;
			case 9:
				temp_data_to_write2.range(440,511) = old_data.data.range(0,71);
				temp_data_to_write2.range(0,439)=data_read.data.range(72,511);
				break;
			case 10:
				temp_data_to_write2.range(432,511) = old_data.data.range(0,79);
				temp_data_to_write2.range(0,431)=data_read.data.range(80,511);
				break;
			case 11:
				temp_data_to_write2.range(424,511) = old_data.data.range(0,87);
				temp_data_to_write2.range(0,423)=data_read.data.range(88,511);
				break;
			case 12:
				temp_data_to_write2.range(416,511) = old_data.data.range(0,95);
				temp_data_to_write2.range(0,415)=data_read.data.range(96,511);
				break;
			case 13:
				temp_data_to_write2.range(408,511) = old_data.data.range(0,103);
				temp_data_to_write2.range(0,407)=data_read.data.range(104,511);
				break;
			case 14:
				temp_data_to_write2.range(400,511) = old_data.data.range(0,111);
				temp_data_to_write2.range(0,399)=data_read.data.range(112,511);
				break;
			case 15:
				temp_data_to_write2.range(392,511) = old_data.data.range(0,119);
				temp_data_to_write2.range(0,391)=data_read.data.range(120,511);
				break;
			case 16:
				temp_data_to_write2.range(384,511) = old_data.data.range(0,127);
				temp_data_to_write2.range(0,383)=data_read.data.range(128,511);
				break;
			case 17:
				temp_data_to_write2.range(376,511) = old_data.data.range(0,135);
				temp_data_to_write2.range(0,375)=data_read.data.range(136,511);
				break;
			case 18:
				temp_data_to_write2.range(368,511) = old_data.data.range(0,143);
				temp_data_to_write2.range(0,367)=data_read.data.range(144,511);
				break;
			case 19:
				temp_data_to_write2.range(360,511) = old_data.data.range(0,151);
				temp_data_to_write2.range(0,359)=data_read.data.range(152,511);
				break;
			case 20:
				temp_data_to_write2.range(352,511) = old_data.data.range(0,159);
				temp_data_to_write2.range(0,351)=data_read.data.range(160,511);
				break;
			case 21:
				temp_data_to_write2.range(344,511) = old_data.data.range(0,167);
				temp_data_to_write2.range(0,343)=data_read.data.range(168,511);
				break;
			case 22:
				temp_data_to_write2.range(336,511) = old_data.data.range(0,175);
				temp_data_to_write2.range(0,335)=data_read.data.range(176,511);
				break;
			case 23:
				temp_data_to_write2.range(328,511) = old_data.data.range(0,183);
				temp_data_to_write2.range(0,327)=data_read.data.range(184,511);
				break;
			case 24:
				temp_data_to_write2.range(320,511) = old_data.data.range(0,191);
				temp_data_to_write2.range(0,319)=data_read.data.range(192,511);
				break;
			case 25:
				temp_data_to_write2.range(312,511) = old_data.data.range(0,199);
				temp_data_to_write2.range(0,311)=data_read.data.range(200,511);
				break;
			case 26:
				temp_data_to_write2.range(304,511) = old_data.data.range(0,207);
				temp_data_to_write2.range(0,303)=data_read.data.range(208,511);
				break;
			case 27:
				temp_data_to_write2.range(296,511) = old_data.data.range(0,215);
				temp_data_to_write2.range(0,295)=data_read.data.range(216,511);
				break;
			case 28:
				temp_data_to_write2.range(288,511) = old_data.data.range(0,223);
				temp_data_to_write2.range(0,287)=data_read.data.range(224,511);
				break;
			case 29:
				temp_data_to_write2.range(280,511) = old_data.data.range(0,231);
				temp_data_to_write2.range(0,279)=data_read.data.range(232,511);
				break;
			case 30:
				temp_data_to_write2.range(272,511) = old_data.data.range(0,239);
				temp_data_to_write2.range(0,271)=data_read.data.range(240,511);
				break;
			case 31:
				temp_data_to_write2.range(264,511) = old_data.data.range(0,247);
				temp_data_to_write2.range(0,263)=data_read.data.range(248,511);
				break;
			case 32:
				temp_data_to_write2.range(256,511) = old_data.data.range(0,255);
				temp_data_to_write2.range(0,255)=data_read.data.range(256,511);
				break;
			case 33:
				temp_data_to_write2.range(248,511) = old_data.data.range(0,263);
				temp_data_to_write2.range(0,247)=data_read.data.range(264,511);
				break;
			case 34:
				temp_data_to_write2.range(240,511) = old_data.data.range(0,271);
				temp_data_to_write2.range(0,239)=data_read.data.range(272,511);
				break;
			case 35:
				temp_data_to_write2.range(232,511) = old_data.data.range(0,279);
				temp_data_to_write2.range(0,231)=data_read.data.range(280,511);
				break;
			case 36:
				temp_data_to_write2.range(224,511) = old_data.data.range(0,287);
				temp_data_to_write2.range(0,223)=data_read.data.range(288,511);
				break;
			case 37:
				temp_data_to_write2.range(216,511) = old_data.data.range(0,295);
				temp_data_to_write2.range(0,215)=data_read.data.range(296,511);
				break;
			case 38:
				temp_data_to_write2.range(208,511) = old_data.data.range(0,303);
				temp_data_to_write2.range(0,207)=data_read.data.range(304,511);
				break;
			case 39:
				temp_data_to_write2.range(200,511) = old_data.data.range(0,311);
				temp_data_to_write2.range(0,199)=data_read.data.range(312,511);
				break;
			case 40:
				temp_data_to_write2.range(192,511) = old_data.data.range(0,319);
				temp_data_to_write2.range(0,191)=data_read.data.range(320,511);
				break;
			case 41:
				temp_data_to_write2.range(184,511) = old_data.data.range(0,327);
				temp_data_to_write2.range(0,183)=data_read.data.range(328,511);
				break;
			case 42:
				temp_data_to_write2.range(176,511) = old_data.data.range(0,335);
				temp_data_to_write2.range(0,175)=data_read.data.range(336,511);
				break;
			case 43:
				temp_data_to_write2.range(168,511) = old_data.data.range(0,343);
				temp_data_to_write2.range(0,167)=data_read.data.range(344,511);
				break;
			case 44:
				temp_data_to_write2.range(160,511) = old_data.data.range(0,351);
				temp_data_to_write2.range(0,159)=data_read.data.range(352,511);
				break;
			case 45:
				temp_data_to_write2.range(152,511) = old_data.data.range(0,359);
				temp_data_to_write2.range(0,151)=data_read.data.range(360,511);
				break;
			case 46:
				temp_data_to_write2.range(144,511) = old_data.data.range(0,367);
				temp_data_to_write2.range(0,143)=data_read.data.range(368,511);
				break;
			case 47:
				temp_data_to_write2.range(136,511) = old_data.data.range(0,375);
				temp_data_to_write2.range(0,135)=data_read.data.range(376,511);
				break;
			case 48:
				temp_data_to_write2.range(128,511) = old_data.data.range(0,383);
				temp_data_to_write2.range(0,127)=data_read.data.range(384,511);
				break;
			case 49:
				temp_data_to_write2.range(120,511) = old_data.data.range(0,391);
				temp_data_to_write2.range(0,119)=data_read.data.range(392,511);
				break;
			case 50:
				temp_data_to_write2.range(112,511) = old_data.data.range(0,399);
				temp_data_to_write2.range(0,111)=data_read.data.range(400,511);
				break;
			case 51:
				temp_data_to_write2.range(104,511) = old_data.data.range(0,407);
				temp_data_to_write2.range(0,103)=data_read.data.range(408,511);
				break;
			case 52:
				temp_data_to_write2.range(96,511) = old_data.data.range(0,415);
				temp_data_to_write2.range(0,95)=data_read.data.range(416,511);
				break;
			case 53:
				temp_data_to_write2.range(88,511) = old_data.data.range(0,423);
				temp_data_to_write2.range(0,87)=data_read.data.range(424,511);
				break;
			case 54:
				temp_data_to_write2.range(80,511) = old_data.data.range(0,431);
				temp_data_to_write2.range(0,79)=data_read.data.range(432,511);
				break;
			case 55:
				temp_data_to_write2.range(72,511) = old_data.data.range(0,439);
				temp_data_to_write2.range(0,71)=data_read.data.range(440,511);
				break;
			case 56:
				temp_data_to_write2.range(64,511) = old_data.data.range(0,447);
				temp_data_to_write2.range(0,63)=data_read.data.range(448,511);
				break;
			case 57:
				temp_data_to_write2.range(56,511) = old_data.data.range(0,455);
				temp_data_to_write2.range(0,55)=data_read.data.range(456,511);
				break;
			case 58:
				temp_data_to_write2.range(48,511) = old_data.data.range(0,463);
				temp_data_to_write2.range(0,47)=data_read.data.range(464,511);
				break;
			case 59:
				temp_data_to_write2.range(40,511) = old_data.data.range(0,471);
				temp_data_to_write2.range(0,39)=data_read.data.range(472,511);
				break;
			case 60:
				temp_data_to_write2.range(32,511) = old_data.data.range(0,479);
				temp_data_to_write2.range(0,31)=data_read.data.range(480,511);
				break;
			case 61:
				temp_data_to_write2.range(24,511) = old_data.data.range(0,487);
				temp_data_to_write2.range(0,23)=data_read.data.range(488,511);
				break;
			case 62:
				temp_data_to_write2.range(16,511) = old_data.data.range(0,495);
				temp_data_to_write2.range(0,15)=data_read.data.range(496,511);
				break;
			case 63:
				temp_data_to_write2.range(8,511) = old_data.data.range(0,503);
				temp_data_to_write2.range(0,7)=data_read.data.range(504,511);
				break;
			}
			//Write out endian corrected data
			data_to_write.data = reverseEndian512_data(temp_data_to_write);
			data_to_write.keep=0xffffffffffffffff;
			data_to_write.last=1;
			mem_w.write(data_to_write);
			if (mem_is_informed==0)
			{
				//Send address info if not done already expecting a reply
				mem_aw.write(addr_info);
				done_msg.expect_done_sig=1;
			}
			else
			{
				//Don't send address info since it was done and the expectation of reply was already sent
				done_msg.expect_done_sig=0;
			}
			//write done signal
			done.write(done_msg);
			//update offset and reset the stage
			offset = offset + 64;
			stage = WAITING_FOR_INSTRUCTIONS;
			//Write out the data and say it is not informed
			mem_is_informed=0;
			//write to memory
		}
		else if (!mem_aw.full() && mem_is_informed==0)
		{
			//We have space to inform even if it is not ready to receive so inform it
			addr_info.address=address + offset;
			addr_info.length=0;
			mem_aw.write(addr_info);
			//Expect a done but don't send it until we have sent the data
			done_msg.expect_done_sig=1;
			done_msg.send_done_sig=0;
			done.write(done_msg);
			//Stay in this stage but record that memory is informed
			mem_is_informed=1;
			stage = DISALIGNED_PRE_WAITING_FOR_INSTRUCTIONS;
		}
		break;
	}
}
