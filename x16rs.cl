#ifndef X16RX_CL
#define X16RX_CL

#define DEBUG(x)

#if __ENDIAN_LITTLE__
  #define SPH_LITTLE_ENDIAN 1
#else
  #define SPH_BIG_ENDIAN 1
#endif

#define SPH_UPTR sph_u64

typedef unsigned int sph_u32;
typedef int sph_s32;
#ifndef __OPENCL_VERSION__
  typedef unsigned long long sph_u64;
  typedef long long sph_s64;
#else
  typedef unsigned long sph_u64;
  typedef long sph_s64;
#endif

#define SPH_64 1
#define SPH_64_TRUE 1

#define SPH_C32(x)    ((sph_u32)(x ## U))
#define SPH_T32(x) (as_uint(x))
#define SPH_ROTL32(x, n) rotate(as_uint(x), as_uint(n))
#define SPH_ROTR32(x, n)   SPH_ROTL32(x, (32 - (n)))

#define SPH_C64(x)    ((sph_u64)(x ## UL))
#define SPH_T64(x) (as_ulong(x))
#define SPH_ROTL64(x, n) rotate(as_ulong(x), (n) & 0xFFFFFFFFFFFFFFFFUL)
#define SPH_ROTR64(x, n)   SPH_ROTL64(x, (64 - (n)))

#define SPH_ECHO_64 1
#define SPH_KECCAK_64 1
#define SPH_JH_64 1
#define SPH_SIMD_NOCOPY 0
#define SPH_KECCAK_NOCOPY 0
#define SPH_SMALL_FOOTPRINT_GROESTL 0
#define SPH_GROESTL_BIG_ENDIAN 0
#define SPH_CUBEHASH_UNROLL 0

#ifndef SPH_COMPACT_BLAKE_64
  #define SPH_COMPACT_BLAKE_64 0
#endif
#ifndef SPH_LUFFA_PARALLEL
  #define SPH_LUFFA_PARALLEL 0
#endif
#ifndef SPH_KECCAK_UNROLL
  #define SPH_KECCAK_UNROLL 0
#endif
#ifndef SPH_HAMSI_EXPAND_BIG
  #define SPH_HAMSI_EXPAND_BIG 1
#endif

#include "blake.cl"
#include "bmw.cl"
#include "groestl.cl"
#include "skein.cl"
#include "jh.cl"
#include "keccak.cl"
#include "luffa.cl"
#include "cubehash.cl"
#include "shavite.cl"
#include "simd.cl"
#include "echo.cl"
#include "hamsi_help.cl"
#include "hamsi.cl"
#include "fugue.cl"
#include "shabal.cl"
#include "whirlpool.cl"
#include "sha2_512.cl"


#define SWAP4(x) as_uint(as_uchar4(x).wzyx)
#define SWAP8(x) as_ulong(as_uchar8(x).s76543210)

#if SPH_BIG_ENDIAN
  #define DEC64E(x) (x)
  #define DEC64BE(x) (*(const sph_u64 *) (x));
  #define DEC32LE(x) SWAP4(*(const sph_u32 *) (x));
#else
  #define DEC64E(x) SWAP8(x)
  #define DEC64BE(x) SWAP8(*(const sph_u64 *) (x));
  #define DEC32LE(x) (*(const sph_u32 *) (x));
#endif

#define SHL(x, n) ((x) << (n))
#define SHR(x, n) ((x) >> (n))

#define CONST_EXP2  q[i+0] + SPH_ROTL64(q[i+1], 5)  + q[i+2] + SPH_ROTL64(q[i+3], 11) + \
                    q[i+4] + SPH_ROTL64(q[i+5], 27) + q[i+6] + SPH_ROTL64(q[i+7], 32) + \
                    q[i+8] + SPH_ROTL64(q[i+9], 37) + q[i+10] + SPH_ROTL64(q[i+11], 43) + \
                    q[i+12] + SPH_ROTL64(q[i+13], 53) + (SHR(q[i+14],1) ^ q[i+14]) + (SHR(q[i+15],2) ^ q[i+15])

typedef union {
  unsigned char h1[64];
  uint h4[16];
  ulong h8[8];
} hash_t;

typedef union {
  unsigned char h1[32];
  uint h4[8];
  ulong h8[4];
} hash_32;

hash_32 cutout_hash_with_32(hash_t* hash) {
    hash_32 reshx;
    reshx.h8[0] = hash->h8[0];
    reshx.h8[1] = hash->h8[1];
    reshx.h8[2] = hash->h8[2];
    reshx.h8[3] = hash->h8[3];
    return reshx;
}

// blake
// void hash_x16rs_func_0(unsigned char* block, unsigned char* output)
void hash_x16rs_func_0(hash_t* hash)
{
    
    // hash_t hashobj;
    // hash_t* hash = &hashobj;

    // for(int i = 0; i < 32; i++)
    //     hash->h1[i] = block[i];
    

    // blake
    sph_u64 H0 = SPH_C64(0x6A09E667F3BCC908), H1 = SPH_C64(0xBB67AE8584CAA73B);
    sph_u64 H2 = SPH_C64(0x3C6EF372FE94F82B), H3 = SPH_C64(0xA54FF53A5F1D36F1);
    sph_u64 H4 = SPH_C64(0x510E527FADE682D1), H5 = SPH_C64(0x9B05688C2B3E6C1F);
    sph_u64 H6 = SPH_C64(0x1F83D9ABFB41BD6B), H7 = SPH_C64(0x5BE0CD19137E2179);
    sph_u64 S0 = 0, S1 = 0, S2 = 0, S3 = 0;
    // sph_u64 T0 = SPH_C64(0xFFFFFFFFFFFFFC00) + (80 << 3), T1 = 0xFFFFFFFFFFFFFFFF;
    sph_u64 T0 = SPH_C64(0x0000000000000100), T1 = 0;

    // if ((T0 = SPH_T64(T0 + 1024)) < 1024)
    // T1 = SPH_T64(T1 + 1);

    sph_u64 M0, M1, M2, M3, M4, M5, M6, M7;
    sph_u64 M8, M9, MA, MB, MC, MD, ME, MF;
    sph_u64 V0, V1, V2, V3, V4, V5, V6, V7;
    sph_u64 V8, V9, VA, VB, VC, VD, VE, VF;

    M0 = SWAP8(hash->h8[0]);
    M1 = SWAP8(hash->h8[1]);
    M2 = SWAP8(hash->h8[2]);
    M3 = SWAP8(hash->h8[3]);
    M4 = SPH_C64(0x8000000000000000);
    M5 = 0;
    M6 = 0;
    M7 = 0;
    M8 = 0;
    M9 = 0;
    MA = 0;
    MB = 0;
    MC = 0;
    MD = SPH_C64(0x0000000000000001);
    ME = 0;
    MF = SPH_C64(0x0000000000000100);

    COMPRESS64;

    hash->h8[0] = SWAP8(H0);
    hash->h8[1] = SWAP8(H1);
    hash->h8[2] = SWAP8(H2);
    hash->h8[3] = SWAP8(H3);
    hash->h8[4] = SWAP8(H4);
    hash->h8[5] = SWAP8(H5);
    hash->h8[6] = SWAP8(H6);
    hash->h8[7] = SWAP8(H7);


    // barrier(CLK_GLOBAL_MEM_FENCE);

}

