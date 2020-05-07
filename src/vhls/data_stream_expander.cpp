#include "hls_stream.h"
#include "ap_int.h"
#include "ap_utils.h"

struct dataword_ext
{
	ap_uint<512> data;
	ap_uint<64> keep;
	ap_uint<1> last;
};

struct dataword
{
	ap_uint<64> data;
	ap_uint<8> keep;
	ap_uint<1> last;
};

void data_stream_expander(
	hls::stream<dataword> data_in,
	hls::stream<dataword_ext> data_out
)
{
#pragma HLS DATAFLOW

#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS resource core=AXI4Stream variable = data_in
#pragma HLS DATA_PACK variable=data_in

#pragma HLS resource core=AXI4Stream variable = data_out
#pragma HLS DATA_PACK variable=data_out
	static ap_uint<8> stage = 0;
	static dataword_ext ext_inst;
	dataword norm_inst;
	switch (stage)
	{
	case 0:
		if (!data_in.empty())
		{
			norm_inst = data_in.read();
			ext_inst.data.range(511,448)=norm_inst.data;
			ext_inst.data.range(447,0)=0;
			ext_inst.keep.range(63,56)=norm_inst.keep;
			ext_inst.keep.range(55,0)=0;
			if (norm_inst.last==1)
			{
				ext_inst.last=1;
				data_out.write(ext_inst);
				stage = 0;
			}
			else
			{
				stage = 1;
			}
		}
		break;
	case 1:
		if (!data_in.empty())
		{
			norm_inst = data_in.read();
			ext_inst.data.range(447,384)=norm_inst.data;
			ext_inst.keep.range(55,48)=norm_inst.keep;
			if (norm_inst.last==1)
			{
				ext_inst.last=1;
				data_out.write(ext_inst);
				stage = 0;
			}
			else
			{
				stage = 2;
			}
		}
		break;
	case 2:
		if (!data_in.empty())
		{
			norm_inst = data_in.read();
			ext_inst.data.range(383,320)=norm_inst.data;
			ext_inst.keep.range(47,40)=norm_inst.keep;
			if (norm_inst.last==1)
			{
				ext_inst.last=1;
				data_out.write(ext_inst);
				stage = 0;
			}
			else
			{
				stage = 3;
			}
		}
		break;
	case 3:
		if (!data_in.empty())
		{
			norm_inst = data_in.read();
			ext_inst.data.range(319,256)=norm_inst.data;
			ext_inst.keep.range(39,32)=norm_inst.keep;
			if (norm_inst.last==1)
			{
				ext_inst.last=1;
				data_out.write(ext_inst);
				stage = 0;
			}
			else
			{
				stage = 4;
			}
		}
		break;
	case 4:
		if (!data_in.empty())
		{
			norm_inst = data_in.read();
			ext_inst.data.range(255,192)=norm_inst.data;
			ext_inst.keep.range(31,24)=norm_inst.keep;
			if (norm_inst.last==1)
			{
				ext_inst.last=1;
				data_out.write(ext_inst);
				stage = 0;
			}
			else
			{
				stage = 5;
			}
		}
		break;
	case 5:
		if (!data_in.empty())
		{
			norm_inst = data_in.read();
			ext_inst.data.range(191,128)=norm_inst.data;
			ext_inst.keep.range(23,16)=norm_inst.keep;
			if (norm_inst.last==1)
			{
				ext_inst.last=1;
				data_out.write(ext_inst);
				stage = 0;
			}
			else
			{
				stage = 6;
			}
		}
		break;
	case 6:
		if (!data_in.empty())
		{
			norm_inst = data_in.read();
			ext_inst.data.range(127,64)=norm_inst.data;
			ext_inst.keep.range(15,8)=norm_inst.keep;
			if (norm_inst.last==1)
			{
				ext_inst.last=1;
				data_out.write(ext_inst);
				stage = 0;
			}
			else
			{
				stage = 7;
			}
		}
		break;
	case 7:
		if (!data_in.empty())
		{
			norm_inst = data_in.read();
			ext_inst.data.range(63,0)=norm_inst.data;
			ext_inst.keep.range(7,0)=norm_inst.keep;
			ext_inst.last=norm_inst.last;
			data_out.write(ext_inst);
			stage = 0;
		}
		break;
	}
}

