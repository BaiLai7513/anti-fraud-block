#!/system/bin/sh
# 屏蔽反诈 - 卸载脚本
# 清除 iptables 规则 + 恢复冻结应用

echo "- 清除屏蔽反诈 iptables 规则..."
iptables -F OUTPUT
iptables -t nat -F OUTPUT

echo "- 恢复冻结应用..."
pm enable com.oplus.thirdkit 2>/dev/null

echo "- 完成！"