// bmw
void hash_x16rs_func_1(hash_t* hash)
{
    // bmw
    sph_u64 BMW_H[16];

    #pragma unroll 16
    for(unsigned u = 0; u < 16; u++)
        BMW_H[u] = BMW_IV512[u];

    sph_u64 mv[16],q[32];
    sph_u64 tmp;

    mv[0] = hash->h8[0];
    mv[1] = hash->h8[1];
    mv[2] = hash->h8[2];
    mv[3] = hash->h8[3];
    mv[4] = SPH_C64(0x0000000000000080);
    mv[5] = 0;
    mv[6] = 0;
    mv[7] = 0;
    mv[8] = 0;
    mv[9] = 0;
    mv[10] = 0;
    mv[11] = 0;
    mv[12] = 0;
    mv[13] = 0;
    mv[14] = 0;
    mv[15] = SPH_C64(0x000000000000100);

    tmp = (mv[5] ^ BMW_H[5]) - (mv[7] ^ BMW_H[7]) + (mv[10] ^ BMW_H[10]) + (mv[13] ^ BMW_H[13]) + (mv[14] ^ BMW_H[14]);
    q[0] = (SHR(tmp, 1) ^ SHL(tmp, 3) ^ SPH_ROTL64(tmp, 4) ^ SPH_ROTL64(tmp, 37)) + BMW_H[1];
    tmp = (mv[6] ^ BMW_H[6]) - (mv[8] ^ BMW_H[8]) + (mv[11] ^ BMW_H[11]) + (mv[14] ^ BMW_H[14]) - (mv[15] ^ BMW_H[15]);
    q[1] = (SHR(tmp, 1) ^ SHL(tmp, 2) ^ SPH_ROTL64(tmp, 13) ^ SPH_ROTL64(tmp, 43)) + BMW_H[2];
    tmp = (mv[0] ^ BMW_H[0]) + (mv[7] ^ BMW_H[7]) + (mv[9] ^ BMW_H[9]) - (mv[12] ^ BMW_H[12]) + (mv[15] ^ BMW_H[15]);
    q[2] = (SHR(tmp, 2) ^ SHL(tmp, 1) ^ SPH_ROTL64(tmp, 19) ^ SPH_ROTL64(tmp, 53)) + BMW_H[3];
    tmp = (mv[0] ^ BMW_H[0]) - (mv[1] ^ BMW_H[1]) + (mv[8] ^ BMW_H[8]) - (mv[10] ^ BMW_H[10]) + (mv[13] ^ BMW_H[13]);
    q[3] = (SHR(tmp, 2) ^ SHL(tmp, 2) ^ SPH_ROTL64(tmp, 28) ^ SPH_ROTL64(tmp, 59)) + BMW_H[4];
    tmp = (mv[1] ^ BMW_H[1]) + (mv[2] ^ BMW_H[2]) + (mv[9] ^ BMW_H[9]) - (mv[11] ^ BMW_H[11]) - (mv[14] ^ BMW_H[14]);
    q[4] = (SHR(tmp, 1) ^ tmp) + BMW_H[5];
    tmp = (mv[3] ^ BMW_H[3]) - (mv[2] ^ BMW_H[2]) + (mv[10] ^ BMW_H[10]) - (mv[12] ^ BMW_H[12]) + (mv[15] ^ BMW_H[15]);
    q[5] = (SHR(tmp, 1) ^ SHL(tmp, 3) ^ SPH_ROTL64(tmp, 4) ^ SPH_ROTL64(tmp, 37)) + BMW_H[6];
    tmp = (mv[4] ^ BMW_H[4]) - (mv[0] ^ BMW_H[0]) - (mv[3] ^ BMW_H[3]) - (mv[11] ^ BMW_H[11]) + (mv[13] ^ BMW_H[13]);
    q[6] = (SHR(tmp, 1) ^ SHL(tmp, 2) ^ SPH_ROTL64(tmp, 13) ^ SPH_ROTL64(tmp, 43)) + BMW_H[7];
    tmp = (mv[1] ^ BMW_H[1]) - (mv[4] ^ BMW_H[4]) - (mv[5] ^ BMW_H[5]) - (mv[12] ^ BMW_H[12]) - (mv[14] ^ BMW_H[14]);
    q[7] = (SHR(tmp, 2) ^ SHL(tmp, 1) ^ SPH_ROTL64(tmp, 19) ^ SPH_ROTL64(tmp, 53)) + BMW_H[8];
    tmp = (mv[2] ^ BMW_H[2]) - (mv[5] ^ BMW_H[5]) - (mv[6] ^ BMW_H[6]) + (mv[13] ^ BMW_H[13]) - (mv[15] ^ BMW_H[15]);
    q[8] = (SHR(tmp, 2) ^ SHL(tmp, 2) ^ SPH_ROTL64(tmp, 28) ^ SPH_ROTL64(tmp, 59)) + BMW_H[9];
    tmp = (mv[0] ^ BMW_H[0]) - (mv[3] ^ BMW_H[3]) + (mv[6] ^ BMW_H[6]) - (mv[7] ^ BMW_H[7]) + (mv[14] ^ BMW_H[14]);
    q[9] = (SHR(tmp, 1) ^ tmp) + BMW_H[10];
    tmp = (mv[8] ^ BMW_H[8]) - (mv[1] ^ BMW_H[1]) - (mv[4] ^ BMW_H[4]) - (mv[7] ^ BMW_H[7]) + (mv[15] ^ BMW_H[15]);
    q[10] = (SHR(tmp, 1) ^ SHL(tmp, 3) ^ SPH_ROTL64(tmp, 4) ^ SPH_ROTL64(tmp, 37)) + BMW_H[11];
    tmp = (mv[8] ^ BMW_H[8]) - (mv[0] ^ BMW_H[0]) - (mv[2] ^ BMW_H[2]) - (mv[5] ^ BMW_H[5]) + (mv[9] ^ BMW_H[9]);
    q[11] = (SHR(tmp, 1) ^ SHL(tmp, 2) ^ SPH_ROTL64(tmp, 13) ^ SPH_ROTL64(tmp, 43)) + BMW_H[12];
    tmp = (mv[1] ^ BMW_H[1]) + (mv[3] ^ BMW_H[3]) - (mv[6] ^ BMW_H[6]) - (mv[9] ^ BMW_H[9]) + (mv[10] ^ BMW_H[10]);
    q[12] = (SHR(tmp, 2) ^ SHL(tmp, 1) ^ SPH_ROTL64(tmp, 19) ^ SPH_ROTL64(tmp, 53)) + BMW_H[13];
    tmp = (mv[2] ^ BMW_H[2]) + (mv[4] ^ BMW_H[4]) + (mv[7] ^ BMW_H[7]) + (mv[10] ^ BMW_H[10]) + (mv[11] ^ BMW_H[11]);
    q[13] = (SHR(tmp, 2) ^ SHL(tmp, 2) ^ SPH_ROTL64(tmp, 28) ^ SPH_ROTL64(tmp, 59)) + BMW_H[14];
    tmp = (mv[3] ^ BMW_H[3]) - (mv[5] ^ BMW_H[5]) + (mv[8] ^ BMW_H[8]) - (mv[11] ^ BMW_H[11]) - (mv[12] ^ BMW_H[12]);
    q[14] = (SHR(tmp, 1) ^ tmp) + BMW_H[15];
    tmp = (mv[12] ^ BMW_H[12]) - (mv[4] ^ BMW_H[4]) - (mv[6] ^ BMW_H[6]) - (mv[9] ^ BMW_H[9]) + (mv[13] ^ BMW_H[13]);
    q[15] = (SHR(tmp, 1) ^ SHL(tmp, 3) ^ SPH_ROTL64(tmp, 4) ^ SPH_ROTL64(tmp, 37)) + BMW_H[0];

    #pragma unroll 2
    for(int i=0;i<2;i++)
    {
        q[i+16] = 
        (SHR(q[i   ], 1) ^ SHL(q[i   ], 2) ^ SPH_ROTL64(q[i   ], 13) ^ SPH_ROTL64(q[i   ], 43)) +
        (SHR(q[i+ 1], 2) ^ SHL(q[i+ 1], 1) ^ SPH_ROTL64(q[i+ 1], 19) ^ SPH_ROTL64(q[i+ 1], 53)) +
        (SHR(q[i+ 2], 2) ^ SHL(q[i+ 2], 2) ^ SPH_ROTL64(q[i+ 2], 28) ^ SPH_ROTL64(q[i+ 2], 59)) +
        (SHR(q[i+ 3], 1) ^ SHL(q[i+ 3], 3) ^ SPH_ROTL64(q[i+ 3],  4) ^ SPH_ROTL64(q[i+ 3], 37)) +
        (SHR(q[i+ 4], 1) ^ SHL(q[i+ 4], 2) ^ SPH_ROTL64(q[i+ 4], 13) ^ SPH_ROTL64(q[i+ 4], 43)) +
        (SHR(q[i+ 5], 2) ^ SHL(q[i+ 5], 1) ^ SPH_ROTL64(q[i+ 5], 19) ^ SPH_ROTL64(q[i+ 5], 53)) +
        (SHR(q[i+ 6], 2) ^ SHL(q[i+ 6], 2) ^ SPH_ROTL64(q[i+ 6], 28) ^ SPH_ROTL64(q[i+ 6], 59)) +
        (SHR(q[i+ 7], 1) ^ SHL(q[i+ 7], 3) ^ SPH_ROTL64(q[i+ 7],  4) ^ SPH_ROTL64(q[i+ 7], 37)) +
        (SHR(q[i+ 8], 1) ^ SHL(q[i+ 8], 2) ^ SPH_ROTL64(q[i+ 8], 13) ^ SPH_ROTL64(q[i+ 8], 43)) +
        (SHR(q[i+ 9], 2) ^ SHL(q[i+ 9], 1) ^ SPH_ROTL64(q[i+ 9], 19) ^ SPH_ROTL64(q[i+ 9], 53)) +
        (SHR(q[i+10], 2) ^ SHL(q[i+10], 2) ^ SPH_ROTL64(q[i+10], 28) ^ SPH_ROTL64(q[i+10], 59)) +
        (SHR(q[i+11], 1) ^ SHL(q[i+11], 3) ^ SPH_ROTL64(q[i+11],  4) ^ SPH_ROTL64(q[i+11], 37)) +
        (SHR(q[i+12], 1) ^ SHL(q[i+12], 2) ^ SPH_ROTL64(q[i+12], 13) ^ SPH_ROTL64(q[i+12], 43)) +
        (SHR(q[i+13], 2) ^ SHL(q[i+13], 1) ^ SPH_ROTL64(q[i+13], 19) ^ SPH_ROTL64(q[i+13], 53)) +
        (SHR(q[i+14], 2) ^ SHL(q[i+14], 2) ^ SPH_ROTL64(q[i+14], 28) ^ SPH_ROTL64(q[i+14], 59)) +
        (SHR(q[i+15], 1) ^ SHL(q[i+15], 3) ^ SPH_ROTL64(q[i+15],  4) ^ SPH_ROTL64(q[i+15], 37)) +
        (( ((i+16)*(0x0555555555555555)) + SPH_ROTL64(mv[i], i+1) + SPH_ROTL64(mv[i+3], i+4) - SPH_ROTL64(mv[i+10], i+11) ) ^ BMW_H[i+7]);
    }


    #pragma unroll 4
    for(int i=2;i<6;i++)
    {
        q[i+16] = CONST_EXP2 +
        (( ((i+16)*(0x0555555555555555)) + SPH_ROTL64(mv[i], i+1) +
        SPH_ROTL64(mv[i+3], i+4) - SPH_ROTL64(mv[i+10], i+11) ) ^ BMW_H[i+7]);
    }

    #pragma unroll 3
    for(int i=6;i<9;i++)
    {
        q[i+16] = CONST_EXP2 +
        (( ((i+16)*(0x0555555555555555)) + SPH_ROTL64(mv[i], i+1) +
        SPH_ROTL64(mv[i+3], i+4) - SPH_ROTL64(mv[i-6], (i-6)+1) ) ^ BMW_H[i+7]);
    }

    #pragma unroll 4
    for(int i=9;i<13;i++)
    {
        q[i+16] = CONST_EXP2 +
        (( ((i+16)*(0x0555555555555555)) + SPH_ROTL64(mv[i], i+1) +
        SPH_ROTL64(mv[i+3], i+4) - SPH_ROTL64(mv[i-6], (i-6)+1) ) ^ BMW_H[i-9]);
    }

    #pragma unroll 3
    for(int i=13;i<16;i++)
    {
        q[i+16] = CONST_EXP2 +
        (( ((i+16)*(0x0555555555555555)) + SPH_ROTL64(mv[i], i+1) +
        SPH_ROTL64(mv[i-13], (i-13)+1) - SPH_ROTL64(mv[i-6], (i-6)+1) ) ^ BMW_H[i-9]);
    }

    sph_u64 XL64 = q[16]^q[17]^q[18]^q[19]^q[20]^q[21]^q[22]^q[23];
    sph_u64 XH64 = XL64^q[24]^q[25]^q[26]^q[27]^q[28]^q[29]^q[30]^q[31];

    BMW_H[0] = (SHL(XH64, 5) ^ SHR(q[16],5) ^ mv[0]) + ( XL64 ^ q[24] ^ q[0]);
    BMW_H[1] = (SHR(XH64, 7) ^ SHL(q[17],8) ^ mv[1]) + ( XL64 ^ q[25] ^ q[1]);
    BMW_H[2] = (SHR(XH64, 5) ^ SHL(q[18],5) ^ mv[2]) + ( XL64 ^ q[26] ^ q[2]);
    BMW_H[3] = (SHR(XH64, 1) ^ SHL(q[19],5) ^ mv[3]) + ( XL64 ^ q[27] ^ q[3]);
    BMW_H[4] = (SHR(XH64, 3) ^ q[20] ^ mv[4]) + ( XL64 ^ q[28] ^ q[4]);
    BMW_H[5] = (SHL(XH64, 6) ^ SHR(q[21],6) ^ mv[5]) + ( XL64 ^ q[29] ^ q[5]);
    BMW_H[6] = (SHR(XH64, 4) ^ SHL(q[22],6) ^ mv[6]) + ( XL64 ^ q[30] ^ q[6]);
    BMW_H[7] = (SHR(XH64,11) ^ SHL(q[23],2) ^ mv[7]) + ( XL64 ^ q[31] ^ q[7]);

    BMW_H[8] = SPH_ROTL64(BMW_H[4], 9) + ( XH64 ^ q[24] ^ mv[8]) + (SHL(XL64,8) ^ q[23] ^ q[8]);
    BMW_H[9] = SPH_ROTL64(BMW_H[5],10) + ( XH64 ^ q[25] ^ mv[9]) + (SHR(XL64,6) ^ q[16] ^ q[9]);
    BMW_H[10] = SPH_ROTL64(BMW_H[6],11) + ( XH64 ^ q[26] ^ mv[10]) + (SHL(XL64,6) ^ q[17] ^ q[10]);
    BMW_H[11] = SPH_ROTL64(BMW_H[7],12) + ( XH64 ^ q[27] ^ mv[11]) + (SHL(XL64,4) ^ q[18] ^ q[11]);
    BMW_H[12] = SPH_ROTL64(BMW_H[0],13) + ( XH64 ^ q[28] ^ mv[12]) + (SHR(XL64,3) ^ q[19] ^ q[12]);
    BMW_H[13] = SPH_ROTL64(BMW_H[1],14) + ( XH64 ^ q[29] ^ mv[13]) + (SHR(XL64,4) ^ q[20] ^ q[13]);
    BMW_H[14] = SPH_ROTL64(BMW_H[2],15) + ( XH64 ^ q[30] ^ mv[14]) + (SHR(XL64,7) ^ q[21] ^ q[14]);
    BMW_H[15] = SPH_ROTL64(BMW_H[3],16) + ( XH64 ^ q[31] ^ mv[15]) + (SHR(XL64,2) ^ q[22] ^ q[15]);

    #pragma unroll 16
    for(int i=0;i<16;i++)
    {
        mv[i] = BMW_H[i];
        BMW_H[i] = 0xaaaaaaaaaaaaaaa0 + (sph_u64)i;
    }

    tmp = (mv[5] ^ BMW_H[5]) - (mv[7] ^ BMW_H[7]) + (mv[10] ^ BMW_H[10]) + (mv[13] ^ BMW_H[13]) + (mv[14] ^ BMW_H[14]);
    q[0] = (SHR(tmp, 1) ^ SHL(tmp, 3) ^ SPH_ROTL64(tmp, 4) ^ SPH_ROTL64(tmp, 37)) + BMW_H[1];
    tmp = (mv[6] ^ BMW_H[6]) - (mv[8] ^ BMW_H[8]) + (mv[11] ^ BMW_H[11]) + (mv[14] ^ BMW_H[14]) - (mv[15] ^ BMW_H[15]);
    q[1] = (SHR(tmp, 1) ^ SHL(tmp, 2) ^ SPH_ROTL64(tmp, 13) ^ SPH_ROTL64(tmp, 43)) + BMW_H[2];
    tmp = (mv[0] ^ BMW_H[0]) + (mv[7] ^ BMW_H[7]) + (mv[9] ^ BMW_H[9]) - (mv[12] ^ BMW_H[12]) + (mv[15] ^ BMW_H[15]);
    q[2] = (SHR(tmp, 2) ^ SHL(tmp, 1) ^ SPH_ROTL64(tmp, 19) ^ SPH_ROTL64(tmp, 53)) + BMW_H[3];
    tmp = (mv[0] ^ BMW_H[0]) - (mv[1] ^ BMW_H[1]) + (mv[8] ^ BMW_H[8]) - (mv[10] ^ BMW_H[10]) + (mv[13] ^ BMW_H[13]);
    q[3] = (SHR(tmp, 2) ^ SHL(tmp, 2) ^ SPH_ROTL64(tmp, 28) ^ SPH_ROTL64(tmp, 59)) + BMW_H[4];
    tmp = (mv[1] ^ BMW_H[1]) + (mv[2] ^ BMW_H[2]) + (mv[9] ^ BMW_H[9]) - (mv[11] ^ BMW_H[11]) - (mv[14] ^ BMW_H[14]);
    q[4] = (SHR(tmp, 1) ^ tmp) + BMW_H[5];
    tmp = (mv[3] ^ BMW_H[3]) - (mv[2] ^ BMW_H[2]) + (mv[10] ^ BMW_H[10]) - (mv[12] ^ BMW_H[12]) + (mv[15] ^ BMW_H[15]);
    q[5] = (SHR(tmp, 1) ^ SHL(tmp, 3) ^ SPH_ROTL64(tmp, 4) ^ SPH_ROTL64(tmp, 37)) + BMW_H[6];
    tmp = (mv[4] ^ BMW_H[4]) - (mv[0] ^ BMW_H[0]) - (mv[3] ^ BMW_H[3]) - (mv[11] ^ BMW_H[11]) + (mv[13] ^ BMW_H[13]);
    q[6] = (SHR(tmp, 1) ^ SHL(tmp, 2) ^ SPH_ROTL64(tmp, 13) ^ SPH_ROTL64(tmp, 43)) + BMW_H[7];
    tmp = (mv[1] ^ BMW_H[1]) - (mv[4] ^ BMW_H[4]) - (mv[5] ^ BMW_H[5]) - (mv[12] ^ BMW_H[12]) - (mv[14] ^ BMW_H[14]);
    q[7] = (SHR(tmp, 2) ^ SHL(tmp, 1) ^ SPH_ROTL64(tmp, 19) ^ SPH_ROTL64(tmp, 53)) + BMW_H[8];
    tmp = (mv[2] ^ BMW_H[2]) - (mv[5] ^ BMW_H[5]) - (mv[6] ^ BMW_H[6]) + (mv[13] ^ BMW_H[13]) - (mv[15] ^ BMW_H[15]);
    q[8] = (SHR(tmp, 2) ^ SHL(tmp, 2) ^ SPH_ROTL64(tmp, 28) ^ SPH_ROTL64(tmp, 59)) + BMW_H[9];
    tmp = (mv[0] ^ BMW_H[0]) - (mv[3] ^ BMW_H[3]) + (mv[6] ^ BMW_H[6]) - (mv[7] ^ BMW_H[7]) + (mv[14] ^ BMW_H[14]);
    q[9] = (SHR(tmp, 1) ^ tmp) + BMW_H[10];
    tmp = (mv[8] ^ BMW_H[8]) - (mv[1] ^ BMW_H[1]) - (mv[4] ^ BMW_H[4]) - (mv[7] ^ BMW_H[7]) + (mv[15] ^ BMW_H[15]);
    q[10] = (SHR(tmp, 1) ^ SHL(tmp, 3) ^ SPH_ROTL64(tmp, 4) ^ SPH_ROTL64(tmp, 37)) + BMW_H[11];
    tmp = (mv[8] ^ BMW_H[8]) - (mv[0] ^ BMW_H[0]) - (mv[2] ^ BMW_H[2]) - (mv[5] ^ BMW_H[5]) + (mv[9] ^ BMW_H[9]);
    q[11] = (SHR(tmp, 1) ^ SHL(tmp, 2) ^ SPH_ROTL64(tmp, 13) ^ SPH_ROTL64(tmp, 43)) + BMW_H[12];
    tmp = (mv[1] ^ BMW_H[1]) + (mv[3] ^ BMW_H[3]) - (mv[6] ^ BMW_H[6]) - (mv[9] ^ BMW_H[9]) + (mv[10] ^ BMW_H[10]);
    q[12] = (SHR(tmp, 2) ^ SHL(tmp, 1) ^ SPH_ROTL64(tmp, 19) ^ SPH_ROTL64(tmp, 53)) + BMW_H[13];
    tmp = (mv[2] ^ BMW_H[2]) + (mv[4] ^ BMW_H[4]) + (mv[7] ^ BMW_H[7]) + (mv[10] ^ BMW_H[10]) + (mv[11] ^ BMW_H[11]);
    q[13] = (SHR(tmp, 2) ^ SHL(tmp, 2) ^ SPH_ROTL64(tmp, 28) ^ SPH_ROTL64(tmp, 59)) + BMW_H[14];
    tmp = (mv[3] ^ BMW_H[3]) - (mv[5] ^ BMW_H[5]) + (mv[8] ^ BMW_H[8]) - (mv[11] ^ BMW_H[11]) - (mv[12] ^ BMW_H[12]);
    q[14] = (SHR(tmp, 1) ^ tmp) + BMW_H[15];
    tmp = (mv[12] ^ BMW_H[12]) - (mv[4] ^ BMW_H[4]) - (mv[6] ^ BMW_H[6]) - (mv[9] ^ BMW_H[9]) + (mv[13] ^ BMW_H[13]);
    q[15] = (SHR(tmp, 1) ^ SHL(tmp, 3) ^ SPH_ROTL64(tmp, 4) ^ SPH_ROTL64(tmp, 37)) + BMW_H[0];

    #pragma unroll 2
    for(int i=0;i<2;i++)
    {
        q[i+16] =
        (SHR(q[i], 1) ^ SHL(q[i], 2) ^ SPH_ROTL64(q[i], 13) ^ SPH_ROTL64(q[i], 43)) +
        (SHR(q[i+1], 2) ^ SHL(q[i+1], 1) ^ SPH_ROTL64(q[i+1], 19) ^ SPH_ROTL64(q[i+1], 53)) +
        (SHR(q[i+2], 2) ^ SHL(q[i+2], 2) ^ SPH_ROTL64(q[i+2], 28) ^ SPH_ROTL64(q[i+2], 59)) +
        (SHR(q[i+3], 1) ^ SHL(q[i+3], 3) ^ SPH_ROTL64(q[i+3], 4) ^ SPH_ROTL64(q[i+3], 37)) +
        (SHR(q[i+4], 1) ^ SHL(q[i+4], 2) ^ SPH_ROTL64(q[i+4], 13) ^ SPH_ROTL64(q[i+4], 43)) +
        (SHR(q[i+5], 2) ^ SHL(q[i+5], 1) ^ SPH_ROTL64(q[i+5], 19) ^ SPH_ROTL64(q[i+5], 53)) +
        (SHR(q[i+6], 2) ^ SHL(q[i+6], 2) ^ SPH_ROTL64(q[i+6], 28) ^ SPH_ROTL64(q[i+6], 59)) +
        (SHR(q[i+7], 1) ^ SHL(q[i+7], 3) ^ SPH_ROTL64(q[i+7], 4) ^ SPH_ROTL64(q[i+7], 37)) +
        (SHR(q[i+8], 1) ^ SHL(q[i+8], 2) ^ SPH_ROTL64(q[i+8], 13) ^ SPH_ROTL64(q[i+8], 43)) +
        (SHR(q[i+9], 2) ^ SHL(q[i+9], 1) ^ SPH_ROTL64(q[i+9], 19) ^ SPH_ROTL64(q[i+9], 53)) +
        (SHR(q[i+10], 2) ^ SHL(q[i+10], 2) ^ SPH_ROTL64(q[i+10], 28) ^ SPH_ROTL64(q[i+10], 59)) +
        (SHR(q[i+11], 1) ^ SHL(q[i+11], 3) ^ SPH_ROTL64(q[i+11], 4) ^ SPH_ROTL64(q[i+11], 37)) +
        (SHR(q[i+12], 1) ^ SHL(q[i+12], 2) ^ SPH_ROTL64(q[i+12], 13) ^ SPH_ROTL64(q[i+12], 43)) +
        (SHR(q[i+13], 2) ^ SHL(q[i+13], 1) ^ SPH_ROTL64(q[i+13], 19) ^ SPH_ROTL64(q[i+13], 53)) +
        (SHR(q[i+14], 2) ^ SHL(q[i+14], 2) ^ SPH_ROTL64(q[i+14], 28) ^ SPH_ROTL64(q[i+14], 59)) +
        (SHR(q[i+15], 1) ^ SHL(q[i+15], 3) ^ SPH_ROTL64(q[i+15], 4) ^ SPH_ROTL64(q[i+15], 37)) +
        (( ((i+16)*(0x0555555555555555)) + SPH_ROTL64(mv[i], i+1) +
        SPH_ROTL64(mv[i+3], i+4) - SPH_ROTL64(mv[i+10], i+11) ) ^ BMW_H[i+7]);
    }

    #pragma unroll 4
    for(int i=2;i<6;i++)
    {
        q[i+16] = CONST_EXP2 +
        (( ((i+16)*(0x0555555555555555)) + SPH_ROTL64(mv[i], i+1) +
        SPH_ROTL64(mv[i+3], i+4) - SPH_ROTL64(mv[i+10], i+11) ) ^ BMW_H[i+7]);
    }

    #pragma unroll 3
    for(int i=6;i<9;i++)
    {
        q[i+16] = CONST_EXP2 +
        (( ((i+16)*(0x0555555555555555)) + SPH_ROTL64(mv[i], i+1) +
        SPH_ROTL64(mv[i+3], i+4) - SPH_ROTL64(mv[i-6], (i-6)+1) ) ^ BMW_H[i+7]);
    }

    #pragma unroll 4
    for(int i=9;i<13;i++)
    {
        q[i+16] = CONST_EXP2 +
        (( ((i+16)*(0x0555555555555555)) + SPH_ROTL64(mv[i], i+1) +
        SPH_ROTL64(mv[i+3], i+4) - SPH_ROTL64(mv[i-6], (i-6)+1) ) ^ BMW_H[i-9]);
    }

    #pragma unroll 3
    for(int i=13;i<16;i++)
    {
        q[i+16] = CONST_EXP2 +
        (( ((i+16)*(0x0555555555555555)) + SPH_ROTL64(mv[i], i+1) +
        SPH_ROTL64(mv[i-13], (i-13)+1) - SPH_ROTL64(mv[i-6], (i-6)+1) ) ^ BMW_H[i-9]);
    }

    XL64 = q[16]^q[17]^q[18]^q[19]^q[20]^q[21]^q[22]^q[23];
    XH64 = XL64^q[24]^q[25]^q[26]^q[27]^q[28]^q[29]^q[30]^q[31];

    BMW_H[0] = (SHL(XH64, 5) ^ SHR(q[16],5) ^ mv[0]) + ( XL64 ^ q[24] ^ q[0]);
    BMW_H[1] = (SHR(XH64, 7) ^ SHL(q[17],8) ^ mv[1]) + ( XL64 ^ q[25] ^ q[1]);
    BMW_H[2] = (SHR(XH64, 5) ^ SHL(q[18],5) ^ mv[2]) + ( XL64 ^ q[26] ^ q[2]);
    BMW_H[3] = (SHR(XH64, 1) ^ SHL(q[19],5) ^ mv[3]) + ( XL64 ^ q[27] ^ q[3]);
    BMW_H[4] = (SHR(XH64, 3) ^ q[20] ^ mv[4]) + ( XL64 ^ q[28] ^ q[4]);
    BMW_H[5] = (SHL(XH64, 6) ^ SHR(q[21],6) ^ mv[5]) + ( XL64 ^ q[29] ^ q[5]);
    BMW_H[6] = (SHR(XH64, 4) ^ SHL(q[22],6) ^ mv[6]) + ( XL64 ^ q[30] ^ q[6]);
    BMW_H[7] = (SHR(XH64,11) ^ SHL(q[23],2) ^ mv[7]) + ( XL64 ^ q[31] ^ q[7]);

    BMW_H[8] = SPH_ROTL64(BMW_H[4], 9) + ( XH64 ^ q[24] ^ mv[8]) + (SHL(XL64,8) ^ q[23] ^ q[8]);
    BMW_H[9] = SPH_ROTL64(BMW_H[5],10) + ( XH64 ^ q[25] ^ mv[9]) + (SHR(XL64,6) ^ q[16] ^ q[9]);
    BMW_H[10] = SPH_ROTL64(BMW_H[6],11) + ( XH64 ^ q[26] ^ mv[10]) + (SHL(XL64,6) ^ q[17] ^ q[10]);
    BMW_H[11] = SPH_ROTL64(BMW_H[7],12) + ( XH64 ^ q[27] ^ mv[11]) + (SHL(XL64,4) ^ q[18] ^ q[11]);
    BMW_H[12] = SPH_ROTL64(BMW_H[0],13) + ( XH64 ^ q[28] ^ mv[12]) + (SHR(XL64,3) ^ q[19] ^ q[12]);
    BMW_H[13] = SPH_ROTL64(BMW_H[1],14) + ( XH64 ^ q[29] ^ mv[13]) + (SHR(XL64,4) ^ q[20] ^ q[13]);
    BMW_H[14] = SPH_ROTL64(BMW_H[2],15) + ( XH64 ^ q[30] ^ mv[14]) + (SHR(XL64,7) ^ q[21] ^ q[14]);
    BMW_H[15] = SPH_ROTL64(BMW_H[3],16) + ( XH64 ^ q[31] ^ mv[15]) + (SHR(XL64,2) ^ q[22] ^ q[15]);

    // copy
    hash->h8[0] = BMW_H[8];
    hash->h8[1] = BMW_H[9];
    hash->h8[2] = BMW_H[10];
    hash->h8[3] = BMW_H[11];
    hash->h8[4] = BMW_H[12];
    hash->h8[5] = BMW_H[13];
    hash->h8[6] = BMW_H[14];
    hash->h8[7] = BMW_H[15];


    //   barrier(CLK_GLOBAL_MEM_FENCE);

}

