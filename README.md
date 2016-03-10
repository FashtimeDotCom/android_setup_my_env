Android 下一键安装 busybox、Superuser、终端模拟器


使用
====
运行`make`，得到`allinone.sh`，在Android上以root运行`allinone.sh`即可。

功能
====
除安装 busybox、Superuser、终端模拟器外，添加了几个命令。

`start-telnet`打开22、2222~2226 号 telnet 端口。

`i`初始化shell环境（设置PATH变量，增加alias等）。
