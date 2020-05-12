#include "hls_stream.h"
#include "ap_int.h"
#include "ap_utils.h"

#define AWAITING_PACKET 0
#define WC_CONTINUED 1
#define OTHER_CONTINUED 2
#define OCH_1 3
#define OCH_2 4

struct dataword
{
	ap_uint<512> data;
	ap_uint<64> keep;
	ap_uint<1> last;
};

struct metadata
{
	ap_uint<16> dest;
	ap_uint<16> id;
	ap_uint<32> data;
};

struct instructions
{
	ap_uint<32> password;
	ap_uint<2> read_or_write;
	ap_uint<1> open1_or_close0;
};

struct param_type
{
	ap_uint<24> dest_qp;
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

struct seek
{
	ap_uint<32> password;
	ap_uint<64> new_index;
	ap_uint<64> queue;
};

void driver_tx
(
	hls::stream<param_type> &param_in,
	hls::stream<dataword> &file_name_in,
	hls::stream<instructions> &open_close_instructions,
	hls::stream<seek> &seek_info_in,
	hls::stream<dataword> &write_core,
	hls::stream<dataword> &payload_out,
	hls::stream<metadata> &meta_out,
	hls::stream<dataword> &other_packets_in,
	hls::stream<metadata> &other_packets_meta_in,
	ap_uint<32> storage_device_ip,
	ap_uint<16> storage_device_port_roce,
	ap_uint<16> storage_device_port_sw,
	ap_uint<16> port_local_roce,
	ap_uint<16> port_local_sw,
	flags roce_flags
)
{
#pragma HLS DATAFLOW
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = open_close_instructions
#pragma HLS DATA_PACK variable=open_close_instructions

#pragma HLS resource core=AXI4Stream variable = file_name_in
#pragma HLS DATA_PACK variable=file_name_in

#pragma HLS resource core=AXI4Stream variable = other_packets_in
#pragma HLS DATA_PACK variable=other_packets_in

#pragma HLS resource core=AXI4Stream variable = other_packets_meta_in
#pragma HLS DATA_PACK variable=other_packets_meta_in

#pragma HLS resource core=AXI4Stream variable = param_in
#pragma HLS DATA_PACK variable=param_in

#pragma HLS resource core=AXI4Stream variable = seek_info_in
#pragma HLS DATA_PACK variable=seek_info_in

#pragma HLS resource core=AXI4Stream variable = write_core
#pragma HLS DATA_PACK variable=write_core

#pragma HLS resource core=AXI4Stream variable = payload_out
#pragma HLS DATA_PACK variable=payload_out

#pragma HLS resource core=AXI4Stream variable = meta_out
#pragma HLS DATA_PACK variable=meta_out
	static ap_uint <64> old_data=0;
	static ap_uint <8> old_keep=0;
	static ap_uint<8> stage = AWAITING_PACKET;
	dataword temp_data_in;
	dataword temp_data_out;
	ap_uint<4> op_code;
	instructions inst_temp;
	dataword data_lrg;
	metadata meta_temp;
	meta_temp.data=storage_device_ip;
	param_type param_inst;
	seek seek_temp;
	switch(stage)
	{
	case AWAITING_PACKET:
		if (!payload_out.full() && !meta_out.full() && !seek_info_in.empty())
		{
			seek_temp=seek_info_in.read();
			meta_temp.id=port_local_sw;
			meta_temp.dest=storage_device_port_sw;
			data_lrg.data.range(511,508)=4;
			data_lrg.data.range(507,480)=0;
			data_lrg.data.range(479,448)=seek_temp.password;
			data_lrg.data.range(447,384)=seek_temp.queue;
			data_lrg.data.range(383,320)=seek_temp.new_index;
			data_lrg.data.range(319,0)=0;
			data_lrg.keep=0xffffff0000000000;
			data_lrg.last=1;
			payload_out.write(data_lrg);
			meta_out.write(meta_temp);
			stage=AWAITING_PACKET;
		}
		else if (!payload_out.full() && !meta_out.full() && !param_in.empty())
		{
			param_inst = param_in.read();
			data_lrg.data.range(511,504) = 12;
			data_lrg.data.bit(503)= roce_flags.solicited_event;
			data_lrg.data.bit(502)= roce_flags.mig_req;
			data_lrg.data.range(501,500)=0;
			data_lrg.data.range(499,496)=roce_flags.transport_header_version;
			data_lrg.data.range(495,480)=roce_flags.partition;
			data_lrg.data.range(479,478)=roce_flags.conjestion;
			data_lrg.data.range(477,472)=0;
			data_lrg.data.range(471,448)=param_inst.dest_qp;
			data_lrg.data.bit(447)=roce_flags.ack_req;
			data_lrg.data.range(446,440)=0;
			data_lrg.data.range(439,416)=param_inst.packet_sequence_number;
			data_lrg.data.range(415,352)=0;
			data_lrg.data.range(351,320)=param_inst.password;
			data_lrg.data.range(319,288)=param_inst.length;
			data_lrg.data.range(287,0)=0;
			data_lrg.keep=0xfffffff000000000;
			data_lrg.last=1;
			payload_out.write(data_lrg);
			meta_temp.id=port_local_roce;
			meta_temp.dest=storage_device_port_roce;
			meta_out.write(meta_temp);
			stage = AWAITING_PACKET;
		}
		else if (!payload_out.full() && !meta_out.full() && !write_core.empty())
		{
			meta_temp.id=port_local_roce;
			meta_temp.dest=storage_device_port_roce;
			data_lrg=write_core.read();
			payload_out.write(data_lrg);
			meta_out.write(meta_temp);
			stage = data_lrg.last==1 ? AWAITING_PACKET : WC_CONTINUED;
		}
		else if (!payload_out.full() && !meta_out.full() && !other_packets_in.empty() && !other_packets_meta_in.empty())
		{
			temp_data_in=other_packets_in.read();
			payload_out.write(temp_data_in);
			meta_out.write(other_packets_meta_in.read());
			stage = (temp_data_in.last==1) ? AWAITING_PACKET : OTHER_CONTINUED;
		}
		else if (!open_close_instructions.empty())
		{
			inst_temp=open_close_instructions.read();
			temp_data_in=file_name_in.read();
			meta_temp.id=port_local_sw;
			meta_temp.dest=storage_device_port_sw;

			if (inst_temp.open1_or_close0==1)
			{
				switch(inst_temp.read_or_write)
				{
				//01 = read, 10 = write, 11=read and write
				case 2:
					op_code = 1;
					break;
				case 1:
					op_code = 3;
					break;
				case 3:
					op_code = 5;
					break;
				}
				temp_data_out.data.range(511,508)=op_code;
				temp_data_out.data.range(507,480)=0;
				temp_data_out.data.range(479,448)=inst_temp.password;
				temp_data_out.data.range(447,0)=temp_data_in.data.range(511,64);
				temp_data_out.keep.range(63,56)=0xff;
				temp_data_out.keep.range(55,0)=temp_data_in.keep.range(63,8);
				old_data=temp_data_in.data.range(63,0);
				old_keep=temp_data_in.keep.range(7,0);
				if ((temp_data_in.last==1) && (temp_data_in.keep.range(7,0)==0))
				{
					stage = AWAITING_PACKET;
					temp_data_out.last = 1;
				}
				else if (temp_data_in.last==1)
				{
					stage = OCH_1;
					temp_data_out.last = 0;
				}
				else
				{
					stage = OCH_2;
					temp_data_out.last = 0;
				}
				payload_out.write(temp_data_out);
			}
			else
			{
				data_lrg.data.range(511,508)=4;
				data_lrg.data.range(507,480)=0;
				data_lrg.data.range(479,448)=inst_temp.password;
				data_lrg.data.range(447,384)=temp_data_in.data.range(63,0);
				data_lrg.data.range(383,0)=0;
				data_lrg.keep=0xffff000000000000;
				data_lrg.last=1;
				payload_out.write(data_lrg);
			}
			meta_out.write(meta_temp);
		}
		break;
	case OCH_1:
		temp_data_out.data.range(511,448)=old_data;
		temp_data_out.data.range(447,0)=0;
		temp_data_out.keep.range(63,56)=old_keep;
		temp_data_out.keep.range(55,0)=0;
		temp_data_out.last = 1;
		payload_out.write(temp_data_out);
		stage = AWAITING_PACKET;
		break;
	case OCH_2:
		if (!file_name_in.empty())
		{
			temp_data_in=file_name_in.read();
			temp_data_out.data.range(511,448)=old_data;
			temp_data_out.data.range(447,0)=temp_data_in.data.range(511,64);
			temp_data_out.keep.range(63,56)=old_keep;
			temp_data_out.keep.range(55,0)=temp_data_in.keep.range(63,8);
			old_data=temp_data_in.data.range(63,0);
			old_keep=temp_data_in.keep.range(7,0);
			if ((temp_data_in.last==1) && (temp_data_in.keep.range(7,0)==0))
			{
				stage = AWAITING_PACKET;
				temp_data_out.last = 1;
			}
			else if (temp_data_in.last==1)
			{
				stage = OCH_1;
				temp_data_out.last = 0;
			}
			else
			{
				stage = OCH_2;
				temp_data_out.last = 0;
			}
			payload_out.write(temp_data_out);
		}
		break;
	case OTHER_CONTINUED:
		if (!payload_out.full() && !other_packets_in.empty())
		{
			data_lrg=other_packets_in.read();
			payload_out.write(data_lrg);
			stage = (data_lrg.last==1) ? AWAITING_PACKET : OTHER_CONTINUED;
		}
		break;
	case WC_CONTINUED:
		if (!payload_out.full() && !write_core.empty())
		{
			data_lrg=write_core.read();
			payload_out.write(data_lrg);
			stage = (data_lrg.last==1) ? AWAITING_PACKET : WC_CONTINUED;
		}
		break;
	}
}
