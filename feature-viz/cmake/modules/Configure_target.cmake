macro (Configure_target target)
	get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)
	foreach(language IN ITEMS CXX C)
		if(language IN_LIST languages)
			set(${language}_IS_ENABLED 1)
		else()
			set(${language}_IS_ENABLED 0)
		endif()
	endforeach()
	
	set_target_properties(${target} PROPERTIES
	    CXX_STANDARD 11
	    CXX_STANDARD_REQUIRED ON
	    CXX_EXTENSIONS OFF #disable gnu++11 extensions
	)
	# the following is used to tell the compiler to handle initialization of memeber variables on the declaration line.
	# GCC will still print a warning like "non-static data member initializers only available with -std=c++11 or -std=gnu++11 [enabled by default]". It can be ignored.
	# the warning is to remind developers that the code is using c++11 where not all versions of GCC (i.e. <4.x) support c++11 correctly.
	target_compile_features(${target}
		PRIVATE
		cxx_nonstatic_member_init
		cxx_std_11
	)
	get_target_property(target_type ${target} TYPE)

	if(MSVC)
		target_compile_definitions(${target}
			PRIVATE
			-D_CONSOLE -D_CRT_SECURE_NO_WARNINGS -DNOMINMAX -DUNICODE -D_UNICODE -DWIN32_LEAN_AND_MEAN
			$<$<CONFIG:Debug>:_DEBUG>
			$<$<CONFIG:Release>:NDEBUG>
		)

		#RGS: because target_compile_options() doesn't support $<COMPILE_LANGUAGE:CXX> with Visual Studio, and CUDA could be used, target_compile_options is replaced with the following:
		#target_compile_options(${target}
			#PRIVATE
			#$<$<CONFIG:Debug>:/Od /Gm /GR> # can't add /MP flag because of /Gm flag
			#$<$<CONFIG:Release>:/Ox /Gm- /Gy /Oi /GR /MP>
		#)
		set(CMAKE_CXX_FLAGS_DEBUG   "${CMAKE_CXX_FLAGS_DEBUG} /Od /Gm /GR") # can't add /MP flag because of /Gm flag
		set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Ox /Gm- /GR /Oi /MP /Gy") # can't add /GL (whole program optimization) because added WINDOWS_EXPORT_ALL_SYMBOLS to shared libraries and
																						   # CMAKE_CXX_FLAGS_RELEASE applies to all projects. If there's a way to use target_compile_options and the target isn't a shared lib,
																						   # should be allowed to use /GL non shared libs.
		
		set_property(TARGET ${target} APPEND_STRING PROPERTY LINK_FLAGS_DEBUG
			" /debug:FASTLINK"
		)
		
		set_property(TARGET ${target} APPEND_STRING PROPERTY LINK_FLAGS_RELEASE
			" /OPT:REF /OPT:ICF"
		)

