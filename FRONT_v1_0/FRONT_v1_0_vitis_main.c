#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"
#include "string.h"

#include "init.h"

int main()
{
	int mode;

	//SW_LED_test
	int full_state;
	int sw_data;
	int led_data;

	//RO_EN_test
	int encoder_state;
	int encoder_cnt = 0;

	led_init();

	while(1)
	{
		printf("0 : LCD\n1 : Switch\n2 : LED\n3 : Rotary Encoder\n4 : SW_LED_test");
		scanf("%d", &mode);
		if (mode == 0)
		{
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 1);						// SPI_DATA_Length
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 36);
			usleep(10);

			lcd_init();

			printf("LCD_test\n");

			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 33);
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0xC4));		// 0xC4 '_'
			usleep(10);

			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 34);
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x4C));		// 0x4C 'L'
			usleep(10);

			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 35);
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x43));		// 0x53 'C'
			usleep(10);

			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 36);
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x44));		// 0x44 'D'
			usleep(10);

			lcd_start();

			printf("LCD_test complete\n");
			usleep(10000);
		}

		else if (mode == 1)																	// Switch_test
		{
			while (1)
			{
				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 1);
				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 31);
				usleep(10);

				lcd_init();

				sw_led_init();

				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 3);
				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 0x4112ff);			// GPIOA (A Channel Read)
				usleep(10);

				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 1);					// lcd_start
				usleep(10000);

				full_state = Xil_In32(XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + (4 * 4));
				sw_data = full_state & 0xFF;
				printf("sw_data : %d\n", sw_data);
				usleep(10000);

				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 2);					// sw_intr clear
				usleep(10000);
			}
		}

		else if (mode == 2)																	// LED_test
		{
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 1);
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 31);
			usleep(10);

			lcd_init();

			sw_led_init();

			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 2);
			printf("please input for led's test\n");
			scanf("%d", &led_data);

			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), (0x401300 + led_data));	// 0x4013xx GPIOB (B Channel Write)
			usleep(10);

			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 1);
			usleep(10000);

			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 2);
			usleep(10000);
		}

//		RO_ENC
/*
		else if (mode == 3)																	// Rotary_Switch_test
		{
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 1);
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 28);
			usleep(1000);

			lcd_init();

			printf("RO_ENC_test\n");

			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 29);
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x30 + encoder_cnt));		// 0x30 '0'
			usleep(10);

			lcd_start();
			usleep(10000);

			while(1)
			{
				full_state = Xil_In32(XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + (4 * 4));
				encoder_state = (full_state >> 8);

				if (encoder_state == 1)						//CW
				{
					lcd_init();

					encoder_cnt++;

					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 29);
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x30 + encoder_cnt));
					usleep(10);

					lcd_start();

					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 2);
					usleep(10);
				}

				else if (encoder_state == 2)				//CCW
				{
					lcd_init();

					encoder_cnt--;

					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 29);
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x30 + encoder_cnt));
					usleep(10);

					lcd_start();

					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 2);
					usleep(10);
				}

				else
				{
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 2);				// sw_intr clear
					usleep(10);

					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 0);				// sw_intr clear
					usleep(10);
				}
				usleep(1000);
			}
		}
*/

//		RO_ENC_test
		else if (mode == 3)																	// Rotary_Switch_test
		{
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 1);
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 28);
			usleep(1000);

			lcd_init();

			printf("RO_ENC_test\n");

			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 29);
			Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x30 + encoder_cnt));		// 0x30 '0'
			usleep(10);

			lcd_start();
			usleep(10000);

			while(1)
			{
				full_state = Xil_In32(XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + (4 * 4));
				encoder_state = (full_state >> 8);

				if (encoder_state == 2)						//CW
				{
					lcd_init();

					encoder_cnt++;

					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 29);
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x30 + encoder_cnt));
					usleep(10);

					lcd_start();

					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 2);
					usleep(10);
				}

				else if (encoder_state == 3)				//CCW
				{
					lcd_init();

					encoder_cnt--;

					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 29);
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x30 + encoder_cnt));
					usleep(10);

					lcd_start();

					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 2);
					usleep(10);
				}

				else
				{
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 0);				// sw_intr clear
					usleep(10);
				}
				usleep(100);
			}
		}

		else if (mode == 4)																	// Switch_LED_test
		{
			while (1)
			{
				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 1);
				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 31);
				usleep(10);

				lcd_init();

				sw_led_init();

				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 3);
				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 0x4112ff);
				usleep(10);

				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 1);					// lcd_start
				usleep(10000);

				full_state = Xil_In32(XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + (4 * 4));
				sw_data = full_state & 0xFF;
				usleep(10000);

				if (sw_data == 14)
				{
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 2);
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), (0x401304));	// 0x4013xx GPIOB (B Channel Write)
					usleep(10);
				}

				else if (sw_data == 13)
				{
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 2);
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), (0x401308));	// 0x4013xx GPIOB (B Channel Write)
					usleep(10);
				}

				else if (sw_data == 12)
				{
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 2);
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), (0x40130C));	// 0x4013xx GPIOB (B Channel Write)
					usleep(10);
				}

				else if (sw_data == 11)
				{
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 2);
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), (0x401310));	// 0x4013xx GPIOB (B Channel Write)
					usleep(10);
				}

				else if (sw_data == 10)
				{
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 2);
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), (0x401314));	// 0x4013xx GPIOB (B Channel Write)
					usleep(10);
				}

				else if (sw_data == 9)
				{
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 2);
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), (0x401318));
					usleep(10);
				}

				else if (sw_data == 8)
				{
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 2);
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), (0x40131C));
					usleep(10);
				}

				else
				{
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 2);
					Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), (0x401300));
					usleep(10);
				}

				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 1);
				usleep(10000);

				Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 2);
				usleep(10000);
			}
		}
	}

	return 0;
}
