#!/bin/bash

export SDKROOT=${SDKROOT:-/opt/python-wasm-sdk}
export CONFIG=${CONFIG:-$SDKROOT/config}



. ${CONFIG}

echo "

    * building pygame for ${CIVER}, PYBUILD=$PYBUILD => CPython${PYMAJOR}.${PYMINOR}
            PYBUILD=$PYBUILD
            EMFLAVOUR=$EMFLAVOUR
            SDKROOT=$SDKROOT
            SYS_PYTHON=${SYS_PYTHON}

" 1>&2

sed -i 's|check.warn(importable)|pass|g' ${HOST_PREFIX}/lib/python${PYMAJOR}.${PYMINOR}/site-packages/setuptools/command/build_py.py

if ${CI:-false}
then
    CYTHON_URL=git+https://github.com/pygame-web/cython.git

    CYTHON=${CYTHON:-Cython-3.0.11-py2.py3-none-any.whl}

    # update cython
    TEST_CYTHON=$($HPY -m cython -V 2>&1)
    if echo $TEST_CYTHON| grep -q 3\\.1\\.0a0$
    then
        echo "  * not upgrading cython $TEST_CYTHON
" 1>&2
    else
        echo "  * upgrading cython $TEST_CYTHON to at least 3.0.11
"  1>&2

        if [ ${PYMINOR} -ge 13 ]
        then
           echo "

 ================= forcing Cython git instead of release ${CYTHON}  =================

"
            # /opt/python-wasm-sdk/python3-wasm -m pip install --upgrade --force --no-build-isolation git+${CYTHON_URL}
            NO_CYTHON_COMPILE=true $HPY -m pip install --upgrade --force --no-build-isolation ${CYTHON_URL}
        else
            echo "

 ================= Using Cython release ${CYTHON}  =================

"
            pushd build
                wget -q -c https://github.com/cython/cython/releases/download/3.0.11-1/${CYTHON}
                /opt/python-wasm-sdk/python3-wasm -m pip install --upgrade --force $CYTHON
                $HPY -m pip install --upgrade --force $CYTHON
            popd
        fi

    fi
fi

# PYTHON_GIL=0
# Fatal Python error: config_read_gil: Disabling the GIL is not supported by this build
# Python runtime state: preinitialized

echo "cython ? $( $HPY -m cython -V 2>&1)"


mkdir -p external
pushd $(pwd)/external


echo "
* using main pygame-ce repo
" 1>&2
PG_BRANCH="main"
PG_GIT="https://github.com/pygame-community/pygame-ce.git"

if ${CI:-true}
then
    if [ -d pygame-wasm ]
    then
        pushd $(pwd)/pygame-wasm
        git restore .
        git pull
    else
        git clone --no-tags --depth 1 --single-branch --branch $PG_BRANCH $PG_GIT pygame-wasm
        pushd $(pwd)/pygame-wasm
    fi

    # to upstream after tests
    # done wget -O- https://patch-diff.githubusercontent.com/raw/pmp-p/pygame-ce-wasm/pull/7.diff | patch -p1




    # unsure : wasm pygame.freetype hack
    #wget -O- https://patch-diff.githubusercontent.com/raw/pmp-p/pygame-ce-wasm/pull/3.diff | patch -p1
    wget -O- https://patch-diff.githubusercontent.com/raw/pygame-community/pygame-ce/pull/1967.diff  | patch -p1

    # 313t controller fix merged
    # wget -O- https://patch-diff.githubusercontent.com/raw/pygame-community/pygame-ce/pull/3137.diff | patch -p1

    # new cython (git)
    wget -O- https://patch-diff.githubusercontent.com/raw/pmp-p/pygame-ce-wasm/pull/8.diff | patch -p1

    # fix 3.13 build
    wget -O- https://patch-diff.githubusercontent.com/raw/pmp-p/pygame-ce-wasm/pull/9.diff | patch -p1

    # cython3 / merged
    # wget -O- https://patch-diff.githubusercontent.com/raw/pygame-community/pygame-ce/pull/2395.diff | patch -p1


    # zerodiv mixer.music / merged
    # wget -O- https://patch-diff.githubusercontent.com/raw/pygame-community/pygame-ce/pull/2426.diff | patch -p1


    # remove cython/gil warnings
    patch -p1 <<END
diff --git a/src_c/cython/pygame/_sdl2/audio.pyx b/src_c/cython/pygame/_sdl2/audio.pyx
index c3667d5e3..dfe85fb72 100644
--- a/src_c/cython/pygame/_sdl2/audio.pyx
+++ b/src_c/cython/pygame/_sdl2/audio.pyx
@@ -68,7 +68,7 @@ def get_audio_device_names(iscapture = False):
     return names

 import traceback
