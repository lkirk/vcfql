cmake_minimum_required(VERSION 3.7)
include(ExternalProject)

project(pcr)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(BCF_VERSION "0.1.0")
set(BCF_BUG_ADDRESS "github.com/lloydkirk/bcf/issues")
set(BCF_DOC_STRING "Sed like operations for bcf files")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wpedantic -Wextra -Werror")

find_package(BISON)
find_package(FLEX)

set(ZLIB_DIR ${CMAKE_BINARY_DIR}/thirdparty/zlib)
ExternalProject_Add(zlib
  PREFIX ${ZLIB_DIR}
  GIT_REPOSITORY "https://github.com/madler/zlib.git"
  GIT_TAG "v1.2.11"
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND ${ZLIB_DIR}/src/zlib/configure --prefix=${ZLIB_DIR} --static)

set(HTSLIB_DIR ${CMAKE_BINARY_DIR}/thirdparty/htslib)
ExternalProject_Add(htslib
  PREFIX ${HTSLIB_DIR}
  GIT_REPOSITORY "https://github.com/samtools/htslib.git"
  GIT_TAG "1.3.1"
  BUILD_IN_SOURCE 1
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND autoheader
  COMMAND autoconf
  COMMAND ./configure --prefix=${HTSLIB_DIR}
  BUILD_COMMAND make
  INSTALL_COMMAND make install)

set(CMOCKA_DIR ${CMAKE_BINARY_DIR}/thirdparty/cmocka)
ExternalProject_Add(cmocka
  PREFIX ${CMOCKA_DIR}
  GIT_TAG "cmocka-1.1.3"
  GIT_REPOSITORY "git://git.cryptomilk.org/projects/cmocka.git"
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND ${CMAKE_COMMAND} -DCMAKE_INSTALL_PREFIX:PATH=${CMOCKA_DIR} ${CMOCKA_DIR}/src/cmocka
  )

set(PARSER_DIR ${CMAKE_CURRENT_BINARY_DIR}/query_parser)
file(MAKE_DIRECTORY ${PARSER_DIR})
BISON_TARGET(parser src/parser.y ${PARSER_DIR}/parser.c)
FLEX_TARGET(lexer src/lexer.l ${PARSER_DIR}/lexer.c DEFINES_FILE ${PARSER_DIR}/lexer.h)
ADD_FLEX_BISON_DEPENDENCY(lexer parser)

include_directories(${PARSER_DIR})
add_definitions(-DYY_NO_INPUT -DYY_NO_UNPUT)

# ===========
# use to make a parser binary (good for debugging just parser related issues)
# ===========

# add_executable(parser ${PARSER_DIR}/lexer.c ${BISON_parser_OUTPUTS} ${FLEX_parser_OUTPUTS})
# target_link_libraries(parser y ${BISON_LIBRARIES} ${FLEX_LIBRARIES})

include_directories(${ZLIB_DIR}/include)
set(zlib_static ${ZLIB_DIR}/lib/libz.a)
include_directories(${HTSLIB_DIR}/include)
set(htslib_static ${HTSLIB_DIR}/lib/libhts.a)
add_dependencies(htslib zlib)

# set(CMAKE_BUILD_TYPE Debug) # compile with debug symbols (cmake -DCMAKE_BUILD_TYPE=Debug)

include_directories(src)
set(INCLUDE_GEN ${CMAKE_CURRENT_BINARY_DIR}/include_generated)
file(MAKE_DIRECTORY ${INCLUDE_GEN})
configure_file("src/config.h.in" "${INCLUDE_GEN}/config.h")
include_directories(${INCLUDE_GEN})

# add_executable(bcf src/main.c ${PARSER_DIR}/lexer.c ${BISON_parser_OUTPUTS} ${FLEX_parser_OUTPUTS})
add_executable(bcf src/main.c ${PARSER_DIR}/lexer.c ${PARSER_DIR}/parser.c ${BISON_parser_OUTPUTS} ${FLEX_parser_OUTPUTS})
add_dependencies(bcf htslib)
target_link_libraries(bcf ${htslib_static} ${zlib_static} pthread m y ${BISON_LIBRARIES} ${FLEX_LIBRARIES})

# ====
# Static linking does not really work because of the libnss stuff... but ya know... it's possible
# One really shouldn't statically link glibc.
# Maybe this could be done with musl!
# TODO: make an option for static linking with musl \'o'/
# ====

# set_target_properties(vcf PROPERTIES LINK_SEARCH_START_STATIC 1)
# set_target_properties(vcf PROPERTIES LINK_SEARCH_END_STATIC 1)
# set_target_properties(htslib PROPERTIES LINK_SEARCH_START_STATIC 1)
# set_target_properties(htslib PROPERTIES LINK_SEARCH_END_STATIC 1)
# set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
# set(CMAKE_EXE_LINKER_FLAGS "-static -static-libgcc -static-libstdc++")


# TODO: break testing out into own module?

enable_testing()
include(CTest)

find_program(MEMORYCHECK_COMMAND valgrind)
set(MEMORYCHECK_COMMAND_OPTIONS "--trace-children=yes --leak-check=full")

add_compile_options(-std=c11)
include_directories(${CMOCKA_DIR}/src/cmocka/include)
add_executable(test_ast test/test_ast.c src/ast.c)
add_dependencies(test_ast cmocka bcf)
add_test(test_ast test_ast)
target_link_libraries(test_ast ${CMOCKA_DIR}/lib64/libcmocka.so)
