# 屏蔽反诈模块 (Anti-Fraud Block)

Magisk 模块，屏蔽 ColorOS 系统内置反诈相关组件 + 屏蔽国家反诈 App 服务及反诈相关 200+ 反诈 IP。

## 灵感来源
TG 阿灵去广告（特殊版）

## 功能
1. 屏蔽 ColorOS 内置反诈
2. 屏蔽国家反诈 IP
3. 屏蔽手机管家和应用增强服务的上传应用列表行为

## 安装
1. 下载 Release 版本并在 Magisk / KSU / APatch 中作为系统模块刷入
2. 重启设备

## 测试效果

用 su 授权终端或 MT管理器/NP管理器等以 root 权限执行以下脚本，三个 PASS 即为生效。

```sh
#!/system/bin/sh
# 反诈模块测试脚本 v3 (修复APatch su退出码问题)
# 用法: su -c "sh 脚本路径"

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
```

## 免责声明
本模块仅用于中国大陆地区保护个人隐私使用，仅用于学习和交流，切勿用于非法用途。如有问题使用者承担法律责任，法律责任与模块开发者无关。
