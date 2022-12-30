#!/bin/bash
set -ex
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
cd $SCRIPT_DIR/../driver/dma_ip_drivers/XDMA/linux-kernel/xdma
sudo sh -c "make install"
sudo sh -c "echo 1 > /sys/bus/pci/rescan"
sudo sh -c "chmod o+rw /dev/xdma0_user"
sudo sh -c "chmod o+w /sys/bus/pci/devices/0000:86:00.0/reset"