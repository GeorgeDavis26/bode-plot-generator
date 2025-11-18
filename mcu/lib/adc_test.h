// adc_test.h
// Header for adc_test.c

#ifndef ADC_TEST_H
#define ADC_TEST_H

#include <stdint.h>
#include <stm32l432xx.h>

#define GPIO_ADC1 PA5 //ADC1_IN10

#define NUM_SAMPLES 1000

uint16_t adcBuffer[NUM_SAMPLES];

#endif