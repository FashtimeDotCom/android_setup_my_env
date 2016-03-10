#!/system/xbin/ash

export PATH="/system/xbin:/sbin:/system/sbin:/system/bin:/data/sh"
export bb="$(which busybox)"

export PS1='\{PWD} \$ '
export HOME="/data/sh"
cd
exec /system/xbin/ash -l
