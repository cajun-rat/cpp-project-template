# Derived from https://github.com/uptane/aktualizr
# License (For this file only): MPL-2.0

add_custom_target(qa)
add_custom_target(check-format)

add_custom_target(format)
add_dependencies(qa format)

# Export compile_commands.json for clang-tidy
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

function(add_ak_test)
    set(options PROJECT_WORKING_DIRECTORY)
    set(oneValueArgs NAME)
    set(multiValueArgs SOURCES LIBRARIES ARGS LAUNCH_CMD)
    cmake_parse_arguments(AK_TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    set(TEST_TARGET t_${AK_TEST_NAME})

    add_executable(${TEST_TARGET} EXCLUDE_FROM_ALL ${AK_TEST_SOURCES})
    target_link_libraries(${TEST_TARGET}
            ${AK_TEST_LIBRARIES}
            ${TEST_LIBS})

    if(AK_TEST_PROJECT_WORKING_DIRECTORY)
        set(WD WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
    else()
        set(WD )
    endif()


    add_test(NAME test_${AK_TEST_NAME}
            COMMAND $<TARGET_FILE:${TEST_TARGET}> ${AK_TEST_ARGS} ${GOOGLE_TEST_OUTPUT} ${WD})

    add_dependencies(build_tests ${TEST_TARGET})
    ak_source_file_checks(${AK_TEST_SOURCES})
endfunction(add_ak_test)

find_program(CLANG_FORMAT NAMES clang-format-11)
find_program(CLANG_TIDY NAMES clang-tidy-12 clang-tidy-11)

if(CLANG_FORMAT)
    function(ak_clang_format)
        file(RELATIVE_PATH SUBDIR ${CMAKE_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR})
        foreach(FILE ${ARGN})
            string(REPLACE "/" "_" TARGETNAME "ak_clang_format-${SUBDIR}-${FILE}")
            add_custom_target(${TARGETNAME}
                    COMMAND ${CLANG_FORMAT} -i -style=file ${FILE}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    VERBATIM)
            add_dependencies(format ${TARGETNAME})

            # The check for CI that fails if stuff changes
            string(REPLACE "/" "_" TARGETNAME_CI "ak_ci_clang_format-${SUBDIR}-${FILE}")

            add_custom_target(${TARGETNAME_CI}
                    COMMAND ${CLANG_FORMAT} -style=file ${FILE} | diff -u ${FILE} - || { echo 'Found unformatted code! Run make format'\; false\; }
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
            add_dependencies(check-format ${TARGETNAME_CI})
        endforeach()
    endfunction()
else()
    message(WARNING "clang-format-11 not found, skipping")
    function(ak_clang_format)
    endfunction()
endif()

if(CLANG_TIDY)
    add_custom_target(clang-tidy)
    add_dependencies(qa clang-tidy)
    function(ak_clang_tidy)
        file(RELATIVE_PATH SUBDIR ${CMAKE_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR})
        foreach(FILE ${ARGN})
            string(REPLACE "/" "_" TARGETNAME "ak_clang_tidy-${SUBDIR}-${FILE}")
            add_custom_target(${TARGETNAME}
                    COMMAND ${CLANG_TIDY} -p "${CMAKE_BINARY_DIR}" -quiet ${FILE}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    VERBATIM)
            add_dependencies(clang-tidy ${TARGETNAME})
        endforeach()
    endfunction()
else()
    message(WARNING "Unable to find clang-tidy-12, clang-tidy-11; skipping")
    function(ak_clang_tidy)
        message(WARNING "nope")
    endfunction()
endif()

function(ak_source_file_checks)
    list(REMOVE_DUPLICATES ARGN)
    message("Source file checks for ${ARGN}")
    foreach(FILE ${ARGN})
        file(RELATIVE_PATH FULL_FN ${CMAKE_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/${FILE})
        set(AKTUALIZR_CHECKED_SRCS ${AKTUALIZR_CHECKED_SRCS} ${FULL_FN} CACHE INTERNAL "")
        if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${FULL_FN})
            message(FATAL_ERROR "file ${FULL_FN} does not exist")
        endif()
    endforeach()
    ak_clang_format(${ARGN})

    # exclude test files from clang-tidy because false positives in googletest
    # are hard to remove...
    file(RELATIVE_PATH SUBDIR ${CMAKE_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR})
    if(NOT "${SUBDIR}" MATCHES "tests.*")
        foreach(FILE ${ARGN})
            if(NOT ${FILE} MATCHES ".*_test\\..*$")
                list(APPEND filtered_files ${FILE})
            endif()
        endforeach()
        ak_clang_tidy(${filtered_files})
    endif()
endfunction()
