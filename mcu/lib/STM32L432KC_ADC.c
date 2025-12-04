// STM32L432KC_ADC.c
// Source code for ADC1 functions

#include <stdio.h>
#include <stdint.h>
#include <math.h>

#include "STM32L432KC.h"
#include <stm32l432xx.h>
#include "STM32L432KC_ADC.h"
#include "STM32L432KC_TIM.h"


void configureADC(void) {
    ///////////////////////// ADC CLK /////////////////////////////
    RCC->AHB2ENR |= RCC_AHB2ENR_ADCEN;
    //ADC clk derived from the AHB clock do not need to respect clk constraints because no injected channels are being used
    RCC->CCIPR |= _VAL2FLD(RCC_CCIPR_ADCSEL, SYSCLK_SEL_ADC);

    ///////////////////////// ADC CALIBRATION /////////////////////////////
    ADC1->CR &= ~ADC_CR_ADEN;       //Make sure the ADC is not enabled
    ADC1->CR &= ~ADC_CR_DEEPPWD;    // To start ADC first exit Deep-power-down mode

    ADC1->CR |= ADC_CR_ADVREGEN;    //ADC1 Voltage Regulator Enable
    delay_micros(TIM15, 50);  // software has to wait for startup time
    
    //ADC1->CR |= ADC_CR_ADCALDIF;     //Differential mode for calibration

    ADC1->CR |= ADC_CR_ADCAL;     //Run Calibration Protocol
    while (ADC1->CR & ADC_CR_ADCAL);

    //////////////////////////ADC DR CONFIGURATION////////////////////////////
    ADC1->CFGR &= ~ADC_CFGR_RES;    //Data Resolution
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_RES, TWELVE_BIT_ADC1_RES);

    ADC1->SMPR1 |= _VAL2FLD(ADC_SMPR1_SMP7, ADC_SAMPLETIME_24CYCLES_5); //ADC1 sample time register 246.5 ADC1 clock cycles

    ADC1->CFGR &= ~ADC_CFGR_CONT;    //single conversion mode for regular conversions

    ADC1->SQR1 &= ~ADC_SQR1_L; //clear conversion count
    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_L, 0); //1 conversion

    ADC1->SQR1 &= ~ADC_SQR1_SQ1; //clear sequence order
    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_SQ1, ADC1_IN7); //1st conversion regular sequence to IN7

    //////////////////////////ENABLE ADC1////////////////////////////
    ADC1->CR |= ADC_CR_ADEN;
    while (ADC1->ISR & ADC_ISR_ADRDY);
}

double amplitudeExtractRMS(const uint16_t *sine_array, int num_samples){
    // compute DC offset (mean)
    double sum = 0.0;
    for (int i = 0; i < num_samples; i++) sum += sine_array[i];
    double mean = sum / num_samples;

    // compute sum of the square of each value
    double square = 0.0;
    for (int i = 0; i < num_samples; i++) {
        double v = (double)sine_array[i] - mean;
        square += v * v;
    }
    // find the average of the squared values and take the sqrt
    double rms_counts = sqrt(square / num_samples);

    // compute peak to peak amplitude
    double peak_counts = rms_counts * sqrt(2.0);
    return peak_counts;
}


double amplitudeExtractPP(const uint16_t *sine_array, int num_samples){
    uint16_t max_value = sine_array[0];
    uint16_t min_value = sine_array[0];
    
    // Find max and min values
    for (int i = 1; i < num_samples; i++) {
        if (sine_array[i] > max_value) max_value = sine_array[i];
        if (sine_array[i] < min_value) min_value = sine_array[i];
    }
    return (double)(max_value - min_value) / 2.0;
}

double gainExtract(double RX_amp, int atten){
    double TX_amp = 0;
    if (atten) {TX_amp = 900;}
    else{TX_amp = 1800;}
    return (double) 20.0 *log10(RX_amp/TX_amp);
}

double phaseExtract(volatile  uint32_t *rx_zc_times, volatile uint32_t *tx_zc_times, uint32_t frequency, int num_zero_cross){
   // Convert time differences to phase differences (in degrees)
   double phases[num_zero_cross];
    
   for (int i = 0; i < num_zero_cross; i++) {
       int32_t time_diff = (int32_t)(rx_zc_times[i] - tx_zc_times[i]);
       // Convert time difference to phase magnitude
       double timer_ticks = (double)TIMER_FREQ / frequency; // Calculates how many timer ticks make up one full wave (360 deg)
       phases[i] = (360.0 * (double)time_diff) / timer_ticks; // Ratios the time difference against the full wave period
       // Wrap phase to [-180, 180]
       while (phases[i] > 180.0) phases[i] -= 360.0;
       while (phases[i] < -180.0) phases[i] += 360.0;
       }

   double sum = 0.0;
   for (int i = 0; i < num_zero_cross; i++) {sum += phases[i];}
   double mean = sum / num_zero_cross;

   return mean;
}

/*
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

double phaseExtract(volatile uint32_t* rx_zc_time, volatile uint32_t* tx_zc_time, uint32_t frequency, int num_zero_cross){
    double sum_sin = 0.0;
    double sum_cos = 0.0;
    
    // Calculate period in timer ticks
    double period_ticks = (double)TIMER_FREQ / (double)frequency; 

    for (int i = 0; i < num_zero_cross; i++) {
        int32_t time_diff = (int32_t)(rx_zc_time[i] - tx_zc_time[i]);
        
        // Calculate Phase in Degrees
        double phase_deg = (360.0 * (double)time_diff) / period_ticks;

        // Convert to Radians for vector math
        double phase_rad = phase_deg * (M_PI / 180.0);

        // Accumulate vector components
        sum_sin += sin(phase_rad);
        sum_cos += cos(phase_rad);
    }

    // Calculate average angle using atan2 (returns -PI to +PI)
    double mean_rad = atan2(sum_sin, sum_cos);

    // Convert back to degrees
    double mean_deg = mean_rad * (180.0 / M_PI);

    return mean_deg;
}
*/