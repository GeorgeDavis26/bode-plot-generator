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
#include <stdint.h>

#define MILLI_TIM TIM2
#define MICRO_TIM TIM15
#define ZERO_CROSS_TIM TIM16 

/*-------------------------GPIO PINS-------------------------*/
//#define GPIO_BUTTON PA4 //INPUT BUTTON
//#define FREQ_CHANGE PA11 

#define GPIO_ADC1 PA2 
#define GPIO_LED PB3 
#define MCO_PIN PA8 //P19

#define INIT_BODE PB6 //P18
#define HALF_ATTEN PB4 //P12
#define FULL_WAVE PA11 //P20

#define SWEEP_DONE PB5 //P10
#define ZERO_CROSS PA6 //P27

#define MCU_READY PA10 //P23
#define MCU_DONE PA9 //P25

/*-------------------------MACROS-------------------------*/

#define BUFF_LEN 32
#define MAX_SAMPLES 10000
#define NUM_FREQUENCIES 28
#define NUM_ZERO_CROSS 2
#define ZC_THRESHOLD 2063

#define PULL_DOWN 2 
#define PULL_UP 1

#define GPIO_HIGH 1
#define GPIO_LOW 0
#define AF0 0
#define MCO_SYSCLK 1
#define MCO_DIV1 0


/*-------------------------Global Variables-------------------------*/

const uint32_t frequency_table[] = {100,200,300,400,500,600,700,800,900,
                               1000,2000,3000,4000,5000,6000,7000,8000,9000,
                               10000,20000,30000,40000,50000,60000,70000,80000,90000,100000};
/*-----------------CONST WEBPAGE HTML STRINGS--------------------*/

char* webpageStart = "<!DOCTYPE html><html><head><title>Bode Plot</title>\
<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\
<style>canvas { border: 1px solid #333; }</style></head>\
<body><canvas id=\"phaseplot\" width=\"600\" height=\"400\"></canvas>\
<canvas id=\"gainplot\" width=\"600\" height=\"400\"></canvas><script>\
function plot_2D(freqs, gain, canvasID) {\
const canvas = document.getElementById(canvasID);\
const ctx = canvas.getContext(\"2d\");\
const width = canvas.width;\
const height = canvas.height;\
const margin = 70;\
const x0 = margin;\
const y0 = height - margin;\
const x1 = width - margin;\
const y1 = margin;\
const freqMin = Math.min(...freqs);\
const freqMax = Math.max(...freqs);\
const xmin = Math.log10(freqMin);\
const xmax = Math.log10(freqMax);\
const ymin = Math.min(...gain);\
const ymax = Math.max(...gain);\
function X(log10Value) { return x0 + (log10Value - xmin) * (x1 - x0) / (xmax - xmin); }\
function Y(value) { return y0 - (value - ymin) * (y0 - y1) / (ymax - ymin); }\
ctx.clearRect(0, 0, width, height);\
ctx.lineWidth = 2;\
ctx.strokeStyle = \"black\";\
ctx.beginPath();\
ctx.moveTo(x0, y0);\
ctx.lineTo(x1, y0);\
ctx.moveTo(x0, y0);\
ctx.lineTo(x0, y1);\
ctx.stroke();\
ctx.lineWidth = 2;\
ctx.font = \"12px sans-serif\";\
ctx.fillStyle = \"black\";\
ctx.textAlign = \"center\";\
const decadeMin = Math.floor(xmin);\
const decadeMax = Math.ceil(xmax);\
for (let d = decadeMin; d <= decadeMax; d++) {\
for (let m = 1; m <= 9; m++) {\
const freq = m * Math.pow(10, d);\
if (freq < freqMin || freq > freqMax) continue;\
const cx = X(Math.log10(freq));\
ctx.beginPath();\
if (m === 1) {\
ctx.moveTo(cx, y0);\
ctx.lineTo(cx, y0 + 10);\
ctx.stroke();\
const majorVal = Math.pow(10, d);\
const label = majorVal >= 1000 ? (majorVal / 1000) + \"k\" : String(majorVal);\
ctx.fillText(label, cx, y0 + 22);\
} else {\
ctx.moveTo(cx, y0);\
ctx.lineTo(cx, y0 + 6);\
ctx.stroke();\
}\
}\
}\
ctx.textAlign = \"right\";\
const numYTicks = 5;\
for (let i = 0; i <= numYTicks; i++) {\
const value = ymin + i * (ymax - ymin) / numYTicks;\
const cy = Y(value);\
ctx.beginPath();\
ctx.moveTo(x0 - 8, cy);\
ctx.lineTo(x0, cy);\
ctx.stroke();\
ctx.fillText(value.toFixed(1), x0 - 12, cy + 4);\
}\
ctx.textAlign = \"center\";\
ctx.font = \"14px sans-serif\";\
ctx.fillText(\"Frequency [Hz]\", width / 2 - 30, height - 20);\
ctx.save();\
ctx.translate(15, height / 2);\
ctx.rotate(-Math.PI / 2);\
if(canvasID == \"gainplot\"){ctx.fillText(\"Gain[dB]\", -30, 5);}\
else if(canvasID == \"phaseplot\"){ctx.fillText(\"Phase [degrees]\", -30, 5)}\
ctx.restore();\
ctx.fillStyle = \"blue\";\
for (let i = 0; i < gain.length; i++) {\
ctx.beginPath();\
const log_data_x = Math.log10(freqs[i]);\
ctx.arc(X(log_data_x), Y(gain[i]), 3, 0, 2 * Math.PI);\
ctx.fill();\
}\
}\
const gain_data = ";

