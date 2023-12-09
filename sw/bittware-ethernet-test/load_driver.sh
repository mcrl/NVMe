XDMA_PATH=$(pwd)
cd $XDMA_PATH/dma_ip_drivers/XDMA/linux-kernel/xdma
sudo sh -c "DEBUG=1 make install"
sudo ../tests/load_driver.sh
