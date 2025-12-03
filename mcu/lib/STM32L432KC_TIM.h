// STM32L432KC_TIM.h
// Header for TIM functions

#ifndef STM32L4_TIM_H
#define STM32L4_TIM_H

#include <stdint.h> // Include stdint header
#include "STM32L432KC_GPIO.h"

#define ZERO_CROSS_PSC 40  // 80 MHz / 40 = 2 MHz, 500 ns per tick

///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

void initTIM_milli(TIM_TypeDef * TIMx);
void initTIM_micro(TIM_TypeDef * TIMx);
void initTIM_ZC(TIM_TypeDef * TIMx);
void delay_millis(TIM_TypeDef * TIMx, uint32_t ms);
void delay_micros(TIM_TypeDef * TIMx, uint32_t us);

#endif