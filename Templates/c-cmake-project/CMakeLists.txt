cmake_minimum_required(VERSION 3.20)
project({{PROJECT_NAME}} C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)

include_directories(include)

add_executable({{PROJECT_NAME}} src/main.c src/app.c)
