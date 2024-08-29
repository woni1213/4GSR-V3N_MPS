#include <stdio.h>
#include "sleep.h"
#include "string.h"

#include "init.h"

unsigned long lcd_data;
unsigned long lcd_command;

unsigned char reverse_bits(unsigned char byte)
{
    unsigned char reversed = 0;
    for (int i = 0; i < 8; i++)
    {
        reversed |= ((byte >> i) & 1) << (7 - i);
    }
    return reversed;
}

unsigned long ascii_data(char character)
{
	unsigned char ascii_code = (unsigned char)character;

	unsigned char reversed = reverse_bits(ascii_code);

	unsigned char high_bit = (reversed & 0xF0);

	unsigned char low_bit = (reversed << 4);

	lcd_data = 0xFA0000 | (high_bit << 8) | low_bit;

	return lcd_data;
}

unsigned long ascii_command(char character)
{
	unsigned char ascii_code = (unsigned char)character;

	unsigned char reversed = reverse_bits(ascii_code);

	unsigned char high_bit = (reversed & 0xF0);

	unsigned char low_bit = (reversed << 4);

	lcd_command = 0xF80000 | (high_bit << 8) | low_bit;

	return lcd_command;
}

void lcd_init()
{
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 4);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_command(0x01));			// 0x01 Clear Display
	usleep(10);

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 5);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_command(0x81));			// 0x81 Set DDRAM Address to 0x00
	usleep(10);

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 6);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_command(0x7F));			// 0x7F Display ON
	usleep(10);

    for (int i = 0; i < 20; i++)
    {
        Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), (7 + i));
        Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x20));
        usleep(10);
    }

    Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 27);
    Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_command(0xA0));		// 0xA0 Set DDRAM Address to Second Line
    usleep(10);

    Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 28);
    Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x20));		// 0x20 ' '
    usleep(10);

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 29);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x54));		// 0x54 'T'
	usleep(10);

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 30);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x45));		// 0x45 'E'
	usleep(10);

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 31);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x53));		// 0x53 'S'
	usleep(10);

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 32);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), ascii_data(0x54));		// 0x54 'T'
	usleep(10);
}

void lcd_start()
{
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 1);							// lcd_start
	usleep(10000);

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 0);							// lcd_start clear
	usleep(10000);
}

void sw_led_init()
{
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 3);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 0x40000f);					// IODIRA (A Channel 0 ~ 3 Input Setup)
	usleep(10);

	lcd_start();

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 3);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 0x400100);					// IODIRB (B Channel 0 ~ 7 Output Setup)
	usleep(10);

	lcd_start();

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 3);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 0x40040f);					// GPINTENA (A Channel 0 ~ 3 Interrupt Control Setup)
	usleep(10);

	lcd_start();

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 3);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 0x40060f);					// DEFVALA (A Channel 0 ~ 3 Interrupt 비교 값 Setup. 입력 값과 비교 값이 다르면 Interrupt 발생)
	usleep(10);

	lcd_start();

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 3);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 0x40080f);					// INTCONA (A Channel 0 ~ 3 DEFVAL 비트와 비교)
	usleep(10);

	lcd_start();

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 3);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 0x400c0f);					// GPPUA (A Channel 0 ~ 3 100KOhm Pullup Resistor Enable)
	usleep(10);

	lcd_start();
}

void led_init()
{
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 1);
	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), 3);
	usleep(10);

	sw_led_init();

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 4), 2);

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 8), (0x401300));
	usleep(10);

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 1);
	usleep(10000);

	Xil_Out32((XPAR_FRONT_FRONT_V1_0_TOP_0_BASEADDR + 12), 2);
	usleep(10000);
}
