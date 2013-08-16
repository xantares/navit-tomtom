#!/bin/sh

# installs tomtom toolchain according instructions from:
# http://wiki.navit-project.org/index.php/TomTom_development

# you'll need some packages:
# - wget
# - gettext
# - libglib2.0-dev for glib-genmarshal
# - automake, autoconf, libtool
# - librsvg2-bin for rsvg-convert
# - gcc-libs-multilib

set -e

export ARCH=arm-linux
cp toolchain-$ARCH.cmake /tmp

# toolchain
export TOMTOM_SDK_DIR=/opt/tomtom-sdk
mkdir -p $TOMTOM_SDK_DIR >/dev/null 2>&1 || export TOMTOM_SDK_DIR=$HOME/tomtom-sdk 
export PREFIX=$TOMTOM_SDK_DIR/gcc-3.3.4_glibc-2.3.2/$ARCH/sys-root
export PATH=$TOMTOM_SDK_DIR/gcc-3.3.4_glibc-2.3.2/bin:$PREFIX/bin/:$PATH
export CFLAGS="-O2 -I$PREFIX/include -I$PREFIX/usr/include"
export CPPFLAGS="-I$PREFIX/include -I$PREFIX/usr/include"
export LDFLAGS="-L$PREFIX/lib -L$PREFIX/usr/lib"
export CC=$ARCH-gcc
export CXX=$ARCH-g++
export LD=$ARCH-ld
export NM="$ARCH-nm -B"
export AR=$ARCH-ar
export RANLIB=$ARCH-ranlib
export STRIP=$ARCH-strip
export OBJCOPY=$ARCH-objcopy
export LN_S="ln -s"
export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
JOBS=`getconf _NPROCESSORS_ONLN`

# toolchain
if ! test -d "$PREFIX"
then
  cd /tmp
  wget -c http://www.tomtom.com/gpl/toolchain_redhat_gcc-3.3.4_glibc-2.3.2-20060131a.tar.gz
  mkdir -p $TOMTOM_SDK_DIR
  tar xzf toolchain_redhat_gcc-3.3.4_glibc-2.3.2-20060131a.tar.gz -C $TOMTOM_SDK_DIR
fi

# zlib
if ! test -f "$PREFIX/include/zlib.h"
then
  cd /tmp
  wget -c http://zlib.net/zlib-1.2.8.tar.gz
  tar xzf zlib-1.2.8.tar.gz
  cd zlib-1.2.8
  ./configure --prefix=$PREFIX
  make -j$JOBS
  make install
fi

# libxml
if ! test -f "$PREFIX/include/libxml2/libxml/parser.h"
then
  cd /tmp/
#   wget -c ftp://xmlsoft.org/libxml2/libxml2-2.9.0.tar.gz
  wget -c http://xmlsoft.org/sources/libxml2-2.7.8.tar.gz
  tar xzf libxml2-2.7.8.tar.gz
  cd libxml2-2.7.8/
  ./configure --prefix=$PREFIX --host=$ARCH --without-python
  make -j$JOBS
  make install
fi

# libpng
if ! test -f "$PREFIX/include/png.h"
then
  cd /tmp/
  wget -c http://prdownloads.sourceforge.net/libpng/libpng-1.2.50.tar.gz
  tar xzf libpng-1.2.50.tar.gz
  cd libpng-1.2.50/
  ./configure --prefix=$PREFIX --host=$ARCH
  make -j$JOBS
  make install
fi
  
# libjpeg
if ! test -f "$PREFIX/include/jpeglib.h"
then
  cd /tmp
  wget -c http://www.ijg.org/files/jpegsrc.v9.tar.gz
  tar xzf jpegsrc.v9.tar.gz
  cd jpeg-9
  ./configure --prefix=$PREFIX --host=$ARCH
  make -j$JOBS
  make install
fi

# freetype
if ! test -f "$PREFIX/include/freetype2/freetype/freetype.h"
then
  cd /tmp
  wget -c http://download.savannah.gnu.org/releases/freetype/freetype-2.5.0.tar.gz
  tar xzf freetype-2.5.0.tar.gz
  cd freetype-2.5.0
  ./configure --prefix=$PREFIX --host=$ARCH
  make -j$JOBS
  make install
fi

# fontconfig
if ! test -f "$PREFIX/include/fontconfig/fontconfig.h"
then
  cd /tmp
#   wget -c http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.10.91.tar.gz
  wget -c http://pkgs.fedoraproject.org/repo/pkgs/fontconfig/fontconfig-2.10.91.tar.bz2/c795bb39fab3a656e5dff8bad6a199f6/fontconfig-2.10.91.tar.bz2
  tar xjf fontconfig-2.10.91.tar.bz2
  cd fontconfig-2.10.91
  ./configure --prefix=$PREFIX --host=$ARCH --with-arch=arm --enable-libxml2
  make -j$JOBS
  make install
fi

# glib
if ! test -f "$PREFIX/include/glib-2.0/glib.h"
then
  cd /tmp
  wget -c http://ftp.gnome.org/pub/gnome/sources/glib/2.25/glib-2.25.17.tar.gz
  tar xzf glib-2.25.17.tar.gz
  cd glib-2.25.17
  cat > tomtom.cache << EOF
