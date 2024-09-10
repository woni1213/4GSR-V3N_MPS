`timescale 1 ns / 1 ps

module SFP_Data_Handler #
(
	parameter integer C_AXIS_TDATA_WIDTH = 0,

	parameter integer C_DATA_STREAM_BIT = 0,
	parameter integer C_DATA_FRAME_BIT = 0
)
(
	input i_clk,
	input i_rst,

	input [C_DATA_STREAM_BIT - 1 : 0] i_axi_data,
	output reg [C_DATA_STREAM_BIT - 1 : 0] o_axi_data,

	input [C_DATA_STREAM_BIT - 1 : 0] i_rx_stream_data,
	output reg [C_DATA_STREAM_BIT - 1 : 0] o_tx_stream_data,

	output o_sfp_start_flag,
	input i_sfp_end_flag,
	
	output o_axi_data_valid,
	input i_sfp_m_en
);

	localparam IDLE = 0;
	
	localparam M_TX_DATA_SET = 1;
	localparam M_TX = 2;
	localparam M_RX = 3;
	localparam M_RX_DATA_SET = 4;
	localparam M_RUN = 5;

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
					if (i_sfp_m_en)
						state = M_TX_DATA_SET;

					else if ((i_sfp_end_flag) && (!i_sfp_m_en))
						state = S_RX;

					else
						state = IDLE;
				end

				// Master Mode Stage
				M_TX_DATA_SET :
						state = M_TX;

				M_TX :
						state = M_RX;

				M_RX :
				begin
					if (i_sfp_end_flag)
						state = M_RX_DATA_SET;

					else
						state = M_RX;
				end

				M_RX_DATA_SET :
						state = M_RUN;

				M_RUN :
				begin
					if (o_axi_data[C_DATA_FRAME_BIT * 2 +: 16] == 16'h00FF)
						state = IDLE;

					else
						state = M_RUN;
				end

				// Slave Mode Stage
				S_RX :
						state = S_RUN;

				S_RUN :
						state = S_DATA_SET;

				S_DATA_SET :
						state = S_TX;

				S_TX :
						state = IDLE;

				default :
						state = IDLE;

			endcase
		end
	end

	
	always @(posedge i_clk or negedge i_rst)
	begin
		if (!i_rst)
			o_tx_stream_data <= 0;

		else if ((state == M_TX_DATA_SET) || (state == S_DATA_SET))
			o_tx_stream_data <= i_axi_data;

		else
			o_tx_stream_data <= o_tx_stream_data;
	end

	always @(posedge i_clk or negedge i_rst) 
	begin
		if (!i_rst)
			o_axi_data <= 0;

		else if ((state == M_RX_DATA_SET) || (state == S_RX))
			o_axi_data <= i_rx_stream_data;

		else if ((state == M_RUN) && (o_axi_data[C_DATA_FRAME_BIT * 2 +: 16] == 16'h0000))
			o_axi_data <= o_axi_data << C_DATA_FRAME_BIT;

		else
			o_axi_data <= o_axi_data;
	end

	assign o_sfp_start_flag = (state == M_TX) || (state == S_TX);
	assign o_axi_data_valid = ((state == M_RUN) || (state == M_RX_DATA_SET)) ? 0 : 1;

endmodule