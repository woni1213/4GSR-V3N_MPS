`timescale 1 ns / 1 ps

module LED_Test #
(
	parameter integer C_AXIS_TDATA_WIDTH = 0,
	parameter integer C_NUMBER_OF_FRAME = 0,

	parameter integer C_DATA_FRAME_BIT = 0
)
(
	input i_clk,
	input i_rst,

	input [C_DATA_FRAME_BIT - 1 : 0] i_frame_data,
	output reg [C_DATA_FRAME_BIT - 1 : 0] o_frame_data,

	input i_frame_data_valid,
	output o_frmae_data_clr,

	output reg o_led_test
);

	localparam IDLE = 0;
	localparam RX_DATA = 1;
	localparam TX_DATA = 2;
	localparam DONE = 3;

	reg [1:0] state;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (!i_rst)
			state <= IDLE;

		else
		begin
			case (state)
				IDLE :
				begin
					if (i_frame_data_valid)
						state <= RX_DATA;

					else
						state <= IDLE;
				end

				RX_DATA :
						state <= TX_DATA;

				TX_DATA :
						state <= DONE;
				
				DONE :
						state <= IDLE;
			endcase
		end
	end


	always @(posedge i_clk or negedge i_rst)
	begin
		if (!i_rst)
			o_led_test <= 1;

		else if (state == RX_DATA)
			o_led_test <= i_frame_data[0];

		else
			o_led_test <= o_led_test;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (!i_rst)
			o_frame_data <= 0;

		else if (state == TX_DATA)
			o_frame_data <= 64'h0000_0000_0000_FFFF;

		else
			o_frame_data <= o_frame_data;
	end

	assign o_frmae_data_clr = (state == DONE);

endmodule