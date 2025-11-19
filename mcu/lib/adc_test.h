// adc_test.h
// Header for adc_test.c

#ifndef ADC_TEST_H
#define ADC_TEST_H
123
#include <stdint.h>
#include <stm32l432xx.h>

#define GPIO_ADC1 PA7 //ADC1_IN7

#define NUM_SAMPLES 1000

uint16_t adcBuffer[NUM_SAMPLES];

#endif