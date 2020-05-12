#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"

#define MAX_PACKET_LENGTH 1344
#define MAX_PAYLOAD_LENGTH (MAX_PACKET_LENGTH-0x40)
#define MAX_NUM_OF_BEATS MAX_PAYLOAD_LENGTH/64

#define WAITING_FOR_PARAM 0
#define WRITE_DATA_OFFSET_28 1
#define SENDING_LAST_OF_PACKET_28 2
#define SENDING_NEXT_PACKET 3
#define WRITE_DATA_OFFSET_12 4
#define SENDING_LAST_OF_PACKET_12 5

struct dataword
{
	ap_uint<512> data;
	ap_uint<64> keep;
	ap_uint<1> last;
};

struct parameters
{
	ap_uint<24> dest_qp;//the queue targeted
	ap_uint<24> packet_sequence_number;
	ap_uint<32> password;
	ap_uint<32> length;
};

struct flags
{
	ap_uint<2> conjestion;//bit 0 is forward congestion, 1 is backwards congestion
	ap_uint<16> partition;//The partition that the dest QP is inside of
	ap_uint<1> solicited_event;//indicates the requester wants an acknowledgement when the work is done
	ap_uint<1> mig_req;//indicates migration state (1 => EE context has migrated)
	ap_uint<4> transport_header_version;//version of IBA transport
	ap_uint<1> ack_req;//indicates the requester wants an acknowledgement when the packet is received
};

