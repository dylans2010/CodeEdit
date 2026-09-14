cmake_minimum_required(VERSION 3.20)
project({{PROJECT_NAME}} CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(include)

add_executable({{PROJECT_NAME}} src/main.cpp src/greeter.cpp)
