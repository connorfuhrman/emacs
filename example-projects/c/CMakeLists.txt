cmake_minimum_required(VERSION 4.0)
project(example_c_project C)

if (CMAKE_EXPORT_COMPILE_COMMANDS)
   set(CMAKE_C_INCLUDE_DIRECTORIES
     CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES)
 endif()

 add_executable(main main.c)
