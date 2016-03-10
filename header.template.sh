#!/system/bin/sh

# require: dd chmod chown rm

# TODO: ensure()
# TODO: require root
# TODO: /etc/install-recovery.sh

self="$0"

block=4096

bb_start=XXXXXXXXXX
bb_count=XXXXXXXXXX
bb="/data/sh/busybox"

tarbal_start=XXXXXXXXXX
tarbal_count=XXXXXXXXXX

slice()
{
	start="$1"
	count="$2"
	dd if="$self" bs="$block" skip="$start" count="$count"
}

slice_test()
{
	slice $bb_start $bb_count >bb
	slice $tarbal_start $tarbal_count >tarbal
}

set_tmp_busybox()
{
	echo 'making busybox working in /data/sh'
	mkdir "/data/sh"
	slice "$bb_start" "$bb_count" > "$bb"
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
	rm $bb				# delete old busybox
	bb="$target_bb"		# new busybox
	cd /system/xbin/
	$bb --install -s .
	cd -
	PATH="/system/xbin/:$PATH"		# use installed busybox first
	hash -r		# clear cached command path
	echo '		Done'
}

extract_tarbal()
{
	echo 'extract tarbal to /data/sh/tmp/'
	tmpdir="/data/sh/tmp"
	$bb mkdir -p "$tmpdir"
	slice "$tarbal_start" "$tarbal_count" |$bb tar xJf - -C "$tmpdir"
	echo '		Done'
}

file_len()
{
	echo "$(wc -c < "$1")"
}

fill_constant()
{
	in_file="$1"
	out_file="$2"
	
	
	in_len="$(file_len "$in_file")"
	bb_len="$(file_len "./busybox.pad")"
	tarbal_len="$(file_len "./tarbal.tar.xz.pad")"
	
	out_len="$(expr '(' "$in_len" / "$block" + 1 ')' '*' "$block" )"
	
	bb_count="$(expr "$bb_len" / "$block")"
	tarbal_count="$(expr "$tarbal_len" / "$block")"
	
	bb_start="$(expr "$out_len" / "$block")"
	tarbal_start="$(expr "$bb_start" + "$bb_len" / "$block" )"
	sed -r "s/^bb_start=XXX.*/bb_start=${bb_start}/;				s/^bb_count=XXX.*/bb_count=${bb_count}/; \
			s/^tarbal_start=XXX.*/tarbal_start=${tarbal_start}/;	s/^tarbal_count=XXX.*/tarbal_count=${tarbal_count}/" < "$in_file" > "$out_file"
	out1_len="$(file_len "$out_file")"
	pad="$(expr "$out_len" - "$out1_len" )"
	head -c "$pad" "/dev/full" >> "$out_file"
}

pad4k()
{
	file="$1"
	out="$2"
	file_len="$(file_len "$file")"
	file_len_pad="$(expr '(' "$(wc -c < "$file")" / "$block" + 1 ')' '*' "$block")"
	pad="$(expr "$file_len_pad" - "$file_len")"
	cp "$file" "$out"
	head -c "$pad" "/dev/full" >> "$out"
}


main()
{
	install_busybox
	extract_tarbal
	echo 'run main script'
	cd "/data/sh/tmp/"
	BB_INSTALLED=true $bb ash run.sh
	echo '		Done'
	
	echo 'clean temporary directory'
	$bb rm -rf "/data/sh/tmp/"
	echo '		Done'
}

if [ x"$1" == x"fill-constant" ]; then
	fill_constant "$2" "$3"
	exit $?
elif [ x"$1" == x"pad4k" ]; then
	pad4k "$2" "$3"
elif [ x"$1" == x"test" ]; then
	slice_test
	exit
else
	main
	exit $?
fi

