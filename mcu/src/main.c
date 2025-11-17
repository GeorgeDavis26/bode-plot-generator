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

char* webpage =
"<!doctype html>\n"
"<html lang=\"en-US\">\n"
"<head>\n"
"  <meta charset=\"utf-8\" />\n"
"  <title>Canvas Plot Example</title>\n"
"  <style>\n"
"    canvas {\n"
"      border: 1px solid #333;\n"
"    }\n"
"  </style>\n"
"</head>\n"
"<body>\n"
"\n"
"<canvas id=\"plot\" width=\"600\" height=\"400\"></canvas>\n"
"\n"
"<script>\n"
"function plot2D(canvasId, data) {\n"
"  const canvas = document.getElementById(canvasId);\n"
"  const ctx = canvas.getContext(\"2d\");\n"
"\n"
"  const W = canvas.width;\n"
"  const H = canvas.height;\n"
"\n"
"  const margin = 40;\n"
"  const x0 = margin;\n"
"  const y0 = H - margin;\n"
"  const x1 = W - margin;\n"
"  const y1 = margin;\n"
"\n"
"  const xs = data.map(p => p[0]);\n"
"  const ys = data.map(p => p[1]);\n"
"  const xmin = Math.min(...xs);\n"
"  const xmax = Math.max(...xs);\n"
"  const ymin = Math.min(...ys);\n"
"  const ymax = Math.max(...ys);\n"
"\n"
"  function X(x) { return x0 + (x - xmin) * (x1 - x0) / (xmax - xmin); }\n"
"  function Y(y) { return y0 - (y - ymin) * (y0 - y1) / (ymax - ymin); }\n"
"\n"
"  ctx.clearRect(0, 0, W, H);\n"
"\n"
"  ctx.lineWidth = 2;\n"
"  ctx.strokeStyle = \"black\";\n"
"  ctx.beginPath();\n"
"  ctx.moveTo(x0, y0);\n"
"  ctx.lineTo(x1, y0);\n"
"  ctx.moveTo(x0, y0);\n"
"  ctx.lineTo(x0, y1);\n"
"  ctx.stroke();\n"
"\n"
"  ctx.lineWidth = 1;\n"
"  ctx.font = \"12px sans-serif\";\n"
"\n"
"  for (let i = 0; i <= 5; i++) {\n"
"    const x = xmin + i * (xmax - xmin) / 5;\n"
"    const cx = X(x);\n"
"    ctx.beginPath();\n"
"    ctx.moveTo(cx, y0);\n"
"    ctx.lineTo(cx, y0 + 5);\n"
"    ctx.stroke();\n"
"    ctx.fillText(x.toFixed(1), cx - 10, y0 + 18);\n"
"  }\n"
"\n"
"  for (let i = 0; i <= 5; i++) {\n"
"    const y = ymin + i * (ymax - ymin) / 5;\n"
"    const cy = Y(y);\n"
"    ctx.beginPath();\n"
"    ctx.moveTo(x0 - 5, cy);\n"
"    ctx.lineTo(x0, cy);\n"
"    ctx.stroke();\n"
"    ctx.fillText(y.toFixed(1), x0 - 35, cy + 4);\n"
"  }\n"
"\n"
"  ctx.strokeStyle = \"blue\";\n"
"  ctx.lineWidth = 2;\n"
"  ctx.beginPath();\n"
"  ctx.moveTo(X(data[0][0]), Y(data[0][1]));\n"
"  for (let i = 1; i < data.length; i++) {\n"
"    ctx.lineTo(X(data[i][0]), Y(data[i][1]));\n"
"  }\n"
"  ctx.stroke();\n"
"}\n"
"\n"
"const exampleData = [\n"
"  [0, 1],\n"
"  [1, 3],\n"
"  [2, 2],\n"
"  [3, 5],\n"
"  [4, 4],\n"
"  [5, 7]\n"
"];\n"
"\n"
"plot2D(\"plot\", exampleData);\n"
"</script>\n"
"</body>\n"
"</html>\n";



char* webpageStart = "<!DOCTYPE html><html><head><title>Bode Plot Generator: E155 Project </title>\
	<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\
	</head>\
	<body><h1>George Davis Lab 6 temp Sensor</h1>";
/*
char* phasePlot = "<p>
                    Temperature Resolution Control:
                </p>
                SOMEHOW PLOT uint16_t phase";


char* gainPlot = "<p>
                    Temperature Resolution Control:
                </p>
                SOMEHOW PLOT uint16_t gain";


  char* webpageEnd   = "</body></html>";
*/
//determines whether a given character sequence is in a char array request, returning 1 if present, -1 if not present

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
        sendString(USART, webpage); // webpage header code
    }
}

