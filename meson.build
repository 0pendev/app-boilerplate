project('Boilerplate', 'c', default_options: ['c_std=gnu99'])

fs = import('fs')

# Application name and version
app_name = 'Boilerplate'
app_version_major = '2'
app_version_minor = '1'
app_version_patch = '0'
app_version = app_version_major + '.' + app_version_minor + '.' + app_version_patch

# Application icons
icons = {
  'nanox': 'icons/app_boilerplate_14px.gif',
  'nanosp': 'icons/app_boilerplate_14px.gif',
  'stax': 'icons/app_boilerplate_32px.gif',
  'flex': 'icons/app_boilerplate_40px.gif',
}

# Application glypths
app_glyphs = get_option('app-glyphs')

# Application allowed derivation curves and paths
curve_app_load_params = ['secp256k1']
path_app_load_params = ['44\'/1']

# Variant configuration (optional)
variant_param = 'COIN'
variant_values = ['BOL']

#$$$
# Makefile.target
#$$$
# TARGET should be set as an environment variable otherwise it will be read from a `.target`
# file in the SDK root repository
sdk = get_option('sdk')
if sdk == ''
  error('SDK not set')
endif
target = get_option('target-device')
target_path = join_paths(sdk, 'target', target, 'include')
bolos_target_h = join_paths(target_path, 'bolos_target.h')

# Needed programs
grep = find_program('grep', required: true)
git = find_program('git', required: true)
find = find_program('find', required: true)
python3 = find_program('python3', required: true)
objcopy = find_program('arm-none-eabi-objcopy', required: true)

api_level = '21'
target_id = run_command(grep, ['-E', '^\#define\\s*TARGET_ID', bolos_target_h], check: true).stdout().strip().split()[2]
target_name = run_command(grep, ['-E', '^\#define\\s*TARGET_[^I]', bolos_target_h], check: true).stdout().strip().split()[1]
sdk_name = 'ledger-secure-sdk'

sdk_version = run_command(
  git,
  [
    '-C', sdk,
    'describe',
    '--tags',
    '--exact-match',
    '--match', 'v[0-9]*',
    '--dirty',
  ],
  check: true,
).stdout().strip()

# Get SDK_HASH using git describe for hash
sdk_hash = run_command(
  git,
  [
    '-C', sdk,
    'describe',
    '--always',
    '--dirty',
    '--exclude', '*',
    '--abbrev=40',
  ],
  check: true,
).stdout().strip()

if sdk_hash == ''
  sdk_hash = 'None'
endif
if sdk_version == ''
  sdk_version = 'None'
endif
#####################################################################
#                            BLUETOOTH                              #
#####################################################################
HAVE_APPLICATION_FLAG_BOLOS_SETTINGS = false
defines = []
SDK_SOURCE_PATH = []
if get_option('enable-bluetooth') and target in ['nanox', 'stax', 'flex']
  HAVE_APPLICATION_FLAG_BOLOS_SETTINGS = true
  defines += [
    '-DHAVE_BLE',
    '-DBLE_COMMAND_TIMEOUT_MS=2000',
    '-DHAVE_BLE_APDU',
    '-DBLE_SEGMENT_SIZE=32',
  ]
  SDK_SOURCE_PATH += ['lib_blewbxx', 'lib_blewbxx_impl']
endif

#####################################################################
#                               NFC                                 #
#####################################################################
if get_option('enable-nfc') and target in ['nanox', 'stax', 'flex']
  HAVE_APPLICATION_FLAG_BOLOS_SETTINGS = 1
  defines += ['-DHAVE_NFC']
endif

#####################################################################
#                               SWAP                                #
#####################################################################
HAVE_APPLICATION_FLAG_LIBRARY = true
if get_option('enable-swap')
  HAVE_APPLICATION_FLAG_LIBRARY = true
  defines += ['-DHAVE_SWAP']
endif

#####################################################################
#                              APP STORAGE                          #
#####################################################################
HAVE_APP_STORAGE = false
if get_option('enable-app-storage')
  HAVE_APP_STORAGE = true
  defines += ['-DHAVE_APP_STORAGE']
endif

