/*
    adc_test: ADC1 test file to run ADC1 drivers and
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
    pinMode(GPIO_ADC1, GPIO_ANALOG);

    RCC->APB2ENR |= (RCC_APB2ENR_TIM15EN);
    initTIM(TIM15);

    configureADC();
}

void adcConversion(void)
{
    ADC1->CR &= ~ADC_CR_ADSTART;   // Make sure no ongoing conversion
    ADC1->CR |= ADC_CR_ADSTART;    // Start continuous conversions

    for (int i = 0; i < NUM_SAMPLES; i++) {
        while(!(ADC1->ISR & ADC_ISR_EOC));  // Wait for end of conversion flag
        adcBuffer[i] = (uint16_t)ADC1->DR;  // Read the data register → reading clears EOC
    }
    ADC1->CR |= ADC_CR_ADSTP;            // ask hardware to stop
    while (ADC1->CR & ADC_CR_ADSTP);     // wait for it to actually stop
}


int main(void){
    config();
    adcConversion();

    while(1) {
    }
}