void write_core
(
	flags roce_flags,
	hls::stream<parameters> param_in,
	hls::stream<dataword> data_to_write,
	hls::stream<dataword> payload_out
)
{
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = param_in
#pragma HLS DATA_PACK variable=param_in

#pragma HLS resource core=AXI4Stream variable = data_to_write
#pragma HLS DATA_PACK variable=data_to_write

#pragma HLS resource core=AXI4Stream variable = payload_out
#pragma HLS DATA_PACK variable=payload_out

	static ap_uint<8> stage = WAITING_FOR_PARAM;
	static ap_uint<8> num_of_reads = 0;
	dataword data_in_temp;
	dataword data_out_temp;
	static bool do_not_read = false;
	static parameters param_perm;
	static ap_uint<224> old_data=0;
	static ap_uint<28> old_keep=0;
	parameters param;
	switch (stage)
	{
	case WAITING_FOR_PARAM:
		if (!param_in.empty() && !data_to_write.empty() && !payload_out.full())
		{
			param = param_in.read();
			data_in_temp=data_to_write.read();
			num_of_reads = 2;
			if (param.length < MAX_PAYLOAD_LENGTH)
			{
				data_out_temp.data.range(511,504) = 10;
			}
			else
			{
				data_out_temp.data.range(511,504) = 6;
			}
			data_out_temp.data.bit(503)= roce_flags.solicited_event;
			data_out_temp.data.bit(502)= roce_flags.mig_req;
			data_out_temp.data.range(501,500)=0;
			data_out_temp.data.range(499,496)=roce_flags.transport_header_version;
			data_out_temp.data.range(495,480)=roce_flags.partition;
			data_out_temp.data.range(479,478)=roce_flags.conjestion;
			data_out_temp.data.range(477,472)=0;
			data_out_temp.data.range(471,448)=param.dest_qp;
			data_out_temp.data.bit(447)=roce_flags.ack_req;
			data_out_temp.data.range(446,440)=0;
			data_out_temp.data.range(439,416)=param.packet_sequence_number;
			data_out_temp.data.range(415,352)=0;
			data_out_temp.data.range(351,320)=param.password;
			data_out_temp.data.range(319,288)=param.length;
			data_out_temp.data.range(287,0)=data_in_temp.data.range(511,224);
			old_data.range(223,0)= data_in_temp.data.range(223,0);
			old_keep.range(27,0)= data_in_temp.keep.range(27,0);
			data_out_temp.keep.range(63,36) = 0xfffffff;
			data_out_temp.keep.range(35,0) = data_in_temp.keep.range(63,28);
			if ((data_in_temp.last==1) && (data_in_temp.keep.range(27,0)==0))
			{
				data_out_temp.last = 1;
				stage = WAITING_FOR_PARAM;
			}
			else if ((data_in_temp.last==1))
			{
				data_out_temp.last = 0;
				do_not_read=true;
				stage = WRITE_DATA_OFFSET_28;
			}
			else
			{
				data_out_temp.last=0;
				do_not_read=false;
				stage = WRITE_DATA_OFFSET_28;
			}
			payload_out.write(data_out_temp);
			param_perm = param;
		}
		break;
	case WRITE_DATA_OFFSET_28:
		if ((!data_to_write.empty() || do_not_read) && !payload_out.full())
		{
			if (do_not_read)
			{
				data_in_temp.data = 0;
				data_in_temp.keep = 0;
				data_in_temp.last = 1;
			}
			else
			{
				data_in_temp=data_to_write.read();
			}
			param_perm.length = param_perm.length - 64;
			data_out_temp.data.range(511,288)=old_data.range(223,0);
			data_out_temp.data.range(287,0)=data_in_temp.data.range(511,224);
			data_out_temp.keep.range(63,36)=old_keep.range(27,0);
			data_out_temp.keep.range(35,0)=data_in_temp.keep.range(63,28);
			if ((do_not_read)||((data_in_temp.last==1) && (data_in_temp.keep.bit(27)==0)))
			{
				data_out_temp.last = 1;
				stage = WAITING_FOR_PARAM;
			}
			else if ((data_in_temp.last==1))
			{
				data_out_temp.last = 0;
				do_not_read=true;
				stage = WRITE_DATA_OFFSET_28;
			}
			else if (num_of_reads>=MAX_NUM_OF_BEATS)
			{
				data_out_temp.last = 0;
				stage = SENDING_LAST_OF_PACKET_28;
			}
			else
			{
				data_out_temp.last = 0;
				do_not_read = false;
				stage = WRITE_DATA_OFFSET_28;
			}
			old_keep.range(27,0)=data_in_temp.keep.range(27,0);
			old_data.range(223,0)=data_in_temp.data.range(223,0);
			payload_out.write(data_out_temp);
			num_of_reads++;
		}
		break;
	case SENDING_LAST_OF_PACKET_28:
		if (!payload_out.full())
		{
			param_perm.length = param_perm.length - 64;
			data_out_temp.data.range(511,288)=old_data.range(223,0);
			data_out_temp.data.range(287,0)=0;
			data_out_temp.keep.range(63,36)=old_keep.range(27,0);
			data_out_temp.keep.range(35,0)=0;
			data_out_temp.last = 1;
			stage = SENDING_NEXT_PACKET;
			payload_out.write(data_out_temp);
		}
		break;
	case SENDING_NEXT_PACKET:
		if (!data_to_write.empty() && !payload_out.full())
		{
			//param = param_perm;
			data_in_temp=data_to_write.read();
			num_of_reads = 2;
			data_out_temp.data.bit(503)= roce_flags.solicited_event;
			data_out_temp.data.bit(502)= roce_flags.mig_req;
			data_out_temp.data.range(501,500)=0;
			data_out_temp.data.range(499,496)=roce_flags.transport_header_version;
			data_out_temp.data.range(495,480)=roce_flags.partition;
			data_out_temp.data.range(479,478)=roce_flags.conjestion;
			data_out_temp.data.range(477,472)=0;
			data_out_temp.data.range(471,448)=param_perm.dest_qp;
			data_out_temp.data.bit(447)=roce_flags.ack_req;
			data_out_temp.data.range(446,440)=0;
			data_out_temp.data.range(439,416)=param_perm.packet_sequence_number;
			data_out_temp.data.range(415,0)=data_in_temp.data.range(511,96);
			old_data.range(95,0)= data_in_temp.data.range(95,0);
			old_keep.range(11,0)= data_in_temp.keep.range(11,0);
			data_out_temp.keep.range(63,52) = 0xfff;
			data_out_temp.keep.range(51,0) = data_in_temp.keep.range(63,12);
			if (param_perm.length < MAX_PAYLOAD_LENGTH)
			{
				data_out_temp.data.range(511,504) = 8;
			}
			else
			{
				data_out_temp.data.range(511,504) = 7;
			}
			if ((data_in_temp.last==1) && (data_in_temp.keep.bit(11)==0))
			{
				data_out_temp.last = 1;
				stage = WAITING_FOR_PARAM;
			}
			else if ((data_in_temp.last==1))
			{
				data_out_temp.last = 0;
				do_not_read=true;
				stage = WRITE_DATA_OFFSET_12;
			}
			else
			{
				data_out_temp.last=0;
				do_not_read=false;
				stage = WRITE_DATA_OFFSET_12;
			}
			payload_out.write(data_out_temp);
		}
		break;
	case WRITE_DATA_OFFSET_12:
		if ((!data_to_write.empty() || do_not_read) && !payload_out.full())
		{
			param_perm.length = param_perm.length - 64;
			if (do_not_read)
			{
				data_in_temp.data = 0;
				data_in_temp.keep = 0;
				data_in_temp.last = 1;
			}
			else
			{
				data_in_temp=data_to_write.read();
			}
			data_out_temp.data.range(511,416)=old_data.range(95,0);
			data_out_temp.data.range(415,0)=data_in_temp.data.range(511,96);
			data_out_temp.keep.range(63,52)=old_keep.range(11,0);
			data_out_temp.keep.range(51,0)=data_in_temp.keep.range(63,12);
			if ((do_not_read)||((data_in_temp.last==1) && (data_in_temp.keep.range(11,0)==0)))
			{
				data_out_temp.last = 1;
				stage = WAITING_FOR_PARAM;
			}
			else if ((data_in_temp.last==1))
			{
				data_out_temp.last = 0;
				do_not_read=true;
				stage = WRITE_DATA_OFFSET_12;
			}
			else if (num_of_reads>=MAX_NUM_OF_BEATS)
			{
				data_out_temp.last = 0;
				stage = SENDING_LAST_OF_PACKET_12;
			}
			else
			{
				data_out_temp.last = 0;
				do_not_read = false;
				stage = WRITE_DATA_OFFSET_12;
			}
			old_keep.range(11,0)=data_in_temp.keep.range(11,0);
			old_data.range(95,0)=data_in_temp.data.range(95,0);
			payload_out.write(data_out_temp);
			num_of_reads++;
		}
		break;
	case SENDING_LAST_OF_PACKET_12:
		if (!payload_out.full())
		{
			param_perm.length = param_perm.length - 64;
			data_out_temp.data.range(511,416)=old_data.range(95,0);
			data_out_temp.data.range(415,0)=0;
			data_out_temp.keep.range(63,52)=old_keep.range(11,0);
			data_out_temp.keep.range(51,0)=0;
			data_out_temp.last = 1;
			stage = SENDING_NEXT_PACKET;
			payload_out.write(data_out_temp);
		}
		break;
	}
}
