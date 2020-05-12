#include "hls_stream.h"
#include "ap_int.h"
#include "ap_utils.h"
#define AWAITING_PACKET 0
#define PASSING_OTHERS 1
#define PASSING_AETH_READ 2
#define PASSING_NON_AETH_READ 3
struct dataword
{
	ap_uint<512> data;
	ap_uint<64> keep;
	ap_uint<1> last;
};
struct read_data_type
{
	ap_uint<1> first;
	ap_uint<1> last;
	ap_uint<1> solicited;
	ap_uint<1> mig_req;
	ap_uint<1> ack_req;
	ap_uint<2> padding;
	ap_uint<4> transport_version;
	ap_uint<16> partition;
	ap_uint<24> queue;
	ap_uint<8> syndrome;
	ap_uint<24> msn;
	ap_uint<24> psn;

};
struct ack_type
{
	ap_uint<1> solicited;
	ap_uint<1> mig_req;
	ap_uint<1> ack_req;
	ap_uint<2> padding;
	ap_uint<4> transport_version;
	ap_uint<16> partition;
	ap_uint<24> queue;
	ap_uint<8> syndrome;
	ap_uint<24> msn;
	ap_uint<24> psn;
};

struct sw_ack
{
	ap_uint<1> ack1_or_nack0;
	ap_uint<5> reason;
	ap_uint<1> open1_or_close0;
	ap_uint<24> queue;
};

struct metadata
{
	ap_uint<16> id;
	ap_uint<16> dest;
	ap_uint<32> data;
};

