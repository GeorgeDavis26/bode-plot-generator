// debug.c
// Source code for debug functions

#include "STM32L432KC.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "main.h"

void led_toggle_debug(void) {
    // Enable LED as output
    gpioEnable(GPIO_PORT_A);
    pinMode(GPIO_LED, GPIO_OUTPUT);

    // Enable button as input
    gpioEnable(GPIO_PORT_A);
    pinMode(GPIO_BUTTON, GPIO_INPUT);

    GPIOA->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD4, 0b01); // Set PA4 as pull-up

    // Initialize timer
    RCC->APB1ENR1 |= RCC_APB1ENR1_TIM2EN;
    initTIM_milli(MILLI_TIM);

    int volatile cur_button_state = digitalRead(GPIO_BUTTON);
    int volatile led_state = 0;
    int volatile prev_button_state = cur_button_state;

    while(1){
        prev_button_state = cur_button_state;
        cur_button_state = digitalRead(GPIO_BUTTON);
        if ((prev_button_state == 1) && (cur_button_state == 0)) {
            led_state = !led_state;
            digitalWrite(GPIO_LED, led_state);
        }
        delay_millis(MILLI_TIM, 200);
    }
}

void IOT_debug(void){
  while(1) {
    // Receive web request from the ESP
    char request[BUFF_LEN] = "                  "; 
    int charIndex = 0;
    while(inString(request, "\n") == -1) {
      while(!(USART->ISR & USART_ISR_RXNE));
      request[charIndex++] = readChar(USART);
    }

    // Collect data with ADC
    adcConversion(adc_samples, NUM_SAMPLES);

    // Format the data into a JavaScript array string: "[val1,val2,val3,...]"
    char temp_buffer[10];
    
    strcpy(adc_data_string, "["); // Start of array

    for(int i = 0; i < NUM_SAMPLES; i++) {
        sprintf(temp_buffer, "%u", adc_samples[i]); // Convert integer to string
        strcat(adc_data_string, temp_buffer);
        if (i < NUM_SAMPLES - 1) {
            strcat(adc_data_string, ","); // Add comma between values
        }
    }
    strcat(adc_data_string, "]"); // End of array

    // Send data to webpage
    sendString(USART, webpageStart);
    sendString(USART, adc_data_string);
    sendString(USART, webpageEnd);
  }
}
 


int main(void) {
  config();

  int volatile cur_button_state = digitalRead(GPIO_BUTTON);
  int volatile led_state = 0;
  int volatile prev_button_state = cur_button_state;

  int i=0;
  uint16_t adc_samples[NUM_FREQUENCIES][NUM_SAMPLES];

  USART_TypeDef * USART = initUSART(USART1_ID, 125000);

  // char adc_data_string[NUM_SAMPLES * NUM_FREQUENCIES];
  char adc_data_string[(NUM_SAMPLES * NUM_FREQUENCIES * 6) + 3];
  //test

  while(i < NUM_FREQUENCIES){

      prev_button_state = cur_button_state;
      cur_button_state = digitalRead(GPIO_BUTTON);

      if ((prev_button_state == 1) && (cur_button_state == 0)) {
          led_state = !led_state;
          digitalWrite(GPIO_LED, led_state);
          adcConversion(adc_samples[i], NUM_SAMPLES);
          i++;
      }
      delay_millis(MILLI_TIM, 200);
  };

  amplitude = amplitudeExtract(adc_samples);

  adc_data_string = array2String(adc_samples);

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
    sendString(USART, adc_data_string);
    sendString(USART, webpageEnd);
  }
}