// groestl
void hash_x16rs_func_2(hash_t* hash)
{
    // groestl

    sph_u64 H[16];
    //#pragma unroll 15
    for (unsigned int u = 0; u < 15; u ++)
    H[u] = 0;
    #if USE_LE
    H[15] = ((sph_u64)(512 & 0xFF) << 56) | ((sph_u64)(512 & 0xFF00) << 40);
    #else
    H[15] = (sph_u64)512;
    #endif

    sph_u64 g[16], m[16];
    m[0] = hash->h8[0];
    m[1] = hash->h8[1];
    m[2] = hash->h8[2];
    m[3] = hash->h8[3];
    m[4] = SPH_C64(0x0000000000000080);
    m[5] = 0;
    m[6] = 0;
    m[7] = 0;
    m[8] = 0;
    m[9] = 0;
    m[10] = 0;
    m[11] = 0;
    m[12] = 0;
    m[13] = 0;
    m[14] = 0;
    m[15] = SPH_C64(0x0100000000000000);

    #pragma unroll 16
    for (unsigned int u = 0; u < 16; u ++)
        g[u] = m[u] ^ H[u];
    g[8] = m[8] ^ H[8];
    g[9] = m[9] ^ H[9];
    g[10] = m[10] ^ H[10];
    g[11] = m[11] ^ H[11];
    g[12] = m[12] ^ H[12];
    g[13] = m[13] ^ H[13];
    g[14] = m[14] ^ H[14];
    g[15] = m[15] ^ H[15];

    PERM_BIG_P(g);
    PERM_BIG_Q(m);



    //#pragma unroll 16
    for (unsigned int u = 0; u < 16; u ++)
        H[u] ^= g[u] ^ m[u];

    sph_u64 xH[16];

    //#pragma unroll 16
    for (unsigned int u = 0; u < 16; u ++)
        xH[u] = H[u];

    PERM_BIG_P(xH);

    //#pragma unroll 16
    for (unsigned int u = 0; u < 16; u ++)
        H[u] ^= xH[u];

    //#pragma unroll 8
    for (unsigned int u = 0; u < 8; u ++)
        hash->h8[u] = H[u + 8];

    // barrier(CLK_GLOBAL_MEM_FENCE);


}

