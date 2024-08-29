# Kria_K26_SOM_Rev1.xdc 파일 내에서 Package Pin을 찾아야함.
# 회로도 내 CN1001이 som240_1, CN1002가 som240_2
# 그리고 포트의 라우팅 이름이 해당 보드의 핀 이름임
# 예시) 회로도 내 CN1001의 라우팅 이름이 A3라면  Kria_K26_SOM_Rev1.xdc 파일의 get_ports는 "som240_1_a3"이다.

### Clock Constraints
create_clock -period 6.400 -name GT_DIFF_REFCLK1_0_clk_p -waveform {0.000 3.200} [get_ports {GT_DIFF_REFCLK1_0_clk_p}]

### LAN Clock
set_property -dict { PACKAGE_PIN C3		IOSTANDARD LVCMOS18 } [get_ports sys_clk];				# HPARCK
#set_property -dict { PACKAGE_PIN L3		IOSTANDARD LVCMOS18 } [get_ports sys_clk_2];			# HPBRCK

### LAN Constraints (See Notion - Zynq - Error and Critical Warning Page)
set_property IODELAY_GROUP tri_mode_ethernet_mac_iodelay_grp1 [get_cells -hier -filter {NAME =~ design_1_i/LAN/LAN_1/* && IODELAY_GROUP != "" }] 
set_property IODELAY_GROUP tri_mode_ethernet_mac_iodelay_grp2 [get_cells -hier -filter {NAME =~ design_1_i/LAN/LAN_2/* && IODELAY_GROUP != "" }]

set_property REFCLK_FREQUENCY 300.03 [get_cells -hier -filter {NAME =~ *delay_rgmii_tx_clk}]
set_property REFCLK_FREQUENCY 300.03 [get_cells -hier -filter {NAME =~ *delay_rgmii_tx_clk_casc}]
set_property REFCLK_FREQUENCY 300.03 [get_cells -hier -filter {NAME =~ *delay_rgmii_txd}]
set_property REFCLK_FREQUENCY 300.03 [get_cells -hier -filter {NAME =~ *delay_rgmii_tx_ctl}]
set_property REFCLK_FREQUENCY 300.03 [get_cells -hier -filter {NAME =~ *delay_rgmii_rx_ctl}]
set_property REFCLK_FREQUENCY 300.03 [get_cells -hier -filter {NAME =~ *delay_rgmii_rxd}]

### SFP 1
set_property PACKAGE_PIN R4 [get_ports GT_SERIAL_TX_1_txp];										# SFTDPA
set_property PACKAGE_PIN R3 [get_ports GT_SERIAL_TX_1_txn];										# SFTDNA
set_property PACKAGE_PIN T2 [get_ports GT_SERIAL_RX_1_rxp];										# SFRDPA
set_property PACKAGE_PIN T1 [get_ports GT_SERIAL_RX_1_rxn];										# SFRDNA

set_property PACKAGE_PIN Y5 [get_ports GT_DIFF_REFCLK_1_clk_n];									# GTHRCK0N
set_property PACKAGE_PIN Y6 [get_ports GT_DIFF_REFCLK_1_clk_p];									# GTHRCK0P

set_property -dict {PACKAGE_PIN Y10 IOSTANDARD LVCMOS33} [get_ports o_sfp_1_tx_en];				# SFTDISA
set_property -dict {PACKAGE_PIN J12 IOSTANDARD LVCMOS33} [get_ports i_sfp_1_los];				# SFRLOSA
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports i_sfp_1_tx_fault];			# SFTFLTA
set_property -dict {PACKAGE_PIN W10 IOSTANDARD LVCMOS33} [get_ports i_sfp_1_module_en];			# SFMABSA

set_property -dict {PACKAGE_PIN G11 IOSTANDARD LVCMOS33} [get_ports o_g_led_1];					# SFLNKA~
set_property -dict {PACKAGE_PIN F10 IOSTANDARD LVCMOS33} [get_ports o_y_led_1];					# SFACTA~

### SFP 2
set_property PACKAGE_PIN N4 [get_ports GT_SERIAL_TX_2_txp];										# SFTDPB
set_property PACKAGE_PIN N3 [get_ports GT_SERIAL_TX_2_txn];										# SFTDNB
set_property PACKAGE_PIN P2 [get_ports GT_SERIAL_RX_2_rxp];										# SFRDPB
set_property PACKAGE_PIN P1 [get_ports GT_SERIAL_RX_2_rxn];										# SFRDNB

set_property PACKAGE_PIN V5 [get_ports GT_DIFF_REFCLK_2_clk_n];									# GTHRCK1N
set_property PACKAGE_PIN V6 [get_ports GT_DIFF_REFCLK_2_clk_p];									# GTHRCK1P

set_property -dict {PACKAGE_PIN G10 IOSTANDARD LVCMOS33} [get_ports o_sfp_2_tx_en];				# SFTDISB
set_property -dict {PACKAGE_PIN E10 IOSTANDARD LVCMOS33} [get_ports i_sfp_2_los];				# SFRLOSB
set_property -dict {PACKAGE_PIN H11 IOSTANDARD LVCMOS33} [get_ports i_sfp_2_tx_fault];			# SFTFLTB
set_property -dict {PACKAGE_PIN H12 IOSTANDARD LVCMOS33} [get_ports i_sfp_2_module_en];			# SFMABSB

set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports o_g_led_2];					# SFLNKB~
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports o_y_led_2];					# SFACTB~

### LAN 1	
set_property -dict { PACKAGE_PIN G3		IOSTANDARD LVCMOS18 } [get_ports lan_1_mdio_mdc];		# EMDCA
set_property -dict { PACKAGE_PIN F3		IOSTANDARD LVCMOS18 } [get_ports lan_1_mdio_mdio_io];	# EMDIOA
set_property -dict { PACKAGE_PIN B1		IOSTANDARD LVCMOS18 } [get_ports lan_1_phy_reset];		# ENMREA~
set_property -dict { PACKAGE_PIN D4		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_rxc];		# ERXCKA
set_property -dict { PACKAGE_PIN A4		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_rx_ctl];	# ERXCTLA
set_property -dict { PACKAGE_PIN A1		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_rd[0]];	# ERXD0A
set_property -dict { PACKAGE_PIN B3		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_rd[1]];	# ERXD1A
set_property -dict { PACKAGE_PIN A3		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_rd[2]];	# ERXD2A
set_property -dict { PACKAGE_PIN B4		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_rd[3]];	# ERXD3A
set_property -dict { PACKAGE_PIN A2		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_txc];		# EGTCKA
set_property -dict { PACKAGE_PIN F1		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_tx_ctl];	# ETXCTLA
set_property -dict { PACKAGE_PIN E1		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_td[0]];	# ETXD0A
set_property -dict { PACKAGE_PIN D1		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_td[1]];	# ETXD1A
set_property -dict { PACKAGE_PIN F2		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_td[2]];	# ETXD2A
set_property -dict { PACKAGE_PIN E2		IOSTANDARD LVCMOS18 } [get_ports lan_1_rgmii_td[3]];	# ETXD3A

### LAN 2
set_property -dict { PACKAGE_PIN R8		IOSTANDARD LVCMOS18 } [get_ports lan_2_mdio_mdc];		# EMDCB
set_property -dict { PACKAGE_PIN T8		IOSTANDARD LVCMOS18 } [get_ports lan_2_mdio_mdio_io];	# EMDIOB
set_property -dict { PACKAGE_PIN K1		IOSTANDARD LVCMOS18 } [get_ports lan_2_phy_reset];		# ENMREB~
set_property -dict { PACKAGE_PIN K4		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_rxc];		# ERXCKB
set_property -dict { PACKAGE_PIN H3		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_rx_ctl];	# ERXCTLB
set_property -dict { PACKAGE_PIN H1		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_rd[0]];	# ERXD0B
set_property -dict { PACKAGE_PIN K2		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_rd[1]];	# ERXD1B
set_property -dict { PACKAGE_PIN J2		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_rd[2]];	# ERXD2B
set_property -dict { PACKAGE_PIN H4		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_rd[3]];	# ERXD3B
set_property -dict { PACKAGE_PIN J1		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_txc];		# EGTCKB
set_property -dict { PACKAGE_PIN Y8		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_tx_ctl];	# ETXCTLB
set_property -dict { PACKAGE_PIN U9		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_td[0]];	# ETXD0B
set_property -dict { PACKAGE_PIN V9		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_td[1]];	# ETXD1B
set_property -dict { PACKAGE_PIN U8		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_td[2]];	# ETXD2B
set_property -dict { PACKAGE_PIN V8		IOSTANDARD LVCMOS18 } [get_ports lan_2_rgmii_td[3]];	# ETXD3B

### ADC_v1_0
# Voltage ADC
set_property -dict { PACKAGE_PIN AH8	IOSTANDARD LVCMOS18 } [get_ports v_adc_spi_miso];	# MSDADC0A
set_property -dict { PACKAGE_PIN AF7	IOSTANDARD LVCMOS18 } [get_ports i_v_adc_busy];		# MBYADCA
set_property -dict { PACKAGE_PIN AE8	IOSTANDARD LVCMOS18 } [get_ports v_adc_spi_n_cs];	# MCSADCA~
set_property -dict { PACKAGE_PIN AB8	IOSTANDARD LVCMOS18 } [get_ports v_adc_spi_clk];	# MSKADCA
set_property -dict { PACKAGE_PIN AC8	IOSTANDARD LVCMOS18 } [get_ports v_adc_spi_mosi];	# MSCADCA
set_property -dict { PACKAGE_PIN AE9	IOSTANDARD LVCMOS18 } [get_ports o_v_adc_cnv];		# MSTADCA

# Current ADC
set_property -dict { PACKAGE_PIN AC4	IOSTANDARD LVCMOS18 } [get_ports c_adc_spi_miso];	# MSDADC0B
set_property -dict { PACKAGE_PIN AF6	IOSTANDARD LVCMOS18 } [get_ports i_c_adc_busy];  	# MBYADCB
set_property -dict { PACKAGE_PIN AE7	IOSTANDARD LVCMOS18 } [get_ports c_adc_spi_n_cs];	# MCSADCB~
set_property -dict { PACKAGE_PIN AB7	IOSTANDARD LVCMOS18 } [get_ports c_adc_spi_clk];	# MSKADCB
set_property -dict { PACKAGE_PIN AC7	IOSTANDARD LVCMOS18 } [get_ports c_adc_spi_mosi];	# MSCADCB
set_property -dict { PACKAGE_PIN AD7	IOSTANDARD LVCMOS18 } [get_ports o_c_adc_cnv];		# MSTADCB

# DC-Link ADC
set_property -dict { PACKAGE_PIN J11	IOSTANDARD LVCMOS33 } [get_ports i_dc_adc_rvs];		# RVADCC
set_property -dict { PACKAGE_PIN J10	IOSTANDARD LVCMOS33 } [get_ports dc_adc_spi_miso];	# SDADCC
set_property -dict { PACKAGE_PIN K13	IOSTANDARD LVCMOS33 } [get_ports dc_adc_spi_clk];	# SKADCC
set_property -dict { PACKAGE_PIN K12	IOSTANDARD LVCMOS33 } [get_ports o_dc_adc_cnv];		# CSADCC~
set_property -dict { PACKAGE_PIN E12	IOSTANDARD LVCMOS33 } [get_ports dc_adc_spi_mosi];	# SCADCC

# ADC Reset
set_property -dict { PACKAGE_PIN AG8	IOSTANDARD LVCMOS18 } [get_ports o_adc_ext_rst];	# MMRADCS~

### DSP_v1_0
# DSP Handshake
set_property -dict { PACKAGE_PIN P7		IOSTANDARD LVCMOS18 } [get_ports i_DSP_intr];		# MXTMP1  DSP : GPIO34
set_property -dict { PACKAGE_PIN P6		IOSTANDARD LVCMOS18 } [get_ports i_valid];			# MXTMP2  DSP : GPIO35
set_property -dict { PACKAGE_PIN AE3	IOSTANDARD LVCMOS18 } [get_ports i_DSP_fail];		# MXTMP3  DSP : GPIO26
set_property -dict { PACKAGE_PIN AF3	IOSTANDARD LVCMOS18 } [get_ports i_DSP_nENPWM];		# MXTMP4  DSP : GPIO27

set_property -dict { PACKAGE_PIN K9		IOSTANDARD LVCMOS18 } [get_ports o_nZ_WE];			# MMTXP1  GPIO32
set_property -dict { PACKAGE_PIN J9		IOSTANDARD LVCMOS18 } [get_ports o_Ready];			# MMTXP2  GPIO33
set_property -dict { PACKAGE_PIN AD5	IOSTANDARD LVCMOS18 } [get_ports o_Hart_beat];		# MMTXP3  GPIO30
set_property -dict { PACKAGE_PIN D5		IOSTANDARD LVCMOS18 } [get_ports o_nMENPWM];		# MENPWM~

# DSP Data Bus, Clock
#set_property -dict { PACKAGE_PIN AC12	IOSTANDARD LVCMOS33 } [get_ports i_CLK_DSP];		# i_CLK_DSP
set_property -dict { PACKAGE_PIN Y9		IOSTANDARD LVCMOS33 } [get_ports i_nZ_B_CS];		# i_nZ_B_CS
set_property -dict { PACKAGE_PIN AB10	IOSTANDARD LVCMOS33 } [get_ports i_nZ_B_WE];		# i_nZ_B_WE

# DSP Data Bus
set_property -dict { PACKAGE_PIN AD15	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[0]];     # io_Z_B_XD[0]
set_property -dict { PACKAGE_PIN AD14	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[1]];     # io_Z_B_XD[1]
set_property -dict { PACKAGE_PIN AE15	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[2]];     # io_Z_B_XD[2]
set_property -dict { PACKAGE_PIN AE14	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[3]];     # io_Z_B_XD[3]
set_property -dict { PACKAGE_PIN AG14	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[4]];     # io_Z_B_XD[4]
set_property -dict { PACKAGE_PIN AH14	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[5]];     # io_Z_B_XD[5]
set_property -dict { PACKAGE_PIN AG13	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[6]];     # io_Z_B_XD[6]
set_property -dict { PACKAGE_PIN AH13	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[7]];     # io_Z_B_XD[7]
set_property -dict { PACKAGE_PIN AC14	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[8]];     # io_Z_B_XD[8]
set_property -dict { PACKAGE_PIN AC13	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[9]];     # io_Z_B_XD[9]
set_property -dict { PACKAGE_PIN AE13	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[10]];    # io_Z_B_XD[10]
set_property -dict { PACKAGE_PIN AF13	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[11]];    # io_Z_B_XD[11]
set_property -dict { PACKAGE_PIN AA13	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[12]];    # io_Z_B_XD[12]
set_property -dict { PACKAGE_PIN AB13	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[13]];    # io_Z_B_XD[13]
set_property -dict { PACKAGE_PIN W14	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[14]];	# io_Z_B_XD[14]
set_property -dict { PACKAGE_PIN W13	IOSTANDARD LVCMOS33 } [get_ports io_Z_B_XD[15]];	# io_Z_B_XD[15]

# DSP Addr Bus
set_property -dict { PACKAGE_PIN AB15	IOSTANDARD LVCMOS33 } [get_ports i_Z_B_XA[0]];		# i_Z_B_XA [0]
set_property -dict { PACKAGE_PIN AB14	IOSTANDARD LVCMOS33 } [get_ports i_Z_B_XA[1]];		# i_Z_B_XA [1]
set_property -dict { PACKAGE_PIN Y14	IOSTANDARD LVCMOS33 } [get_ports i_Z_B_XA[2]];		# i_Z_B_XA [2]
set_property -dict { PACKAGE_PIN Y13	IOSTANDARD LVCMOS33 } [get_ports i_Z_B_XA[3]];		# i_Z_B_XA [3]
set_property -dict { PACKAGE_PIN W12	IOSTANDARD LVCMOS33 } [get_ports i_Z_B_XA[4]];		# i_Z_B_XA [4]
set_property -dict { PACKAGE_PIN W11	IOSTANDARD LVCMOS33 } [get_ports i_Z_B_XA[5]];		# i_Z_B_XA [5]
set_property -dict { PACKAGE_PIN Y12	IOSTANDARD LVCMOS33 } [get_ports i_Z_B_XA[6]];		# i_Z_B_XA [6]
set_property -dict { PACKAGE_PIN AA12	IOSTANDARD LVCMOS33 } [get_ports i_Z_B_XA[7]];		# i_Z_B_XA [7]
set_property -dict { PACKAGE_PIN AA11	IOSTANDARD LVCMOS33 } [get_ports i_Z_B_XA[8]];		# i_Z_B_XA [8]

# External Interlock
set_property -dict { PACKAGE_PIN AD11	IOSTANDARD LVCMOS33 } [get_ports o_intl_ext1];		# NILKO1~
set_property -dict { PACKAGE_PIN AD10	IOSTANDARD LVCMOS33 } [get_ports o_intl_ext2];		# NILKO2~
set_property -dict { PACKAGE_PIN AD12	IOSTANDARD LVCMOS33 } [get_ports o_intl_ext3];		# NILKO3~
set_property -dict { PACKAGE_PIN AE10	IOSTANDARD LVCMOS33 } [get_ports o_intl_ext4];		# NILKO4~

set_property -dict { PACKAGE_PIN G1		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext1];		# MILKI1
set_property -dict { PACKAGE_PIN C4		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext2];		# MILKI2
set_property -dict { PACKAGE_PIN K8		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext3];		# MILKI3
set_property -dict { PACKAGE_PIN K7		IOSTANDARD LVCMOS18 } [get_ports i_intl_ext4];		# MILKI4

set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_ports i_intl_ext1];
set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_ports i_intl_ext2];
set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_ports i_intl_ext3];
set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_ports i_intl_ext4];

# Interlock
set_property -dict { PACKAGE_PIN D7		IOSTANDARD LVCMOS18 } [get_ports i_intl_POC];		# MINOCF
set_property -dict { PACKAGE_PIN E5		IOSTANDARD LVCMOS18 } [get_ports i_intl_OC];		# MOCDETF
set_property -dict { PACKAGE_PIN G6		IOSTANDARD LVCMOS18 } [get_ports i_intl_OV];		# MPCHKS
set_property -dict { PACKAGE_PIN F6		IOSTANDARD LVCMOS18 } [get_ports i_intl_OH];		# MOHSS (전력보드 TP202)

# Interlock Reset
set_property -dict { PACKAGE_PIN F8		IOSTANDARD LVCMOS18 } [get_ports i_sys_rst_flag];	# MONXRST~
set_property -dict { PACKAGE_PIN F7		IOSTANDARD LVCMOS18 } [get_ports o_intl_OC_rst];	# MCLOCF~
set_property -dict { PACKAGE_PIN E8		IOSTANDARD LVCMOS18 } [get_ports o_intl_POC_rst];	# MINOCMR

# System Control
set_property -dict { PACKAGE_PIN AF10	IOSTANDARD LVCMOS33 } [get_ports i_ext_trg];		# MEXTRG~
set_property -dict { PACKAGE_PIN D11	IOSTANDARD LVCMOS33 } [get_ports o_en_dsp_boot];	# ENSOMBT~
set_property -dict { PACKAGE_PIN B10	IOSTANDARD LVCMOS33 } [get_ports o_sys_rst];		# ENSOMMR
set_property -dict { PACKAGE_PIN H9		IOSTANDARD LVCMOS18 } [get_ports o_en_dsp_buf_ctrl];# MENLLS
set_property -dict { PACKAGE_PIN G8		IOSTANDARD LVCMOS18 } [get_ports o_eeprom_rst];		# WEMEEP~

# Test Point
set_property -dict { PACKAGE_PIN D6		IOSTANDARD LVCMOS18 } [get_ports o_SP601];			# MDOER1
set_property -dict { PACKAGE_PIN L7		IOSTANDARD LVCMOS18 } [get_ports o_SP1005];			# SP1005
set_property -dict { PACKAGE_PIN L6		IOSTANDARD LVCMOS18 } [get_ports o_SP1006];			# SP1006
set_property -dict { PACKAGE_PIN AC9	IOSTANDARD LVCMOS18 } [get_ports i_SP1010];			# SP1010
set_property -dict { PACKAGE_PIN AD9	IOSTANDARD LVCMOS18 } [get_ports i_SP1011];			# SP1011

# FRONT
set_property -dict { PACKAGE_PIN AE12   IOSTANDARD LVCMOS33 } [get_ports front_sw_spi_clk];		# SKSPI
set_property -dict { PACKAGE_PIN AF12   IOSTANDARD LVCMOS33 } [get_ports o_lcd_cs];				# nCSODM  
set_property -dict { PACKAGE_PIN AG10   IOSTANDARD LVCMOS33 } [get_ports o_sw_cs];				# nCSIOE
set_property -dict { PACKAGE_PIN AH10   IOSTANDARD LVCMOS33 } [get_ports front_sw_spi_mosi];	# SCSPI
set_property -dict { PACKAGE_PIN AF11   IOSTANDARD LVCMOS33 } [get_ports front_sw_spi_miso];	# SDSPI
set_property -dict { PACKAGE_PIN AG11   IOSTANDARD LVCMOS33 } [get_ports i_sw_intr];			# nINTKY
set_property -dict { PACKAGE_PIN AH12   IOSTANDARD LVCMOS33 } [get_ports i_ro_enc_state_a];		# ENCKYA
set_property -dict { PACKAGE_PIN AH11   IOSTANDARD LVCMOS33 } [get_ports i_ro_enc_state_b];		# ENCKYB