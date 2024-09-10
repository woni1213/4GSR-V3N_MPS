/*
1. DSP_XINTF
 - i_DSP_intr과 상관없이 FSM 동작
 - 계속 Read Write
*/

module DSP_Handler
(
    input i_clk,
    input i_rst,

    input i_sfp_m_en,
	input i_i_zynq_intl,

    // DPBRAM WRITE
	output reg [8:0] o_xintf_w_ram_addr,
	output reg [15:0] o_xintf_w_ram_din,
	output reg o_xintf_w_ram_ce,

    input [31:0] i_c_adc_data,
    input [31:0] i_v_adc_data,
    input [15:0] i_zynq_status,
    input [15:0] i_zynq_firmware_ver,
    input [31:0] i_set_c,
    input [31:0] i_set_v,
    input [31:0] i_p_gain_c,
    input [31:0] i_i_gain_c,
    input [31:0] i_d_gain_c,
    input [31:0] i_p_gain_v,
    input [31:0] i_i_gain_v,
    input [31:0] i_d_gain_v,
    input [31:0] i_max_duty,
    input [31:0] i_max_phase,
    input [31:0] i_max_freq,
    input [31:0] i_min_freq,
    input [31:0] i_max_v,
    input [31:0] i_min_v,
    input [31:0] i_max_c,
    input [31:0] i_min_c,
    input [31:0] i_master_pi_param,
	input [15:0] i_deadband,
    input [15:0] i_sw_freq,

    // DPBRAM READ
    input [15:0] i_xintf_PL_R_ram_dout,
	output reg [8:0] o_xintf_PL_R_ram_addr,
	output reg o_xintf_r_ram_ce,

    output reg [15:0] o_dsp_status,
    output reg [15:0] o_dsp_firmware_ver,
    output reg [31:0] o_wf_read_cnt,
    output reg [15:0] o_slave_pi_param_1,
    output reg [31:0] o_slave_pi_param_2,
    output reg [31:0] o_slave_pi_param_3,

    // Debugging
    output [1:0] o_debug_r_state,
    output [1:0] o_debug_w_state,
    output [8:0] o_W_addr_pointer,
    output [8:0] o_R_addr_pointer
);

    localparam IDLE = 0;
    localparam WRITE = 1;
    localparam READ = 2;
    localparam DONE = 3;

    reg [1:0] r_state;
    reg [1:0] w_state;
    reg [1:0] n_r_state;
    reg [1:0] n_w_state;

    reg [8:0] w_addr_pointer;
    reg [8:0] r_addr_pointer;


    always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
        begin
            r_state <= IDLE;
            w_state <= IDLE;
        end

        else
        begin
            r_state <= n_r_state;
            w_state <= n_w_state;
        end
    end

    always @(*)
    begin
        case (w_state)
            IDLE :
                if (i_sfp_m_en)
                    n_w_state = WRITE;

            WRITE :
            begin
                if (w_addr_pointer == 48)
                    n_w_state = DONE;
                
                else
                    n_w_state = WRITE;
            end

            DONE :
               n_w_state = IDLE;
        endcase
    end

    always @(*)
    begin
        case (r_state)
            IDLE :
                n_r_state <= READ;

            READ :
            begin
                if (r_addr_pointer == 49)
                    n_r_state <= DONE;
                
                else
                    n_r_state <= READ;
            end

            DONE :
               n_r_state <= IDLE;
        endcase
    end

	// DPBRAM Addr Pointer
    always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            w_addr_pointer <= 0;

        else if (w_state == WRITE)
            w_addr_pointer <= w_addr_pointer + 1;

        else if (w_state == DONE)
            w_addr_pointer <= 0;

        else
            w_addr_pointer <= w_addr_pointer;
    end

    always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            r_addr_pointer <= 0;

        else if (r_state == READ)
            r_addr_pointer <= r_addr_pointer + 1;

        else if (r_state == DONE)
            r_addr_pointer <= 0;

        else
            r_addr_pointer <= r_addr_pointer;
    end

	// DPBRAM CE Control
	always @(posedge i_clk or negedge i_rst)
    begin
            if (~i_rst)
				o_xintf_w_ram_ce <= 0;

			else if (w_state == WRITE)
				o_xintf_w_ram_ce <= 1;

			else
				o_xintf_w_ram_ce <= 0;
	end

	always @(posedge i_clk or negedge i_rst)
    begin
            if (~i_rst)
				o_xintf_r_ram_ce <= 0;

			else if (w_state == READ)
				o_xintf_r_ram_ce <= 1;

			else
				o_xintf_r_ram_ce <= 0;
	end

    // DPBRAM WRITE
    always @(posedge i_clk or negedge i_rst)
    begin
            if (~i_rst)
            begin
                o_xintf_w_ram_din <= 0;
                o_xintf_w_ram_addr <= 0;
            end

        else if (w_state == WRITE)
        begin
            case (w_addr_pointer)
                0  : begin o_xintf_w_ram_addr <= 0 ;		o_xintf_w_ram_din <= i_c_adc_data[15:0];		end
                1  : begin o_xintf_w_ram_addr <= 1 ;		o_xintf_w_ram_din <= i_c_adc_data[31:16];		end
                2  : begin o_xintf_w_ram_addr <= 2 ;		o_xintf_w_ram_din <= i_v_adc_data[15:0];		end
                3  : begin o_xintf_w_ram_addr <= 3 ;		o_xintf_w_ram_din <= i_v_adc_data[31:16];		end
                4  : begin o_xintf_w_ram_addr <= 4 ;		o_xintf_w_ram_din <= i_zynq_status;				end
                5  : begin o_xintf_w_ram_addr <= 4 ;		o_xintf_w_ram_din <= i_i_zynq_intl;				end
                6  : begin o_xintf_w_ram_addr <= 4 ;		o_xintf_w_ram_din <= i_zynq_firmware_ver;		end
                7  : begin o_xintf_w_ram_addr <= 5 ;		o_xintf_w_ram_din <= i_set_c[15:0];				end
                8  : begin o_xintf_w_ram_addr <= 6 ;		o_xintf_w_ram_din <= i_set_c[31:16];			end
                9  : begin o_xintf_w_ram_addr <= 7 ;		o_xintf_w_ram_din <= i_set_v[15:0];				end
                10 : begin o_xintf_w_ram_addr <= 8 ;		o_xintf_w_ram_din <= i_set_v[31:16];			end
                11 : begin o_xintf_w_ram_addr <= 9 ;		o_xintf_w_ram_din <= i_p_gain_c[15:0];			end
                12 : begin o_xintf_w_ram_addr <= 10;		o_xintf_w_ram_din <= i_p_gain_c[31:16];			end
                13 : begin o_xintf_w_ram_addr <= 11;		o_xintf_w_ram_din <= i_i_gain_c[15:0];			end
                14 : begin o_xintf_w_ram_addr <= 12;		o_xintf_w_ram_din <= i_i_gain_c[31:16];			end
                15 : begin o_xintf_w_ram_addr <= 13;		o_xintf_w_ram_din <= i_d_gain_c[15:0];			end
                16 : begin o_xintf_w_ram_addr <= 14;		o_xintf_w_ram_din <= i_d_gain_c[31:16];			end
                17 : begin o_xintf_w_ram_addr <= 15;		o_xintf_w_ram_din <= i_p_gain_v[15:0];			end
                18 : begin o_xintf_w_ram_addr <= 16;		o_xintf_w_ram_din <= i_p_gain_v[31:16];			end
                19 : begin o_xintf_w_ram_addr <= 17;		o_xintf_w_ram_din <= i_i_gain_v[15:0];			end
                20 : begin o_xintf_w_ram_addr <= 18;		o_xintf_w_ram_din <= i_i_gain_v[31:16];			end
                21 : begin o_xintf_w_ram_addr <= 19;		o_xintf_w_ram_din <= i_d_gain_v[15:0];			end
                22 : begin o_xintf_w_ram_addr <= 20;		o_xintf_w_ram_din <= i_d_gain_v[31:16];			end
                23 : begin o_xintf_w_ram_addr <= 21;		o_xintf_w_ram_din <= i_max_duty[15:0];			end
                24 : begin o_xintf_w_ram_addr <= 22;		o_xintf_w_ram_din <= i_max_duty[31:16];			end
                25 : begin o_xintf_w_ram_addr <= 23;		o_xintf_w_ram_din <= i_max_phase[15:0];			end
                26 : begin o_xintf_w_ram_addr <= 24;		o_xintf_w_ram_din <= i_max_phase[31:16];		end
                27 : begin o_xintf_w_ram_addr <= 25;		o_xintf_w_ram_din <= i_max_freq[15:0];			end
                28 : begin o_xintf_w_ram_addr <= 26;		o_xintf_w_ram_din <= i_max_freq[31:16];			end
                29 : begin o_xintf_w_ram_addr <= 27;		o_xintf_w_ram_din <= i_min_freq[15:0];			end
                30 : begin o_xintf_w_ram_addr <= 28;		o_xintf_w_ram_din <= i_min_freq[31:16];			end
                31 : begin o_xintf_w_ram_addr <= 31;		o_xintf_w_ram_din <= i_max_v[15:0];				end
                32 : begin o_xintf_w_ram_addr <= 32;		o_xintf_w_ram_din <= i_max_v[31:16];			end
                33 : begin o_xintf_w_ram_addr <= 33;		o_xintf_w_ram_din <= i_min_v[15:0];				end
                34 : begin o_xintf_w_ram_addr <= 34;		o_xintf_w_ram_din <= i_min_v[31:16];			end
                35 : begin o_xintf_w_ram_addr <= 35;		o_xintf_w_ram_din <= i_max_c[15:0];				end
                36 : begin o_xintf_w_ram_addr <= 36;		o_xintf_w_ram_din <= i_max_c[31:16];			end
                37 : begin o_xintf_w_ram_addr <= 37;		o_xintf_w_ram_din <= i_min_c[15:0];				end
                38 : begin o_xintf_w_ram_addr <= 38;		o_xintf_w_ram_din <= i_min_c[31:16];			end
                39 : begin o_xintf_w_ram_addr <= 39;		o_xintf_w_ram_din <= i_master_pi_param[15:0];	end
                40 : begin o_xintf_w_ram_addr <= 40;		o_xintf_w_ram_din <= i_master_pi_param[31:16];	end
                41 : begin o_xintf_w_ram_addr <= 41;		o_xintf_w_ram_din <= i_deadband;				end
                42 : begin o_xintf_w_ram_addr <= 42;		o_xintf_w_ram_din <= i_sw_freq;					end

                default :
                begin
                    o_xintf_w_ram_addr <= 0;
                    o_xintf_w_ram_din  <= 0;
                end
            endcase
        end

        else
        begin
            o_xintf_w_ram_din <= 0;
            o_xintf_w_ram_addr <= 0;
        end
    end

    // DPBRAM READ
    always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
        begin
			o_xintf_PL_R_ram_addr <= 0;
            o_dsp_status <= 0;
            o_dsp_firmware_ver <= 0;
            o_wf_read_cnt <= 0;
            o_slave_pi_param_1 <= 0;
            o_slave_pi_param_2 <= 0;
            o_slave_pi_param_3 <= 0;
        end

        else if (r_state == IDLE)
            o_xintf_PL_R_ram_addr <= 0;

        else if (r_state == READ)
        begin
            case (r_addr_pointer)
                0  : begin o_xintf_PL_R_ram_addr <= 1 ;		o_dsp_status				<= i_xintf_PL_R_ram_dout;  end
                1  : begin o_xintf_PL_R_ram_addr <= 2 ;		o_dsp_firmware_ver			<= i_xintf_PL_R_ram_dout;  end
                2  : begin o_xintf_PL_R_ram_addr <= 3 ;		o_wf_read_cnt[15:0]			<= i_xintf_PL_R_ram_dout;  end
                3  : begin o_xintf_PL_R_ram_addr <= 4 ;		o_wf_read_cnt[31:16]		<= i_xintf_PL_R_ram_dout;  end
                4  : begin o_xintf_PL_R_ram_addr <= 7 ;		o_slave_pi_param_1[15:0]	<= i_xintf_PL_R_ram_dout;  end
                5  : begin o_xintf_PL_R_ram_addr <= 8 ;		o_slave_pi_param_1[31:16]	<= i_xintf_PL_R_ram_dout;  end
                6  : begin o_xintf_PL_R_ram_addr <= 9 ;		o_slave_pi_param_2[15:0]	<= i_xintf_PL_R_ram_dout;  end
                7  : begin o_xintf_PL_R_ram_addr <= 10;		o_slave_pi_param_2[31:16]	<= i_xintf_PL_R_ram_dout;  end
                8  : begin o_xintf_PL_R_ram_addr <= 11;		o_slave_pi_param_3[15:0]	<= i_xintf_PL_R_ram_dout;  end
                9  : begin o_xintf_PL_R_ram_addr <= 12;		o_slave_pi_param_3[31:16]	<= i_xintf_PL_R_ram_dout;  end
                 
                default :
                begin
					o_xintf_PL_R_ram_addr <= o_xintf_PL_R_ram_addr;
                    o_dsp_status <= o_dsp_status;
                    o_dsp_firmware_ver <= o_dsp_firmware_ver;
                    o_wf_read_cnt <= o_wf_read_cnt;
                    o_slave_pi_param_1 <= o_slave_pi_param_1;
                    o_slave_pi_param_2 <= o_slave_pi_param_2;
                    o_slave_pi_param_3 <= o_slave_pi_param_3;
                end
            endcase
        end

        else
        begin
            		o_xintf_PL_R_ram_addr <= o_xintf_PL_R_ram_addr;
                    o_dsp_status <= o_dsp_status;
                    o_dsp_firmware_ver <= o_dsp_firmware_ver;
                    o_wf_read_cnt <= o_wf_read_cnt;
                    o_slave_pi_param_1 <= o_slave_pi_param_1;
                    o_slave_pi_param_2 <= o_slave_pi_param_2;
                    o_slave_pi_param_3 <= o_slave_pi_param_3;
        end
    end

    assign o_debug_r_state = r_state;
    assign o_debug_w_state = w_state;
    assign o_W_addr_pointer = w_addr_pointer;
    assign o_R_addr_pointer = r_addr_pointer;

endmodule