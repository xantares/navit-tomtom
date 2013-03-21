#!/bin/sh

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
  make
  make install
fi

# libxml
if ! test -f "$PREFIX/include/libxml2/libxml/parser.h"
then
  cd /tmp/
  wget -c ftp://xmlsoft.org/libxml2/libxml2-2.9.0.tar.gz
  tar xzf libxml2-2.9.0.tar.gz
  cd libxml2-2.9.0/
  ./configure --prefix=$PREFIX --host=arm-linux --without-python
  make
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
  make
  make install
fi
  
# libjpeg
if ! test -f "$PREFIX/bin/cjpeg"
then
  cd /tmp
  wget -c http://prdownloads.sourceforge.net/libjpeg/jpegsrc.v6b.tar.gz
  tar xzf jpegsrc.v6b.tar.gz
  cd jpeg-6b/
  mkdir -p $PREFIX/man/man1
  ./configure --prefix=$PREFIX --host=arm-linux
  make
  make install
fi


cd /tmp
wget -c http://ftp.gnome.org/pub/gnome/sources/glib/2.35/glib-2.35.9.tar.xz
rm -rf glib-2.35.9
tar xf glib-2.35.9.tar.xz
cd glib-2.35.9
cat > tomtom.cache << EOF
glib_cv_long_long_format=ll
glib_cv_stack_grows=no
glib_cv_uscore=no
ac_cv_func_posix_getgrgid_r=yes
ac_cv_func_posix_getpwuid_r=yes
EOF
chmod a-w tomtom.cache
./configure --prefix=$PREFIX --host=arm-linux --cache-file=tomtom.cache
make
make install
