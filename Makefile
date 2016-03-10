
.SUFFIXES: .pad

allinone.sh: header.computed busybox.pad tarbal.tar.xz.pad
	cat header.computed busybox.pad tarbal.tar.xz.pad > allinone.sh

%.pad: %
	bash ./header.template.sh pad4k $< $@

tar_files = Superuser.apk su su2 loginp fsrw fsro start-telnet i etc.tar.xz ash_profile \
    run.sh jackpal.androidterm_preferences.xml

tarbal.tar.xz: $(tar_files)
	tar cJf tarbal.tar.xz $(tar_files)

header.computed: header.template.sh busybox.pad tarbal.tar.xz.pad
	bash ./header.template.sh fill-constant header.template.sh header.computed

clean:
	-rm header.computed tarbal.tar.xz allinone.sh *.pad
