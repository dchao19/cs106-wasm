# cs106-wasm
## What is this?
I work as an undergraduate section leader for the CS198 program at Stanford. The CS198 program staffs the two introductory computer science courses at Stanford, CS106A and CS106B, the latter of which is taught in C++ and uses Qt to display a project GUI for students. 

As the class transitioned online, we started using online collaborative tools like Ed Workspaces as a sort of live coding environment. One thing that's never been great about these sorts of online environments, however, is that they have never supported running graphical Qt programs in any meaningful way. 

I recently discovered Qt projects can be built to target WebAssembly to run in the browser. This project is the result of a weekend's worth of work attempting to compile both the Stanford CS106 C++ library and a CS106B assignment to run graphically in the browser using WebAssembly. 

## Demo
Demos are available at [https://cs106-wasm.projects.danielchao.me](https://cs106-wasm.projects.danielchao.me).

## Project Overview
This project consists of a few parts. There's a Dockerfile at `docker/Dockerfile` that, when built, compiles OpenSSL, Qt, and the Stanford C++ libraries, then prepares to build a student project. Once built, the container can be reused to build student programs that target WebAssembly. This container is huge (I'm not very good at optimizing Dockerfiles) and takes a very long time to build (30-40 minutes). The docker image is published so you don't have to build it yourself; see INSERTLINKHERE.

There are also some scripts in the `scripts/` directory. One is a WIP script at `scripts/wasm_configure.sh` that automates the project configuration changes necessary to adapt a starter `.pro` file for WebAssembly. The other two  (`scripts/run_example.sh` and `scripts/run_simpletest.sh`) are convenience scripts to build and run two sample projects, detailed below.

Finally, there's two example projects. 
 - `examples/welcome` contains the "CS106 Welcome" project available as part of the Stanford library that tests to make sure the library is installed and working properly
 - `examples/simpletest` contains a starter "SimpleTest" project is the foundation for most 106B assignments. There's a few silly tests to demonstrate that everything works properly with the framework. 

## The Docker Container
The building container is laid out in three phases (it should be four, working on it). Here is the general shape of the build phases:
### Phase 1: Qt and OpenSSL
1. Version 5.15.2 of Open Source QT is cloned and the repository is initalized with Qt's own `init-repository` script. Only the "essentials" are cloned - technically only the `QtBase` module is strictly necessary.
2. Version 1.1.1k of OpenSSL is cloned.
    * The Stanford C++ library uses the `QtTextBrowser` widget more than you'd like. It turns out that the `QtTextBrowser` requires QT to be built in the presence of an OpenSSL library. This isn't usually a problem when Qt can dynamically link at runtime to OpenSSL, but all WebAssembly Qt projects (and Qt itself) must be statically linked. Also, WebAssembly / Emscripten currently doesn't maintain an upstream version of OpenSSL targeted explicitly for WebAssembly, and no official binaries are available. This means it's up to us to cross compile. 
3. OpenSSL is configured with `emconfigure` and some modifications are made directly to the Makefile to make everything work
    * `emconfigure` hijacks the creation of the `Makefile` that a configuration script usually produces to redirect the compilation process to Emscripten's own `em++` and `emcc` - however, OpenSSL has some cross configuration support built in (there's just no WebAssembly target), and using both causes some conflicts that we have to edit out with a few `sed` commands. 
4.  Qt is configured and built. 
    * Qt has a built-in WebAssembly target, so we don't need to use `emconfigure`. We do, however, need some additional options:
        - `OPENSSL_LIBS="-L/qt_build/openssl/lib -lssl -lcrypto"` tells Qt where to find our compiled version of OpenSSL
        - `-xplatform wasm-emscripten` tells Qt to target WebAssembly via emscripten
        - `-feature-thread` enabled pthreads inside WebAssembly via Web Workers
        - `-nomake examples -nomake tests` tells Qt not to build examples or tests because we won't be needing them 
        - `-opensource --confirm-license` accepts the conditions of the Qt Open Source license
        - `-openssl-linked -I /qt_build/openssl/include` tells Qt that we need to link OpenSSL statically and tells Make where to find the include files to do this
        