// jh
void hash_x16rs_func_3(hash_t* hash)
{
    // jh
    sph_u64 h0h = C64e(0x6fd14b963e00aa17), h0l = C64e(0x636a2e057a15d543), h1h = C64e(0x8a225e8d0c97ef0b), h1l = C64e(0xe9341259f2b3c361), h2h = C64e(0x891da0c1536f801e), h2l = C64e(0x2aa9056bea2b6d80), h3h = C64e(0x588eccdb2075baa6), h3l = C64e(0xa90f3a76baf83bf7);
    sph_u64 h4h = C64e(0x0169e60541e34a69), h4l = C64e(0x46b58a8e2e6fe65a), h5h = C64e(0x1047a7d0c1843c24), h5l = C64e(0x3b6e71b12d5ac199), h6h = C64e(0xcf57f6ec9db1f856), h6l = C64e(0xa706887c5716b156), h7h = C64e(0xe3c2fcdfe68517fb), h7l = C64e(0x545a4678cc8cdd4b);
    sph_u64 tmp;

    for(int i = 0; i < 2; i++)
    {
        if (i == 0)
        {
            h0h ^= hash->h8[0];
            h0l ^= hash->h8[1];
            h1h ^= hash->h8[2];
            h1l ^= hash->h8[3];
            h2h ^= SPH_C64(0x0000000000000080);
            h2l ^= 0;
            h3h ^= 0;
            h3l ^= 0;
        }
        else if(i == 1)
        {
            h0h ^= 0;
            h0l ^= 0;
            h1h ^= 0;
            h1l ^= 0;
            h2h ^= 0;
            h2l ^= 0;
            h3h ^= 0;
            h3l ^= SPH_C64(0x0001000000000000);
        }

        E8;

        if (i == 0)
        {
            h4h ^= hash->h8[0];
            h4l ^= hash->h8[1];
            h5h ^= hash->h8[2];
            h5l ^= hash->h8[3];
            h6h ^= SPH_C64(0x0000000000000080);
            h6l ^= 0;
            h7h ^= 0;
            h7l ^= 0;
        }
        else if(i == 1)
        {
            h4h ^= 0;
            h4l ^= 0;
            h5h ^= 0;
            h5l ^= 0;
            h6h ^= 0;
            h6l ^= 0;
            h7h ^= 0;
            h7l ^= SPH_C64(0x0001000000000000);
        }


    }

    hash->h8[0] = h4h;
    hash->h8[1] = h4l;
    hash->h8[2] = h5h;
    hash->h8[3] = h5l;
    hash->h8[4] = h6h;
    hash->h8[5] = h6l;
    hash->h8[6] = h7h;
    hash->h8[7] = h7l;

    // barrier(CLK_GLOBAL_MEM_FENCE);



}

