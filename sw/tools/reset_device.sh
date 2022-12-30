#!/bin/bash
set -ex
sudo sh -c "echo 1 > /sys/bus/pci/devices/0000:86:00.0/reset"
