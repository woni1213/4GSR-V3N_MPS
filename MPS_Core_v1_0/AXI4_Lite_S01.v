`timescale 1 ns / 1 ps

module AXI4_Lite_S01 #
(
	parameter integer C_S_AXI_DATA_WIDTH	= 0,
	parameter integer C_S_AXI_ADDR_NUM 		= 0,
	parameter integer C_S_AXI_ADDR_WIDTH	= 0,

	parameter integer C_DATA_STREAM_BIT = 0,
	parameter integer C_DATA_FRAME_BIT = 0
)
(
	// ADC Calc Factor
	output reg [31:0]	o_c_factor,
	output reg [31:0]	o_v_factor,

	// ADC Data
	input [31:0]		i_c_adc_data,
	input [31:0]		i_v_adc_data,

	// SFP Control
	output reg			o_sfp_m_en,				// 웹 페이지에서 명령줘야함. Init할 때 1로 주면 안됨
	input 				i_pwm_en,
	output reg			o_pwm_en,
	input [15:0] 		i_zynq_intl,

	// DPBRAM Write
	output reg [15:0]	o_zynq_status,
	output reg [15:0]	o_zynq_ver,
    output reg [31:0]	o_set_c,
    output reg [31:0]	o_set_v,
    output reg [31:0]	o_p_gain_c,
    output reg [31:0]	o_i_gain_c,
    output reg [31:0]	o_d_gain_c,
    output reg [31:0]	o_p_gain_v,
    output reg [31:0]	o_i_gain_v,
    output reg [31:0]	o_d_gain_v,
    output reg [31:0]	o_max_duty,
    output reg [31:0]	o_max_phase,
    output reg [31:0]	o_max_freq,
    output reg [31:0]	o_min_freq,
	output reg [31:0]	o_max_c,
    output reg [31:0]	o_min_c,
    output reg [31:0]	o_max_v,
    output reg [31:0]	o_min_v,
	output reg [15:0]	o_deadband,
    output reg [15:0]	o_sw_freq,

	// DPBRAM Read
	input [15:0]		i_dsp_status,
	input [15:0]		i_dsp_ver,
    input [31:0]		i_wf_read_cnt,

	// SFP PI Parameter
	input [31:0]		i_slave_pi_param_1,
	input [31:0]		i_slave_pi_param_2,
	input [31:0]		i_slave_pi_param_3,
	output reg [31:0]	o_master_pi_param,
	input 				i_axi_data_valid,

	output reg [C_DATA_STREAM_BIT - 1 : 0] o_master_stream_data,
	input [C_DATA_STREAM_BIT - 1: 0] i_master_stream_data,

	input S_AXI_ACLK,
	input S_AXI_ARESETN,
	input [C_S_AXI_ADDR_WIDTH - 1 : 0] S_AXI_AWADDR,
	input [2:0] S_AXI_AWPROT,
	input S_AXI_AWVALID,
	output S_AXI_AWREADY,
	input [C_S_AXI_DATA_WIDTH - 1 : 0] S_AXI_WDATA,
	input [(C_S_AXI_DATA_WIDTH / 8) - 1 : 0] S_AXI_WSTRB,
	input S_AXI_WVALID,
	output S_AXI_WREADY,
	output [1:0] S_AXI_BRESP,
	output wire S_AXI_BVALID,
	input S_AXI_BREADY,
	input [C_S_AXI_ADDR_WIDTH - 1 : 0] S_AXI_ARADDR,
	input [2 : 0] S_AXI_ARPROT,
	input S_AXI_ARVALID,
	output S_AXI_ARREADY,
	output [C_S_AXI_DATA_WIDTH - 1 : 0] S_AXI_RDATA,
	output [1 : 0] S_AXI_RRESP,
	output S_AXI_RVALID,
	input S_AXI_RREADY
);

	reg [C_S_AXI_ADDR_WIDTH - 1 : 0] axi_awaddr;
	reg axi_awready;
	reg axi_wready;
	reg [1:0] axi_bresp;
	reg axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
	reg axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
	reg [1:0] axi_rresp;
	reg axi_rvalid;

	localparam integer ADDR_LSB = 2;
	localparam integer OPT_MEM_ADDR_BITS = $clog2(C_S_AXI_ADDR_NUM) - 1;

	// slv_reg IO Type Select. 0 : Input, 1 : Output
	// slv_reg Start to LSB
	localparam [C_S_AXI_ADDR_NUM - 1 : 0] io_sel = 64'hFFFF_FFFF_FFFF_FFFF;	// 0 : Input, 1 : Output

	reg [C_S_AXI_DATA_WIDTH - 1 : 0] slv_reg[C_S_AXI_ADDR_NUM - 1 : 0];

	wire slv_reg_rden;
	wire slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
	integer byte_index;
	reg aw_en;

	genvar i;
	integer j;

	// Address Write Flag
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_awready <= 1'b0;
			aw_en <= 1'b1;
		end

		else
		begin
			if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
			begin
				axi_awready <= 1'b1;
				aw_en <= 1'b0;
			end

			else if (S_AXI_BREADY && axi_bvalid)
			begin
				aw_en <= 1'b1;
				axi_awready <= 1'b0;
			end

			else
	          axi_awready <= 1'b0;
	    end 
	end

	// Address Write
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
			axi_awaddr <= 0;

		else
		begin
			if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
				axi_awaddr <= S_AXI_AWADDR;
		end

	end

	// Write Data Flag
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
			axi_wready <= 1'b0;

		else
		begin
			if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
				axi_wready <= 1'b1;
			else
				axi_wready <= 1'b0;
		end 
	end

	// Write Data (M to S)
	generate
	for (i = 0; i < C_S_AXI_ADDR_NUM; i = i + 1)
	begin
		always @( posedge S_AXI_ACLK )
		begin
		if (io_sel[i])
		begin
			if (S_AXI_ARESETN == 1'b0)
				slv_reg[i] <= 0;

			else if (slv_reg_wren)
				if (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == i)
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
						if ( S_AXI_WSTRB[byte_index] == 1 ) 
							slv_reg[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];

			else
				slv_reg[i] <= slv_reg[i];
			end
		end
	end
	endgenerate

	// Response Flag
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_bvalid  <= 0;
			axi_bresp   <= 2'b0;
		end

		else
		begin
			if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
			begin
				axi_bvalid <= 1'b1;
				axi_bresp  <= 2'b0;
			end

			else
			begin
				if (S_AXI_BREADY && axi_bvalid) 
					axi_bvalid <= 1'b0; 
			end
		end
	end

	// Address Read Flag
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_arready <= 1'b0;
			axi_araddr  <= 32'b0;
		end

		else
		begin
			if (~axi_arready && S_AXI_ARVALID)
			begin
				axi_arready <= 1'b1;
				axi_araddr  <= S_AXI_ARADDR;
			end

			else
				axi_arready <= 1'b0;
		end
	end

	// Read Data Flag
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_rvalid <= 0;
			axi_rresp  <= 0;
		end 

		else
		begin
			if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
			begin
				axi_rvalid <= 1'b1;
				axi_rresp  <= 2'b0;
			end

			else if (axi_rvalid && S_AXI_RREADY)
				axi_rvalid <= 1'b0;
		end
	end

	// Read Data (S to M)
	always @(*)
	begin
		reg_data_out = 0;

		for (j = 0; j < C_S_AXI_ADDR_NUM; j = j + 1)
			if (axi_araddr[ADDR_LSB + OPT_MEM_ADDR_BITS : ADDR_LSB] == j)
				reg_data_out = slv_reg[j];
	end

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
			axi_rdata  <= 0;

		else
		begin
			if (slv_reg_rden)
				axi_rdata <= reg_data_out;
		end
	end

	// Output
	always @(posedge S_AXI_ACLK)
	begin
		if (slv_reg[0][0])
		begin
			o_sfp_m_en 		<= slv_reg[0][0];
			o_pwm_en		<= slv_reg[0][1];

			o_c_factor 		<= slv_reg[1];
			o_v_factor 		<= slv_reg[2];
			o_zynq_status 	<= slv_reg[3][15:0];
			o_zynq_ver		<= slv_reg[3][31:16];
			o_set_c			<= slv_reg[4];
			o_set_v			<= slv_reg[5];
			o_p_gain_c		<= slv_reg[6];
			o_i_gain_c		<= slv_reg[7];
			o_d_gain_c		<= slv_reg[8];
			o_p_gain_v		<= slv_reg[9];
			o_i_gain_v		<= slv_reg[10];
			o_d_gain_v		<= slv_reg[11];
			o_max_duty		<= slv_reg[12];
			o_max_phase		<= slv_reg[13];
			o_max_freq		<= slv_reg[14];
			o_min_freq		<= slv_reg[15];
			o_min_c			<= slv_reg[16];
			o_max_c			<= slv_reg[17];
			o_min_v			<= slv_reg[18];
			o_max_v			<= slv_reg[19];
			o_deadband		<= slv_reg[20][15:0];
			o_sw_freq		<= slv_reg[20][31:16];
		end

		else
		begin
			o_sfp_m_en 			<= 0;
			o_pwm_en			<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 1) +: 1];

			o_c_factor 			<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 22) +: 32];
			o_v_factor 			<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 24) +: 32];
			o_master_pi_param 	<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 26) +: 32];
			o_zynq_status 		<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 2) +: 16];
			o_zynq_ver			<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 3) +: 16];
			o_max_duty			<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 4) +: 32];
			o_max_phase			<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 6) +: 32];
			o_max_freq			<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 8) +: 32];
			o_min_freq			<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 10) +: 32];
			o_min_c				<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 12) +: 32];
			o_max_c				<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 14) +: 32];
			o_min_v				<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 16) +: 32];
			o_max_v				<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 18) +: 32];
			o_deadband			<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 20) +: 16];
			o_sw_freq			<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (16 * 21) +: 16];
		end
	end

	// SFP Send Data Stream
	always @(posedge S_AXI_ACLK)
	begin
		if (slv_reg[0][0])
			o_master_stream_data <= {	i_slave_pi_param_1, slv_reg[63], slv_reg[62], slv_reg[61], slv_reg[60], slv_reg[59], slv_reg[58],
										slv_reg[57], slv_reg[56], slv_reg[55], slv_reg[54], slv_reg[53], slv_reg[52], slv_reg[51],

										i_slave_pi_param_2, slv_reg[50], slv_reg[49], slv_reg[48], slv_reg[47], slv_reg[46], slv_reg[45],
										slv_reg[44], slv_reg[43], slv_reg[42], slv_reg[41], slv_reg[40], slv_reg[39], slv_reg[38],

										i_slave_pi_param_3, slv_reg[37], slv_reg[36], slv_reg[35], slv_reg[34], slv_reg[33], slv_reg[32],
										slv_reg[31], slv_reg[30], slv_reg[29], slv_reg[28], slv_reg[27], slv_reg[26], slv_reg[25]			};

		else
			o_master_stream_data <= (i_master_stream_data << (C_DATA_FRAME_BIT * 2)) + 
										{i_v_adc_data, i_c_adc_data, i_zynq_intl, i_dsp_ver, i_dsp_status, 16'b0000_0000_1111_1111};
	end

	// Input
	always @(posedge S_AXI_ACLK)
	begin
		slv_reg[64][0]		<= i_pwm_en;

		slv_reg[65]			<= i_c_adc_data;
		slv_reg[66]			<= i_v_adc_data;
		slv_reg[67][15:0]	<= i_dsp_status;
		slv_reg[67][31:16]	<= i_dsp_ver;
		slv_reg[68]			<= i_wf_read_cnt;
	end

	// SFP Receive Data Stream
	always @(posedge S_AXI_ACLK)
	begin
		if ((i_axi_data_valid) && (slv_reg[0][0]))
		begin
			// Slave 3
			slv_reg[108]		<= i_master_stream_data[(32 * 1) -: 32];
			slv_reg[109]		<= i_master_stream_data[(32 * 2) -: 32];
			slv_reg[110]		<= i_master_stream_data[(32 * 3) -: 32];
			slv_reg[111]		<= i_master_stream_data[(32 * 4) -: 32];

			// Slave 2
			slv_reg[116]		<= i_master_stream_data[(C_DATA_FRAME_BIT * 1) + (32 * 1) -: 32];
			slv_reg[117]		<= i_master_stream_data[(C_DATA_FRAME_BIT * 1) + (32 * 2) -: 32];
			slv_reg[118]		<= i_master_stream_data[(C_DATA_FRAME_BIT * 1) + (32 * 3) -: 32];
			slv_reg[119]		<= i_master_stream_data[(C_DATA_FRAME_BIT * 1) + (32 * 4) -: 32];

			// Slave 1
			slv_reg[124]		<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (32 * 1) -: 32];
			slv_reg[125]		<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (32 * 2) -: 32];
			slv_reg[126]		<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (32 * 3) -: 32];
			slv_reg[127]		<= i_master_stream_data[(C_DATA_FRAME_BIT * 2) + (32 * 4) -: 32];
		end
	end

	// User logic ends

	assign S_AXI_AWREADY = axi_awready;
	assign S_AXI_WREADY = axi_wready;
	assign S_AXI_BRESP = axi_bresp;
	assign S_AXI_BVALID = axi_bvalid;
	assign S_AXI_ARREADY = axi_arready;
	assign S_AXI_RDATA = axi_rdata;
	assign S_AXI_RRESP = axi_rresp;
	assign S_AXI_RVALID = axi_rvalid;

	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

endmodule