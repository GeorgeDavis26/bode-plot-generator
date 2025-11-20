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
 