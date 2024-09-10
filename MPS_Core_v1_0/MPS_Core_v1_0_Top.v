`timescale 1 ns / 1 ps

/*
0. PS가 
    Interlock State. From INTL_v1_0인 i_INTL_state는 AXI로 PS가 읽어가게만 설정함
    o_Ready, o_Hart_beat 핀 만들기만 해놓음
	SFP Handler 추가 해야함
*/

module MPS_Core_v1_0_Top #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_NUM = 128,
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2,

	parameter integer C_AXIS_TDATA_WIDTH = 64,		// Frame Data Width
	parameter integer C_NUMBER_OF_SLAVE = 3,		// Slave 수
	parameter integer C_NUMBER_OF_FRAME = 7,		// Slave의 Frame 수

	parameter integer C_DATA_STREAM_BIT = ((C_AXIS_TDATA_WIDTH) * (C_NUMBER_OF_SLAVE) * (C_NUMBER_OF_FRAME)),	// Stream Bit 수
	parameter integer C_DATA_FRAME_BIT = ((C_AXIS_TDATA_WIDTH) * (C_NUMBER_OF_FRAME))					// Frame Bit 수
)
(
	input [15:0] i_zynq_intl,						// Interlock Input
	input i_pwm_en,									// PWM Enable (AND Gate IP)
	output o_pwm_en,

    // From ADC
	input [31:0] i_c_adc_data,						// Current ADC Floating Data
	input [31:0] i_v_adc_data,						// Voltage ADC Floating Data

    // Float 연산 용 Factor AXIS
	output [31:0] o_c_factor_axis_tdata,
	output o_c_factor_axis_tvalid,

	output [31:0] o_v_factor_axis_tdata,
	output o_v_factor_axis_tvalid,

	// SFP Data
	output [C_DATA_STREAM_BIT - 1 : 0] o_stream_data,
	input [C_DATA_STREAM_BIT - 1 : 0] i_stream_data,

	// SFP Flag
	output o_aurora_tx_start_flag,				// SFP Tx 시작
	input i_aurora_rx_end_flag,					// SFP Rx 종료

    // DPBRAM (XINTF) Bus Interface Ports Attribute
	// Address length : 9 (Depth : ) / Data Width : 16
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM addr0" *) output [8:0] o_xintf_w_ram_addr,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM ce0" *) output o_xintf_w_ram_ce,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM we0" *) output o_xintf_w_ram_we,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM din0" *) output [15:0] o_xintf_w_ram_din,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM dout0" *) input [15:0] i_xintf_w_ram_dout,

    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 S_XINTF_R_DPBRAM addr1" *) output [8:0] o_xintf_r_ram_addr,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 S_XINTF_R_DPBRAM ce1" *) output o_xintf_r_ram_ce,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 S_XINTF_R_DPBRAM we1" *) output o_xintf_r_ram_we,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 S_XINTF_R_DPBRAM din1" *) output [15:0] o_xintf_r_ram_din,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 S_XINTF_R_DPBRAM dout1" *) input [15:0] i_xintf_r_ram_dout,

    // AXI4 Lite Bus Interface Ports
	input wire  s00_axi_aclk,
    input wire  s00_axi_aresetn,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire  s00_axi_awvalid,
    output wire  s00_axi_awready,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire  s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire  s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire  s00_axi_arvalid,
    output wire  s00_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire  s00_axi_rvalid,
    input wire  s00_axi_rready,

    // Debugging
    output [1:0] o_debug_r_state,
    output [1:0] o_debug_w_state,
    output [8:0] o_W_addr_pointer,
    output [8:0] o_R_addr_pointer
);
	wire sfp_m_en;
	wire pwm_en;
	wire zynq_intl;
	wire axi_data_valid;

    wire [15:0] zynq_status;
	wire [15:0] o_zynq_ver;
    wire [31:0] set_c;
    wire [31:0] set_v;
    wire [31:0] p_gain_c;
    wire [31:0] i_gain_c;
    wire [31:0] d_gain_c;
    wire [31:0] p_gain_v;
    wire [31:0] i_gain_v;
    wire [31:0] d_gain_v;
    wire [31:0] max_duty;
    wire [31:0] max_phase;
    wire [31:0] max_freq;
    wire [31:0] min_freq;
    wire [15:0] deadband;
    wire [15:0] sw_freq;
    wire [31:0] max_c;
    wire [31:0] min_c;
	wire [31:0] max_v;
    wire [31:0] min_v;
    wire [31:0] master_pi_param;

    wire [15:0] dsp_status;
	wire [15:0] i_dsp_ver;
	wire [31:0] slave_pi_param_1;
	wire [31:0] slave_pi_param_2;
	wire [31:0] slave_pi_param_3;
	wire [31:0] wf_read_cnt;

	wire [(C_NUMBER_OF_FRAME * C_AXIS_TDATA_WIDTH) * C_NUMBER_OF_SLAVE : 0] rx_axi_data;
	wire [(C_NUMBER_OF_FRAME * C_AXIS_TDATA_WIDTH) * C_NUMBER_OF_SLAVE : 0] tx_axi_data;

	AXI4_Lite_S01 #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),

		.C_DATA_STREAM_BIT(C_DATA_STREAM_BIT),
		.C_DATA_FRAME_BIT(C_DATA_FRAME_BIT)
	)
	u_AXI4_Lite_S01
	(
		// ADC Calc Factor
		.o_c_factor(o_c_factor_axis_tdata),
		.o_v_factor(o_v_factor_axis_tdata),

		// ADC Data
		.i_c_adc_data(i_c_adc_data),
        .i_v_adc_data(i_v_adc_data),

		// System Control
		.o_sfp_m_en(sfp_m_en),
		.i_pwm_en(i_pwm_en),
		.o_pwn_en(o_pwm_en),
		.i_zynq_intl(i_zynq_intl),

		// DPBRAM Write
        .o_zynq_status(zynq_status),
		.o_zynq_firmware_ver(o_zynq_ver),
        .o_set_c(set_c),
        .o_set_v(set_v),
        .o_p_gain_c(p_gain_c),
        .o_i_gain_c(i_gain_c),
        .o_d_gain_c(d_gain_c),
        .o_p_gain_v(p_gain_v),
        .o_i_gain_v(i_gain_v),
        .o_d_gain_v(d_gain_v),
        .o_max_duty(max_duty),
        .o_max_phase(max_phase),
        .o_max_freq(max_freq),
        .o_min_freq(min_freq),
		.o_max_c(max_c),
        .o_min_c(min_c),
        .o_max_v(max_v),
        .o_min_v(min_v),
		.o_deadband(deadband),
        .o_sw_freq(sw_freq),

		// DPBRAM Read
        .i_dsp_status(dsp_status),
		.i_dsp_firmware_ver(i_dsp_ver),
		.i_wf_read_cnt(wf_read_cnt),

		// SFP Data
		.i_slave_pi_param_1(slave_pi_param_1),			// Slave PI Parameter Receive to DSP (SFP Master Mode)
		.i_slave_pi_param_2(slave_pi_param_2),
		.i_slave_pi_param_3(slave_pi_param_3),
		.o_master_stream_data(tx_axi_data),				// SFP Master Mode Data to Slave
		.i_msater_stream_data(rx_axi_data),				// SFP Master Mode Data from Slave
		.o_master_pi_param(master_pi_param),
		.i_axi_data_valid(axi_data_valid),

		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

    DSP_Handler
	u_DSP_Handler
	(
        .i_clk(s00_axi_aclk),
        .i_rst(s00_axi_aresetn),

        .i_sfp_m_en(sfp_m_en),
		.i_i_zynq_intl(zynq_intl),

        // DPBRAM WRITE
        .o_xintf_w_ram_addr(o_xintf_w_ram_addr),
        .o_xintf_w_ram_din(o_xintf_w_ram_din),
		.o_xintf_w_ram_ce(o_xintf_w_ram_ce),

        .i_c_adc_data(i_c_adc_data),
        .i_v_adc_data(i_v_adc_data),
        .i_zynq_status(zynq_status),
		.i_zynq_firmware_ver(o_zynq_ver),
		.i_set_c(set_c),
        .i_set_v(set_v),
        .i_p_gain_c(p_gain_c),
        .i_i_gain_c(i_gain_c),
        .i_d_gain_c(d_gain_c),
        .i_p_gain_v(p_gain_v),
        .i_i_gain_v(i_gain_v),
        .i_d_gain_v(d_gain_v),
        .i_max_duty(max_duty),
        .i_max_phase(max_phase),
        .i_max_freq(max_freq),
        .i_min_freq(min_freq),
        .i_max_v(max_v),
        .i_min_v(min_v),
        .i_max_c(max_c),
        .i_min_c(min_c),
		.i_master_pi_param(master_pi_param),			// Master PI Parameter Send to DSP (SFP Slave Mode)
		.i_deadband(deadband),
        .i_sw_freq(sw_freq),

        // DPBRAM READ
        .i_xintf_r_ram_dout(i_xintf_r_ram_dout),
        .o_xintf_r_ram_addr(o_xintf_r_ram_addr),
		.o_xintf_r_ram_ce(o_xintf_r_ram_ce),

        .o_dsp_status(dsp_status),
		.o_dsp_firmware_ver(i_dsp_ver),
		.o_wf_read_cnt(wf_read_cnt),
		.o_slave_pi_param_1(slave_pi_param_1),			// Slave PI Parameter Receive to DSP (SFP Master Mode)
		.o_slave_pi_param_2(slave_pi_param_2),
		.o_slave_pi_param_3(slave_pi_param_3),

        // Debugging
        .o_debug_r_state(o_debug_r_state),
        .o_debug_w_state(o_debug_w_state),
        .o_R_addr_pointer(o_R_addr_pointer),
        .o_W_addr_pointer(o_W_addr_pointer)
    );

	SFP_Handler #
	(
		.C_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),
		.C_DATA_STREAM_BIT(C_DATA_STREAM_BIT),
		.C_DATA_FRAME_BIT(C_DATA_FRAME_BIT)
	)
	u_SFP_Handler
	(
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_axi_data(tx_axi_data),
		.o_axi_data(rx_axi_data),

		.i_stream_data(i_stream_data),
		.o_stream_data(o_stream_data),

		.i_sfp_end_flag(i_aurora_rx_end_flag),
		.o_sfp_start_flag(o_aurora_tx_start_flag),

		.o_axi_data_valid(axi_data_valid),
		.i_sfp_m_en(sfp_m_en)
	);

    assign o_c_factor_axis_tvalid = 1;
    assign o_v_factor_axis_tvalid = 1;

    assign o_xintf_w_ram_we = 1;
    assign o_xintf_r_ram_we = 0;

	assign zynq_intl = (i_zynq_intl != 0);

endmodule