#####################################################################
#                               DEBUG                               #
#####################################################################
if get_option('debug')
  defines += ['-DHAVE_PRINTF']
  if target == 'nanos'
    defines += ['-DPRINTF=screen_printf']
  else
    defines += ['-DPRINTF=mcu_usb_printf']
  endif
  if get_option('disable-debug-ledger-assert')
    defines += ['-DHAVE_LEDGER_ASSERT_DISPLAY', '-DLEDGER_ASSERT_CONFIG_FILE_INFO']
  endif
  if get_option('disable-debug-throw')
    defines += ['-DHAVE_DEBUG_THROWS']
  endif
endif

#####################################################################
#                        IO SEPROXY BUFFER SIZE                     #
#####################################################################
if not get_option('disable-default-io-seproxy-buffer-size')
  if target == 'nanos'
    defines += ['-DIO_SEPROXYHAL_BUFFER_SIZE_B=128']
  else
    defines += ['-DIO_SEPROXYHAL_BUFFER_SIZE_B=300']
  endif
endif

#####################################################################
#                              NBGL                                 #
#####################################################################
use_nbgl = false
if target in ['nanos', 'nanox', 'nanosplus']
  use_nbgl = get_option('enabe-nbgl-for-nano-devices')
else
  use_nbgl = true
endif

if get_option('enable-nbgl-qrcode') and target in ['stax', 'flex']
  defines += ['-DNBGL_QRCODE']
  SDK_SOURCE_PATH += ['qrcode']
endif

if get_option('enable-nbgl-keyboard')
  defines += ['-DNBGL_KEYBOARD']
endif

if get_option('enable-nbgl-keypad')
  defines += ['-DNBGL_KEYPAD']
endif

#####################################################################
#                          STANDARD defines                         #
#####################################################################
# WARNING, removed support for DEFINES_LIB
# USE CFLAGS instead
defines += [
  '-DMAJOR_VERSION=' + app_version_major,
  '-DMINOR_VERSION=' + app_version_minor,
  '-DPATCH_VERSION=' + app_version_patch,
  '-DIO_HID_EP_LENGTH=64',
]
SDK_SOURCE_PATH = []
if not get_option('disable-standard-app-defines')
  if not get_option('disable-standard-snprintf')
    defines += ['-DHAVE_SPRINTF', '-DHAVE_SNPRINTF_FORMAT_U']
  endif

  if not get_option('disable-standard-usb')
    defines += [
      '-DHAVE_IO_USB',
      '-DHAVE_L4_USBLIB',
      '-DIO_USB_MAX_ENDPOINTS=4',
      '-DHAVE_USB_APDU',
      '-DUSB_SEGMENT_SIZE=64',
    ]
    SDK_SOURCE_PATH += ['lib_stusb', 'lib_stusb_impl']
  endif

  if not get_option('disable-standard-webusb')
    # Enable WEBUSB
    webusb_url = get_option('app-webusb-url').split()
    webusb_url_size_b = webusb_url.length()
    webusb_url_escaped = ''.join(webusb_url)
    defines += [
      '-DHAVE_WEBUSB',
      '-DWEBUSB_URL_SIZE_B=' + webusb_url_size_b.to_string(),
      '-DWEBUSB_URL=' + webusb_url_escaped,
    ]
  endif
  if not get_option('disable-standard-bagl-ux-flow')
    if use_nbgl
      defines += ['-DHAVE_UX_FLOW']
    endif
  endif

  if not get_option('disable-standard-seproxyhal')
    defines += ['-DOS_IO_SEPROXYHAL']
  endif
endif

if not get_option('disable-standard-app-files')
  SDK_SOURCE_PATH += ['lib_standard_app']
endif

if not get_option('disable-standard-app-sync-rapdu') and use_nbgl
  # On LNS only activate it by default if using NBGL.
  # This impact stack usage and shouldn't be activated on all apps silently
  defines += ['-DSTANDARD_APP_SYNC_RAPDU']
endif

#####################################################################
#                          APP_LOAD_PARAMS                          #
#####################################################################

standard_app_flags = 0x000

# Following flags enables app permissions.
# See SDK include/appflags.h for the purpose of each permission
if get_option('allow-derive-master')
  standard_app_flags += 0x010
endif
if get_option('allow-global-pin')
  standard_app_flags += 0x040
endif
if get_option('allow-bolos-settings')
  standard_app_flags += 0x200
