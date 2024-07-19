`timescale 1 ns / 1 ps

/*

MPS INTerLock Module
개발 4팀 전경원 차장

24.07.04 :	최초 생성

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - 

1. o_intl_state
 - 16 Bit
 - Interlock 상태를 EPICS와 DSP로 보내줌

 0	: 외부 인터락 입력 1
 1	: 외부 인터락 입력 2
 2	: 외부 인터락 입력 3
 3	: 외부 인터락 입력 4

 4	: 제어보드 OC
 5	: 전력보드 OC (POC)
 6	: 전력보드 OV
 7	: 전력보드 OH (Over Heat) 사용 안함

 8	: S/W UV (DC-Link Under Voltage)
 9	: S/W OV
 10	: S/W OC

 15 : System Reset Monitor

2. i_intl_ctrl (삭제 - AXI Module에서 분할함)
 - 16 Bit
 - Interlock 관련 명령 및 데이터
 - From. EPICS

 0	: 외부 인터락 출력 1
 1	: 외부 인터락 출력 2
 2	: 외부 인터락 출력 3
 3	: 외부 인터락 출력 4

 4	: OC Reset
 5	: POC Reset

 8	: 외부 인터락 입력 1 Bypass
 9	: 외부 인터락 입력 2 Bypass
 10	: 외부 인터락 입력 3 Bypass
 11	: 외부 인터락 입력 4 Bypass

3. 검토 사항
 - OSC, REG는 SBC 타입이고 나머지는 TCC 타입임

*/

module INTL
(
	input i_clk,
	input i_rst,

	// External Interlock Input
	input i_intl_ext1,
	input i_intl_ext2,
	input i_intl_ext3,
	input i_intl_ext4,

	input i_intl_ext_bypass1,
	input i_intl_ext_bypass2,
	input i_intl_ext_bypass3,
	input i_intl_ext_bypass4,

	// H/W Interlock
	input i_intl_OC,
	input i_intl_POC,
	input i_intl_OV,
	input i_intl_OH,

	// Reset
	input i_sys_rst_flag,
	input i_intl_rst,

	// ADC
	input [15:0] i_dc_adc_data,
	input [31:0] i_c_adc_raw_data,
	input [31:0] i_v_adc_raw_data,

	input [31:0] i_intl_OC_p,
	input [31:0] i_intl_OC_n,
	input [31:0] i_intl_OV_p,
	input [31:0] i_intl_OV_n,
	input [15:0] i_intl_UV,
	input i_mps_polarity,

	// Current Oscillation
	input i_intl_OSC_bypass,
	input [31:0] i_c_intl_OSC_adc_threshold,
	input [9:0]	i_c_intl_OSC_count_threshold,
	input [19:0] i_intl_OSC_period,				// Count Cycle Period. Max 1,048,576 = 5,242,880 ns
	input [9:0] i_intl_OSC_cycle_count,			// Count Cycle Periode * i_intl_OSC_cycle_count = Total Cycle. Max 1024
	
	// Interlock State
	output reg [15:0] o_intl_state
);

	parameter IDLE		= 0;
	parameter OSC_RUN	= 1;
	parameter OSC_COUNT	= 2;
	parameter OSC_RESET	= 3;

	// FSM
	reg [1:0] state;
	reg [1:0] n_state;

	// Interlock Flag
	wire intl_UV;
	wire intl_OV;
	wire intl_OC;
	reg c_intl_OSC;
	reg v_intl_OSC;

	// Counter
	reg [19:0] intl_OSC_period_cnt;
	reg [9:0] intl_OSC_cycle_cnt;

	// Oscillation
	wire [31:0] c_adc_sbc_raw_data;
	reg [31:0] c_intl_OSC_adc_max;
	reg [31:0] c_intl_OSC_adc_min;
	reg [9:0] c_intl_OSC_cnt;

	wire [31:0] v_adc_sbc_raw_data;
	reg [31:0] v_intl_OSC_adc_max;
	reg [31:0] v_intl_OSC_adc_min;
	reg [9:0] v_intl_OSC_cnt;

	// FSM Control
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            state <= IDLE;

        else 
            state <= n_state;
    end

	// FSM
	always @(*)
    begin
        case (state)
            IDLE :
            begin
                if (~c_intl_OSC && ~v_intl_OSC)
                    n_state <= OSC_RUN;

                else
                    n_state <= IDLE;
            end

			OSC_RUN :
            begin
                if (intl_OSC_period_cnt == i_intl_OSC_period)
                    n_state <= OSC_COUNT;

				else if (c_intl_OSC || v_intl_OSC)
					n_state <= IDLE;

                else
                    n_state <= OSC_RUN;
            end

			OSC_COUNT :
				n_state <= OSC_RESET;
            
			OSC_RESET:
			begin
                if (intl_OSC_cycle_cnt == i_intl_OSC_cycle_count)
                    n_state <= IDLE;

				else if (c_intl_OSC || v_intl_OSC)
					n_state <= IDLE;

				else
					n_state <= OSC_RUN;
            end
                
		endcase
	end

	/////////////////////////////////////////////////////////////////////////////
	// OSC Control //
	
	// OSC Period Counter
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst) 
        	intl_OSC_period_cnt <= 0;

		else if (state == OSC_RUN)
			intl_OSC_period_cnt <= intl_OSC_period_cnt + 1;

		else
			intl_OSC_period_cnt <= 0;
	end

	// OSC Cycle Counter
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst || (state == IDLE)) 
        	intl_OSC_cycle_cnt <= 0;

		else if (state == OSC_COUNT)
			intl_OSC_cycle_cnt <= intl_OSC_cycle_cnt + 1;

		else
			intl_OSC_cycle_cnt <= intl_OSC_cycle_cnt;
	end

	/////////////////////////////////////////////////////////////////////////////

	/////////////////////////////////////////////////////////////////////////////
	// OSC Current //

	// OSC ADC Data Min Calc
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst || (state == IDLE) || (state == OSC_RESET))
			c_intl_OSC_adc_min <= 0;

		else if (state == OSC_RUN)
		begin
			if (c_intl_OSC_adc_min < c_adc_sbc_raw_data)
				c_intl_OSC_adc_min <= c_adc_sbc_raw_data;
			
			else
				c_intl_OSC_adc_min <= c_intl_OSC_adc_min;
		end

		else
			c_intl_OSC_adc_min <= c_intl_OSC_adc_min;
	end

	// OSC ADC Data Max Calc
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst || (state == IDLE) || (state == OSC_RESET))
			c_intl_OSC_adc_max <= 0;

		else if (state == OSC_RUN)
		begin
			if (c_intl_OSC_adc_max < c_adc_sbc_raw_data)
				c_intl_OSC_adc_max <= c_adc_sbc_raw_data;
			
			else
				c_intl_OSC_adc_max <= c_intl_OSC_adc_max;
		end

		else
			c_intl_OSC_adc_max <= c_intl_OSC_adc_max;
	end

	// OSC ADC Data ABS, Interlock Count
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst || (state == IDLE))
			c_intl_OSC_cnt <= 0;

		else if (state == OSC_COUNT)
		begin
			if ((c_intl_OSC_adc_max - c_intl_OSC_adc_min) >= i_c_intl_OSC_adc_threshold)
				c_intl_OSC_cnt <= c_intl_OSC_cnt + 1;
			
			else if ((c_intl_OSC_adc_max - c_intl_OSC_adc_min) < i_c_intl_OSC_adc_threshold)
			begin
				if (c_intl_OSC_cnt == 0)
					c_intl_OSC_cnt <= c_intl_OSC_cnt;

				else
					c_intl_OSC_cnt <= c_intl_OSC_cnt - 1;
			end
		end
	end

	// OSC Current Interlock
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst || i_intl_rst)
			c_intl_OSC <= 0;

		else if (c_intl_OSC_cnt >= i_intl_OSC_cycle_count)
			c_intl_OSC <= 1;

		else
			c_intl_OSC <= c_intl_OSC;
	end

	/////////////////////////////////////////////////////////////////////////////

	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst) 
        	o_intl_state <= 0;
			
		else
		begin
			o_intl_state[0] <= ~(i_intl_ext_bypass1 ^ i_intl_ext1);
			o_intl_state[1] <= ~(i_intl_ext_bypass2 ^ i_intl_ext2);
			o_intl_state[2] <= ~(i_intl_ext_bypass3 ^ i_intl_ext3);
			o_intl_state[3] <= ~(i_intl_ext_bypass4 ^ i_intl_ext4);

			o_intl_state[4] <= i_intl_OC;
			o_intl_state[5] <= i_intl_POC;
			o_intl_state[6] <= ~i_intl_OV;
			o_intl_state[7] <= ~i_intl_OH;

			o_intl_state[8] <= intl_UV;
			o_intl_state[9] <= intl_OV;
			o_intl_state[10] <= intl_OC;

			o_intl_state[15] <= ~i_sys_rst_flag;
    	end
	end

	assign intl_UV = 	(i_dc_adc_data < i_intl_UV) ? 1 : 0;
	assign intl_OV = 	((i_intl_OV_p < i_v_adc_raw_data) || 
						((i_mps_polarity) && (i_v_adc_raw_data < i_intl_OV_n))) ? 1 : 0;
	assign intl_OC = 	((i_intl_OC_p < i_c_adc_raw_data) || 
						((i_mps_polarity) && (i_c_adc_raw_data < i_intl_OC_n))) ? 1 : 0;

	assign c_adc_sbc_raw_data = {~i_c_adc_raw_data[31], i_c_adc_raw_data[30:0]};
endmodule