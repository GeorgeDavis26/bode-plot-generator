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

#define NUM_FREQUENCIES 10

uint16_t gain[NUM_SAMPLES*NUM_FREQUENCIES];
uint16_t phase[NUM_SAMPLES*NUM_FREQUENCIES];

#endif // MAIN_H