endif
if get_option('allow-library')
  standard_app_flags += 0x800
endif

if get_option('not-reviewed')
  standard_app_flags += 0x20000
endif

APP_FLAGS_APP_LOAD_PARAMS = get_option('custom-app-flags') + standard_app_flags

#####################################################################
#                         COMPILER SETTINGS                         #
#####################################################################

#####################################################################
#                               MISC                                #
#####################################################################
icon_name = get_option('icon-name')
if icon_name == ''
  icon_name = icons[target]
endif

crypt = [
  'HAVE_NES_CRYPT',
  'HAVE_ST_AES',
  'NATIVE_LITTLE_ENDIAN',
  'HAVE_CRC',
  'HAVE_HASH',
  'HAVE_RIPEMD160',
  'HAVE_SHA224',
  'HAVE_SHA256',
  'HAVE_SHA3',
  'HAVE_SHA384',
  'HAVE_SHA512',
  'HAVE_SHA512_WITH_BLOCK_ALT_METHOD',
  'HAVE_SHA512_WITH_BLOCK_ALT_METHOD_M0',
  'HAVE_BLAKE2',
  'HAVE_HMAC',
  'HAVE_PBKDF2',
  'HAVE_AES',
  'HAVE_MATH',
  'HAVE_RNG',
  'HAVE_RNG_RFC6979',
  'HAVE_RNG_SP800_90A',
  'HAVE_ECC',
  'HAVE_ECC_WEIERSTRASS',
  'HAVE_ECC_TWISTED_EDWARDS',
  'HAVE_ECC_MONTGOMERY',
  'HAVE_SECP256K1_CURVE',
  'HAVE_SECP256R1_CURVE',
  'HAVE_SECP384R1_CURVE',
  'HAVE_SECP521R1_CURVE',
  'HAVE_FR256V1_CURVE',
  'HAVE_STARK256_CURVE',
  'HAVE_BRAINPOOL_P256R1_CURVE',
  'HAVE_BRAINPOOL_P256T1_CURVE',
  'HAVE_BRAINPOOL_P320R1_CURVE',
  'HAVE_BRAINPOOL_P320T1_CURVE',
  'HAVE_BRAINPOOL_P384R1_CURVE',
  'HAVE_BRAINPOOL_P384T1_CURVE',
  'HAVE_BRAINPOOL_P512R1_CURVE',
  'HAVE_BRAINPOOL_P512T1_CURVE',
  'HAVE_BLS12_381_G1_CURVE',
  'HAVE_CV25519_CURVE',
  'HAVE_CV448_CURVE',
  'HAVE_ED25519_CURVE',
  'HAVE_ED448_CURVE',
  'HAVE_ECDH',
  'HAVE_ECDSA',
  'HAVE_EDDSA',
  'HAVE_ECSCHNORR',
  'HAVE_X25519',
  'HAVE_X448',
  'HAVE_AES_GCM',
  'HAVE_CMAC',
  'HAVE_AES_SIV',
]
foreach def : crypt
  defines += ['-D' + def]
endforeach

# GLYPHS
if not use_nbgl
  error('Only nbgl build is supported')
endif
glyph_paths = ['glyphs']
glyph_opt = ''
if target in ['flex', 'stax']
  glyph_paths += join_paths(sdk, 'lib_nbgl/glyphs/wallet')
  glyph_paths += join_paths(sdk, 'lib_nbgl/glyphs/64px')
  if target == 'flex'
    glyph_paths += join_paths(sdk, 'lib_nbgl/glyphs/40px')
  elif target == 'stax'
    glyph_paths += join_paths(sdk, 'lib_nbgl/glyphs/32px')
  endif
else
  glyph_paths += join_paths(sdk, 'lib_nbgl/glyphs/nano')
  glyph_opt = '--reverse'
endif

glyph_paths += icon_name
glyph_files = app_glyphs
foreach path : glyph_paths
  if fs.exists(path)
    content = run_command(
      find,
      [
        path,
        '-type', 'f',
        '-iname', '*.png',
        '-o',
        '-iname', '*.gif',
        '-o',
        '-iname', '*.bmp',
      ],
      check: true,
    ).stdout().strip()
    if content != ''
      glyph_files += files(content.split('\n'))
    endif
  endif
