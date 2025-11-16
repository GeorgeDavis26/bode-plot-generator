/*
File: main.c
Author: George Davis
Email: gdavis@hmc.edi
Date: 11/15/25
*/


#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "main.h"

/////////////////////////////////////////////////////////////////
// Provided Constants and Functions
/////////////////////////////////////////////////////////////////

//Defining the web page in two chunks: everything before the current time, and everything after the current time

char* webpageStart = "<!DOCTYPE html><html><head><title>Bode Plot Generator: E155 Project </title>\
	<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\
	</head>\
	<body><h1>George Davis Lab 6 temp Sensor</h1>";

char* phasePlot = "<p>
                    Temperature Resolution Control:
                </p>
                SOMEHOW PLOT uint16_t phase";


char* gainPlot = "<p>
                    Temperature Resolution Control:
                </p>
                SOMEHOW PLOT uint16_t gain";

  char* webpageEnd   = "</body></html>";

//determines whether a given character sequence is in a char array request, returning 1 if present, -1 if not present
int inString(char request[], char des[]) {
	if (strstr(request, des) != NULL) {return 1;}
	return -1;
}

int main(void) {
    configureFlash();
    configureClock();

    gpioEnable(GPIO_PORT_A);
    gpioEnable(GPIO_PORT_B);
    gpioEnable(GPIO_PORT_C);

    
    RCC->APB2ENR |= (RCC_APB2ENR_TIM15EN);
    initTIM(TIM15);
    
    USART_TypeDef * USART = initUSART(USART1_ID, 125000);
    while(1) {
        // Receive web request from the ESP
        char request[BUFF_LEN] = "                  "; // initialize to known value
        int charIndex = 0;
        
        // Keep going until you get end of line character
        while((inString(request, "\n")) == -1) {
            // Wait for a complete request to be transmitted before processing
            while(!(USART->ISR & USART_ISR_RXNE));
                request[charIndex++] = readChar(USART);
        }

        // finally, transmit the webpage over UART
        sendString(USART, webpageStart); // webpage header code

        sendString(USART, gainPlot); // gain plot
        sendString(USART, phasePlot); // phase plot 
        
        sendString(USART, webpageEnd);
    }
}