// void adcConversion(void)
// {
//     for (int j = 0; j < NUM_FREQUENCIES; j++) {
//         //if the frequencey changes then do this 
//         //while(!FREQ_GPIO); //wait for a new frequency to be set
//         uint16_t adcBuffer[NUM_FREQUENCIES][NUM_SAMPLES];
//         for (int i = 0; i < NUM_SAMPLES; i++) {
//             ADC1->CR &= ~ADC_CR_ADSTART;   // Make sure no ongoing conversion
//             ADC1->CR |= ADC_CR_ADSTART;    // Start continuous conversions
//             while(!(ADC1->ISR & ADC_ISR_EOC));  // Wait for end of conversion flag
//             adcBuffer[j][i] = (uint16_t)ADC1->DR;  // Read the data register, reading clears EOC
//         }
//         ADC1->CR |= ADC_CR_ADSTP;            // ask hardware to stop
//         while (ADC1->CR & ADC_CR_ADSTP);     // wait for it to actually stop
//     }
// }

    /*
    while(1){
        ADC1->CR &= ~ADC_CR_ADSTART;   // Make sure no ongoing conversion
        ADC1->CR |= ADC_CR_ADSTART;    // Start continuous conversions
        while(!(ADC1->ISR & ADC_ISR_EOC));  // Wait for end of conversion flag
        uint16_t VREFINT_DATA = (uint16_t)ADC1->DR;  // Read the data register, reading clears EOC;
        float voltage = 3*(VREFINT_DATA/(4095.0));
        printf("ADC Voltage: ");
        printf("%d ", VREFINT_DATA);
        printf("%f", voltage);
        printf("\n");
    }
*/

char array2String2d(uint16_t array){
  char temp_buffer[20];
  string[0] = '\0'; // Initialize to empty string
  strcat(string, "["); // beginning of array

  for(int x = 0; x < NUM_FREQUENCIES; x++) {
    for(int y = 0; y < NUM_SAMPLES; y++) {
      sprintf(temp_buffer, "%u", array[x][y]);
      strcat(string, temp_buffer); 
      if (!(x == NUM_FREQUENCIES - 1 && y == NUM_SAMPLES - 1)) {
        strcat(string, ","); // Add comma between values, but not after the last one.
      }
    }
  }
  strcat(string, "]"); // End of array    
  return string;
}



/*
int adcConversion(uint16_t* buffer) {
    int i = 0;
    // Sample until we get NUM_ZERO_CROSS crossings OR hit max buffer
    while (i < MAX_SAMPLES) {
        ADC1->CR &= ~ADC_CR_ADSTART;   // Make sure no ongoing conversion
        //delay_micros(MICRO_TIM,  1); //reduce sample frequency a bit so we don't overflow into PLL with 100 Hz max sample
        ADC1->CR |= ADC_CR_ADSTART;    // Start continuous conversions
        while(!(ADC1->ISR & ADC_ISR_EOC));  // Wait for end of conversion flag
        buffer[i] = (uint16_t)ADC1->DR;  // Read the data register, reading clears EOC
        
        // Check for zero crossing in software (TX detection)
        if (zero_cross_count < NUM_ZERO_CROSS) {  // Add bounds check
          if((buffer[i] <= ZC_THRESHOLD) && (buffer[i-1] > ZC_THRESHOLD)) {
                RX_zc_times[zero_cross_count] = (uint32_t)ZERO_CROSS_TIM->CNT;
                zero_cross_count++;
            }
          }
        }
        i++;
    ADC1->CR |= ADC_CR_ADSTP;         // ask hardware to stop
    while (ADC1->CR & ADC_CR_ADSTP);  // wait for it to actually stop
    
    return i; // Return actual number of samples collected
}

*/

/*
void REadcConversionPHASE(uint16_t *rx_zc_time, int num_zero_cross) {
    
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
                rx_zc_time[0] = (uint16_t)ZERO_CROSS_TIM->CNT;
          }
        }
        if (phase_buffer < ZC_THRESHOLD){below_thresh = 1;}
    }
    ADC1->CR |= ADC_CR_ADSTP;         // ask hardware to stop
    while (ADC1->CR & ADC_CR_ADSTP);  // wait for it to actually stop
}
*/