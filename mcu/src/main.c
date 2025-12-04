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

// Global variable definitions
volatile uint32_t RX_ZC_TIME[NUM_ZERO_CROSS];
volatile uint32_t TX_ZC_TIME[NUM_ZERO_CROSS];

volatile int zc_count = 0;
volatile int rx_zc_count = 0;
volatile int tx_zc_count = 0;
volatile int half_wave = 0 ;
volatile int interupt_disable = 1;


/*
ZERO_CROSS interrupt handler, check for an interrupt then performs timer sample
*/

void EXTI9_5_IRQHandler(void){
    if (EXTI->PR1 & (1 << gpioPinOffset(ZERO_CROSS))){ // Check if EXTI6 triggered
        EXTI->PR1 |= (1 << gpioPinOffset(ZERO_CROSS)); // Clear the interrupt flag
        // Read and store the timer counter value
        if (!interupt_disable){
          if (zc_count < NUM_ZERO_CROSS) {
              TX_ZC_TIME[zc_count] = (uint32_t)ZERO_CROSS_TIM->CNT;
              zc_count++;
          }
        }
    }
}

void adcConversionGAIN(uint16_t* buffer, int num_samples) {
    for (int i = 0; i < num_samples; i++) {
        ADC1->CR &= ~ADC_CR_ADSTART;   // Make sure no ongoing conversion
        ADC1->CR |= ADC_CR_ADSTART;    // Start continuous conversions
        while(!(ADC1->ISR & ADC_ISR_EOC));  // Wait for end of conversion flag
        buffer[i] = (uint16_t)ADC1->DR;  // Read the data register, reading clears EOC
    }
    ADC1->CR |= ADC_CR_ADSTP;         // ask hardware to stop
    while (ADC1->CR & ADC_CR_ADSTP);  // wait for it to actually stop
}

void REadcConversionPHASE(uint32_t *rx_zc_time, int num_zero_cross) {
    
    uint16_t phase_buffer = 0;
    int below_thresh = 0;
    
    while((zc_count < num_zero_cross)){
        ADC1->CR &= ~ADC_CR_ADSTART;   // Make sure no ongoing conversion
        ADC1->CR |= ADC_CR_ADSTART;    // Start continuous conversions
        while(!(ADC1->ISR & ADC_ISR_EOC));  // Wait for end of conversion flag
        phase_buffer = (uint16_t)ADC1->DR;  // Read the data register, reading clears EOC

        if ((phase_buffer >= ZC_THRESHOLD) && (below_thresh)){
          below_thresh = 0;
          if (zc_count < num_zero_cross) {  // Add bounds check
                rx_zc_time[zc_count] = (uint32_t)ZERO_CROSS_TIM->CNT;
          }
        }
        if (phase_buffer < ZC_THRESHOLD){below_thresh = 1;}
    }
    ADC1->CR |= ADC_CR_ADSTP;         // ask hardware to stop
    while (ADC1->CR & ADC_CR_ADSTP);  // wait for it to actually stop
}

void FEadcConversionPHASE(uint32_t *rx_zc_time, int num_zero_cross) {
    
    uint16_t phase_buffer = 0;
    int above_thresh = 0;
    
    while((zc_count < num_zero_cross)){
        ADC1->CR &= ~ADC_CR_ADSTART;   // Make sure no ongoing conversion
        ADC1->CR |= ADC_CR_ADSTART;    // Start continuous conversions
        while(!(ADC1->ISR & ADC_ISR_EOC));  // Wait for end of conversion flag
        phase_buffer = (uint16_t)ADC1->DR;  // Read the data register, reading clears EOC

        if ((phase_buffer <= ZC_THRESHOLD) && (above_thresh)){
          above_thresh = 0;
          if (zc_count < num_zero_cross) {  // Add bounds check
                rx_zc_time[zc_count] = (uint32_t)ZERO_CROSS_TIM->CNT;
          }
        }
        if (phase_buffer > ZC_THRESHOLD){above_thresh = 1;}
    }
    ADC1->CR |= ADC_CR_ADSTP;         // ask hardware to stop
    while (ADC1->CR & ADC_CR_ADSTP);  // wait for it to actually stop
}

