`timescale 1 ns / 1 ps

/*

MPS DSP Module
개발 4팀 전경원 차장

24.06.10 :	최초 생성
24.07.08 :	DPBRAM Test용 AXI 추가
			위의 이유로 인하여 Zynq에서 DPBRAM에 접근하는 Port 수정
			- AXI4_Lite_S01 수정
			- DSP_XINTF 수정

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - 수정 많이 해야함

1. DSP_XINTF
 1.1 공통
  - DSP는 외부 인터페이스 (eXternal INTFace)를 이용해서 Zynq의 DPBRAM에 접근하여 데이터를 R/W
  - i_DSP_intr로 FSM 시작
  - 통신은 10us의 주기
  - DPBRAM M은 Zynq Port, S는 DSP Port임

 1.2 EPICS to DPBRAM (WRITE)
  - DPBRAM에 특정 주소에 값을 써줌 (index)
 
 1.3 DPBRAM to DSP (DELAY)
  - FSM가 DELAY 일 경우 데이터를 R/W
 
 1.4 DSP to DPBRAM (DELAY)
  - 1.2와 같음
 
 1.5 DPBRAM to EPICS (READ)
  - DELAY가 끝나면 DPBRAM의 데이터를 EPICS로 넘겨줌
 
2. WF_Counter
 2.1 공통
  - WF : WaveForm
  - Waveform 데이터 카운트 용
  - EPICS에서 DPBRAM으로 Waveform 데이터를 DPBRAM에 씀
  - DPBRAM의 Waveform 데이터를 읽은 후 XINTF DPBRAM에 다시 씀
  - 위의 사항으로 예상해보면 DSP가 Waveform 데이터를 읽어 감
  - 이거 필요없는 기능이라고 함 (김재오 과장)
  - 암튼 동작하면 o_addr로 1000까지 카운트하고 다시 0부터 반복
  - Flag로 0 ~ 499, 500 ~ 1000을 EPICS로 보내줌
 
3. DPBRAM
 - 아래 코드 주석 참조

*/

module DSP_v1_0_Top #
(
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_WIDTH = 8
)
(
	input i_DSP_intr,								// DSP Interrupt. Data R/W
	output o_Ready,
	output o_Hart_beat,
	output o_nMENPWM,
	input i_valid,
	input i_DSP_fail,

	input [15:0] i_INTL_state,						// Interlock State. From INTL_v1_0
	input i_DSP_nENPWM,

	// From ADC
	input [31:0] i_c_adc_data,						// Current ADC Floating Data
	input [31:0] i_v_adc_data,						// Voltage ADC Floating Data

	// Float 연산 용 Factor AXIS
	output [31:0] o_c_factor_axis_tdata,
	output o_c_factor_axis_tvalid,

	output [31:0] o_v_factor_axis_tdata,
	output o_v_factor_axis_tvalid,

	// DSP XINTF Data Line
	output o_nZ_WE,
	input i_nZ_B_WE,
    input i_nZ_B_CS,
    input [8:0] i_Z_B_XA,
    inout [15:0] io_Z_B_XD,

	output dpbram_Setup_flag,
	output [2:0] o_debug_fsm_state,

	// DPBRAM (XINTF) Bus Interface Ports Attribute
	// Dual Clock
	// M Port - Zynq / S Port - DSP
	// Address length : 9 (Depth : 500) / Data Width : 16

	// Zynq System Clock
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_DPBRAM addr0" *) output [8:0] o_xintf_PL_ram_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_DPBRAM ce0" *) output o_xintf_PL_ram_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_DPBRAM we0" *) output o_xintf_PL_ram_we,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_DPBRAM din0" *) output [15:0] o_xintf_PL_ram_din,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_DPBRAM dout0" *) input [15:0] i_xintf_PL_ram_dout,

	// DSP Clock
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_DPBRAM addr1" *) output [8:0] o_xintf_DSP_ram_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_DPBRAM ce1" *) output o_xintf_DSP_ram_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_DPBRAM we1" *) output o_xintf_DSP_ram_we,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_DPBRAM din1" *) output [15:0] o_xintf_DSP_ram_din,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_DPBRAM dout1" *) input [15:0] i_xintf_DSP_ram_dout,

	// DPBRAM (WF) Bus Interface Ports Attribute
	// M Port - PS (Write Only) / S Port - XINTF DPBRAM (Read Only)
	// Address length : 10 (Depth : 1000) / Data Width : 32
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_WF_PS_DPBRAM addr0" *) output [9:0] o_WF_PS_ram_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_WF_PS_DPBRAM ce0" *) output o_WF_PS_ram_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_WF_PS_DPBRAM we0" *) output o_WF_PS_ram_we,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_WF_PS_DPBRAM din0" *) output [31:0] o_WF_PS_ram_din,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_WF_PS_DPBRAM dout0" *) input [31:0] i_WF_PS_ram_dout,

	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_WF_DSP_DPBRAM addr1" *) output [9:0] o_WF_dsp_ram_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_WF_DSP_DPBRAM ce1" *) output o_WF_dsp_ram_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_WF_DSP_DPBRAM we1" *) output o_WF_dsp_ram_we,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_WF_DSP_DPBRAM din1" *) output [31:0] o_WF_dsp_ram_din,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_WF_DSP_DPBRAM dout1" *) input [31:0] i_WF_dsp_ram_dout,

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

	wire [31:0] WF_total_count;
    wire WF_BRAM_WE;
    wire WF_start_count;

    wire WF_reset_count;
    wire [15:0] WF_dsp;
    wire WF_mode_sel;

    wire [9:0] WF_addr;
    wire [31:0] WF_data;

    wire [15:0] Write_Index;
    wire [31:0] Write_DATA;

    wire WF_INT_0;
    wire WF_INT_500;
    wire [31:0] WF_current_count;
	wire WF_Counter_flag;

    wire [31:0] DSP_Duty;
    wire [15:0] DSP_FaultNum;
    wire [31:0] DSP_System_Status;
    wire [15:0] DSP_EIS;
    wire [31:0] DSP_RLoad;
    wire [15:0] DSP_MPS_TYPE;
    wire [31:0] DSP_SetCurrRD;
    wire [31:0] DSP_DEGCurrentRD;
    wire [31:0] DSP_DEGPeriod;
    wire [31:0] DSP_OverCurrent;
    wire [31:0] DSP_LowVoltage;
    wire [31:0] DSP_OverVoltage;
    wire [31:0] DSP_OverTemp;
    wire [31:0] DSP_CurrentHighLimit;
    wire [31:0] DSP_Vpgain;
    wire [31:0] DSP_ViGain;
    wire [31:0] DSP_CurrentPgain;
    wire [31:0] DSP_CurrentIgain;
    wire [31:0] DSP_Max_Duty;
    wire [15:0] DSP_DSP_Code;
    wire [15:0] DSP_SlewRate;
    wire [15:0] DSP_osc_state;
    wire [15:0] DSP_remote_state;
    wire [31:0] DSP_regulation_time;
    wire [31:0] DSP_Current_Factor;
    wire [31:0] DSP_Voltage_Factor;
    wire [31:0] DSP_Input_Voltage_Factor;
    wire [31:0] DSP_Current_Offset_Set;
    wire [15:0] DSP_Deadband_Set;
    wire [15:0] DSP_Dual_Offset_Deadband_Set;
    wire [31:0] DSP_PI_Max_V;
    wire [31:0] DSP_PI_Min_V;
    wire [31:0] DSP_Eruption_V;
    wire [31:0] DSP_Eruption_C;
    wire [31:0] F_DSP_ADC_C;
    wire [31:0] F_DSP_ADC_V;

	AXI4_Lite_S01 #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_S01
	(
		// Write (PS - PL)
		.o_WF_total_count(WF_total_count),
		.o_WF_BRAM_WE(WF_BRAM_WE),
		.o_WF_start_count(WF_start_count),
		.o_WF_reset_count(WF_reset_count),
		.o_WF_mode_sel(WF_mode_sel),
		.o_WF_addr(WF_addr),
		.o_WF_data(WF_data),
        .o_WF_dsp(WF_dsp),
		.o_Ready(o_Ready),
        .o_Hart_beat(o_Hart_beat),
		.o_c_factor(o_c_factor_axis_tdata),
		.o_v_factor(o_v_factor_axis_tdata),
		.o_Write_Index(Write_Index),
		.o_Write_DATA(Write_DATA),

		// Read (PL - PS)
		.i_WF_INT_0(WF_INT_0),
		.i_WF_INT_500(WF_INT_500),
		.i_WF_current_count(WF_current_count),
		.i_valid(i_valid),
        .i_DSP_fail(i_DSP_fail),
        .i_DSP_nENPWM(i_DSP_nENPWM),
		.i_Float_ADC_C(i_c_adc_data),
		.i_Float_ADC_V(i_v_adc_data),
		.i_DSP_Duty(DSP_Duty),
		.i_DSP_FaultNum(DSP_FaultNum),
		.i_DSP_System_Status(DSP_System_Status),
		.i_DSP_EIS(DSP_EIS),
		.i_DSP_RLoad(DSP_RLoad),
		.i_DSP_MPS_TYPE(DSP_MPS_TYPE),
		.i_DSP_SetCurrRD(DSP_SetCurrRD),
		.i_DSP_DEGCurrentRD(DSP_DEGCurrentRD),
		.i_DSP_DEGPeriod(DSP_DEGPeriod),
		.i_DSP_OverCurrent(DSP_OverCurrent),
		.i_DSP_LowVoltage(DSP_LowVoltage),
		.i_DSP_OverVoltage(DSP_OverVoltage),
		.i_DSP_OverTemp(DSP_OverTemp),
		.i_DSP_CurrentHighLimit(DSP_CurrentHighLimit),
		.i_DSP_Vpgain(DSP_Vpgain),
		.i_DSP_ViGain(DSP_ViGain),
		.i_DSP_CurrentPgain(DSP_CurrentPgain),
		.i_DSP_CurrentIgain(DSP_CurrentIgain),
		.i_DSP_Max_Duty(DSP_Max_Duty),
		.i_DSP_DSP_Code(DSP_DSP_Code),
		.i_DSP_SlewRate(DSP_SlewRate),
		.i_DSP_osc_state(DSP_osc_state),
		.i_DSP_remote_state(DSP_remote_state),
		.i_DSP_regulation_time(DSP_regulation_time),
		.i_DSP_Current_Factor(DSP_Current_Factor),
		.i_DSP_Voltage_Factor(DSP_Voltage_Factor),
		.i_DSP_Input_Voltage_Factor(DSP_Input_Voltage_Factor),
		.i_DSP_Current_Offset_Set(DSP_Current_Offset_Set),
		.i_DSP_Deadband_Set(DSP_Deadband_Set),
		.i_DSP_Dual_Offset_Deadband_Set(DSP_Dual_Offset_Deadband_Set),
		.i_DSP_PI_Max_V(DSP_PI_Max_V),
		.i_DSP_PI_Min_V(DSP_PI_Min_V),
		.i_DSP_Eruption_V(DSP_Eruption_V),
		.i_DSP_Eruption_C(DSP_Eruption_C),
		.i_F_DSP_ADC_C(F_DSP_ADC_C),
		.i_F_DSP_ADC_V(F_DSP_ADC_V),

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

	DSP_XINTF
	u_DSP_XINTF
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),

		.i_DSP_intr(i_DSP_intr),
		.i_INTL_state(i_INTL_state),

		.i_Write_Index(Write_Index),
		.i_Write_DATA(Write_DATA),
		.i_WF_dsp(WF_dsp),
		.i_WF_data(i_WF_dsp_ram_dout),

		.i_xintf_PL_ram_dout(i_xintf_PL_ram_dout),
		.o_xintf_PL_ram_addr(o_xintf_PL_ram_addr),
		.o_xintf_PL_ram_ce(o_xintf_PL_ram_ce),
		.o_xintf_PL_ram_we(o_xintf_PL_ram_we),
		.o_xintf_PL_ram_din(o_xintf_PL_ram_din),

		.i_c_adc_data(i_c_adc_data),
		.i_v_adc_data(i_v_adc_data),

		.o_DSP_Duty(DSP_Duty),
        .o_DSP_FaultNum(DSP_FaultNum),
        .o_DSP_System_Status(DSP_System_Status),
        .o_DSP_EIS(DSP_EIS),
        .o_DSP_R_Load(DSP_RLoad),
        .o_DSP_MPS_TYPE(DSP_MPS_TYPE),
        .o_DSP_SetCurrRD(DSP_SetCurrRD),
        .o_DSP_DEGCurrentRD(DSP_DEGCurrentRD),
        .o_DSP_DEGPeriod(DSP_DEGPeriod),
        .o_DSP_OverCurrent(DSP_OverCurrent),
        .o_DSP_LowVoltage(DSP_LowVoltage),
        .o_DSP_OverVoltage(DSP_OverVoltage),
        .o_DSP_OverTemp(DSP_OverTemp),
        .o_DSP_CurrentHighLimit(DSP_CurrentHighLimit),
        .o_DSP_Vpgain(DSP_Vpgain),
        .o_DSP_ViGain(DSP_ViGain),
        .o_DSP_CurrentPgain(DSP_CurrentPgain),
        .o_DSP_CurrentIgain(DSP_CurrentIgain),
        .o_DSP_Max_Duty(DSP_Max_Duty),
        .o_DSP_DSP_Code(DSP_DSP_Code),
        .o_DSP_SlewRate(DSP_SlewRate),
        .o_DSP_osc_state(DSP_osc_state),
        .o_DSP_remote_state(DSP_remote_state),
        .o_DSP_regulation_time(DSP_regulation_time),
        .o_DSP_Current_Factor(DSP_Current_Factor),
        .o_DSP_Voltage_Factor(DSP_Voltage_Factor),
        .o_DSP_Input_Voltage_Factor(DSP_Input_Voltage_Factor),
        .o_DSP_Current_Offset_Set(DSP_Current_Offset_Set),
        .o_DSP_Deadband_Set(DSP_Deadband_Set),
        .o_DSP_Dual_Offset_Deadband_Set(DSP_Dual_Offset_Deadband_Set),
        .o_DSP_PI_Max_V(DSP_PI_Max_V),
        .o_DSP_PI_Min_V(DSP_PI_Min_V),
        .o_DSP_Eruption_V(DSP_Eruption_V),
        .o_DSP_Eruption_C(DSP_Eruption_C),
        .o_F_DSP_ADC_C(F_DSP_ADC_C),
        .o_F_DSP_ADC_V(F_DSP_ADC_V),

		.o_WF_Counter_flag(WF_Counter_flag),
		.o_debug_fsm_state(o_debug_fsm_state),
		.dpbram_Setup_flag(dpbram_Setup_flag)
	);

	WF_Counter
	u_WF_Counter
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),

		.i_ps_rst(~WF_reset_count),
		.i_start_count(WF_start_count),
		.i_mode_sel(WF_mode_sel),
		.i_total_count(WF_total_count),
		.o_current_count(WF_current_count),

		.o_WF_INT_0(WF_INT_0),
		.o_WF_INT_500(WF_INT_500),

		.o_cs(o_WF_dsp_ram_ce),
		.o_addr(o_WF_dsp_ram_addr),

		.i_WF_Counter_flag(WF_Counter_flag)
	);

assign o_nMENPWM = i_DSP_nENPWM; 

assign o_c_factor_axis_tvalid = 1;
assign o_v_factor_axis_tvalid = 1;

assign o_nZ_WE = ~o_xintf_PL_ram_we;
assign o_xintf_DSP_ram_addr = i_Z_B_XA;
assign o_xintf_DSP_ram_ce = ~i_nZ_B_CS;
assign o_xintf_DSP_ram_we = ~i_nZ_B_WE;
assign o_xintf_DSP_ram_din = io_Z_B_XD;
assign io_Z_B_XD = (o_xintf_DSP_ram_we) ? 16'hZZZZ : i_xintf_DSP_ram_dout;

assign o_WF_PS_ram_addr = WF_addr;
assign o_WF_PS_ram_ce = WF_BRAM_WE;
assign o_WF_PS_ram_we = WF_BRAM_WE;
assign o_WF_PS_ram_din = WF_data;
assign o_WF_dsp_ram_we = 0;

endmodule