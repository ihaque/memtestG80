/*
 * memtestG80_cli.cu
 * Command-line interface frontend for MemtestG80 tester
 *
 * Author: Imran Haque, 2009
 * Copyright 2009, Stanford University
 *
 * This file is licensed under the terms of the LGPL. Please see
 * the COPYING file in the accompanying source distribution for
 * full license terms.
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <ctype.h>
#include "memtestG80_core.h"
#include "ezOptionParser.hpp"

#ifdef OSX
inline size_t strnlen(const char* s,size_t maxlen) {
    size_t i;
    for (i=0;i<maxlen && s[i];i++);
    return i;
}
#endif


bool validateNumeric(const char* str) {
    size_t idlen;
    // Assumes number will not be larger than 10 digits
    if ((idlen=strnlen(str,11))==11)
        return false;
    for (size_t i = 0; i < idlen; i++) {
        if (!isdigit(str[i])) return false;
    }
    return true;
}

void print_usage(void) {
    printf("     -------------------------------------------------------------\n");
    printf("     |                      MemtestG80 v1.00                     |\n");
    //printf("     |             Copyright 2009, Stanford University           |\n");
    printf("     |                                                           |\n");
    printf("     | Usage: memtestG80 [flags] [MB GPU RAM to test] [# iters]  |\n");
    printf("     |                                                           |\n");
    printf("     | Defaults: GPU 0, 128MB RAM, 50 test iterations            |\n");
    printf("     | Amount of tested RAM will be rounded up to nearest 2MB    |\n");
    printf("     -------------------------------------------------------------\n\n");
    printf("      Available flags:\n");
    printf("        --gpu N ,-g N : run test on the Nth (from 0) CUDA GPU\n");
    printf("        --license ,-l : show license terms for this build\n");
    printf("\n");
}

void print_licensing(void) {
    printf("Copyright 2009, Stanford University\n");
    #ifndef WEBCOMM // Don't just #else this! Translation scripts need the ifdef form.
    printf("Licensed under the GNU Library General Public License (LGPL), version 3.0\n");
    printf("Please see the file COPYING in the source distribution for details\n");
    #endif
    printf("\n");
    #if defined(WINDOWS) || defined(WINNV)
    printf("This software incorporates by linkage code from the libintl and libiconv\n");
    printf("libraries, which are covered by the Library GNU Public License, available\n");
    printf("at http://www.gnu.org/licenses/lgpl-3.0.txt\n");
    #endif
    return;
}

int main(int argc,const char** argv) {
    uint megsToTest=128;
    uint maxIters=50;
    int gpuID=0;
    int showLicense = 0;
    cudaDeviceProp deviceProps;

    print_usage(); 
    ez::ezOptionParser opt;

    opt.add(
        "0", // Default.
        0, // Required?
        1, // Number of args expected.
        0, // Delimiter if expecting multiple args.
        "run test on the Nth (from 0) CUDA GPU", // Help description.
        "--gpu",
        "-g"
    );

    opt.add(
        "", // Default.
        0, // Required?
        0, // Number of args expected.
        0, // Delimiter if expecting multiple args.
        "show license terms for this build\n", // Help description.
        "-l",
        "--license"
    );

    opt.parse(argc, argv);
    std::string lastArg;
    if(opt.isSet("-g"))
        opt.get("-g")->getInt(gpuID);
    if(opt.isSet("-l"))
        opt.get("-g")->getInt(showLicense);
    if(opt.lastArgs.size() == 0) {
        // do nothing, use default settings
    } else if(opt.lastArgs.size() == 2) {
        sscanf(opt.lastArgs[0]->c_str(),"%u",&megsToTest);
        sscanf(opt.lastArgs[1]->c_str(),"%u",&maxIters);
    } else {
        printf("Error: Bad argument for [MB GPU RAM to test] [# iters]");
    }

    if (showLicense) print_licensing();
    
    // Sanity check device ID
    int devCount;
    cudaGetDeviceCount(&devCount);
    if (gpuID >= devCount) {
        printf("Error: Specified invalid GPU index (%d); %d CUDA devices present, numbered from zero.\n",gpuID,devCount);
        printf("\nValid CUDA devices:\n");
        for (int i = 0; i < devCount; i++) {
            cudaGetDeviceProperties(&deviceProps,i);
            printf("%d: %s\n",i,deviceProps.name);
        }
        exit(2);
    }

    cudaGetDeviceProperties(&deviceProps,gpuID);

    // Sanity check for real device
    if ((deviceProps.major == 9999) && (deviceProps.minor == 9999)) {
        printf("Error: No CUDA hardware detected. CUDA device emulator is not supported.\n");
        exit(2);
    }

    // Passed sanity checks, set device to use
    if (cudaSetDevice(gpuID) == cudaErrorInvalidDevice) {
        printf("Error: Got Invalid Device Error setting %d as active CUDA device.\n",gpuID);
        exit(2);
    }

    // Sanity check RAM size and iteration count
    if (megsToTest <= 0) {
        printf("Error: invalid memory test region size %d MiB\n",megsToTest);
        exit(2);
    }
    if (maxIters <= 0) {
        printf("Error: invalid iteration count %d\n",maxIters);
        exit(2);
    }


    memtestState tester;
    if (!tester.allocate(megsToTest)) {
        printf("Error: unable to allocate %u MiB of GPU memory to test, bailing!\n",megsToTest);
        printf("Error text: %s\n",cudaGetErrorString(cudaGetLastError()));
        exit(2);
    } else {
        printf("Running %u iterations of tests over %u MB of GPU memory on card %d: %s\n\n",maxIters,tester.size(),gpuID,deviceProps.name);
    }

    // Run bandwidth test
    const unsigned bw_iters = 20;
    printf("Running memory bandwidth test over %u iterations of %u MB transfers...\n",bw_iters,tester.size()/2);
    double bandwidth;
    if (!tester.gpuMemoryBandwidth(bandwidth,tester.size()/2,bw_iters)) {
        printf("\tTest failed!\n");
        bandwidth = 0;
    } else {
        printf("\tEstimated bandwidth %.02f MB/s\n\n",bandwidth);
    }


    uint accumulatedErrors = 0,iterErrors;
    uint errorCounts[15];
    memset(errorCounts,0,15*sizeof(uint));
   
    unsigned int start,end;

    for (uint i = 0; i < maxIters ; i++) { 
        printf("Test iteration %u (GPU %d, %d MiB): %u errors so far\n",i+1,gpuID,tester.size(),accumulatedErrors);
        uint errorCount;
        
        // Moving inversions, 1's and 0's {{{
        errorCount = 0;
        start=getTimeMilliseconds();
        tester.gpuMovingInversionsOnesZeros(errorCount);
        accumulatedErrors += errorCount;
        end=getTimeMilliseconds();
        errorCounts[0] += errorCount;
        printf("\tMoving Inversions (ones and zeros): %u errors (%u ms)\n",errorCount,end-start);
        // }}}
        // Memtest86 walking 8-bit {{{
        errorCount = 0;
        start=getTimeMilliseconds();
        for (uint shift=0;shift<8;shift++){
            tester.gpuWalking8BitM86(iterErrors,shift);
            errorCount += iterErrors;
        }
        end=getTimeMilliseconds();
        accumulatedErrors+=errorCount;
        errorCounts[1] += errorCount;
        printf("\tMemtest86 Walking 8-bit: %u errors (%u ms)\n",errorCount,end-start);
        // }}}
        // True Walking zeros, 8-bit {{{
        errorCount = 0;
        start=getTimeMilliseconds();
        for (uint shift=0;shift<8;shift++){
            tester.gpuWalking8Bit(iterErrors,false,shift);
            errorCount += iterErrors;
        }
        end=getTimeMilliseconds();
        accumulatedErrors+=errorCount;
        errorCounts[2] += errorCount;
        printf("\tTrue Walking zeros (8-bit): %u errors (%u ms)\n",errorCount,end-start);
        // }}}
        // True Walking ones, 8-bit {{{
        errorCount = 0;
        start=getTimeMilliseconds();
        for (uint shift=0;shift<8;shift++){
            tester.gpuWalking8Bit(iterErrors,true,shift);
            errorCount += iterErrors;
        }
        end=getTimeMilliseconds();
        accumulatedErrors+=errorCount;
        errorCounts[3] += errorCount;
        printf("\tTrue Walking ones (8-bit): %u errors (%u ms)\n",errorCount,end-start);
        // }}}
        // Moving inversions, random {{{
        start=getTimeMilliseconds();
        tester.gpuMovingInversionsRandom(errorCount);
        accumulatedErrors += errorCount;
        end=getTimeMilliseconds();
        errorCounts[4] += errorCount;
        printf("\tMoving Inversions (random): %u errors (%u ms)\n",errorCount,end-start);
        // }}}
        // Walking zeros, 32-bit {{{
        errorCount = 0;
        start=getTimeMilliseconds();
        for (uint shift=0;shift<32;shift++){
            tester.gpuWalking32Bit(iterErrors,false,shift);
            errorCount += iterErrors;
        }
        end=getTimeMilliseconds();
        accumulatedErrors+=errorCount;
        errorCounts[5] += errorCount;
        printf("\tMemtest86 Walking zeros (32-bit): %u errors (%u ms)\n",errorCount,end-start);
        // }}}
        // Walking ones, 32-bit {{{
        errorCount = 0;
        start=getTimeMilliseconds();
        for (uint shift=0;shift<32;shift++){
            tester.gpuWalking32Bit(iterErrors,true,shift);
            errorCount += iterErrors;
        }
        end=getTimeMilliseconds();
        accumulatedErrors+=errorCount;
        errorCounts[6] += errorCount;
        printf("\tMemtest86 Walking ones (32-bit): %u errors (%u ms)\n",errorCount,end-start);
        // }}}
        // Random blocks {{{
        if (tester.size() <= 16400){
            start=getTimeMilliseconds();
            tester.gpuRandomBlocks(errorCount,rand());
            accumulatedErrors += errorCount;
            errorCounts[7] += errorCount;
            end=getTimeMilliseconds();
            printf("\tRandom blocks: %u errors (%u ms)\n",errorCount,end-start);
        }
        else
          printf("\tRandom blocks: skipped, see Bug #3569\n");

        // }}}
        // Modulo-20, 32-bit {{{
        errorCount = 0;
        start=getTimeMilliseconds();
        for (uint shift=0;shift<20;shift++){
            tester.gpuModuloX(iterErrors,shift,rand(),20,2);
            errorCount += iterErrors;
        }
        end=getTimeMilliseconds();
        accumulatedErrors+=errorCount;
        errorCounts[8] += errorCount;
        printf("\tMemtest86 Modulo-20: %u errors (%u ms)\n",errorCount,end-start);
        // }}}
        // Logic, 1 iteration {{{
        errorCount = 0;
        start=getTimeMilliseconds();
        tester.gpuShortLCG0(errorCount,1);
        end=getTimeMilliseconds();
        accumulatedErrors += errorCount;
        errorCounts[9] += errorCount;
        printf("\tLogic (one iteration): %u errors (%u ms)\n",errorCount,end-start);
        // }}}
        // Logic, 4 iterations {{{
        errorCount = 0;
        start=getTimeMilliseconds();
        tester.gpuShortLCG0(errorCount,4);
        end=getTimeMilliseconds();
        accumulatedErrors += errorCount;
        errorCounts[10] += errorCount;
        printf("\tLogic (4 iterations): %u errors (%u ms)\n",errorCount,end-start);
        // }}}
       // Logic, shared-memory, 1 iteration {{{
        errorCount = 0;
        start=getTimeMilliseconds();
        tester.gpuShortLCG0Shmem(errorCount,1);
        end=getTimeMilliseconds();
        accumulatedErrors += errorCount;
        errorCounts[11] += errorCount;
        printf("\tLogic (shared memory, one iteration): %u errors (%u ms)\n",errorCount,end-start);
        // }}}
        // Logic, shared-memory, 4 iterations {{{
        errorCount = 0;
        start=getTimeMilliseconds();
        tester.gpuShortLCG0Shmem(errorCount,4);
        end=getTimeMilliseconds();
        accumulatedErrors += errorCount;
        errorCounts[12] += errorCount;
        printf("\tLogic (shared-memory, 4 iterations): %u errors (%u ms)\n",errorCount,end-start);
        // }}}
        
        printf("\n");
    }
    printf("Final error count after %u iterations over %u MiB of GPU memory: %u errors\n",maxIters,tester.size(),accumulatedErrors);
    return (accumulatedErrors != 0);
}
