// STM32L432KC_ADC.c
// Source code for ADC1 functions

#include "STM32L432KC_ADC.h"

void configureADC() {
    //many CFGR registers can't be written to w/o these bits low
    ADC1->CR &= ~ADC_CR_ADSTART;
    ADC1->CR &= ~ADC_CR_JADSTART;

    //ADC1 Voltage Regulator Enable
    ADC1->CR |= ADC_CR_ADVREGEN;
    delay_millis(1);
    while (!(ADC1->CR & ADC_CR_ADVREGEN));

    //Differential mode for calibration
    ADC1->CR |= ADC_CR_ADCALDIF;
    //Run Calibration Protocol
    ADC1->CR |= ADC_CR_ADCAL;
    while (ADC1->CR & ADC_CR_ADCAL);
    
    //Data Resolution
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_RES, SIX_BIT_ADC_RES);

    //ADC1 sample time register
    ADC1->SMPR1 |= _VAL2FLD(ADC_SMPR1_SMP10, 2); //12.5 ADC1 clock cycles
    
    //Continuous conversion mode for regular conversions
    ADC1->CFGR |= ADC_CR_CONT;

    //Conversion order and count
    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_T, 0); //1 conversion
    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_SQ1, ADC1_IN10); //1st conversion regular sequence to IN10
    // Enable ADC1
    ADC1->CR |= ADC_CR_ADEN;
}
