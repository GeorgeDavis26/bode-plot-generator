// STM32L432KC_ADC.h
// Header for ADC1 functions

#ifndef STM32L4_ADC_H
#define STM32L4_ADC_H
#include <stdint.h>
#include <stdint.h>
#include <stm32l432xx.h>
///////////////////////////////////////////////////////////////////////////////
// Definitions
///////////////////////////////////////////////////////////////////////////////

//Values for ADC1 Data Resolution
#define TWELVE_BIT_ADC1_RES  0 // Value to set ADC_CFG_RES[1:0] to 12-bit resolution
#define TEN_BIT_ADC1_RES     1 // Value to set ADC_CFG_RES[1:0] to 10-bit resolution
#define EIGHT_BIT_ADC1_RES   2 // Value to set ADC_CFG_RES[1:0] to 8-bit resolution
#define SIX_BIT_ADC1_RES     3 // Value to set ADC_CFG_RES[1:0] to 6-bit resolution

#define TWELVE_BIT_ADC1_RES_SCALAR  (2e11)*1.0
#define TEN_BIT_ADC1_RES_SCALAR     (2e9)*1.0
#define EIGHT_BIT_ADC1_RES_SCALAR   (2e7)*1.0
#define SIX_BIT_ADC1_RES_SCALAR     (2e5)*1.0

#define ADC1_IN7 7 //PA2 or ADC1_IN7

#define SYSCLK_SEL_ADC 3 // System clock selected as ADCs clock

#define ADC_SAMPLETIME_2CYCLES_5    0 // 2.5 ADC clock cycles
#define ADC_SAMPLETIME_6CYCLES_5    1 // 6.5 ADC clock cycles
#define ADC_SAMPLETIME_12CYCLES_5   2 // 12.5 ADC clock cycles
#define ADC_SAMPLETIME_24CYCLES_5   3 // 24.5 ADC clock cycles
#define ADC_SAMPLETIME_47CYCLES_5   4 // 47.5 ADC clock cycles
#define ADC_SAMPLETIME_92CYCLES_5   5 // 92.5 ADC clock cycles
#define ADC_SAMPLETIME_247CYCLES_5  6 // 247.5 ADC clock cycles
#define ADC_SAMPLETIME_640CYCLES_5  7 // 640.5 ADC clock cycles

#define LED_HIGH 1
#define LED_LOW 0
#define TIMER_FREQ 2000000

#define RESOLUTION_12bit 12

//uint16_t adcBuffer[NUM_FREQUENCIES][NUM_SAMPLES];
///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

void configureADC(void);
//int adcConversion(uint16_t* buffer);
double amplitudeExtractRMS(const uint16_t * sine_array, int num_samples);
double amplitudeExtractPP(const uint16_t * sine_array, int num_samples);
double gainExtract(double RX_amp, int atten);

double phaseExtract(volatile uint32_t *rx_zc_times, volatile uint32_t *tx_zc_times, uint32_t frequency,int num_zero_cross);
#endif