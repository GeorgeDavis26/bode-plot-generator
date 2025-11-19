// adc_test.h
// Header for adc_test.c

#ifndef ADC_TEST_H
#define ADC_TEST_H

#include <stdint.h>
#include <stm32l432xx.h>

#define GPIO_ADC1 PA2 //ADC1_IN7
#define GPIO_LED PA8

#define LED_HIGH 1
#define LED_LOW 0

#define NUM_SAMPLES 1000
#define NUM_FREQUENCIES 10


uint16_t adcBuffer[NUM_FREQUENCIES][NUM_SAMPLES];

#endif