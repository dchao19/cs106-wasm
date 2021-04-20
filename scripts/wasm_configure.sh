#!/bin/bash
# ----------------------------
# Daniel Chao
# cs106-wasm/wasm_configure.sh
#
# Use this script to update .pro files from CS106B Qt projects to target WebAssembly
# Usage: ./scripts/wasm_configure path-to-project/project.pro

PROJECT=$1
PROJECT_DIR=$(dirname "$PROJECT")

if [ ! -f "$PROJECT" ]; then
    echo "The project file could not be found."
    exit 0;
fi

if grep -q "Add WebAssembly specific compiler/linker flags" "$PROJECT"; then
    echo "This project file has already been updated."
    exit 0;
fi

gawk -i inplace '{gsub("multimedia","");print}' $PROJECT
sed -i '/^# Library installed into per-user writable data location/,+3d' $PROJECT 
sed -i 's|^SPL_DIR.*$|SPL_DIR = /opt/libcs106|g' $PROJECT
sed -i '/^# set DESTDIR to project root dir/,+2d' $PROJECT 

echo "###############################################################################" >>  $PROJECT
echo "#       Add WebAssembly specific compiler/linker flags                        #" >> $PROJECT
echo "###############################################################################" >> $PROJECT
echo "QMAKE_LFLAGS    +=  -L/opt/openssl/lib --preload-file \$\$PWD/res@res -fexceptions" >> $PROJECT
echo "QMAKE_CXXFLAGS  +=  -fexceptions" >> $PROJECT

if [ ! -d "$PROJECT_DIR/res" ]; then
  mkdir $PROJECT_DIR/res
fi

if [ -d "$PROJECT_DIR/testing" ] && [ -f "$PROJECT_DIR/testing/styles.css" ]; then
    cp $PROJECT_DIR/testing/styles.css $PROJECT_DIR/res/
fi

if [ -f "$PROJECT_DIR/testing/TestingGUI.cpp" ]; then
    sed -i 's/testing\/styles.css/res\/styles.css/' $PROJECT_DIR/testing/TestingGUI.cpp
fi