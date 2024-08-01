#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"
#include "string.h"

int main()
{
	int mode;

	//raw_data_read
	int v_data;
	int c_data;

	//init test
	int init_data;

	//interlock_test
	int o_init_state;
	int interlock_data;
	int mps_polarity;
	int OC_p;
	int OC_n;
	int OV_p;
	int OV_n;
	int UV;
	int SP;

	//floating_test
	float raw_data;

	//OSC
	int OSC_mode;
	int c_min;
	int c_max;
	int v_min;
	int v_max;
	int c_adc_threshold;
	int v_adc_threshold;
	int c_adc_threshold_count;
	int v_adc_threshold_count;
	int OSC_state;
	int OSC_state_IDLE;
	int rst;

	//REGU
	int REGU_mode;
	int c_REGU_abs;
	int v_REGU_abs;
	int c_diff;
	int v_diff;
	int c_set;
	int v_set;
	int c_delay;
	int v_delay;
	int REGU_state;

	while(1)
	{
		printf("0 : v_raw_data, 1 : c_raw_data, 2 : init_custom, 3: interlock_set, 4 : interlock_costom\n 5 : Floating_c, 6 : Floating_c, 7 : OSC_mode 8 : REGU_mode\n");
		scanf("%d", &mode);
		usleep(1000);

		Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 8)), 9);									//eeprom_rst, ~en_dsp_buf_ctrl, sys_rst, en_dsp_boot 1001
		usleep(1000);

		if(mode == 0)																				//v_raw_data
		{
			printf("v_raw_data :\n");
			while(1)
			{
				v_data = Xil_In32(XPAR_ADC_RAW_V3N_ADC_V1_0_TOP_0_BASEADDR + (4 * 11));
				printf("%d\n", v_data);
				usleep(100000);
			}
		}

		else if(mode == 1)																			//c_raw_data
		{
			while(1)
			{
				printf("c_raw_data :\n");
				c_data = Xil_In32(XPAR_ADC_RAW_V3N_ADC_V1_0_TOP_0_BASEADDR + (4 * 12));
				printf(" %d\n", c_data);
				usleep(100000);
			}
		}

		else if(mode == 2)																			//init_custom
		{
			printf("init set eeprom_rst, en_dsp_buf_ctrl, sys_rst, en_dsp_boot?\n");
			scanf("%d", &init_data);
			usleep(1000);
			while (init_data != 100)
			{
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 8)), init_data);
				usleep(100000);
				printf("init set eeprom_rst, en_dsp_buf_ctrl, sys_rst, en_dsp_boot?\n");
				scanf("%d", &init_data);
				usleep(1000);
			}
			return 0;
		}

		else if(mode == 3)																			//interlock_set
		{
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 1)), 768);								//Interlock Data에  삽입
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 7)), 0);								//o_mps_polarity
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 2)), 0);								//intl_OC_p
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 5)), 0);								//intl_OC_n
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 3)), 0);								//intl_OV_p
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 6)), 0);								//intl_OV_n
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 4)), 0);								//intl_UV
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 10)), 0);								//SP1006, o_SP1005, o_SP601
			usleep(10000);

			o_init_state = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR);
			printf("o_init_state : %d\n", o_init_state);

		}

		else if(mode == 4)																			//interlock_costom
		{
			printf("interlock_data?\n");
			scanf("%d", &interlock_data);
			usleep(1000);
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 1)), interlock_data);

			printf("mps_polarity?\n");
			scanf("%d", &mps_polarity);
			usleep(1000);
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 7)), mps_polarity);						//o_mps_polarity

			printf("OC_p?\n");
			scanf("%d", &OC_p);
			usleep(1000);
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 2)), OC_p);								//intl_OC_p

			printf("OV_p?\n");
			scanf("%d", &OV_p);
			usleep(1000);
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 3)), OV_p);								//intl_OV_p

			printf("OC_n?\n");
			scanf("%d", &OC_n);
			usleep(1000);
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 5)), OC_n);								//intl_OC_n

			printf("OV_n?\n");
			scanf("%d", &OV_n);
			usleep(1000);
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 6)), OV_n);								//intl_OV_n

			printf("UV?\n");
			scanf("%d", &UV);
			usleep(1000);
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 4)), UV);								//intl_UV

			printf("SP1006, o_SP1005, o_SP601?\n");
			scanf("%d", &SP);
			usleep(1000);
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 10)), SP);								//SP1006, o_SP1005, o_SP601
			usleep(10000);

			o_init_state = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR);
			printf("o_init_state : %d\n", o_init_state);
			usleep(10000);
		}

		else if(mode == 5)																			//Floating_c
		{
			Xil_Out32((XPAR_DSP_XINTF_DSP_V1_0_TOP_0_BASEADDR + (4 * 8)), 0x3da74081);				//o_c_factor_axis_tdata 32'h3da74081 0.081666
			Xil_Out32((XPAR_DSP_XINTF_DSP_V1_0_TOP_0_BASEADDR + (4 * 9)), 0x4244f77b);				//o_v_factor_axis_tdata 32'h34244f77b 49.2417
			usleep(10000);

			printf("Floating_c :\n");
			while(1)
			{
				c_data = Xil_In32(XPAR_DSP_XINTF_DSP_V1_0_TOP_0_BASEADDR + (4 * 10));
				float *p_data = (float*) &c_data;
				raw_data = *p_data;
				printf("%f\n", raw_data);
				usleep(100000);
			}
		}

		else if(mode == 6)																			//Floating_v
		{
			Xil_Out32((XPAR_DSP_XINTF_DSP_V1_0_TOP_0_BASEADDR + (4 * 8)), 0x3da74081);				//o_c_factor_axis_tdata 32'h3da74081 0.081666
			Xil_Out32((XPAR_DSP_XINTF_DSP_V1_0_TOP_0_BASEADDR + (4 * 9)), 0x4244f77b);				//o_v_factor_axis_tdata 32'h4244f77b 49.2417
			usleep(10000);

			printf("Floating_v :\n");
			while(1)
			{
				v_data = Xil_In32(XPAR_DSP_XINTF_DSP_V1_0_TOP_0_BASEADDR + (4 * 11));
				float *p_data = (float*) &v_data;
				raw_data = *p_data;
				printf("%f\n", raw_data);
				usleep(100000);
			}
		}

		else if(mode == 7)																			//OSC_mode
		{
			printf("0 : c_min c_max, 1 : v_min v_max, 2 : c_OSC, 3 : v_OSC, 4 : OSC_state\n");
			scanf("%d", &OSC_mode);
			usleep(1000);

			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 17)), 2000);							//OSC_period
			usleep(10000);

			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 18)), 1000);							//OSC_cycle
			usleep(10000);

			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 13)), 0xFFFFFFFF);						//c_adc_threshold
			usleep(10000);

			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 15)), 0xFFFFFFFF);						//v_adc_threshold
			usleep(10000);

			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 14)), 1023);							//c_adc_threshold_count
			usleep(10000);

			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 16)), 1023);							//v_adc_threshold_count
			usleep(10000);

			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 1);								//intl_rst
			usleep(10000);

			if(OSC_mode == 0)																		//c_min, c_max
			{
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 0);
				usleep(10000);

				printf("c_min c_max : \n");
				while(1)
				{
					c_min = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 27));
					c_max = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 28));
					printf("%d %d\n", c_min, c_max);
					usleep(100000);
				}
			}

			else if(OSC_mode == 1)																	//v_min v_max
			{
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 0);
				usleep(10000);

				printf("v_min v_max : \n");
				while(1)
				{
					v_min = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 29));
					v_max = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 30));
					printf("%d %d\n", v_min, v_max);
					usleep(100000);
				}
			}

			else if(OSC_mode == 2)																	//c_OSC
			{	
				printf("c_adc_threshold?\n");
				scanf("%d", &c_adc_threshold);
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 13)), c_adc_threshold);
				usleep(10000);

				printf("c_adc_threshold_count?\n");
				scanf("%d", &c_adc_threshold_count);
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 14)), c_adc_threshold_count);
				usleep(10000);

				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 0);
				usleep(10000);

				printf("c_min c_max : \n");
				while(1)
				{
					rst = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12));
					c_min = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 27));
					c_max = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 28));
					printf("%d %d\n", c_min, c_max);
					usleep(100000);
				}
			}

			else if(OSC_mode == 3)																	//v_OSC
			{
				printf("v_adc_threshold?\n");
				scanf("%d", &v_adc_threshold);
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 15)), v_adc_threshold);
				usleep(10000);

				printf("v_adc_threshold_count?\n");
				scanf("%d", &v_adc_threshold_count);
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 16)), v_adc_threshold_count);
				usleep(10000);

				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 0);
				usleep(10000);

				printf("v_min v_max : \n");
				while(1)
				{
					rst = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12));
					v_min = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 29));
					v_max = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 30));
					printf("%d\n", rst);
					printf("%d %d\n", v_min, v_max);
					usleep(100000);
				}
			}

			else if(OSC_mode == 4)																	//OSC_state
			{
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 0);
				usleep(10000);

				while(1)
				{
					OSC_state = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 25));
					printf("OSC_state : %d\n", OSC_state);
					usleep(10000);

					OSC_state_IDLE = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 26));
					printf("OSC_state_IDLE : %d\n", OSC_state_IDLE);
					usleep(10000);
				}
			}
		}
		else if(mode == 8)																			//REGU_mode
		{
			printf("0 : c_REGU_check, 1 : v_REGU_check, 2 : c_REGU, 3 : v_REGU, 4 : REGU_state\n");
			scanf("%d", &REGU_mode);
			usleep(1000);

			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 19)), 10000000);						//c_REGU 목표값 설정
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 20)), 0xFFFFFFFF);						//c_REGU_diff
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 21)), 240000000);						//c_REGU_delay
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 22)), 10000000);						//v_REGU 목표값 설정
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 23)), 0xFFFFFFFF);						//v_REGU_diff
			Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 24)), 240000000);						//v_REGU_delay
			usleep(10000);

			if(REGU_mode == 0)																		//c_REGU_check
			{
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 1);							//v_REGU_flag, c_REGU_flag, REGU_bypass, OSC_bypass, REGU_mode(0 : C / 1 : V), intl_rst 000001
				usleep(10000);

				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 16);							//010000
				usleep(10000);

				printf("c_REGU_abs : \n");
				while(1)
				{
					Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 1);						//000001
					usleep(10);

					c_REGU_abs = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 27));
					printf("%d\n", c_REGU_abs);
					usleep(100000);

					Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 16);						//010000
					usleep(10);
				}
			}

			else if(REGU_mode == 1)																	//v_REGU_check
			{
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 3);							//v_REGU_flag, c_REGU_flag, REGU_bypass, OSC_bypass, REGU_mode(0 : C / 1 : V), intl_rst 000011
				usleep(10000);

				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 34);							//100010
				usleep(10000);

				printf("v_REGU_abs : \n");
				while(1)
				{

					Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 34);						//100010
					usleep(10);

					v_REGU_abs = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 28));
					printf("%d\n", v_REGU_abs);
					usleep(10000);

					Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 3);						//000011
					usleep(10);
				}
			}

			else if(REGU_mode == 2)																	//c_REGU
			{
				printf("c_delay?\n");
				scanf("%d", &c_delay);
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 21)), c_delay);						//c_REGU_delay
				usleep(10000);

				printf("c_diff?\n");
				scanf("%d", &c_diff);
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 20)), c_diff);
				usleep(10000);

				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 1);							//v_REGU_flag, c_REGU_flag, REGU_bypass, OSC_bypass, REGU_mode(0 : C / 1 : V), intl_rst 000001
				usleep(10000);

				printf("c_set?\n");
				scanf("%d", &c_set);
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 19)), c_set);
				usleep(10000);

				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 16);							//010000
				usleep(10000);

				printf("c_REGU_abs : \n");
				while(1)
				{
					c_REGU_abs = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 27));
					printf("%d\n", c_REGU_abs);
					usleep(100000);
				}
			}

			else if(REGU_mode == 3)																	//v_REGU
			{
				printf("v_delay?\n");
				scanf("%d", &v_delay);
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 24)), v_delay);						//v_REGU_delay
				usleep(10000);

				printf("v_diff?\n");
				scanf("%d", &v_diff);
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 23)), v_diff);						//v_REGU_diff
				usleep(10000);

				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 3);							//v_REGU_flag, c_REGU_flag, REGU_bypass, OSC_bypass, REGU_mode(0 : C / 1 : V), intl_rst 000011
				usleep(10000);

				printf("v_set?\n");
				scanf("%d", &v_set);
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 22)), v_set);						//v_REGU 목표값 설정
				usleep(10000);

				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 34);							//100010
				usleep(10000);

				printf("v_REGU_abs : \n");
				while(1)
				{
					v_REGU_abs = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 28));
					printf("%d\n", v_REGU_abs);
					usleep(100000);
				}
			}

			else if(REGU_mode == 4)																	//REGU_state
			{		
				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 3);							//v_REGU_flag, c_REGU_flag, REGU_bypass, OSC_bypass, REGU_mode(0 : C / 1 : V), intl_rst 000011
				usleep(10000);

				Xil_Out32((XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 12)), 34);							//100010
				usleep(10000);

				while(1)
				{
					REGU_state = Xil_In32(XPAR_INTL_V1_0_TOP_0_BASEADDR + (4 * 26));
					printf("REGU_state : %d\n", REGU_state);
					usleep(10000);
				}
			}
		}
	}
	return 0;
}