char* scriptEnd = ";\
const phase_data = ";

char* webpageEnd = ";\
const freq_data = ";

char* dataEnd = ";\
plot_2D(freq_data, phase_data, \"phaseplot\");\
plot_2D(freq_data, gain_data, \"gainplot\");\
</script></body></html>";

/*
char* webpageStart = "<!DOCTYPE html><html><head><title>George and Matthews O-Scope</title>\
	<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\
	</head>\
	<body><h1>George and Matthews O-Scope</h1>";

char* plot =
"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
"<style>canvas { border: 1px solid #333; }</style></head>"
"<canvas id=\"plot\" width=\"1000\" height=\"400\"></canvas>"
"<script>"
"function plot_2D(adc_data) {"
    "const canvas = document.getElementById(\"plot\");"
    "const ctx = canvas.getContext(\"2d\");"
    "const width = canvas.width;"
    "const height = canvas.height;"
    "const data = new Array(adc_data.length);"
    "for (let i = 0; i < data.length; i++) {data[i] = (3.29483 * adc_data[i]) / 4095.0;}"
    "const margin = 70;"
    "const x0 = margin;"
    "const y0 = height - margin;"
    "const x1 = width - margin;"
    "const y1 = margin;"
    "const xmin = 0;"
    "const xmax = data.length - 1;"
    "const ymin = Math.min(...data);"
    "const ymax = Math.max(...data);"
    "function X(sample) { return x0 + (sample - xmin) * (x1 - x0) / (xmax - xmin); }"
    "function Y(value) { return y0 - (value - ymin) * (y0 - y1) / (ymax - ymin); }"
    "ctx.clearRect(0, 0, width, height);"
    "ctx.lineWidth = 2;"
    "ctx.strokeStyle = \"black\";"
    "ctx.beginPath();"
    "ctx.moveTo(x0, y0);"
    "ctx.lineTo(x1, y0);"
    "ctx.moveTo(x0, y0);"
    "ctx.lineTo(x0, y1);"
    "ctx.stroke();"
    "ctx.lineWidth = 1;"
    "ctx.font = \"12px sans-serif\";"
    "ctx.fillStyle = \"black\";"
    "for (let i = 0; i <= 6; i++) {"
        "const sample = xmin + i * (xmax - xmin) / 6;"
        "const cx = X(sample);"
        "ctx.beginPath();"
        "ctx.moveTo(cx, y0);"
        "ctx.lineTo(cx, y0 + 5);"
        "ctx.stroke();"
        "ctx.fillText(sample.toFixed(0), cx - 10, y0 + 18);"
    "}"
    "for (let i = 0; i <= 6; i++) {"
        "const value = ymin + i * (ymax - ymin) / 6;"
        "const cy = Y(value);"
        "ctx.beginPath();"
        "ctx.moveTo(x0 - 5, cy);"
        "ctx.lineTo(x0, cy);"
        "ctx.stroke();"
        "ctx.fillText(value.toFixed(2), x0 - 45, cy + 4);"
    "}"
    "ctx.font = \"14px sans-serif\";"
    "ctx.fillText(\"Samples\", width / 2 - 30, height - 10);"
    "ctx.save();"
    "ctx.translate(15, height / 2);"
    "ctx.rotate(-Math.PI / 2);"
    "ctx.fillText(\"Voltage [V]\", -30, 0);"
    "ctx.restore();"
    "ctx.strokeStyle = \"blue\";"
    "ctx.lineWidth = 2;"
    "ctx.beginPath();"
    "ctx.moveTo(X(0), Y(data[0]));"
    "for (let i = 1; i < data.length; i++) {"
        "ctx.lineTo(X(i), Y(data[i]));"
    "}"
    "ctx.stroke();"
"}"
"const data = "; // insert data

char* webpageEnd =
";" 
"plot_2D(data);"
"</script>"
"</body></html>";
*/

/*-----------------FUNCTION PROTOTYPES--------------------*/

int inString(char request[], char des[]);
int adcConversion(uint16_t* buffer, int num_samples);
//int adcConversion(uint16_t* buffer);
void config(void);
int main(void);
void doubleArray2String(double *array, char *string);
void uint32Array2String(uint32_t *array, char *string);

#endif // MAIN_H