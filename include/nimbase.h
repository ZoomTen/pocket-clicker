// Minimal nimbase.h targetting GBDK '20
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#define OLDCALL __sdcccall(0)
#define NONBANKED __nonbanked
#define N_LIB_PRIVATE
#define N_NIMCALL(rettype, name) rettype name
#define N_NIMCALL_PTR(rettype, name) rettype (*name)
#define N_RAW_NIMCALL
#define N_INLINE(rettype, name) inline rettype name
#define N_NOINLINE(rettype, name) rettype name
#define N_NOCONV(rettype, name) rettype name
#define N_CLOSURE(rettype, name) N_NIMCALL(rettype, name)
#define N_CLOSURE_PTR(rettype, name) N_NIMCALL_PTR(rettype, name)
#define N_CDECL(rettype, name) rettype name
typedef signed int NI;
typedef unsigned int NU;
typedef int8_t NI8;
typedef int16_t NI16;
typedef int32_t NI32;
typedef int64_t NI64;
#define IL64(x) (x)
typedef float NF;
typedef float NF32;
typedef uint8_t NU8;
typedef uint16_t NU16;
typedef uint32_t NU32;
typedef uint64_t NU64;
typedef char NIM_CHAR;
typedef char* NCSTRING;
#define NIM_BOOL bool
#define NIM_NIL 0
#define NIM_TRUE true
#define NIM_FALSE false
#define NIM_ALIGNOF(x) _Alignof(x)
#define NIM_CONST  const
#define SEQ_DECL_SIZE
#define NIM_STRLIT_FLAG ((NU)(1) << ((16) - 2))
#define NIM_LIKELY(x) (x)
#define NIM_UNLIKELY(x) (x)

// alias these functions at compiletime for now
#define fwrite(a,b,c,d) 0
#define fflush(a) 0

// these are added by os:any
// #define FILE void
// #define TFrame void
// #define stderr (void*)0
// + divulonglong, cannot use that
