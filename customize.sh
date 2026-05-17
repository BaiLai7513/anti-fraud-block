#!/system/bin/sh
# 屏蔽反诈 - 精简版
# 安装时立即应用 iptables 规则

echo "- 屏蔽反诈模块安装中..."
echo "- 应用 ColorOS + 国家反诈 iptables 规则"

source $MODPATH/mod/iptables.sh

echo "- 完成！"
