#!/bin/bash

#source /opt/Xilinx/13.4/ISE_DS/settings64.sh
app_name=$1
ISIM_HOME=/home/soteria/openrisc/orpsocv2/boards/xilinx/atlys/isim

echo "Going to $ISIM_HOME/app/$app_name"
cd $ISIM_HOME/app/$app_name
or32-elf-gcc -mnewlib -mboard=atlys $app_name.c -o $app_name
or32-elf-objdump -d $app_name > debug
or32-elf-objcopy -O binary $app_name $app_name.bin
bin2vmem $app_name.bin > $app_name.vmem
cp $app_name.vmem ../../sram.vmem

echo "Cleaning at $ISIM_HOME"
cd $ISIM_HOME
rm -r isim/*
rm fuse*
cp ../syn/xst/run/orpsoc.prj project/
fuse work.orpsoc_testbench work.glbl -f command/isim_commands.def -o orpsoc

echo "Simulating at $ISIM_HOME"
cp project/orpsoc.prj.template project/orpsoc.prj
fuse work.orpsoc_testbench work.glbl -f command/isim_commands.def -o orpsoc

./orpsoc -tclbatch tcl/run_test.tcl > debug_sim

