#!/bin/bash

# ==========================================
# Initial Settings
# ==========================================
APPDIR="Firestorm.AppDir"
# Replace with the exact name of the extracted Firestorm folder
SOURCE_DIR="Phoenix-Firestorm-Releasex64_AVX2-7-2-3-80036"
TEMP_DEBS="temp_debs"
OUTPUT_NAME="Firestorm_Viewer_Online_Build.AppImage"

# Destination folders inside the AppImage
LIB64="$APPDIR/usr/lib/x86_64-linux-gnu"
LIB32="$APPDIR/usr/lib/i386-linux-gnu"

echo "--- 1. Preparing Environment ---"
rm -rf $APPDIR $TEMP_DEBS
mkdir -p $APPDIR/usr/bin $LIB64/gtk-2.0/2.10.0/engines $LIB32 $TEMP_DEBS
mkdir -p $APPDIR/usr/share/themes/Default/gtk-2.0

echo "--- 2. Integrating Firestorm Binaries ---"
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Folder '$SOURCE_DIR' was not found in the root directory."
    exit 1
fi
cp -r $SOURCE_DIR/* $APPDIR/usr/bin/

echo "--- 3. Download: GTK2 Engines (Visual Isolation) ---"
cd $TEMP_DEBS
# Fetching stable packages directly from Debian mirrors
wget -qnc http://ftp.us.debian.org/debian/pool/main/g/gtk2-engines-murrine/gtk2-engines-murrine_0.98.2-4+b1_amd64.deb
wget -qnc http://ftp.us.debian.org/debian/pool/main/g/gtk2-engines-pixbuf/gtk2-engines-pixbuf_2.24.33-2+b1_amd64.deb

for deb in *.deb; do
    [ -f "$deb" ] && dpkg-deb -x "$deb" .
done
# Injecting engines into the AppImage
find . -name "*.so" -path "*/engines/*" -exec cp {} ../$LIB64/gtk-2.0/2.10.0/engines/ \; 2>/dev/null
cd ..

echo "--- 4. Download: System Dependencies and SLVoice (32-bit and 64-bit) ---"
cd $TEMP_DEBS

# THE REAL libidn11 (Brought from Debian Buster/Bullseye via archive) for full Voice stability
wget -qnc http://archive.debian.org/debian/pool/main/libi/libidn/libidn11_1.33-2.2_i386.deb
# Other 32-bit dependencies for Voice
wget -qnc http://ftp.us.debian.org/debian/pool/main/g/gcc-12/libstdc++6_12.2.0-14_i386.deb
wget -qnc http://ftp.us.debian.org/debian/pool/main/u/util-linux/libuuid1_2.38.1-5+b1_i386.deb

# Extra 64-bit dependencies that Firestorm usually requires on Linux
wget -qnc http://ftp.us.debian.org/debian/pool/main/a/apr/libapr1_1.7.2-3_amd64.deb
wget -qnc http://ftp.us.debian.org/debian/pool/main/a/apr-util/libaprutil1_1.6.3-1_amd64.deb

for deb in *.deb; do
    [ -f "$deb" ] && dpkg-deb -x "$deb" .
done

# Distributing 32-bit (Voice) and 64-bit (System) libraries to their proper locations
find . -name "*.so*" -path "*/i386-linux-gnu/*" -exec cp -P {} ../$LIB32/ \; 2>/dev/null
find . -name "*.so*" -path "*/x86_64-linux-gnu/*" -exec cp -P {} ../$LIB64/ \; 2>/dev/null
cd ..

echo "--- 5. Configuring AppRun (The Package Brain) ---"
cat << 'EOF' > $APPDIR/AppRun
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LC_ALL=C.UTF-8

# Prioritize bundled libraries
export LD_LIBRARY_PATH="$HERE/usr/lib/x86_64-linux-gnu:$HERE/usr/lib/i386-linux-gnu:$HERE/usr/bin/lib:$HERE/usr/bin/bin:$LD_LIBRARY_PATH"

# GTK2 engine activation
export GTK_PATH="$HERE/usr/lib/x86_64-linux-gnu/gtk-2.0"
export GTK2_RC_FILES="$HERE/usr/share/themes/Default/gtk-2.0/gtkrc"

# Processing and Video Optimizations (AMD)
export mesa_glthread=true
export __GL_THREADED_OPTIMIZATIONS=1

# RAM management focused on high mesh and texture density
if [ -f "/usr/lib/x86_64-linux-gnu/libjemalloc.so.2" ]; then
    export LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libjemalloc.so.2:$LD_PRELOAD"
fi

# Critical Firestorm override for compatibility and stability on modern Linux
export GDK_BACKEND=x11
export SDL_VIDEODRIVER=x11
export LL_GL_NOEXT=1
unset GTK_MODULES
unset GTK3_MODULES

# Start
cd "$HERE/usr/bin"
exec "./firestorm" "$@"
EOF
chmod +x $APPDIR/AppRun

echo "--- 6. Injected Library Report (Online Build) ---"
echo "--------------------------------------------------"
find $APPDIR/usr/lib -type f -name "*.so*" | sed "s|$APPDIR/||g" | sort
TOTAL_LIBS=$(find $APPDIR/usr/lib -type f -name "*.so*" | wc -l)
echo "--------------------------------------------------"
echo "Total pure encapsulated libraries: $TOTAL_LIBS"
echo "--------------------------------------------------"
sleep 3

echo "--- 7. Finalizing Packaging ---"
cat << 'EOF' > $APPDIR/firestorm.desktop
[Desktop Entry]
Name=Firestorm Viewer
Exec=AppRun
Icon=firestorm
Type=Application
Categories=Game;
EOF

# Ensures the existence of the main icon
cp $APPDIR/usr/bin/firestorm_icon.png $APPDIR/firestorm.png 2>/dev/null || touch $APPDIR/firestorm.png

export ARCH=x86_64
if [ -x "./appimagetool-x86_64.AppImage" ]; then
    ./appimagetool-x86_64.AppImage $APPDIR $OUTPUT_NAME
else
    echo "Warning: appimagetool not found or lacks execution permissions. AppDir is ready at $APPDIR."
fi
rm -rf $TEMP_DEBS

echo "--- Process Completed ---"
