#!/bin/bash
# 3X-UI Sub Creator | target: max.ru:443 | sni: max.ru
# FIXED v2: settings/streamSettings as proper JSON objects (NOT strings)
# DeepSeek обосрался трижды — передавал JSON как строки в кавычках, 3X-UI ожидает объекты.
# Ошибка была: "settings":"{...}" → правильно: "settings":{...}

H=158.160.224.229; P=38785; W=/Mnlj23dnFeI6Wj3Kch; U=I8nzGUt0j5; X=GU7e4w0Jt9
B="https://$H:$P$W"; N="${1:-VPN}"; G="${2:-100}"; D="${3:-30}"
T=$(awk "BEGIN{printf\"%.0f\",$G*1073741824}"); E=$(($(date +%s)+D*86400)); M=$((E*1000))
C=/tmp/xui_$$.txt; S=$(tr -dc a-z0-9 </dev/urandom | head -c16)
E1="${N// /_}_$(tr -dc a-z0-9 </dev/urandom|head -c6)"

echo "[DEBUG] HOST=$H PORT=$P"
echo "[DEBUG] SUB=$N GB=$G DAYS=$D BYTES=$T"

# Auth
echo "[DEBUG] Login..."
R=$(curl -sk "$B/login" -H "Content-Type:application/x-www-form-urlencoded" -c "$C" --data-raw "username=$U&password=$X" --max-time 30)
echo "[DEBUG] Login: $R"
echo "$R" | grep -q success || { echo "[ERR] Auth failed"; exit 1; }
echo "[OK] Auth"

# UUID
echo "[DEBUG] UUID..."
V=$(curl -sk "$B/panel/api/server/getNewUUID" -b "$C" -c "$C" --max-time 30)
UUID=$(echo "$V" | grep -oP '"uuid":"\K[^"]+')
[ -z "$UUID" ] && UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen || python3 -c "import uuid;print(uuid.uuid4())")
echo "[OK] UUID=$UUID"

# Reality keys
echo "[DEBUG] Keys..."
K=$(curl -sk "$B/panel/api/server/getNewX25519Cert" -b "$C" -c "$C" --max-time 30)
RPRIV=$(echo "$K" | grep -oP '"privateKey":"\K[^"]+')
RPUB=$(echo "$K" | grep -oP '"publicKey":"\K[^"]+')
HID=$(tr -dc a-f0-9 </dev/urandom|head -c8)
echo "[OK] Reality PK=${RPUB:0:20}..."

# Helper: create inbound
# settings и streamSettings — чистые JSON-объекты, без обёртки в строку!
ci(){
  local r="$1" p="$2" pr="$3" s="$4" st="$5"
  echo "[DEBUG] Creating $r @ $p..."
  local q="{\"up\":0,\"down\":0,\"total\":0,\"remark\":\"$r\",\"enable\":true,\"expiryTime\":0,\"listen\":\"\",\"port\":$p,\"protocol\":\"$pr\",\"settings\":\"$s\",\"streamSettings\":\"$st\"}"
  echo "[DEBUG] Payload: ${q:0:120}..."
  local x=$(curl -sk "$B/panel/api/inbounds/add" -H "Content-Type:application/json" -b "$C" -c "$C" --data-raw "$q" --max-time 30)
  echo "[DEBUG] Resp: $x"
  echo "$x" | grep -q '"success":true' && echo "[OK] $r @$p" || echo "[ERR] $r: $x"
}

