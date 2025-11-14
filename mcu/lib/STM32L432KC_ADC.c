// STM32L432KC_ADC.c
// Source code for ADC functions

#include "STM32L432KC_ADC.h"

void configureADC() {
    //many CFGR registers can't be written to w/o these bits low
    ADC->CR &= ~ADC_CR_ADSTART;
    ADC->CR &= ~ADC_CR_JADSTART;

    //ADC Voltage Regulator Enable
    ADC->CR |= ADC_CR_ADVREGEN;
    delaymilis(1);
    while (!(ADC->CR & ADC_CR_ADVREGEN));

    //Differential mode for calibration
    ADC->CR |= ADC_CR_ADCALDIF;
    //Run Calibration Protocol
    ADC->CR |= ADC_CR_ADCAL;
    while (ADC->CR & ADC_CR_ADCAL);
    
    //Data Resolution
    ADC->CFGR |= _VAL2FLD(ADC_CFGR_RES, SIX_BIT_ADC_RES);

    //ADC sample time register
    ADC->SMPR1 |= _VAL2FLD(ADC_SMPR1_SMP10, 2); //12.5 ADC clock cycles
    
    //Continuous conversion mode for regular conversions
    ADC->CFGR |= ADC_CR_CONT;

    //Conversion order and count
    ADC->SQR1 |= _VAL2FLD(ADC_SQR1_T, 0); //1 conversion
    ADC->SQR1 |= _VAL2FLD(ADC_SQR1_SQ1, ADC1_IN10); //1st conversion regular sequence to IN10
    // Enable ADC
    ADC->CR |= ADC_CR_ADEN;
}
