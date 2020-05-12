#include "hls_stream.h"
#include "ap_int.h"
#include "ap_utils.h"

struct metadata
{
	ap_uint<16> port_remote;
	ap_uint<16> port_local;
	ap_uint<32> ip_remote;
};
struct dataword
{
	ap_uint<512> data;
	ap_uint<64> keep;
	ap_uint<1> last;
};

void rx_formatter
(
	hls::stream<metadata> &rx_meta_out,
	hls::stream<dataword> &rx_payload_in,
	hls::stream<dataword> &rx_payload_out,
	metadata rx_meta_in
)
{
#pragma HLS INLINE
	static ap_uint<1> prev_last1 = 1;
	dataword temp_packet;
	if ((!rx_payload_in.empty())&&(!rx_meta_out.full())&&(!rx_payload_out.full()))
	{
		temp_packet=rx_payload_in.read();
		rx_payload_out.write(temp_packet);
		if (prev_last1==1)
		{
			rx_meta_out.write(rx_meta_in);
		}
		prev_last1 = temp_packet.last;
	}
}

void tx_formatter
(
	hls::stream<metadata> &tx_meta_in,
	hls::stream<dataword> &tx_payload_in,
	hls::stream<dataword> &tx_payload_out,
	metadata *tx_meta_out
)
{
#pragma HLS INLINE
	static ap_uint<1> prev_last = 1;
	static metadata held_meta;
	metadata temp_metadata;
	dataword temp_packet;
	if ((prev_last==1) && (!tx_meta_in.empty()) && (!tx_payload_in.empty())&&(!tx_payload_out.full()))
	{
		temp_metadata=tx_meta_in.read();
		held_meta=temp_metadata;
		*tx_meta_out=temp_metadata;
		temp_packet=tx_payload_in.read();
		tx_payload_out.write(temp_packet);
		prev_last=temp_packet.last;
	}
	else if ((prev_last==0) && (!tx_payload_in.empty()) && (!tx_payload_out.full()))
	{
		*tx_meta_out=held_meta;
		temp_packet=tx_payload_in.read();
		tx_payload_out.write(temp_packet);
		prev_last=temp_packet.last;
	}
	else
	{
		*tx_meta_out=held_meta;
	}
}
void stream_meta_to_gulf
(
	hls::stream<metadata> &rx_meta_out,
	hls::stream<dataword> &rx_payload_in,
	hls::stream<dataword> &rx_payload_out,
	metadata rx_meta_in,
	hls::stream<metadata> &tx_meta_in,
	hls::stream<dataword> &tx_payload_in,
	hls::stream<dataword> &tx_payload_out,
	metadata *tx_meta_out
)
{
#pragma HLS INTERFACE ap_none port=tx_meta_out
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS resource core=AXI4Stream variable = rx_meta_out
#pragma HLS DATA_PACK variable=rx_meta_out

#pragma HLS resource core=AXI4Stream variable = tx_meta_in
#pragma HLS DATA_PACK variable=tx_meta_in

#pragma HLS resource core=AXI4Stream variable = rx_payload_in
#pragma HLS DATA_PACK variable=rx_payload_in

#pragma HLS resource core=AXI4Stream variable = rx_payload_out
#pragma HLS DATA_PACK variable=rx_payload_out

#pragma HLS resource core=AXI4Stream variable = tx_payload_in
#pragma HLS DATA_PACK variable=tx_payload_in

#pragma HLS resource core=AXI4Stream variable = tx_payload_out
#pragma HLS DATA_PACK variable=tx_payload_out

	rx_formatter(rx_meta_out,rx_payload_in,rx_payload_out,rx_meta_in);
	tx_formatter(tx_meta_in,tx_payload_in,tx_payload_out,tx_meta_out);

}
