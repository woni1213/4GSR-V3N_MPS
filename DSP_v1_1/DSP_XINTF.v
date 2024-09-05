/*
1. DSP_XINTF
 - i_DSP_intr과 상관없이 FSM 동작
 - 계속 Read Write
*/

module DSP_XINTF
(
    input i_clk,
    input i_rst,

    input i_Ethernet_connect,

    // WRITE
	output reg [8:0] o_xintf_PL_W_ram_addr,
	output reg [15:0] o_xintf_PL_W_ram_din,

    input [31:0] i_c_adc_data,
    input [31:0] i_v_adc_data,
    input [15:0] i_DSP_System_Status,
    input [31:0] i_DSP_Set_C,
    input [31:0] i_DSP_Set_V,
    input [31:0] i_DSP_Current_P_Gain,
    input [31:0] i_DSP_Current_I_Gain,
    input [31:0] i_DSP_Current_D_Gain,
    input [31:0] i_DSP_Voltage_P_Gain,
    input [31:0] i_DSP_Voltage_I_Gain,
    input [31:0] i_DSP_Voltage_D_Gain,
    input [31:0] i_DSP_Max_Duty,
    input [31:0] i_DSP_Max_Phase,
    input [31:0] i_DSP_Max_Freq,
    input [31:0] i_DSP_Min_Freq,
    input [15:0] i_DSP_Deadband_Set,
    input [15:0] i_DSP_Switching_Freq_Set,
    input [31:0] i_DSP_PI_Max_V,
    input [31:0] i_DSP_PI_Min_V,
    input [31:0] i_DSP_PI_Max_C,
    input [31:0] i_DSP_PI_Min_C,
    input [31:0] i_DSP_Current_Duty,
    input [31:0] i_DSP_Current_Phase,
    input [31:0] i_DSP_Current_Freq,
    input [15:0] i_DSP_Intr,
    input [15:0] i_DSP_Firmware_Ver,

    // READ
    input [15:0] i_xintf_PL_R_ram_dout,
	output reg [8:0] o_xintf_PL_R_ram_addr, 

    output reg [31:0] o_c_adc_data,
    output reg [31:0] o_v_adc_data,
    output reg [15:0] o_DSP_System_Status,
    output reg [31:0] o_DSP_Set_C,
    output reg [31:0] o_DSP_Set_V,
    output reg [31:0] o_DSP_Current_P_Gain,
    output reg [31:0] o_DSP_Current_I_Gain,
    output reg [31:0] o_DSP_Current_D_Gain,
    output reg [31:0] o_DSP_Voltage_P_Gain,
    output reg [31:0] o_DSP_Voltage_I_Gain,
    output reg [31:0] o_DSP_Voltage_D_Gain,
    output reg [31:0] o_DSP_Max_Duty,
    output reg [31:0] o_DSP_Max_Phase,
    output reg [31:0] o_DSP_Max_Freq,
    output reg [31:0] o_DSP_Min_Freq,
    output reg [15:0] o_DSP_Deadband_Set,
    output reg [15:0] o_DSP_Switching_Freq_Set,
    output reg [31:0] o_DSP_PI_Max_V,
    output reg [31:0] o_DSP_PI_Min_V,
    output reg [31:0] o_DSP_PI_Max_C,
    output reg [31:0] o_DSP_PI_Min_C,
    output reg [31:0] o_DSP_Current_Duty,
    output reg [31:0] o_DSP_Current_Phase,
    output reg [31:0] o_DSP_Current_Freq,
    output reg [15:0] o_DSP_Intr,
    output reg [15:0] o_DSP_Firmware_Ver,
    output reg [15:0] o_PI_Intr_Status,
    output reg [31:0] o_WF_Counter,

    // Debugging
    output [1:0] o_debug_r_state,
    output [1:0] o_debug_w_state,
    output [8:0] o_W_addr_pointer,
    output [8:0] o_R_addr_pointer
);

    localparam IDLE         = 0;
    localparam WRITE_AXI    = 1;
    localparam READ         = 2;
    localparam DONE         = 3;

    wire en_Master_flag;

    reg [1:0] r_state;
    reg [1:0] w_state;
    reg [1:0] n_r_state;
    reg [1:0] n_w_state;

    reg [8:0] W_addr_pointer;
    reg [8:0] R_addr_pointer;

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
                if (en_Master_flag)
                    n_w_state <= WRITE_AXI;

            WRITE_AXI :
            begin
                if (W_addr_pointer == 48)
                    n_w_state <= DONE;
                
                else
                    n_w_state <= WRITE_AXI;
            end

            DONE :
               n_w_state <= IDLE;
        endcase
    end

    always @(*)
    begin
        case (r_state)
            IDLE :
                n_r_state <= READ;

            READ :
            begin
                if (R_addr_pointer == 49)
                    n_r_state <= DONE;
                
                else
                    n_r_state <= READ;
            end

            DONE :
               n_r_state <= IDLE;
        endcase
    end

    always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            W_addr_pointer <= 0;

        else if (w_state == WRITE_AXI)
            W_addr_pointer <= W_addr_pointer + 1;

        else if (w_state == DONE)
            W_addr_pointer <= 0;

        else
            W_addr_pointer <= W_addr_pointer;
    end

    always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            R_addr_pointer <= 0;

        else if (r_state == READ)
            R_addr_pointer <= R_addr_pointer + 1;

        else if (r_state == DONE)
            R_addr_pointer <= 0;

        else
            R_addr_pointer <= R_addr_pointer;
    end

    // DPBRAM WRITE
    always @(posedge i_clk or negedge i_rst)
    begin
            if (~i_rst)
            begin
                o_xintf_PL_W_ram_din <= 0;
                o_xintf_PL_W_ram_addr <= 0;
            end

        else if (w_state == WRITE_AXI)
        begin
            case (W_addr_pointer)
                1  : begin o_xintf_PL_W_ram_addr <= 0 ;             o_xintf_PL_W_ram_din <= i_c_adc_data[15:0];                end
                2  : begin o_xintf_PL_W_ram_addr <= 1 ;             o_xintf_PL_W_ram_din <= i_c_adc_data[31:16];               end
                3  : begin o_xintf_PL_W_ram_addr <= 2 ;             o_xintf_PL_W_ram_din <= i_v_adc_data[15:0];                end
                4  : begin o_xintf_PL_W_ram_addr <= 3 ;             o_xintf_PL_W_ram_din <= i_v_adc_data[31:16];               end
                5  : begin o_xintf_PL_W_ram_addr <= 4 ;             o_xintf_PL_W_ram_din <= i_DSP_System_Status;               end
                6  : begin o_xintf_PL_W_ram_addr <= 5 ;             o_xintf_PL_W_ram_din <= i_DSP_Set_C[15:0];                 end
                7  : begin o_xintf_PL_W_ram_addr <= 6 ;             o_xintf_PL_W_ram_din <= i_DSP_Set_C[31:16];                end
                8  : begin o_xintf_PL_W_ram_addr <= 7 ;             o_xintf_PL_W_ram_din <= i_DSP_Set_V[15:0];                 end
                9  : begin o_xintf_PL_W_ram_addr <= 8 ;             o_xintf_PL_W_ram_din <= i_DSP_Set_V[31:16];                end
                10 : begin o_xintf_PL_W_ram_addr <= 9 ;             o_xintf_PL_W_ram_din <= i_DSP_Current_P_Gain[15:0];        end
                11 : begin o_xintf_PL_W_ram_addr <= 10;             o_xintf_PL_W_ram_din <= i_DSP_Current_P_Gain[31:16];       end
                12 : begin o_xintf_PL_W_ram_addr <= 11;             o_xintf_PL_W_ram_din <= i_DSP_Current_I_Gain[15:0];        end
                13 : begin o_xintf_PL_W_ram_addr <= 12;             o_xintf_PL_W_ram_din <= i_DSP_Current_I_Gain[31:16];       end
                14 : begin o_xintf_PL_W_ram_addr <= 13;             o_xintf_PL_W_ram_din <= i_DSP_Current_D_Gain[15:0];        end
                15 : begin o_xintf_PL_W_ram_addr <= 14;             o_xintf_PL_W_ram_din <= i_DSP_Current_D_Gain[31:16];       end
                16 : begin o_xintf_PL_W_ram_addr <= 15;             o_xintf_PL_W_ram_din <= i_DSP_Voltage_P_Gain[15:0];        end
                17 : begin o_xintf_PL_W_ram_addr <= 16;             o_xintf_PL_W_ram_din <= i_DSP_Voltage_P_Gain[31:16];       end
                18 : begin o_xintf_PL_W_ram_addr <= 17;             o_xintf_PL_W_ram_din <= i_DSP_Voltage_I_Gain[15:0];        end
                19 : begin o_xintf_PL_W_ram_addr <= 18;             o_xintf_PL_W_ram_din <= i_DSP_Voltage_I_Gain[31:16];       end
                20 : begin o_xintf_PL_W_ram_addr <= 19;             o_xintf_PL_W_ram_din <= i_DSP_Voltage_D_Gain[15:0];        end
                21 : begin o_xintf_PL_W_ram_addr <= 20;             o_xintf_PL_W_ram_din <= i_DSP_Voltage_D_Gain[31:16];       end
                22 : begin o_xintf_PL_W_ram_addr <= 21;             o_xintf_PL_W_ram_din <= i_DSP_Max_Duty[15:0];              end
                23 : begin o_xintf_PL_W_ram_addr <= 22;             o_xintf_PL_W_ram_din <= i_DSP_Max_Duty[31:16];             end
                24 : begin o_xintf_PL_W_ram_addr <= 23;             o_xintf_PL_W_ram_din <= i_DSP_Max_Phase[15:0];             end
                25 : begin o_xintf_PL_W_ram_addr <= 24;             o_xintf_PL_W_ram_din <= i_DSP_Max_Phase[31:16];            end
                26 : begin o_xintf_PL_W_ram_addr <= 25;             o_xintf_PL_W_ram_din <= i_DSP_Max_Freq[15:0];              end
                27 : begin o_xintf_PL_W_ram_addr <= 26;             o_xintf_PL_W_ram_din <= i_DSP_Max_Freq[31:16];             end
                28 : begin o_xintf_PL_W_ram_addr <= 27;             o_xintf_PL_W_ram_din <= i_DSP_Min_Freq[15:0];              end
                29 : begin o_xintf_PL_W_ram_addr <= 28;             o_xintf_PL_W_ram_din <= i_DSP_Min_Freq[31:16];             end
                30 : begin o_xintf_PL_W_ram_addr <= 29;             o_xintf_PL_W_ram_din <= i_DSP_Deadband_Set;                end
                31 : begin o_xintf_PL_W_ram_addr <= 30;             o_xintf_PL_W_ram_din <= i_DSP_Switching_Freq_Set;          end
                32 : begin o_xintf_PL_W_ram_addr <= 31;             o_xintf_PL_W_ram_din <= i_DSP_PI_Max_V[15:0];              end
                33 : begin o_xintf_PL_W_ram_addr <= 32;             o_xintf_PL_W_ram_din <= i_DSP_PI_Max_V[31:16];             end
                34 : begin o_xintf_PL_W_ram_addr <= 33;             o_xintf_PL_W_ram_din <= i_DSP_PI_Min_V[15:0];              end
                35 : begin o_xintf_PL_W_ram_addr <= 34;             o_xintf_PL_W_ram_din <= i_DSP_PI_Min_V[31:16];             end
                36 : begin o_xintf_PL_W_ram_addr <= 35;             o_xintf_PL_W_ram_din <= i_DSP_PI_Max_C[15:0];              end
                37 : begin o_xintf_PL_W_ram_addr <= 36;             o_xintf_PL_W_ram_din <= i_DSP_PI_Max_C[31:16];             end
                38 : begin o_xintf_PL_W_ram_addr <= 37;             o_xintf_PL_W_ram_din <= i_DSP_PI_Min_C[15:0];              end
                39 : begin o_xintf_PL_W_ram_addr <= 38;             o_xintf_PL_W_ram_din <= i_DSP_PI_Min_C[31:16];             end
                40 : begin o_xintf_PL_W_ram_addr <= 39;             o_xintf_PL_W_ram_din <= i_DSP_Current_Duty[15:0];          end
                41 : begin o_xintf_PL_W_ram_addr <= 40;             o_xintf_PL_W_ram_din <= i_DSP_Current_Duty[31:16];         end
                42 : begin o_xintf_PL_W_ram_addr <= 41;             o_xintf_PL_W_ram_din <= i_DSP_Current_Phase[15:0];         end
                43 : begin o_xintf_PL_W_ram_addr <= 42;             o_xintf_PL_W_ram_din <= i_DSP_Current_Phase[31:16];        end
                44 : begin o_xintf_PL_W_ram_addr <= 43;             o_xintf_PL_W_ram_din <= i_DSP_Current_Freq[15:0];          end
                45 : begin o_xintf_PL_W_ram_addr <= 44;             o_xintf_PL_W_ram_din <= i_DSP_Current_Freq[31:16];         end
                46 : begin o_xintf_PL_W_ram_addr <= 45;             o_xintf_PL_W_ram_din <= i_DSP_Intr;                        end
                47 : begin o_xintf_PL_W_ram_addr <= 46;             o_xintf_PL_W_ram_din <= i_DSP_Firmware_Ver;                end
                
                default :
                begin
                    o_xintf_PL_W_ram_addr <= 0;
                    o_xintf_PL_W_ram_din  <= 0;
                end
            endcase
        end

        else
        begin
            o_xintf_PL_W_ram_din <= 0;
            o_xintf_PL_W_ram_addr <= 0;
        end
    end

    // DPBRAM READ
    always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
        begin
            o_xintf_PL_R_ram_addr    <= 0;
            o_c_adc_data             <= 0;
            o_v_adc_data             <= 0;
            o_DSP_System_Status      <= 0;
            o_DSP_Set_C              <= 0;
            o_DSP_Set_V              <= 0;
            o_DSP_Current_P_Gain     <= 0;
            o_DSP_Current_I_Gain     <= 0;
            o_DSP_Current_D_Gain     <= 0;
            o_DSP_Voltage_P_Gain     <= 0;
            o_DSP_Voltage_I_Gain     <= 0;
            o_DSP_Voltage_D_Gain     <= 0;
            o_DSP_Max_Duty           <= 0;
            o_DSP_Max_Phase          <= 0;
            o_DSP_Max_Freq           <= 0;
            o_DSP_Min_Freq           <= 0;
            o_DSP_Deadband_Set       <= 0;
            o_DSP_Switching_Freq_Set <= 0;
            o_DSP_PI_Max_V           <= 0;
            o_DSP_PI_Min_V           <= 0;
            o_DSP_PI_Max_C           <= 0;
            o_DSP_PI_Min_C           <= 0;
            o_DSP_Current_Duty       <= 0;
            o_DSP_Current_Phase      <= 0;
            o_DSP_Current_Freq       <= 0;
            o_DSP_Intr               <= 0;
            o_DSP_Firmware_Ver       <= 0;
            o_PI_Intr_Status         <= 0;
            o_WF_Counter             <= 0;
        end

        else if (r_state == IDLE)            
            o_xintf_PL_R_ram_addr <= 1;

        else if (r_state == READ)
        begin
            case (R_addr_pointer)
                0  : begin o_xintf_PL_R_ram_addr <= 2 ;              o_c_adc_data[15:0]             <= i_xintf_PL_R_ram_dout;  end
                1  : begin o_xintf_PL_R_ram_addr <= 3 ;              o_c_adc_data[31:16]            <= i_xintf_PL_R_ram_dout;  end
                2  : begin o_xintf_PL_R_ram_addr <= 4 ;              o_v_adc_data[15:0]             <= i_xintf_PL_R_ram_dout;  end
                3  : begin o_xintf_PL_R_ram_addr <= 5 ;              o_v_adc_data[31:16]            <= i_xintf_PL_R_ram_dout;  end
                4  : begin o_xintf_PL_R_ram_addr <= 6 ;              o_DSP_System_Status            <= i_xintf_PL_R_ram_dout;  end
                5  : begin o_xintf_PL_R_ram_addr <= 7 ;              o_DSP_Set_C[15:0]              <= i_xintf_PL_R_ram_dout;  end
                6  : begin o_xintf_PL_R_ram_addr <= 8 ;              o_DSP_Set_C[31:16]             <= i_xintf_PL_R_ram_dout;  end
                7  : begin o_xintf_PL_R_ram_addr <= 9 ;              o_DSP_Set_V[15:0]              <= i_xintf_PL_R_ram_dout;  end
                8  : begin o_xintf_PL_R_ram_addr <= 10;              o_DSP_Set_V[31:16]             <= i_xintf_PL_R_ram_dout;  end
                9  : begin o_xintf_PL_R_ram_addr <= 11;              o_DSP_Current_P_Gain[15:0]     <= i_xintf_PL_R_ram_dout;  end
                10 : begin o_xintf_PL_R_ram_addr <= 12;              o_DSP_Current_P_Gain[31:16]    <= i_xintf_PL_R_ram_dout;  end
                11 : begin o_xintf_PL_R_ram_addr <= 13;              o_DSP_Current_I_Gain[15:0]     <= i_xintf_PL_R_ram_dout;  end
                12 : begin o_xintf_PL_R_ram_addr <= 14;              o_DSP_Current_I_Gain[31:16]    <= i_xintf_PL_R_ram_dout;  end
                13 : begin o_xintf_PL_R_ram_addr <= 15;              o_DSP_Current_D_Gain[15:0]     <= i_xintf_PL_R_ram_dout;  end
                14 : begin o_xintf_PL_R_ram_addr <= 16;              o_DSP_Current_D_Gain[31:16]    <= i_xintf_PL_R_ram_dout;  end
                15 : begin o_xintf_PL_R_ram_addr <= 17;              o_DSP_Voltage_P_Gain[15:0]     <= i_xintf_PL_R_ram_dout;  end
                16 : begin o_xintf_PL_R_ram_addr <= 18;              o_DSP_Voltage_P_Gain[31:16]    <= i_xintf_PL_R_ram_dout;  end
                17 : begin o_xintf_PL_R_ram_addr <= 19;              o_DSP_Voltage_I_Gain[15:0]     <= i_xintf_PL_R_ram_dout;  end
                18 : begin o_xintf_PL_R_ram_addr <= 20;              o_DSP_Voltage_I_Gain[31:16]    <= i_xintf_PL_R_ram_dout;  end
                19 : begin o_xintf_PL_R_ram_addr <= 21;              o_DSP_Voltage_D_Gain[15:0]     <= i_xintf_PL_R_ram_dout;  end
                20 : begin o_xintf_PL_R_ram_addr <= 22;              o_DSP_Voltage_D_Gain[31:16]    <= i_xintf_PL_R_ram_dout;  end
                21 : begin o_xintf_PL_R_ram_addr <= 23;              o_DSP_Max_Duty[15:0]           <= i_xintf_PL_R_ram_dout;  end
                22 : begin o_xintf_PL_R_ram_addr <= 24;              o_DSP_Max_Duty[31:16]          <= i_xintf_PL_R_ram_dout;  end
                23 : begin o_xintf_PL_R_ram_addr <= 25;              o_DSP_Max_Phase[15:0]          <= i_xintf_PL_R_ram_dout;  end
                24 : begin o_xintf_PL_R_ram_addr <= 26;              o_DSP_Max_Phase[31:16]         <= i_xintf_PL_R_ram_dout;  end
                25 : begin o_xintf_PL_R_ram_addr <= 27;              o_DSP_Max_Freq[15:0]           <= i_xintf_PL_R_ram_dout;  end
                26 : begin o_xintf_PL_R_ram_addr <= 28;              o_DSP_Max_Freq[31:16]          <= i_xintf_PL_R_ram_dout;  end
                27 : begin o_xintf_PL_R_ram_addr <= 29;              o_DSP_Min_Freq[15:0]           <= i_xintf_PL_R_ram_dout;  end
                28 : begin o_xintf_PL_R_ram_addr <= 30;              o_DSP_Min_Freq[31:16]          <= i_xintf_PL_R_ram_dout;  end
                29 : begin o_xintf_PL_R_ram_addr <= 31;              o_DSP_Deadband_Set             <= i_xintf_PL_R_ram_dout;  end
                30 : begin o_xintf_PL_R_ram_addr <= 32;              o_DSP_Switching_Freq_Set       <= i_xintf_PL_R_ram_dout;  end
                31 : begin o_xintf_PL_R_ram_addr <= 33;              o_DSP_PI_Max_V[15:0]           <= i_xintf_PL_R_ram_dout;  end
                32 : begin o_xintf_PL_R_ram_addr <= 34;              o_DSP_PI_Max_V[31:16]          <= i_xintf_PL_R_ram_dout;  end
                33 : begin o_xintf_PL_R_ram_addr <= 35;              o_DSP_PI_Min_V[15:0]           <= i_xintf_PL_R_ram_dout;  end
                34 : begin o_xintf_PL_R_ram_addr <= 36;              o_DSP_PI_Min_V[31:16]          <= i_xintf_PL_R_ram_dout;  end
                35 : begin o_xintf_PL_R_ram_addr <= 37;              o_DSP_PI_Max_C[15:0]           <= i_xintf_PL_R_ram_dout;  end
                36 : begin o_xintf_PL_R_ram_addr <= 38;              o_DSP_PI_Max_C[31:16]          <= i_xintf_PL_R_ram_dout;  end
                37 : begin o_xintf_PL_R_ram_addr <= 39;              o_DSP_PI_Min_C[15:0]           <= i_xintf_PL_R_ram_dout;  end
                38 : begin o_xintf_PL_R_ram_addr <= 40;              o_DSP_PI_Min_C[31:16]          <= i_xintf_PL_R_ram_dout;  end
                39 : begin o_xintf_PL_R_ram_addr <= 41;              o_DSP_Current_Duty[15:0]       <= i_xintf_PL_R_ram_dout;  end
                40 : begin o_xintf_PL_R_ram_addr <= 42;              o_DSP_Current_Duty[31:16]      <= i_xintf_PL_R_ram_dout;  end
                41 : begin o_xintf_PL_R_ram_addr <= 43;              o_DSP_Current_Phase[15:0]      <= i_xintf_PL_R_ram_dout;  end
                42 : begin o_xintf_PL_R_ram_addr <= 44;              o_DSP_Current_Phase[31:16]     <= i_xintf_PL_R_ram_dout;  end
                43 : begin o_xintf_PL_R_ram_addr <= 45;              o_DSP_Current_Freq[15:0]       <= i_xintf_PL_R_ram_dout;  end
                44 : begin o_xintf_PL_R_ram_addr <= 46;              o_DSP_Current_Freq[31:16]      <= i_xintf_PL_R_ram_dout;  end
                45 : begin o_xintf_PL_R_ram_addr <= 47;              o_DSP_Intr                     <= i_xintf_PL_R_ram_dout;  end
                46 : begin o_xintf_PL_R_ram_addr <= 48;              o_DSP_Firmware_Ver             <= i_xintf_PL_R_ram_dout;  end
                47 : begin o_xintf_PL_R_ram_addr <= 49;              o_PI_Intr_Status               <= i_xintf_PL_R_ram_dout;  end
                48 : begin o_xintf_PL_R_ram_addr <= 0 ;              o_WF_Counter[15:0]             <= i_xintf_PL_R_ram_dout;  end
                49 : begin                                           o_WF_Counter[31:16]            <= i_xintf_PL_R_ram_dout;  end
                 
                default :
                begin
                    o_xintf_PL_R_ram_addr               <= o_xintf_PL_R_ram_addr   ;
                    o_c_adc_data                        <= o_c_adc_data            ;
                    o_v_adc_data                        <= o_v_adc_data            ;
                    o_DSP_System_Status                 <= o_DSP_System_Status     ;
                    o_DSP_Set_C                         <= o_DSP_Set_C             ;
                    o_DSP_Set_V                         <= o_DSP_Set_V             ;
                    o_DSP_Current_P_Gain                <= o_DSP_Current_P_Gain    ;
                    o_DSP_Current_I_Gain                <= o_DSP_Current_I_Gain    ;
                    o_DSP_Current_D_Gain                <= o_DSP_Current_D_Gain    ;
                    o_DSP_Voltage_P_Gain                <= o_DSP_Voltage_P_Gain    ;
                    o_DSP_Voltage_I_Gain                <= o_DSP_Voltage_I_Gain    ;
                    o_DSP_Voltage_D_Gain                <= o_DSP_Voltage_D_Gain    ;
                    o_DSP_Max_Duty                      <= o_DSP_Max_Duty          ;
                    o_DSP_Max_Phase                     <= o_DSP_Max_Phase         ;
                    o_DSP_Max_Freq                      <= o_DSP_Max_Freq          ;
                    o_DSP_Min_Freq                      <= o_DSP_Min_Freq          ;
                    o_DSP_Deadband_Set                  <= o_DSP_Deadband_Set      ;
                    o_DSP_Switching_Freq_Set            <= o_DSP_Switching_Freq_Set;
                    o_DSP_PI_Max_V                      <= o_DSP_PI_Max_V          ;
                    o_DSP_PI_Min_V                      <= o_DSP_PI_Min_V          ;
                    o_DSP_PI_Max_C                      <= o_DSP_PI_Max_C          ;
                    o_DSP_PI_Min_C                      <= o_DSP_PI_Min_C          ;
                    o_DSP_Current_Duty                  <= o_DSP_Current_Duty      ;
                    o_DSP_Current_Phase                 <= o_DSP_Current_Phase     ;
                    o_DSP_Current_Freq                  <= o_DSP_Current_Freq      ;
                    o_DSP_Intr                          <= o_DSP_Intr              ;
                    o_DSP_Firmware_Ver                  <= o_DSP_Firmware_Ver      ;
                    o_PI_Intr_Status                    <= o_PI_Intr_Status        ;
                    o_WF_Counter                        <= o_WF_Counter            ;
                end
                    
            endcase
        end

        else
        begin
            o_xintf_PL_R_ram_addr                       <= o_xintf_PL_R_ram_addr   ;
            o_c_adc_data                                <= o_c_adc_data            ;
            o_v_adc_data                                <= o_v_adc_data            ;
            o_DSP_System_Status                         <= o_DSP_System_Status     ;
            o_DSP_Set_C                                 <= o_DSP_Set_C             ;
            o_DSP_Set_V                                 <= o_DSP_Set_V             ;
            o_DSP_Current_P_Gain                        <= o_DSP_Current_P_Gain    ;
            o_DSP_Current_I_Gain                        <= o_DSP_Current_I_Gain    ;
            o_DSP_Current_D_Gain                        <= o_DSP_Current_D_Gain    ;
            o_DSP_Voltage_P_Gain                        <= o_DSP_Voltage_P_Gain    ;
            o_DSP_Voltage_I_Gain                        <= o_DSP_Voltage_I_Gain    ;
            o_DSP_Voltage_D_Gain                        <= o_DSP_Voltage_D_Gain    ;
            o_DSP_Max_Duty                              <= o_DSP_Max_Duty          ;
            o_DSP_Max_Phase                             <= o_DSP_Max_Phase         ;
            o_DSP_Max_Freq                              <= o_DSP_Max_Freq          ;
            o_DSP_Min_Freq                              <= o_DSP_Min_Freq          ;
            o_DSP_Deadband_Set                          <= o_DSP_Deadband_Set      ;
            o_DSP_Switching_Freq_Set                    <= o_DSP_Switching_Freq_Set;
            o_DSP_PI_Max_V                              <= o_DSP_PI_Max_V          ;
            o_DSP_PI_Min_V                              <= o_DSP_PI_Min_V          ;
            o_DSP_PI_Max_C                              <= o_DSP_PI_Max_C          ;
            o_DSP_PI_Min_C                              <= o_DSP_PI_Min_C          ;
            o_DSP_Current_Duty                          <= o_DSP_Current_Duty      ;
            o_DSP_Current_Phase                         <= o_DSP_Current_Phase     ;
            o_DSP_Current_Freq                          <= o_DSP_Current_Freq      ;
            o_DSP_Intr                                  <= o_DSP_Intr              ;
            o_DSP_Firmware_Ver                          <= o_DSP_Firmware_Ver      ;
            o_PI_Intr_Status                            <= o_PI_Intr_Status        ;
            o_WF_Counter                                <= o_WF_Counter            ;
        end

    end

    assign en_Master_flag = i_Ethernet_connect;
    assign o_debug_r_state = r_state;
    assign o_debug_w_state = w_state;
    assign o_W_addr_pointer = W_addr_pointer;
    assign o_R_addr_pointer = R_addr_pointer;

endmodule