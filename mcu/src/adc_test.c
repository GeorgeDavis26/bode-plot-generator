/*
    adc_test: ADC test file to run ADC drivers and
    store recorded values in a struct to be later
    plotted on the website
*/

#include <stdio.h>
#include <stm32l432xx.h>
#include "STM32L432KC.h"
#include "adc_test.h"

void config(void) {
    configureFlash();
    configureClock();
    
    gpioEnable(GPIO_PORT_A);
    pinMode(GPIO_ADC, GPIO_OUTPUT);

    RCC->APB2ENR |= (RCC_APB2ENR_TIM15EN);
    initTIM(TIM15);
}

void adcConversion(void)
{
    ADC->CR &= ~ADC_CR_ADSTART;   // Make sure no ongoing conversion
    ADC->CR |= ADC_CR_ADSTART;    // Start continuous conversions

    for (int i = 0; i < NUM_SAMPLES; i++) {
        while(!(ADC->ISR & ADC_ISR_EOC));  // Wait for end of conversion flag
        adcBuffer[i] = (uint16_t)ADC->DR;  // Read the data register → reading clears EOC
    }
    ADC->CR |= ADC_CR_ADSTP;            // ask hardware to stop
    while (ADC->CR & ADC_CR_ADSTP);     // wait for it to actually stop
}


int adc_test(void){
    cofig(void);
    adcConversion(void);
}

