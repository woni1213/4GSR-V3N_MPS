
##SFP
set_property LOC Y10 [get_ports o_sfp_tx_disable[0]]
set_property IOSTANDARD LVCMOS33 [get_ports o_sfp_tx_disable[0]]

set_property LOC G10 [get_ports o_sfp_tx_disable[1]]
set_property IOSTANDARD LVCMOS33 [get_ports o_sfp_tx_disable[1]]


set_property LOC Y6 [get_ports diff_clk_p]           
set_property LOC Y5 [get_ports diff_clk_n]

create_clock -name diff_clk_p -period 8.0 [get_ports diff_clk_p]



set_property LOC R4 [get_ports sfp_0_txp]
set_property LOC R3 [get_ports sfp_0_txn]
set_property LOC T2 [get_ports sfp_0_rxp]
set_property LOC T1 [get_ports sfp_0_rxn]

set_property LOC N4 [get_ports sfp_1_txp]
set_property LOC N3 [get_ports sfp_1_txn]
set_property LOC P2 [get_ports sfp_1_rxp]
set_property LOC P1 [get_ports sfp_1_rxn]

##UART
set_property -dict { PACKAGE_PIN B11   IOSTANDARD LVCMOS33 } [get_ports { uart_txd }];         # Tx
set_property -dict { PACKAGE_PIN A12   IOSTANDARD LVCMOS33 } [get_ports { uart_rxd }];         # Rx

##PL_Ethernet
set_property PACKAGE_PIN C3 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS18 [get_ports sys_clk]

set_property PACKAGE_PIN G3 [get_ports {mdio_0_mdc          }]
set_property PACKAGE_PIN F3 [get_ports {mdio_0_mdio_io      }]
set_property PACKAGE_PIN B1 [get_ports {phy_rst_n_0         }]
set_property PACKAGE_PIN D4 [get_ports {rgmii_0_rxc         }]
set_property PACKAGE_PIN A4 [get_ports {rgmii_0_rx_ctl      }]
set_property PACKAGE_PIN A1 [get_ports {rgmii_0_rd[0]       }]
set_property PACKAGE_PIN B3 [get_ports {rgmii_0_rd[1]       }]
set_property PACKAGE_PIN A3 [get_ports {rgmii_0_rd[2]       }]
set_property PACKAGE_PIN B4 [get_ports {rgmii_0_rd[3]       }]
set_property PACKAGE_PIN A2 [get_ports {rgmii_0_txc         }]
set_property PACKAGE_PIN F1 [get_ports {rgmii_0_tx_ctl      }]
set_property PACKAGE_PIN E1 [get_ports {rgmii_0_td[0]       }]
set_property PACKAGE_PIN D1 [get_ports {rgmii_0_td[1]       }]
set_property PACKAGE_PIN F2 [get_ports {rgmii_0_td[2]       }]
set_property PACKAGE_PIN E2 [get_ports {rgmii_0_td[3]       }]

set_property IOSTANDARD LVCMOS18 [get_ports {mdio_0_mdc          }]
set_property IOSTANDARD LVCMOS18 [get_ports {mdio_0_mdio_io      }]
set_property IOSTANDARD LVCMOS18 [get_ports {phy_rst_n_0         }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_0_rxc         }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_0_rx_ctl      }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_0_rd[0]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_0_rd[1]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_0_rd[2]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_0_rd[3]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_0_txc         }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_0_tx_ctl      }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_0_td[0]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_0_td[1]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_0_td[2]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_0_td[3]       }]

set_property PACKAGE_PIN R8 [get_ports {mdio_1_mdc          }]
set_property PACKAGE_PIN T8 [get_ports {mdio_1_mdio_io      }]
set_property PACKAGE_PIN K1 [get_ports {phy_rst_n_1         }]
set_property PACKAGE_PIN K4 [get_ports {rgmii_1_rxc         }]
set_property PACKAGE_PIN H3 [get_ports {rgmii_1_rx_ctl      }]
set_property PACKAGE_PIN H1 [get_ports {rgmii_1_rd[0]       }]
set_property PACKAGE_PIN K2 [get_ports {rgmii_1_rd[1]       }]
set_property PACKAGE_PIN J2 [get_ports {rgmii_1_rd[2]       }]
set_property PACKAGE_PIN H4 [get_ports {rgmii_1_rd[3]       }]
set_property PACKAGE_PIN J1 [get_ports {rgmii_1_txc         }]
set_property PACKAGE_PIN Y8 [get_ports {rgmii_1_tx_ctl      }]
set_property PACKAGE_PIN U9 [get_ports {rgmii_1_td[0]       }]
set_property PACKAGE_PIN V9 [get_ports {rgmii_1_td[1]       }]
set_property PACKAGE_PIN U8 [get_ports {rgmii_1_td[2]       }]
set_property PACKAGE_PIN V8 [get_ports {rgmii_1_td[3]       }]

