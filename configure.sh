
#!/bin/sh

# Download and install xray
mkdir /tmp/xray
curl -L -H "Cache-Control: no-cache" -o /tmp/xray/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip /tmp/xray/xray.zip -d /tmp/xray
install -m 755 /tmp/xray/xray /usr/local/bin/xray
curl -L https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -o /usr/local/bin/geoip.dat
curl -L https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o /usr/local/bin/geosite.dat

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
                "clients": [{"id": "$UUID","flow": ""}],
                "decryption": "none",
                "fallbacks": [
                    {"dest": 3001},
                    {"path": "$TROJAN_PATH","dest": 3002},
                    {"path": "$VLESS_PATH","dest": 3003}
                ]
            },
            "streamSettings": {"network": "tcp"}
        },
        {
            "port": 3001,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {"clients": [{"id": "$UUID"}],"decryption": "none"},
            "streamSettings": {"network": "ws","security": "none"}
        },
        {
            "port": 3002,
            "listen": "127.0.0.1",
            "protocol": "trojan",
            "settings": { "clients": [{"password": "$UUID"}]},
            "streamSettings": {"network": "ws","security": "none","wsSettings": {"path": "$TROJAN_PATH"}}
        },
        {
            "port": 3003,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {"clients": [{ "id": "$UUID"}],"decryption": "none"},
            "streamSettings": {"network": "ws","security": "none","wsSettings": {"path": "$VLESS_PATH"}}
        },
		{
            "listen": "0.0.0.0",
            "port": $SPORT,
            "protocol": "socks",
            "settings": {
                "auth": "password",
                "accounts": [
                    {
                        "user": "$SUSER",
                        "pass": "$SPASS"
                    }
                ],
                "udp": true,
                "ip": "127.0.0.1"
            }
        }
    ],
    "outbounds": [
		{"tag": "direct","protocol": "freedom"},
		{"tag": "block","protocol": "blackhole","settings": {"response": {"type": "http"}}}
    ],
	"routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {"outboundTag": "direct","domain": ["geosite:google"],"type": "field"},
            {"outboundTag": "block","domain": ["geosite:cn","geosite:category-ads-all"],"type": "field"},
            {"outboundTag": "block","ip": ["geoip:cn","geoip:private"],"type": "field"}
        ]
	}
}
EOF

# Run xray
/usr/local/bin/xray -config /usr/local/etc/xray/config.json
