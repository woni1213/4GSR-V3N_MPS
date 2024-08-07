`timescale 1 ns / 1 ps

/*

MPS ADC Module
개발 4팀 전경원 차장

24.05.08 :	최초 생성

24.08.06 :	parameter -> localparam으로 변경

1. Time
 - ADC Cycle			: 1 MHz
 - SCK Period			: > 12.3ns (50MHz / SPI IP T_CYCLE : 2)
 - CNV Hold Time (tcnvh): > 10ns (Setup 4)
 - /CS to SCK (tcssck)	: > 12.3ns (SPI IP DELAY : 3)
 - BUSY to /CS			: 데이터시트에 없음. 임의로 50ns (Setup 10)

2. SPI Setup (SPI_v1_0)
 - T_CYCLE 		: 1
 - DELAY		: 2
 - DATA_WIDTH	: 24
 - CPHA / CPOL	: 0 / 0

*/

module AD4030_24 #
(
	parameter integer AD4030_RAM_DEPTH = 0
)
(
	input i_clk,
	input i_rst,

	input i_v_adc_busy,
	input i_c_adc_busy,
	output o_v_c_adc_cnv,

	output o_v_c_adc_spi_start,
	input i_v_adc_data_valid,
	input i_c_adc_data_valid,

	output reg [14:0] o_v_c_adc_ram_addr,
	output o_v_c_adc_ram_cs,
	output o_v_c_adc_ram_1_flag,
	output o_v_c_adc_ram_2_flag,
	output o_adc_data_valid,

	output [1:0] o_debug_state
);

	localparam IDLE	= 0;
	localparam BUSY	= 1;
	localparam SPI	= 2;
	localparam DONE	= 3;

	localparam ADC_CYCLE = 200;

	// FSM
	reg [1:0] state;
	reg [1:0] n_state;

	// Count
	reg [$clog2(ADC_CYCLE) : 0] cnv_cnt;		// Conversion Counter
	reg [3:0] spi_start_delay_cnt;				// SPI Start Delay Counter

	// Flag
	wire adc_busy_start_flag;
	wire adc_busy_end_flag;
	wire adc_data_valid_flag;

	// FSM Control
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            state <= IDLE;

        else 
            state <= n_state;
    end

	// FSM
	always @(*)
    begin
        case (state)
            IDLE :
            begin
                if (adc_busy_start_flag)
                    n_state <= BUSY;

                else
                    n_state <= IDLE;
            end

			BUSY :
            begin
                if (adc_busy_end_flag)
                    n_state <= SPI;

                else
                    n_state <= BUSY;
            end

			SPI :
            begin
                if (adc_data_valid_flag & (spi_start_delay_cnt == 15))
                    n_state <= DONE;

                else
                    n_state <= SPI;
            end

			DONE :
                n_state <= IDLE;


			default :
                    n_state <= n_state;
		endcase
	end

	// Conversion Count. Fixed 1us
	always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            cnv_cnt <= 0;

		else if (cnv_cnt == ADC_CYCLE)
			cnv_cnt <= 0;

		else 
			cnv_cnt <= cnv_cnt + 1;
	end

	// SPI Start Delay Counter. 0 ~ 14 Count. 9th Count, o_v_c_adc_spi_start is actived (assign).
	always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            spi_start_delay_cnt <= 0;

		else if (state == SPI)
		begin
			if (spi_start_delay_cnt < 15)
				spi_start_delay_cnt <= spi_start_delay_cnt + 1;

			else
				spi_start_delay_cnt <= spi_start_delay_cnt;
		end

		else
			spi_start_delay_cnt <= 0;
	end

	// DPBRAM Address
	always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            o_v_c_adc_ram_addr <= 0;

		else if (state == DONE)
		begin
			if (o_v_c_adc_ram_addr == AD4030_RAM_DEPTH - 1)
				o_v_c_adc_ram_addr <= 0;

			else
				o_v_c_adc_ram_addr <= o_v_c_adc_ram_addr + 1;
		end

		else
			o_v_c_adc_ram_addr <= o_v_c_adc_ram_addr;
	end

	assign adc_busy_start_flag = i_v_adc_busy & i_c_adc_busy;
	assign adc_busy_end_flag = ~(i_v_adc_busy | i_c_adc_busy);
	assign adc_data_valid_flag = i_v_adc_data_valid & i_c_adc_data_valid;
	
	assign o_v_c_adc_cnv = (cnv_cnt < 4) ? 1 : 0;						// CNV H
	assign o_v_c_adc_spi_start = (spi_start_delay_cnt == 9) ? 1 : 0;	// SPI Start
	assign o_v_c_adc_ram_cs = (state == DONE) ? 1 : 0;
	assign o_adc_data_valid = (state == BUSY) ? 1 : 0;
	assign o_v_c_adc_ram_1_flag = (o_v_c_adc_ram_addr < AD4030_RAM_DEPTH / 2) ? 1 : 0;
	assign o_v_c_adc_ram_2_flag = (o_v_c_adc_ram_addr >= AD4030_RAM_DEPTH / 2) ? 1 : 0;

	assign o_debug_state = state;
endmodule