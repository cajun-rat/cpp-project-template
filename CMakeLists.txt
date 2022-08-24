cmake_minimum_required(VERSION 3.18)
project(template) ## change me

set(CMAKE_CXX_STANDARD 20)

find_package(Boost REQUIRED COMPONENTS)
include(CTest)
enable_testing()

include(FetchContent)
FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG 25cc5777a17820a6339204a3552aa1dd5e428669
)
# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

add_custom_target(build_tests)
set(TEST_LIBS GTest::gtest_main)

set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake-modules)
include(ProjectHelpers)




add_executable(demo main.cc)

add_library(foo foo.cc)

ak_source_file_checks(main.cc foo.cc foo.h)

add_ak_test(NAME foo
            SOURCES foo_test.cc
            LIBRARIES foo)


