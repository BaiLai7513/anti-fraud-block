# 屏蔽反诈模块 (Anti-Fraud Block)

Magisk 模块，屏蔽 ColorOS 系统内置反诈相关组件 + 屏蔽国家反诈 App 服务及反诈相关 200+ 反诈 IP。

## 灵感来源
TG 阿灵去广告（特殊版）

## 功能
1. 屏蔽 ColorOS 内置反诈
2. 屏蔽国家反诈 IP
3. 冻结 ColorOS 应用上传和用户行为定义肖像刻画的智能应用检测

## 安装
1. 下载 Release 版本并在 Magisk / KSU / APatch 中作为系统模块刷入
2. 重启设备

## 测试效果

用 su 授权终端或 MT管理器/NP管理器等以 root 权限执行以下脚本：

```sh
#!/system/bin/sh
# ============================================
# 隐私防护检测脚本 — 一键检查所有监控应用状态
# 用法: su -c "sh /sdcard/Download/check_privacy.sh"
# ============================================

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       隐私防护状态检测 v260517          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

PASS=0
FAIL=0
WARN=0

pass()  { PASS=$((PASS+1)); echo "  ✅ $1"; }
fail()  { FAIL=$((FAIL+1)); echo "  ❌ $1"; }
warn()  { WARN=$((WARN+1)); echo "  ⚠️  $1"; }
check() { echo ""; echo "▸ $1"; echo "  ──────────────────────────"; }

# ──────────────────────────────────────
check "1. iptables DROP 规则 (反诈IP封锁)"
count=$(iptables -L OUTPUT -n 2>/dev/null | grep -c DROP)
if [ "$count" -ge 100 ]; then
    pass "DROP 规则: $count 条 (正常)"
else
    fail "DROP 规则: $count 条 (预期 >= 100，模块可能未加载)"
fi

# ──────────────────────────────────────
check "2. iptables 劫持规则 (phonemanager/appdetail)"
dnat_count=$(iptables -t nat -L OUTPUT -n 2>/dev/null | grep -c "8848")
if [ "$dnat_count" -ge 1 ]; then
    pass "劫持规则: $dnat_count 条 -> 127.0.0.1:8848"
else
    fail "劫持规则: 0 条"
fi

# ──────────────────────────────────────
check "3. phonemanager 反诈 (com.coloros.phonemanager)"
uid=$(grep "^com.coloros.phonemanager" /data/system/packages.list 2>/dev/null | awk '{print $2}')
if [ -n "$uid" ]; then
    pass "UID=$uid | 已劫持"
else
    fail "包未安装或未找到 UID"
fi

# ──────────────────────────────────────
check "4. appdetail 应用详情 (com.oplus.appdetail)"
uid=$(grep "^com.oplus.appdetail" /data/system/packages.list 2>/dev/null | awk '{print $2}')
if [ -n "$uid" ]; then
    pass "UID=$uid | 已劫持"
else
    fail "包未安装或未找到 UID"
fi

# ──────────────────────────────────────
check "5. thirdkit 智能应用检测 (com.oplus.thirdkit)"
enabled=$(pm list packages -d 2>/dev/null | grep "com.oplus.thirdkit")
if [ -n "$enabled" ]; then
    pass "已冻结 (pm disable)"
else
    installed=$(pm list packages 2>/dev/null | grep "com.oplus.thirdkit")
    if [ -n "$installed" ]; then
        fail "已安装但未冻结！"
    else
        warn "未安装"
    fi
fi

# ──────────────────────────────────────
check "6. 国家反诈中心 (com.hicorenational.antifraud)"
installed=$(pm list packages 2>/dev/null | grep "com.hicorenational.antifraud")
if [ -n "$installed" ]; then
    uid=$(grep "^com.hicorenational.antifraud" /data/system/packages.list 2>/dev/null | awk '{print $2}')
    if [ -n "$uid" ]; then
        warn "UID=$uid | 规则存在但已安装"
    fi
else
    pass "未安装 ✓"
fi

# ──────────────────────────────────────
check "7. 反诈IP连通性测试 (抽样3个)"
test_ip() {
    ping -c 1 -W 2 "$1" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        fail "$1 可连通 (DROP失效!)"
    else
        pass "$1 不可达 (DROP生效)"
    fi
}
test_ip "49.7.228.53"
test_ip "14.29.101.168"
test_ip "116.177.251.215"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  检测完成: ✅$PASS  ❌$FAIL  ⚠️$WARN            ║"
echo "╚══════════════════════════════════════════╝"
```

## 免责声明
本模块仅用于中国大陆地区保护个人隐私使用，仅用于学习和交流，切勿用于非法用途。如有问题使用者承担法律责任，法律责任与模块开发者无关。
