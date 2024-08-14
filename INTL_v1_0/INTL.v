`timescale 1 ns / 1 ps

/*

MPS INTerLock Module
개발 4팀 전경원 차장

24.07.04 :	최초 생성
24.07.19 : 	OSC Interlock 추가
24.07.22 :	REGU Interlock 추가

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

 11	: OSC 전류 인터락
 12	: OSC 전압 인터락
 13	: REGU 전류 인터락
 14	: REGU 전류 인터락

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

3. Oscillation Interlock
 - 출력이 발진될 때 동작
 - 2의 보수로 구성된 ADC Data를 ADC IP에서 16번 더한 값을 기준으로 동작함
 - 따라서 ADC Data를 Offset Binary를 취하여 계산
 - 계산 방법은 MSB를 반전시킴 (27번째 Bit. 16번 더함으로 4개의 Bit가 << 됨. 따라서 27Bit임)

4. Regulation Interlock
 - 출력 값을 입력한 후 동작
 - 출력 값 변경 후 일정시간 지난 뒤에 설정한 출력 값까지 실제 출력 값에 맞지 않는 경우 발생
 - 출력의 모드에 따라서 동작함 (C.C or C.V)

5. 검토 사항
 - OSC, REGU는 Offset Binary 타입이고 나머지는 TCC 타입임
 - REGU 관련 time, diff 값은 비트 수 조절해야함

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
	input i_intl_rst,							// OSC, REGU Interlock Reset

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

	// Oscillation (OSC)
	input i_intl_OSC_bypass,
	input [31:0] i_c_intl_OSC_adc_threshold,
	input [9:0]	i_c_intl_OSC_count_threshold,
	input [31:0] i_v_intl_OSC_adc_threshold,
	input [9:0]	i_v_intl_OSC_count_threshold,
	input [19:0] i_intl_OSC_period,				// Count Cycle Period. Max 1,048,576 = 5,242,880 ns
	input [9:0] i_intl_OSC_cycle_count,			// Count Cycle Periode * i_intl_OSC_cycle_count = Total Period. Max 1024
	
	// REGulation (REGU)
	input i_intl_REGU_mode,						// Output Mode (0 : C.C or 1 : C.V)
	input i_intl_REGU_bypass,
	input i_c_intl_REGU_sp_flag,				// Output Set Flag (REGU Start)
	input i_v_intl_REGU_sp_flag,
	input [31:0] i_c_intl_REGU_sp,				// Output Set Value
	input [31:0] i_c_intl_REGU_diff,			// Regulation Differential Threashold
	input [31:0] i_c_intl_REGU_delay,			// Regulation Delay Time
	input [31:0] i_v_intl_REGU_sp,
	input [31:0] i_v_intl_REGU_diff,
	input [31:0] i_v_intl_REGU_delay,

	// Interlock State
	output reg [15:0] o_intl_state
);

	parameter OSC_IDLE	= 0;
	parameter OSC_RUN	= 1;
	parameter OSC_COUNT	= 2;
	parameter OSC_RESET	= 3;

	parameter REGU_IDLE	= 0;
	parameter REGU_DELAY	= 1;
	parameter REGU_RUN	= 2;
	parameter REGU_DONE	= 3;

	// FSM
	reg [1:0] OSC_state;
	reg [1:0] OSC_n_state;

	reg [1:0] REGU_state;
	reg [1:0] REGU_n_state;

	// Interlock Flag
	wire intl_UV;
	wire intl_OV;
	wire intl_OC;
	reg c_intl_OSC;
	reg v_intl_OSC;
	reg c_intl_REGU;
	reg v_intl_REGU;

	// Counter
	reg [19:0] intl_OSC_period_cnt;
	reg [9:0] intl_OSC_cycle_cnt;
	reg [31:0] intl_REGU_cnt;

	// OSC
	wire [31:0] c_adc_sbc_raw_data;
	reg [31:0] c_intl_OSC_adc_max;
	reg [31:0] c_intl_OSC_adc_min;
	reg [9:0] c_intl_OSC_cnt;

	wire [31:0] v_adc_sbc_raw_data;
	reg [31:0] v_intl_OSC_adc_max;
	reg [31:0] v_intl_OSC_adc_min;
	reg [9:0] v_intl_OSC_cnt;

	// REGU
	wire [31:0] c_intl_REGU_abs;
	wire [31:0] v_intl_REGU_abs;

	// OSC FSM Control
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            OSC_state <= OSC_IDLE;

        else 
            OSC_state <= OSC_n_state;
    end

	// REGU FSM Control
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            REGU_state <= REGU_IDLE;

        else 
            REGU_state <= REGU_n_state;
    end

	// OSC FSM
	always @(*)
    begin
        case (OSC_state)
            OSC_IDLE :
            begin
                if ((~c_intl_OSC && ~v_intl_OSC) && ~i_intl_OSC_bypass)
                    OSC_n_state <= OSC_RUN;

                else
                    OSC_n_state <= OSC_IDLE;
            end

			OSC_RUN :
            begin
                if (intl_OSC_period_cnt == i_intl_OSC_period)
                    OSC_n_state <= OSC_COUNT;

				else if (c_intl_OSC || v_intl_OSC)
					OSC_n_state <= OSC_IDLE;

                else
                    OSC_n_state <= OSC_RUN;
            end

			OSC_COUNT :
				OSC_n_state <= OSC_RESET;
            
			OSC_RESET:
			begin
                if (intl_OSC_cycle_cnt == i_intl_OSC_cycle_count + 1)		// OSC_COUNT에서 1을 미리 더하기 때문에 + 1을 해줌
                    OSC_n_state <= OSC_IDLE;

				else if (c_intl_OSC || v_intl_OSC)
					OSC_n_state <= OSC_IDLE;

				else
					OSC_n_state <= OSC_RUN;
            end
		endcase
	end

	// REGU FSM
	always @(*)
    begin
        case (REGU_state)
            REGU_IDLE :
            begin
                if ((i_c_intl_REGU_sp_flag || i_v_intl_REGU_sp_flag) && ~(c_intl_REGU || v_intl_REGU) && ~i_intl_REGU_bypass)
                    REGU_n_state <= REGU_DELAY;

                else
                    REGU_n_state <= REGU_IDLE;
            end

			REGU_DELAY :
            begin
				if (i_intl_REGU_mode)
					if (intl_REGU_cnt == i_v_intl_REGU_delay)
						REGU_n_state <= REGU_RUN;

					else
						REGU_n_state <= REGU_DELAY;
				
				else
					if (intl_REGU_cnt == i_c_intl_REGU_delay)
						REGU_n_state <= REGU_RUN;

					else
						REGU_n_state <= REGU_DELAY;
            end

			REGU_RUN :
                REGU_n_state <= REGU_DONE;

			REGU_DONE :
            begin
                if (~i_c_intl_REGU_sp_flag && ~i_v_intl_REGU_sp_flag)
                    REGU_n_state <= REGU_IDLE;

                else
                    REGU_n_state <= REGU_DONE;
            end
		endcase
	end


	/***** Counter Control *****/
	
	// OSC Period Counter
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst) 
        	intl_OSC_period_cnt <= 0;

		else if (OSC_state == OSC_RUN)
			intl_OSC_period_cnt <= intl_OSC_period_cnt + 1;

		else
			intl_OSC_period_cnt <= 0;
	end

	// OSC Cycle Counter
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst || (OSC_state == OSC_IDLE)) 
        	intl_OSC_cycle_cnt <= 0;

		else if (OSC_state == OSC_COUNT)
			intl_OSC_cycle_cnt <= intl_OSC_cycle_cnt + 1;

		else
			intl_OSC_cycle_cnt <= intl_OSC_cycle_cnt;
	end

	// REGU Delay Counter
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst) 
        	intl_REGU_cnt <= 0;

		else if (REGU_state == REGU_DELAY)
			intl_REGU_cnt <= intl_REGU_cnt + 1;

		else
			intl_REGU_cnt <= 0;
	end

	/***** Current OSC  *****/

	// OSC ADC Data Min Calc
	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			c_intl_OSC_adc_min <= 0;

		else if ((OSC_state == OSC_IDLE) || (OSC_state == OSC_RESET))
			c_intl_OSC_adc_min <= c_adc_sbc_raw_data;

		else if (OSC_state == OSC_RUN)
		begin
			if (c_adc_sbc_raw_data < c_intl_OSC_adc_min)
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
    	if (~i_rst)
			c_intl_OSC_adc_max <= 0;

		else if ((OSC_state == OSC_IDLE) || (OSC_state == OSC_RESET))
			c_intl_OSC_adc_max <= c_adc_sbc_raw_data;

		else if (OSC_state == OSC_RUN)
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
    	if (~i_rst || (OSC_state == OSC_IDLE))
			c_intl_OSC_cnt <= 0;

		else if (OSC_state == OSC_COUNT)
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

		else if (c_intl_OSC_cnt >= i_c_intl_OSC_count_threshold)
			c_intl_OSC <= 1;

		else
			c_intl_OSC <= c_intl_OSC;
	end

	/***** Voltage OSC  *****/

	// OSC ADC Data Min Calc
	always @(posedge i_clk or negedge i_rst) 
	begin
		if (~i_rst)
			v_intl_OSC_adc_min <= 0;

		else if ((OSC_state == OSC_IDLE) || (OSC_state == OSC_RESET))
			v_intl_OSC_adc_min <= v_adc_sbc_raw_data;

		else if (OSC_state == OSC_RUN)
		begin
			if (v_adc_sbc_raw_data < v_intl_OSC_adc_min)
				v_intl_OSC_adc_min <= v_adc_sbc_raw_data;
			
			else
				v_intl_OSC_adc_min <= v_intl_OSC_adc_min;
		end

		else
			v_intl_OSC_adc_min <= v_intl_OSC_adc_min;
	end

	// OSC ADC Data Max Calc
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst)
			v_intl_OSC_adc_max <= 0;

		else if ((OSC_state == OSC_IDLE) || (OSC_state == OSC_RESET))
			v_intl_OSC_adc_max <= v_adc_sbc_raw_data;

		else if (OSC_state == OSC_RUN)
		begin
			if (v_intl_OSC_adc_max < v_adc_sbc_raw_data)
				v_intl_OSC_adc_max <= v_adc_sbc_raw_data;
			
			else
				v_intl_OSC_adc_max <= v_intl_OSC_adc_max;
		end

		else
			v_intl_OSC_adc_max <= v_intl_OSC_adc_max;
	end

	// OSC ADC Data ABS, Interlock Count
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst || (OSC_state == OSC_IDLE))
			v_intl_OSC_cnt <= 0;

		else if (OSC_state == OSC_COUNT)
		begin
			if ((v_intl_OSC_adc_max - v_intl_OSC_adc_min) >= i_v_intl_OSC_adc_threshold)
				v_intl_OSC_cnt <= v_intl_OSC_cnt + 1;
			
			else if ((v_intl_OSC_adc_max - v_intl_OSC_adc_min) < i_v_intl_OSC_adc_threshold)
			begin
				if (v_intl_OSC_cnt == 0)
					v_intl_OSC_cnt <= v_intl_OSC_cnt;

				else
					v_intl_OSC_cnt <= v_intl_OSC_cnt - 1;
			end
		end
	end

	// OSC Current Interlock
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst || i_intl_rst)
			v_intl_OSC <= 0;

		else if (v_intl_OSC_cnt >= i_v_intl_OSC_count_threshold)
			v_intl_OSC <= 1;

		else
			v_intl_OSC <= v_intl_OSC;
	end

	/***** REGU *****/

	// REGU Interlock
	always @(posedge i_clk or negedge i_rst) 
	begin
    	if (~i_rst || i_intl_rst)
		begin
			v_intl_REGU <= 0;
			c_intl_REGU <= 0;
		end

		else if (REGU_state == REGU_RUN)
		begin
			if (i_intl_REGU_mode)
			begin
				if (v_intl_REGU_abs > i_v_intl_REGU_diff)
				begin
					v_intl_REGU <= 1;
					c_intl_REGU <= c_intl_REGU;
				end
					
				else
				begin
					v_intl_REGU <= v_intl_REGU;
					c_intl_REGU <= c_intl_REGU;
				end
			end

			else
			begin
				if (c_intl_REGU_abs > i_c_intl_REGU_diff)
				begin
					v_intl_REGU <= v_intl_REGU;
					c_intl_REGU <= 1;
				end
					
				else
				begin
					v_intl_REGU <= v_intl_REGU;
					c_intl_REGU <= c_intl_REGU;
				end
					
			end
		end

		else
		begin
			v_intl_REGU <= v_intl_REGU;
			c_intl_REGU <= c_intl_REGU;
		end
	end


	/***** Interlock State *****/

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

			o_intl_state[11] <= c_intl_OSC;
			o_intl_state[12] <= v_intl_OSC;
			o_intl_state[13] <= c_intl_REGU;
			o_intl_state[14] <= v_intl_REGU;

			o_intl_state[15] <= ~i_sys_rst_flag;
    	end
	end

	assign intl_UV = 	(i_dc_adc_data < i_intl_UV) ? 1 : 0;
	assign intl_OV = 	((i_intl_OV_p < i_v_adc_raw_data) || 
						((i_mps_polarity) && (i_v_adc_raw_data < i_intl_OV_n))) ? 1 : 0;
	assign intl_OC = 	((i_intl_OC_p < i_c_adc_raw_data) || 
						((i_mps_polarity) && (i_c_adc_raw_data < i_intl_OC_n))) ? 1 : 0;

	assign c_adc_sbc_raw_data = {~i_c_adc_raw_data[27], i_c_adc_raw_data[26:0]};
	assign v_adc_sbc_raw_data = {~i_v_adc_raw_data[27], i_v_adc_raw_data[26:0]};

	assign c_intl_REGU_abs = (i_c_intl_REGU_sp > c_adc_sbc_raw_data) ? 
							i_c_intl_REGU_sp - c_adc_sbc_raw_data : c_adc_sbc_raw_data - i_c_intl_REGU_sp;
	assign v_intl_REGU_abs = (i_v_intl_REGU_sp > v_adc_sbc_raw_data) ? 
							i_v_intl_REGU_sp - v_adc_sbc_raw_data : v_adc_sbc_raw_data - i_v_intl_REGU_sp;
endmodule