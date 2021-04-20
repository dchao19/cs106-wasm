#!/bin/bash
# ----------------------------
# Daniel Chao
# cs106-wasm/wasm_configure.sh
#
# Use this script to run the simpletest project in the examples directory
# This script should be run from the root cs106-wasm directory
#
# Usage: ./scripts/run_simpletest.sh [--clean]

SHOULD_CLEAN=${1:-false}
PROJECT_DIR=$PWD/examples/simpletest
BUILD_DIR=$PWD/build/simpletest

if [ "$SHOULD_CLEAN" = true ] ; then
    echo "Removing the build directory before building..."
    rm -rf $BUILD_DIR
fi

echo "Building the project..."
docker run --rm -v $PROJECT_DIR:/project/source -v $BUILD_DIR:/project/build danielchao/cs106-wasm:latest

echo "Build successful."
echo "Starting the server. The project will be available at localhost:8000/simpletest.html. Press Ctrl+C to exit."
docker run --rm -p 8000:80 -v $BUILD_DIR:/usr/share/caddy caddy:latest