glib_cv_long_long_format=ll
glib_cv_stack_grows=no
glib_cv_uscore=no
ac_cv_func_posix_getgrgid_r=yes
ac_cv_func_posix_getpwuid_r=yes
EOF
  chmod a-w tomtom.cache
  ./configure --prefix=$PREFIX --host=$ARCH --cache-file=tomtom.cache
  sed -i "s|cp xgen-gmc gmarshal.c |cp xgen-gmc gmarshal.c \&\& sed -i \"s\|g_value_get_schar\|g_value_get_char\|g\" gmarshal.c |g" gobject/Makefile
  make -j$JOBS
  make install
fi

# tslib
if ! test -f "$PREFIX/include/tslib.h"
then
  cd /tmp
  rm -rf tslib-svn
  git clone https://github.com/playya/tslib-svn.git
  cd tslib-svn
  sed -i "s|AM_CONFIG_HEADER|AC_CONFIG_HEADERS|g" configure.ac
  sed -i "119i\#ifdef EVIOCGRAB" plugins/input-raw.c
  sed -i "124i\#endif" plugins/input-raw.c
  sed -i "290i\#ifdef EVIOCGRAB" plugins/input-raw.c
  sed -i "294i\#endif" plugins/input-raw.c
  sed -i "s|# module_raw input|module_raw input|g" etc/ts.conf # tomtom one
  ./autogen.sh
  ./configure --prefix=$PREFIX --host=$ARCH
  make -j$JOBS
  make install
fi

# sdl
if ! test -f "$PREFIX/include/SDL/SDL.h"
then
  cd /tmp
  wget -c http://www.libsdl.org/release/SDL-1.2.13.tar.gz
  tar xzf SDL-1.2.13.tar.gz
  cd SDL-1.2.13
  wget -c http://tracks.yaina.de/source/sdl-fbcon-notty.patch
  patch -p0 -i sdl-fbcon-notty.patch
  ./configure --prefix=$PREFIX --host=$ARCH \
    --disable-esd --disable-joystick --disable-cdrom --disable-video-x11 \
    --disable-x11-vm --disable-dga --disable-video-x11-dgamouse \
    --disable-video-x11-xv --disable-video-x11-xinerama --disable-video-directfb \
    --enable-video-fbcon --disable-audio CFLAGS="$CFLAGS -DFBCON_NOTTY"
  make -j$JOBS
  make install
fi

# to find sdl-config
export PATH=$PREFIX/bin:$PATH

# sdl image
if ! test -f "$PREFIX/include/SDL/SDL_image.h"
then
  cd /tmp
  wget -c http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.12.tar.gz
  tar xzf SDL_image-1.2.12.tar.gz
  cd SDL_image-1.2.12
  ./configure --prefix=$PREFIX --host=$ARCH
  make -j$JOBS
  make install
fi

# sdl ttf
# if ! test -f "$PREFIX/include/SDL/SDL_ttf.h"
# then
#   cd /tmp
#   wget -c http://www.libsdl.org/projects/SDL_ttf/release/SDL_ttf-2.0.11.tar.gz
#   tar xzf SDL_ttf-2.0.11.tar.gz
#   cd SDL_ttf-2.0.11
#   ./configure --prefix=$PREFIX --host=$ARCH --with-sdl-prefix=$PREFIX
#   make
#   make install
# fi

# navit
if ! test -f "$PREFIX/bin/navit"
then
  cd /tmp
  if ! test -d navit
  then
    svn co https://navit.svn.sourceforge.net/svnroot/navit/trunk/navit navit 
  else
    svn up navit
  fi
  cd navit
  mkdir -p build
  cd build
  sed -i "s|set ( TOMTOM_SDK_DIR /opt/tomtom-sdk )|set ( TOMTOM_SDK_DIR $TOMTOM_SDK_DIR )|g" /tmp/toolchain-$ARCH.cmake
  cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_TOOLCHAIN_FILE=/tmp/toolchain-$ARCH.cmake -DDISABLE_QT=ON
  make -j$JOBS
  make install
fi

# creating directories
OUT_PATH=/tmp/sdcard
rm -rf $OUT_PATH
mkdir -p $OUT_PATH
cd $OUT_PATH
mkdir -p navit SDKRegistry
cd navit
mkdir -p bin lib share sdl ts

# libraries
cp $PREFIX/lib/libfreetype.so.6 lib
cp $PREFIX/lib/libSDL-1.2.so.0 lib
cp $PREFIX/lib/libSDL_image.so.0 lib
cp $PREFIX/lib/libfontconfig.so lib
cp $PREFIX/lib/libgio-2.0.so lib
cp $PREFIX/lib/libglib-2.0.so.0 lib
cp $PREFIX/lib/libgmodule-2.0.so.0 lib
cp $PREFIX/lib/libgobject-2.0.so lib
cp $PREFIX/lib/libgthread-2.0.so lib
cp $PREFIX/lib/libpng12.so.0 lib
cp $PREFIX/lib/libts-1.0.so.0 lib
cp $PREFIX/lib/libts.so lib
cp $PREFIX/lib/libxml2.so lib
cp $PREFIX/lib/librt.so.1 lib
cp $PREFIX/lib/libthread_db.so.1 lib
cp $PREFIX/lib/libz.so.1 lib
cp $PREFIX/etc/ts.conf .