// keccak
void hash_x16rs_func_4(hash_t* hash)
{
    // keccak
    sph_u64 a00 = 0, a01 = 0, a02 = 0, a03 = 0, a04 = 0;
    sph_u64 a10 = 0, a11 = 0, a12 = 0, a13 = 0, a14 = 0;
    sph_u64 a20 = 0, a21 = 0, a22 = 0, a23 = 0, a24 = 0;
    sph_u64 a30 = 0, a31 = 0, a32 = 0, a33 = 0, a34 = 0;
    sph_u64 a40 = 0, a41 = 0, a42 = 0, a43 = 0, a44 = 0;

    a10 = SPH_C64(0xFFFFFFFFFFFFFFFF);
    a20 = SPH_C64(0xFFFFFFFFFFFFFFFF);
    a31 = SPH_C64(0xFFFFFFFFFFFFFFFF);
    a22 = SPH_C64(0xFFFFFFFFFFFFFFFF);
    a23 = SPH_C64(0xFFFFFFFFFFFFFFFF);
    a04 = SPH_C64(0xFFFFFFFFFFFFFFFF);

    a00 ^= hash->h8[0];
    a10 ^= hash->h8[1];
    a20 ^= hash->h8[2];
    a30 ^= hash->h8[3];
    a40 ^= SPH_C64(0x000000000000001);
    a01 ^= 0;
    a11 ^= 0;
    a21 ^= 0;
    a31 ^= 0x8000000000000000;

    KECCAK_F_1600;

    // Finalize the "lane complement"
    a10 = ~a10;
    a20 = ~a20;

    hash->h8[0] = a00;
    hash->h8[1] = a10;
    hash->h8[2] = a20;
    hash->h8[3] = a30;
    hash->h8[4] = a40;
    hash->h8[5] = a01;
    hash->h8[6] = a11;
    hash->h8[7] = a21;

    // barrier(CLK_GLOBAL_MEM_FENCE);

}

// skein
void hash_x16rs_func_5(hash_t* hash)
{
    // skein
    sph_u64 h0 = SPH_C64(0x4903ADFF749C51CE), h1 = SPH_C64(0x0D95DE399746DF03), 
    h2 = SPH_C64(0x8FD1934127C79BCE), h3 = SPH_C64(0x9A255629FF352CB1), 
    h4 = SPH_C64(0x5DB62599DF6CA7B0), h5 = SPH_C64(0xEABE394CA9D5C3F4), 
    h6 = SPH_C64(0x991112C71A75B523), h7 = SPH_C64(0xAE18A40B660FCC33);
    sph_u64 m0, m1, m2, m3, m4, m5, m6, m7;
    sph_u64 bcount = 0;


    m0 = hash->h8[0];
    m1 = hash->h8[1];
    m2 = hash->h8[2];
    m3 = hash->h8[3];
    m4 = 0;
    m5 = 0;
    m6 = 0;
    m7 = 0;

    UBI_BIG(480, 32); // 64 => 43

    bcount = 0;
    m0 = m1 = m2 = m3 = m4 = m5 = m6 = m7 = 0;

    UBI_BIG(510, 8);

    hash->h8[0] = h0;
    hash->h8[1] = h1;
    hash->h8[2] = h2;
    hash->h8[3] = h3;
    hash->h8[4] = h4;
    hash->h8[5] = h5;
    hash->h8[6] = h6;
    hash->h8[7] = h7;

    // barrier(CLK_GLOBAL_MEM_FENCE);
}

// luffa
void hash_x16rs_func_6(hash_t* hash)
{

    // luffa
    sph_u32 V00 = SPH_C32(0x6d251e69), V01 = SPH_C32(0x44b051e0), V02 = SPH_C32(0x4eaa6fb4), V03 = SPH_C32(0xdbf78465), V04 = SPH_C32(0x6e292011), V05 = SPH_C32(0x90152df4), V06 = SPH_C32(0xee058139), V07 = SPH_C32(0xdef610bb);
    sph_u32 V10 = SPH_C32(0xc3b44b95), V11 = SPH_C32(0xd9d2f256), V12 = SPH_C32(0x70eee9a0), V13 = SPH_C32(0xde099fa3), V14 = SPH_C32(0x5d9b0557), V15 = SPH_C32(0x8fc944b3), V16 = SPH_C32(0xcf1ccf0e), V17 = SPH_C32(0x746cd581);
    sph_u32 V20 = SPH_C32(0xf7efc89d), V21 = SPH_C32(0x5dba5781), V22 = SPH_C32(0x04016ce5), V23 = SPH_C32(0xad659c05), V24 = SPH_C32(0x0306194f), V25 = SPH_C32(0x666d1836), V26 = SPH_C32(0x24aa230a), V27 = SPH_C32(0x8b264ae7);
    sph_u32 V30 = SPH_C32(0x858075d5), V31 = SPH_C32(0x36d79cce), V32 = SPH_C32(0xe571f7d7), V33 = SPH_C32(0x204b1f67), V34 = SPH_C32(0x35870c6a), V35 = SPH_C32(0x57e9e923), V36 = SPH_C32(0x14bcb808), V37 = SPH_C32(0x7cde72ce);
    sph_u32 V40 = SPH_C32(0x6c68e9be), V41 = SPH_C32(0x5ec41e22), V42 = SPH_C32(0xc825b7c7), V43 = SPH_C32(0xaffb4363), V44 = SPH_C32(0xf5df3999), V45 = SPH_C32(0x0fc688f1), V46 = SPH_C32(0xb07224cc), V47 = SPH_C32(0x03e86cea);

    DECL_TMP8(M);


    for(uint i = 0; i < 5; i++)
    {

        if(i == 0)
        {
            M0 = SWAP4(hash->h4[0]);
            M1 = SWAP4(hash->h4[1]);
            M2 = SWAP4(hash->h4[2]);
            M3 = SWAP4(hash->h4[3]);
            M4 = SWAP4(hash->h4[4]);
            M5 = SWAP4(hash->h4[5]);
            M6 = SWAP4(hash->h4[6]);
            M7 = SWAP4(hash->h4[7]);
        }
        else if(i == 1)
        {
            M0 = SPH_C32(0x80000000);
            M1 = M2 = M3 = M4 = M5 = M6 = M7 = 0;
        }
        else if(i == 2)
        {
            M0 = M1 = M2 = M3 = M4 = M5 = M6 = M7 = 0;
        }
        else if(i == 3)
        {
            hash->h4[0] = SWAP4(V00 ^ V10 ^ V20 ^ V30 ^ V40);
            hash->h4[1] = SWAP4(V01 ^ V11 ^ V21 ^ V31 ^ V41);
            hash->h4[2] = SWAP4(V02 ^ V12 ^ V22 ^ V32 ^ V42);
            hash->h4[3] = SWAP4(V03 ^ V13 ^ V23 ^ V33 ^ V43);
            hash->h4[4] = SWAP4(V04 ^ V14 ^ V24 ^ V34 ^ V44);
            hash->h4[5] = SWAP4( V05 ^ V15 ^ V25 ^ V35 ^ V45);
            hash->h4[6] = SWAP4(V06 ^ V16 ^ V26 ^ V36 ^ V46);
            hash->h4[7] = SWAP4(V07 ^ V17 ^ V27 ^ V37 ^ V47);
        }
        // else if(i == 4)
        // {
        //     hash->h4[8] = SWAP4(V00 ^ V10 ^ V20 ^ V30 ^ V40);
        //     hash->h4[9] = SWAP4(V01 ^ V11 ^ V21 ^ V31 ^ V41);
        //     hash->h4[10] = SWAP4(V02 ^ V12 ^ V22 ^ V32 ^ V42);
        //     hash->h4[11] = SWAP4(V03 ^ V13 ^ V23 ^ V33 ^ V43);
        //     hash->h4[12] = SWAP4(V04 ^ V14 ^ V24 ^ V34 ^ V44);
        //     hash->h4[13] = SWAP4(V05 ^ V15 ^ V25 ^ V35 ^ V45);
        //     hash->h4[14] = SWAP4(V06 ^ V16 ^ V26 ^ V36 ^ V46);
        //     hash->h4[15] = SWAP4(V07 ^ V17 ^ V27 ^ V37 ^ V47);
        //     break;
        // }

        MI5;
        LUFFA_P5;

    }


    // barrier(CLK_GLOBAL_MEM_FENCE);

}

