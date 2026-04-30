#!/bin/bash
# 3X-UI Sub Creator | github.com/USER/REPO/raw/main/xui.sh
# target: max.ru:443 | sni: max.ru
set -e
H=158.160.224.229; P=38785; W=/Mnlj23dnFeI6Wj3Kch; U=I8nzGUt0j5; X=GU7e4w0Jt9
B="https://$H:$P$W"; N="${1:-VPN}"; G="${2:-100}"; D="${3:-30}"
T=$(awk "BEGIN{printf\"%.0f\",$G*1073741824}"); E=$(($(date +%s)+D*86400)); M=$((E*1000))
C=/tmp/xui_$$.txt; S=$(tr -dc a-z0-9 </dev/urandom | head -c16)
M1(){ echo -e "\033[36m[*]\033[0m $1"; }; M2(){ echo -e "\033[32m[OK]\033[0m $1"; }
M3(){ echo -e "\033[31m[ERR]\033[0m $1"; exit 1; }
XP(){ curl -sk "$B$1" -H "Content-Type:${3:-application/json}" -b "$C" -c "$C" --data-raw "$2" --max-time 30; }
XG(){ curl -sk "$B$1" -b "$C" -c "$C" --max-time 30; }
L(){ XP /login "username=$U&password=$X" "application/x-www-form-urlencoded"|grep -q success||M3 auth; M2 "Auth OK"; }
V(){ XG /panel/api/server/getNewUUID|grep -oP '"uuid":"\K[^"]+'; }
K(){ XG /panel/api/server/getNewX25519Cert; }
I(){ local r="$1" p="$2" pr="$3" s="$4" st="$5"
 local q=$(printf '{"up":0,"down":0,"total":0,"remark":"%s","enable":true,"expiryTime":0,"listen":"","port":%s,"protocol":"%s","settings":%s,"streamSettings":%s,"sniffing":{"enabled":true,"destOverride":["http","tls","quic","fakedns"],"metadataOnly":false,"routeOnly":false},"allocate":{"strategy":"always","refresh":5,"concurrency":3}}' "$r" "$p" "$pr" "$s" "$st")
 local x=$(XP /panel/api/inbounds/add "$q"); echo "$x"|grep -q success&&M2 "$r @$p"||M3 "$r failed"; }
U=$(V); [ -z "$U" ]&&U=$(cat /proc/sys/kernel/random/uuid 2>/dev/null||uuidgen||python3 -c "import uuid;print(uuid.uuid4())")
R=$(K|grep -oP '"privateKey":"\K[^"]+'); K=$(K|grep -oP '"publicKey":"\K[^"]+'); H=$(tr -dc a-f0-9 </dev/urandom|head -c8)
E1="${N// /_}_$(tr -dc a-z0-9 </dev/urandom|head -c6)"
L
M1 "UUID: $U"

# 10 inbounds
I "${N}-VLESS-TR" $((30000+RANDOM%10000)) vless \
  "{\"clients\":[{\"id\":\"$U\",\"flow\":\"xtls-rprx-vision\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}],\"decryption\":\"none\",\"fallbacks\":[]}" \
  "{\"network\":\"tcp\",\"security\":\"reality\",\"externalProxy\":[],\"realitySettings\":{\"show\":false,\"xver\":0,\"dest\":\"max.ru:443\",\"serverNames\":[\"max.ru\"],\"privateKey\":\"$R\",\"shortIds\":[\"$H\"],\"settings\":{\"publicKey\":\"$K\",\"fingerprint\":\"random\",\"serverName\":\"max.ru\",\"spiderX\":\"/\"}},\"tcpSettings\":{\"acceptProxyProtocol\":false,\"header\":{\"type\":\"none\"}}}"

I "${N}-VLESS-GR" $((30000+RANDOM%10000)) vless \
  "{\"clients\":[{\"id\":\"$U\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}],\"decryption\":\"none\",\"fallbacks\":[]}" \
  "{\"network\":\"grpc\",\"security\":\"reality\",\"externalProxy\":[],\"realitySettings\":{\"show\":false,\"xver\":0,\"dest\":\"max.ru:443\",\"serverNames\":[\"max.ru\"],\"privateKey\":\"$R\",\"shortIds\":[\"$H\"],\"settings\":{\"publicKey\":\"$K\",\"fingerprint\":\"random\",\"serverName\":\"max.ru\",\"spiderX\":\"/\"}},\"grpcSettings\":{\"serviceName\":\"grpc\"}}"

I "${N}-VLESS-TT" $((30000+RANDOM%10000)) vless \
  "{\"clients\":[{\"id\":\"$U\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}],\"decryption\":\"none\",\"fallbacks\":[]}" \
  "{\"network\":\"tcp\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"tcpSettings\":{\"acceptProxyProtocol\":false,\"header\":{\"type\":\"none\"}}}"

I "${N}-VLESS-WT" $((30000+RANDOM%10000)) vless \
  "{\"clients\":[{\"id\":\"$U\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}],\"decryption\":\"none\",\"fallbacks\":[]}" \
  "{\"network\":\"ws\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"wsSettings\":{\"path\":\"/ws\",\"headers\":{\"Host\":\"max.ru\"}}}"

