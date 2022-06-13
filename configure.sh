#!/bin/sh

# Download and install xray
mkdir /tmp/xray
curl -L -H "Cache-Control: no-cache" -o /tmp/xray/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip /tmp/xray/xray.zip -d /tmp/xray
install -m 755 /tmp/xray/xray /usr/local/bin/xray

# Remove temporary directory
rm -rf /tmp/xray

# xray new configuration
install -d /usr/local/etc/xray
cat << EOF > /usr/local/etc/xray/config.json
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": $PORT,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "flow": "xtls-rprx-direct"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
					{
                        "dest": 3001
                    },
                    {
                        "path": "$TROJAN_PATH",
                        "dest": 3002
                    },
                    {
                        "path": "$VMESS_PATH",
                        "dest": 3003
                    },
                    {
                        "path": "$VLESS_PATH",
                        "dest": 3004
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp"
            }
        },
        {
            "port": 3001,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none"
            }
        },
        {
            "port": 3002,
            "listen": "127.0.0.1",
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "$UUID"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "$TROJAN_PATH"
                }
            }
        },
        {
            "port": 3003,
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "$VMESS_PATH"
                }
            }
        },
		{
            "port": 3004,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
				"wsSettings": {
                    "path": "$VLESS_PATH"
                }
            }
        }
    ],
    "outbounds": [
		{
			"tag": "direct",
			"protocol": "freedom"
		},
		{
		  "tag": "block",
		  "protocol": "blackhole",
		  "settings": {
			"response": {
			  "type": "http"
			}
		  }
		}
    ],
	"routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "domain": [
                    "geosite:cn"
                ],
                "outboundTag": "block",
                "type": "field"
            },
            {
                "ip": [
                    "geoip:cn"
                ],
                "outboundTag": "block",
                "type": "field"
            },
			{
				"domain": [
					"geosite:category-ads-all"
				],
                "outboundTag": "block",
                "type": "field"
            },
			{
				"ip": [
					"geoip:private"
				],
				"outboundTag": "block",
				"type": "field"
			}
       ]
	}
}
EOF

# Run xray
/usr/local/bin/xray -config /usr/local/etc/xray/config.json
