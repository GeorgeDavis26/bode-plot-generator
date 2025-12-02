/*
File: main.c
Author: George Davis and Matthew Molinar
Email: gdavis@hmc.edu mmolinar@hmc.edu
Date: 12/1/25
*/

#include "STM32L432KC.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "main.h"

/*

Bode Plot SOP:

Buttons:
Init Bode -- button on B0
Half Amplitude -- P43
Three Quarters Amplitude -- P34

Flags:
MCU ready -- A10

zero cross -- A6
frequency change -- A11
Sweep done -- B5
Half Amplitude -- B4
Three Quarters Amplitude -- B7

Init Bode
Amplitude?

Loop{
zerocross timer start
[FPGA loads the next frequency]
wait(MCU ready) 
delay micros {
frequency change
zero cross (continuous)
}
1500 Samples
MCU Done -- zero cross timer end
}

sweep done
*/

// Global variable definitions
volatile uint32_t RX_zc_times[NUM_ZERO_CROSS];
volatile uint32_t TX_zc_times[NUM_ZERO_CROSS];
volatile int zero_cross_count = 0;

volatile int cur_freq_change_state = 0;
volatile int prev_freq_change_state = 0;


/*
ZERO_CROSS interrupt handler, check for an interrupt then performs timer sample
*/
void EXTI9_5_IRQHandler(void){
    if (EXTI->PR1 & (1 << gpioPinOffset(ZERO_CROSS))){ // Check if EXTI6 triggered
        EXTI->PR1 |= (1 << gpioPinOffset(ZERO_CROSS)); // Clear the interrupt flag
        // Read and store the timer counter value
        if (zero_cross_count < NUM_ZERO_CROSS) {
            RX_zc_times[zero_cross_count] = (uint32_t)ZERO_CROSS_TIM->CNT;
            zero_cross_count++;
        }
    }
}

//determines whether a given character sequence is in a char array request, returning 1 if present, -1 if not present
int inString(char request[], char des[]) {
	if (strstr(request, des) != NULL) {return 1;}
	return -1;
}

void config(void){
  //Clock enables
  configureFlash();
  configureClock();

  //Timer enables
  RCC->APB2ENR |= RCC_APB2ENR_TIM15EN; //MICRO TIM
  RCC->APB1ENR1 |= RCC_APB1ENR1_TIM2EN; //MILLI TIM
  RCC->APB2ENR |= RCC_APB2ENR_TIM16EN; // ZERO CROSSING TIMER
  initTIM_milli(MILLI_TIM);
  initTIM_micro(MICRO_TIM);
  initTIM_ZC(ZERO_CROSS_TIM);

  //GPIO enables
  gpioEnable(GPIO_PORT_A);
  gpioEnable(GPIO_PORT_B);
  gpioEnable(GPIO_PORT_C);

  //ADC Config
  configureADC();

  //GPIO mode
  //pinMode(GPIO_BUTTON, GPIO_INPUT);
  //GPIOA->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD4, 0b01); // Set PA4 (GPIO_BUTTON) as pull-up
  
  //pinMode(GPIO_LED, GPIO_OUTPUT);
  
  //ADC1 input pin
  pinMode(GPIO_ADC1, GPIO_ANALOG);

  //initialize a bode plot flag pin
  pinMode(INIT_BODE, GPIO_INPUT);
  GPIOB->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD0, PULL_DOWN);
  
  //Half wave attenuation flag pin
  pinMode(HALF_ATTEN, GPIO_INPUT);
  GPIOB->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD4, PULL_DOWN);
  
  //Quarter wave attenuation flag pin
  pinMode(QUARTER_ATTEN, GPIO_INPUT);
  GPIOB->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD7, PULL_DOWN);
  
  //Sweep is over flag pin
  pinMode(SWEEP_DONE, GPIO_INPUT);
  GPIOB->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD5, PULL_DOWN);
  
  //Change in frequncies flag pin
  pinMode(FREQ_CHANGE, GPIO_INPUT);
  GPIOA->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD11, PULL_DOWN);
  
  //Zero cross flag pin (INTERRUPT)
  pinMode(ZERO_CROSS, GPIO_INPUT);
  GPIOA->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD10, PULL_DOWN);
  
  //MCU ready to take new ADC samples at a different frequency
  pinMode(MCU_READY, GPIO_OUTPUT);

  //MCU done taking samples and ready to go to a new frequency
  pinMode(MCU_DONE, GPIO_OUTPUT);

  //Enable SYSCFG clock domain in RCC for EXTI interrupts
  RCC->APB2ENR |= RCC_APB2ENR_SYSCFGEN;
  // Configure EXTICR for the zero crossing flag
  SYSCFG->EXTICR[1] |= _VAL2FLD(SYSCFG_EXTICR2_EXTI6, 0b000); // Select PA6

  //enable interrupts globally
  __enable_irq();
  EXTI->IMR1 |= (1 << gpioPinOffset(ZERO_CROSS)); // Configure the mask bit
  // Enable rising edge trigger
  EXTI->RTSR1 |= (1 << gpioPinOffset(ZERO_CROSS));// Enable rising edge trigger
  // Turn on EXTI interrupt in NVIC_ISER
  NVIC->ISER[0] |= (1 << EXTI9_5_IRQn);  // Changed from EXTI1_IRQn
};

