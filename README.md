# 4GSR-V3N_MPS - INTerLock Module
4GSR의 MPS V3N 제어기의 Interlock 관련 모듈에 대한 설명이다.  
  
기본적으로 ADC 모듈에서 보내주는 ADC 데이터 (16개의 ADC 데이터를 더한 값)를 기준으로 AXI4-Lite로 설정된 각종 값을 비교하여 Interlock을 설정 및 제어한다.  

Interlock은 H/W, External과 S/W Interlock으로 크게 2가지로 구분되어 있다. H/W Interlock은 말 그대로 회로에서 발생하며 S/W는 사용자가 설정한 값을 비교해서 발생한다.  

OSC, REGU를 제외한 Interlock은 발생 조건이 해제되면 바로 Interlock이 해제가 된다. Interlock의 Latch는 상위에서 제어하고 있다.  

해당 항목의 각종 변수들의 이름은 퇴사한 이성진 차장이 지은 이름이다.

---

### 1. ADC Data
ADC Data는 ADC_v1_0 IP에서 연결된다. 출력 전압, 전류 및 DC-Link (SMPS) 전압이 입력되며 출력 전압, 전류는 ADC_Data_Moving_Sum.v에 의해서 16개의 ADC 데이터를 더한 값이다. DC-Link를 제외한 ADC 데이터는 2의 보수형식으로 총 24 Bit이다. 그리고 24 Bit의 데이터를 16번 더해서 총 28 Bit의 데이터로 구성된다.  
OSC와 REGU에서 사용할 ADC Data는 MSB(27 Bit - [27:0])를 반전시켜 2의 보수형태를 Offset Binary로 재정렬한다.  

### 2. H/W Interlock
H/W Interlock은 회로상에서 발생하는 Interlock이다. 자세한 Interlock은 Top의 주석을 참조한다.  

### 3. External Interlock
External Interlock은 외부에서 사용하는 Interlock으로서 사용자가 관여할 수 있는 Interlock이다. 입출력 각각 4개씩 총 8개로 구성되어 있으며 인터락 제어와 조건은 현재 미정이다.  

### 4. S/W Interlock
S/W Interlock은 사용자가 설정한 값을 토대로 실제 출력과 비교한 후 Interlock을 발생하는 기능을 한다.  

#### O.C (Over Current)
O.C는 사용자가 설정한 값보다 실제 출력 전류가 높아지면 발생한다. MPS의 극성에 따라서 p와 n으로 구성된다.

#### O.V (Over Voltage)
O.V는 사용자가 설정한 값보다 실제 출력 전압이 높아지면 발생한다. MPS의 극성에 따라서 p와 n으로 구성된다.

#### U.V (Under Voltage)
U.V는 내부 DC-Link (SMPS)의 전압을 감지한다. 사용자가 설정한 값보다 DC-Link의 출력이 낮아지면 발생한다.

#### OSC (Oscillation)
OSC는 출력의 전류나 전압이 발진되면 발생하며 상시로 구동된다. 단위 시간(i_intl_OSC_period)동안 출력(x_adc_sbc_raw_data)의 P-P(x_intl_OSC_adc_max, x_intl_OSC_adc_min)를 측정한 후 설정한 값(i_x_intl_OSC_adc_threshold)보다 높으면 지정한 변수(x_intl_OSC_cnt)에 횟수를 누적한다. 사용자가 설정한 횟수(i_x_intl_OSC_count_threshold)보다 지정한 변수(x_intl_OSC_cnt)가 높아지면 Interlock(x_intl_OSC)을 발생시킨다.  
발생된 Interlock은 Latch 상태가 되며 Clear는 i_intl_rst신호가 인가되어야 한다.  

#### REGU (Regulation)
REGU는 출력 전류나 전압을 설정했지만 설정값 까지 도달하지 못한 경우 발생한다. 출력이 재설정(i_x_intl_REGU_sp_flag)되면 사용자가 설정한 시간(i_x_intl_REGU_delay)동안 Delay를 가진다. 그리고 출력(x_adc_sbc_raw_data)과 설정(i_x_intl_REGU_sp)의 절대값(x_intl_REGU_abs)과 사용자가 설정한 값(i_x_intl_REGU_diff)을 비교한 후 값이 넘어가면 Interlock을 발생시킨다.  
Reset은 OSC와 동일하다.

### 5. Bypass
코드 내 주석 및 코드 참고  

### 6. Test

- 테스트는 ILA를 연결하여 출력되는 파형을 기준으로 테스트한다.  
- 모든 Interlock 출력은 o_intl_state로 AXI에 보낸다.
- 사용자가 설정하는 Threshold 값은 *16해야한다. (ADC Raw Data가 16개의 데이터 합산임)
- OSC, REGU는 ***2의 보수 형태가 아니다!***

#### H/W, External Interlock
 - 회로도를 보고 직접 신호를 인가하여 측정함

#### S/W Interlock
 - 캘리브레이터 등의 소스를 이용하여 ADC Data 측정 (16개의 데이터가 합산되는 것을 염두하여)
 - ADC Data 측정 후 OSC, REGU를 제외한 Interlock 테스트
 - ADC Data Offset Binary 값(x_adc_sbc_raw_data) 측정 및 비교
 - OSC, REGU 테스트

### 7. 기타
 - 테스트 항목 중 추가나 수정해야할 것 같으면 수정해도 됨
 - 간단하게 나마 결과 값은 공유해주길 바람
 - 변수 이름에서 오타가 많을 수 있으니 주의바람

### 8. 추가 test

