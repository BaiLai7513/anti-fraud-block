#!/system/bin/sh
# 屏蔽反诈 - 开机自启 (增强重试版)
MODDIR=${0%/*}

# ===== 阶段1: 等待系统就绪 =====
# 等待开机完成
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done

# 等待网络就绪 (能 ping 通百度才算)
for i in $(seq 1 12); do
    ping -c 1 -W 3 baidu.com >/dev/null 2>&1 && break
    sleep 5
done

# 等待 iptables/netfilter 就绪 (能成功执行命令才算)
for i in $(seq 1 20); do
    iptables -L OUTPUT -n >/dev/null 2>&1 && break
    sleep 3
done

# 验证 netfilter 可写 (读成功不代表能写 — ColorOS 上两者初始化可能差好几分钟)
for i in $(seq 1 20); do
    iptables -A OUTPUT -d 127.0.0.2 -j DROP 2>/dev/null && \
    iptables -D OUTPUT -d 127.0.0.2 -j DROP 2>/dev/null && break
    sleep 3
done

# ===== 阶段2: 渐进式重试加载 iptables =====
# 间隔: 5 10 15 20 25 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 (阶段2最长~14分钟)
# 阶段1 最长约 4 分钟 (系统+网络+netfilter读+netfilter写)，总计约 18 分钟

retry=0
max_retry=30

while [ $retry -lt $max_retry ]; do
    retry=$((retry + 1))

    # 先检查是否已经达标 (可能被其他脚本加载过)
    count=$(iptables -L OUTPUT -n 2>/dev/null | grep -c DROP)
    if [ "$count" -ge 100 ]; then
        break
    fi

    # 加载规则 (idempotent: 每条规则先 -D 再 -A)
    source $MODDIR/mod/iptables.sh

    # 验证
    count=$(iptables -L OUTPUT -n 2>/dev/null | grep -c DROP)
    if [ "$count" -ge 100 ]; then
        break
    fi

    # 渐进间隔: 前5次递增，之后固定30s
    if [ $retry -le 5 ]; then
        sleep $((retry * 5))
    else
        sleep 30
    fi
done

# ===== 阶段3: KernelSU/Apatch 适配 (后台) =====
test -f $MODDIR/mod/kernel_su.sh && nohup $MODDIR/mod/kernel_su.sh >/dev/null 2>&1 &