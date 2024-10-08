`timescale 1 ns / 1 ps

module AXI4_Lite_S01 #
(
	parameter integer C_S_AXI_DATA_WIDTH	= 0,
	parameter integer C_S_AXI_ADDR_NUM 		= 0,
	parameter integer C_S_AXI_ADDR_WIDTH	= 0,

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
	output reg			o_pwm_en,
	input				i_dsp_sfp_en,
	input				i_tx_en,
	output 				o_sfp_start_flag,
	input 				i_sfp_end_flag,

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

	// SFP PI Parameter
	input [31:0]		i_slave_pi_param_1,
	input [31:0]		i_slave_pi_param_2,
	input [31:0]		i_slave_pi_param_3,
	output reg [31:0]	o_master_pi_param,
	input 				i_axi_data_valid,

	output reg [C_DATA_FRAME_BIT - 1 : 0] o_master_stream_data,
	input [C_DATA_FRAME_BIT - 1: 0] i_master_stream_data,

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

	// Address Write (AW) Flag
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

	// Address Write (AW)
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

	// Write Data Flag (W)
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

	// Response Flag (B)
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

	// Address Read Flag (AR)
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

	// Read Data Flag (R)
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

	// USer Code Here

	localparam M_TX_IDLE = 0;
	localparam M_TX_ZYNQ_DATA_SET = 1;
	localparam M_TX_ZYNQ_EN = 2;
	localparam M_TX_ZYNQ_DONE = 3;
	localparam M_TX_DSP_DATA_SET = 4;
	localparam M_TX_DSP_EN = 5;
	localparam M_TX_DSP_DONE = 6;

	localparam M_RX_IDLE = 0;
	localparam M_RX_RUN = 1;
	localparam M_RX_DONE = 2;

	localparam S_TX_IDLE = 0;
	localparam S_TX_STAT_DATA_SET = 1;
	localparam S_TX_PASS_DATA_SET = 2;
	localparam S_TX_EN = 3;
	localparam S_TX_DONE = 4;

	localparam S_RX_IDLE = 0;
	localparam S_RX_RUN = 1;
	localparam S_RX_PASS = 2;
	localparam S_RX_INSERT = 3;
	localparam S_RX_DONE = 4;

	reg [2:0] m_tx_state;
	reg [2:0] m_rx_state;
	reg [2:0] s_tx_state;
	reg [2:0] s_rx_state;

	wire sfp_master;				// SFP Master Mode Flag. sfp_id == 0이면 Master
	reg zynq_sfp_en;				// PS용 SFP Start Flag
	reg [15:0] sfp_id;				// Master 및 Slave 장비 번호 지정. 16비트는 Stream Data에 편하게 넣을려고 만듬
	wire [31:0] slave_state;		// Slave State
	reg [9:0] slave_sfp_state_cnt;	// Slave SFP Start Counter. 1us로 설정함
	wire [15:0] cmd;				// Slave Command
	wire [15:0] slv_id;				// Slave가 Master에 데이터 보내줄때 지정하는 Slave 장비 번호
	wire [31:0] data_1;
	wire [31:0] data_2;
	wire [31:0] data_3;

	reg [7:0] m_tx_fsm_cnt;			// SFP TX 이후 무한루프 방지용 Counter. 100ns
	reg [7:0] s_tx_fsm_cnt;

	// Timeout Count
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
		if (!S_AXI_ARESETN)
			m_tx_fsm_cnt <= 0;

		else if ((m_tx_state == M_TX_ZYNQ_DONE) || (m_tx_state == M_TX_DSP_DONE))
			m_tx_fsm_cnt <= m_tx_fsm_cnt + 1;

		else
			m_tx_fsm_cnt <= 0;

	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
		if (!S_AXI_ARESETN)
			s_tx_fsm_cnt <= 0;

		else if (s_tx_state == S_TX_DONE)
			s_tx_fsm_cnt <= s_tx_fsm_cnt + 1;

		else
			s_tx_fsm_cnt <= 0;

	end

	// SFP Master TX
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
		if (!S_AXI_ARESETN)
			m_tx_state <= M_TX_IDLE;

		else
		begin
			case (m_tx_state)
				M_TX_IDLE :
				begin
					if (zynq_sfp_en && sfp_master)
						m_tx_state <= M_TX_ZYNQ_DATA_SET;

					else if (i_dsp_sfp_en && sfp_master)
						m_tx_state <= M_TX_DSP_DATA_SET;

					else
						m_tx_state <= M_TX_IDLE;
				end

				// Zynq Procedure
				M_TX_ZYNQ_DATA_SET :
					m_tx_state <= M_TX_ZYNQ_EN;

				M_TX_ZYNQ_EN :
					m_tx_state <= M_TX_ZYNQ_DONE;

				M_TX_ZYNQ_DONE :
				begin
					if ((i_tx_en || (m_tx_fsm_cnt >= 20)) && !(zynq_sfp_en))
						m_tx_state <= M_TX_IDLE;

					else
						m_tx_state <= M_TX_ZYNQ_DONE;
				end


				// DSP Procedure
				M_TX_DSP_DATA_SET :
					m_tx_state <= M_TX_DSP_EN;

				M_TX_DSP_EN :
					m_tx_state <= M_TX_DSP_DONE;

				M_TX_DSP_DONE :
				begin
					if ((i_tx_en || (m_tx_fsm_cnt >= 20)) && !(zynq_sfp_en))
							m_tx_state <= M_TX_IDLE;

					else
						m_tx_state <= M_TX_DSP_DONE;
				end
			endcase
		end
	end

	// SFP Master RX
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
		if (!S_AXI_ARESETN)
			m_rx_state <= M_RX_IDLE;

		else
		begin
			case (m_rx_state)
				M_RX_IDLE :
				begin
					if (i_sfp_end_flag && (sfp_master))
						m_rx_state <= M_RX_RUN;

					else
						m_rx_state <= M_RX_IDLE;
				end

				M_RX_RUN :
					m_rx_state <= M_RX_DONE;

				M_RX_DONE :
					m_rx_state <= M_RX_IDLE;
			endcase
		end
	end

	// SFP Slave TX
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
		if (!S_AXI_ARESETN)
			s_tx_state <= S_TX_IDLE;

		else
		begin
			case (s_tx_state)
				S_TX_IDLE :
				begin
					if ((slave_sfp_state_cnt == 199) && !sfp_master)
						s_tx_state <= S_TX_STAT_DATA_SET;

					else if ((s_rx_state == S_RX_PASS) && !sfp_master)	// !! S_RX_PASS 신호가 들어오면 동작함
						s_tx_state <= S_TX_PASS_DATA_SET;

					else
						s_tx_state <= S_TX_IDLE;
				end

				S_TX_STAT_DATA_SET :
					s_tx_state <= S_TX_EN;

				S_TX_PASS_DATA_SET :
					s_tx_state <= S_TX_EN;

				S_TX_EN :
					s_tx_state <= S_TX_DONE;

				S_TX_DONE :
				begin
					if (i_tx_en || (s_tx_fsm_cnt >= 20))
						s_tx_state <= S_TX_IDLE;

					else
						s_tx_state <= S_TX_DONE;
				end
			endcase
		end
	end

	// SFP Slave RX
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
		if (!S_AXI_ARESETN)
			s_rx_state <= S_RX_IDLE;

		else
		begin
			case (s_rx_state)
				S_RX_IDLE :
				begin
					if (i_sfp_end_flag && !sfp_master)
						s_rx_state <= S_RX_RUN;

					else
						s_rx_state <= S_RX_IDLE;
				end

				S_RX_RUN :
				begin
					if (slv_id != sfp_id)
						s_rx_state <= S_RX_PASS;

					else
						s_rx_state <= S_RX_INSERT;
				end
				
				S_RX_PASS :								// Slave가 자신의 데이터가 아닐 시 다른 장비로 데이터 전달
				begin
					if (s_tx_state == S_TX_EN)			// !! S_TX_EN 신호가 들어오면 Clear
						s_rx_state <= S_RX_DONE;

					else
						s_rx_state <= S_RX_PASS;
				end

				S_RX_INSERT :							// Slave가 자신의 데이터일 경우 적용 
					s_rx_state <= S_RX_DONE;

				S_RX_DONE :
					s_rx_state <= S_RX_IDLE;
			endcase
		end
	end

	// DSP Write DPBRAM
	always @(posedge S_AXI_ACLK)
	begin
		if (sfp_id != 0)	// Slave Mode
		begin
			if (s_rx_state == S_RX_INSERT)
			begin
				case (cmd)
					1 : o_pwm_en <= data_3[0];

					2 : 
					begin 
						o_c_factor <= data_2;
						o_v_factor <= data_3;
					end

					3 : 
					begin
						o_zynq_status <= data_2;
						o_zynq_ver	<= data_3;
					end

					4 : 
					begin
						o_max_duty <= data_2;
						o_max_phase <= data_3;
					end

					5 : 
					begin
						o_max_freq <= data_2;
						o_min_freq <= data_3;
					end

					6 : 
					begin
						o_min_c <= data_2;
						o_max_c <= data_3;
					end

					7 : 
					begin
						o_min_v <= data_2;
						o_max_v <= data_3;
					end

					8 : 
					begin
						o_deadband <= data_2;
						o_sw_freq <= data_3;
					end
				endcase
			end
		end

		else				// Master Mode
		begin
			o_pwm_en		<= slv_reg[0][2];
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

	end

	// Slave 용 PI Parameter RX. PASS 상태로 되지만 cmd가 0일 경우
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
		if (!S_AXI_ARESETN)
			o_master_pi_param <= 0;

		else if (s_rx_state == S_RX_PASS)
			if (cmd == 0)
				o_master_pi_param <= i_master_stream_data[(32 * sfp_id) - 1 -: 32];

		else
			o_master_pi_param <= o_master_pi_param;
	end

	// Slave Status RX Counter
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
		if (!S_AXI_ARESETN)
			slave_sfp_state_cnt <= 0;

		else if (s_tx_state == S_TX_IDLE)
			slave_sfp_state_cnt <= slave_sfp_state_cnt + 1;

		else if (slave_sfp_state_cnt == 200)
			slave_sfp_state_cnt <= 0;

		else
			slave_sfp_state_cnt <= slave_sfp_state_cnt;
	end

	// SFP Control
	always @(posedge S_AXI_ACLK)
	begin
		sfp_id 			<= slv_reg[0][1:0];
		zynq_sfp_en		<= slv_reg[0][3];
	end

	// SFP TX Data
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
		if (!S_AXI_ARESETN)
			o_master_stream_data <= 0;

		else if (m_tx_state == M_TX_ZYNQ_DATA_SET)		// Master Send Data
			o_master_stream_data <= {slv_reg[63][15:0], slv_reg[62][15:0], slv_reg[61], slv_reg[60], slv_reg[59]};
			
		else if (m_tx_state == M_TX_DSP_DATA_SET)		// Master Send PI Parameter
			o_master_stream_data <= {16'h0000_0000_0000_0000, 16'h0000_0000_0000_0000, i_slave_pi_param_3, i_slave_pi_param_2, i_slave_pi_param_1};

		else if (s_tx_state == S_TX_STAT_DATA_SET)		// Slave Send Status
			o_master_stream_data <= {16'h0000_0000_0000_1111, sfp_id, slave_state, i_c_adc_data, i_v_adc_data};

		else if (s_tx_state == S_TX_PASS_DATA_SET)		// Slave Send Pass Data
			o_master_stream_data <= i_master_stream_data;

		else
			o_master_stream_data <= o_master_stream_data;
	end

	// Master Received Slave Status Data
	always @(posedge S_AXI_ACLK)
	begin
		if ((m_rx_state == M_RX_RUN) && (cmd == 16'h0000_0000_0000_1111))
		begin
			if (slv_id == 1)
			begin
				slv_reg[119] <= data_1;
				slv_reg[120] <= data_2;
				slv_reg[121] <= data_3;
			end

			else if (slv_id == 2)
			begin
				slv_reg[122] <= data_1;
				slv_reg[123] <= data_2;
				slv_reg[124] <= data_3;
			end

			else if (slv_id == 3)
			begin
				slv_reg[125] <= data_1;
				slv_reg[126] <= data_2;
				slv_reg[127] <= data_3;
			end
		end
	end

	// Zynq, DSP Data
	always @(posedge S_AXI_ACLK)
	begin
		slv_reg[65]			<= i_c_adc_data;
		slv_reg[66]			<= i_v_adc_data;
		slv_reg[67][15:0]	<= i_dsp_status;
		slv_reg[67][31:16]	<= i_dsp_ver;
	end

	assign sfp_master = (sfp_id == 0);
	assign o_sfp_start_flag = ((m_tx_state == M_TX_ZYNQ_EN) || (m_tx_state == M_TX_DSP_EN) || (s_tx_state == S_TX_EN));

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
	
	assign cmd = i_master_stream_data[127:112];
	assign slv_id = i_master_stream_data[111:96];
	assign data_1 = i_master_stream_data[95:64];
	assign data_2 = i_master_stream_data[63:32];
	assign data_3 = i_master_stream_data[31:0];

endmodule