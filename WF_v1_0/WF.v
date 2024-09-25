module WF
(
	input i_clk,
	input i_rst,

	input i_wf_start,
	output reg o_dsp_wf_mode,

	input [31:0] i_wf_read_cnt,

	input i_wf_write_en,

	// DPBRAM WRITE
	output reg [8:0] o_xintf_wf_ram_addr,
	output reg [9:0] o_xintf_wf_ram_din,
	output reg o_xintf_wf_ram_ce,

	input [9:0] i_wf_write_addr,
	input [15:0] i_wf_write_data,

	output reg [31:0] o_wf_read_data_num
);
	parameter W_IDLE = 0;
	parameter W_SETUP = 1;
	parameter WRITE = 2;
	parameter W_DONE = 3;

	parameter DSP_IDLE = 0;
	parameter DSP_RUN = 1;
	parameter DSP_DONE = 2;

	// FSM
	reg [1:0] w_state;
	reg [1:0] n_w_state;

	reg [1:0] dsp_state;
	reg [1:0] n_dsp_state;

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			w_state <= W_IDLE;

		else
			w_state <= n_w_state;
	end

	// DPBRAM CE Control
	always @(posedge i_clk or negedge i_rst)
    begin
            if (~i_rst)
				o_xintf_wf_ram_ce <= 0;

			else if ((w_state == W_SETUP) || (w_state == WRITE))
				o_xintf_wf_ram_ce <= 1;

			else
				o_xintf_wf_ram_ce <= 0;
	end

	// FSM
	always @(*)
	begin
		case (w_state)
			W_IDLE :
			begin
				if (i_wf_write_en)
					n_w_state <= W_SETUP;

				else
					n_w_state <= W_IDLE;
			end

			W_SETUP :
				n_w_state <= WRITE;

			WRITE :
				n_w_state <= W_DONE;

			W_DONE :
			begin
				if (!i_wf_write_en)
					n_w_state <= W_IDLE;

				else
					n_w_state <= W_DONE;
			end
			
			default: 
				n_w_state <= W_IDLE;
		endcase
	end

	// DPBRAM Write
	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
		begin
			o_xintf_wf_ram_addr <= 0;
            o_xintf_wf_ram_din <= 0;
		end

		else if (w_state == WRITE)
		begin
			o_xintf_wf_ram_addr <= i_wf_write_addr;
			o_xintf_wf_ram_din <= i_wf_write_data;
		end
				
		else
			o_xintf_wf_ram_addr <= 0;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			dsp_state <= DSP_IDLE;

		else
			dsp_state <= n_dsp_state;
	end

	always @(posedge i_clk or negedge i_rst)
	begin
		if (~i_rst)
			o_wf_read_data_num <= 0;

		else if (dsp_state == DSP_RUN)
			o_wf_read_data_num <= o_wf_read_data_num + 1;

		else
			o_wf_read_data_num <= 0;
	end

	// FSM
	always @(*)
	begin
		case (dsp_state)
			DSP_IDLE :
			begin
				if (i_wf_start)
				begin
					n_dsp_state <= DSP_RUN;
					o_dsp_wf_mode <= 1;
				end	

				else
					n_dsp_state <= DSP_IDLE;
			end

			DSP_RUN :
			begin
				if (o_wf_read_data_num == i_wf_read_cnt)
				begin
					n_dsp_state <= DSP_DONE;
					o_dsp_wf_mode <= 0;
				end
			end

			DSP_DONE :
			begin
				if (!i_wf_start)
					n_dsp_state <= DSP_IDLE;

				else
					n_dsp_state <= DSP_DONE;
			end
			
			default: 
				n_dsp_state <= DSP_IDLE;
		endcase
	end


endmodule