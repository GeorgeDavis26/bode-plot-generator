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

    gpioEnable(GPIO_PORT_B);
    gpioEnable(GPIO_PORT_A);
    pinMode(GPIO_LED, GPIO_OUTPUT);

    RCC->APB2ENR |= (RCC_APB2ENR_TIM15EN);
    initTIM(TIM15);
/*
    while(1) {
        togglePin(GPIO_LED);
        delay_micros(TIM15, 500);
    }
*/
    pinMode(GPIO_ADC1, GPIO_ANALOG);

    configureADC();
}

void adcConversion(void)
{
    
    //ADC1->CR &= ~ADC_CR_ADSTART;   // Make sure no ongoing conversion
    //ADC1->CR |= ADC_CR_ADSTART;    // Start continuous conversions

    while(1){
        ADC1->CR &= ~ADC_CR_ADSTART;   // Make sure no ongoing conversion
        ADC1->CR |= ADC_CR_ADSTART;    // Start continuous conversions
        while(!(ADC1->ISR & ADC_ISR_EOC));  // Wait for end of conversion flag
        uint16_t VREFINT_DATA = (uint16_t)ADC1->DR;  // Read the data register, reading clears EOC
        //unit16_t VREFINT_CAL = (uint16_t);
        float voltage = 3*(VREFINT_DATA/63.0);
        printf("ADC Voltage: ");
        printf("%d ", VREFINT_DATA);
        printf("%f", voltage);
        printf("\n");
        delay_micros(TIM15, 1000);
    }

/*
    for (int i = 0; i < NUM_SAMPLES; i++) {
        ADC1->CR &= ~ADC_CR_ADSTART;   // Make sure no ongoing conversion
        ADC1->CR |= ADC_CR_ADSTART;    // Start continuous conversions
        while(!(ADC1->ISR & ADC_ISR_EOC));  // Wait for end of conversion flag
        adcBuffer[0][i] = (uint16_t)ADC1->DR;  // Read the data register, reading clears EOC
        //togglePin(GPIO_LED);
        //delay_micros(TIM15, 100);
        printf("ADC Voltage: ");
        printf("%d", adcBuffer[0][i]);
        printf(" \n");
    }
*/
    ADC1->CR |= ADC_CR_ADSTP;            // ask hardware to stop
    while (ADC1->CR & ADC_CR_ADSTP);     // wait for it to actually stop
}


int main(void){
    config();
    adcConversion();
    while(1) {
    }
}