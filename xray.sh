#!/bin/bash
# XRay Installation
# Coded By AJ
# ==================================

# // Update & Installing Requirement
apt update -y
apt upgrade -y
apt install socat -y
apt install python -y
apt install curl -y
apt install wget -y
apt install sed -y
apt install nano -y
apt install python3 -y

# // Make Main Directory
mkdir -p /usr/local/dark-xray/

# // Installation XRay Core
wget -q -O /usr/local/dark-xray/xray-mini "https://raw.githubusercontent.com/wehoi/ws/main/xray-min" 
chmod +x /usr/local/dark-xray/xray-mini

# // Make XRay Mini Root Folder
mkdir -p /etc/xray-mini/
chmod 775 /etc/xray-mini/

# // Installing XRay Mini Service
cat > /etc/systemd/system/xray-mini@.service << EOF
[Unit]
Description=XRay-Mini Service ( %i )
Documentation=https://speedtest.net https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=root
NoNewPrivileges=true
ExecStart=/usr/local/dark-xray/xray-mini -config /etc/xray-mini/%i.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

# // String
ssl_path_crt="/etc/v2ray/v2ray.crt"
ssl_path_key="/etc/v2ray/v2ray.key"
uuid=$(cat /proc/sys/kernel/random/uuid)

# // Vless Splice
cat > /etc/xray-mini/vless-splice.json << END
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "flow": "xtls-rprx-splice"
#XRay
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 60000,
            "alpn": "",
            "xver": 1
          },
          {
            "dest": 60001,
            "alpn": "h2",
            "xver": 1
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
          "minVersion": "1.2",
          "certificates": [
            {
              "certificateFile": "${ssl_path_crt}",
              "keyFile": "${ssl_path_key}"
            }
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
END

# // Vless Direct
cat > /etc/xray-mini/vless-direct.json << END
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "flow": "xtls-rprx-direct"
#XRay
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 60000,
            "alpn": "",
            "xver": 1
          },
          {
            "dest": 60001,
            "alpn": "h2",
            "xver": 1
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
          "minVersion": "1.2",
          "certificates": [
            {
              "certificateFile": "${ssl_path_crt}",
              "keyFile": "${ssl_path_key}"
            }
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
END

iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 443 -j ACCEPT
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload
systemctl daemon-reload
systemctl enable xray-mini@vless-direct
systemctl start xray-mini@vless-direct
systemctl enable xray-mini@vless-splice
systemctl start xray-mini@vless-splice

# // Remove Not Used Files
rm -f install-xray.sh
