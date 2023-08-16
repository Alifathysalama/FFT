vlib work
vlog FFT.v FFT_tb.v FFT_DIT_Radix2.v CU.v 
vsim -voptargs=+acc work.FFT_tb
add wave *

