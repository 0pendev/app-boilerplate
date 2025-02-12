# the name of the target operating system
set(CMAKE_SYSTEM_NAME Generic)

# which compilers to use for C and C++
# set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
set(LEDGER_CLANG /opt/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-/bin/clang)
set(CMAKE_ASM_COMPILER ${LEDGER_CLANG})
set(CMAKE_ASM_LINKER ${LEDGER_CLANG})
set(CMAKE_C_COMPILER   ${LEDGER_CLANG})
set(CMAKE_CXX_COMPILER ${LEDGER_CLANG})

set(TARGET_DEVICE stax CACHE INTERNAL "The name of the device")
set(TARGET_SDKNAME stax CACHE INTERNAL "the name used in the folder target of the secure SDK")
set(TARGET_ASM_FLAGS --target=armv8m-none-eabi -mcpu=cortex-m35p+nodsp -mthumb CACHE INTERNAL "Flags used when build .s and .S files")
set(TARGET_C_FLAGS --sysroot=/usr/arm-linux-gnueabi --target=armv8m-none-eabi -frwpi -mcpu=cortex-m35p+nodsp -mno-movt -msoft-float -mthumb -mtune=cortex-m35p+nodsp -fropi -mno-unaligned-access CACHE INTERNAL "CFLAGS used for the compilation")
set(TARGET_LD_FLAGS --target=armv8m-none-eabi -mcpu=cortex-m35p+nodsp -mlittle-endian -mno-movt -momit-leaf-frame-pointer -nodefaultlibs -nostdlib CACHE INTERNAL "LDFLAGS used for the compilation")

# Cryptographic definitions
set(DEFINES HAVE_NES_CRYPT HAVE_ST_AES NATIVE_LITTLE_ENDIAN HAVE_CRC HAVE_HASH HAVE_RIPEMD160 HAVE_SHA224 HAVE_SHA256 HAVE_SHA3 HAVE_SHA384 HAVE_SHA512 HAVE_SHA512_WITH_BLOCK_ALT_METHOD HAVE_SHA512_WITH_BLOCK_ALT_METHOD_M0 HAVE_BLAKE2 HAVE_HMAC HAVE_PBKDF2 HAVE_AES HAVE_MATH HAVE_RNG HAVE_RNG_RFC6979 HAVE_RNG_SP800_90A HAVE_ECC HAVE_ECC_WEIERSTRASS HAVE_ECC_TWISTED_EDWARDS HAVE_ECC_MONTGOMERY HAVE_SECP256K1_CURVE HAVE_SECP256R1_CURVE HAVE_SECP384R1_CURVE HAVE_SECP521R1_CURVE HAVE_FR256V1_CURVE HAVE_STARK256_CURVE HAVE_BRAINPOOL_P256R1_CURVE HAVE_BRAINPOOL_P256T1_CURVE HAVE_BRAINPOOL_P320R1_CURVE HAVE_BRAINPOOL_P320T1_CURVE HAVE_BRAINPOOL_P384R1_CURVE HAVE_BRAINPOOL_P384T1_CURVE HAVE_BRAINPOOL_P512R1_CURVE HAVE_BRAINPOOL_P512T1_CURVE HAVE_BLS12_381_G1_CURVE HAVE_CV25519_CURVE HAVE_CV448_CURVE HAVE_ED25519_CURVE HAVE_ED448_CURVE HAVE_ECDH HAVE_ECDSA HAVE_EDDSA HAVE_ECSCHNORR HAVE_X25519 HAVE_X448 HAVE_AES_GCM HAVE_CMAC HAVE_AES_SIV CACHE INTERNAL "Target specific definitions")

# Only uses the host system root to search for programs
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ALWAYS)

# search headers and libraries in the target environment
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# SDK Informations
set(API_TAG v22.1.0 CACHE INTERNAL "Git Tag to fetch")
set(API_LEVEL 22 CACHE INTERNAL "API LEVEL Supported by the target")
set(SDK_NAME ledger-secure-sdk CACHE INTERNAL "Name of the sdk in use")