set_property IOSTANDARD LVCMOS18 [get_ports {mdio_1_mdc          }]
set_property IOSTANDARD LVCMOS18 [get_ports {mdio_1_mdio_io      }]
set_property IOSTANDARD LVCMOS18 [get_ports {phy_rst_n_1         }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_1_rxc         }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_1_rx_ctl      }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_1_rd[0]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_1_rd[1]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_1_rd[2]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_1_rd[3]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_1_txc         }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_1_tx_ctl      }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_1_td[0]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_1_td[1]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_1_td[2]       }]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_1_td[3]       }]


### SFP_State

set_property -dict { PACKAGE_PIN G11  IOSTANDARD LVCMOS33 } [get_ports { o_SFP_A_Link_LED }];       # o_SFP_A_Link_LED
set_property -dict { PACKAGE_PIN F10  IOSTANDARD LVCMOS33 } [get_ports { o_SFP_A_Act_LED }];        # o_SFP_A_Act_LED
set_property -dict { PACKAGE_PIN D10  IOSTANDARD LVCMOS33 } [get_ports { o_SFP_B_Link_LED }];       # o_SFP_B_Link_LED
set_property -dict { PACKAGE_PIN C11  IOSTANDARD LVCMOS33 } [get_ports { o_SFP_B_Act_LED }];        # o_SFP_B_Act_LED

set_property -dict { PACKAGE_PIN W10   IOSTANDARD LVCMOS33 } [get_ports { i_SFP_A_MODABS }];        # i_SFP_A_MODABS
set_property -dict { PACKAGE_PIN J12   IOSTANDARD LVCMOS33 } [get_ports { i_SFP_A_LOS }];           # i_SFP_A_LOS
set_property -dict { PACKAGE_PIN A10   IOSTANDARD LVCMOS33 } [get_ports { i_SFP_A_TXFLT }];         # i_SFP_A_TXFLT
set_property -dict { PACKAGE_PIN H12   IOSTANDARD LVCMOS33 } [get_ports { i_SFP_B_MODABS }];        # i_SFP_B_MODABS
set_property -dict { PACKAGE_PIN E10   IOSTANDARD LVCMOS33 } [get_ports { i_SFP_B_LOS }];           # i_SFP_B_LOS
set_property -dict { PACKAGE_PIN H11   IOSTANDARD LVCMOS33 } [get_ports { i_SFP_B_TXFLT }];         # i_SFP_B_TXFLT

### FRONT
set_property -dict { PACKAGE_PIN AE12   IOSTANDARD LVCMOS33 } [get_ports { SKSPI }];     # SKSPI
set_property -dict { PACKAGE_PIN AF12   IOSTANDARD LVCMOS33 } [get_ports { nCSODM }];    # nCSODM  
set_property -dict { PACKAGE_PIN AG10   IOSTANDARD LVCMOS33 } [get_ports { nCSIOE }];    # nCSIOE
set_property -dict { PACKAGE_PIN AH10   IOSTANDARD LVCMOS33 } [get_ports { SCSPI }];     # SCSPI
set_property -dict { PACKAGE_PIN AF11   IOSTANDARD LVCMOS33 } [get_ports { SDSPI }];     # SDSPI
set_property -dict { PACKAGE_PIN AG11   IOSTANDARD LVCMOS33 } [get_ports { nINTKY }];    # nINTKY
set_property -dict { PACKAGE_PIN AH12   IOSTANDARD LVCMOS33 } [get_ports { ENCKYA }];    # ENCKYA
set_property -dict { PACKAGE_PIN AH11   IOSTANDARD LVCMOS33 } [get_ports { ENCKYB }];    # ENCKYB


#set_property -dict { PACKAGE_PIN AA10   IOSTANDARD LVCMOS33 } [get_ports { i_Z_B_XA[9] }];     # i_Z_B_XA [9] # 사용 않함


