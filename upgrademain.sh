#!/bin/bash
cd $HOME
rm -rf lava
git clone https://github.com/lavanet/lava.git
cd lava
git checkout v5.3.0

export LAVA_BINARY=lavad
make install

sudo systemctl start lavad && sudo journalctl -u lavad -f --no-hostname -o cat
