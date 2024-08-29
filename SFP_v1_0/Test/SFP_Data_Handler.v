`timescale 1 ns / 1 ps
/*

SFP Test Handler Module
개발 4팀 전경원 차장

24.08.26 :	최초 생성

1. 개요
 - Master와 Slave 동작이 서로 다름
 - IDLE 상태에서 어떤 신호가 들어오느냐에 따라서 갈림

2. Master FSM
 - AXI4-Lite로 동작 시작
 - 데이터 셋업 - 데이터 전송 - 데이터 수신 대기 - 수신 후 데이터 AXI4-Lite로 전송 - Clear

3. Slave FSM
 - 데이터 수신 - 데이터 처리 - 데이터 셋업 - 데이터 송신

*/

module SFP_Data_Handler #
(
	parameter integer C_AXIS_TDATA_WIDTH = 0,

	parameter integer C_DATA_BIT = 0,
	parameter integer C_DATA_FRAME_BIT = 0
)
(
	input i_clk,
	input i_rst,

	input [C_DATA_BIT - 1 : 0] i_axi_data,
	output reg [C_DATA_BIT - 1 : 0] o_axi_data,

	input [C_DATA_BIT - 1 : 0] i_rx_stream_data,
	output reg [C_DATA_BIT - 1 : 0] o_tx_stream_data,

	input [C_DATA_FRAME_BIT - 1 : 0] i_frame_data,
	output reg [C_DATA_FRAME_BIT - 1 : 0] o_frame_data,

	input i_ps_sfp_start,
	output o_ps_sfp_valid,
	input i_ps_sfp_valid_clr,
	output o_frame_data_valid,
	input i_frame_data_clr,

	output o_sfp_start_flag,
	input i_sfp_end_flag,

	output [3:0] o_test_state
);

	localparam IDLE = 0;
	
	localparam M_DATA_SET = 1;
	localparam M_TX = 2;
	localparam M_RX = 3;
	localparam M_RUN = 4;

	localparam S_RX = 6;
	localparam S_RUN = 7;
	localparam S_DATA_SET = 8;
	localparam S_TX = 9;


	reg [3:0] state;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (!i_rst)
			state <= IDLE;

		else
		begin
			case (state)
				IDLE :
				begin
					if (i_ps_sfp_start)
						state <= M_DATA_SET;

					else if (i_sfp_end_flag)
						state <= S_RX;

					else
						state <= IDLE;
				end

				M_DATA_SET :
						state <= M_TX;

				M_TX :
						state <= M_RX;

				M_RX :
				begin
					if (i_sfp_end_flag)
						state <= M_RUN;

					else
						state <= M_RX;
				end

				M_RUN :
				begin
					if (i_ps_sfp_valid_clr)
						state <= IDLE;

					else
						state <= M_RUN;
				end

				S_RX :
						state <= S_RUN;

				S_RUN :
				begin
					if (i_frame_data_clr)
						state <= S_DATA_SET;

					else
						state <= S_RUN;
				end

				S_DATA_SET :
						state <= S_TX;

				S_TX :
						state <= IDLE;

				default :
						state <= IDLE;

			endcase
		end
	end

	
	always @(posedge i_clk or negedge i_rst)
	begin
		if (!i_rst)
			o_tx_stream_data <= 0;

		else if (state == M_DATA_SET)
			o_tx_stream_data <= i_axi_data;

		else if (state == S_DATA_SET)
			o_tx_stream_data <= (i_rx_stream_data << C_DATA_FRAME_BIT) + i_frame_data;

		else
			o_tx_stream_data <= o_tx_stream_data;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (!i_rst)
			o_axi_data <= 0;

		else if (state == M_RUN)
			o_axi_data <= i_rx_stream_data;

		else
			o_axi_data <= o_axi_data;
	end


	always @(posedge i_clk or negedge i_rst) 
	begin
		if (!i_rst)
			o_frame_data <= 0;

		else if (state == S_RX)
			o_frame_data <= i_rx_stream_data[(C_DATA_BIT - 1) -: C_DATA_FRAME_BIT];

		else
			o_frame_data <= o_frame_data;
	end
	
	assign o_ps_sfp_valid = (state == M_RUN);
	assign o_sfp_start_flag = ((state == M_TX) || (state == S_TX));
	assign o_frame_data_valid = (state == S_RUN);
				
	assign o_test_state = state;
endmodule