// cubehash
void hash_x16rs_func_7(hash_t* hash)
{

    // cubehash.h1

    sph_u32 x0 = SPH_C32(0x2AEA2A61), x1 = SPH_C32(0x50F494D4), x2 = SPH_C32(0x2D538B8B), x3 = SPH_C32(0x4167D83E);
    sph_u32 x4 = SPH_C32(0x3FEE2313), x5 = SPH_C32(0xC701CF8C), x6 = SPH_C32(0xCC39968E), x7 = SPH_C32(0x50AC5695);
    sph_u32 x8 = SPH_C32(0x4D42C787), x9 = SPH_C32(0xA647A8B3), xa = SPH_C32(0x97CF0BEF), xb = SPH_C32(0x825B4537);
    sph_u32 xc = SPH_C32(0xEEF864D2), xd = SPH_C32(0xF22090C4), xe = SPH_C32(0xD0E5CD33), xf = SPH_C32(0xA23911AE);
    sph_u32 xg = SPH_C32(0xFCD398D9), xh = SPH_C32(0x148FE485), xi = SPH_C32(0x1B017BEF), xj = SPH_C32(0xB6444532);
    sph_u32 xk = SPH_C32(0x6A536159), xl = SPH_C32(0x2FF5781C), xm = SPH_C32(0x91FA7934), xn = SPH_C32(0x0DBADEA9);
    sph_u32 xo = SPH_C32(0xD65C8A2B), xp = SPH_C32(0xA5A70E75), xq = SPH_C32(0xB1C62456), xr = SPH_C32(0xBC796576);
    sph_u32 xs = SPH_C32(0x1921C8F7), xt = SPH_C32(0xE7989AF1), xu = SPH_C32(0x7795D246), xv = SPH_C32(0xD43E3B44);


    for (int i = 0; i < 12; i ++)
    {

        if (i == 0)
        {
            x0 ^= (hash->h4[0]);
            x1 ^= (hash->h4[1]);
            x2 ^= (hash->h4[2]);
            x3 ^= (hash->h4[3]);
            x4 ^= (hash->h4[4]);
            x5 ^= (hash->h4[5]);
            x6 ^= (hash->h4[6]);
            x7 ^= (hash->h4[7]);
        }
        else if(i == 1)
        {
            x0 ^= SPH_C32(0x00000080);
            x1 ^= 0;
            x2 ^= 0;
            x3 ^= 0;
            x4 ^= 0;
            x5 ^= 0;
            x6 ^= 0;
            x7 ^= 0;
        }
        else if (i == 2)
        {
            xv ^= SPH_C32(1);
        }
        
        SIXTEEN_ROUNDS;

    }

    hash->h4[0] = x0;
    hash->h4[1] = x1;
    hash->h4[2] = x2;
    hash->h4[3] = x3;
    hash->h4[4] = x4;
    hash->h4[5] = x5;
    hash->h4[6] = x6;
    hash->h4[7] = x7;
    hash->h4[8] = x8;
    hash->h4[9] = x9;
    hash->h4[10] = xa;
    hash->h4[11] = xb;
    hash->h4[12] = xc;
    hash->h4[13] = xd;
    hash->h4[14] = xe;
    hash->h4[15] = xf;

    // barrier(CLK_GLOBAL_MEM_FENCE);

}

// shavite
void hash_x16rs_func_8(hash_t* hash)
{

    // shavite
    sph_u32 AES0[256], AES1[256], AES2[256], AES3[256];

    for (int i = 0; i < 256; i += 1)
    {
        AES0[i] = AES0_C[i];
        AES1[i] = AES1_C[i];
        AES2[i] = AES2_C[i];
        AES3[i] = AES3_C[i];
    }

    // shavite
    // IV
    sph_u32 h0 = SPH_C32(0x72FCCDD8), h1 = SPH_C32(0x79CA4727), h2 = SPH_C32(0x128A077B), h3 = SPH_C32(0x40D55AEC);
    sph_u32 h4 = SPH_C32(0xD1901A06), h5 = SPH_C32(0x430AE307), h6 = SPH_C32(0xB29F5CD1), h7 = SPH_C32(0xDF07FBFC);
    sph_u32 h8 = SPH_C32(0x8E45D73D), h9 = SPH_C32(0x681AB538), hA = SPH_C32(0xBDE86578), hB = SPH_C32(0xDD577E47);
    sph_u32 hC = SPH_C32(0xE275EADE), hD = SPH_C32(0x502D9FCD), hE = SPH_C32(0xB9357178), hF = SPH_C32(0x022A4B9A);

    // state
    sph_u32 rk00, rk01, rk02, rk03, rk04, rk05, rk06, rk07;
    sph_u32 rk08, rk09, rk0A, rk0B, rk0C, rk0D, rk0E, rk0F;
    sph_u32 rk10, rk11, rk12, rk13, rk14, rk15, rk16, rk17;
    sph_u32 rk18, rk19, rk1A, rk1B, rk1C, rk1D, rk1E, rk1F;

    // 64 >= 32
    sph_u32 sc_count0 = (32 << 3), sc_count1 = 0, sc_count2 = 0, sc_count3 = 0;

    rk00 = (hash->h4[0]);
    rk01 = (hash->h4[1]);
    rk02 = (hash->h4[2]);
    rk03 = (hash->h4[3]);
    rk04 = (hash->h4[4]);
    rk05 = (hash->h4[5]);
    rk06 = (hash->h4[6]);
    rk07 = (hash->h4[7]);
    rk08 = (SPH_C32(0x00000080));
    rk09 = 0;
    rk0A = 0;
    rk0B = 0;
    rk0C = 0;
    rk0D = 0;
    rk0E = 0;
    rk0F = 0;
    rk10 = rk11 = rk12 = rk13 = rk14 = rk15 = rk16 = rk17 = 0;
    rk18 = rk19 = rk1A = 0;
    rk1B = (SPH_C32(0x01000000));
    rk1C = 0;
    rk1D = 0;
    rk1E = 0;
    rk1F = (SPH_C32(0x02000000));

    c512(buf);

    hash->h4[0] = h0;
    hash->h4[1] = h1;
    hash->h4[2] = h2;
    hash->h4[3] = h3;
    hash->h4[4] = h4;
    hash->h4[5] = h5;
    hash->h4[6] = h6;
    hash->h4[7] = h7;
    hash->h4[8] = h8;
    hash->h4[9] = h9;
    hash->h4[10] = hA;
    hash->h4[11] = hB;
    hash->h4[12] = hC;
    hash->h4[13] = hD;
    hash->h4[14] = hE;
    hash->h4[15] = hF;
    

    //   barrier(CLK_GLOBAL_MEM_FENCE);

}

// simd
void hash_x16rs_func_9(hash_t* hash)
{

  // simd
  s32 q[256];
  unsigned char x[128];
  for(unsigned int i = 0; i < 32; i++)
    x[i] = hash->h1[i];
  for(unsigned int i = 32; i < 128; i++)
    x[i] = 0;


  u32 A0 = C32(0x0BA16B95), A1 = C32(0x72F999AD), A2 = C32(0x9FECC2AE), A3 = C32(0xBA3264FC), A4 = C32(0x5E894929), A5 = C32(0x8E9F30E5), A6 = C32(0x2F1DAA37), A7 = C32(0xF0F2C558);
  u32 B0 = C32(0xAC506643), B1 = C32(0xA90635A5), B2 = C32(0xE25B878B), B3 = C32(0xAAB7878F), B4 = C32(0x88817F7A), B5 = C32(0x0A02892B), B6 = C32(0x559A7550), B7 = C32(0x598F657E);
  u32 C0 = C32(0x7EEF60A1), C1 = C32(0x6B70E3E8), C2 = C32(0x9C1714D1), C3 = C32(0xB958E2A8), C4 = C32(0xAB02675E), C5 = C32(0xED1C014F), C6 = C32(0xCD8D65BB), C7 = C32(0xFDB7A257);
  u32 D0 = C32(0x09254899), D1 = C32(0xD699C7BC), D2 = C32(0x9019B6DC), D3 = C32(0x2B9022E4), D4 = C32(0x8FA14956), D5 = C32(0x21BF9BD3), D6 = C32(0xB94D0943), D7 = C32(0x6FFDDC22);

  FFT256(0, 1, 0, ll1);
  for (int i = 0; i < 256; i ++)
  {
    s32 tq;

    tq = q[i] + yoff_b_n[i];
    tq = REDS2(tq);
    tq = REDS1(tq);
    tq = REDS1(tq);
    q[i] = (tq <= 128 ? tq : tq - 257);
  }


  A0 ^= hash->h4[0];
  A1 ^= hash->h4[1];
  A2 ^= hash->h4[2];
  A3 ^= hash->h4[3];
  A4 ^= hash->h4[4];
  A5 ^= hash->h4[5];
  A6 ^= hash->h4[6];
  A7 ^= hash->h4[7];
  B0 ^= 0;
  B1 ^= 0;
  B2 ^= 0;
  B3 ^= 0;
  B4 ^= 0;
  B5 ^= 0;
  B6 ^= 0;
  B7 ^= 0;
  C0 ^= 0;
  C1 ^= 0;
  C2 ^= 0;
  C3 ^= 0;
  C4 ^= 0;
  C5 ^= 0;
  C6 ^= 0;
  C7 ^= 0;
  D0 ^= 0;
  D1 ^= 0;
  D2 ^= 0;
  D3 ^= 0;
  D4 ^= 0;
  D5 ^= 0;
  D6 ^= 0;
  D7 ^= 0;


  ONE_ROUND_BIG(0_, 0,  3, 23, 17, 27);
  ONE_ROUND_BIG(1_, 1, 28, 19, 22,  7);
  ONE_ROUND_BIG(2_, 2, 29,  9, 15,  5);
  ONE_ROUND_BIG(3_, 3,  4, 13, 10, 25);


  STEP_BIG(
    C32(0x0BA16B95), C32(0x72F999AD), C32(0x9FECC2AE), C32(0xBA3264FC),
    C32(0x5E894929), C32(0x8E9F30E5), C32(0x2F1DAA37), C32(0xF0F2C558),
    IF,  4, 13, PP8_4_);

  STEP_BIG(
    C32(0xAC506643), C32(0xA90635A5), C32(0xE25B878B), C32(0xAAB7878F),
    C32(0x88817F7A), C32(0x0A02892B), C32(0x559A7550), C32(0x598F657E),
    IF, 13, 10, PP8_5_);

  STEP_BIG(
    C32(0x7EEF60A1), C32(0x6B70E3E8), C32(0x9C1714D1), C32(0xB958E2A8),
    C32(0xAB02675E), C32(0xED1C014F), C32(0xCD8D65BB), C32(0xFDB7A257),
    IF, 10, 25, PP8_6_);

  STEP_BIG(
    C32(0x09254899), C32(0xD699C7BC), C32(0x9019B6DC), C32(0x2B9022E4),
    C32(0x8FA14956), C32(0x21BF9BD3), C32(0xB94D0943), C32(0x6FFDDC22),
    IF, 25,  4, PP8_0_);



  u32 COPY_A0 = (A0), COPY_A1 = (A1), COPY_A2 = (A2), COPY_A3 = (A3), 
      COPY_A4 = (A4), COPY_A5 = (A5), COPY_A6 = (A6), COPY_A7 = (A7);
  u32 COPY_B0 = (B0), COPY_B1 = (B1), COPY_B2 = (B2), COPY_B3 = (B3), 
      COPY_B4 = (B4), COPY_B5 = (B5), COPY_B6 = (B6), COPY_B7 = (B7);
  u32 COPY_C0 = (C0), COPY_C1 = (C1), COPY_C2 = (C2), COPY_C3 = (C3), 
      COPY_C4 = (C4), COPY_C5 = (C5), COPY_C6 = (C6), COPY_C7 = (C7);
  u32 COPY_D0 = (D0), COPY_D1 = (D1), COPY_D2 = (D2), COPY_D3 = (D3), 
      COPY_D4 = (D4), COPY_D5 = (D5), COPY_D6 = (D6), COPY_D7 = (D7);


  
  A0 ^= (SPH_C32(0x00000100));
  // A0 ^= 0x200;


    for(unsigned int i = 0; i < 128; i++)
        x[i] = 0;
    x[1] = 1; // FIXED

    FFT256(0, 1, 0, ll1);
    for (int i = 0; i < 256; i ++) {
        s32 tq;

        tq = q[i] + yoff_b_f[i];
        tq = REDS2(tq);
        tq = REDS1(tq);
        tq = REDS1(tq);
        q[i] = (tq <= 128 ? tq : tq - 257);
    }


  ONE_ROUND_BIG(0_, 0,  3, 23, 17, 27);
  ONE_ROUND_BIG(1_, 1, 28, 19, 22,  7);
  ONE_ROUND_BIG(2_, 2, 29,  9, 15,  5);
  ONE_ROUND_BIG(3_, 3,  4, 13, 10, 25);




  STEP_BIG(
    COPY_A0, COPY_A1, COPY_A2, COPY_A3,
    COPY_A4, COPY_A5, COPY_A6, COPY_A7,
    IF,  4, 13, PP8_4_);

  STEP_BIG(
    COPY_B0, COPY_B1, COPY_B2, COPY_B3,
    COPY_B4, COPY_B5, COPY_B6, COPY_B7,
    IF, 13, 10, PP8_5_);

  STEP_BIG(
    COPY_C0, COPY_C1, COPY_C2, COPY_C3,
    COPY_C4, COPY_C5, COPY_C6, COPY_C7,
    IF, 10, 25, PP8_6_);

  STEP_BIG(
    COPY_D0, COPY_D1, COPY_D2, COPY_D3,
    COPY_D4, COPY_D5, COPY_D6, COPY_D7,
    IF, 25,  4, PP8_0_);

  hash->h4[0] = A0;
  hash->h4[1] = A1;
  hash->h4[2] = A2;
  hash->h4[3] = A3;
  hash->h4[4] = A4;
  hash->h4[5] = A5;
  hash->h4[6] = A6;
  hash->h4[7] = A7;
  hash->h4[8] = B0;
  hash->h4[9] = B1;
  hash->h4[10] = B2;
  hash->h4[11] = B3;
  hash->h4[12] = B4;
  hash->h4[13] = B5;
  hash->h4[14] = B6;
  hash->h4[15] = B7;

    // barrier(CLK_GLOBAL_MEM_FENCE);


}

