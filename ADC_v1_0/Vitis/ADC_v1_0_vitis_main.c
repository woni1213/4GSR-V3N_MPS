#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"
#include "string.h"

//XPAR_MYIP_V1_0_0_BASEADDR			0x80001000

int main()
{
	int axi_ch;
	int data;
	float raw_data;

	printf("Voltage? Current? (0 : Voltage, 1 : Current)\n");
	scanf("%d", &axi_ch);
	if (axi_ch == 0)
	{
		printf("voltage : \n");
		while(1)
		{
			data = Xil_In32(XPAR_MYIP_V1_0_0_BASEADDR);
			float *p_data = (float*) &data;
			raw_data = *p_data;
			printf("%f\n", raw_data);
			usleep(10000);
		}
	}
	else if (axi_ch == 1)
	{
		printf("current : \n");
		while(1)
		{
			data = Xil_In32(XPAR_MYIP_V1_0_0_BASEADDR + 4);
			float *p_data = (float*) &data;
			raw_data = *p_data;
			printf("%f\n", raw_data);
			usleep(10000);
		}
	}

	return 0;
}

/*
 * data = Xil_In32(XPAR_MAIN_4GSR_DSP_0_BASEADDR + 44);
            float *float_pointer = (float *)&data;
            adc_data = *float_pointer;
            printf("%f\n", adc_data);
 */
