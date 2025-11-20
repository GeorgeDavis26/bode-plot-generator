/**
    Main Header: Contains general defines and selected portions of CMSIS files
    @file main.h
    @author George DAvis
    @version 10/27/2025

    Main header file for Bode Plot Generator IOT function.
*/

#ifndef MAIN_H
#define MAIN_H

#include "STM32L432KC.h"

/*-------------------------GPIO PINS-------------------------*/
#define GPIO_ADC1 PA2 //ADC1_IN7
#define GPIO_LED PA6 //DEBUG LED
#define GPIO_BUTTON PA4 //INPUT BUTTON
#define MILLI_TIM TIM2
#define MICRO_TIM TIM15

/*-------------------------MACROS-------------------------*/

#define BUFF_LEN 32
#define NUM_SAMPLES 1000
#define NUM_FREQUENCIES 2

/*-----------------CONST WEBPAGE HTML STRINGS--------------------*/

//Defining the web page in two chunks: everything before the current time, and everything after the current time
const char* webpageStart = "<!DOCTYPE html><html><head><title>George and Matthew's Sine Wave</title>\
	<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\
	</head>\
	<body><h1>Bodeplot</h1>";

const char* webpageEnd   = "</body></html>";

/*-----------------FUNCTION PROTOTYPES--------------------*/

int inString(char request[], char des[]);
void config(void);
int main(void);

#endif // MAIN_H