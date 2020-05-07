#include "hls_stream.h"
#include "ap_int.h"
#include "ap_utils.h"
#define ROCE_PORT_NUM 4791
#define awaiting_data 0
#define reading_from_roce 1
#define reading_from_non_roce 2

#define awaiting_first 0
#define writing_to_non_roce 1
#define writing_to_roce 2

ap_uint<16> reverse_endian_16(ap_uint<16> input)
{
	//ap_uint<32> output;
	//output.range(7,0)=input.range(15,8);
	//output.range(15,8)=input.range(7,0);
	//return output;
	return input;
}
ap_uint<32> reverse_endian_32(ap_uint<32> input)
{
	//ap_uint<32> output;
	//output.range(7,0)=input.range(31,24);
	//output.range(15,8)=input.range(23,16);
	//output.range(23,16)=input.range(15,8);
	//output.range(31,24)=input.range(7,0);
	//return output;
	return input;
}

struct connection
{
	ap_uint<16> port;
	ap_uint<32> ip;
};

struct metadata
{
	connection source;
	connection dest;
};

struct metadata_512
{
	ap_uint<16> port_remote;
	ap_uint<16> port_local;
	ap_uint<32> ip_remote;
};
struct dataword_512
{
	ap_uint<512> data;
	ap_uint<64> keep;
	ap_uint<1> last;
};

void udp_roce_tx_engine (
	//to network
	hls::stream<ap_uint<648> >& udp_txData_converged,

	//to roce app

	hls::stream<connection>& tx_roce_meta,
	hls::stream<dataword_512>& tx_roce_data,

	//to non roce app
	hls::stream<metadata_512>& tx_nonroce_meta,
	hls::stream<dataword_512>& tx_nonroce_data
)
{

#pragma HLS DATAFLOW
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = udp_txData_converged

#pragma HLS resource core=AXI4Stream variable = tx_roce_meta
#pragma HLS DATA_PACK variable=tx_roce_meta

#pragma HLS resource core=AXI4Stream variable = tx_roce_data
#pragma HLS DATA_PACK variable=tx_roce_data

#pragma HLS resource core=AXI4Stream variable = tx_nonroce_meta
#pragma HLS DATA_PACK variable=tx_nonroce_meta

#pragma HLS resource core=AXI4Stream variable = tx_nonroce_data
#pragma HLS DATA_PACK variable=tx_nonroce_data

	static ap_uint<2> stage = awaiting_data;
	dataword_512 incoming_data;
	ap_uint<648> outgoing_data;
	metadata_512 metadata_to_send;
	static metadata_512 saved_metadata;
	connection roce_meta_in;
	outgoing_data.range(647,641)=0;
	switch (stage)
	{
	case awaiting_data:
		if (!tx_roce_meta.empty() && !tx_roce_data.empty() && !udp_txData_converged.full())
		{
			roce_meta_in=tx_roce_meta.read();
			metadata_to_send.ip_remote=roce_meta_in.ip;
			metadata_to_send.port_local=ROCE_PORT_NUM;
			metadata_to_send.port_remote=roce_meta_in.port;
			incoming_data=tx_roce_data.read();
			outgoing_data.range(511,0)=incoming_data.data.range(511,0);
			outgoing_data.range(527,512)=reverse_endian_16(roce_meta_in.port);
			outgoing_data.range(543,528)=reverse_endian_16(ROCE_PORT_NUM);
			outgoing_data.range(575,544)=reverse_endian_32(roce_meta_in.ip);
			outgoing_data.range(639,576)=incoming_data.keep;
			outgoing_data.range(640,640)=incoming_data.last.range(0,0);
			udp_txData_converged.write(outgoing_data);
			saved_metadata = metadata_to_send;
			if (incoming_data.last==1)
			{
				stage = awaiting_data;
			}
			else
			{
				stage = reading_from_roce;
			}
		}
		else if (!tx_nonroce_data.empty() && !tx_nonroce_meta.empty() && !udp_txData_converged.full())
		{
			metadata_to_send=tx_nonroce_meta.read();
			incoming_data=tx_nonroce_data.read();
			outgoing_data.range(511,0)=incoming_data.data.range(511,0);
			outgoing_data.range(527,512)=reverse_endian_16(metadata_to_send.port_remote);
			outgoing_data.range(543,528)=reverse_endian_16(metadata_to_send.port_local);
			outgoing_data.range(575,544)=reverse_endian_32(metadata_to_send.ip_remote);
			outgoing_data.range(639,576)=incoming_data.keep;
			outgoing_data.range(640,640)=incoming_data.last.range(0,0);
			udp_txData_converged.write(outgoing_data);
			saved_metadata = metadata_to_send;
		}
		break;
	case reading_from_roce:
		if (!tx_roce_data.empty() && !udp_txData_converged.full())
		{
			incoming_data=tx_roce_data.read();
			outgoing_data.range(511,0)=incoming_data.data.range(511,0);
			outgoing_data.range(527,512)=reverse_endian_16(saved_metadata.port_remote);
			outgoing_data.range(543,528)=reverse_endian_16(saved_metadata.port_local);
			outgoing_data.range(575,544)=reverse_endian_32(saved_metadata.ip_remote);
			outgoing_data.range(639,576)=incoming_data.keep;
			outgoing_data.range(640,640)=incoming_data.last.range(0,0);
			udp_txData_converged.write(outgoing_data);
			if (incoming_data.last==1)
			{
				stage = awaiting_data;
			}
			else
			{
				stage = reading_from_roce;
			}
		}
		break;
	case reading_from_non_roce:
		if (!tx_nonroce_data.empty() && !udp_txData_converged.full())
		{
			incoming_data=tx_nonroce_data.read();
			outgoing_data.range(511,0)=incoming_data.data.range(511,0);
			outgoing_data.range(527,512)=reverse_endian_16(saved_metadata.port_remote);
			outgoing_data.range(543,528)=reverse_endian_16(saved_metadata.port_local);
			outgoing_data.range(575,544)=reverse_endian_32(saved_metadata.ip_remote);
			outgoing_data.range(639,576)=incoming_data.keep;
			outgoing_data.range(640,640)=incoming_data.last.range(0,0);
			udp_txData_converged.write(outgoing_data);
			if (incoming_data.last.range(0,0)==1)
			{
				stage = awaiting_data;
			}
			else
			{
				stage = reading_from_roce;
			}
		}
		break;
	}
}
