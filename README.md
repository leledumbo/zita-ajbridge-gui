# Zita-AJ Bridge GUI #

![icon.png](https://bitbucket.org/repo/M6RLjE/images/2275785820-icon.png)

This is a GUI frontend for [zita-ajbridge](https://kokkinizita.linuxaudio.org/linuxaudio/zita-ajbridge-doc/quickguide.html), both zita-a2j and zita-j2a. The idea is of course to ease calling the program through a convenient user interface.

[Bug reports](https://github.com/leledumbo/zita-ajbridge-gui/issues/new) are welcome but I can't promise that it'll be fixed immediately.

### Runtime Requirements ###

* Linux OS :)
* Zita-AJBridge binaries in PATH
* [libQt4Pas](http://users.telenet.be/Jan.Van.hijfte/qtforfpc/fpcqt4.html) if building with Qt interface

### Build Requirements ###

* Any OS capable to build for Linux
* Lazarus, please try latest stable or trunk
* FPC, please try latest stable or trunk
* fpALSA, please try latest stable or trunk

### How to Build ###

* Open the .lpi
* Set Other unit files and Other sources in Compiler Options to point to correct fpALSA units
* Optionally pick a build mode
* Press compile/build