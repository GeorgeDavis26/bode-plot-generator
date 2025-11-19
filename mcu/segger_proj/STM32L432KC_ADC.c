// STM32L432KC_ADC.c
// Source code for ADC1 functions

#include "STM32L432KC_ADC.h"
#include "STM32L432KC_TIM.h"

void configureADC(void) {
    ///////////////////////// ADC CLK /////////////////////////////
    RCC->AHB2ENR |= RCC_AHB2ENR_ADCEN;
    //ADC clk derived from the AHB clock do not need to respect clk constraints because no injected channels are being used
    RCC->CCIPR |= _VAL2FLD(RCC_CCIPR_ADCSEL, SYSCLK_SEL_ADC);

    ///////////////////////// ADC CALIBRATION /////////////////////////////
    ADC1->CR &= ~ADC_CR_ADEN;       //Make sure the ADC is not enabled
    ADC1->CR &= ~ADC_CR_DEEPPWD;    // To start ADC first exit Deep-power-down mode

    ADC1->CR |= ADC_CR_ADVREGEN;    //ADC1 Voltage Regulator Enable
    delay_micros(TIM15, 50);  // software has to wait for startup time
    
    //ADC1->CR |= ADC_CR_ADCALDIF;     //Differential mode for calibration

    ADC1->CR |= ADC_CR_ADCAL;     //Run Calibration Protocol
    while (ADC1->CR & ADC_CR_ADCAL);

    //////////////////////////ADC DR CONFIGURATION////////////////////////////
    ADC1->CFGR &= ~ADC_CFGR_RES;    //Data Resolution
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_RES, SIX_BIT_ADC1_RES);

    ADC1->SMPR1 |= _VAL2FLD(ADC_SMPR1_SMP7, ADC_SAMPLETIME_247CYCLES_5); //ADC1 sample time register 246.5 ADC1 clock cycles

    ADC1->CFGR &= ~ADC_CFGR_CONT;    //single conversion mode for regular conversions

    ADC1->SQR1 &= ~ADC_SQR1_L; //clear conversion count
    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_L, 0); //1 conversion

    ADC1->SQR1 &= ~ADC_SQR1_SQ1; //clear sequence order
    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_SQ1, ADC1_IN7); //1st conversion regular sequence to IN7

    //////////////////////////ENABLE ADC1////////////////////////////
    ADC1->CR |= ADC_CR_ADEN;
    while (ADC1->ISR & ADC_ISR_ADRDY);
}