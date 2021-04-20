FROM emscripten/emsdk:1.39.8 AS qt_build

RUN mkdir -p /qt_build
WORKDIR /qt_build

RUN git clone --branch=5.15.2 git://code.qt.io/qt/qt5.git
WORKDIR /qt_build/qt5
RUN ./init-repository --module-subset=qtbase,qttools,qtrepotools

WORKDIR /qt_build
RUN wget https://www.openssl.org/source/openssl-1.1.1k.tar.gz
RUN tar xzf openssl-1.1.1k.tar.gz
WORKDIR /qt_build/openssl-1.1.1k
RUN emconfigure ./Configure -no-asm -no-tests --prefix=/qt_build/openssl linux-generic32
RUN sed -i 's|^CROSS_COMPILE.*$|CROSS_COMPILE=|g' Makefile
RUN make -j `grep -c '^processor' /proc/cpuinfo`
RUN make install -j `grep -c '^processor' /proc/cpuinfo`

WORKDIR /qt_build/qt5
RUN OPENSSL_LIBS="-L/qt_build/openssl/lib -lssl -lcrypto"  ./configure -xplatform wasm-emscripten -feature-thread -nomake examples -nomake tests -opensource --confirm-license -openssl-linked -I /qt_build/openssl/include
RUN make -j `grep -c '^processor' /proc/cpuinfo`
RUN make install -j `grep -c '^processor' /proc/cpuinfo`

FROM emscripten/emsdk:1.39.8 AS library_build
COPY --from=qt_build /usr/local/Qt-5.15.2/ /usr/local/Qt-5.15.2/
WORKDIR /library_build
RUN apt update && apt install -y gawk
RUN wget https://web.stanford.edu/class/cs106b/qt/CS106.zip && unzip CS106.zip
WORKDIR /library_build/Library
RUN rm -rf util/sound.h util/sound.cpp personaltypes.py
RUN gawk -i inplace '{gsub("multimedia","");gsub("debughelper","");gsub("personaltypes.py","");print}' Library.pro \
    && sed -i '/^.files/,+7d' Library.pro \
    && sed -i '/^# Use makefile include to set default goal to install target/,+4d' Library.pro \
    && sed -i 's|^SPL_DIR.*$|SPL_DIR = $$(PREFIX)|g' Library.pro

WORKDIR /library_build/build
RUN PREFIX=/opt/libcs106 /usr/local/Qt-5.15.2/bin/qmake /library_build/Library && make -j `grep -c '^processor' /proc/cpuinfo` && make install

FROM emscripten/emsdk:1.39.8 AS user_build
COPY --from=qt_build /usr/local/Qt-5.15.2/ /usr/local/Qt-5.15.2/
COPY --from=qt_build /qt_build/openssl /opt/openssl
COPY --from=library_build /opt/libcs106 /opt/libcs106
RUN apt update && apt install -y gawk
#WORKDIR /project/source
# RUN gawk -i inplace '{gsub("multimedia","");print}' *.pro \
#     && sed -i '/^# Library installed into per-user writable data location/,+3d' *.pro \
#     && sed -i 's|^SPL_DIR.*$|SPL_DIR = /opt/libcs106|g' *.pro

WORKDIR /project/build
CMD /usr/local/Qt-5.15.2/bin/qmake /project/source && make -j `grep -c '^processor' /proc/cpuinfo`