endforeach

############# Makefile.defines
defines += [
  '-DAPI_LEVEL=' + api_level,
  '-DAPPNAME="@0@"'.format(app_name),
  '-DAPPVERSION="@0@"'.format(app_version),
  '-DSDK_HASH="@0@"'.format(sdk_hash),
  '-DSDK_NAME="@0@"'.format(sdk_name),
  '-DSDK_VERSION="@0@"'.format(sdk_version),
  '-DTARGET="@0@"'.format(target),
  '-DTARGET_NAME="@0@"'.format(target_name),
  '-D__IO=volatile',
  '-Dgcc',
  '-DNDEBUG',
]

# To debug or not to debug
if get_option('debug')
  c_args = ['-Og', '-g1']
  asm_flags = ['-Og', '-g1']
  link_args = ['-Og', '-g1']
else
  c_args = ['-Oz', '-g0']
  asm_flags = ['-Oz', '-g0']
  link_args = ['-Oz', '-g0']
endif

c_args += [
  '-Wall',
  '-Werror=int-to-pointer-cast',
  '-Wextra',
  '-Wformat-security',
  '-Wformat=2',
  '-Wimplicit-fallthrough',
  '-Wno-error=int-conversion',
  '-Wno-main',
  '-Wshadow',
  '-Wundef',
  '-Wvla',
  '-Wwrite-strings',
  '-fdata-sections',
  '-ffunction-sections',
  '-fno-common',
  '-fno-jump-tables', # avoid jump tables for switch to prevent invalid PIC access
  '-fomit-frame-pointer',
  '-fropi',
  '-fshort-enums',
  '-funsigned-char',
  '-mlittle-endian',
  '-mno-unaligned-access',
  '-momit-leaf-frame-pointer',
  '-nodefaultlibs',
  '-nostdlib',
]

if get_option('enable-sdk-werror')
  c_args += ['-Werror']
endif

link_args += [
  '-Wall',
  '-Wl,--gc-sections',
  '-fdata-sections',
  '-ffunction-sections',
  '-fno-common',
  '-fomit-frame-pointer',
  '-fwhole-program',
  '-mno-unaligned-access',
  # TODO
  #-Wl,-Map,$(DBG_DIR)/app.map
]

if target == 'nanos'
  c_args += [
    '--target=armv6m-none-eabi',
    '-mcpu=cortex-m0plus',
    '-frwpi',
    '-mthumb',
  ]
  link_args += ['-mcpu=cortex-m0plus', '-mthumb', '-nostartfiles', '--specs=nano.specs']
endif

if target == 'nanox'
  c_args += ['--target=armv6m-none-eabi', '-frwpi', '-mthumb']
  link_args += [
    '--target=armv6m-none-eabi',
    '-mcpu=cortex-m0plus',
    '-mlittle-endian ',
    '-mno-movt',
    '-momit-leaf-frame-pointer',
    '-mthumb',
    '-mtune=cortex-m0plus',
    '-nodefaultlibs',
    '-nostdlib',
  ]
endif

if target in ['flex', 'nanosp', 'stax']
  c_args += [
    '--target=armv8m-none-eabi',
    '-frwpi',
    '-mcpu=cortex-m35p+nodsp',
    '-mno-movt',
    '-msoft-float',
    '-mthumb',
    '-mtune=cortex-m35p+nodsp',
  ]
  link_args += [
    '--target=armv8m-none-eabi',
    '-mcpu=cortex-m35p+nodsp',
    '-mlittle-endian',
    '-mno-movt',
    '-momit-leaf-frame-pointer',
    '-nodefaultlibs',
    '-nostdlib',
  ]
endif

if target == 'stax'
  defines += [
    '-DHAVE_BAGL_FONT_INTER_MEDIUM_32PX',
    '-DHAVE_BAGL_FONT_INTER_REGULAR_24PX',
    '-DHAVE_BAGL_FONT_INTER_SEMIBOLD_24PX',
    '-DHAVE_INAPP_BLE_PAIRING',
    '-DHAVE_NBGL',
    '-DHAVE_PIEZO_SOUND',
    '-DHAVE_SE_EINK_DISPLAY',
    '-DHAVE_SE_TOUCH',
    '-DNBGL_PAGE',
    '-DNBGL_USE_CASE',
    '-DSCREEN_SIZE_WALLET',
  ]
