# 4GSR-V3N_MPS - INTLock Module
4GSR의 MPS V3N 제어기 중 Interlock 관련 모듈에 대한 설명이다.  
  
기본적으로 ADC 모듈에서 보내주는 ADC 데이터 (16개의 ADC 데이터를 더한 값)를 기준으로 AXI4-Lite로 설정된 각종 값을 비교하여 Interlock을 설정 및 제어한다.  

Interlock은 H/W, External과 S/W Interlock으로 크게 2가지로 구분되어 있다. H/W Interlock은 말 그대로 회로에서 발생하며 S/W는 사용자가 설정한 값을 비교해서 발생한다.  

OSC, REG를 제외한 Interlock은 발생 조건이 해제되면 바로 Interlock이 해제가 된다. Interlock의 Latch는 상위에서 제어하고 있다.  

해당 항목의 각종 변수들의 이름은 퇴사한 이성진 차장이 지은 이름이다.

---

### 1. ADC Data
ADC Data는 ADC_v1_0 IP에서 연결된다. 출력 전압, 전류 및 DC-Link (SMPS) 전압이 입력되며 출력 전압, 전류는 ADC_Data_Moving_Sum.v에 의해서 16개의 ADC 데이터를 더한 값이다. DC-Link를 제외한 ADC 데이터는 2의 보수형식으로 총 24 Bit이다. 그리고 24 Bit의 데이터를 16번 더해서 총 28 Bit의 데이터로 구성된다.  
OSC와 REG에서 사용할 ADC Data는 MSB(27 Bit - [27:0])를 반전시켜 2의 보수형태를 Offset Binary로 재정렬한다.  

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

#### REG (Regulation)
REG는 출력 전류나 전압을 설정했지만 설정값 까지 도달하지 못한 경우 발생한다. 출력이 재설정(i_x_intl_REG_sp_flag)되면 사용자가 설정한 시간(i_x_intl_REG_delay)동안 Delay를 가진다. 그리고 출력(x_adc_sbc_raw_data)과 설정(i_x_intl_REG_sp)의 절대값(x_intl_REG_abs)과 사용자가 설정한 값(i_x_intl_REG_diff)을 비교한 후 값이 넘어가면 Interlock을 발생시킨다.  
Reset은 OSC와 동일하다.

### 5. Bypass
코드 내 주석 및 코드 참고  

### 6. Test

- 테스트는 ILA를 연결하여 출력되는 파형을 기준으로 테스트한다.  
- 모든 Interlock 출력은 o_intl_state로 AXI에 보낸다.
- 사용자가 설정하는 Threshold 값은 *16해야한다. (ADC Raw Data가 16개의 데이터 합산임)
- OSC, REG는 ***2의 보수 형태가 아니다!***

#### H/W, External Interlock
 - 회로도를 보고 직접 신호를 인가하여 측정함

#### S/W Interlock
 - 캘리브레이터 등의 소스를 이용하여 ADC Data 측정 (16개의 데이터가 합산되는 것을 염두하여)
 - ADC Data 측정 후 OSC, REG를 제외한 Interlock 테스트
 - ADC Data Offset Binary 값(x_adc_sbc_raw_data) 측정 및 비교
 - OSC, REG 테스트

### 7. 기타
 - 테스트 항목 중 추가나 수정해야할 것 같으면 수정해도 됨
 - 간단하게 나마 결과 값은 공유해주길 바람
 - 변수 이름에서 오타가 많을 수 있으니 주의바람