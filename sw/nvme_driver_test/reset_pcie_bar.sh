sudo rmmod xdma
sudo sh -c "echo 1 > /sys/bus/pci/devices/0000\:81\:00.0/remove"  # 250-SoC
sudo sh -c "echo 1 > /sys/bus/pci/devices/0000\:c2\:00.0/remove"  # Alveo U280
sudo sh -c "echo 1 > /sys/bus/pci/rescan"
