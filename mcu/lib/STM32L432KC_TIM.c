// STM32F401RE_TIM.c
// TIM functions

#include "STM32L432KC_TIM.h"
#include "STM32L432KC_RCC.h"
/*
initTIM_micro initializes a timer at micro seconds counter scale
*/
void initTIM_micro(TIM_TypeDef * TIMx){
  // Set prescaler to give 1 us time base
  uint32_t psc_div = (uint32_t) ((SystemCoreClock/1e6));
  // Set prescaler division factor
  TIMx->PSC = (psc_div - 1);
  // Generate an update event to update prescaler value
  TIMx->EGR |= 1;
  // Enable counter
  TIMx->CR1 |= 1; // Set CEN = 1
}
/*
initTIM_milli initializes a timer at millis seconds counter scale
*/
void initTIM_milli(TIM_TypeDef * TIMx){
  // Set prescaler to give 1 ms time base
  uint32_t psc_div = (uint32_t) ((SystemCoreClock/1e3));

  // Set prescaler division factor
  TIMx->PSC = (psc_div - 1);
  // Generate an update event to update prescaler value
  TIMx->EGR |= 1;
  // Enable counter
  TIMx->CR1 |= 1; // Set CEN = 1
}
/*
initTIM_ZC initializes a timer at counter scale relative to ADC sample rate
*/
void initTIM_ZC(TIM_TypeDef * TIMx){
  // Set prescaler to give 1 ns time base
  uint32_t psc_div = (uint32_t) (ZERO_CROSS_PSC);
  // Set prescaler division factor
  TIMx->PSC = (psc_div - 1);
  // Generate an update event to update prescaler value
  TIMx->EGR |= 1;
  // Enable counter
  TIMx->CR1 |= 1; // Set CEN = 1
}

/*
delay_micros delays based on input us int 
*/
void delay_micros(TIM_TypeDef * TIMx, uint32_t us){
  TIMx->ARR = us;// Set timer max count
  TIMx->EGR |= 1;     // Force update
  TIMx->SR &= ~(0x1); // Clear UIF
  TIMx->CNT = 0;      // Reset count

  while(!(TIMx->SR & 1)); // Wait for UIF to go high
}
/*
delay_millis delays based on input ms int 
*/
void delay_millis(TIM_TypeDef * TIMx, uint32_t ms){
  TIMx->ARR = ms;// Set timer max count
  TIMx->EGR |= 1;     // Force update
  TIMx->SR &= ~(0x1); // Clear UIF
  TIMx->CNT = 0;      // Reset count

  while(!(TIMx->SR & 1)); // Wait for UIF to go high
}