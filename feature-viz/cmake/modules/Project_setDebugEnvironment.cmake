macro(Project_setDebugEnvironment target)
	if(MSVC)
		###############################################################
		# set paths
		set (optionalArgs ${ARGN})
		list(LENGTH optionalArgs optionalArgsCnt)
		if(${optionalArgsCnt} GREATER 0)
			foreach(currPath "${optionalArgs}")
				list(APPEND debugEnvPaths ${currPath})
			endforeach()
		endif()
		
		foreach (currBinDir ${debugEnvPaths})
			string(REGEX REPLACE "/" "\\\\" formattedBinDir ${currBinDir})
			message(STATUS "Added bin dir for debugging: ${formattedBinDir}")
			string(CONCAT pathStr "${pathStr}" "${formattedBinDir};")
		endforeach()

		string(CONCAT pathStr "${pathStr}" "%PATH%")
		###############################################################
		# generate .user file for Visual Studio
		if(compiler_arch STREQUAL "x64")
			set(currPlatform "x64")
		else()
			set(currPlatform "Win32")
		endif()

		foreach(currConfig ${CMAKE_CONFIGURATION_TYPES})
			string(CONCAT propGrpsStr "${propGrpsStr}"
				"\t<PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='${currConfig}|${currPlatform}'\">\n"
				"\t\t<LocalDebuggerEnvironment>PATH=${pathStr}</LocalDebuggerEnvironment>\n"
				"\t\t<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>\n"
				"\t</PropertyGroup>\n"
			)
		endforeach()

		file(WRITE "${CMAKE_BINARY_DIR}\\${target}.vcxproj.user"
			"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
			"<Project ToolsVersion=\"${MSVC_VERSION}\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">\n"
			"${propGrpsStr}"
			"</Project>"
		)
	endif()
endmacro()