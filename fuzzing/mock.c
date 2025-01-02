#include <stdbool.h>
#include <stdlib.h>

#include <os_helpers.h>

void assert_exit(bool confirm) {
    UNUSED(confirm);
    exit(1);
}

void *pic(void *addr) {
    return addr;
}