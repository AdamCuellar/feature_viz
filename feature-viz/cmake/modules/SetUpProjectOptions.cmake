macro(SetUpProjectOptions)
	file(GLOB options "${CMAKE_COMMON_OPTIONS}/*.cmake")
	foreach(option ${options})
		include(${option})
	endforeach()
endmacro()
