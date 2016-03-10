
# Usage:
# 1. Install jackpal.androidterm.apk
# 2. Run sh ./run.sh with root permission

# TODO:

bb="/data/sh/busybox"

set_tmp_busybox()
{
	echo 'making busybox working in /data/sh'
	mkdir "/data/sh"
	slice "$bb_start" "$bb_len" > "$bb"
	chown 0 $bb
	chown 0.0 $bb		# toolbox may have different chown syntax
	chown 0:0 $bb
	chmod 4755 $bb		# -rwsr-xr-x
	echo '		Done'
}

mount_rw()
{
	# toolbox's mount must specify device in arguments, so we use busybox mount here
	echo 'mounting /system rw'
	$bb mount -o remount,rw /system
	echo '		Done'
}

mount_ro()
{
	echo 'mounting /system rw'
	$bb mount -o remount,ro /system
	echo '		Done'
}

install_busybox()
{
	# copy busybox to /data/sh temporary so we can use busybox mount
	# /data/sh/busybox will be removed later
	set_tmp_busybox
	mount_rw
	
	echo 'installing busybox to /system/xbin/'
	target_bb=/system/xbin/busybox
	# install -o USER -g GROUP -m MODE SOURCE... DEST
	$bb install -o 0 -g 0 -m 4755 $bb "$target_bb"
	$bb chmod u+s "target_bb"
	rm $bb				# delete old busybox
	bb="$target_bb"		# new busybox
	cd /system/xbin/
	$bb --install -s .
	cd -
	PATH="/system/xbin/:$PATH"		# use installed busybox first
	hash -r		# clear cached command path
	echo '		Done'
}

install_su()
{
	echo 'installing superuser'
	$bb install -o 0 -g 0 -m 4755 su su2 "/system/xbin/"
	$bb chmod u+s "/system/xbin/su" "/system/xbin/su2"		# `install` dont't set s permission
	$bb mv -f "/system/bin/su" "/system/bin/su.bak" 2>/dev/null		# delete other su
	$bb install "Superuser.apk" "/system/app/"
	echo '		Done'
}

set_term_env()
{
	echo 'install scripts'
	$bb install -o 0 -g 0 -m 755 "fsrw" "fsro" "loginp" "start-telnet" "i" "/system/xbin/"
	echo '		Done'

	echo 'install ash shell profile'
	$bb install -o 0 -g 0 -m 640 "ash_profile" "/data/sh/.profile"
	echo '		Done'
	
	echo 'install profile for jackpal.androidterm'
	app_dir="/data/data/jackpal.androidterm"
	app_owner="$($bb ls -dl "$app_dir" | $bb awk '{print $3 ":" $4}')"
	target="$app_dir/shared_prefs/jackpal.androidterm_preferences.xml"
	$bb cp -f "jackpal.androidterm_preferences.xml" "$target"
	$bb chown "$app_owner" "$target"
	$bb chmod 660 "$target"
	echo '		Done'
	
	echo 'setup users and password'
	$bb tar -xf etc.tar.xz -C /etc/
	$bb telnetd -l /system/xbin/loginp
	echo '		Done'
}

main()
{
	if [ "$BB_INSTALLED" != "true" ]; then
		install_busybox
	else
		bb="$(which busybox)"
	fi
	install_su
	set_term_env
	mount_ro
}


main