// echo
void hash_x16rs_func_10(hash_t* hash)
{

    // shavite
    sph_u32 AES0[256], AES1[256], AES2[256], AES3[256];

    for (int i = 0; i < 256; i += 1)
    {
        AES0[i] = AES0_C[i];
        AES1[i] = AES1_C[i];
        AES2[i] = AES2_C[i];
        AES3[i] = AES3_C[i];
    }


  // echo
  sph_u64 W00, W01, W10, W11, W20, W21, W30, W31, W40, W41, W50, W51, W60, W61, W70, W71, W80, W81, W90, W91, WA0, WA1, WB0, WB1, WC0, WC1, WD0, WD1, WE0, WE1, WF0, WF1;
  sph_u64 Vb00, Vb01, Vb10, Vb11, Vb20, Vb21, Vb30, Vb31, Vb40, Vb41, Vb50, Vb51, Vb60, Vb61, Vb70, Vb71;
  Vb00 = Vb10 = Vb20 = Vb30 = Vb40 = Vb50 = Vb60 = Vb70 = 512UL;
  Vb01 = Vb11 = Vb21 = Vb31 = Vb41 = Vb51 = Vb61 = Vb71 = 0;

  sph_u32 K0 = SPH_C32(0x00000100);
  sph_u32 K1 = 0;
  sph_u32 K2 = 0;
  sph_u32 K3 = 0;

  W00 = Vb00;
  W01 = Vb01;
  W10 = Vb10;
  W11 = Vb11;
  W20 = Vb20;
  W21 = Vb21;
  W30 = Vb30;
  W31 = Vb31;
  W40 = Vb40;
  W41 = Vb41;
  W50 = Vb50;
  W51 = Vb51;
  W60 = Vb60;
  W61 = Vb61;
  W70 = Vb70;
  W71 = Vb71;
  W80 = hash->h8[0];
  W81 = hash->h8[1];
  W90 = hash->h8[2];
  W91 = hash->h8[3];
  WA0 = SPH_C64(0x0000000000000080);
  WA1 = 0;
  WB0 = 0;
  WB1 = 0;
  WC0 = 0;
  WC1 = 0;
  WD0 = 0;
  WD1 = 0;
  WE0 = 0;
  WE1 = SPH_C64(0x0200000000000000);
  WF0 = SPH_C64(0x0000000000000100);
  WF1 = 0;


  for (unsigned u = 0; u < 10; u ++)
    BIG_ROUND;



  hash->h8[0] = hash->h8[0] ^ Vb00 ^ W00 ^ W80;
  hash->h8[1] = hash->h8[1] ^ Vb01 ^ W01 ^ W81;
  hash->h8[2] = hash->h8[2] ^ Vb10 ^ W10 ^ W90;
  hash->h8[3] = hash->h8[3] ^ Vb11 ^ W11 ^ W91;
  hash->h8[4] = hash->h8[4] ^ Vb20 ^ W20 ^ WA0;
  hash->h8[5] = hash->h8[5] ^ Vb21 ^ W21 ^ WA1;
  hash->h8[6] = hash->h8[6] ^ Vb30 ^ W30 ^ WB0;
  hash->h8[7] = hash->h8[7] ^ Vb31 ^ W31 ^ WB1;

    //   barrier(CLK_GLOBAL_MEM_FENCE);



}

// hamsi
void hash_x16rs_func_11(hash_t* hash)
{
    for(int i = 0; i < 4; i++)
        hash->h8[i+4] = 0;


    sph_u32 T512_L[1024];

    for (int i = 0; i < 1024; i += 1)
      T512_L[i] = T512_W[i];
      // T512_L[i] = T512[i]; // old code


  sph_u32 c0 = HAMSI_IV512[0], c1 = HAMSI_IV512[1], c2 = HAMSI_IV512[2], c3 = HAMSI_IV512[3];
  sph_u32 c4 = HAMSI_IV512[4], c5 = HAMSI_IV512[5], c6 = HAMSI_IV512[6], c7 = HAMSI_IV512[7];
  sph_u32 c8 = HAMSI_IV512[8], c9 = HAMSI_IV512[9], cA = HAMSI_IV512[10], cB = HAMSI_IV512[11];
  sph_u32 cC = HAMSI_IV512[12], cD = HAMSI_IV512[13], cE = HAMSI_IV512[14], cF = HAMSI_IV512[15];
  sph_u32 m0, m1, m2, m3, m4, m5, m6, m7;
  sph_u32 m8, m9, mA, mB, mC, mD, mE, mF;
  sph_u32 h[16] = { c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, cA, cB, cC, cD, cE, cF };


    unsigned char right_padding[32] = {0,0,0,0,0,0,0,0,17,16,0,0,0,0,0,0,73,78,80,85,84,95,66,73,71,32,98,117,102,58,32,58};

    for(int i = 0; i < 32; i++)
        hash->h1[i+32] = right_padding[i];


  #define buf(u) hash->h1[i + u]

  for(int i = 0; i < 32; i += 8)
  {
    INPUT_BIG;
    P_BIG;
    T_BIG;
  }

  #undef buf
  #define buf(u) (u == 0 ? 0x80 : 0)

  INPUT_BIG;
  P_BIG;
  T_BIG;

  #undef buf
  #define buf(u) (u == 6 ? 1 : 0)

  INPUT_BIG;
  PF_BIG;
  T_BIG;



  for (unsigned u = 0; u < 16; u ++)
      hash->h4[u] = SWAP4(h[u]);

  //   barrier(CLK_GLOBAL_MEM_FENCE);


}

