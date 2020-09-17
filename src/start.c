#include <sys/cdefs.h>
#include <string.h>

extern int main(void);

extern unsigned int _stack;
extern unsigned int _data_loadaddr;
extern unsigned int _data;
extern unsigned int _edata;
extern unsigned int _bss;
extern unsigned int _ebss;
extern unsigned int __init_array_start;
extern unsigned int __init_array_end;

/* Define a conventient type for cast integer ptr to function ptr */
typedef void (*func_t)(void);

__attribute__((naked))
void reset_handler(void)
{
    unsigned int *src;
    unsigned int *dst;

    /* Copy data from rom to ram */
    src = &_data_loadaddr;
    dst = &_data;
    while (dst < &_edata) {
        *dst++ = *src++;
    }

    /* Set to 0 all uninitialized data */
    dst = &_bss;
    while (dst < &_ebss) {
        *dst++ = 0;
    }

    /* Call all startup functions */
    for (src = &__init_array_start; src < &__init_array_end; src++) {
        ((func_t)src)();
    }

    main();

    while(1) {}
}


void hang_isr(void)
{
    while (1) {
    }
}

void pass_isr(void)
{
}

void *vector_core[] __attribute__((section(".vector_core"))) = {
    (void*) &_stack, /* Stack pointer */
    (void*) reset_handler, /* Reset */
    (void*) hang_isr, /* nmi */
    (void*) hang_isr, /* hardfault */
    (void*) hang_isr, /* memfault */
    (void*) hang_isr, /* busfault */
    (void*) hang_isr, /* usagefault */
    (void*) 0UL, /* reserved 4 */
    (void*) 0UL, /* reserved 5 */
    (void*) 0UL, /* reserved 6 */
    (void*) 0UL, /* reserved 7 */
    (void*) 0UL, /* reserved 8 */
    (void*) 0UL, /* reserved 9 */
    (void*) 0UL, /* reserved 10 */
    (void*) pass_isr, /* svc */
    (void*) pass_isr, /* debug monitor */
    (void*) 0UL, /* reserved_13 */
    (void*) pass_isr, /* pendsv */
    (void*) pass_isr, /* systick */
};
