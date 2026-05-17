#!/system/bin/sh
# 屏蔽反诈 - 开机自启 (诊断增强版)
MODDIR=${0%/*}
LOG="$MODDIR/module.log"

# 初始化日志
echo "=== $(date) service.sh started ===" >> $LOG

# ===== 阶段1: 等待系统就绪 =====
echo "[$(date)] Phase1: waiting for boot_completed" >> $LOG
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done
echo "[$(date)] Phase1: boot_completed OK" >> $LOG

# 等待网络就绪
echo "[$(date)] Phase1: waiting for network" >> $LOG
for i in $(seq 1 12); do
    ping -c 1 -W 3 baidu.com >/dev/null 2>&1 && break
    sleep 5
done
echo "[$(date)] Phase1: network check done (attempt $i)" >> $LOG

# 等待 iptables 读操作就绪
echo "[$(date)] Phase1: waiting for iptables readability" >> $LOG
for i in $(seq 1 20); do
    iptables -L OUTPUT -n >/dev/null 2>&1 && break
    sleep 3
done
echo "[$(date)] Phase1: iptables readable (attempt $i)" >> $LOG

# 等待 iptables 写操作就绪 (关键: 不仅 -L，还要 -A)
echo "[$(date)] Phase1: waiting for iptables write capability" >> $LOG
for i in $(seq 1 30); do
    if iptables -A OUTPUT -d 127.0.0.253 -j DROP 2>>$LOG; then
        iptables -D OUTPUT -d 127.0.0.253 -j DROP 2>>$LOG
        break
    fi
    sleep 3
done
echo "[$(date)] Phase1: iptables writable (attempt $i)" >> $LOG

# ===== 阶段2: 渐进式重试加载 iptables =====
echo "[$(date)] Phase2: starting retry loop (max_retry=30)" >> $LOG

retry=0
max_retry=30

while [ $retry -lt $max_retry ]; do
    retry=$((retry + 1))

    # 先检查是否已经达标
    count=$(iptables -L OUTPUT -n 2>/dev/null | grep -c DROP)
    if [ "$count" -ge 100 ]; then
        echo "[$(date)] Phase2: already loaded ($count DROP), skip" >> $LOG
        break
    fi

    echo "[$(date)] Phase2: retry $retry/$max_retry, DROP=$count, loading..." >> $LOG

    # 加载规则（后台执行，避免 iptables 内核锁阻塞 retry 循环）
    nohup sh $MODDIR/mod/iptables.sh >> $LOG 2>&1 &
    ipt_pid=$!

    # 轮询等待规则加载完成，最多等 25 秒
    wait_sec=0
    while [ $wait_sec -lt 25 ]; do
        sleep 2
        wait_sec=$((wait_sec + 2))
        # 检查进程是否还在跑
        if ! kill -0 $ipt_pid 2>/dev/null; then
            break
        fi
    done

    # 超时则杀掉
    kill -0 $ipt_pid 2>/dev/null && kill $ipt_pid 2>/dev/null

    # 验证
    count=$(iptables -L OUTPUT -n 2>/dev/null | grep -c DROP)
    if [ "$count" -ge 100 ]; then
        echo "[$(date)] Phase2: SUCCESS at retry $retry, DROP=$count" >> $LOG
        break
    fi

    echo "[$(date)] Phase2: retry $retry failed, DROP=$count" >> $LOG

    # 渐进间隔
    if [ $retry -le 5 ]; then
        sleep $((retry * 5))
    else
        sleep 30
    fi
done

# 最终状态
final_count=$(iptables -L OUTPUT -n 2>/dev/null | grep -c DROP)
if [ "$final_count" -ge 100 ]; then
    echo "[$(date)] service.sh: ALL OK, final DROP=$final_count" >> $LOG
else
    echo "[$(date)] service.sh: FAILED after $retry retries, final DROP=$final_count" >> $LOG
fi

# ===== 阶段3: 冻结隐私监控应用 =====
echo "[$(date)] Phase3: disabling surveillance apps" >> $LOG

# 冻结智能应用检测 (com.oplus.thirdkit / App Diagnostics)
# 它是一个以"兼容性诊断"为名的应用列表+设备指纹采集上报程序
pm disable com.oplus.thirdkit 2>>$LOG
echo "[$(date)] Phase3: thirdkit disabled (exit=$?)" >> $LOG

# ===== 阶段4: KernelSU/Apatch 适配 (后台) =====
test -f $MODDIR/mod/kernel_su.sh && nohup $MODDIR/mod/kernel_su.sh >/dev/null 2>&1 &