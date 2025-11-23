/*
File: Lab_6_JHB.c
Author: Josh Brake
Email: jbrake@hmc.edu
Date: 9/14/19
*/

#include "STM32L432KC.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "main.h"


//determines whether a given character sequence is in a char array request, returning 1 if present, -1 if not present
int inString(char request[], char des[]) {
	if (strstr(request, des) != NULL) {return 1;}
	return -1;
}

void config(void){
  configureFlash();
  configureClock();

  RCC->APB2ENR |= (RCC_APB2ENR_TIM15EN); //MICRO TIM
  RCC->APB1ENR1 |= RCC_APB1ENR1_TIM2EN; //MILLI TIM
  initTIM_milli(MILLI_TIM);
  initTIM_micro(MICRO_TIM);

  gpioEnable(GPIO_PORT_A);
  gpioEnable(GPIO_PORT_B);
  gpioEnable(GPIO_PORT_C);

  configureADC();

  pinMode(GPIO_BUTTON, GPIO_INPUT);
  GPIOA->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD4, 0b01); // Set PA4 (GPIO_BUTTON) as pull-up
  pinMode(GPIO_LED, GPIO_OUTPUT);
  pinMode(GPIO_ADC1, GPIO_ANALOG);

};

char array2String(uint16_t array){
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

double amplitudeExtract(const uint16_t *sine_array, int res_bits){
    // compute DC offset (mean)
    double sum = 0.0;
    for (int i = 0; i < NUM_SAMPLES ; i++) sum += sine_array[i];
    double mean = sum / NUM_SAMPLES;

    // compute sum of the square of each value
    double square = 0.0;
    for (size_t i=0;i<n;i++) {
        double v = (double)sine_array[i] - mean;
        square += v * v;
    }
    // find the average of the squared values and take the sqrt
    double rms_avg = sqrt(square / NUM_SAMPLES);

    // compute peak to peak amplitude
    double peak_counts = rms_counts * sqrt(2.0);
    double scale = vref / ((1u << res_bits) - 1u);
    return (double)(peak_counts * scale);
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