I "${N}-VLESS-HT" $((30000+RANDOM%10000)) vless \
  "{\"clients\":[{\"id\":\"$U\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}],\"decryption\":\"none\",\"fallbacks\":[]}" \
  "{\"network\":\"httpupgrade\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"httpupgradeSettings\":{\"path\":\"/hu\",\"host\":\"max.ru\"}}"

I "${N}-SS-TCP" $((30000+RANDOM%10000)) shadowsocks \
  "{\"method\":\"aes-256-gcm\",\"password\":\"$U\",\"network\":\"tcp,udp\"}" \
  "{\"network\":\"tcp\",\"security\":\"none\",\"externalProxy\":[],\"tcpSettings\":{\"acceptProxyProtocol\":false,\"header\":{\"type\":\"none\"}}}"

I "${N}-SS-TLS" $((30000+RANDOM%10000)) shadowsocks \
  "{\"method\":\"aes-256-gcm\",\"password\":\"$U\",\"network\":\"tcp,udp\"}" \
  "{\"network\":\"tcp\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"tcpSettings\":{\"acceptProxyProtocol\":false,\"header\":{\"type\":\"none\"}}}"

I "${N}-TRJAN" $((30000+RANDOM%10000)) trojan \
  "{\"clients\":[{\"password\":\"$U\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}],\"fallbacks\":[]}" \
  "{\"network\":\"tcp\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"tcpSettings\":{\"acceptProxyProtocol\":false,\"header\":{\"type\":\"none\"}}}"

I "${N}-VM-TCP" $((30000+RANDOM%10000)) vmess \
  "{\"clients\":[{\"id\":\"$U\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}]}" \
  "{\"network\":\"tcp\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"tcpSettings\":{\"acceptProxyProtocol\":false,\"header\":{\"type\":\"none\"}}}"

I "${N}-VM-WS" $((30000+RANDOM%10000)) vmess \
  "{\"clients\":[{\"id\":\"$U\",\"email\":\"$E1\",\"limitIp\":0,\"totalGB\":$T,\"expiryTime\":$M,\"enable\":true,\"subId\":\"$S\"}]}" \
  "{\"network\":\"ws\",\"security\":\"tls\",\"externalProxy\":[],\"tlsSettings\":{\"serverName\":\"max.ru\"},\"wsSettings\":{\"path\":\"/ws\",\"headers\":{\"Host\":\"max.ru\"}}}"

# Subscription output
SUB="https://$H:$P$W/sub/$S"
F="${N// /_}_sub.txt"
echo -e "#profile-title: $N\n#profile-update-interval: 1\n#subscription-userinfo: upload=0; download=0; total=$T; expire=$E" > "$F"
echo "vless://$U@$H:$((30000+RANDOM%10000))?type=tcp&security=reality&flow=xtls-rprx-vision&pbk=$K&fp=random&sni=max.ru&sid=$H&spx=%2F#${N}-VLESS-TR" >> "$F"
echo "vless://$U@$H:$((30000+RANDOM%10000))?type=grpc&security=reality&pbk=$K&fp=random&sni=max.ru&sid=$H&spx=%2F&serviceName=grpc#${N}-VLESS-GR" >> "$F"
echo "vless://$U@$H:$((30000+RANDOM%10000))?type=tcp&security=tls&sni=max.ru#${N}-VLESS-TT" >> "$F"
echo "vless://$U@$H:$((30000+RANDOM%10000))?type=ws&security=tls&path=%2Fws&host=$H&sni=max.ru#${N}-VLESS-WT" >> "$F"
echo "vless://$U@$H:$((30000+RANDOM%10000))?type=httpupgrade&security=tls&path=%2Fhu&host=max.ru&sni=max.ru#${N}-VLESS-HT" >> "$F"
echo "ss://$(echo -n aes-256-gcm:$U|base64|tr -d '=\n')@$H:$((30000+RANDOM%10000))#${N}-SS-TCP" >> "$F"
echo "ss://$(echo -n aes-256-gcm:$U|base64|tr -d '=\n')@$H:$((30000+RANDOM%10000))#${N}-SS-TLS" >> "$F"
echo "trojan://$U@$H:$((30000+RANDOM%10000))?security=tls&sni=max.ru&type=tcp#${N}-TRJAN" >> "$F"
echo "vmess://$(echo -n '{"v":"2","ps":"'${N}-VM-TCP'","add":"'$H'","port":"'$((30000+RANDOM%10000))'","id":"'$U'","aid":"0","scy":"auto","net":"tcp","type":"none","tls":"tls","sni":"max.ru"}'|base64|tr -d '=\n')" >> "$F"
echo "vmess://$(echo -n '{"v":"2","ps":"'${N}-VM-WS'","add":"'$H'","port":"'$((30000+RANDOM%10000))'","id":"'$U'","aid":"0","scy":"auto","net":"ws","type":"none","tls":"tls","sni":"max.ru"}'|base64|tr -d '=\n')" >> "$F"

M2 "Sub URL: $SUB"
M2 "Saved: $F"
cat "$F"
rm -f "$C"