-cdef void recording_cb(void* userdata, Uint8* stream, int len) nogil:
+cdef int recording_cb(void* userdata, Uint8* stream, int len) nogil:
     """ This is called in a thread made by SDL.
         So we need the python GIL to do python stuff.
     """
diff --git a/src_c/cython/pygame/_sdl2/mixer.pyx b/src_c/cython/pygame/_sdl2/mixer.pyx
index ebc23b992..c70cebab6 100644
--- a/src_c/cython/pygame/_sdl2/mixer.pyx
+++ b/src_c/cython/pygame/_sdl2/mixer.pyx
@@ -14,7 +14,7 @@ import traceback
 # Mix_SetPostMix(noEffect, NULL);


-cdef void recording_cb(void* userdata, Uint8* stream, int len) nogil:
+cdef int recording_cb(void* userdata, Uint8* stream, int len) nogil:
     """ This is called in a thread made by SDL.
         So we need the python GIL to do python stuff.
     """
END


    patch -p1 <<END
diff --git a/src_c/key.c b/src_c/key.c
index 3a2435d2..a353c24f 100644
--- a/src_c/key.c
+++ b/src_c/key.c
@@ -150,8 +150,10 @@ static PyTypeObject pgScancodeWrapper_Type = {
     PyVarObject_HEAD_INIT(NULL, 0).tp_name = "pygame.key.ScancodeWrapper",
     .tp_repr = (reprfunc)pg_scancodewrapper_repr,
     .tp_as_mapping = &pg_scancodewrapper_mapping,
+/*
     .tp_iter = (getiterfunc)pg_iter_raise,
     .tp_iternext = (iternextfunc)pg_iter_raise,
+*/
 #ifdef PYPY_VERSION
     .tp_new = pg_scancodewrapper_new,
 #endif
END


    # weird exception not raised correctly in test/pixelcopy_test
    patch -p1 <<END
diff --git a/src_c/pixelcopy.c b/src_c/pixelcopy.c
index e33eae33..f5f6697e 100644
--- a/src_c/pixelcopy.c
+++ b/src_c/pixelcopy.c
@@ -485,6 +485,7 @@ array_to_surface(PyObject *self, PyObject *arg)
     }

     if (_validate_view_format(view_p->format)) {
+PyErr_SetString(PyExc_ValueError, "Unsupported array item type");
         return 0;
     }

END

    if echo $PYBUILD|grep -q 3.13$
    then
        echo "


============================================
    Forcing cython regen for 3.13+
============================================


"
        rm src_c/_sdl2/sdl2.c src_c/_sdl2/audio.c src_c/_sdl2/mixer.c src_c/_sdl2/controller_old.c src_c/_sdl2/video.c src_c/pypm.c
    fi

else
    pushd $(pwd)/pygame-wasm
    echo "






                NOT UPDATING PYGAME, TEST MODE






"
    read

fi

# test patches go here
# ===================
# patch -p1 <<END

# END
    rm -rf build Setup
# ===================


if ${CI:-false}
then
    touch $(find | grep pxd$)
    if $HPY setup.py cython_only
    then
        echo -n
    else
        echo "cythonize failed" 1>&2
        exit 208
    fi
else
    echo "skipping cython regen"
touch $(find | grep pxd$)
$HPY setup.py cython_only

fi

#$HPY ${WORKSPACE}/src/replacer.py --go "Py_GIL_DISABLED'\): raise ImportError" "Py_GIL_DISABLED'): print(__name__)"

# do not link -lSDL2 some emmc versions will think .so will use EM_ASM
#SDL_IMAGE="-s USE_SDL=2 -lfreetype -lwebp"
SDL_IMAGE="-lSDL2 -lfreetype -lwebp"

export CFLAGS="-DBUILD_STATIC -DSDL_NO_COMPAT $SDL_IMAGE"
EMCC_CFLAGS="-I${SDKROOT}/emsdk/upstream/emscripten/cache/sysroot/include/freetype2"
EMCC_CFLAGS="$EMCC_CFLAGS -I$PREFIX/include/SDL2"
EMCC_CFLAGS="$EMCC_CFLAGS -Wno-unused-command-line-argument"
EMCC_CFLAGS="$EMCC_CFLAGS -Wno-unreachable-code-fallthrough"
EMCC_CFLAGS="$EMCC_CFLAGS -Wno-unreachable-code"
EMCC_CFLAGS="$EMCC_CFLAGS -Wno-parentheses-equality"
EMCC_CFLAGS="$EMCC_CFLAGS -Wno-unknown-pragmas"


# FIXME 3.13
EMCC_CFLAGS="$EMCC_CFLAGS -Wno-deprecated-declarations"



