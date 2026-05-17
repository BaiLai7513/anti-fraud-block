#!/system/bin/sh
# 屏蔽反诈 - 卸载脚本
# 清除 iptables 规则

echo "- 清除屏蔽反诈 iptables 规则..."

iptables -F OUTPUT
iptables -t nat -F OUTPUT

echo "- 完成！"