endif

if target == 'flex'
  defines += [
    '-DHAVE_BAGL_FONT_INTER_MEDIUM_36PX',
    '-DHAVE_BAGL_FONT_INTER_REGULAR_28PX',
    '-DHAVE_BAGL_FONT_INTER_SEMIBOLD_28PX',
    '-DHAVE_FAST_HOLD_TO_APPROVE',
    '-DHAVE_INAPP_BLE_PAIRING',
    '-DHAVE_NBGL',
    '-DHAVE_PIEZO_SOUND',
    '-DHAVE_SE_EINK_DISPLAY',
    '-DHAVE_SE_TOUCH',
    '-DNBGL_PAGE',
    '-DNBGL_USE_CASE',
    '-DSCREEN_SIZE_WALLET',
  ]
endif

if target in ['nanox', 'nanosp']
  defines += [
    '-DBAGL_HEIGHT=64',
    '-DBAGL_WIDTH=128',
    '-DHAVE_BAGL_ELLIPSIS',
    '-DHAVE_BAGL_FONT_OPEN_SANS_EXTRABOLD_11PX',
    '-DHAVE_BAGL_FONT_OPEN_SANS_LIGHT_16PX',
    '-DHAVE_BAGL_FONT_OPEN_SANS_REGULAR_11PX',
    '-DSCREEN_SIZE_NANO',
  ]

  if use_nbgl
    defines += ['-DHAVE_NBGL', '-DNBGL_STEP', '-DNBGL_USE_CASE']
  else
    defines += ['-DHAVE_BAGL', '-DHAVE_UX_FLOW']
  endif
endif

if target == 'nanos'
  defines += [
    '-DBAGL_HEIGHT=32',
    '-DBAGL_WIDTH=128',
    '-DHAVE_BAGL',
    '-DSCREEN_SIZE_NANO',
  ]
endif

if target in ['nanox', 'nanosp']
  defines += [
    '-DHAVE_SE_SCREEN',
    # Button is directly connected to the SE
    '-DHAVE_SE_BUTTON',
    # MCU serial is stored on board of the SE
    '-DHAVE_BATTERY',
    '-DHAVE_FONTS',
    '-DHAVE_INAPP_BLE_PAIRING',
    '-DHAVE_MCU_SERIAL_STORAGE',
  ]
endif

defines += ['-DHAVE_LEDGER_PKI']

c_args += [defines]

gen_glyphs_cmd = [python3, join_paths(sdk, 'lib_nbgl/tools/icon2glyph.py')]
if glyph_opt != ''
  gen_glyphs_cmd += glyph_opt
endif

glyphs_h = custom_target(
  'glyphs_header',
  input: glyph_files,
  output: ['glyphs.h'],
  command: gen_glyphs_cmd
  + ['--glyphcheader', '@OUTPUT0@', '--glyphcfile', 'ignore.c', '@INPUT@'],
)

glyphs_c = custom_target(
  'glyphs_code',
  input: glyph_files,
  output: ['glyphs.c'],
  command: gen_glyphs_cmd
  + ['--glyphcheader', 'ignore.h', '--glyphcfile', '@OUTPUT0@', '@INPUT@'],
)

if get_option('is-plugin')
  link_args += [
    '-L' + join_paths(sdk, 'target', target),
    '-T' + join_paths(sdk, 'target', target, 'plugin_script.ld'),
  ]
else
  link_args += [
    '-L' + join_paths(sdk, 'target', target),
    '-T' + join_paths(sdk, 'target', target, 'script.ld'),
  ]
endif

incos = include_directories(
  join_paths(sdk, 'include'),
  target_path,
)

libbagl = static_library(
  'bagl',
  sources: [
    join_paths(sdk, 'lib_bagl/src/bagl.c'),
    join_paths(sdk, 'lib_bagl/src/bagl_animate.c'),
    join_paths(sdk, 'lib_bagl/src/bagl_fonts.c'),
    join_paths(sdk, 'lib_bagl/src/bagl_glyphs.c'),
  ],
  include_directories: [join_paths(sdk, 'include'), join_paths(sdk, 'lib_bagl/include')],
  pic: false,
  c_args: c_args,
)

