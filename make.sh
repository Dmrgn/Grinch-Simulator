#!/bin/sh
# build for web using emscripten
EMSDK=/usr/local/lib/emsdk
zig build -Drelease-small -Dtarget=wasm32-wasi --sysroot "$EMSDK/upstream/emscripten"