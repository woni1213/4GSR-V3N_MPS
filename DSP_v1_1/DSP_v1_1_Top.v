/*
0. PS가 
    Interlock State. From INTL_v1_0인 i_INTL_state는 AXI로 PS가 읽어가게만 설정함
    o_Ready, o_Hart_beat 핀 만들기만 해놓음
*/
module DSP_v1_1_Top #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_WIDTH = 8
)
(
    input i_Ethernet_connect,                       // 1 : Master / 0 : Slave
    input [15:0] i_INTL_state,						// Interlock State. From INTL_v1_0

    output o_Ready,
	output o_Hart_beat,
	output o_nMENPWM,
	input i_valid,
	input i_DSP_fail,

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

    // DPBRAM (XINTF) Bus Interface Ports Attribute
	// Dual Clock
	// M Port - Zynq / S Port - DSP
	// Address length : 9 (Depth : 500) / Data Width : 16

    // Zynq System Clock
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_W_DPBRAM addr0" *) output [8:0] o_xintf_PL_W_ram_addr,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_W_DPBRAM ce0" *) output o_xintf_PL_W_ram_ce,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_W_DPBRAM we0" *) output o_xintf_PL_W_ram_we,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_W_DPBRAM din0" *) output [15:0] o_xintf_PL_W_ram_din,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_W_DPBRAM dout0" *) input [15:0] i_xintf_PL_W_ram_dout,

    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_R_DPBRAM addr1" *) output [8:0] o_xintf_DSP_R_ram_addr,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_R_DPBRAM ce1" *) output o_xintf_DSP_R_ram_ce,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_R_DPBRAM we1" *) output o_xintf_DSP_R_ram_we,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_R_DPBRAM din1" *) output [15:0] o_xintf_DSP_R_ram_din,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_R_DPBRAM dout1" *) input [15:0] i_xintf_DSP_R_ram_dout,

    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_R_DPBRAM addr0" *) output [8:0] o_xintf_PL_R_ram_addr,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_R_DPBRAM ce0" *) output o_xintf_PL_R_ram_ce,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_R_DPBRAM we0" *) output o_xintf_PL_R_ram_we,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_R_DPBRAM din0" *) output [15:0] o_xintf_PL_R_ram_din,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_PL_R_DPBRAM dout0" *) input [15:0] i_xintf_PL_R_ram_dout,
    
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_W_DPBRAM addr1" *) output [8:0] o_xintf_DSP_W_ram_addr,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_W_DPBRAM ce1" *) output o_xintf_DSP_W_ram_ce,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_W_DPBRAM we1" *) output o_xintf_DSP_W_ram_we,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_W_DPBRAM din1" *) output [15:0] o_xintf_DSP_W_ram_din,
    (* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 S_XINTF_DSP_W_DPBRAM dout1" *) input [15:0] i_xintf_DSP_W_ram_dout,

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
    wire [15:0] w_DSP_System_Status;
    wire [31:0] w_DSP_Set_C;
    wire [31:0] w_DSP_Set_V;
    wire [31:0] w_DSP_Current_P_Gain;
    wire [31:0] w_DSP_Current_I_Gain;
    wire [31:0] w_DSP_Current_D_Gain;
    wire [31:0] w_DSP_Voltage_P_Gain;
    wire [31:0] w_DSP_Voltage_I_Gain;
    wire [31:0] w_DSP_Voltage_D_Gain;
    wire [31:0] w_DSP_Max_Duty;
    wire [31:0] w_DSP_Max_Phase;
    wire [31:0] w_DSP_Max_Freq;
    wire [31:0] w_DSP_Min_Freq;
    wire [15:0] w_DSP_Deadband_Set;
    wire [15:0] w_DSP_Switching_Freq_Set;
    wire [31:0] w_DSP_PI_Max_V;
    wire [31:0] w_DSP_PI_Min_V;
    wire [31:0] w_DSP_PI_Max_C;
    wire [31:0] w_DSP_PI_Min_C;
    wire [31:0] w_DSP_Current_Duty;
    wire [31:0] w_DSP_Current_Phase;
    wire [31:0] w_DSP_Current_Freq;
    wire [15:0] w_DSP_Intr;
    wire [15:0] w_DSP_Firmware_Ver;

    wire [31:0] r_c_adc_data;
    wire [31:0] r_v_adc_data;
    wire [15:0] r_DSP_System_Status;
    wire [31:0] r_DSP_Set_C;
    wire [31:0] r_DSP_Set_V;
    wire [31:0] r_DSP_Current_P_Gain;
    wire [31:0] r_DSP_Current_I_Gain;
    wire [31:0] r_DSP_Current_D_Gain;
    wire [31:0] r_DSP_Voltage_P_Gain;
    wire [31:0] r_DSP_Voltage_I_Gain;
    wire [31:0] r_DSP_Voltage_D_Gain;
    wire [31:0] r_DSP_Max_Duty;
    wire [31:0] r_DSP_Max_Phase;
    wire [31:0] r_DSP_Max_Freq;
    wire [31:0] r_DSP_Min_Freq;
    wire [15:0] r_DSP_Deadband_Set;
    wire [15:0] r_DSP_Switching_Freq_Set;
    wire [31:0] r_DSP_PI_Max_V;
    wire [31:0] r_DSP_PI_Min_V;
    wire [31:0] r_DSP_PI_Max_C;
    wire [31:0] r_DSP_PI_Min_C;
    wire [31:0] r_DSP_Current_Duty;
    wire [31:0] r_DSP_Current_Phase;
    wire [31:0] r_DSP_Current_Freq;
    wire [15:0] r_DSP_Intr;
    wire [15:0] r_DSP_Firmware_Ver;
    wire [15:0] r_PI_Intr_Status;
    wire [31:0] r_WF_Counter;

	AXI4_Lite_S01 #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_S01
	(
		// Write (PS - PL)
        .o_DSP_System_Status(w_DSP_System_Status),
        .o_DSP_Set_C(w_DSP_Set_C),
        .o_DSP_Set_V(w_DSP_Set_V),
        .o_DSP_Current_P_Gain(w_DSP_Current_P_Gain),
        .o_DSP_Current_I_Gain(w_DSP_Current_I_Gain),
        .o_DSP_Current_D_Gain(w_DSP_Current_D_Gain),
        .o_DSP_Voltage_P_Gain(w_DSP_Voltage_P_Gain),
        .o_DSP_Voltage_I_Gain(w_DSP_Voltage_I_Gain),
        .o_DSP_Voltage_D_Gain(w_DSP_Voltage_D_Gain),
        .o_DSP_Max_Duty(w_DSP_Max_Duty),
        .o_DSP_Max_Phase(w_DSP_Max_Phase),
        .o_DSP_Max_Freq(w_DSP_Max_Freq),
        .o_DSP_Min_Freq(w_DSP_Min_Freq),
        .o_DSP_Deadband_Set(w_DSP_Deadband_Set),
        .o_DSP_Switching_Freq_Set(w_DSP_Switching_Freq_Set),
        .o_DSP_PI_Max_V(w_DSP_PI_Max_V),
        .o_DSP_PI_Min_V(w_DSP_PI_Min_V),
        .o_DSP_PI_Max_C(w_DSP_PI_Max_C),
        .o_DSP_PI_Min_C(w_DSP_PI_Min_C),
        .o_DSP_Current_Duty(w_DSP_Current_Duty),
        .o_DSP_Current_Phase(w_DSP_Current_Phase),
        .o_DSP_Current_Freq(w_DSP_Current_Freq),
        .o_DSP_Intr(w_DSP_Intr),
        .o_DSP_Firmware_Ver(w_DSP_Firmware_Ver),

        .o_c_factor(o_c_factor_axis_tdata),
		.o_v_factor(o_v_factor_axis_tdata),

		// Read (PL - PS)
        .i_valid(i_valid),
        .i_DSP_fail(i_DSP_fail),
        .i_DSP_nENPWM(i_DSP_nENPWM),

        .i_c_adc_data(r_c_adc_data),
        .i_v_adc_data(r_v_adc_data),
        .i_DSP_System_Status(r_DSP_System_Status),
        .i_DSP_Set_C(r_DSP_Set_C),
        .i_DSP_Set_V(r_DSP_Set_V),
        .i_DSP_Current_P_Gain(r_DSP_Current_P_Gain),
        .i_DSP_Current_I_Gain(r_DSP_Current_I_Gain),
        .i_DSP_Current_D_Gain(r_DSP_Current_D_Gain),
        .i_DSP_Voltage_P_Gain(r_DSP_Voltage_P_Gain),
        .i_DSP_Voltage_I_Gain(r_DSP_Voltage_I_Gain),
        .i_DSP_Voltage_D_Gain(r_DSP_Voltage_D_Gain),
        .i_DSP_Max_Duty(r_DSP_Max_Duty),
        .i_DSP_Max_Phase(r_DSP_Max_Phase),
        .i_DSP_Max_Freq(r_DSP_Max_Freq),
        .i_DSP_Min_Freq(r_DSP_Min_Freq),
        .i_DSP_Deadband_Set(r_DSP_Deadband_Set),
        .i_DSP_Switching_Freq_Set(r_DSP_Switching_Freq_Set),
        .i_DSP_PI_Max_V(r_DSP_PI_Max_V),
        .i_DSP_PI_Min_V(r_DSP_PI_Min_V),
        .i_DSP_PI_Max_C(r_DSP_PI_Max_C),
        .i_DSP_PI_Min_C(r_DSP_PI_Min_C),
        .i_DSP_Current_Duty(r_DSP_Current_Duty),
        .i_DSP_Current_Phase(r_DSP_Current_Phase),
        .i_DSP_Current_Freq(r_DSP_Current_Freq),
        .i_DSP_Intr(r_DSP_Intr),
        .i_DSP_Firmware_Ver(r_DSP_Firmware_Ver),
        .i_PI_Intr_Status(r_PI_Intr_Status),
        .i_WF_Counter(r_WF_Counter),
        .i_INTL_state(i_INTL_state),

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

        .i_Ethernet_connect(i_Ethernet_connect),

        // WRITE
        .o_xintf_PL_W_ram_addr(o_xintf_PL_W_ram_addr),
        .o_xintf_PL_W_ram_din(o_xintf_PL_W_ram_din),

        .i_c_adc_data(i_c_adc_data),
        .i_v_adc_data(i_v_adc_data),
        .i_DSP_System_Status(w_DSP_System_Status),
        .i_DSP_Set_C(w_DSP_Set_C),
        .i_DSP_Set_V(w_DSP_Set_V),
        .i_DSP_Current_P_Gain(w_DSP_Current_P_Gain),
        .i_DSP_Current_I_Gain(w_DSP_Current_I_Gain),
        .i_DSP_Current_D_Gain(w_DSP_Current_D_Gain),
        .i_DSP_Voltage_P_Gain(w_DSP_Voltage_P_Gain),
        .i_DSP_Voltage_I_Gain(w_DSP_Voltage_I_Gain),
        .i_DSP_Voltage_D_Gain(w_DSP_Voltage_D_Gain),
        .i_DSP_Max_Duty(w_DSP_Max_Duty),
        .i_DSP_Max_Phase(w_DSP_Max_Phase),
        .i_DSP_Max_Freq(w_DSP_Max_Freq),
        .i_DSP_Min_Freq(w_DSP_Min_Freq),
        .i_DSP_Deadband_Set(w_DSP_Deadband_Set),
        .i_DSP_Switching_Freq_Set(w_DSP_Switching_Freq_Set),
        .i_DSP_PI_Max_V(w_DSP_PI_Max_V),
        .i_DSP_PI_Min_V(w_DSP_PI_Min_V),
        .i_DSP_PI_Max_C(w_DSP_PI_Max_C),
        .i_DSP_PI_Min_C(w_DSP_PI_Min_C),
        .i_DSP_Current_Duty(w_DSP_Current_Duty),
        .i_DSP_Current_Phase(w_DSP_Current_Phase),
        .i_DSP_Current_Freq(w_DSP_Current_Freq),
        .i_DSP_Intr(w_DSP_Intr),
        .i_DSP_Firmware_Ver(w_DSP_Firmware_Ver),
        
        // READ
        .i_xintf_PL_R_ram_dout(i_xintf_PL_R_ram_dout),
        .o_xintf_PL_R_ram_addr(o_xintf_PL_R_ram_addr),

        .o_c_adc_data(r_c_adc_data),
        .o_v_adc_data(r_v_adc_data),
        .o_DSP_System_Status(r_DSP_System_Status),
        .o_DSP_Set_C(r_DSP_Set_C),
        .o_DSP_Set_V(r_DSP_Set_V),
        .o_DSP_Current_P_Gain(r_DSP_Current_P_Gain),
        .o_DSP_Current_I_Gain(r_DSP_Current_I_Gain),
        .o_DSP_Current_D_Gain(r_DSP_Current_D_Gain),
        .o_DSP_Voltage_P_Gain(r_DSP_Voltage_P_Gain),
        .o_DSP_Voltage_I_Gain(r_DSP_Voltage_I_Gain),
        .o_DSP_Voltage_D_Gain(r_DSP_Voltage_D_Gain),
        .o_DSP_Max_Duty(r_DSP_Max_Duty),
        .o_DSP_Max_Phase(r_DSP_Max_Phase),
        .o_DSP_Max_Freq(r_DSP_Max_Freq),
        .o_DSP_Min_Freq(r_DSP_Min_Freq),
        .o_DSP_Deadband_Set(r_DSP_Deadband_Set),
        .o_DSP_Switching_Freq_Set(r_DSP_Switching_Freq_Set),
        .o_DSP_PI_Max_V(r_DSP_PI_Max_V),
        .o_DSP_PI_Min_V(r_DSP_PI_Min_V),
        .o_DSP_PI_Max_C(r_DSP_PI_Max_C),
        .o_DSP_PI_Min_C(r_DSP_PI_Min_C),
        .o_DSP_Current_Duty(r_DSP_Current_Duty),
        .o_DSP_Current_Phase(r_DSP_Current_Phase),
        .o_DSP_Current_Freq(r_DSP_Current_Freq),
        .o_DSP_Intr(r_DSP_Intr),
        .o_DSP_Firmware_Ver(r_DSP_Firmware_Ver),
        .o_PI_Intr_Status(r_PI_Intr_Status),
        .o_WF_Counter(r_WF_Counter),

        // Debugging
        .o_debug_r_state(o_debug_r_state),
        .o_debug_w_state(o_debug_w_state),
        .o_R_addr_pointer(o_R_addr_pointer),
        .o_W_addr_pointer(o_W_addr_pointer)
    );

    assign o_nMENPWM = i_DSP_nENPWM;

    assign o_c_factor_axis_tvalid = 1;
    assign o_v_factor_axis_tvalid = 1;

    assign o_xintf_PL_W_ram_ce = 1;
    assign o_xintf_PL_W_ram_we = 1;

    assign o_xintf_PL_R_ram_ce = 1;
    assign o_xintf_PL_R_ram_we = 0;

    assign o_xintf_PL_R_ram_din = 0;

    assign o_nZ_WE = o_xintf_DSP_R_ram_we;

    assign o_xintf_DSP_R_ram_addr = i_Z_B_XA;
    assign o_xintf_DSP_R_ram_din = 0;
    assign o_xintf_DSP_R_ram_ce = (i_nZ_B_WE) ? ~i_nZ_B_CS : 0;
    assign o_xintf_DSP_R_ram_we = ~i_nZ_B_WE;
    assign io_Z_B_XD = (o_xintf_DSP_R_ram_ce && ~o_xintf_DSP_R_ram_we) ? i_xintf_DSP_R_ram_dout : 16'hZZZZ;

    assign o_xintf_DSP_W_ram_addr = i_Z_B_XA;
    assign o_xintf_DSP_W_ram_ce = (~i_nZ_B_WE) ? ~i_nZ_B_CS : 0;
    assign o_xintf_DSP_W_ram_we = ~i_nZ_B_WE;
    assign o_xintf_DSP_W_ram_din = io_Z_B_XD;  

endmodule