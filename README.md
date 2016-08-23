# fpga-audio
Verilog modules for encoding and decoding various digital audio formats.

## Usage
See each module; I've tried to include comments. Most modules assume a clock
of 8x or 16x the data rate is available, and this should come from a stable
clock source such as a crystal oscillator. 

## License
MIT, see LICENSE file.

## Caveat Emptor
It's been a while since I've done any FPGA work. These modules are not 
especially likely to represent the best way of doing things. That said,
they are useful for me and hopefully they can be useful to you too.
Suggestions are always welcome.
