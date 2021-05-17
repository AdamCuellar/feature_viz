# input:
# 	files: list of files to group
#   parentFolder: if required, "parent folder" can be used to set the top level group name (optional)

macro(Project_source_group files)
	# parentFolder is optional; used to set the filters in Visual Studio. For a single level, use "[folder]"; for nested, use "[folder]\\[folder]".
	# replace all "(..)" combinations to enable regex replacements
	string(REPLACE "(" "_" scrubbedRefDir "${CMAKE_CURRENT_SOURCE_DIR}")
	string(REPLACE ")" "_" scrubbedRefDir "${scrubbedRefDir}")
	
	string(REPLACE "(" "_" scrubbedRefRootDir "${CMAKE_SOURCE_DIR}")
	string(REPLACE ")" "_" scrubbedRefRootDir "${scrubbedRefRootDir}")

	foreach(file ${${files}})
		string(REPLACE "(" "_" scrubbedFile "${file}")
		string(REPLACE ")" "_" scrubbedFile "${scrubbedFile}")
		string(REGEX REPLACE "${scrubbedRefDir}/(../)*" "" scrubbedFile "${scrubbedFile}")
		string(REGEX REPLACE "${scrubbedRefRootDir}" "" scrubbedFile "${scrubbedFile}")
		get_filename_component(dir "${scrubbedFile}" DIRECTORY)
		string(REGEX REPLACE "/" "\\\\" dir "${dir}")

		set(optionalArgs ${ARGN})
		list(LENGTH optionalArgs optionalArgCnt)
		if(${optionalArgCnt} GREATER 0)
			list(GET optionalArgs 0 parentFolder)
			string(CONCAT dir ${parentFolder} "\\\\" ${dir})
		endif()

		if(NOT(dir STREQUAL ""))
			source_group("${dir}" FILES ${file})
		endif()
	endforeach()
endmacro()