######################################################################################################################

# SOM240_2 Connector Pinout

### ADC_v1_0
# Voltage ADC
set_property -dict { PACKAGE_PIN AH8	IOSTANDARD LVCMOS18 } [get_ports miso_0];			# MSDADC0A
set_property -dict { PACKAGE_PIN AE8	IOSTANDARD LVCMOS18 } [get_ports n_cs_0];   		# MCSADCA~
set_property -dict { PACKAGE_PIN AB8	IOSTANDARD LVCMOS18 } [get_ports spi_clk_0];   		# MSKADCA
set_property -dict { PACKAGE_PIN AC8	IOSTANDARD LVCMOS18 } [get_ports mosi_0];   		# MSCADCA
set_property -dict { PACKAGE_PIN AE9	IOSTANDARD LVCMOS18 } [get_ports o_v_c_adc_cnv_0];	# MSTADCA

# Current ADC
set_property -dict { PACKAGE_PIN AC4	IOSTANDARD LVCMOS18 } [get_ports miso_1];   		# MSDADC0B
set_property -dict { PACKAGE_PIN AF6	IOSTANDARD LVCMOS18 } [get_ports i_c_adc_busy_0];  	# MBYADCB
set_property -dict { PACKAGE_PIN AE7	IOSTANDARD LVCMOS18 } [get_ports n_cs_1];   		# MCSADCB~
set_property -dict { PACKAGE_PIN AB7	IOSTANDARD LVCMOS18 } [get_ports spi_clk_1];   		# MSKADCB
set_property -dict { PACKAGE_PIN AC7	IOSTANDARD LVCMOS18 } [get_ports mosi_1];   		# MSCADCB
set_property -dict { PACKAGE_PIN AD7	IOSTANDARD LVCMOS18 } [get_ports o_v_c_adc_cnv_1];	# MSTADCB

# DC-Link ADC
set_property -dict { PACKAGE_PIN J11	IOSTANDARD LVCMOS33 } [get_ports i_dc_adc_rvs_0];	# RVADCC
set_property -dict { PACKAGE_PIN J10	IOSTANDARD LVCMOS33 } [get_ports miso_2];			# SDADCC
set_property -dict { PACKAGE_PIN K13	IOSTANDARD LVCMOS33 } [get_ports spi_clk_2];		# SKADCC
set_property -dict { PACKAGE_PIN K12	IOSTANDARD LVCMOS33 } [get_ports o_dc_adc_cnv_0];	# CSADCC~
set_property -dict { PACKAGE_PIN E12	IOSTANDARD LVCMOS33 } [get_ports mosi_2];			# SCADCC

# ADC Reset
set_property -dict { PACKAGE_PIN AG8	IOSTANDARD LVCMOS18 } [get_ports o_adc_ext_rst_0];	# MMRADCS~

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
set_property -dict { PACKAGE_PIN AC12	IOSTANDARD LVCMOS33 } [get_ports i_CLK_DSP];		# i_CLK_DSP
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
set_property -dict { PACKAGE_PIN AD11	IOSTANDARD LVCMOS33 } [get_ports o_ext_IL1];		# NILKO1~
set_property -dict { PACKAGE_PIN AD10	IOSTANDARD LVCMOS33 } [get_ports o_ext_IL2];		# NILKO2~
set_property -dict { PACKAGE_PIN AD12	IOSTANDARD LVCMOS33 } [get_ports o_ext_IL3];		# NILKO3~
set_property -dict { PACKAGE_PIN AE10	IOSTANDARD LVCMOS33 } [get_ports o_ext_IL4];		# NILKO4~

set_property -dict { PACKAGE_PIN G1		IOSTANDARD LVCMOS18 } [get_ports i_ext_IL1];		# MILKI1
set_property -dict { PACKAGE_PIN C4		IOSTANDARD LVCMOS18 } [get_ports i_ext_IL2];		# MILKI2
set_property -dict { PACKAGE_PIN K8		IOSTANDARD LVCMOS18 } [get_ports i_ext_IL3];		# MILKI3
set_property -dict { PACKAGE_PIN K7		IOSTANDARD LVCMOS18 } [get_ports i_ext_IL4];		# MILKI4

set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_ports i_ext_IL1];
set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_ports i_ext_IL2];
set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_ports i_ext_IL3];
set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_ports i_ext_IL4];

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