libprintf = static_library(
  'printf',
  sources: [join_paths(sdk, 'src/os_printf.c')],
  include_directories: incos,
  pic: false,
  c_args: c_args,
)

inccxng = include_directories(join_paths(sdk, 'lib_cxng/include'))
libcxng = static_library(
  'cxng',
  sources: [
    join_paths(sdk, 'lib_cxng/src/cx_Groestl-ref.c'),
    join_paths(sdk, 'lib_cxng/src/cx_aead.c'),
    join_paths(sdk, 'lib_cxng/src/cx_aes.c'),
    join_paths(sdk, 'lib_cxng/src/cx_aes_gcm.c'),
    join_paths(sdk, 'lib_cxng/src/cx_aes_siv.c'),
    join_paths(sdk, 'lib_cxng/src/cx_blake2b.c'),
    join_paths(sdk, 'lib_cxng/src/cx_blake3.c'),
    join_paths(sdk, 'lib_cxng/src/cx_blake3_ref.c'),
    join_paths(sdk, 'lib_cxng/src/cx_chacha.c'),
    join_paths(sdk, 'lib_cxng/src/cx_chacha_poly.c'),
    join_paths(sdk, 'lib_cxng/src/cx_cipher.c'),
    join_paths(sdk, 'lib_cxng/src/cx_cmac.c'),
    join_paths(sdk, 'lib_cxng/src/cx_crc16.c'),
    join_paths(sdk, 'lib_cxng/src/cx_crc32.c'),
    join_paths(sdk, 'lib_cxng/src/cx_ecdh.c'),
    join_paths(sdk, 'lib_cxng/src/cx_ecdsa.c'),
    join_paths(sdk, 'lib_cxng/src/cx_ecfp.c'),
    join_paths(sdk, 'lib_cxng/src/cx_ecschnorr.c'),
    join_paths(sdk, 'lib_cxng/src/cx_eddsa.c'),
    join_paths(sdk, 'lib_cxng/src/cx_exported_functions.c'),
    join_paths(sdk, 'lib_cxng/src/cx_hash.c'),
    join_paths(sdk, 'lib_cxng/src/cx_hkdf.c'),
    join_paths(sdk, 'lib_cxng/src/cx_hmac.c'),
    join_paths(sdk, 'lib_cxng/src/cx_math.c'),
    join_paths(sdk, 'lib_cxng/src/cx_pbkdf2.c'),
    join_paths(sdk, 'lib_cxng/src/cx_pkcs1.c'),
    join_paths(sdk, 'lib_cxng/src/cx_poly1305.c'),
    join_paths(sdk, 'lib_cxng/src/cx_ram.c'),
    join_paths(sdk, 'lib_cxng/src/cx_ripemd160.c'),
    join_paths(sdk, 'lib_cxng/src/cx_rng.c'),
    join_paths(sdk, 'lib_cxng/src/cx_rng_rfc6979.c'),
    join_paths(sdk, 'lib_cxng/src/cx_rsa.c'),
    join_paths(sdk, 'lib_cxng/src/cx_selftests.c'),
    join_paths(sdk, 'lib_cxng/src/cx_sha256.c'),
    join_paths(sdk, 'lib_cxng/src/cx_sha3.c'),
    join_paths(sdk, 'lib_cxng/src/cx_sha512.c'),
    join_paths(sdk, 'lib_cxng/src/cx_utils.c'),
  ],
  include_directories: [
    inccxng,
    incos,
  ],
  pic: false,
  c_args: c_args,
)

incblewbxx = include_directories(
  join_paths(sdk, 'lib_blewbxx/core/'),
  join_paths(sdk, 'lib_blewbxx/core/auto/'),
  join_paths(sdk, 'lib_blewbxx/core/template/'),
  join_paths(sdk, 'lib_blewbxx_impl/include'),
)