# navit executable and wrapper
cp $PREFIX/bin/navit bin/
cat > bin/navit-wrapper << EOF
#!/bin/sh

cd /mnt/sdcard

# Set some paths.
export PATH=\$PATH:/mnt/sdcard/navit/bin
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/mnt/sdcard/navit/lib
export HOME=/mnt/sdcard/
export NAVIT_PREFIX=/mnt/sdcard/navit
export NAVIT_LIBDIR=\$NAVIT_PREFIX/lib/navit
export NAVIT_SHAREDIR=\$NAVIT_PREFIX/share

# tslib requirements.
export TSLIB_CONSOLEDEVICE=none
export TSLIB_FBDEVICE=/dev/fb
export TSLIB_TSDEVICE=/dev/ts
export TSLIB_CALIBFILE=/mnt/sdcard/navit/ts/pointercal
export TSLIB_CONFFILE=/mnt/sdcard/navit/ts/ts.conf
export TSLIB_PLUGINDIR=/mnt/sdcard/navit/lib/ts

# SDL requirements.
export SDL_MOUSEDRV=TSLIB
export SDL_MOUSEDEV=\$TSLIB_TSDEVICE
export SDL_NOMOUSE=1
export SDL_FBDEV=/dev/fb
export SDL_VIDEODRIVER=fbcon
export SDL_AUDIODRIVER=dsp

# fontconfig requirements
export FC_CONFIG_DIR=/mnt/sdcard/navit/fonts
export FONTCONFIG_DIR=/mnt/sdcard/navit/fonts
export FC_CONFIG_FILE=/mnt/sdcard/navit/fonts/fonts.conf
export FONTCONFIG_FILE=/mnt/sdcard/navit/fonts/fonts.conf
export FC_DEBUG=0

# Set language.
export LANG=en_US.utf8

# Run Navit.
/mnt/sdcard/navit/bin/navit /mnt/sdcard/navit/share/navit.xml 2>/mnt/sdcard/navit/navit.log

EOF
chmod a+rx bin/navit-wrapper

# copy plugins
cp -r $PREFIX/lib/navit $OUT_PATH/navit/lib/

# copy the images 
cd share
cp -r $PREFIX/share/navit/xpm ./
cp $PREFIX/share/navit/navit.xml ./
mkdir -p maps


# add a menu button
cat > $OUT_PATH/SDKRegistry/navit.cap << EOF
Version|100|
AppName|navit-wrapper|
AppPath|/mnt/sdcard/navit/bin/|
AppIconFile|navit.bmp|
AppMainTitle|Navit|
AppPort||
COMMAND|CMD|hallo|navit.bmp|Navit|
EOF
convert $PREFIX/share/icons/hicolor/128x128/apps/navit.png -size 48x48 $OUT_PATH/SDKRegistry/navit.bmp

# get a map!
cp /tmp/osm_france.bin $OUT_PATH/navit/share/maps
sed -i "s|xi:include href=\"\$NAVIT_SHAREDIR/maps/\*.xml\"/|map type=\"binfile\" enabled=\"yes\" data=\"/mnt/sdcard/navit/share/maps/osm_france.bin\" /|g" $OUT_PATH/navit/share/navit.xml

# configure navit
sed -i "s|<debug name=\"segv\" level=\"1\"/>|<debug name=\"segv\" level=\"0\"/>|g" $OUT_PATH/navit/share/navit.xml
sed -i "s|<graphics type=\"gtk_drawing_area\"/>|<graphics type=\"sdl\" w=\"320\" h=\"240\" bpp=\"16\" frame=\"0\" flags=\"1\"/>|g" $OUT_PATH/navit/share/navit.xml
sed -i "s|source=\"gpsd://localhost\" gpsd_query=\"w+xj\"|source=\"file://var/run/gpsfeed\"|g" $OUT_PATH/navit/share/navit.xml

# standalone boot system
wget -c http://prdownloads.sourceforge.net/tomplayer/tomplayer/tomplayer_v0.230/tomplayer_v0.230.zip -P /tmp
unzip -u /tmp/tomplayer_v0.230.zip -d /tmp
cp /tmp/distrib/ttsystem $OUT_PATH
mkdir -p $OUT_PATH/tomplayer
cat > $OUT_PATH/tomplayer/tomplayergui.sh << EOF
#!/bin/sh
/mnt/sdcard/navit/bin/navit-wrapper > /mnt/sdcard/tomplayer/tomplayer.log 2>&1
echo "navit-wrapper rc=\$?" >> /mnt/sdcard/tomplayer/tomplayer.log
echo "[`date`] end" >> /mnt/sdcard/tomplayer/tomplayer.log
EOF
chmod a+rx $OUT_PATH/tomplayer/tomplayergui.sh