export EMCC_CFLAGS="$EMCC_CFLAGS -DHAVE_STDARG_PROTOTYPES -ferror-limit=1 -fpic -DBUILD_STATIC"
export COPTS="-O2 -g3 -DBUILD_STATIC"
export CC=emcc

# remove SDL1 for good
rm -rf /opt/python-wasm-sdk/emsdk/upstream/emscripten/cache/sysroot/include/SDL

[ -d build ] && rm -r build
[ -f Setup ] && rm Setup
[ -f ${SDKROOT}/prebuilt/emsdk/libpygame${PYBUILD}.a ] && rm ${SDKROOT}/prebuilt/emsdk/libpygame${PYBUILD}.a

if $SDKROOT/python3-wasm setup.py -config -auto -sdl2
then
    $SDKROOT/python3-wasm setup.py build -j1 || echo "encountered some build errors" 1>&2

    OBJS=$(find build/temp.wasm32-*/|grep o$)


    $SDKROOT/emsdk/upstream/emscripten/emar rcs ${SDKROOT}/prebuilt/emsdk/libpygame${PYBUILD}.a $OBJS
    for obj in $OBJS
    do
        echo $obj
    done

    # to install python part (unpatched)
    cp -r src_py/. ${PKGDIR:-${SDKROOT}/prebuilt/emsdk/${PYBUILD}/site-packages/pygame/}

    # prepare testsuite
    [ -d ${ROOT}/build/pygame-test ] && rm -fr ${ROOT}/build/pygame-test
    mkdir ${ROOT}/build/pygame-test
    cp -r test ${ROOT}/build/pygame-test/test
    cp -r examples ${ROOT}/build/pygame-test/test/
    cp ${ROOT}/packages.d/pygame/tests/main.py ${ROOT}/build/pygame-test/

else
    echo "ERROR: pygame configuration failed" 1>&2
    exit 109
fi

popd
popd

TAG=${PYMAJOR}${PYMINOR}


echo "FIXME: build wheel"

SDL2="-sUSE_ZLIB=1 -sUSE_BZIP2=1 -sUSE_LIBPNG"
SDL2="$SDL2 -sUSE_FREETYPE -sUSE_SDL=2 -sUSE_SDL_MIXER=2 -lSDL2 -L/opt/python-wasm-sdk/devices/emsdk/usr/lib"

if echo $EMFLAVOUR|grep -q ^4
then
    SDL2="$SDL2 -lSDL2_image -lSDL2_gfx -lSDL2_mixer -lSDL2_mixer-ogg -lSDL2_ttf"
else
    SDL2="$SDL2 -lSDL2_image -lSDL2_gfx -lSDL2_mixer -lSDL2_mixer_ogg -lSDL2_ttf"
fi

SDL2="$SDL2 -lvorbis -logg -lwebp -lwebpdemux -ljpeg -lpng -lharfbuzz -lfreetype"
SDL2="$SDL2 -lssl -lcrypto -lffi -lbz2 -lz -ldl -lm"


TARGET_FOLDER=$(pwd)/testing/pygame_static-1.0-cp${TAG}-cp${TAG}-wasm32_${WASM_FLAVOUR}_emscripten

if [ -d ${TARGET_FOLDER} ]
then

    TARGET_FILE=${TARGET_FOLDER}/pygame_static.cpython-${TAG}-wasm32-emscripten.so

    . ${SDKROOT}/emsdk/emsdk_env.sh

    [ -f ${TARGET_FILE} ] && rm ${TARGET_FILE} ${TARGET_FILE}.map

    COPTS="-O2 -g3" emcc -shared -fpic -o ${TARGET_FILE} $SDKROOT/prebuilt/emsdk/libpygame${PYMAJOR}.${PYMINOR}.a $SDL2

    # github CI does not build wheel for now.
    echo ${WHEEL_DIR}
    if [ -d ${WHEEL_DIR} ]
    then
        mkdir -p $TARGET_FOLDER
        /bin/cp -rf testing/pygame_static-1.0-cp${TAG}-cp${TAG}-wasm32_mvp_emscripten/. ${TARGET_FOLDER}/

        if pushd testing/pygame_static-1.0-cp${TAG}-cp${TAG}-wasm32_${WASM_FLAVOUR}_emscripten
        then
            rm ${TARGET_FILE}.map
            WHEEL_PATH=${WHEEL_DIR}/$(basename $(pwd)).whl
            [ -f $WHEEL_PATH ] && rm $WHEEL_PATH
            zip $WHEEL_PATH -r .
            rm ${TARGET_FILE}
            popd
        fi
    else
        echo " =========== no wheel build from ${TARGET_FOLDER} ==========="
    fi

fi