void driver_rx
(
	hls::stream<dataword> &data_in,
	hls::stream<metadata> &meta_in,
	hls::stream<dataword> &other_packets_data,
	hls::stream<metadata> &other_packets_meta,
	hls::stream<dataword> &read_packets_data,
	hls::stream<read_data_type> &read_packets_info,
	hls::stream<ack_type> &acknowledgements,
	hls::stream<sw_ack> &sw_acknowledgements,
	ap_uint<16> port_local_sw,
	ap_uint<32> storage_ip_addr,
	ap_uint<16> roce_port_number
)
{
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = data_in
#pragma HLS DATA_PACK variable=data_in

#pragma HLS resource core=AXI4Stream variable = meta_in
#pragma HLS DATA_PACK variable=meta_in

#pragma HLS resource core=AXI4Stream variable = other_packets_data
#pragma HLS DATA_PACK variable=other_packets_data

#pragma HLS resource core=AXI4Stream variable = other_packets_meta
#pragma HLS DATA_PACK variable=other_packets_meta

#pragma HLS resource core=AXI4Stream variable = read_packets_data
#pragma HLS DATA_PACK variable=read_packets_data

#pragma HLS resource core=AXI4Stream variable = read_packets_info
#pragma HLS DATA_PACK variable=read_packets_info

#pragma HLS resource core=AXI4Stream variable = acknowledgements
#pragma HLS DATA_PACK variable=acknowledgements

#pragma HLS resource core=AXI4Stream variable = sw_acknowledgements
#pragma HLS DATA_PACK variable=sw_acknowledgements

	static ap_uint<8> stage = AWAITING_PACKET;
	metadata metainst;
	dataword datainst;
	dataword dataout;
	static ap_uint<416> old_data;
	static ap_uint<52> old_keep;
	static bool do_not_read;
	ack_type ackinst;
	sw_ack sw_ackinst;
	read_data_type rdtinst;
	switch (stage)
	{
	case AWAITING_PACKET:
		if (!data_in.empty() && !meta_in.empty())
		{
			metainst = meta_in.read();
			datainst = data_in.read();
			if ((metainst.data!=storage_ip_addr) || (metainst.dest!=roce_port_number && metainst.dest!=port_local_sw))
			{
				other_packets_data.write(datainst);
				other_packets_meta.write(metainst);
				stage = (datainst.last==1) ? AWAITING_PACKET : PASSING_OTHERS;
			}
			else if (metainst.dest==port_local_sw)
			{
				sw_ackinst.ack1_or_nack0=datainst.data.bit(506);
				sw_ackinst.reason=datainst.data.range(505,501);
				sw_ackinst.open1_or_close0=datainst.data.bit(500);
				sw_ackinst.queue=datainst.data.range(499,472);
				sw_acknowledgements.write(sw_ackinst);
			}
			else if (datainst.data.range(511,504)==17)
			{
				ackinst.solicited=datainst.data.bit(503);
				ackinst.mig_req=datainst.data.bit(502);
				ackinst.padding=datainst.data.range(501,500);
				ackinst.transport_version=datainst.data.range(499,496);
				ackinst.partition=datainst.data.range(495,480);
				ackinst.queue=datainst.data.range(471,448);
				ackinst.ack_req=datainst.data.bit(447);
				ackinst.psn=datainst.data.range(439,416);
				ackinst.syndrome=datainst.data.range(415,408);
				ackinst.msn=datainst.data.range(407,384);
				acknowledgements.write(ackinst);
				stage = AWAITING_PACKET;
			}
			else if (datainst.data.range(511,504)==14)
			{
				rdtinst.first=0;
				rdtinst.last=0;
				rdtinst.solicited=datainst.data.bit(503);
				rdtinst.mig_req=datainst.data.bit(502);
				rdtinst.padding=datainst.data.range(501,500);
				rdtinst.transport_version=datainst.data.range(499,496);
				rdtinst.partition=datainst.data.range(495,480);
				rdtinst.queue=datainst.data.range(471,448);
				rdtinst.ack_req=datainst.data.bit(447);
				rdtinst.psn=datainst.data.range(439,416);
				rdtinst.syndrome=0;
				rdtinst.msn=0;
				old_data.range(415,0)=datainst.data.range(415,0);
				old_keep.range(51,0)=datainst.keep.range(51,0);
				if (datainst.last==1)
				{
					stage = AWAITING_PACKET;
					dataout.data.range(511,96)=datainst.data.range(415,0);
					dataout.data.range(95,0)=0;
					dataout.keep.range(63,12)=datainst.data.range(51,0);
					dataout.keep.range(11,0)=0;
					dataout.last = 1;
					read_packets_data.write(dataout);
				}
				else
				{
					do_not_read=false;
					stage = PASSING_NON_AETH_READ;
				}
				read_packets_info.write(rdtinst);
			}
			else if (datainst.data.range(511,504)==13 || datainst.data.range(511,504)==15 || datainst.data.range(511,504)==16)
			{
				rdtinst.first=(datainst.data.range(511,504)==13 || datainst.data.range(511,504)==16) ? 1 : 0;
				rdtinst.last=(datainst.data.range(511,504)==15 || datainst.data.range(511,504)==16) ? 1 : 0;
				rdtinst.solicited=datainst.data.bit(503);
				rdtinst.mig_req=datainst.data.bit(502);
				rdtinst.padding=datainst.data.range(501,500);
				rdtinst.transport_version=datainst.data.range(499,496);
				rdtinst.partition=datainst.data.range(495,480);
				rdtinst.queue=datainst.data.range(471,448);
				rdtinst.ack_req=datainst.data.bit(447);
				rdtinst.psn=datainst.data.range(439,416);
				rdtinst.syndrome=datainst.data.range(415,408);
				rdtinst.msn=datainst.data.range(407,384);
				old_data.range(383,0)=datainst.data.range(383,0);
				old_keep.range(47,0)=datainst.keep.range(47,0);
				if (datainst.last==1)
				{
					stage = AWAITING_PACKET;
					dataout.data.range(511,128)=datainst.data.range(383,0);
					dataout.data.range(127,0)=0;
					dataout.keep.range(63,16)=datainst.data.range(47,0);
					dataout.keep.range(15,0)=0;
					dataout.last = 1;
					read_packets_data.write(dataout);
				}
				else
				{
					stage = PASSING_AETH_READ;
					do_not_read=false;
				}
				read_packets_info.write(rdtinst);
			}
			else
			{
				other_packets_data.write(datainst);
				other_packets_meta.write(metainst);
				stage = (datainst.last==1) ? AWAITING_PACKET : PASSING_OTHERS;
			}
		}
		break;
	case PASSING_NON_AETH_READ:
		if (!data_in.empty() || do_not_read)
		{
			if (!do_not_read)
			{
				//means we are reading, retreive the data
				datainst=data_in.read();
			}
			else
			{
				//we are not reading, pad the data with zeros
				datainst.data=0;
				datainst.keep=0;
				datainst.last=1;
			}
			dataout.data.range(511,96)=old_data.range(415,0);
			dataout.data.range(95,0)=datainst.data.range(511,416);
			dataout.keep.range(63,12)=old_keep.range(51,0);
			dataout.keep.range(11,0)=datainst.keep.range(63,52);
			old_keep.range(51,0)=datainst.keep.range(51,0);
			old_data.range(415,0)=datainst.data.range(415,0);
			if (do_not_read || (datainst.keep.bit(51)==0 && datainst.last==1))
			{
				dataout.last=1;
				stage = AWAITING_PACKET;
				do_not_read=false;
			}
			else if (datainst.last==1)
			{
				dataout.last = 0;
				stage=PASSING_NON_AETH_READ;
				do_not_read=true;
			}
			else
			{
				dataout.last=0;
				stage=PASSING_NON_AETH_READ;
				do_not_read=false;
			}
			read_packets_data.write(dataout);
		}
		break;
	case PASSING_AETH_READ:
		if (!data_in.empty() || do_not_read)
		{
			if (!do_not_read)
			{
				//means we are reading, retreive the data
				datainst=data_in.read();
			}
			else
			{
				//we are not reading, pad the data with zeros
				datainst.data=0;
				datainst.keep=0;
				datainst.last=1;
			}
			dataout.data.range(511,128)=old_data.range(383,0);
			dataout.data.range(127,0)=datainst.data.range(511,384);
			dataout.keep.range(63,16)=old_keep.range(47,0);
			dataout.keep.range(15,0)=datainst.keep.range(63,48);
			old_keep.range(47,0)=datainst.keep.range(47,0);
			old_data.range(383,0)=datainst.data.range(383,0);
			if (do_not_read || (datainst.keep.bit(47)==0 && datainst.last==1))
			{
				dataout.last=1;
				stage = AWAITING_PACKET;
				do_not_read=false;
			}
			else if (datainst.last==1)
			{
				dataout.last = 0;
				stage=PASSING_AETH_READ;
				do_not_read=true;
			}
			else
			{
				dataout.last=0;
				stage=PASSING_AETH_READ;
				do_not_read=false;
			}
			read_packets_data.write(dataout);
		}
		break;
	case PASSING_OTHERS:
		if (!data_in.empty())
		{
			datainst = data_in.read();
			other_packets_data.write(datainst);
			stage = (datainst.last==1) ? AWAITING_PACKET : PASSING_OTHERS;
		}
	}
}
