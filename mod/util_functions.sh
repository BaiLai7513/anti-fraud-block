
id="anti_fraud_260516"
Magisk_mod=$(grep -w -q 'lite_modules' /data/adb/magisk/util_functions.sh 2>/dev/null && echo "lite_modules" || echo "modules")
MODPATH="/data/adb/$Magisk_mod/$id"

export PATH="/system/bin:$MODPATH/busybox:$PATH"


function show_value() {
	local value=$1
	local file="$MODPATH/配置.prop"
	test ! -f "$file" && file="$MODPATH/配置.conf"
	cat "${file}" | grep -E "(^$value=)" | sed '/^#/d;/^[[:space:]]*$/d;s/.*=//g' | sed 's/，/,/g;s/——/-/g;s/：/:/g'
}

#删除并且chattr +i 广告文件
function X_file() {
case $i in
"/data/user/"|"/data/user"|"/data/media/0/Android/data/"|"/data/media/0/Android/data"|"/data/data/"|"/data/data"|"/data"|"/data/"|"/data/media/0"|"/data/media/0/"|"/data/media/0/Downloa"|"/data/media/0/Download/"|"/data/media/0/Android"|"/data/media/0/Android/"|"/sdcard"|"/sdcard/"|"/sdcard/Download"|"/sdcard/Download/"|"/sdcard/Android"|"/sdcard/Android/"|"/storage"|"/storage/"|"/storage/emulated/0"|"/storage/emulated/0/"|"/storage/emulated/0/Download"|"/storage/emulated/0/Download/"|"/storage/emulated/0/Android"|"/storage/emulated/0/Android/"|"/"|"/*")
echo "你他娘的真是个人才！想把系统给格了？™"
exit 1
;;
*)
	if test -e "$1"; then
		rm -rf "$1"
		touch "$1"
		chmod 000 "$1"
		chattr +i "$1"
	fi
;;
esac
}

#恢复chattr +i锁定的文件，并且删除
function RE_file() {
case $i in
"/data/user/"|"/data/user"|"/data/media/0/Android/data/"|"/data/media/0/Android/data"|"/data/data/"|"/data/data"|"/data"|"/data/"|"/data/media/0"|"/data/media/0/"|"/data/media/0/Downloa"|"/data/media/0/Download/"|"/data/media/0/Android"|"/data/media/0/Android/"|"/sdcard"|"/sdcard/"|"/sdcard/Download"|"/sdcard/Download/"|"/sdcard/Android"|"/sdcard/Android/"|"/storage"|"/storage/"|"/storage/emulated/0"|"/storage/emulated/0/"|"/storage/emulated/0/Download"|"/storage/emulated/0/Download/"|"/storage/emulated/0/Android"|"/storage/emulated/0/Android/"|"/"|"/*")
echo "你他娘的真是个人才！想把系统给格了？™"
exit 1
;;
*)
	if test -e "$1"; then
		chattr =A "$1"
		chmod 777 "$1"
		rm -rf "$1"
	fi
;;
esac
}

#删除并且用chmod权限锁定文件，效果比chattr要差
function mkdir_file() {
case $i in
"/data/user/"|"/data/user"|"/data/media/0/Android/data/"|"/data/media/0/Android/data"|"/data/data/"|"/data/data"|"/data"|"/data/"|"/data/media/0"|"/data/media/0/"|"/data/media/0/Downloa"|"/data/media/0/Download/"|"/data/media/0/Android"|"/data/media/0/Android/"|"/sdcard"|"/sdcard/"|"/sdcard/Download"|"/sdcard/Download/"|"/sdcard/Android"|"/sdcard/Android/"|"/storage"|"/storage/"|"/storage/emulated/0"|"/storage/emulated/0/"|"/storage/emulated/0/Download"|"/storage/emulated/0/Download/"|"/storage/emulated/0/Android"|"/storage/emulated/0/Android/"|"/"|"/*")
echo "你他娘的真是个人才！想把系统给格了？™"
exit 1
;;
*)
	if test -e "$1"; then
		chattr =A "$1"
		rm -rf "$1"
		mkdir -p "${1%/*}"
		touch "$1"
		chmod 000 "$1"
	fi
;;
esac
}

#日志记录
function Log_10007_dmesg(){
local log_type="${2}"
local text="${1}"
local time="$(date +'%F %T')"
case "${log_type}" in
W|w|warning|Warning)
	log_type="[W]"
;;
E|e|error|Error)
	log_type="[E]"
;;
I|i|info|Info)
	log_type="[I]"
;;
*)
	log_type="[?]"
;;
esac
test "$text" = "" && return
echo -e "${log_type}${time} ${text}"
echo -e "${log_type}${time} ${text}" >> /dev/kmsg
}