# NOTE: These will be set in the top level CMakeLists.txt
#		set_target_properties(${target}
#			PROPERTIES
#			RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin/${compiler_arch}
#			LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/${compiler_arch}
#			ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/${compiler_arch}
#		)
		if(target_type STREQUAL "SHARED_LIBRARY")
			# the following is to support cross-platform development:
			# for shared libraries, on Windows, instead of having to configure __declspec(dllimport/export) for classes and functions, the following is done instead.
			# see https://cmake.org/cmake/help/v3.10/prop_tgt/WINDOWS_EXPORT_ALL_SYMBOLS.html for details. Note, if global data symbols are used (including static class vars), __declspec(dllimport)
			# still needs to be defined in the other projects.
			set_target_properties(${target}
				PROPERTIES
				WINDOWS_EXPORT_ALL_SYMBOLS TRUE
			)
			# the following will generate ${target}_export.h to be included by any other project that needs access to exported global data (including static class-member variables):
			#usage:
			#	"#include <${target}_export.h>"
			#	"class myclass"
			#	"{"
			#	"	static mylibrary_EXPORT int GlobalCounter;"
			#	"	..."
			include(GenerateExportHeader)
			generate_export_header(${target})
		endif()
	elseif(${CMAKE_CXX_COMPILER_ID} MATCHES "GNU")
		add_definitions(-DLinux)
		if(CMAKE_BUILD_TYPE STREQUAL "Debug")
			add_definitions(-D_DEBUG)
		elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
			add_definitions(-DNDEBUG -D_FORTIFY_SOURCE=2)
		endif()

		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fasynchronous-unwind-tables -pedantic -Wall -Werror=format-security -fstack-protector-strong -fpermissive")
		set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g")
		set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")
		# for GCC, all linker commands need to be passed with the prefix -Wl,[option],[option's value if any]
		set_property(TARGET ${target} APPEND_STRING PROPERTY LINK_FLAGS
			" -Wl,-z,relro -Wl,-z,now"
		)
		
		if(target_type STREQUAL "EXECUTABLE")
			target_compile_options(${target}
 				PRIVATE
				$<${CXX_IS_ENABLED}:$<$<COMPILE_LANGUAGE:CXX>:-fpie>>
				$<${C_IS_ENABLED}:$<$<COMPILE_LANGUAGE:C>:-fpie>>
			)			
			set_property(TARGET ${target} APPEND_STRING PROPERTY LINK_FLAGS
				" -pie"
			)
		elseif(target_type STREQUAL "SHARED_LIBRARY")
			target_compile_options(${target}
 				PRIVATE
				$<${CXX_IS_ENABLED}:$<$<COMPILE_LANGUAGE:CXX>:-fPIC>>
				$<${C_IS_ENABLED}:$<$<COMPILE_LANGUAGE:C>:-fPIC>>
				$<${CXX_IS_ENABLED}:$<$<COMPILE_LANGUAGE:CXX>:-fno-jump-tables>>
				$<${C_IS_ENABLED}:$<$<COMPILE_LANGUAGE:C>:-fno-jump-tables>>
			)
			set_property(TARGET ${target} APPEND_STRING PROPERTY LINK_FLAGS
				" -shared"
			)		
		elseif(target_type STREQUAL "STATIC_LIBRARY")		
			target_compile_options(${target}
				PRIVATE
				# some documentation will say that it's better to compile with -fpie instead of -fPIC for static libraries if they'll end up pulled into an executable
				# compiled with -fpie and linked with -pie. However, it's ok to use -fPIC; it's also better in case the static libs will end up being pulled into
				# shared objects (.so) also compiled with -fPIC and linked with -shared.
				$<${CXX_IS_ENABLED}:$<$<COMPILE_LANGUAGE:CXX>:-fPIC>>
				$<${C_IS_ENABLED}:$<$<COMPILE_LANGUAGE:C>:-fPIC>>
				$<${CXX_IS_ENABLED}:$<$<COMPILE_LANGUAGE:CXX>:-fno-jump-tables>>
				$<${C_IS_ENABLED}:$<$<COMPILE_LANGUAGE:C>:-fno-jump-tables>>
			)
		endif()


		if(${compiler_arch} STREQUAL "x64")
			set(libFolder lib64)
		else()
			set(libFolder lib)
		endif()

# NOTE: These will be set in the top level CMakeLists.txt
#		set_target_properties(${target}
#			PROPERTIES
#			RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
#			LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${libFolder}
#			ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${libFolder}
#		)
	endif()

	if(target_type STREQUAL "EXECUTABLE")
		set_target_properties(${target}
			PROPERTIES
			DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX}
			FOLDER "Applications"
		)
	elseif(target_type STREQUAL "SHARED_LIBRARY" OR target_type STREQUAL "STATIC_LIBRARY")
		set_target_properties(${target}
			PROPERTIES
			FOLDER "Libraries"
		)
	endif()
endmacro()