libblewbxx = static_library(
  'blewbxx',
  sources: [
    join_paths(sdk, 'lib_blewbxx/core/auto/ble_gap_aci.c'),
    join_paths(sdk, 'lib_blewbxx/core/auto/ble_gatt_aci.c'),
    join_paths(sdk, 'lib_blewbxx/core/auto/ble_hal_aci.c'),
    join_paths(sdk, 'lib_blewbxx/core/auto/ble_hci_le.c'),
    join_paths(sdk, 'lib_blewbxx/core/auto/ble_l2cap_aci.c'),
    join_paths(sdk, 'lib_blewbxx/core/template/osal.c'),
    join_paths(sdk, 'lib_blewbxx_impl/src/ledger_ble.c'),
  ],
  include_directories: [
    incos,
    inccxng,
    incblewbxx,
  ],
  pic: false,
  c_args: c_args,
)

incnbgl = include_directories(join_paths(sdk, 'lib_nbgl/include'), join_paths(sdk, 'lib_ux_nbgl'))
libnbgl = static_library(
  'nbgl',
  sources: [
    #fonts
    glyphs_h,
    #lib_ux_nbgl
    join_paths(sdk, 'lib_ux_nbgl/ux.c'),
    #lib_nbgl
    join_paths(sdk, 'lib_nbgl/src/nbgl_buttons.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_draw.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_flow.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_fonts.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_layout.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_layout_keyboard.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_layout_keyboard_nanos.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_layout_keypad.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_layout_keypad_nanos.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_layout_nanos.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_layout_navigation.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_obj.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_obj_keyboard.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_obj_keyboard_nanos.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_obj_keypad.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_obj_keypad_nanos.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_obj_pool.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_page.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_screen.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_serialize.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_step.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_touch.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_use_case.c'),
    join_paths(sdk, 'lib_nbgl/src/nbgl_use_case_nanos.c'),
  ],
  include_directories: [incnbgl, incos, inccxng],
  pic: false,
  c_args: c_args,
)

incstusb = include_directories(
  join_paths(sdk, 'lib_stusb'),
  join_paths(sdk, 'lib_stusb_impl'),
  join_paths(sdk, 'lib_stusb/STM32_USB_Device_Library/Core/Inc/'),
  join_paths(sdk, 'lib_stusb/STM32_USB_Device_Library/Class/CCID/inc/'),
  join_paths(sdk, 'lib_stusb/STM32_USB_Device_Library/Class/HID/Inc'),
)

libstusb = static_library(
  'stusb',
  sources: [
    join_paths(sdk, 'lib_stusb/STM32_USB_Device_Library/Class/CCID/src/usbd_ccid_cmd.c'),
    join_paths(
      sdk,
      'lib_stusb/STM32_USB_Device_Library/Class/CCID/src/usbd_ccid_core.c',
    ),
    join_paths(sdk, 'lib_stusb/STM32_USB_Device_Library/Class/CCID/src/usbd_ccid_if.c'),
    join_paths(sdk, 'lib_stusb/STM32_USB_Device_Library/Class/HID/Src/usbd_hid.c'),
    join_paths(sdk, 'lib_stusb/STM32_USB_Device_Library/Core/Src/usbd_core.c'),
    join_paths(sdk, 'lib_stusb/STM32_USB_Device_Library/Core/Src/usbd_ctlreq.c'),
    join_paths(sdk, 'lib_stusb/STM32_USB_Device_Library/Core/Src/usbd_ioreq.c'),
    join_paths(sdk, 'lib_stusb/usbd_conf.c'),
    join_paths(sdk, 'lib_stusb_impl/u2f_impl.c'),
    join_paths(sdk, 'lib_stusb_impl/u2f_io.c'),
    join_paths(sdk, 'lib_stusb_impl/usbd_impl.c'),
  ],
  include_directories: [incstusb, incos, inccxng],
  pic: false,
  c_args: c_args,
)

libos_assembly = static_library(
  'os_assembly',
  sources: [
    join_paths(sdk, 'src/cx_stubs.S'),
    join_paths(sdk, 'src/stack_protector_init.S'),
    join_paths(sdk, 'src/svc_call.s'),
    join_paths(sdk, 'src/svc_cx_call.s'),
  ],
  include_directories: [incos],
  pic: false,
  c_args: c_args,
)

