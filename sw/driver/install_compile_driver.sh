sudo sh -c "echo 1 > /sys/bus/pci/devices/0000\:86\:00.0/remove"
sudo sh -c "echo 1 > /sys/bus/pci/rescan"
cd /home/junsik/LAB/NVMe/sw/dma_ip_drivers-2020.2/XDMA/linux-kernel/xdma
sudo sh -c "DEBUG=1 make install"
sudo ../tests/load_driver.sh
/home/junsik/LAB/NVMe/build/xdma-test
