macro (SetCompilerOptions)

  #cmake has some strange defaults, this should help us a lot
  #Please use them everywhere
  #WINDOWS   =   Windows Desktop
  #WINRT     =   Windows RT
  #WP8       =   Windows Phone 8
  #ANDROID    =  Android
  #IOS    =  iOS
  #MACOSX    =  MacOS X
  #LINUX      =   Linux
  if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    if(WINRT)
      set(SYSTEM_STRING "Windows RT")
    elseif(WP8)
      set(SYSTEM_STRING "Windows Phone 8")
    else()
      set(WINDOWS TRUE)
      set(SYSTEM_STRING "Windows Desktop")
    endif()
  elseif (${CMAKE_SYSTEM_NAME} MATCHES "Android")
    set(SYSTEM_STRING "Android")
  elseif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    if(ANDROID)
      set(SYSTEM_STRING "Android")
    else()
      set(LINUX TRUE)
      set(SYSTEM_STRING "Linux")
    endif()
  elseif (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    if(IOS)
      set(APPLE TRUE)
      set(SYSTEM_STRING "IOS")
    else()
      set(APPLE TRUE)
      set(MACOSX TRUE)
      set(SYSTEM_STRING "Mac OSX")
    endif()
  endif()

  if(CMAKE_GENERATOR STREQUAL Xcode)
      set (XCODE TRUE)
  elseif(CMAKE_GENERATOR MATCHES Visual)
      set (VS TRUE)
  endif()
  #Debug is default value
  if(NOT CMAKE_BUILD_TYPE)
    if(DEBUG_MODE)
        set(CMAKE_BUILD_TYPE Debug)
    else()
        set(CMAKE_BUILD_TYPE Release)
    endif()
  endif()
  # make configurations type keep same to cmake build type. prevent use generate debug project but switch release mode in IDE
  if(CMAKE_GENERATOR)
    set(CMAKE_CONFIGURATION_TYPES "${CMAKE_BUILD_TYPE}" CACHE STRING "Reset the configurations to what we need" FORCE)
  endif()
  message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")

  # architecture
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
      set(ARCH_DIR "64-bit")
  elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
      set(ARCH_DIR "32-bit")
  else()
      message(WARN "CMAKE_SIZEOF_VOID_P: ${CMAKE_SIZEOF_VOID_P}")
  endif()

  if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(COMPILER_STRING ${CMAKE_CXX_COMPILER_ID})
    set(CLANG TRUE)
  elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    if(MINGW)
      set(COMPILER_STRING "Mingw GCC")
    else()
      set(COMPILER_STRING "GCC")
    endif()
  elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
    set(COMPILER_STRING "${CMAKE_CXX_COMPILER_ID} C++")
  elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    set(COMPILER_STRING "Visual Studio C++")
  endif()

  if(CMAKE_CROSSCOMPILING)
    set(BUILDING_STRING "It appears you are cross compiling for ${SYSTEM_STRING} with ${COMPILER_STRING}")
  else()
    set(BUILDING_STRING "It appears you are building natively for ${SYSTEM_STRING} with ${COMPILER_STRING}")
  endif()

  message(STATUS ${BUILDING_STRING})

  set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DCOCOS2D_DEBUG=1")
  set(CMAKE_CXX_FLAGS_DEBUG ${CMAKE_C_FLAGS_DEBUG})

    # definitions for chipmunk
  if (USE_CHIPMUNK)
    add_definitions(-DCC_ENABLE_CHIPMUNK_INTEGRATION=1)
    if (IOS OR MACOSX)
      # without this chipmunk will try to use apple defined geometry types, that conflicts with cocos
            add_definitions(-DCP_USE_CGPOINTS=0)
    endif()
  else()
    add_definitions(-DCC_USE_PHYSICS=0)
  endif()

    # definitions for box2d
  if (USE_BOX2D)
    add_definitions(-DCC_ENABLE_BOX2D_INTEGRATION=1)
  else()
    add_definitions(-DCC_ENABLE_BOX2D_INTEGRATION=0)
  endif()

    # definitions for bullet
  if (USE_BULLET)
    add_definitions(-DCC_ENABLE_BULLET_INTEGRATION=1)
        add_definitions(-DCC_USE_3D_PHYSICS=1)
  else()
    add_definitions(-DCC_ENABLE_BULLET_INTEGRATION=0)
        add_definitions(-DCC_USE_3D_PHYSICS=0)
  endif()

    # definitions for recast
  if (USE_RECAST)
    add_definitions(-DCC_USE_NAVMESH=1)
  else()
    add_definitions(-DCC_USE_NAVMESH=0)
  endif()

  # Compiler options
  if(MSVC)

    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS} /MDd")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS} /MD")
    set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} /NODEFAULTLIB:msvcrt /NODEFAULTLIB:libcmt")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /NODEFAULTLIB:libcmt")

    add_definitions(-DUNICODE -D_UNICODE)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS -D_SCL_SECURE_NO_WARNINGS
                    -wd4251 -wd4244 -wd4334 -wd4005 -wd4820 -wd4710
                    -wd4514 -wd4056 -wd4996 -wd4099)
    # multi thread compile option
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
    # Use inline Debug info (/Z7) format. Or internal error may occur.
    # Errors looks like: "xmemory0(592): error C3130: Internal Compiler Error: failed to write injected code block to PDB"
    foreach(lang C CXX)
      string(REGEX REPLACE "/Z[iI7]" "" CMAKE_${lang}_FLAGS_DEBUG "${CMAKE_${lang}_FLAGS_DEBUG}")
      set(CMAKE_${lang}_FLAGS_DEBUG "${CMAKE_${lang}_FLAGS_DEBUG} /Z7")
    endforeach()

  else()
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
      ADD_DEFINITIONS(-DCOCOS2D_DEBUG=1)
    endif()
    set(CMAKE_C_FLAGS_DEBUG "-g -Wall")
    set(CMAKE_CXX_FLAGS_DEBUG ${CMAKE_C_FLAGS_DEBUG})
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 -fPIC")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wno-deprecated-declarations -Wno-reorder -Wno-invalid-offsetof -fPIC")
    if(CLANG AND NOT ANDROID)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
    endif()
    if(CLANG AND ANDROID AND ANDROID_ARM_MODE STREQUAL thumb AND ANDROID_ABI STREQUAL armeabi)
      string(REPLACE "-mthumb" "-marm" CMAKE_C_FLAGS ${CMAKE_C_FLAGS})
      string(REPLACE "-mthumb" "-marm" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
    endif()
  endif(MSVC)

  # Some macro definitions
  if(WINDOWS)

    if(BUILD_SHARED_LIBS)
      add_definitions(-D_USRDLL -D_EXPORT_DLL_ -D_USEGUIDLL -D_USREXDLL -D_USRSTUDIODLL)
    else()
      add_definitions(-DCC_STATIC)
    endif()

    add_definitions(-DCOCOS2DXWIN32_EXPORTS -D_WINDOWS -DWIN32 -D_WIN32)
    set(PLATFORM_FOLDER win32)
  elseif(APPLE)
    add_definitions(-DUSE_FILE32API)
    if(MACOSX)
      add_definitions(-DTARGET_OS_MAC)
      set(PLATFORM_FOLDER mac)
    elseif(IOS)
      # TARGET_OS_IOS
      # add_definitions(-DTARGET_OS_IPHONE)
      add_definitions(-DTARGET_OS_IOS)
      set(PLATFORM_FOLDER ios)
    endif(MACOSX)

  elseif(LINUX)
    add_definitions(-DLINUX)
    set(PLATFORM_FOLDER linux)
  elseif(ANDROID)
    add_definitions(-DUSE_FILE32API)
    set(PLATFORM_FOLDER android)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fexceptions")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsigned-char -fexceptions")
    set(CMAKE_CXX_CREATE_SHARED_LIBRARY "${CMAKE_CXX_CREATE_SHARED_LIBRARY} -latomic")
    
    if(CLANG AND ANDROID_ARM_MODE STREQUAL thumb AND ANDROID_ABI STREQUAL armeabi)
            string(REPLACE "-mthumb" "-marm" CMAKE_C_FLAGS ${CMAKE_C_FLAGS})
            string(REPLACE "-mthumb" "-marm" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
    endif()

  else()
    message( FATAL_ERROR "Unsupported platform, CMake will exit" )
    return()
  endif()

  if(MINGW)
    add_definitions(-DGLEW_STATIC)
    add_definitions(-DCURL_STATICLIB)
    add_definitions(-DAL_LIBTYPE_STATIC)
    add_definitions(-D__SSIZE_T)

    if(CLANG)
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ")
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ")
    endif()
  endif()

  if(CMAKE_FIND_ROOT_PATH AND USE_EXTERNAL_PREBUILT)
  # Adds cocos2d-x external folder to the list of valid include/library paths when cross-compiling and using prebuilds
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_FIND_ROOT_PATH} ${COCOS_EXTERNAL_DIR})
endif()

  if(WINDOWS)
    # folder much targets
    set_property(GLOBAL PROPERTY USE_FOLDERS ON)
    # not support other compile tools except MSVC for now
    if(MSVC)
        if (${MSVC_VERSION} EQUAL 1900 OR ${MSVC_VERSION} GREATER 1900)
            message(STATUS "using Windows MSVC generate cocos2d-x project, MSVC_VERSION:${MSVC_VERSION} check pass")
        else()
            message(FATAL_ERROR "using Windows MSVC generate cocos2d-x project, MSVC_VERSION:${MSVC_VERSION} too low" )
        endif()
        define_property(TARGET
            PROPERTY DEPEND_DLLS
            BRIEF_DOCS "depend dlls of a target"
            FULL_DOCS "use to save depend dlls of a target"
        )
    else()
        message(FATAL_ERROR "please using Windows MSVC compile cocos2d-x project, support other compile tools not yet" )
    endif()
  endif()

  # check use prebuilt config
  if(GEN_COCOS_PREBUILT AND USE_COCOS_PREBUILT)
    message(FATAL_ERROR "can't generate prebuilt libs and use prebuilt libs at the same time" )
  endif()

  if(GEN_COCOS_PREBUILT OR USE_COCOS_PREBUILT)
    if(DEFINED COCOS_PREBUILT_ROOT)
        message(STATUS "pre-defined COCOS_PREBUILT_ROOT: ${COCOS_PREBUILT_ROOT}")
    else()
        # the default prebuilt path is cocos2d-x/prebuilt
        set(COCOS_PREBUILT_ROOT $ENV{COCOS_TEMPLATES_ROOT}/../prebuilt)
    endif()
    if(NOT IS_DIRECTORY ${COCOS_PREBUILT_ROOT})
        message(STATUS "prebuilt root directory defined but not existed, create: ${COCOS_PREBUILT_ROOT}")
        file(MAKE_DIRECTORY ${COCOS_PREBUILT_ROOT})
    endif()
    if(IS_DIRECTORY ${COCOS_PREBUILT_ROOT})
        # prebuilt libs path
        set(COCOS_PREBUILT_PATH ${COCOS_PREBUILT_ROOT}/${PLATFORM_FOLDER}/${CMAKE_BUILD_TYPE})
        if(XCODE OR VS)
            set(COCOS_PREBUILT_PATH ${COCOS_PREBUILT_ROOT}/${PLATFORM_FOLDER})
        endif()
        if(ANDROID)
            set(COCOS_PREBUILT_PATH ${COCOS_PREBUILT_ROOT}/${PLATFORM_FOLDER}/${ANDROID_ABI})
        endif()
        message(STATUS "COCOS_PREBUILT_PATH:" ${COCOS_PREBUILT_PATH})
    else()
        if(ANDROID)
            message(WARNING "using cmake in Android Studio, can't get value of environment variable, please define COCOS_PREBUILT_ROOT manually" )
        endif()
        message(FATAL_ERROR "can't find prebuilt libs location" )
    endif()
  endif()
endmacro (SetCompilerOptions)