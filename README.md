# Lava
Lava is a protocol that coordinates dapp and AI agent traffic on each blockchain. Lava aggregates RPC providers, dynamically scaling to support demand and route requests to fast, reliable providers.

# 🌟 Lava Setup & Upgrade Scripts

A collection of automated scripts for setting up and upgrading Lava nodes on **Mainnet (`lava-mainnet-1`)**.

---

### ⚙️ Validator Node Setup  
Install a Lava validator node with custom ports, snapshot download, and systemd service configuration.

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Lava/main/installmain.sh)
~~~
---

### 🔄 Validator Node Upgrade 
Upgrade your Lava node binary and safely restart the systemd service.

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Lava/main/upgrademain.sh)
~~~

---

### 🧰 Useful Commands

| Task            | Command                                 |
|-----------------|------------------------------------------|
| View logs       | `journalctl -u lavad -f -o cat`        |
| Check status    | `systemctl status lavad`              |
| Restart service | `systemctl restart lavad`             |
