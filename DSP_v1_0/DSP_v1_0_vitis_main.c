#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"
#include "string.h"

int main()
{
	int mode;
	int i;
	int o_data;
	int i_data;
	int i_reg;
	int i_addr;


	while(1)
	{
		printf("Write? or READ? (0 : WRITE, 1 : READ)\n");
		scanf("%d", &mode);

		if (mode == 0)									                        //AXI_WRITE
		{
			printf("reg_?\n");
			scanf("%d", &i_reg);                                                //8(o_c_factor), 9(o_v_factor), 12(o_Hart_beat o_Ready), 60(o_Write_Index), 61(o_Write_DATA)
			printf("data ?\n");
			scanf("%d", &i_data);
			usleep(1000);

			Xil_Out32(XPAR_DSP_V1_0_TOP_0_BASEADDR + (i_reg * 4), i_data);
			usleep(100000);

			o_data = Xil_In32(XPAR_DSP_V1_0_TOP_0_BASEADDR + (i_reg * 4));
			printf("reg_%d : %d\n", i_reg, o_data);
			usleep(1000);
		}

		else if (mode == 1)								                        //AXI_READ
		{
			for(i = 0; i <= 61; i++)
			{
				o_data = Xil_In32(XPAR_DSP_V1_0_TOP_0_BASEADDR + (i * 4));
				printf("reg_%d : %d\n", i, o_data);
				usleep(10000);
			}
			usleep(10000);
		}
        usleep(10000);
    }
	return 0;
}
