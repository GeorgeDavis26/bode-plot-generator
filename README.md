George Davis and Matthew Molinar

gdavis@hmc.edu
mmolinar@hmc.edu

This project will implement an interactive Bode plot generator, which will be capable of displaying the amplitude and phase response of a device under test (DUT) across a swept frequency range. This will be implemented using an FPGA to generate sine waves via an internal DDS, and an MCU to receive and process the signal. Then, the data is sent from the MCU to an ESP8266, which will host a webpage for plotting the Bode plot.