//determines whether a given character sequence is in a char array request, returning 1 if present, -1 if not present
int inString(char request[], char des[]) {
	if (strstr(request, des) != NULL) {return 1;}
	return -1;
}

void config(void){
  /*---------------GPIO enables---------------*/
  gpioEnable(GPIO_PORT_A);
  gpioEnable(GPIO_PORT_B);
  gpioEnable(GPIO_PORT_C);
  
  pinMode(GPIO_LED, GPIO_OUTPUT); //PB3
  
  //ADC1 input pin
  pinMode(GPIO_ADC1, GPIO_ANALOG); //PA2

  //initialize a bode plot flag pin
  pinMode(INIT_BODE, GPIO_INPUT);
  GPIOB->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD6, PULL_UP); //PB6
  
  //Half wave attenuation flag pin
  pinMode(HALF_ATTEN, GPIO_INPUT);
  GPIOB->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD4, PULL_DOWN); //PB4
  
  //Quarter wave attenuation flag pin
  pinMode(FULL_WAVE, GPIO_INPUT);
  GPIOA->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD11, PULL_DOWN); //PA11
  
  //Sweep is over flag pin
  pinMode(SWEEP_DONE, GPIO_INPUT);
  GPIOB->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD5, PULL_DOWN); //PB5
  
  //Zero cross flag pin (INTERRUPT)
  pinMode(ZERO_CROSS, GPIO_INPUT);
  GPIOA->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD6, PULL_DOWN); //PA6
  
  //MCU ready to take new ADC samples at a different frequency
  pinMode(MCU_READY, GPIO_OUTPUT); //PA12

  //MCU done taking samples and ready to go to a new frequency
  pinMode(MCU_DONE, GPIO_OUTPUT); //PA0

  //---------------Timer Enables---------------//
  RCC->APB2ENR |= RCC_APB2ENR_TIM15EN; //MICRO TIM
  RCC->APB1ENR1 |= RCC_APB1ENR1_TIM2EN; //MILLI TIM
  RCC->APB2ENR |= RCC_APB2ENR_TIM16EN; // ZERO CROSSING TIMER
  initTIM_milli(MILLI_TIM);
  initTIM_micro(MICRO_TIM);
  initTIM_ZC(ZERO_CROSS_TIM);

  //ADC Config
  configureADC();


  //---------------Interrupts---------------//

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

  //---------------MCO---------------//
    pinMode(MCO_PIN, GPIO_ALT);
    GPIOA->AFR[1] |= _VAL2FLD(GPIO_AFRH_AFSEL8, AF0);     // PA8 AF0 = MCO

    // Set MCO output to SYSCLK divided by 16 = 5 MHz
    RCC->CFGR &= ~RCC_CFGR_MCOSEL;
    RCC->CFGR |= RCC_CFGR_MCOSEL_0;  // SYSCLK
    RCC->CFGR |= RCC_CFGR_MCOPRE_DIV8;  // Divide by 16

};

void floatArray2String(float* array, char* string){
  char temp_buffer[40];
  string[0] = '\0'; // Initialize to empty string
  strcat(string, "["); // beginning of array

  for(int x = 0; x < NUM_FREQUENCIES; x++) {
    sprintf(temp_buffer, "%0.2f", array[x]);
    strcat(string, temp_buffer); 
    if (!(x == NUM_FREQUENCIES - 1)) {
      strcat(string, ","); // Add comma between values, but not after the last one.
    }
  }
  strcat(string, "]"); // End of array    
}

/**
 * Converts a uint32_t array to a string representation.
 */
