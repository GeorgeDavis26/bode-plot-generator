// STM32L432KC_ADC.c
// Source code for ADC1 functions

#include "STM32L432KC_ADC.h"
#include "STM32L432KC_TIM.h"

void configureADC(void) {
    // Enable ADC clock
    RCC->AHB2ENR |= RCC_AHB2ENR_ADCEN;

    // Enable VREFINT channel (internal Vref)
    ADC1_COMMON->CCR |= ADC_CCR_VREFEN;

    //ADC1 Voltage Regulator Enable
    ADC1->CR |= ADC_CR_ADVREGEN;
    delay_millis(TIM15, 1);
    
    //many CFGR registers can't be written to w/o these bits low
    ADC1->CR &= ~ADC_CR_ADSTART;
    ADC1->CR &= ~ADC_CR_JADSTART;

    while (!(ADC1->CR & ADC_CR_ADVREGEN));

    //Differential mode for calibration
    ADC1->CR |= ADC_CR_ADCALDIF;
    //Run Calibration Protocol
    ADC1->CR |= ADC_CR_ADCAL;
    while (ADC1->CR & ADC_CR_ADCAL);
    
    //Data Resolution
    ADC1->CFGR &= ~ADC_CFGR_RES;
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_RES, SIX_BIT_ADC1_RES);

    //ADC1 sample time register
    //ADC1->SMPR1 |= _VAL2FLD(ADC_SMPR2_SMP10, 2); //12.5 ADC1 clock cycles
    
    ///////////////////////// VREFINT TESTING /////////////////////////////

    //ADC1 sample time register for channel 0 
    ADC1->SMPR1 |= _VAL2FLD(ADC_SMPR1_SMP0, 2); //12.5 ADC1 clock cycles

    //////////////////////////////////////////////////////////////////////

    //Continuous conversion mode for regular conversions
    ADC1->CFGR |= ADC_CFGR_CONT;

    //Conversion order and count
    ADC1->SQR1 |= ~ADC_SQR1_L;
    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_L, 0); //1 conversion

    ADC1->SQR1 &= ~ADC_SQR1_SQ1;
    //ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_SQ1, ADC1_IN10); //1st conversion regular sequence to IN10


    ///////////////////////// VREFINT TESTING /////////////////////////////

    //Set channel as the first conversion in the sequence
    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_SQ1, 0); //1st conversion regular sequence to IN0 (VREFINT)

    //////////////////////////////////////////////////////////////////////

    // Enable ADC1
    ADC1->CR |= ADC_CR_ADEN;

}