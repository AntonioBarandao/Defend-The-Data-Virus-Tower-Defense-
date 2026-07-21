cmake_minimum_required(VERSION 3.15)

project(auth_extension)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Godot C++ bindings
add_subdirectory(godot-cpp)

# -------------------------------------------------
# SOURCE FILES
# -------------------------------------------------
add_library(auth SHARED
    cpp_extension/auth_wrapper.cpp
    cpp_extension/register_types.cpp
    cpp_extension/database.cpp
    cpp_extension/auth.cpp
    sqlite/sqlite3.c
)

# -------------------------------------------------
# INCLUDE DIRECTORIES
# -------------------------------------------------
target_include_directories(auth PRIVATE
    ${CMAKE_SOURCE_DIR}/godot-cpp/include
    ${CMAKE_SOURCE_DIR}/cpp_extension
    ${CMAKE_SOURCE_DIR}/sqlite
)

# -------------------------------------------------
# LINK GODOT C++ BINDINGS
# -------------------------------------------------
target_link_libraries(auth PRIVATE godot-cpp)

# -------------------------------------------------
# Build output directory
# -------------------------------------------------
set_target_properties(auth PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

# -------------------------------------------------
# Automatically copy auth.dll to Godot's bin folder
# -------------------------------------------------
add_custom_command(TARGET auth POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory
        "${CMAKE_SOURCE_DIR}/bin"

    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:auth>"
        "${CMAKE_SOURCE_DIR}/bin/auth.dll"

    COMMENT "Copying auth.dll to Godot's bin folder..."
)