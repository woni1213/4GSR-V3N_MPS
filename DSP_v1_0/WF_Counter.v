`timescale 1 ns / 1 ps

/*

MPS WF_counter Module
개발 4팀 전경원 차장

24.06.18 :	최초 생성

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - 나중에 삭제해야할 Module
 - 과거에 DSP가 Waveform을 처리할 시절에 남아있던 코드임
 - 누누히 말하지만 이 코드는 이성진 차장 코드임. 
 - ****내가 짠거 아니고 이성진 차장 코드를 최적화한거임****
 - 난 이따구로 안짬

1. FSM
 - CYCLE_RUN이 실행되면 무한상태로 바뀜
 - 무한상태로 되면서 o_current_count가 Overflow로 무한히 반복함
 - CUSTOM_RUN은 i_total_count에 도달 시 IDLE로 돌아감

*/

module WF_counter
(
    // AXI
    input i_clk,
    input i_rst,
    
	input i_ps_rst,
    input i_start_count,					// FSM 시작
    input i_mode_sel,
    input [31:0] i_total_count,
    output reg [31:0] o_current_count,
    
    output reg o_WF_INT_0,
    output reg o_WF_INT_500,
    
    // BRAM
    output reg o_cs,
    output reg [9:0] o_addr,
    
    // FC MPS
	input i_WF_Counter_flag
);

	parameter IDLE	= 0;
	parameter READY	= 1;
	parameter CUSTOM_RUN = 2;
	parameter CYCLE_RUN	= 3;

	// FSM
	reg [1:0] state;
	reg [1:0] n_state;

	// FSM Control
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst || ~i_ps_rst)
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
                if (i_start_count)
                    n_state <= READY;

                else
                    n_state <= IDLE;
            end

			READY :
            begin
                if (~i_start_count)
				begin
					if (i_mode_sel)
						n_state <= CYCLE_RUN;
					
					else if (i_total_count != 0)
						n_state <= CUSTOM_RUN;

					else
						n_state <= READY;
				end

                else
                    n_state <= READY;
            end

			CYCLE_RUN :
                    n_state <= CYCLE_RUN;

			CUSTOM_RUN :
            begin
                if (o_current_count == i_total_count - 1)
                    n_state <= IDLE;

                else
                    n_state <= CUSTOM_RUN;
            end

			default :
                    n_state <= IDLE;
		endcase
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst || ~i_ps_rst)
			o_cs <= 0;

		else if ((state == CUSTOM_RUN) || (state == CYCLE_RUN))
			o_cs <= 1;

		else 
			o_cs <= 0;
	end


	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst || ~i_ps_rst)
			o_current_count <= 0;
		
		else if (i_WF_Counter_flag) 
		begin
			if (state == CUSTOM_RUN)
			begin
				if ((o_current_count == i_total_count - 1))
					o_current_count <= 0;
				else
					o_current_count <= o_current_count + 1;
			end
				
			else if (state == CYCLE_RUN)
				o_current_count <= o_current_count + 1;
		end

		else
			o_current_count <= o_current_count;
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst || ~i_ps_rst)
			o_addr <= 0;
		
		else if (i_WF_Counter_flag) 
		begin
			if ((state == CUSTOM_RUN) || (state == CYCLE_RUN))
			begin
				if (o_addr == 999)
					o_addr <= 0;

				else
					o_addr <= o_addr + 1;
			end
		end
		else
			o_addr <= o_addr;
	end

	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst || ~i_ps_rst)
		begin
			o_WF_INT_0 <= 0;
			o_WF_INT_500 <= 0;
		end

		else if (o_addr == 499)
		begin
			o_WF_INT_0 <= 1;
			o_WF_INT_500 <= 0;
		end

		else if (o_addr == 999)
		begin
			o_WF_INT_0 <= 0;
			o_WF_INT_500 <= 1;
		end

		else
		begin
			o_WF_INT_0 <= o_WF_INT_0;
			o_WF_INT_500 <= o_WF_INT_500;
		end
	end

endmodule