libos = static_library(
  'os',
  sources: [
    #App fonts
    glyphs_h,
    join_paths(sdk, 'src/app_metadata.c'),
    join_paths(sdk, 'src/checks.c'),
    join_paths(sdk, 'src/cx_hash_iovec.c'),
    join_paths(sdk, 'src/cx_wrappers.c'),
    join_paths(sdk, 'src/ledger_assert.c'),
    join_paths(sdk, 'src/ledger_protocol.c'),
    join_paths(sdk, 'src/os.c'),
    join_paths(sdk, 'src/os_io_nfc.c'),
    join_paths(sdk, 'src/os_io_seproxyhal.c'),
    join_paths(sdk, 'src/os_io_task.c'),
    join_paths(sdk, 'src/os_io_usb.c'),
    join_paths(sdk, 'src/pic.c'),
    join_paths(sdk, 'src/stack_protector.c'),
    join_paths(sdk, 'src/syscalls.c'),
  ],
  objects: libos_assembly.extract_all_objects(recursive: true),
  include_directories: [incos, inccxng, incnbgl, incblewbxx, incstusb, sdk],
  pic: false,
  c_args: c_args,
)

incstandard = include_directories(join_paths(sdk, 'lib_standard_app'))

libstandard = static_library(
  'standard',
  sources: [
    join_paths(sdk, 'lib_standard_app/read.c'),
    join_paths(sdk, 'lib_standard_app/app_storage.c'),
    join_paths(sdk, 'lib_standard_app/format.c'),
    join_paths(sdk, 'lib_standard_app/io.c'),
    join_paths(sdk, 'lib_standard_app/base58.c'),
    join_paths(sdk, 'lib_standard_app/bip32.c'),
    join_paths(sdk, 'lib_standard_app/crypto_helpers.c'),
    join_paths(sdk, 'lib_standard_app/write.c'),
    join_paths(sdk, 'lib_standard_app/varint.c'),
    join_paths(sdk, 'lib_standard_app/buffer.c'),
    join_paths(sdk, 'lib_standard_app/main.c'),
    join_paths(sdk, 'lib_standard_app/parser.c'),
    join_paths(sdk, 'lib_standard_app/swap_utils.c'),
  ],
  include_directories: [incos, inccxng, incnbgl],
  pic: false,
  c_args: c_args,
)

temp_args = ['-Wl,--verbose', '-Wl,--print-gc-sections']

if target in ['flex', 'nanosp', 'stax']
  stroot = join_paths(sdk, 'arch/st33k1/lib')
else
  stroot = join_paths(sdk, 'arch/st33/lib')
endif

cc = meson.get_compiler('c')
libm_st = cc.find_library('libc', dirs: [stroot])
libc_st = cc.find_library('libm', dirs: stroot)
libgcc_st = cc.find_library('libgcc', dirs: stroot)

app_elf = executable(
  'app.elf',
  sources: [
    #App fonts
    glyphs_h,
    glyphs_c,
    #App source code
    'src/transaction/utils.c',
    'src/transaction/serialize.c',
    'src/transaction/deserialize.c',
    'src/handler/get_public_key.c',
    'src/handler/sign_tx.c',
    'src/handler/get_app_name.c',
    'src/handler/get_version.c',
    'src/ui/nbgl_display_transaction.c',
    'src/ui/nbgl_display_address.c',
    'src/ui/bagl_display.c',
    'src/ui/menu_bagl.c',
    'src/ui/menu_nbgl.c',
    'src/ui/action/validate.c',
    'src/app_main.c',
    'src/helper/send_reponse.c',
    'src/address.c',
    'src/apdu/dispatcher.c',
  ],
  objects: libos.extract_all_objects(recursive: true),
  include_directories: ['src', incos, incstandard, inccxng, incnbgl],
  link_with: [libstandard, libcxng, libnbgl, libstusb, libblewbxx, libprintf],
  dependencies: [libm_st, libgcc_st, libc_st],
  link_args: link_args + ['-Wl,-Map=app.map'],
  c_args: c_args,
)

custom_target('app.map', depends: app_elf, output: 'app.map', command: 'id')

custom_target(
  'app.hex',
  command: [objcopy, '-O', 'ihex', '-S', '@INPUT0@', '@OUTPUT0@'],
  output: ['app.hex'],
  input: [app_elf],
)

custom_target(
  'app.apdu',
  command: [
    python3,
    '-m', 'ledgerblue.loadApp',
    '--offline', '@OUTPUT0@',
    '--appname', app_name,
    '--appVersion', app_version,
  ],
  output: ['app.apdu'],
)