#### ADC 전류와 전압 Factor
 - C Factor : 0x3da74081 (32'h3da74081 0.081666)
 - V Factor : 0x4244f77b (32'h4244f77b 49.2417)

#### INTL Initialize 변경에 따른 변화
 - eeprom_rst, en_dsp_buf_ctrl, sys_rst, en_dsp_boot 1001	9       : default
 - eeprom_rst, en_dsp_buf_ctrl, sys_rst, en_dsp_boot 1000	8		: 아무 변화 없음
 - eeprom_rst, en_dsp_buf_ctrl, sys_rst, en_dsp_boot 1011	11		: ADC 동작 안 함, i_intr 1(high)로 고정된 상태, i_DSP_clk 느려짐
 - eeprom_rst, en_dsp_buf_ctrl, sys_rst, en_dsp_boot 1101	13		: i_intr 1(high)로 고정된 상태
 - eeprom_rst, en_dsp_buf_ctrl, sys_rst, en_dsp_boot 0001	1		: 아무 변화 없음

# 4GSR-V3N_MPS - FRONT Module
4GSR의 MPS V3N 제어기의 Front Panel 관련 모듈에 대한 설명이다.  

Front Panel은 OLED(LCD)와 Rotary Encoder, LED, Switch가 장착되어 있다. 

### 1. OLED (LCD)
 - NHD-0420CW-AB3
 - 24 Bit SPI (Clock : < 1.2MHz / Clock Width : > 400ns / Delay : > 200ns / CPHA, CPOL : 11)
 - Data Format : US2066.pdf 10page 참조 (데이터 진짜 이상하게 통신하니까 꼭 봐야함)
 - Init 후 PS에서 RAM addr 4부터 쓴 데이터를 그대로 SPI로 전송함
 - SPI 1st Byte : 0xF8 - Command / 0xFA - Data
 - SPI 2, 3rd Byte : ASCII Code 역순으로 나눠서 보내야함
 - ASCII Code : 데이터의 순서가 7654 3210 이라면 보낼때는 2nd : 01230000 3rd : 45670000으로 보내야함 (데이터시트 및 조민규 과장 참조)  

### 2. Switch
 - MCP23S17 (GPIO 8 Channel X 2)
 - 24 Bit SPI (Clock : < 10MHz / Clock Width : > 45ns / Delay : > 50ns / CPHA, CPOL : 11)
 - Switch Interrupt(~i_sw_intr)가 발생하면 FSM이 동작함. RAM addr 2, 3일 때 동작하며 2이면 LED, 3이면 Switch의 신호를 입력받는다.
 - Init (PS)  
 1. 0x40000f : IODIRA (A Channel 0 ~ 3 Input Setup)
 2. 0x400100 : IODIRB (B Channel 0 ~ 7 Output Setup)
 3. 0x40040f : GPINTENA (A Channel 0 ~ 3 Interrupt Control Setup)
 4. 0x40060f : DEFVALA (A Channel 0 ~ 3 Interrupt 비교 값 Setup. 입력 값과 비교 값이 다르면 Interrupt 발생)
 5. 0x40080f : INTCONA (A Channel 0 ~ 3 DEFVAL 비트와 비교)
 6. 0x400c0f : GPPUA (A Channel 0 ~ 3 100KOhm Pullup Resistor Enable)  

 - Read  
 1. RAM addr 3에 써줌
 2. 0x4112ff : GPIOA (A Channel Read)  

### 3. LED
 - RAM addr 2
 - Write  
 1. RAM addr 2에 써줌
 2. 0x4013xx : GPIOB (B Channel Write), 테스트 필요

### 4. Rotary Encoder
 - Timing은 데이터시트 참조
 - a,b 2개의 신호가 HH or LL일 때 FSM이 동작하며 a나 b의 상태가 바뀜으로 CW, CCW가 결정된다.

### 5. RAM
 - 24 Bit / 256 Len / Single Clock
 - M : PS / S : PL
 - 0 : IDLE
 - 1 : SPI Data Length
 - 2, 3 : LED, Switch
 - 4 이상 : LCD SPI Data

### 6. Block Design
 - SPI IP는 1개를 사용하여 LCD와 SW 범용으로 사용한다.
 - SPI의 CS는 FRONT_v1_0_Top.v에 assign으로 정의(o_lcd_cs, o_sw_cs)되어 있다.
 - SPI, DPBRAM Parameter 설정해야함

### 7. Test
#### LCD Test
- Init Test  
전원을 인가한 후 LCD 화면을 확인한다.

- LCD Test  
모든 LCD 데이터는 RAM을 통해서 쓸 데이터를 저장한다. LCD에 쓸 데이터를 RAM 4번째 주소부터 작성한다. RAM의 데이터를 그대로 보내는 것에 유의해야한다. RAM에 저장이 완료가 되면 완료 신호(o_lcd_sw_start)를 보내고 난 후 Clear를 해준다.  

#### LED / Switch Test
- PS에서 Init  
위의 항목 참조. 데이터는 2개씩 나눠서 보내야함 (addr : 2, 3이 LED, Switch임)  

- LED Test  
RAM의 addr에 LED데이터를 써준다. 데이터 포맷 등은 위의 LED 항목을 참조한다.

- Switch Test  
1. 스위치를 누르면 Interrupt(~i_sw_intr)가 발생한다. 
2. Switch Data (sw_data)를 확인한다.
3. Interrupt를 Clear(i_sw_intr_clear)한다.

#### Rotary Switch Test
1. Dial을 움직이며 o_ro_en_data를 확인한다.