if(CMAKE_SIZEOF_VOID_P EQUAL 8)
  set(OpenCV_ARCH x64)
else()
  set(OpenCV_ARCH x86)
endif()

if(MSVC)
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(OpenCV_TBB_ARCH intel64)
  else()
    set(OpenCV_TBB_ARCH ia32)
  endif()
endif()

set (OpenCV_BIN_DIR "${OpenCV_ROOT}/bin" CACHE STRING "OpenCV binaries directory")
mark_as_advanced(FORCE OpenCV_BIN_DIR)

set (OpenCV_INCLUDE_DIR "${OpenCV_ROOT}/include" CACHE STRING "OpenCV include path")
mark_as_advanced(FORCE OpenCV_INCLUDE_DIR)

if(OpenCV_INCLUDE_DIR)
  # Extract from version.hpp
  file(STRINGS "${OpenCV_INCLUDE_DIR}/opencv2/core/version.hpp" OpenCV_VERSION_MAJOR REGEX "#define CV_VERSION_MAJOR ")
  file(STRINGS "${OpenCV_INCLUDE_DIR}/opencv2/core/version.hpp" OpenCV_VERSION_MINOR REGEX "#define CV_VERSION_MINOR ")
  file(STRINGS "${OpenCV_INCLUDE_DIR}/opencv2/core/version.hpp" OpenCV_VERSION_PATCH REGEX "#define CV_VERSION_REVISION ")
  
  string(REGEX MATCH "([0-9]+)" OpenCV_VERSION_MAJOR ${OpenCV_VERSION_MAJOR})
  string(REGEX MATCH "([0-9]+)" OpenCV_VERSION_MINOR ${OpenCV_VERSION_MINOR})
  string(REGEX MATCH "([0-9]+)" OpenCV_VERSION_PATCH ${OpenCV_VERSION_PATCH})
endif()

if((NOT DEFINED OpenCV_VERSION_MAJOR) OR (NOT DEFINED OpenCV_VERSION_MINOR) OR (NOT DEFINED OpenCV_VERSION_PATCH))
	message(FATAL_ERROR "Open CV version not found")
endif()

set (OpenCV_CVLIB_NAME_SUFFIX "${OpenCV_VERSION_MAJOR}${OpenCV_VERSION_MINOR}${OpenCV_VERSION_PATCH}")

# find libraries of components
if(OpenCV_FIND_COMPONENTS)
    foreach (__CVLIB ${OpenCV_FIND_COMPONENTS})
      # debug build
	find_library (
            OpenCV_${__CVLIB}_LIBRARY_DEBUG
            NAMES "opencv_${__CVLIB}${OpenCV_CVLIB_NAME_SUFFIX}d" "${__CVLIB}${OpenCV_CVLIB_NAME_SUFFIX}d"
                  "libopencv_${__CVLIB}d.so"
            PATHS "${OpenCV_ROOT}"
            PATH_SUFFIXES lib64 lib
            NO_DEFAULT_PATH
        )

      # release build
      find_library (
          OpenCV_${__CVLIB}_LIBRARY_RELEASE
          NAMES "opencv_${__CVLIB}${OpenCV_CVLIB_NAME_SUFFIX}" "${__CVLIB}${OpenCV_CVLIB_NAME_SUFFIX}"
                "libopencv_${__CVLIB}.so"
          PATHS "${OpenCV_ROOT}"
          PATH_SUFFIXES lib64 lib
          NO_DEFAULT_PATH
        )

      mark_as_advanced (OpenCV_${__CVLIB}_LIBRARY_DEBUG)
      mark_as_advanced (OpenCV_${__CVLIB}_LIBRARY_RELEASE)

      # both debug/release
      if (OpenCV_${__CVLIB}_LIBRARY_DEBUG AND OpenCV_${__CVLIB}_LIBRARY_RELEASE)
        set (OpenCV_${__CVLIB}_LIBRARY debug ${OpenCV_${__CVLIB}_LIBRARY_DEBUG} optimized ${OpenCV_${__CVLIB}_LIBRARY_RELEASE})
      # only debug
      elseif (OpenCV_${__CVLIB}_LIBRARY_DEBUG)
        set (OpenCV_${__CVLIB}_LIBRARY ${OpenCV_${__CVLIB}_LIBRARY_DEBUG})
      # only release
      elseif (OpenCV_${__CVLIB}_LIBRARY_RELEASE)
        set (OpenCV_${__CVLIB}_LIBRARY ${OpenCV_${__CVLIB}_LIBRARY_RELEASE})
      # not found
      else ()
        set (OpenCV_${__CVLIB}_LIBRARY)
      endif()

      # add to list of found libraries
      if (OpenCV_${__CVLIB}_LIBRARY)
        list (APPEND OpenCV_LIBS "${OpenCV_${__CVLIB}_LIBRARY}")
      endif ()
    endforeach()
endif()	

set(OpenCV_LIBRARIES ${OpenCV_LIBS} CACHE string "")
mark_as_advanced(OpenCV_LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args (OpenCV DEFAULT_MSG OpenCV_BIN_DIR OpenCV_LIBRARIES)