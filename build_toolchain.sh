#!/bin/sh

# installs tomtom toolchain according instructions from:
# http://wiki.navit-project.org/index.php/TomTom_development

set -e

# toolchain
export PATH=/opt/tomtom-sdk/gcc-3.3.4_glibc-2.3.2/bin:$PATH
export PREFIX=/opt/tomtom-sdk/gcc-3.3.4_glibc-2.3.2/arm-linux/sys-root
export CFLAGS="-O2 -I$PREFIX/include -I$PREFIX/usr/include"
export CPPFLAGS="-I$PREFIX/include -I$PREFIX/usr/include"
export LDFLAGS="-L$PREFIX/lib -L$PREFIX/usr/lib"
export CC=arm-linux-gcc
export CXX=arm-linux-g++
export LD=arm-linux-ld
export NM="arm-linux-nm -B"
export AR=arm-linux-ar
export RANLIB=arm-linux-ranlib
export STRIP=arm-linux-strip
export OBJCOPY=arm-linux-objcopy
export LN_S="ln -s"

# toolchain
if ! test -d "$PREFIX"
then
  cd /tmp
  wget -c http://www.tomtom.com/gpl/toolchain_redhat_gcc-3.3.4_glibc-2.3.2-20060131a.tar.gz
  mkdir -p /opt/tomtom-sdk
  tar xzf toolchain_redhat_gcc-3.3.4_glibc-2.3.2-20060131a.tar.gz -C /opt/tomtom-sdk
fi

# zlib
if ! test -f "$PREFIX/include/zlib.h"
then
  cd /tmp
  wget -c http://zlib.net/zlib-1.2.7.tar.gz
  tar xzf zlib-1.2.7.tar.gz
  cd zlib-1.2.7

  ./configure --prefix=$PREFIX
  make -j4
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
  ./configure --prefix=$PREFIX --host=arm-linux --without-python
  make -j4
  make install
fi

# libpng
if ! test -f "$PREFIX/include/png.h"
then
  cd /tmp/
  wget -c http://prdownloads.sourceforge.net/libpng/libpng-1.2.50.tar.gz
  tar xzf libpng-1.2.50.tar.gz
  cd libpng-1.2.50/
  ./configure --prefix=$PREFIX --host=arm-linux
  make -j4
  make install
fi
  
# libjpeg
if ! test -f "$PREFIX/include/jpeglib.h"
then
  cd /tmp
  wget -c http://www.ijg.org/files/jpegsrc.v9.tar.gz
  tar xzf jpegsrc.v9.tar.gz
  cd jpeg-9
  ./configure --prefix=$PREFIX --host=arm-linux
  make -j4
  make install
fi

# fontconfig
if ! test -f "$PREFIX/include/fontconfig/fontconfig.h"
then
  cd /tmp
  wget -c http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.10.91.tar.gz
  tar xzf fontconfig-2.10.91.tar.gz
  cd fontconfig-2.10.91
  ./configure --prefix=$PREFIX --host=arm-linux --with-arch=arm --enable-libxml2
  make -j4
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
  ./configure --prefix=$PREFIX --host=arm-linux --cache-file=tomtom.cache
  make -j4
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
  ./configure --prefix=$PREFIX --host=arm-linux
  make -j4
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
  ./configure --prefix=$PREFIX --host=arm-linux \
    --disable-esd --disable-joystick --disable-cdrom --disable-video-x11 \
    --disable-x11-vm --disable-dga --disable-video-x11-dgamouse \
    --disable-video-x11-xv --disable-video-x11-xinerama --disable-video-directfb \
    --enable-video-fbcon --disable-audio CFLAGS="$CFLAGS -DFBCON_NOTTY"
  make -j4
  make install
fi

# sdl image
if ! test -f "$PREFIX/include/SDL/SDL_image.h"
then
  cd /tmp
  wget -c http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.12.tar.gz
  tar xzf SDL_image-1.2.12.tar.gz
  cd SDL_image-1.2.12
  PATH="$PATH:$PREFIX/bin" ./configure --prefix=$PREFIX --host=arm-linux
  make
  make install
fi

# navit
cd /tmp
# rm -rf navit
# svn co https://navit.svn.sourceforge.net/svnroot/navit/trunk/navit navit 
cd navit
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX
# ./configure --prefix=$PREFIX --host=arm-linux --disable-graphics-gtk-drawing-area --disable-gui-gtk \
#  --disable-graphics-qt-qpainter --disable-binding-dbus --disable-fribidi --enable-cache-size=16777216
make
make install



