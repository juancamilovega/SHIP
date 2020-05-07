#include "hls_stream.h"
#include "ap_int.h"
#include "ap_utils.h"
//#define ROCE_PORT_NUM 4791
#define awaiting_data 0
#define reading_from_roce 1
#define reading_from_non_roce 2

#define awaiting_first 0
#define writing_to_non_roce 1
#define writing_to_roce 2

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

void udp_roce_rx_engine (
	//to network
	hls::stream<ap_uint<648> >& udp_rxData_converged,


	//to roce app

	hls::stream<ap_uint<32> >& rx_roce_meta,//contains the ip only
	hls::stream<dataword_512>& rx_roce_data,

	//to non roce app
	hls::stream<metadata_512>& rx_nonroce_meta,
	hls::stream<dataword_512>& rx_nonroce_data,
	ap_uint<16> ROCE_PORT_NUM
)
{
#pragma HLS DATAFLOW
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = udp_rxData_converged

#pragma HLS resource core=AXI4Stream variable = rx_roce_meta

#pragma HLS resource core=AXI4Stream variable = rx_roce_data
#pragma HLS DATA_PACK variable=rx_roce_data

#pragma HLS resource core=AXI4Stream variable = rx_nonroce_meta
#pragma HLS DATA_PACK variable=rx_nonroce_meta

#pragma HLS resource core=AXI4Stream variable = rx_nonroce_data
#pragma HLS DATA_PACK variable=rx_nonroce_data

	static ap_uint<2> stage = awaiting_first;
	ap_uint<648> incoming_data_unstripped;
	dataword_512 incoming_data;
	metadata_512 metadata_rx_cache;
	if (!udp_rxData_converged.empty())
	{
		incoming_data_unstripped=udp_rxData_converged.read();
		incoming_data.data=incoming_data_unstripped.range(511,0);
		metadata_rx_cache.port_remote=incoming_data_unstripped.range(527,512);
		metadata_rx_cache.port_local=incoming_data_unstripped.range(543,528);
		metadata_rx_cache.ip_remote=incoming_data_unstripped.range(575,544);
		incoming_data.keep=incoming_data_unstripped.range(639,576);
		incoming_data.last=incoming_data_unstripped.range(640,640);
		switch (stage)
		{
		case awaiting_first:
			if (metadata_rx_cache.port_local==ROCE_PORT_NUM)
			{
				rx_roce_meta.write(metadata_rx_cache.ip_remote);
				rx_roce_data.write(incoming_data);
				if (incoming_data.last==1)
				{
					stage = awaiting_first;
				}
				else
				{
					stage = writing_to_roce;
				}
			}
			else
			{
				rx_nonroce_meta.write(metadata_rx_cache);
				rx_nonroce_data.write(incoming_data);
				if (incoming_data.last==1)
				{
					stage = awaiting_first;
				}
				else
				{
					stage = writing_to_non_roce;
				}
			}
			break;
		case writing_to_roce:
			rx_roce_data.write(incoming_data);
			if (incoming_data.last==1)
			{
				stage = awaiting_first;
			}
			else
			{
				stage = writing_to_roce;
			}
			break;
		case writing_to_non_roce:
			rx_nonroce_data.write(incoming_data);
			if (incoming_data.last==1)
			{
				stage = awaiting_first;
			}
			else
			{
				stage = writing_to_non_roce;
			}
			break;
		}
	}
}
