#!/bin/bash
set -ex
sudo sh -c "echo 1 > /sys/bus/pci/rescan"
