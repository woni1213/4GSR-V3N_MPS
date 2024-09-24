`timescale 1 ns / 1 ps

/*

MPS MPS Core Module

개발 4팀 전경원 차장
개발 4팀 김선경 사원

24.09.10 :	최초 생성

24.09.24 :	WF 삭제. 다른 IP로 이동. WF_Counter(wf_read_cnt)는 존재함
			DSP에서 DPBRAM으로 해당 Count값이 오기 때문임
			WF Count 값 Output 생성. WF IP로 전달

1. 개요
 - 기존의 DSP_v1_0을 대체함
 - DSP와 Zynq간 Handler
 - SFP Control 구현 (AXI4_Lite에 포함)
 - Slave는 최대 3개까지 구현을 하였으며 추가가 될 경우 DSP에서 보내는 PI Parameter의 Protocol을 수정해야하며 나머지는 수정없이 적용 가능하다.
 - ADC, DSP Control Data, SFP
 - Protocol 및 데이터 등은 구글 시트를 참조한다.

2. DSP
 - DSP와의 통신은 DPBRAM을 이용한다.
 - Read와 Write용 DPBRAM을 구분하여 DSP to Zynq, Zynq to DSP를 별도로(2가지 FSM) 관리한다.
 - 기존 코드와 다르게 주기적(100KHz)으로 데이터를 교체하는 것이 아닌 실시간으로 데이터를 입력한다.
 - SFP Master(sfp_m_en)일 경우에만 Write FSM이 동작한다.

3. SFP
 - AXI4_Lite_S01.v에 포함되어있다.
 - PS가 Master 및 Slave를 선택(sfp_id)하며 Slave시 장비의 번호(slv_id)를 지정하여야 한다.
 - 총 4개의 FSM으로 구성되어 있으며 Master와 Slave 별 R/W로 구성된다. (M_TX, M_RX, S_TX, S_RX)
 
 3.1 Master
  3.1.1 TX
   - Master TX의 경우 2가지 타입으로 전송된다.
   - PS에서 각 Slave별로 다양한 Parameter를 보내며
   - DSP에서 전체 Slave로 PI 제어용 Parameter를 보낸다.

  3.1.2 RX
   - 각 Slave가 보내는 데이터를 처리한다.
   - CMD 영역이 0x000F일 경우에만 데이터를 PS로 보내주며
   - 나머지는 무시한다.

 3.2 Slave
  3.2.1 TX
   - Slave의 TX도 2가지 타입으로 전송된다.
   - 본 장비의 데이터가 아닐 경우 다른 장비로 전송되는 PASS 신호와
   - 주기적(1us)으로 보내는 상태값 및 I, V 값으로 구성된다.
   - PASS의 신호는 Slave RX에서 명령(S_RX_PASS)을 받는다.

  3.2.2 RX
   - RX의 경우에는 본 장비의 데이터일 경우 데이터를 적용(S_RX_INSERT)한다.
   - 데이터의 적용은 AXI4_Lite를 대신해서 값을 적용한다는 개념이다.
   - Master의 DSP가 각 Slave의 PI제어 값(i_slave_pi_param_x)을 연산하기 때문에 Set값이나 Gain값은 무시된다.
   - 만약 본 장비의 데이터가 아닐 경우 다른 장비로 전달(S_RX_PASS)한다.

4. AXI4-Lite
 - Slave Reg의 수가 많아져서 배열로 수정함.
 - 내부적으로 사용되는 ADDR_LSB 및 OPT_MEM_ADDR_BITS 등도 함께 수정하였음
 - 자세한건 Custom IP의 AXI4_Lite_Array 파일 주석 참조

*/
module MPS_Core_v1_0_Top #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,								// AXI4-Lite Data Width
	parameter integer C_S_AXI_ADDR_NUM = 128,								// AXI4-Lite Slave Reg Number
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2,	// AXI4-Lite Address

	parameter integer C_AXIS_TDATA_WIDTH = 64,								// Frame Data Width (Aurora 64B/66B)
	parameter integer C_NUMBER_OF_FRAME = 2,								// Slave의 Frame 수

	parameter integer C_DATA_FRAME_BIT = ((C_AXIS_TDATA_WIDTH) * (C_NUMBER_OF_FRAME))	// 전체 Frame Bit 수
)
(
	input i_zynq_intl,							// Interlock Input. from INTL IP
	output o_pwm_en,							// PWM Enable. to INTL IP
	input i_dsp_sfp_en,							// SFP Send Flag used by DSP. to DSP (MXTMP2)
	input i_tx_en,								// from AXIS FRAME IP
	output [31:0] o_wf_read_cnt,				// Waveform Read Count. to WF IP

    // From ADC
	input [31:0] i_c_adc_data,					// Current ADC Data (Data Type : Float)
	input [31:0] i_v_adc_data,					// Voltage ADC Data (Data Type : Float)

    // Float 연산 용 Factor AXIS
	output [31:0] o_c_factor_axis_tdata,
	output o_c_factor_axis_tvalid,

	output [31:0] o_v_factor_axis_tdata,
	output o_v_factor_axis_tvalid,

	// SFP Data
	output [C_DATA_FRAME_BIT - 1 : 0] o_stream_data,
	input [C_DATA_FRAME_BIT - 1 : 0] i_stream_data,

	// SFP Flag
	output o_aurora_tx_start_flag,				// SFP Tx 시작
	input i_aurora_rx_end_flag,					// SFP Rx 종료

    // DPBRAM (XINTF) Bus Interface Ports Attribute
	// DPBRAM Write / Address length : 6 (Depth : 43) / Data Width : 16
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM addr0" *) output [8:0] o_xintf_w_ram_addr,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM ce0" *) output o_xintf_w_ram_ce,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM we0" *) output o_xintf_w_ram_we,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM din0" *) output [15:0] o_xintf_w_ram_din,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_W_DPBRAM dout0" *) input [15:0] i_xintf_w_ram_dout,

	// DPBRAM Read / Address length : 4 (Depth : 10) / Data Width : 16
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM addr1" *) output [8:0] o_xintf_r_ram_addr,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM ce1" *) output o_xintf_r_ram_ce,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM we1" *) output o_xintf_r_ram_we,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM din1" *) output [15:0] o_xintf_r_ram_din,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_R_DPBRAM dout1" *) input [15:0] i_xintf_r_ram_dout,

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
    input wire  s00_axi_rready
);
	wire pwm_en;
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

	AXI4_Lite_S01 #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),

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
		.o_pwm_en(o_pwm_en),
		.i_dsp_sfp_en(i_dsp_sfp_en),
		.i_tx_en(i_tx_en),
		.o_sfp_start_flag(o_aurora_tx_start_flag),
		.i_sfp_end_flag(i_aurora_rx_end_flag),

		// DPBRAM Write
        .o_zynq_status(zynq_status),
		.o_zynq_ver(o_zynq_ver),
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
		.i_dsp_ver(i_dsp_ver),

		// SFP Data
		.i_slave_pi_param_1(slave_pi_param_1),			// Slave PI Parameter Receive to DSP (SFP Master Mode)
		.i_slave_pi_param_2(slave_pi_param_2),
		.i_slave_pi_param_3(slave_pi_param_3),
		.o_master_stream_data(o_stream_data),			// SFP Master Mode Data to Slave
		.i_master_stream_data(i_stream_data),			// SFP Master Mode Data from Slave
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

		.i_zynq_intl(i_zynq_intl),

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
		.o_wf_read_cnt(o_wf_read_cnt),
		.o_slave_pi_param_1(slave_pi_param_1),			// Slave PI Parameter Receive to DSP (SFP Master Mode)
		.o_slave_pi_param_2(slave_pi_param_2),
		.o_slave_pi_param_3(slave_pi_param_3)
    );

    assign o_c_factor_axis_tvalid = 1;
    assign o_v_factor_axis_tvalid = 1;

    assign o_xintf_w_ram_we = 1;
    assign o_xintf_r_ram_we = 0;

	assign o_xintf_wf_ram_ce = 1;
	assign o_xintf_wf_ram_we = 1;

endmodule