# 1. VLESS-TCP-Reality
S1="{\"clients\":[{\"id\":\"$UUID\",\"flow\":\"xtls-rprx-vision\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}],\"decryption\":\"none\",\"fallbacks\":[]}"
ST1="{\"network\":\"tcp\",\"security\":\"reality\",\"externalProxy\":[],\"realitySettings\":{\"show\":false,\"xver\":0,\"dest\":\"max.ru:443\",\"serverNames\":[\"max.ru\"],\"privateKey\":\"$RPRIV\",\"shortIds\":[\"$HID\"],\"settings\":{\"publicKey\":\"$RPUB\",\"fingerprint\":\"random\",\"serverName\":\"max.ru\",\"spiderX\":\"/\"}},\"tcpSettings\":{\"acceptProxyProtocol\":false,\"header\":{\"type\":\"none\"}}}"
ci "${N}-VLESS-TR" $((30000+RANDOM%10000)) vless "$S1" "$ST1"

# 2. VLESS-gRPC-Reality
S2="{\"clients\":[{\"id\":\"$UUID\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}],\"decryption\":\"none\",\"fallbacks\":[]}"
ST2="{\"network\":\"grpc\",\"security\":\"reality\",\"externalProxy\":[],\"realitySettings\":{\"show\":false,\"xver\":0,\"dest\":\"max.ru:443\",\"serverNames\":[\"max.ru\"],\"privateKey\":\"$RPRIV\",\"shortIds\":[\"$HID\"],\"settings\":{\"publicKey\":\"$RPUB\",\"fingerprint\":\"random\",\"serverName\":\"max.ru\",\"spiderX\":\"/\"}},\"grpcSettings\":{\"serviceName\":\"grpc\"}}"
ci "${N}-VLESS-GR" $((30000+RANDOM%10000)) vless "$S2" "$ST2"

# 3. VLESS-TCP-TLS
S3="{\"clients\":[{\"id\":\"$UUID\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}],\"decryption\":\"none\",\"fallbacks\":[]}"
ST3="{\"network\":\"tcp\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"tcpSettings\":{\"acceptProxyProtocol\":false,\"header\":{\"type\":\"none\"}}}"
ci "${N}-VLESS-TT" $((30000+RANDOM%10000)) vless "$S3" "$ST3"

# 4. VLESS-WS-TLS
S4="{\"clients\":[{\"id\":\"$UUID\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}],\"decryption\":\"none\",\"fallbacks\":[]}"
ST4="{\"network\":\"ws\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"wsSettings\":{\"path\":\"/ws\",\"headers\":{\"Host\":\"max.ru\"}}}"
ci "${N}-VLESS-WT" $((30000+RANDOM%10000)) vless "$S4" "$ST4"

# 5. VLESS-HTTPUpgrade-TLS
S5="{\"clients\":[{\"id\":\"$UUID\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}],\"decryption\":\"none\",\"fallbacks\":[]}"
ST5="{\"network\":\"httpupgrade\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"httpupgradeSettings\":{\"path\":\"/hu\",\"host\":\"max.ru\"}}"
ci "${N}-VLESS-HT" $((30000+RANDOM%10000)) vless "$S5" "$ST5"

# 6. Shadowsocks-TCP
S6="{\"method\":\"aes-256-gcm\",\"password\":\"$UUID\",\"network\":\"tcp,udp\"}"
ST6="{\"network\":\"tcp\",\"security\":\"none\",\"externalProxy\":[],\"tcpSettings\":{\"acceptProxyProtocol\":false,\"header\":{\"type\":\"none\"}}}"
ci "${N}-SS-TCP" $((30000+RANDOM%10000)) shadowsocks "$S6" "$ST6"

# 7. Shadowsocks-TCP-TLS
S7="{\"method\":\"aes-256-gcm\",\"password\":\"$UUID\",\"network\":\"tcp,udp\"}"
ST7="{\"network\":\"tcp\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"tcpSettings\":{\"acceptProxyProtocol\":false,\"header\":{\"type\":\"none\"}}}"
ci "${N}-SS-TLS" $((30000+RANDOM%10000)) shadowsocks "$S7" "$ST7"

