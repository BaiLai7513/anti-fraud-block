#!/system/bin/sh
# 反诈模块测试脚本 v3 (修复APatch su退出码问题)
# 用法: su -c "sh /storage/emulated/0/Download/test_anti_fraud.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass=0
fail=0
total=3

echo "====== 反诈模块测试 v3 ======"
echo ""

# ===== [1/3] REDIRECT 重定向 =====
echo -n "[1/3] REDIRECT重定向: 反诈流量→127.0.0.1:8848 ... "

iptables -t nat -Z OUTPUT 2>/dev/null

# APatch su 不传递子进程退出码，改用输出判断
curl_out=$(su 10137 -c "/system/bin/curl -4 -s -S --connect-timeout 3 http://connectivitycheck.gstatic.com/generate_204" 2>&1)

pkt=$(iptables -t nat -L OUTPUT -n -v 2>/dev/null | grep "UID match 10137" | awk '{print $1}')

if [ "$pkt" -gt 0 ] && echo "$curl_out" | grep -qE "refused|Failed to connect|timed out|Couldn.t connect"; then
    echo "${GREEN}PASS${NC} REDIRECT生效(计数=${pkt}, 连接被拒绝)"
    pass=$((pass + 1))
elif [ "$pkt" -gt 0 ]; then
    echo "${RED}FAIL${NC} 规则匹配但未拦截(计数=${pkt}) — curl输出: ${curl_out}"
    fail=$((fail + 1))
else
    echo "${RED}FAIL${NC} 计数=${pkt:-0}, 输出: ${curl_out}"
    fail=$((fail + 1))
fi

# ===== [2/3] IP DROP =====
echo -n "[2/3] IP DROP: ping 被屏蔽IP 49.7.228.53 ... "

ping -c 1 -W 2 49.7.228.53 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "${GREEN}PASS${NC} 内核级DROP ✓"
    pass=$((pass + 1))
else
    echo "${RED}FAIL${NC} ping通了"
    fail=$((fail + 1))
fi

# ===== [3/3] 规则完整性 =====
echo -n "[3/3] 规则完整性: DROP规则总数 ... "

count=$(iptables -L OUTPUT -n 2>/dev/null | grep -c DROP)
if [ "$count" -ge 200 ]; then
    echo "${GREEN}PASS${NC} DROP规则 ${count} 条 ✓"
    pass=$((pass + 1))
elif [ "$count" -gt 0 ]; then
    echo "${RED}FAIL${NC} DROP规则仅 ${count} 条 (预期≥200)"
    fail=$((fail + 1))
else
    echo "${RED}FAIL${NC} DROP规则 0 条 — 模块未加载"
    fail=$((fail + 1))
fi

echo ""
echo "====== ${GREEN}${pass} PASS${NC} / ${RED}${fail} FAIL${NC} / ${total} ======"
