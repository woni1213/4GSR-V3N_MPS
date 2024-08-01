`timescale 1 ns / 1 ps

/*

MPS LCD_SWitch Module
개발 4팀 전경원 차장

24.07.25 :	최초 생성

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - 이성진 차장 코드 주석 오류 존나 많으니 참고하지마라
 - 미친 SPI Data를 MOSI를 SO로 표기함 미친새낀가
 - 원본 코드 진짜 개 더럽네

1. 개요
 - 

*/

module LCD_SW
(
	input i_clk,
	input i_rst,

	input i_lcd_sw_start,
	input i_sw_intr,
	input i_sw_intr_clear,
	output reg [7:0] o_sw_data,

	input [23:0] i_dpbram_data,
	output reg [7:0] o_dpbram_addr,

	output o_spi_start,
	output [23:0] o_mosi_data,
	input [23:0] i_miso_data,

	output o_lcd_sw_cs					// 0 : LCD, 1 : Switch
);

	parameter LCD_SW_DELAY	= 0;
	parameter LCD_SW_INIT 	= 1;
	parameter LCD_SW_IDLE  	= 2;
	parameter LCD_SW_LEN_RD	= 3;
	parameter LCD_SW_RUN	= 4;
	parameter LCD_SW_DONE	= 5;

	parameter INTR_IDLE	= 0;
	parameter INTR_RUN	= 1;
	parameter INTR_DONE	= 2;

	// FSM
	reg [2:0] lcd_sw_state;
	reg [2:0] lcd_sw_n_state;

	reg [1:0] intr_state;
	reg [1:0] intr_n_state;

	// Counter
	reg [25:0] delay_cnt;
	reg [12:0] run_time_cnt;
	reg [6:0] init_data_cnt;
	reg [3:0] len_rd_time_cnt;
	reg [7:0] run_data_cnt;

	// SPI Data
	wire [23:0] init_data [0:116];
	reg [23:0] mosi_data;
	reg [7:0] spi_data_set_len;

	// Flag
	wire run_time_cnt_flag;
	wire len_rd_data_read_flag;
	wire run_addr_set_flag;
	wire run_data_set_flag;

	// FSM Control
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            lcd_sw_state <= LCD_SW_DELAY;

        else 
			lcd_sw_state <= lcd_sw_n_state;
    end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            intr_state <= INTR_IDLE;

        else 
			intr_state <= intr_n_state;
    end

	// FSM
	always @(*)
    begin
        case (lcd_sw_state)
            LCD_SW_DELAY :
            begin
                if (delay_cnt == 67_000_000)
                    lcd_sw_n_state <= LCD_SW_INIT;

                else
                    lcd_sw_n_state <= LCD_SW_DELAY;
            end

			LCD_SW_INIT :
            begin
                if (init_data_cnt == 117)
                    lcd_sw_n_state <= LCD_SW_IDLE;

                else
                    lcd_sw_n_state <= LCD_SW_INIT;
            end

			LCD_SW_IDLE :
            begin
                if (i_lcd_sw_start)
                    lcd_sw_n_state <= LCD_SW_LEN_RD;

                else
                    lcd_sw_n_state <= LCD_SW_IDLE;
            end

			LCD_SW_LEN_RD :
            begin
                if (len_rd_time_cnt == 5)
                    lcd_sw_n_state <= LCD_SW_RUN;

                else
                    lcd_sw_n_state <= LCD_SW_LEN_RD;
            end

			LCD_SW_RUN :
            begin
                if (run_data_cnt == spi_data_set_len)
                    lcd_sw_n_state <= LCD_SW_DONE;

                else
                    lcd_sw_n_state <= LCD_SW_RUN;
            end

			LCD_SW_DONE :
			begin
				if (~i_lcd_sw_start)
                    lcd_sw_n_state <= LCD_SW_IDLE;

                else
                    lcd_sw_n_state <= LCD_SW_DONE;
			end
                

			default :
                    lcd_sw_n_state <= LCD_SW_DELAY;
		endcase
	end

	always @(*)
    begin
        case (intr_state)
            INTR_IDLE :
            begin
                if ((~i_sw_intr) && (~i_sw_intr_clear))
                    intr_n_state <= INTR_RUN;

                else
                    intr_n_state <= INTR_IDLE;
            end

			INTR_RUN :
            begin
                if (i_sw_intr_clear)
                    intr_n_state <= INTR_DONE;

                else
                    intr_n_state <= INTR_RUN;
            end

			INTR_DONE :
            begin
                if ((i_sw_intr) && (~i_sw_intr_clear))
                    intr_n_state <= INTR_IDLE;

                else
                    intr_n_state <= INTR_DONE;
            end

			default :
                    intr_n_state <= INTR_IDLE;
		endcase
	end

	// Delay Counter
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			delay_cnt <= 0;

		else if (lcd_sw_state == LCD_SW_DELAY)
			delay_cnt <= delay_cnt + 1;

		else
			delay_cnt <= 0;
	end

	// SPI Data Send Time Counter
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			run_time_cnt <= 0;

		else if (lcd_sw_state == LCD_SW_INIT || lcd_sw_state == LCD_SW_RUN)
		begin
			if (run_time_cnt_flag)
				run_time_cnt <= 0;

			else
				run_time_cnt <= run_time_cnt + 1;
		end
			
		else
			run_time_cnt <= 0;
	end

	// Init SPI Data Counter
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			init_data_cnt <= 0;

		else if (lcd_sw_state == LCD_SW_INIT)
		begin
			if (run_time_cnt_flag)
				init_data_cnt <= init_data_cnt + 1;

			else
				init_data_cnt <= init_data_cnt;
		end

		else
			init_data_cnt <= 0;
	end

	// SPI Data Set Length Read State Time Counter
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			len_rd_time_cnt <= 0;

		else if (lcd_sw_state == LCD_SW_LEN_RD)
			len_rd_time_cnt <= len_rd_time_cnt + 1;

		else
			len_rd_time_cnt <= 0;
	end

	// SPI Data Set Length Read
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			spi_data_set_len <= 0;

		else if (len_rd_data_read_flag)
			spi_data_set_len <= i_dpbram_data[7:0];

		else
			spi_data_set_len <= spi_data_set_len;
	end

	// DPBRAM Addr
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			o_dpbram_addr <= 0;

		else if (lcd_sw_state == LCD_SW_LEN_RD)
			o_dpbram_addr <= 1;

		else if (lcd_sw_state == LCD_SW_RUN)
		begin
			if (run_addr_set_flag)
				o_dpbram_addr <= o_dpbram_addr + 1;

			else
				o_dpbram_addr <= o_dpbram_addr;
		end

		else
			o_dpbram_addr <= 0;
	end

	// SPI Send Data
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			mosi_data <= 0;

		else if (run_data_set_flag)
			mosi_data <= i_dpbram_data;

		else if (!(lcd_sw_state == LCD_SW_RUN))
			mosi_data <= 0;

		else
			mosi_data <= mosi_data;
	end

	// SPI Send Data
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			run_data_cnt <= 0;

		else if (lcd_sw_state == LCD_SW_RUN)
		begin
			if (run_time_cnt_flag)
				run_data_cnt <= run_data_cnt + 1;

			else
				run_data_cnt <= run_data_cnt;
		end

		else
			run_data_cnt <= 0;
	end

	// SW Interrupt Data
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
			o_sw_data <= 8'hff;

		else if (intr_state == INTR_RUN)
		begin
			if (o_dpbram_addr == 3)
				o_sw_data <= i_miso_data[7:0];

			else
				o_sw_data <= o_sw_data;
		end

		else
			o_sw_data <= 8'hff;
	end


	assign o_mosi_data = (lcd_sw_state == LCD_SW_INIT) ? init_data[init_data_cnt] : mosi_data;
	assign o_spi_start = (((lcd_sw_state == LCD_SW_INIT) && (run_time_cnt == 1)) || ((lcd_sw_state == LCD_SW_RUN) && (run_time_cnt == 4))) ? 1 : 0;

	assign run_time_cnt_flag = (run_time_cnt == 6600) ? 1 : 0;
	assign len_rd_data_read_flag = ((lcd_sw_state == LCD_SW_LEN_RD) && (len_rd_time_cnt == 2)) ? 1 : 0;
	assign run_addr_set_flag = ((lcd_sw_state == LCD_SW_RUN) && (run_time_cnt == 1)) ? 1 : 0;
	assign run_data_set_flag = ((lcd_sw_state == LCD_SW_RUN) && (run_time_cnt == 3)) ? 1 : 0;

	assign o_lcd_sw_cs = ((o_dpbram_addr == 2) || (o_dpbram_addr == 3)) ? 1 : 0;

	assign init_data[0]		= 24'hF8_50_40;			// 0x2A Function Set
	assign init_data[1]		= 24'hF8_80_E0;			// 0x71 Function Selection A
	assign init_data[2]		= 24'hFA_30_A0;			// 0x5C Enable Internal VDD
	assign init_data[3]		= 24'hF8_10_40;			// 이하 주석 생략
	assign init_data[4]		= 24'hF8_10_00;
	assign init_data[5]		= 24'hF8_50_40;
	assign init_data[6]		= 24'hF8_90_E0;
	assign init_data[7]		= 24'hF8_A0_B0;
	assign init_data[8]		= 24'hF8_00_E0;
	assign init_data[9]		= 24'hF8_10_E0;
	assign init_data[10]	= 24'hF8_90_00; 
	assign init_data[11]	= 24'hF8_60_00; 
	assign init_data[12]	= 24'hF8_40_E0; 
	assign init_data[13]	= 24'hFA_80_00; 
	assign init_data[14]	= 24'hF8_50_40; 
	assign init_data[15]	= 24'hF8_90_E0; 
	assign init_data[16]	= 24'hF8_50_B0; 
	assign init_data[17]	= 24'hF8_00_80; 
	assign init_data[18]	= 24'hF8_30_B0; 
	assign init_data[19]	= 24'hF8_00_00; 
	assign init_data[20]	= 24'hF8_80_10; 
	assign init_data[21]	= 24'hF8_F0_E0; 
	assign init_data[22]	= 24'hF8_90_B0; 
	assign init_data[23]	= 24'hF8_80_F0; 
	assign init_data[24]	= 24'hF8_D0_B0; 
	assign init_data[25]	= 24'hF8_00_20; 
	assign init_data[26]	= 24'hF8_10_E0; 
	assign init_data[27]	= 24'hF8_10_40; 
	assign init_data[28]	= 24'hF8_80_00; 
	assign init_data[29]	= 24'hF8_00_10; 
	assign init_data[30]	= 24'hF8_30_00; 
	assign init_data[31]	= 24'hF8_80_00; 
	assign init_data[32]	= 24'hF8_40_00; 
	assign init_data[33]	= 24'hF8_00_10; 
	assign init_data[34]	= 24'hFA_00_40;			// 0x20 ' '
	assign init_data[35]	= 24'hFA_00_40; 
	assign init_data[36]	= 24'hFA_00_40; 
	assign init_data[37]	= 24'hFA_00_40; 
	assign init_data[38]	= 24'hFA_00_40; 
	assign init_data[39]	= 24'hFA_00_40; 
	assign init_data[40]	= 24'hFA_00_40; 
	assign init_data[41]	= 24'hFA_00_40; 
	assign init_data[42]	= 24'hFA_00_40; 
	assign init_data[43]	= 24'hFA_00_40; 
	assign init_data[44]	= 24'hFA_00_40; 
	assign init_data[45]	= 24'hFA_00_40; 
	assign init_data[46]	= 24'hFA_00_40; 
	assign init_data[47]	= 24'hFA_00_40; 
	assign init_data[48]	= 24'hFA_00_40; 
	assign init_data[49]	= 24'hFA_00_40; 
	assign init_data[50]	= 24'hFA_00_40; 
	assign init_data[51]	= 24'hFA_00_40; 
	assign init_data[52]	= 24'hFA_00_40; 
	assign init_data[53]	= 24'hFA_00_40; 
	assign init_data[54]	= 24'hF8_00_50; 
	assign init_data[55]	= 24'hFA_00_40; 
	assign init_data[56]	= 24'hFA_B0_20;			// 0x4D 'M'
	assign init_data[57]	= 24'hFA_00_A0; 
	assign init_data[58]	= 24'hFA_C0_A0; 
	assign init_data[59]	= 24'hFA_C0_20; 
	assign init_data[60]	= 24'hFA_20_30;  
	assign init_data[61]	= 24'hFA_60_A0; 
	assign init_data[62]	= 24'hFA_C0_C0; 
	assign init_data[63]	= 24'hFA_00_40; 
	assign init_data[64]	= 24'hFA_00_40; 
	assign init_data[65]	= 24'hFA_00_40; 
	assign init_data[66]	= 24'hFA_00_40; 
	assign init_data[67]	= 24'hFA_00_40; 
	assign init_data[68]	= 24'hFA_00_40; 
	assign init_data[69]	= 24'hFA_00_40; 
	assign init_data[70]	= 24'hFA_00_40; 
	assign init_data[71]	= 24'hFA_00_40; 
	assign init_data[72]	= 24'hFA_00_40; 
	assign init_data[73]	= 24'hFA_00_40; 
	assign init_data[74]	= 24'hFA_00_40; 
	assign init_data[75]	= 24'hF8_00_30; 
	assign init_data[76]	= 24'hFA_00_40; 
	assign init_data[77]	= 24'hFA_00_40; 
	assign init_data[78]	= 24'hFA_00_40; 
	assign init_data[79]	= 24'hFA_00_40; 
	assign init_data[80]	= 24'hFA_00_40; 
	assign init_data[81]	= 24'hFA_00_40; 
	assign init_data[82]	= 24'hFA_00_40; 
	assign init_data[83]	= 24'hFA_00_40; 
	assign init_data[84]	= 24'hFA_00_40; 
	assign init_data[85]	= 24'hFA_00_40; 
	assign init_data[86]	= 24'hFA_00_40; 
	assign init_data[87]	= 24'hFA_00_40; 
	assign init_data[88]	= 24'hFA_00_40; 
	assign init_data[89]	= 24'hFA_60_A0; 
	assign init_data[90]	= 24'hFA_A0_60; 
	assign init_data[91]	= 24'hFA_40_E0; 
	assign init_data[92]	= 24'hFA_80_C0; 
	assign init_data[93]	= 24'hFA_70_40; 
	assign init_data[94]	= 24'hFA_00_C0; 
	assign init_data[95]	= 24'hFA_00_40; 
	assign init_data[96]	= 24'hF8_00_70; 
	assign init_data[97]	= 24'hFA_00_40; 
	assign init_data[98]	= 24'hFA_00_40; 
	assign init_data[99]	= 24'hFA_00_40; 
	assign init_data[100]	= 24'hFA_00_40; 
	assign init_data[101]	= 24'hFA_00_40; 
	assign init_data[102]	= 24'hFA_00_40; 
	assign init_data[103]	= 24'hFA_00_40; 
	assign init_data[104]	= 24'hFA_00_40; 
	assign init_data[105]	= 24'hFA_00_40; 
	assign init_data[106]	= 24'hFA_00_40; 
	assign init_data[107]	= 24'hFA_00_40; 
	assign init_data[108]	= 24'hFA_00_40; 
	assign init_data[109]	= 24'hFA_00_40; 
	assign init_data[110]	= 24'hFA_00_40; 
	assign init_data[111]	= 24'hFA_00_40; 
	assign init_data[112]	= 24'hFA_00_40; 
	assign init_data[113]	= 24'hFA_00_40; 
	assign init_data[114]	= 24'hFA_00_40; 
	assign init_data[115]	= 24'hFA_00_40; 
	assign init_data[116]	= 24'hFA_00_40; 

endmodule