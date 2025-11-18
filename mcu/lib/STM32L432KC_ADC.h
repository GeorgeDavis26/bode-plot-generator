// STM32L432KC_ADC.h
// Header for ADC1 functions

#ifndef STM32L4_ADC_H
#define STM32L4_ADC_H

#include <stdint.h>
#include <stm32l432xx.h>
///////////////////////////////////////////////////////////////////////////////
// Definitions
///////////////////////////////////////////////////////////////////////////////

//Values for ADC1 Data Resolution
#define TWELVE_BIT_ADC1_RES  0 // Value to set ADC_CFG_RES[1:0] to 12-bit resolution
#define TEN_BIT_ADC1_RES     1 // Value to set ADC_CFG_RES[1:0] to 10-bit resolution
#define EIGHT_BIT_ADC1_RES   2 // Value to set ADC_CFG_RES[1:0] to 8-bit resolution
#define SIX_BIT_ADC1_RES     3 // Value to set ADC_CFG_RES[1:0] to 6-bit resolution

#define ADC1_IN10 10 //PA5 or ADC1_IN10

#define ZERO_VOLTS_UPPER //


///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

void configureADC();

#endif