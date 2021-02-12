
# ---
# ockam::ffi_interface
# ---
add_library(ockam_ffi_interface INTERFACE)
add_library(ockam::ffi_interface ALIAS ockam_ffi_interface)

set(INCLUDE_DIR ${CMAKE_CURRENT_BINARY_DIR}/include)

target_include_directories(ockam_ffi_interface INTERFACE ${INCLUDE_DIR})

file(COPY ../../../../../../rust/ockam/ockam_ffi/include/vault.h DESTINATION ${INCLUDE_DIR}/ockam)

target_sources(
  ockam_ffi_interface
  INTERFACE
    ${INCLUDE_DIR}/ockam/vault.h
)

# ---
# ockam::vault_rust_default
# ---

add_library(ockam_ffi SHARED IMPORTED GLOBAL)
add_library(ockam::ffi ALIAS ockam_ffi)

add_library(ockam_vault SHARED IMPORTED GLOBAL)
add_library(ockam::vault ALIAS ockam_vault)

if(APPLE)
file(COPY ../../../../../../rust/target/debug/libockam_ffi.dylib DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
set(ffi_lib_path "${CMAKE_CURRENT_BINARY_DIR}/libockam_ffi.dylib")
file(COPY ../../../../../../rust/target/debug/libockam_vault.dylib DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
set(vault_lib_path "${CMAKE_CURRENT_BINARY_DIR}/libockam_vault.dylib")
endif()

if(UNIX AND NOT APPLE)
file(COPY ../../../../../../rust/target/debug/libockam_ffi.so DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
set(ffi_lib_path "${CMAKE_CURRENT_BINARY_DIR}/libockam_ffi.so")
file(COPY ../../../../../../rust/target/debug/libockam_vault.so DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
set(vault_lib_path "${CMAKE_CURRENT_BINARY_DIR}/libockam_vault.so")
endif()

get_filename_component(real_ffi_lib_path "${ffi_lib_path}" REALPATH BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}")
set_target_properties(
        ockam_ffi
        PROPERTIES
        IMPORTED_LOCATION "${real_ffi_lib_path}"
)

get_filename_component(real_vault_lib_path "${vault_lib_path}" REALPATH BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}")
set_target_properties(
        ockam_vault
        PROPERTIES
        IMPORTED_LOCATION "${real_vault_lib_path}"
)

# ---
# ockam::elixir_vault
# ---
add_library(ockam_elixir_ffi)
add_library(ockam::elixir_ffi ALIAS ockam_elixir_ffi)

target_sources(ockam_elixir_ffi PRIVATE nifs.c vault.c vault.h common.c common.h)

target_include_directories(ockam_elixir_ffi PUBLIC $ENV{ERL_INCLUDE_DIR})

if(APPLE)
set_target_properties(ockam_elixir_ffi PROPERTIES LINK_FLAGS "-dynamiclib -undefined dynamic_lookup")
set_target_properties(ockam_vault PROPERTIES LINK_FLAGS "-dynamiclib -undefined dynamic_lookup")
endif()

if(UNIX AND NOT APPLE)
set_target_properties(ockam_elixir_ffi PROPERTIES LINK_FLAGS "-fPIC -shared")
set_target_properties(ockam_vault PROPERTIES LINK_FLAGS "-fPIC -shared")
endif()

target_link_libraries(
        ockam_elixir_ffi
  PUBLIC
    ockam::ffi_interface
    ockam::ffi
    ockam::vault
)
