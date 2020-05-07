#include "hls_stream.h"
#include "ap_int.h"
#include "ap_cint.h"
#include "ap_utils.h"

struct dataword
{
	ap_uint<512> data;
	ap_uint<64> keep;
	ap_uint<1> last;
};

void packet_length_counter (
	hls::stream<dataword> data_in,
	hls::stream<dataword> data_out,
	hls::stream<ap_uint<64> > length
)
{
#pragma HLS DATAFLOW
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = data_in
#pragma HLS DATA_PACK variable=data_in

#pragma HLS resource core=AXI4Stream variable = data_out
#pragma HLS DATA_PACK variable=data_out

#pragma HLS resource core=AXI4Stream variable = length

	static ap_uint<64> current_count=0;
	dataword temp_data;
	if (!data_in.empty() && !data_out.full()&& !length.full())
	{
		temp_data = data_in.read();
		data_out.write(temp_data);
		if (temp_data.last==0)
		{
			current_count+=64;
		}
		else
		{
			switch (temp_data.keep)
			{
			case 0x0:
				length.write(current_count);
				break;
			case 0x8000000000000000:
				length.write(current_count+1);
				break;
			case 0xC000000000000000:
				length.write(current_count+2);
				break;
			case 0xE000000000000000:
				length.write(current_count+3);
				break;
			case 0xF000000000000000:
				length.write(current_count+4);
				break;
			case 0xF800000000000000:
				length.write(current_count+5);
				break;
			case 0xFC00000000000000:
				length.write(current_count+6);
				break;
			case 0xFE00000000000000:
				length.write(current_count+7);
				break;
			case 0xFF00000000000000:
				length.write(current_count+8);
				break;
			case 0xFF80000000000000:
				length.write(current_count+9);
				break;
			case 0xFFC0000000000000:
				length.write(current_count+10);
				break;
			case 0xFFE0000000000000:
				length.write(current_count+11);
				break;
			case 0xFFF0000000000000:
				length.write(current_count+12);
				break;
			case 0xFFF8000000000000:
				length.write(current_count+13);
				break;
			case 0xFFFC000000000000:
				length.write(current_count+14);
				break;
			case 0xFFFE000000000000:
				length.write(current_count+15);
				break;
			case 0xFFFF000000000000:
				length.write(current_count+16);
				break;
			case 0xFFFF800000000000:
				length.write(current_count+17);
				break;
			case 0xFFFFC00000000000:
				length.write(current_count+18);
				break;
			case 0xFFFFE00000000000:
				length.write(current_count+19);
				break;
			case 0xFFFFF00000000000:
				length.write(current_count+20);
				break;
			case 0xFFFFF80000000000:
				length.write(current_count+21);
				break;
			case 0xFFFFFC0000000000:
				length.write(current_count+22);
				break;
			case 0xFFFFFE0000000000:
				length.write(current_count+23);
				break;
			case 0xFFFFFF0000000000:
				length.write(current_count+24);
				break;
			case 0xFFFFFF8000000000:
				length.write(current_count+25);
				break;
			case 0xFFFFFFC000000000:
				length.write(current_count+26);
				break;
			case 0xFFFFFFE000000000:
				length.write(current_count+27);
				break;
			case 0xFFFFFFF000000000:
				length.write(current_count+28);
				break;
			case 0xFFFFFFF800000000:
				length.write(current_count+29);
				break;
			case 0xFFFFFFFC00000000:
				length.write(current_count+30);
				break;
			case 0xFFFFFFFE00000000:
				length.write(current_count+31);
				break;
			case 0xFFFFFFFF00000000:
				length.write(current_count+32);
				break;
			case 0xFFFFFFFF80000000:
				length.write(current_count+33);
				break;
			case 0xFFFFFFFFC0000000:
				length.write(current_count+34);
				break;
			case 0xFFFFFFFFE0000000:
				length.write(current_count+35);
				break;
			case 0xFFFFFFFFF0000000:
				length.write(current_count+36);
				break;
			case 0xFFFFFFFFF8000000:
				length.write(current_count+37);
				break;
			case 0xFFFFFFFFFC000000:
				length.write(current_count+38);
				break;
			case 0xFFFFFFFFFE000000:
				length.write(current_count+39);
				break;
			case 0xFFFFFFFFFF000000:
				length.write(current_count+40);
				break;
			case 0xFFFFFFFFFF800000:
				length.write(current_count+41);
				break;
			case 0xFFFFFFFFFFC00000:
				length.write(current_count+42);
				break;
			case 0xFFFFFFFFFFE00000:
				length.write(current_count+43);
				break;
			case 0xFFFFFFFFFFF00000:
				length.write(current_count+44);
				break;
			case 0xFFFFFFFFFFF80000:
				length.write(current_count+45);
				break;
			case 0xFFFFFFFFFFFC0000:
				length.write(current_count+46);
				break;
			case 0xFFFFFFFFFFFE0000:
				length.write(current_count+47);
				break;
			case 0xFFFFFFFFFFFF0000:
				length.write(current_count+48);
				break;
			case 0xFFFFFFFFFFFF8000:
				length.write(current_count+49);
				break;
			case 0xFFFFFFFFFFFFC000:
				length.write(current_count+50);
				break;
			case 0xFFFFFFFFFFFFE000:
				length.write(current_count+51);
				break;
			case 0xFFFFFFFFFFFFF000:
				length.write(current_count+52);
				break;
			case 0xFFFFFFFFFFFFF800:
				length.write(current_count+53);
				break;
			case 0xFFFFFFFFFFFFFC00:
				length.write(current_count+54);
				break;
			case 0xFFFFFFFFFFFFFE00:
				length.write(current_count+55);
				break;
			case 0xFFFFFFFFFFFFFF00:
				length.write(current_count+56);
				break;
			case 0xFFFFFFFFFFFFFF80:
				length.write(current_count+57);
				break;
			case 0xFFFFFFFFFFFFFFC0:
				length.write(current_count+58);
				break;
			case 0xFFFFFFFFFFFFFFE0:
				length.write(current_count+59);
				break;
			case 0xFFFFFFFFFFFFFFF0:
				length.write(current_count+60);
				break;
			case 0xFFFFFFFFFFFFFFF8:
				length.write(current_count+61);
				break;
			case 0xFFFFFFFFFFFFFFFC:
				length.write(current_count+62);
				break;
			case 0xFFFFFFFFFFFFFFFE:
				length.write(current_count+63);
				break;
			case 0xFFFFFFFFFFFFFFFF:
				length.write(current_count+64);
				break;
			}
			current_count=0;
		}
	}
}