void uint32Array2String(uint32_t* array, char* string){
  char temp_buffer[40];
  string[0] = '\0'; // Initialize to empty string
  strcat(string, "["); // beginning of array

  for(int x = 0; x < NUM_FREQUENCIES; x++) {
    sprintf(temp_buffer, "%lu", (unsigned long)array[x]);
    strcat(string, temp_buffer); 
    if (!(x == NUM_FREQUENCIES - 1)) {
      strcat(string, ","); // Add comma between values, but not after the last one.
    }
  }
  strcat(string, "]"); // End of array    
}

int main(void) {
  configureFlash();
  configureClock();
  config();

  // Wait for INIT_BODE to go high before starting
  while (digitalRead(INIT_BODE));
  interupt_disable = 1;
  // Wait for amplitude scalar to be chosen
  while (!(digitalRead(HALF_ATTEN) || digitalRead(FULL_WAVE)));
  if(digitalRead(HALF_ATTEN)){half_wave = !half_wave;}


  int i=0;
  int high_freq = 0;
  uint16_t adc_samples[MAX_SAMPLES];

  // gain
  float amp_samples[NUM_FREQUENCIES];
  float gain_samples[NUM_FREQUENCIES];

  //phase
  float phase_samples[NUM_FREQUENCIES];

  while(i < NUM_FREQUENCIES){
    //---------------TOGGLE MCU_RDY---------------//
    digitalWrite(MCU_READY, GPIO_HIGH);
    delay_millis(MILLI_TIM, 1000);
    digitalWrite(MCU_READY, GPIO_LOW);

    //---------------GAIN EXTRACT---------------//

    // Collect ADC samples for gain calculation
    adcConversionGAIN(adc_samples, MAX_SAMPLES);
    amp_samples[i] = amplitudeExtractRMS(adc_samples, MAX_SAMPLES);
    gain_samples[i] = gainExtract(amp_samples[i], half_wave);

    //---------------PHASE EXTRACT---------------//
    
    // Start all of the counter and interrupt enables
    zc_count = 0;
    tx_zc_count = 0;
    rx_zc_count = 0;
    interupt_disable = 0;
    ZERO_CROSS_TIM->CNT = 0;  // Reset counter to 0
    ZERO_CROSS_TIM->CR1 |= TIM_CR1_CEN;  // Start timer

    // Find zero crossing times for phase calculation
    REadcConversionPHASE(RX_ZC_TIME, NUM_ZERO_CROSS);

    // Stop the timer after sampling
    //while(!TX_ZC_TIME);
    ZERO_CROSS_TIM->CR1 &= ~TIM_CR1_CEN;  // Stop timer
    interupt_disable = 1;
    delay_millis(MILLI_TIM, 100);

    phase_samples[i] = (double)phaseExtract(RX_ZC_TIME, TX_ZC_TIME, frequency_table[i], NUM_ZERO_CROSS);
    

    //---------------TOGGLE MCU_DONE---------------//
    i++;
    digitalWrite(MCU_DONE, GPIO_HIGH);
    delay_millis(MILLI_TIM, 100);
    digitalWrite(MCU_DONE, GPIO_LOW);

  };
  digitalWrite(GPIO_LED,GPIO_LOW);


  USART_TypeDef * USART = initUSART(USART1_ID, 125000);
  char phase_data_string[(NUM_FREQUENCIES * 10) + 3];
  char gain_data_string[(NUM_FREQUENCIES * 10) + 3];
  char freq_data_string[(NUM_FREQUENCIES * 10) + 3];

  floatArray2String(phase_samples, phase_data_string);
  floatArray2String(gain_samples, gain_data_string);
  uint32Array2String(frequency_table, freq_data_string);
  
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
    sendString(USART, phase_data_string);
    sendString(USART, plot);
    sendString(USART, freq_data_string);
    sendString(USART, gain_data_plot);
    sendString(USART, gain_data_string);
    sendString(USART, webpageEnd);
  }


  while(1);
}