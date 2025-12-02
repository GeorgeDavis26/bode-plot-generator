// STM32L432KC_ADC.c
// Source code for ADC1 functions

#include <stdio.h>
#include <stdint.h>
#include <stm32l432xx.h>
#include "STM32L432KC.h"
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

int adcConversion(uint16_t* buffer) {
    int i = 0;
    // Sample until we get NUM_ZERO_CROSS crossings OR hit max buffer
    while (zero_cross_count < NUM_ZERO_CROSS && i < MAX_SAMPLES) {
        ADC1->CR &= ~ADC_CR_ADSTART;   // Make sure no ongoing conversion
        ADC1->CR |= ADC_CR_ADSTART;    // Start continuous conversions
        while(!(ADC1->ISR & ADC_ISR_EOC));  // Wait for end of conversion flag
        buffer[i] = (uint16_t)ADC1->DR;  // Read the data register, reading clears EOC
        
        // Check for zero crossing in software (TX detection)
        if(i >= 1){
            if((buffer[i] <= ZC_THRESHOLD) && (buffer[i-1] > ZC_THRESHOLD)) {
                if (zero_cross_count < NUM_ZERO_CROSS) {  // Add bounds check
                    TX_zc_times[zero_cross_count] = (uint32_t)ZERO_CROSS_TIM->CNT;
                }
            }
        }
        i++;
    }
    ADC1->CR |= ADC_CR_ADSTP;         // ask hardware to stop
    while (ADC1->CR & ADC_CR_ADSTP);  // wait for it to actually stop
    
    return i; // Return actual number of samples collected
}

double amplitudeExtract(const uint16_t *sine_array, int num_samples, int res_bits){
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
    double vref = 3.3;     
    double scale = vref / ((1u << res_bits) - 1u);
    return (double)(peak_counts * scale);
}

double phaseExtract(const uint16_t *rx, const uint16_t *tx){
    double phase = 0.0;
    uint16_t phasearray[NUM_ZERO_CROSS];
    for (int i = 0; i < NUM_ZERO_CROSS; i++) {
        phasearray[i] = (uint16_t)rx[i] - (uint16_t)tx[i];
        sum += phasearray[i];
    }
    double mean = sum / NUM_ZERO_CROSS;
    return 0.0;
}