typedef unsigned long size_t;
typedef struct _IO_FILE FILE;

extern int vfscanf(FILE *restrict stream, const char *restrict format, __builtin_va_list args);
extern long strtol(const char *restrict nptr, char **restrict endptr, int base);

int __isoc23_fscanf(FILE *restrict stream, const char *restrict format, ...) {
    __builtin_va_list args;
    __builtin_va_start(args, format);
    int ret = vfscanf(stream, format, args);
    __builtin_va_end(args);
    return ret;
}

long __isoc23_strtol(const char *restrict nptr, char **restrict endptr, int base) {
    return strtol(nptr, endptr, base);
}