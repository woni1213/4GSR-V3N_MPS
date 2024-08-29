create_clock -period 6.400 -name GT_DIFF_REFCLK1_0_clk_p -waveform {0.000 3.200} [get_ports {GT_DIFF_REFCLK1_0_clk_p}]

set_property PACKAGE_PIN N4 [get_ports GT_SERIAL_TX_0_txp]
set_property PACKAGE_PIN N3 [get_ports GT_SERIAL_TX_0_txn]
set_property PACKAGE_PIN P2 [get_ports GT_SERIAL_RX_0_rxp]
set_property PACKAGE_PIN P1 [get_ports GT_SERIAL_RX_0_rxn]

set_property PACKAGE_PIN Y5 [get_ports GT_DIFF_REFCLK1_0_clk_n]
set_property PACKAGE_PIN Y6 [get_ports GT_DIFF_REFCLK1_0_clk_p]

set_property -dict {PACKAGE_PIN G10 IOSTANDARD LVCMOS33} [get_ports o_sfp_tx_en]
set_property -dict {PACKAGE_PIN E10 IOSTANDARD LVCMOS33} [get_ports i_sfp_los]
set_property -dict {PACKAGE_PIN H11 IOSTANDARD LVCMOS33} [get_ports i_sfp_tx_fault]
set_property -dict {PACKAGE_PIN H12 IOSTANDARD LVCMOS33} [get_ports i_sfp_module_en]

set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports o_g_led]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports o_y_led]

set_property -dict {PACKAGE_PIN D6 IOSTANDARD LVCMOS18} [get_ports o_led_test]

set_property -dict {PACKAGE_PIN H9 IOSTANDARD LVCMOS18} [get_ports MENLLS]