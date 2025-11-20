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
#define NUM_SAMPLES 600
#define NUM_FREQUENCIES 2

/*-----------------CONST WEBPAGE HTML STRINGS--------------------*/

char* webpageStart = "<!DOCTYPE html><html><head><title>George and Matthews O-Scope</title>\
	<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\
	</head>\
	<body><h1>George and Matthews O-Scope</h1>";

char* plot =
"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
"<style>canvas { border: 1px solid #333; }</style></head>"
"<canvas id=\"plot\" width=\"500\" height=\"400\"></canvas>"
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
/*-----------------FUNCTION PROTOTYPES--------------------*/

int inString(char request[], char des[]);
void config(void);
int main(void);

#endif // MAIN_H