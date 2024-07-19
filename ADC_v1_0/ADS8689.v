`timescale 1 ns / 1 ps

/*

MPS ADC Module
개발 4팀 전경원 차장

1. Time
 - ADC Cycle				: 100 KHz
 - SCK Period				: > 14.9ns (50MHz / SPI IP T_CYCLE : 2)
 - CNV Hold Time (tcnvh)	: < 5000ns
 - CNV to SCK (tsu_csck)	: > 7.5ns (SPI IP DELAY : 3)

2. SPI Setup (SPI_v1_0)
 - T_CYCLE 		: 2
 - DELAY		: 3
 - DATA_WIDTH	: 32
 - CPHA / CPOL	: 0 / 0 (Default)

*/

module ADS8689 #
(
	parameter integer ADS8689_RAM_DEPTH = 0
)
(
	input i_clk,
	input i_rst,

	input i_dc_adc_rvs,
	output o_dc_adc_cnv,

	output o_dc_adc_spi_start,
	input i_dc_adc_data_valid,

	output reg [10:0] o_dc_adc_ram_addr,
	output o_dc_adc_ram_cs,
	output o_dc_adc_ram_1_flag,
	output o_dc_adc_ram_2_flag,

	output reg [31:0] o_dc_adc_o_mosi_data,

	output [2:0] o_debug_state					// Debug Port
);

	parameter IDLE	= 0;
	parameter BUSY	= 1;
	parameter RVS	= 2;
	parameter SPI	= 3;
	parameter DONE	= 4;

	parameter ADC_CYCLE = 2000;

	// FSM
	reg [2:0] state;
	reg [2:0] n_state;

	// Count
	reg [$clog2(ADC_CYCLE) : 0] cnv_cnt;			// Conversion Counter

	// Flag
	wire cnv_start_flag;
	wire cnv_end_flag;
	reg init_flag;

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
                if (cnv_start_flag)
                    n_state <= BUSY;

                else
                    n_state <= IDLE;
            end

			BUSY :
            begin
                if (cnv_end_flag)
                    n_state <= RVS;

                else
                    n_state <= BUSY;
            end

			RVS :
            begin
                if (~i_dc_adc_rvs)
                    n_state <= SPI;

                else
                    n_state <= RVS;
            end

			SPI :
            begin
                if (i_dc_adc_data_valid)
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

	// Conversion Count. Fixed 10us
	// 1 Cycle 후에 동작하기 위하여 reset 후 cnv_cnt를 1로 함
	always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            cnv_cnt <= 1;

		else if (cnv_cnt == ADC_CYCLE)
			cnv_cnt <= 0;

		else 
			cnv_cnt <= cnv_cnt + 1;
	end

	// DPBRAM Address
	always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            o_dc_adc_ram_addr <= 0;

		else if (state == DONE)
		begin
			if (o_dc_adc_ram_addr == ADS8689_RAM_DEPTH - 1)
				o_dc_adc_ram_addr <= 0;

			else
			begin
				if (init_flag)
					o_dc_adc_ram_addr <= o_dc_adc_ram_addr + 1;

				else
					o_dc_adc_ram_addr <= o_dc_adc_ram_addr;
			end
		end

		else
			o_dc_adc_ram_addr <= o_dc_adc_ram_addr;
	end

	// Init Flag
	always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            init_flag <= 0;

		else if (state == DONE)
			init_flag <= 1;

		else
			init_flag <= init_flag;
	end

	// Init MOSI Data
	always @(posedge i_clk or negedge i_rst) 
    begin
        if (~i_rst)
            o_dc_adc_o_mosi_data <= 31'hd0140001;
		
		else if (init_flag)
			o_dc_adc_o_mosi_data <= 31'h00000000;

		else
			o_dc_adc_o_mosi_data <= o_dc_adc_o_mosi_data;
	end

	assign cnv_start_flag = (cnv_cnt == 0) ? 1 : 0;
	assign cnv_end_flag = (cnv_cnt == 1000) ? 1 : 0;

	assign o_dc_adc_cnv = (cnv_cnt <= 1000) ? 1 : 0;
	assign o_dc_adc_spi_start = (state == RVS && ~i_dc_adc_rvs) ? 1 : 0;
	assign o_dc_adc_ram_cs = (state == DONE) ? 1 : 0;
	assign o_dc_adc_ram_1_flag = (o_dc_adc_ram_addr < ADS8689_RAM_DEPTH / 2) ? 1 : 0;
	assign o_dc_adc_ram_2_flag = (o_dc_adc_ram_addr >= ADS8689_RAM_DEPTH / 2) ? 1 : 0;

	assign o_debug_state = state;
endmodule