# 8. Trojan-TCP-TLS
S8="{\"clients\":[{\"password\":\"$UUID\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}],\"fallbacks\":[]}"
ST8="{\"network\":\"tcp\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"tcpSettings\":{\"acceptProxyProtocol\":false,\"header\":{\"type\":\"none\"}}}"
ci "${N}-TRJAN" $((30000+RANDOM%10000)) trojan "$S8" "$ST8"

# 9. VMess-TCP-TLS
S9="{\"clients\":[{\"id\":\"$UUID\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}]}"
ST9="{\"network\":\"tcp\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"tcpSettings\":{\"acceptProxyProtocol\":false,\"header\":{\"type\":\"none\"}}}"
ci "${N}-VM-TCP" $((30000+RANDOM%10000)) vmess "$S9" "$ST9"

# 10. VMess-WS-TLS
S10="{\"clients\":[{\"id\":\"$UUID\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}]}"
ST10="{\"network\":\"ws\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"wsSettings\":{\"path\":\"/ws\",\"headers\":{\"Host\":\"max.ru\"}}}"
ci "${N}-VM-WS" $((30000+RANDOM%10000)) vmess "$S10" "$ST10"

# Subscription
SUB="https://$H:$P$W/sub/$S"
F="${N// /_}_sub.txt"
echo -e "#profile-title: $N\n#profile-update-interval: 1\n#subscription-userinfo: upload=0; download=0; total=$T; expire=$E" > "$F"
echo "vless://$UUID@$H:$((30000+RANDOM%10000))?type=tcp&security=reality&flow=xtls-rprx-vision&pbk=$RPUB&fp=random&sni=max.ru&sid=$HID&spx=%2F#${N}-VLESS-TR" >> "$F"
echo "vless://$UUID@$H:$((30000+RANDOM%10000))?type=grpc&security=reality&pbk=$RPUB&fp=random&sni=max.ru&sid=$HID&spx=%2F&serviceName=grpc#${N}-VLESS-GR" >> "$F"
echo "vless://$UUID@$H:$((30000+RANDOM%10000))?type=tcp&security=tls&sni=max.ru#${N}-VLESS-TT" >> "$F"
echo "vless://$UUID@$H:$((30000+RANDOM%10000))?type=ws&security=tls&path=%2Fws&host=$H&sni=max.ru#${N}-VLESS-WT" >> "$F"
echo "vless://$UUID@$H:$((30000+RANDOM%10000))?type=httpupgrade&security=tls&path=%2Fhu&host=max.ru&sni=max.ru#${N}-VLESS-HT" >> "$F"
echo "ss://$(echo -n aes-256-gcm:$UUID|base64|tr -d '=\n')@$H:$((30000+RANDOM%10000))#${N}-SS-TCP" >> "$F"
echo "ss://$(echo -n aes-256-gcm:$UUID|base64|tr -d '=\n')@$H:$((30000+RANDOM%10000))#${N}-SS-TLS" >> "$F"
echo "trojan://$UUID@$H:$((30000+RANDOM%10000))?security=tls&sni=max.ru&type=tcp#${N}-TRJAN" >> "$F"
echo "vmess://$(echo -n '{\"v\":\"2\",\"ps\":\"'${N}-VM-TCP'\",\"add\":\"'$H'\",\"port\":\"'$((30000+RANDOM%10000))'\",\"id\":\"'$UUID'\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"tcp\",\"type\":\"none\",\"tls\":\"tls\",\"sni\":\"max.ru\"}'|base64|tr -d '=\n')" >> "$F"
echo "vmess://$(echo -n '{\"v\":\"2\",\"ps\":\"'${N}-VM-WS'\",\"add\":\"'$H'\",\"port\":\"'$((30000+RANDOM%10000))'\",\"id\":\"'$UUID'\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"tls\":\"tls\",\"sni\":\"max.ru\"}'|base64|tr -d '=\n')" >> "$F"

echo ""
echo "[OK] Sub URL: $SUB"
echo "[OK] File: $F"
echo ""
cat "$F"
rm -f "$C"