// fugue
void hash_x16rs_func_12(hash_t* hash)
{
  // mixtab
  sph_u32 mixtab0[256], mixtab1[256], mixtab2[256], mixtab3[256];

  for (int i = 0; i < 256; i += 1)
  {
    mixtab0[i] = mixtab0_c[i];
    mixtab1[i] = mixtab1_c[i];
    mixtab2[i] = mixtab2_c[i];
    mixtab3[i] = mixtab3_c[i];
  }

  // fugue
  sph_u32 S00, S01, S02, S03, S04, S05, S06, S07, S08, S09;
  sph_u32 S10, S11, S12, S13, S14, S15, S16, S17, S18, S19;
  sph_u32 S20, S21, S22, S23, S24, S25, S26, S27, S28, S29;
  sph_u32 S30, S31, S32, S33, S34, S35;

  ulong fc_bit_count = (sph_u64) 64 << 3;

  S00 = S01 = S02 = S03 = S04 = S05 = S06 = S07 = S08 = S09 = S10 = S11 = S12 = S13 = S14 = S15 = S16 = S17 = S18 = S19 = 0;
  S20 = SPH_C32(0x8807a57e); S21 = SPH_C32(0xe616af75); S22 = SPH_C32(0xc5d3e4db); S23 = SPH_C32(0xac9ab027);
  S24 = SPH_C32(0xd915f117); S25 = SPH_C32(0xb6eecc54); S26 = SPH_C32(0x06e8020b); S27 = SPH_C32(0x4a92efd1);
  S28 = SPH_C32(0xaac6e2c9); S29 = SPH_C32(0xddb21398); S30 = SPH_C32(0xcae65838); S31 = SPH_C32(0x437f203f);
  S32 = SPH_C32(0x25ea78e7); S33 = SPH_C32(0x951fddd6); S34 = SPH_C32(0xda6ed11d); S35 = SPH_C32(0xe13e3567);



    //   FUGUE512_3((hash->h4[0x0]), (hash->h4[0x1]), (hash->h4[0x2]));
    //   FUGUE512_3((hash->h4[0x3]), (hash->h4[0x4]), (hash->h4[0x5]));
    //   FUGUE512_3((hash->h4[0x6]), (hash->h4[0x7]), (hash->h4[0x8]));
    //   FUGUE512_3((hash->h4[0x9]), (hash->h4[0xA]), (hash->h4[0xB]));
    //   FUGUE512_3((hash->h4[0xC]), (hash->h4[0xD]), (hash->h4[0xE]));
    //   FUGUE512_3((hash->h4[0xF]), as_uint2(fc_bit_count).y, as_uint2(fc_bit_count).x);

    FUGUE512_one(SWAP4(hash->h4[0]));
    FUGUE512_two(SWAP4(hash->h4[1]));
    FUGUE512_trd(SWAP4(hash->h4[2]));
    FUGUE512_one(SWAP4(hash->h4[3]));
    FUGUE512_two(SWAP4(hash->h4[4]));
    FUGUE512_trd(SWAP4(hash->h4[5]));
    FUGUE512_one(SWAP4(hash->h4[6]));

    FUGUE512_two(SWAP4(hash->h4[7]));
    FUGUE512_trd((0));
    FUGUE512_one((SPH_C32(0x00000100)));


    ROR12;

  // apply round shift if necessary
  int i;

  for (i = 0; i < 32; i ++)
  {
    ROR3;
    CMIX36(S00, S01, S02, S04, S05, S06, S18, S19, S20);
    SMIX(S00, S01, S02, S03);
  }

  for (i = 0; i < 13; i ++)
  {
    S04 ^= S00;
    S09 ^= S00;
    S18 ^= S00;
    S27 ^= S00;
    ROR9;
    SMIX(S00, S01, S02, S03);
    S04 ^= S00;
    S10 ^= S00;
    S18 ^= S00;
    S27 ^= S00;
    ROR9;
    SMIX(S00, S01, S02, S03);
    S04 ^= S00;
    S10 ^= S00;
    S19 ^= S00;
    S27 ^= S00;
    ROR9;
    SMIX(S00, S01, S02, S03);
    S04 ^= S00;
    S10 ^= S00;
    S19 ^= S00;
    S28 ^= S00;
    ROR8;
    SMIX(S00, S01, S02, S03);
  }

  S04 ^= S00;
  S09 ^= S00;
  S18 ^= S00;
  S27 ^= S00;

  hash->h4[0] = SWAP4(S01);
  hash->h4[1] = SWAP4(S02);
  hash->h4[2] = SWAP4(S03);
  hash->h4[3] = SWAP4(S04);
  hash->h4[4] = SWAP4(S09);
  hash->h4[5] = SWAP4(S10);
  hash->h4[6] = SWAP4(S11);
  hash->h4[7] = SWAP4(S12);
  hash->h4[8] = SWAP4(S18);
  hash->h4[9] = SWAP4(S19);
  hash->h4[10] = SWAP4(S20);
  hash->h4[11] = SWAP4(S21);
  hash->h4[12] = SWAP4(S27);
  hash->h4[13] = SWAP4(S28);
  hash->h4[14] = SWAP4(S29);
  hash->h4[15] = SWAP4(S30);

  // barrier(CLK_GLOBAL_MEM_FENCE);


}

// shabal
void hash_x16rs_func_13(hash_t* hash)
{

    // shabal
    sph_u32 A00 = A_init_512[0], A01 = A_init_512[1], A02 = A_init_512[2], A03 = A_init_512[3], A04 = A_init_512[4], A05 = A_init_512[5], A06 = A_init_512[6], A07 = A_init_512[7],
    A08 = A_init_512[8], A09 = A_init_512[9], A0A = A_init_512[10], A0B = A_init_512[11];
    sph_u32 B0 = B_init_512[0], B1 = B_init_512[1], B2 = B_init_512[2], B3 = B_init_512[3], B4 = B_init_512[4], B5 = B_init_512[5], B6 = B_init_512[6], B7 = B_init_512[7],
    B8 = B_init_512[8], B9 = B_init_512[9], BA = B_init_512[10], BB = B_init_512[11], BC = B_init_512[12], BD = B_init_512[13], BE = B_init_512[14], BF = B_init_512[15];
    sph_u32 C0 = C_init_512[0], C1 = C_init_512[1], C2 = C_init_512[2], C3 = C_init_512[3], C4 = C_init_512[4], C5 = C_init_512[5], C6 = C_init_512[6], C7 = C_init_512[7],
    C8 = C_init_512[8], C9 = C_init_512[9], CA = C_init_512[10], CB = C_init_512[11], CC = C_init_512[12], CD = C_init_512[13], CE = C_init_512[14], CF = C_init_512[15];
    sph_u32 M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, MA, MB, MC, MD, ME, MF;
    sph_u32 Wlow = 1, Whigh = 0;

    M0 = hash->h4[0];
    M1 = hash->h4[1];
    M2 = hash->h4[2];
    M3 = hash->h4[3];
    M4 = hash->h4[4];
    M5 = hash->h4[5];
    M6 = hash->h4[6];
    M7 = hash->h4[7];
    M8 = SPH_C32(0x00000080);
    M9 = 0;
    MA = 0;
    MB = 0;
    MC = 0;
    MD = 0;
    ME = 0;
    MF = 0;

    //   INPUT_BLOCK_ADD;
    //   XOR_W;
    //   APPLY_P;
    //   INPUT_BLOCK_SUB;
    //   SWAP_BC;
    //   INCR_W;

    //   M0 = 0x80;
    //   M1 = M2 = M3 = M4 = M5 = M6 = M7 = M8 = M9 = MA = MB = MC = MD = ME = MF = 0;

    INPUT_BLOCK_ADD;
    XOR_W;
    APPLY_P;

    for (unsigned i = 0; i < 3; i ++)
    {
    SWAP_BC;
    XOR_W;
    APPLY_P;
    }

	hash->h4[0] = B0;
	hash->h4[1] = B1;
	hash->h4[2] = B2;
	hash->h4[3] = B3;
	hash->h4[4] = B4;
	hash->h4[5] = B5;
	hash->h4[6] = B6;
	hash->h4[7] = B7;
	hash->h4[8] = B8;
	hash->h4[9] = B9;
	hash->h4[10] = BA;
	hash->h4[11] = BB;
	hash->h4[12] = BC;
	hash->h4[13] = BD;
	hash->h4[14] = BE;
	hash->h4[15] = BF;


    // barrier(CLK_GLOBAL_MEM_FENCE);

}

// whirlpool
void hash_x16rs_func_14(hash_t* hash)
{

    // whirlpool
    sph_u64 LT0[256], LT1[256], LT2[256], LT3[256], LT4[256], LT5[256], LT6[256], LT7[256];

    
    for (int i = 0; i < 256; i += 1)
    {
        LT0[i] = plain_T0[i];
        LT1[i] = plain_T1[i];
        LT2[i] = plain_T2[i];
        LT3[i] = plain_T3[i];
        LT4[i] = plain_T4[i];
        LT5[i] = plain_T5[i];
        LT6[i] = plain_T6[i];
        LT7[i] = plain_T7[i];
    }


    // barrier(CLK_LOCAL_MEM_FENCE);


    // whirlpool
    sph_u64 n0, n1, n2, n3, n4, n5, n6, n7;
    sph_u64 h0, h1, h2, h3, h4, h5, h6, h7;
    sph_u64 state[8];

    n0 = (hash->h8[0]);
    n1 = (hash->h8[1]);
    n2 = (hash->h8[2]);
    n3 = (hash->h8[3]);
    n4 = SPH_C64(0x0000000000000080);
    n5 = 0;
    n6 = 0;
    n7 = 0;

    h0 = h1 = h2 = h3 = h4 = h5 = h6 = h7 = 0;

    n0 ^= h0;
    n1 ^= h1;
    n2 ^= h2;
    n3 ^= h3;
    n4 ^= h4;
    n5 ^= h5;
    n6 ^= h6;
    n7 ^= h7;


    #pragma unroll 10
    for (unsigned r = 0; r < 10; r ++)
    {
        sph_u64 tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;

        ROUND_KSCHED(plain_T, h, tmp, plain_RC[r]);
        TRANSFER(h, tmp);
        ROUND_WENC(plain_T, n, h, tmp);
        TRANSFER(n, tmp);
    }

    state[0] = n0 ^ (hash->h8[0]);
    state[1] = n1 ^ (hash->h8[1]);
    state[2] = n2 ^ (hash->h8[2]);
    state[3] = n3 ^ (hash->h8[3]);
    state[4] = n4 ^ SPH_C64(0x0000000000000080);
    state[5] = n5 ^ 0;
    state[6] = n6 ^ 0;
    state[7] = n7 ^ 0;

    n0 = n1 = n2 = n3 = n4 = n5 = n6 = 0;
    n7 = SPH_C64(0x0001000000000000);

    h0 = state[0];
    h1 = state[1];
    h2 = state[2];
    h3 = state[3];
    h4 = state[4];
    h5 = state[5];
    h6 = state[6];
    h7 = state[7];

    n0 ^= h0;
    n1 ^= h1;
    n2 ^= h2;
    n3 ^= h3;
    n4 ^= h4;
    n5 ^= h5;
    n6 ^= h6;
    n7 ^= h7;

    #pragma unroll 10
    for (unsigned r = 0; r < 10; r ++)
    {
        sph_u64 tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;

        ROUND_KSCHED(LT, h, tmp, plain_RC[r]);
        TRANSFER(h, tmp);
        ROUND_WENC(plain_T, n, h, tmp);
        TRANSFER(n, tmp);
    }

    state[0] ^= n0 ^ (hash->h8[0]);
    state[1] ^= n1 ^ (hash->h8[1]);
    state[2] ^= n2 ^ (hash->h8[2]);
    state[3] ^= n3 ^ (hash->h8[3]);
    state[4] ^= n4 ^ SPH_C64(0x0000000000000080);
    state[5] ^= n5 ^ 0;
    state[6] ^= n6 ^ 0;
    state[7] ^= n7 ^ SPH_C64(0x0001000000000000);

    state[0] ^= (hash->h8[0]);
    state[1] ^= (hash->h8[1]);
    state[2] ^= (hash->h8[2]);
    state[3] ^= (hash->h8[3]);
    state[4] ^= SPH_C64(0x0000000000000080);
    state[5] ^= 0;
    state[6] ^= 0;
    state[7] ^= SPH_C64(0x0001000000000000);


    for (unsigned i = 0; i < 8; i ++){
        hash->h8[i] = state[i];
    }

    // barrier(CLK_GLOBAL_MEM_FENCE);


}

// sha2
void hash_x16rs_func_15(hash_t* hash)
{
    uint cnf[3] = { 0, 0, 32 };

    unsigned char data[32];
    for(int i=0; i<32; i++){
        data[i] = hash->h1[i];
    }

    unsigned char digest[64];

    // // 运算  
    easy_sha512(data, 32, digest);

    // 结果
    for(int i=0; i<32; i++){
        hash->h1[i] = ((char*)digest)[i];
    }

}








#endif // X16RX_CL