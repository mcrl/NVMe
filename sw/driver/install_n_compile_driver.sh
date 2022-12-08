XDMA_PATH=$(pwd)
sudo sh -c "echo 1 > /sys/bus/pci/devices/0000\:86\:00.0/remove"
sudo sh -c "echo 1 > /sys/bus/pci/rescan"
cd $XDMA_PATH/dma_ip_drivers/XDMA/linux-kernel/xdma
sudo sh -c "DEBUG=1 make install"
sudo ../tests/load_driver.sh
