project(minitrace
        LANGUAGES C
        VERSION 1.0.0.0)

set(minitrace_files
        minitrace.c
        minitrace.h
        )
add_library(minitrace ${minitrace_files})