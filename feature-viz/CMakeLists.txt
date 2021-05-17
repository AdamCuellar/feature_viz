cmake_minimum_required(VERSION 3.11 FATAL_ERROR)

project(Feature-Viz
        LANGUAGES CXX
        VERSION 1.0.0.0)

set(CMAKE_COMMON_MODULES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules" CACHE PATH "Path to cmake modules directory")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_COMMON_MODULES}")

if(${CMAKE_CXX_COMPILER_ID} MATCHES "GNU")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m64") # set to build x64 versions
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m64") # set to build x64 versions
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread") #enable support for std::thread
endif()

include(Configure_project)
Configure_project()

set(${PROJECT_NAME}_header_files
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${CMAKE_CURRENT_SOURCE_DIR}/cvui
        /home/adam/Documents/darknet/include
)

set(${PROJECT_NAME}_source_files
        ${CMAKE_CURRENT_SOURCE_DIR}/src/lightnet.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/MiniTraceHelper.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/os_hal.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/VideoHelper.cpp
)

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/minitrace")

add_executable(${PROJECT_NAME}
        ${${PROJECT_NAME}_header_files}
        ${${PROJECT_NAME}_source_files}
)

# OpenCV
find_package(OpenCV REQUIRED)
find_package(X11 REQUIRED)

# If the package has been found, several variables will
# be set, you can find the full list with descriptions
# in the OpenCVConfig.cmake file.
# Print some message showing some of them
message(STATUS "OpenCV library status:")
message(STATUS "    version: ${OpenCV_VERSION}")
message(STATUS "    libraries: ${OpenCV_LIBS}")
message(STATUS "    include path: ${OpenCV_INCLUDE_DIRS}")
message(STATUS " current dir: ${CMAKE_CURRENT_SOURCE_DIR}")

set(OpenCVComponents core highgui imgproc dnn)
find_package(OpenCV COMPONENTS ${OpenCVComponents})

target_link_directories(${PROJECT_NAME}
        PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/minitrace"
        )

target_include_directories(${PROJECT_NAME}
        PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/minitrace"
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
        "${CMAKE_CURRENT_SOURCE_DIR}/src"
        "${CMAKE_CURRENT_SOURCE_DIR}/cvui"
        "/home/adam/Documents/darknet/include"
        "${OpenCV_INCLUDE_DIRS}"
        "${X11_INCLUDE_DIR}"
)

target_link_libraries(${PROJECT_NAME}
        PRIVATE
        $<$<CXX_COMPILER_ID:GNU>:-pthread> #enable support for std::thread
        ${OpenCV_LIBRARIES}
        ${X11_LIBRARIES}
        /home/adam/Documents/darknet/libdarknet.so
        stdc++fs
        minitrace
        )

# set common flags
Configure_target(${PROJECT_NAME})

target_compile_definitions(${PROJECT_NAME}
        PRIVATE
        -DUSEOPENCV
)

