VGA PROJECT: Discrete Component VGA Card

[Demo VGA Project YouTube](https://youtube.com/shorts/xp8ev63LN8c)
[Demo VGA TTL Video Card](https://youtube.com/shorts/Ok6mRmr4r1A)

A VGA board built entirely from discrete components to generate a full sync signal and video buffer.
The goal is to understand digital electronics and create a self-built 8-bit computer that requires a video card for output.
Any CPU can be used (such as the Arduino Uno used in this project), as well as any existing or custom-built CPU.
The board is prototyped on breadboards and consists of a signal generator, a DAC, and a video buffer.
The DAC uses 6 resistors for a 64-color palette (6-bit). The last 2 bits are unused.
Specifications
The board simulates an 800x600 @ 60 Hz resolution. The horizontal scan timing is reduced by a quarter to achieve 200x600 @ 60 Hz, driven by a 10 MHz active crystal oscillator.
The video RAM manages 200x150 pixels (30,000 pixels total). Currently, it is possible to write 628 pixels per frame during the SyncH low signal phase (which lasts 3,200 ns), resulting in a write speed of $628 \text{ pixels} \times 60 \text{ frames} = 37,680 \text{ pixels/second}$.
Video memory is writable only during the active SyncH phase (low level), lasting approximately 3,200 ns per line.
Note: This time window represents when the board is ready to receive data from the CPU; it does not imply the CPU can fully saturate the available bandwidth.
The actual number of writable pixels depends strictly on CPU speed and software implementation. The pixel storage range can be easily expanded by adding more control logic components.
Timing Details:
•	Horizontal Blanking: 6,400 ns for 628 lines @ 60 frames.
•	Vertical Blanking: 28 lines at 26,400 ns/line @ 60 frames.
•	SyncH (Low): Occurs when the horizontal counter is between 210 and 242.
•	SyncV (Low): Occurs when the vertical counter is between 601 and 605.
•	Horizontal Blank: From count 201 to 264.
•	Vertical Blank: From count 601 to 628.
________________________________________
PHASE 1: Signal Generator
Built on 4 breadboards.
•	Horizontal Line: Three 74HC161 counters (1 to 264) @ 10 MHz.
•	Vertical Line: Three 74HC161 counters (1 to 628).
Horizontal Counter:
Values 200, 210, 242, 263 are decoded via four 74LS30 (8-input NAND gates) and a dedicated 74HC04 (hex inverter). The Reset pin is not used for logic; instead, it's connected to GND via a capacitor/resistor network for "Power-On Reset" only. The LOAD function is used to restart from 1. The 4 decoded values are sampled by a 74HCT574 at 10 MHz. When 263 is sampled, it pulls the counters' LOAD pin low; at the next clock, counters reset to 1.
Vertical Counter:
Values 600, 601, 605, 628 are decoded similarly via 74LS30 and 74HC04 gates. The LOAD function restarts the count from 1. Sampling is handled by the same 74HCT574 used for the horizontal counter. The 263 output from the horizontal counter (sampled by the 74HCT574) acts as the clock for the vertical counter. When 628 is sampled, it triggers the LOAD pin for the vertical counters.
Logic & Sync Output:
A 74HCT574 (10 MHz clock) samples the decoded outputs. The outputs drive four latches of a 74LS279:
1.	H-Blank: Set by 200 / Reset by 263.
2.	SyncH: Set by 210 / Reset by 242.
3.	V-Blank: Set by 600 / Reset by 628.
4.	SyncV: Set by 601 / Reset by 605.
Additional Components:
•	SyncH/SyncV: Signals from the 74LS279 are inverted (74HC04), sampled (74HC574), and sent to VGA pins 13 and 14.
•	NOPIXEL Signal: Generated using four 74HC32 (OR gates) to combine latch outputs (600-628 and 200-263) and sampled 263/628 signals. This signal is inverted and sampled before being sent to the DAC to ensure a black level during blanking.
________________________________________
PHASE 2: Video Buffer
Built on 2 breadboards.
•	Logic: 3x 74HC574 registers, 3x 74HC244 buffers.
•	Memory: 1x 6C1008 64KB SRAM (55ns).
The Address Bus is split into two 8-bit groups (X and Y).
•	Group X: Shared between a 74HC574 and a 74HC244 (horizontal line counter).
•	Group Y: Shared between a 74HC574 and a 74HC244 (vertical line counter).
The vertical counter uses 10 bits (1-628), but only 8 bits are used for the RAM (starting from the 10th MSB, excluding the 2 LSBs). This results in 150 vertical pixels, where each pixel is duplicated 4 times to fill the 600-line display.
Bus Management:
The 74LS279 H-Blank latch (200-263) controls the High-Impedance state of the buffers to disconnect counters from the RAM. When high, it enables High-Z on buffers and manages the RAM OE (Output Enable) for READ mode.
The SyncH signal (210-242) enables High-Z on the X-Y-Color registers, allowing the CPU to write pixels.
Arduino/CPU Interface:
The CPU monitors the SyncH state (Pin A0). When LOW, it can write by pulsing the clocks of the X-Y-Color registers and then pulling the WE (Write Enable) pin low.
•	Pins 0-7: Address/Data/Color Bus.
•	Pin A0: SyncH status read.
•	Pins 8-10: Clock for X, Y, and Color registers.
•	Pin 11: RAM WE (Active Low).
________________________________________
PHASE 3: DAC (Digital to Analog Converter)
Built on 1 breadboard.
•	Components: 1x 74HC574, 2x 74HC08 (AND gates), resistors ($3 \times 1500\Omega$, $3 \times 680\Omega$).
The 74HC574 samples the RAM output at 10 MHz to compensate for RAM propagation delay. The AND gates combine the 6-bit color data with the NOPIXEL signal to ensure RGB pins (1, 2, 3) are at 0V (GND) during blanking.
The resistor pairs (680Ω for MSB, 1500Ω for LSB) create the voltage levels for each RGB channel. VGA pins 5, 6, 7, 8, and 10 are tied to common GND.
________________________________________

RITARDI PiPeline:
----------------------------------------------------------------
DAC/74HC574     CONTATORE h   74HC574/LS279     74HC574 VGA
----------------------------------------------------------------	
262	             	263	           262	           261
263	   	          264            263              262
264	   	          1              264             263   
1	               	2	             1 	             264   pixel view
2	   	            3              2	             1
3             	  4	             3	             2
...	             	...           ...              ...
199        	      200           199              198
200         	   201            200              199
201         	  202             201              200    no pixel
...	   	        ...            ...               ...

