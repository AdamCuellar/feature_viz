set(minGccVersion 3.4) # required to support #pragma once
set(minMsvcVersion 1900) # 1900 is equivalent to MSVC 14 (Visual Studio 2015)

macro(Configure_project)
	# Disable in-source builds to prevent source tree corruption.
	if(" ${CMAKE_SOURCE_DIR}" STREQUAL " ${CMAKE_BINARY_DIR}")
		message(FATAL_ERROR "In-source builds are not allowed. You should create a separate directory for build files."
	)
	endif()

	if(NOT DEFINED CMAKE_CXX_COMPILER_VERSION)
		message(FATAL_ERROR "Compiler version not detected; compiler not supported.")
	endif()


	if(NOT((DEFINED MSVC AND (${MSVC_VERSION} GREATER_EQUAL minMsvcVersion)) OR ((${CMAKE_CXX_COMPILER_VERSION} VERSION_GREATER_EQUAL minGccVersion) AND ((${CMAKE_CXX_COMPILER_ID} MATCHES "GNU")))))
		message(STATUS "${CMAKE_CXX_COMPILER_ID} compiler found, version ${CMAKE_CXX_COMPILER_VERSION}")
		message(FATAL_ERROR "Supported compilers: GCC versions ${minGccVersion} and higher; MSVC version ${minMsvcVersion} and higher.")
	endif()
	
	# check '3rdParty' path is set
	#if(NOT EXISTS "$ENV{HOME}")
	#	set(ENV{HOME} "$ENV{HOMEDRIVE}$ENV{HOMEPATH}") # match Windows' setup to Linux's setup
	#endif()
	
#	set(ENV{HOME} "C:/Workspaces")
#
#	if(NOT EXISTS "$ENV{HOME}/external")
#		message(FATAL_ERROR "Can't find 3rd Party path")
#	endif()

	# In accordance with the Common Software Development Processes and Standards, the RelWithDebInfo build type is removed
 	set(CMAKE_CONFIGURATION_TYPES Debug Release CACHE INTERNAL "Supported configuration types." FORCE)
	
	set_property(GLOBAL PROPERTY USE_FOLDERS ON)

	include(Project_source_group)
	
	get_cmake_property(allVars VARIABLES)
	foreach (var ${allVars})
		string(REGEX MATCH "CMAKE_" matchedVar ${var})
		if(NOT(matchedVar STREQUAL ""))
			mark_as_advanced(FORCE ${var})
		endif()
	endforeach()
	
	# figure the architecture
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	  set(compiler_arch x64)
	else()
	  set(compiler_arch x86)
	endif()
        message(STATUS "Detected compiler architecture: ${compiler_arch}")
	
	# append postfix to all library projects
	set(CMAKE_DEBUG_POSTFIX "-gd")
	
	# Check that the build type has been defined
	if(NOT CMAKE_BUILD_TYPE)
		message(STATUS "Build type not specified; defaulting to 'Release'")
		set(CMAKE_BUILD_TYPE Release)
	endif()

	include(Configure_target)
	
	# Add support for if() IN_LIST operator
	cmake_policy(SET CMP0057 NEW)
endmacro()