char array2String(uint16_t array){
  char temp_buffer[20];
  string[0] = '\0'; // Initialize to empty string
  strcat(string, "["); // beginning of array

  for(int x = 0; x < NUM_FREQUENCIES; x++) {
    sprintf(temp_buffer, "%u", array[x][y]);
    strcat(string, temp_buffer); 
    if (!(x == NUM_FREQUENCIES - 1)) {
      strcat(string, ","); // Add comma between values, but not after the last one.
    }
  }
  strcat(string, "]"); // End of array    
  return string;
}

int main(void) {
  config();
  // Wait for INIT_BODE to go high before starting
  while (!digitalRead(INIT_BODE));

  int volatile cur_freq_change_state = digitalRead(GPIO_BUTTON);
  int volatile prev_freq_change_state = cur_freq_change_state;

  int i=0;
  int num_samples_collected=0;

  uint16_t adc_samples[MAX_SAMPLES];
  uint16_t gain_samples[NUM_FREQUENCIES];
  uint16_t phase_samples[NUM_FREQUENCIES];

  while((i < NUM_FREQUENCIES) || digitalRead(SWEEP_DONE)){
    prev_freq_change_state = cur_freq_change_state;
    cur_freq_change_state = digitalRead(FREQ_CHANGE);

    digitalWrite(MCU_READY, GPIO_HIGH);
    if ((prev_freq_change_state == 0) && (cur_freq_change_state == 1)) { //check for rising edge of freq_change flag
      digitialWrite(MCU_READY, GPIO_LOW);
      // Reset and start the zero crossing timer
      zero_cross_count = 0;
      ZERO_CROSS_TIM->CNT = 0;  // Reset counter to 0
      ZERO_CROSS_TIM->CR1 |= TIM_CR1_CEN;  // Start timer
      
      num_samples_collected = adcConversion(adc_samples);
      
      // Stop the timer after sampling
      ZERO_CROSS_TIM->CR1 &= ~TIM_CR1_CEN;  // Stop timer
      
      gain_samples[i] = (uint16_t)amplitudeExtract(adc_samples, num_samples_collected, RESOLUTION_12bit);
      phase_samples[i] = ; // phaseExtract not implemented yet
      i++;
      digitalWrite(MCU_DONE, GPIO_HIGH);
      delay_millis(MILLI_TIM, 10);
      digitalWrite(MCU_DONE, GPIO_LOW);
    }
    delay_millis(MILLI_TIM, 1);
  };
  
  USART_TypeDef * USART = initUSART(USART1_ID, 125000);
  char phase_data_string[(NUM_FREQUENCIES * 6) + 3];
  char gain_data_string[(NUM_FREQUENCIES * 6) + 3];

  phase_data_string = array2String(phase_samples, NUM_FREQUENCIES);
  gain_data_string = array2String(gain_samples, NUM_FREQUENCIES);

  while(1) {
    // Receive web request from the ESP
    char request[BUFF_LEN] = "                  "; 
    int charIndex = 0;
    while(inString(request, "\n") == -1) {
      while(!(USART->ISR & USART_ISR_RXNE));
      request[charIndex++] = readChar(USART);
    }

    // Send data to webpage
    sendString(USART, webpageStart);
    sendString(USART, plot);
    sendString(USART, gain_data_string);
    sendString(USART, webpageEnd);
  }
}