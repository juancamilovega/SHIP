//FEATURES//

//INCLUDES//

#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"

//STAGE NAMES//

#define INITIALIZING				0
#define WAITING_FOR_FLAG			1

#define ACK_2 						2

#define SENDING_DATA_r3				3
#define SENDING_DATA_r4				4
#define INTERMISSION_r3				5
#define INTERMISSION_r4				6
#define RE_STARTING_TRANSMISSION	7

//PARAMETERS//

#define max_packet_size			1344//in bytes

//STRUCTURE DEFINITIONS//

struct non_roce_meta
{
	ap_uint<16> port;
	ap_uint<32> ip;
};

struct dataword
{
	ap_uint<512> data;
	ap_uint<64> keep;
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

#define max_payload_size (max_packet_size-0x40)
#define max_number_of_flits			(max_payload_size/64)
#if max_payload_size%64!=0 || max_payload_size<=64
#error "Parameters Error, max payload size number of bytes must be a multiple of 64 and bigger than 64"
#endif
//MAIN FUNCTION//

void roce_tx_interpreter(

	hls::stream<non_roce_meta>& tx_roce_meta,
	hls::stream<dataword>& tx_roce_data,

	//from read response handler
	hls::stream<dataword>& rdma_read_payload,
	hls::stream<flags>& read_flags,
	hls::stream<aeth>& rdma_read_aeth,
	//from ack handler
	hls::stream<flags>& ack_flags,
	hls::stream<aeth>& acknowledgement,

	ap_uint<16> roce_port,
	ap_uint<1> init,
	ap_uint<4> transport_version,
	ap_uint<16> partition
)
{

	//Declare the port level pragmas
#pragma HLS DATAFLOW

#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = tx_roce_meta
#pragma HLS DATA_PACK variable=tx_roce_meta

#pragma HLS resource core=AXI4Stream variable = tx_roce_data
#pragma HLS DATA_PACK variable=tx_roce_data

#pragma HLS resource core=AXI4Stream variable = rdma_read_payload
#pragma HLS DATA_PACK variable=rdma_read_payload

#pragma HLS resource core=AXI4Stream variable = read_flags
#pragma HLS DATA_PACK variable=read_flags

#pragma HLS resource core=AXI4Stream variable = rdma_read_aeth
#pragma HLS DATA_PACK variable=rdma_read_aeth

#pragma HLS resource core=AXI4Stream variable = ack_flags
#pragma HLS DATA_PACK variable=ack_flags

#pragma HLS resource core=AXI4Stream variable = acknowledgement
#pragma HLS DATA_PACK variable=acknowledgement

#pragma HLS resource variable=transport_version core=AXI4LiteS metadata={-bus_bundle BUS_A}

#pragma HLS resource variable=partition core=AXI4LiteS metadata={-bus_bundle BUS_A}

#pragma HLS resource variable=init core=AXI4LiteS metadata={-bus_bundle BUS_A}

	//Declare registers for dataflow
	static ap_uint<8> stage = INITIALIZING;
	static flags active_read_flags;
	static ap_uint<32> read_amount_to_write = 0;
	static ap_uint<16> old_keep;
	static ap_uint<128> old_data;
	static aeth aeth_read_in;
	static ap_uint<24> current_psn = 0;
	static ap_uint<64> packet_size_count;
	static bool do_not_read=false;
	static bool only_at_sender=false;
	//declare local variables
	aeth aeth_read_in_temp;
	flags quick_flags;
	aeth aeth_in;
	dataword payload_to_write;
	dataword data_in;
	bool clause;
	non_roce_meta meta_to_write;
	//main State Machine
	switch(stage)
	{
	case INITIALIZING:
		if(init==1)
		{
			//Wait for all axi values to come in before starting
			stage = WAITING_FOR_FLAG;
		}
		break;
	case WAITING_FOR_FLAG:

		if (!ack_flags.empty()&&!acknowledgement.empty())
		{
			//reach the ack flags and eth
			aeth_in=acknowledgement.read();
			quick_flags=ack_flags.read();
			//form the packet and metadata
			meta_to_write.ip=quick_flags.ip_addr;
			meta_to_write.port=roce_port;
			payload_to_write.data.range(511,504)=17;
			payload_to_write.data.range(503,503)=quick_flags.solicited_event;
			payload_to_write.data.range(502,502)=quick_flags.mig_req;
			payload_to_write.data.range(501,500)=quick_flags.padding;
			payload_to_write.data.range(499,496)=transport_version;
			payload_to_write.data.range(495,480)=partition;
			payload_to_write.data.range(479,472)=0;
			payload_to_write.data.range(471,448)=quick_flags.dest_qp;
			payload_to_write.data.range(447,447)=quick_flags.ack_req;
			payload_to_write.data.range(446,440)=0;
			payload_to_write.data.range(439,416)=current_psn++;
			payload_to_write.data.range(415,408)=aeth_in.syndrome;
			payload_to_write.data.range(407,384)=aeth_in.MSN;
			payload_to_write.data.range(383,0)=0;
			payload_to_write.keep=0xFFFF000000000000;
			payload_to_write.last=1;
			//send the packet and metadata
			tx_roce_meta.write(meta_to_write);
			tx_roce_data.write(payload_to_write);
			stage=WAITING_FOR_FLAG;
		}
		else if(!read_flags.empty() && !rdma_read_payload.empty())
		{
			//read the flags
			active_read_flags=read_flags.read();
			//Populate the flag and common values of the packet header as well as the metadata packet
			payload_to_write.data.range(503,503)=active_read_flags.solicited_event;
			payload_to_write.data.range(502,502)=active_read_flags.mig_req;
			payload_to_write.data.range(501,500)=active_read_flags.padding;
			payload_to_write.data.range(499,496)=transport_version;
			payload_to_write.data.range(495,480)=partition;
			payload_to_write.data.range(479,472)=0;
			payload_to_write.data.range(471,448)=active_read_flags.dest_qp;
			payload_to_write.data.range(447,447)=active_read_flags.ack_req;
			payload_to_write.data.range(446,440)=0;
			payload_to_write.data.range(439,416)=current_psn++;
			meta_to_write.ip=active_read_flags.ip_addr;
			meta_to_write.port=roce_port;
			//Since we may have 1 packet at sender be split to many packets in network (due to max size) this says the sender packet is an only packet so only one aeth will be sent
			only_at_sender=active_read_flags.first && active_read_flags.last;
			//clause would indicate this is the last packet in the stream
			//Note: because of possible intermission packet max_payload_size = max_packet_size - 64bytes
			clause = ((active_read_flags.last==1)&&((active_read_flags.payload_length)<=max_payload_size));
			if ((active_read_flags.first==1)||clause)
			{
				//need aeth
				if (clause && active_read_flags.first!=1)
				{
					//LAST case
					payload_to_write.data.range(511,504)=15;
				}
				else if (clause)
				{
					//ONLY case
					payload_to_write.data.range(511,504)=16;
				}
				else
				{
					//First case
					payload_to_write.data.range(511,504)=13;
				}
				//read aeth and data
				aeth_read_in=rdma_read_aeth.read();
				data_in=rdma_read_payload.read();
				read_amount_to_write=active_read_flags.payload_length;
				//add aeth information
				payload_to_write.data.range(415,408)=aeth_read_in.syndrome;
				payload_to_write.data.range(407,384)=aeth_read_in.MSN;
				//fill last 48 bytes with start of data
				payload_to_write.data.range(383,0)=data_in.data.range(511,128);
				//store the old data and keep for the next beat
				old_data.range(127,0)=data_in.data.range(127,0);
				old_keep.range(15,0)=data_in.keep.range(15,0);
				//add all 1s to keep of header and append keep from the data sent
				payload_to_write.keep.range(47,0)=data_in.keep(63,16);
				payload_to_write.keep.range(63,48)=0xFFFF;
				packet_size_count = 1;
				if (data_in.last==1&&data_in.keep.range(15,0)==0)
				{
					//Indicates the packet is of 1 flit long and lower 16 bits are not significant, translates to a 1 flit packet total so send it now
					payload_to_write.last=1;
					stage=WAITING_FOR_FLAG;
				}
				else if (data_in.last==1)
				{
					//This is the last packet on the incoming side but it doesn't fit in the area left over by the header
					//do_not_read tells SENDING_DATA_r4 to only send the remainder old data and not to read the incoming port
					payload_to_write.last=0;
					stage=SENDING_DATA_r4;
					do_not_read=true;
				}
				else
				{
					//This is not the last packet, continue
					payload_to_write.last=0;
					stage=SENDING_DATA_r4;
					do_not_read=false;
				}
				tx_roce_data.write(payload_to_write);
				tx_roce_meta.write(meta_to_write);
			}
			else
			{
				//don't need aeth
				//Middle Case
				payload_to_write.data.range(511,504)=14;
				//reset count of packet size
				packet_size_count = 1;
				read_amount_to_write=active_read_flags.payload_length;
				//read the incoming packet
				data_in=rdma_read_payload.read();
				//write the higher 52 bytes alongside the header
				payload_to_write.data.range(415,0)=data_in.data.range(511,96);
				//store the old data values in regs
				old_data.range(95,0)=data_in.data.range(95,0);
				old_keep.range(11,0)=data_in.keep.range(11,0);
				//write all 1s to the header keep, transfer the data keep of the bytes being sent
				payload_to_write.keep.range(51,0)=data_in.keep.range(63,12);
				payload_to_write.keep.range(63,52)=0xFFF;
				if (data_in.last==1&&data_in.keep.range(11,0)==0)
				{
					//Indicates the packet is 1 beat long and fits with the area left over by the header
					payload_to_write.last=1;
					stage=WAITING_FOR_FLAG;
				}
				else if (data_in.last==1)
				{
					//Indicates the packet is 1 beat long but doesn't fit with the area left over
					//do not read tells SENDING_DATA_r3 to not read from the incoming port but instead to just send the remainder of the packet in old data
					payload_to_write.last=0;
					stage=SENDING_DATA_r3;
					do_not_read=true;
				}
				else
				{
					//Indicates the packet is longer than 1 beat and should continue to be transmitted
					payload_to_write.last=0;
					stage=SENDING_DATA_r3;
					do_not_read=false;
				}
				//write the data and metadata
				tx_roce_data.write(payload_to_write);
				tx_roce_meta.write(meta_to_write);
			}

		}
		break;
	case SENDING_DATA_r3:
		if (!rdma_read_payload.empty()||do_not_read)
		{
			//either we are not reading the incoming port or there is data ready
			if (!do_not_read)
			{
				//means we are reading, retreive the data
				data_in=rdma_read_payload.read();
			}
			else
			{
				//we are not reading, pad the data with zeros
				data_in.data=0;
				data_in.keep=0;
				data_in.last=1;
			}
			//write the payload including the saved portion of old_data and old_keep
			payload_to_write.data.range(511,416)=old_data(95,0);
			payload_to_write.data.range(415,0)=data_in.data.range(511,96);
			payload_to_write.keep.range(63,52)=old_keep.range(11,0);
			payload_to_write.keep.range(51,0)=data_in.keep.range(63,12);
			//store the old_data and old_keep for next packet
			old_data.range(95,0)=data_in.data.range(95,0);
			old_keep.range(11,0)=data_in.keep.range(11,0);
			if (do_not_read||(data_in.last==1&&data_in.keep.bit(11)==0))
			{
				//Indicates this was the last packet and no significant data can be found in the remainder
				payload_to_write.last=1;
				stage=WAITING_FOR_FLAG;
				packet_size_count=0;
			}
			else if (data_in.last==1)
			{
				//Indicates this was the last packet but the remainder of old data still has useful info, set do_not_read so that it is sent
				payload_to_write.last=0;
				stage=SENDING_DATA_r3;
				do_not_read=true;
				packet_size_count++;
			}
			else if (packet_size_count>=max_number_of_flits-1)
			{
				//Indicates we are 1 beat away from the maximum number of flits allowed. Go to intermission to send the remaining old data before starting a new packet
				read_amount_to_write=read_amount_to_write-max_payload_size;
				payload_to_write.last=0;
				stage=INTERMISSION_r3;
				packet_size_count=0;
			}
			else
			{
				//The payload continues as usual, increment the size counter
				payload_to_write.last=0;
				stage=SENDING_DATA_r3;
				do_not_read=false;
				packet_size_count++;
			}
			tx_roce_data.write(payload_to_write);
		}
		break;
	case SENDING_DATA_r4:
		//same as SENDING_DATA_r4 but old_data has 16 significant bits instead of 12 (due to the larger header with aeth vs without)
		if (!rdma_read_payload.empty()||do_not_read)
		{
			if (!do_not_read)
			{
				data_in=rdma_read_payload.read();
			}
			else
			{
				data_in.data=0;
				data_in.keep=0;
				data_in.last=1;
			}
			payload_to_write.data.range(511,384)=old_data.range(127,0);
			payload_to_write.data.range(383,0)=data_in.data.range(511,128);
			payload_to_write.keep.range(47,0)=data_in.keep.range(63,16);
			payload_to_write.keep.range(63,48)=old_keep.range(15,0);
			old_data.range(127,0)=data_in.data.range(127,0);
			old_keep.range(15,0)=data_in.keep;
			if (do_not_read||(data_in.last==1&&data_in.keep.bit(15)==0))
			{
				payload_to_write.last=1;
				stage=WAITING_FOR_FLAG;
				packet_size_count=0;
			}
			else if (data_in.last==1)
			{
				payload_to_write.last=0;
				stage=SENDING_DATA_r4;
				do_not_read=true;
				packet_size_count++;
			}
			else if (packet_size_count>=max_number_of_flits-1)
			{
				read_amount_to_write=read_amount_to_write-max_payload_size;
				payload_to_write.last=0;
				stage=INTERMISSION_r4;
				packet_size_count=0;
			}
			else
			{
				payload_to_write.last=0;
				stage=SENDING_DATA_r4;
				do_not_read=false;
				packet_size_count++;
			}
			tx_roce_data.write(payload_to_write);
		}
		break;
	case INTERMISSION_r3:
		//send the remaining 12 bytes of old data before restarting with a new packet
		payload_to_write.data.range(511,416)=old_data(95,0);
		payload_to_write.data.range(415,0)=0;
		payload_to_write.keep.range(63,52)=old_keep.range(11,0);
		payload_to_write.keep.range(51,0)=0;
		payload_to_write.last=1;
		tx_roce_data.write(payload_to_write);
		stage=RE_STARTING_TRANSMISSION;
		break;
	case INTERMISSION_r4:
		//send the remaining 16 bytes of old data before restarting with a new packet
		payload_to_write.data.range(511,384)=old_data.range(127,0);
		payload_to_write.data.range(383,0)=0;
		payload_to_write.keep.range(63,48)=old_keep.range(15,0);
		payload_to_write.keep.range(47,0)=0;
		payload_to_write.last=1;
		tx_roce_data.write(payload_to_write);
		stage=RE_STARTING_TRANSMISSION;
		break;
	case RE_STARTING_TRANSMISSION:
		if (!ack_flags.empty()&&!acknowledgement.empty())
		{
			//check if there are any acks available
			aeth_in=acknowledgement.read();
			quick_flags=ack_flags.read();
			meta_to_write.ip=quick_flags.ip_addr;
			meta_to_write.port=roce_port;
			tx_roce_meta.write(meta_to_write);
			payload_to_write.data.range(511,504)=17;
			payload_to_write.data.range(503,503)=quick_flags.solicited_event;
			payload_to_write.data.range(502,502)=quick_flags.mig_req;
			payload_to_write.data.range(501,500)=quick_flags.padding;
			payload_to_write.data.range(499,496)=transport_version;
			payload_to_write.data.range(495,480)=partition;
			payload_to_write.data.range(479,472)=0;
			payload_to_write.data.range(471,448)=quick_flags.dest_qp;
			payload_to_write.data.range(447,447)=quick_flags.ack_req;
			payload_to_write.data.range(446,440)=0;
			payload_to_write.data.range(439,416)=current_psn++;
			payload_to_write.data.range(415,408)=aeth_in.syndrome;
			payload_to_write.data.range(407,384)=aeth_in.MSN;
			payload_to_write.data.range(406,0)=0;
			payload_to_write.keep=0xFFFF000000000000;
			payload_to_write.last=1;
			tx_roce_data.write(payload_to_write);
			stage=WAITING_FOR_FLAG;
		}
		else if (!rdma_read_payload.empty())
		{
			//resend the header
			payload_to_write.data.range(503,503)=active_read_flags.solicited_event;
			payload_to_write.data.range(502,502)=active_read_flags.mig_req;
			payload_to_write.data.range(501,500)=active_read_flags.padding;
			payload_to_write.data.range(499,496)=transport_version;
			payload_to_write.data.range(495,480)=partition;
			payload_to_write.data.range(479,472)=0;
			payload_to_write.data.range(471,448)=active_read_flags.dest_qp;
			payload_to_write.data.range(447,447)=active_read_flags.ack_req;
			payload_to_write.data.range(446,440)=0;
			payload_to_write.data.range(439,416)=current_psn++;
			meta_to_write.ip=active_read_flags.ip_addr;
			meta_to_write.port=roce_port;
			clause = ((active_read_flags.last==1)&&((read_amount_to_write)<=max_payload_size));
			if (clause)
			{
				if (!only_at_sender)
				{
					//sender will send another aeth, we must read it
					aeth_read_in_temp=rdma_read_aeth.read();
					aeth_read_in=aeth_read_in_temp;
				}
				else
				{
					//sender already sent the only aeth so retreive it from memory
					aeth_read_in_temp=aeth_read_in;
				}
				//it is always a last case since another earlier packet was already sent, can't be first
				payload_to_write.data.range(511,504)=15;
				data_in=rdma_read_payload.read();
				//add aeth to header
				payload_to_write.data.range(415,408)=aeth_read_in_temp.syndrome;
				payload_to_write.data.range(407,384)=aeth_read_in_temp.MSN;
				//send and store the data and keep
				payload_to_write.data.range(383,0)=data_in.data.range(511,128);
				old_data.range(127,0)=data_in.data.range(127,0);
				old_keep.range(15,0)=data_in.keep.range(15,0);
				//add all 1s to the keep of the header portion, append it to the keep of the relevant data bits.
				payload_to_write.keep.range(47,0)=data_in.keep(63,16);
				payload_to_write.keep.range(63,48)=0xFFFF;
				packet_size_count = 1;
				if (data_in.last==1&&data_in.keep.range(15,0)==0)
				{
					//If the rest of the packet fits in this slot, then terminate and go back
					payload_to_write.last=1;
					stage=WAITING_FOR_FLAG;
				}
				else if (data_in.last==1)
				{
					//flag do not read to tell SENDING_DATA to not read but only send the remainder
					payload_to_write.last=0;
					stage=SENDING_DATA_r4;
					do_not_read=true;
				}
				else
				{
					//continue transmitting the packet as is usual
					payload_to_write.last=0;
					stage=SENDING_DATA_r4;
					do_not_read=false;
				}
				tx_roce_data.write(payload_to_write);
				tx_roce_meta.write(meta_to_write);
			}
			else
			{
				//don't need aeth
				//Middle Case
				//same as above but using SENDING_DATA_r3 function instead since the lack of aeth shrinks the old data size.
				payload_to_write.data.range(511,504)=14;
				packet_size_count = 1;
				data_in=rdma_read_payload.read();
				payload_to_write.data.range(415,0)=data_in.data.range(511,96);
				old_data.range(95,0)=data_in.data.range(95,0);
				old_keep.range(11,0)=data_in.keep.range(11,0);
				payload_to_write.keep.range(51,0)=data_in.keep.range(63,12);
				payload_to_write.keep.range(63,52)=0xFFF;
				if (data_in.last==1&&data_in.keep.range(11,0)==0)
				{
					payload_to_write.last=1;
					stage=WAITING_FOR_FLAG;
				}
				else if (data_in.last==1)
				{
					payload_to_write.last=0;
					stage=SENDING_DATA_r3;
					do_not_read=true;
				}
				else
				{
					payload_to_write.last=0;
					stage=SENDING_DATA_r3;
					do_not_read=false;
				}
				tx_roce_data.write(payload_to_write);
				tx_roce_meta.write(meta_to_write);
			}
		}
	}
}
