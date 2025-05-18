#!/bin/bash

set -e

GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

print() {
  echo -e "${GREEN}$1${NC}"
}

print_error() {
  echo -e "${RED}$1${NC}"
}

read -p "Enter your node MONIKER: " MONIKER
read -p "Enter your custom port prefix (e.g. 16): " CUSTOM_PORT

print "Installing Lava Node with moniker: $MONIKER"
print "Using custom port prefix: $CUSTOM_PORT"

print "Updating system and installing dependencies..."
sudo apt update
sudo apt install -y curl git build-essential lz4 wget

sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.23.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
echo "export PATH=$PATH:/usr/local/go/bin:/usr/local/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
rm -rf lava
git clone https://github.com/lavanet/lava.git
cd lava
git checkout v5.3.0
make install-all

lavad config chain-id lava-mainnet-1
lavad config keyring-backend file
lavad config node tcp://localhost:${CUSTOM_PORT}657
lavad init $MONIKER --chain-id lava-mainnet-1

curl -Ls https://snapshots.kjnodes.com/lava/genesis.json > $HOME/.lava/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/lava/addrbook.json > $HOME/.lava/config/addrbook.json

sed -i -e "s|^seeds *=.*|seeds = \"ebacd3e666003397fb685cd44956d33419219950@seed2.lava.chainlayer.net:26656,1105d3a3384edaa450f4f63c2b1ff08d366ee256@159.203.86.102:26656,f1caeaacfac32e4dd00916e8d912e1d834e94eb3@lava-seed.stakecito.com:26666,e4eb68c6fdfab1575b8794205caed47d4f737df4@lava-mainnet-seed.01node.com:26107,2d4db6b95804ea97e1f3655d043e6becf9bffc94@lava-seeds2.w3coins.io:11156,dcbfb490ea930fe9e8058089e3f6a14ca274c1c4@217.182.136.79:26656,e023c3892862744081360a99a2666e8111b196d3@38.242.213.53:26656,eafff29ec471bdd0985a9360b2c103997539c939@lava-seed.node.monster:26649,6a9a65d92b4820a5d198dd95743aa3059d0d3d4c@seed-lava.hashkey.cloud:26656\"|" $HOME/.lava/config/config.toml
peers="159a27880fe8704f44c307b18404061d46b77083@162.19.95.240:15656,0d6aed3038c55387f5b7c8fb1e702545358213ea@65.109.78.246:37656,0d67bedc7f929200d52c8724dfc50f848661f9ba@65.109.69.119:28656,f978474e77246a3635340d3bdb8dc14cb28d5ba0@188.214.129.218:26656,4008607a63c61e23bb74dfa613f93f9d178f5bd8@54.38.12.103:26656,d9bfa29e0cf9c4ce0cc9c26d98e5d97228f93b0b@65.108.233.103:14456,03c935c903ec7620d8e653fd179d5aa927888a09@136.243.55.115:40004,9d6216e9d79dc73247336ea18b928af9c9544e4f@51.210.223.80:19956,91971680907af210c45bf3618046314225a2629f@176.103.222.58:26656"
sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$peers\"|" $HOME/.lava/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.000000001ulava\"|" $HOME/.lava/config/app.toml
sed -i \
-e 's/timeout_propose = .*/timeout_propose = "1s"/' \
-e 's/timeout_propose_delta = .*/timeout_propose_delta = "500ms"/' \
-e 's/timeout_prevote = .*/timeout_prevote = "1s"/' \
-e 's/timeout_prevote_delta = .*/timeout_prevote_delta = "500ms"/' \
-e 's/timeout_precommit = .*/timeout_precommit = "500ms"/' \
-e 's/timeout_precommit_delta = .*/timeout_precommit_delta = "1s"/' \
-e 's/timeout_commit = .*/timeout_commit = "15s"/' \
-e 's/^create_empty_blocks = .*/create_empty_blocks = true/' \
-e 's/^create_empty_blocks_interval = .*/create_empty_blocks_interval = "15s"/' \
-e 's/^timeout_broadcast_tx_commit = .*/timeout_broadcast_tx_commit = "151s"/' \
-e 's/skip_timeout_commit = .*/skip_timeout_commit = false/' \
$HOME/.lava/config/config.toml

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.lava/config/app.toml 
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.lava/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.lava/config/app.toml
  
sed -i.bak -e "s%:26658%:${CUSTOM_PORT}658%g;
s%:26657%:${CUSTOM_PORT}657%g;
s%:26656%:${CUSTOM_PORT}656%g;
s%:6060%:${CUSTOM_PORT}060%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${CUSTOM_PORT}56\"%;
s%:26660%:${CUSTOM_PORT}660%g" $HOME/.lava/config/config.toml

sed -i.bak -e "s%:1317%:${CUSTOM_PORT}317%g;
s%:8080%:${CUSTOM_PORT}080%g;
s%:9090%:${CUSTOM_PORT}090%g;
s%:9091%:${CUSTOM_PORT}091%g;
s%:8545%:${CUSTOM_PORT}545%g;
s%:8546%:${CUSTOM_PORT}546%g" $HOME/.lava/config/app.toml

sudo tee /etc/systemd/system/lavad.service > /dev/null <<EOF
[Unit]
Description=Lava node
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/.lava
ExecStart=$(which lavad) start --home $HOME/.lava
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

print "Downloading snapshot..."
curl -L https://snapshots.kjnodes.com/lava/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.lava

sudo systemctl daemon-reload
sudo systemctl enable lavad
sudo systemctl start lavad

print "✅ Setup complete. Use 'journalctl -u lavad -f -o cat' to view logs"
