# README for MemtestG80 open source edition

## CONTENTS

1. Description
2. How to build
3. Using MemtestG80 as a library
4. CLI Standalone Basic Usage
5. CLI Standalone Advanced Usage
6. FAQ
7. Licensing


## DESCRIPTION

MemtestG80 is a program to test the memory and logic of NVIDIA CUDA-enabled
GPUs for errors. 

This is the open-source version of MemtestG80, implementing the same memory
tests as the closed-source version. The intended usage is as a library so that
other software developers can use the MemtestG80 tests to validate the correct
operation of GPUs in their own code. In addition to the core memory testing
libraries, this package contains the source code to a limited version of the
command-line interface standalone tester included in the closed-source build;
certain capabilities, such as the ability to transmit results back to Stanford,
are not present in the open-source version.

The closed-source version can be found at https://simtk.org/home/memtest. The
open-source version lives at http://github.com/ihaque/memtestG80.

This document concerns the open-source version.

## HOW TO BUILD

First, ensure that the CUDA toolkit binaries and libraries are included in the
appropriate path variables for you system so that you can run the nvcc
toolchain and successfully execute CUDA programs.

Makefiles for 32- and 64-bit Linux, Mac OS X, and 32-bit Windows are included
From the root of the source package, it should be possible to build MemtestG80
by executing the following:

    make -f Makefile.OS

where `OS` is one of linux32, linux64, osx, or windows. Note that on Windows,
GNU make (included, for example, in Cygwin) is assumed, not Microsoft nmake.

The resulting executable, memtestG80, should be immediately executable
on Linux and OS X platforms. On Windows, libiconv-2.dll, libintl-2.dll, and
popt1.dll must be copied from the popt/win32 subdirectory into a directory in
the DLL search path (most conveniently, the root of the source distribution).
MemtestG80 uses the MIT/X licensed popt library to handle command line
arguments; precompiled static libraries are provided for Linux and OS X, but
dynamic libraries for Windows.

## USING MEMTESTG80 AS A LIBRARY

We encourage software developers to use MemtestG80 as a code library in their
programs to verify the correct operation of GPUs on which they execute. The
code is licensed under the LGPL, so developers of both open- and closed-source
software can use it - developers of closed-source software are required to link
to MemtestG80 via a shared library (.so, .dll) mechanism; open-source software
can integrate it via static linkage.

The API for the memory tests is defined in memtestG80_core.h. There are two
APIs - a low-level API defined by CUDA `__host__` functions, and a high-level
API defined by the memtestState class. At an even lower level, the individual
tests are implemented by CUDA `__global__` functions. Naming conventions are
explained in comments in memtestG80_core.cu.

In general, for ease of use, we recommend the use of the high-level (object-
oriented) API. An example of the API's usage can be found in the standalone
tester, memtestG80_cli.cu.

## CLI STANDALONE BASIC USAGE

MemtestG80 is available for Windows, Linux, and Mac OS X-based machines. In the
following directions, please replace "MemtestG80" with the name of the program
included in the distribution for your operating system.

MemtestG80 is a command line application; to run it, start it from a command
prompt (Start->Run->cmd in Windows, Terminal.app in OS X). For basic operation,
just run it from the command prompt:

    MemtestG80

By default, MemtestG80 will test 128 megabytes of memory on your first video
card, running 50 iterations of its tests. On typical machines, each iteration
will complete in under 10 seconds with these parameters (the speed will vary
both with the speed of the card tested and the amount of memory tested). The
amount of memory tested and number of test iterations can be modified by adding
command line parameters as follows:

    MemtestG80 [amount of RAM in megabytes] [number of test iterations]

For example, to run MemtestG80 over 256 megabytes of RAM, with 100 test
iterations, execute the following command:
    
    MemtestG80 256 100

Be aware that not all of the memory on your video card can be tested, as part
of it is reserved for use by the operating system. If too large a test region
is specified, the program will print a warning and quit. Also, if the tested
GPU is currently driving a graphical desktop, the NVIDIA driver may impose time
limits on test execution such that tests over very large test regions will
time out. This can be easily recognized by seeing a number of test errors
larger than 4 billion, which go away when a smaller region is tested.

If you suspect that your graphics card is having issues (for example, it fails
running Folding@home work units), we strongly recommend that you test as large
a memory region as is practical, and run thousands of test iterations. In our
testing, we have found that even "problematic" cards may only fail sporadically
(e.g., once every 50,000 test iterations). Like other stress testing tools,
to properly verify stability MemtestG80 should be run for an extended period of
time.

## CLI STANDALONE ADVANCED USAGE

MemtestG80 supports the use of various command line flags to enable
advanced functionality. Flags may be issued in any order, and may precede
or follow the memory size and iteration count parameters (but the memory size
must always precede the iteration count).

To run MemtestG80 on a GPU other than the first, use the --gpu or -g flags,
passing the index of the GPU to test (starting at zero). For example, to run
MemtestG80 on the third GPU in a system:
    
    MemtestG80 --gpu 2

Finally, to display the license agreement for MemtestG80, provide the --license
or -l options:

    MemtestG80 -l

6. Frequently Asked Questions

- I have an {ATI,NVIDIA 5/6/7-series} video card and it doesn't work!
        * Currently, only NVIDIA CUDA-enabled GPUs are supported. As of
          this writing, only the GeForce 8-, 9-, and GTX-series, the Quadro
          FX series, and the Tesla series of NVIDIA products support CUDA.

- I have a CUDA-enabled card, but it still doesn't work!
        * You must have a CUDA-enabled graphics driver installed. See
          the Downloads section of http://nvidia.com/cuda to obtain a CUDA
          driver.
        
- I get an error complaining about a missing "cudart.dll" on Windows!
        * This is a CUDA runtime file which we currently cannot redistribute
          with MemtestG80. However, a version of the file is bundled with the
          Folding@home GPU client; that file will work if copied into the 
          MemtestG80 runtime directory.

## Licensing

The source code to the open-source edition of MemtestG80 is Copyright 2009,
Stanford University, and is licensed under the terms of the GNU Lesser General
Public License, version 3, reproduced below:

```
		   GNU LESSER GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.


  This version of the GNU Lesser General Public License incorporates
the terms and conditions of version 3 of the GNU General Public
License, supplemented by the additional permissions listed below.

  0. Additional Definitions.

  As used herein, "this License" refers to version 3 of the GNU Lesser
General Public License, and the "GNU GPL" refers to version 3 of the GNU
General Public License.

  "The Library" refers to a covered work governed by this License,
other than an Application or a Combined Work as defined below.

  An "Application" is any work that makes use of an interface provided
by the Library, but which is not otherwise based on the Library.
Defining a subclass of a class defined by the Library is deemed a mode
of using an interface provided by the Library.

  A "Combined Work" is a work produced by combining or linking an
Application with the Library.  The particular version of the Library
with which the Combined Work was made is also called the "Linked
Version".

  The "Minimal Corresponding Source" for a Combined Work means the
Corresponding Source for the Combined Work, excluding any source code
for portions of the Combined Work that, considered in isolation, are
based on the Application, and not on the Linked Version.

  The "Corresponding Application Code" for a Combined Work means the
object code and/or source code for the Application, including any data
and utility programs needed for reproducing the Combined Work from the
Application, but excluding the System Libraries of the Combined Work.

  1. Exception to Section 3 of the GNU GPL.

  You may convey a covered work under sections 3 and 4 of this License
without being bound by section 3 of the GNU GPL.

  2. Conveying Modified Versions.

  If you modify a copy of the Library, and, in your modifications, a
facility refers to a function or data to be supplied by an Application
that uses the facility (other than as an argument passed when the
facility is invoked), then you may convey a copy of the modified
version:

   a) under this License, provided that you make a good faith effort to
   ensure that, in the event an Application does not supply the
   function or data, the facility still operates, and performs
   whatever part of its purpose remains meaningful, or

   b) under the GNU GPL, with none of the additional permissions of
   this License applicable to that copy.

  3. Object Code Incorporating Material from Library Header Files.

  The object code form of an Application may incorporate material from
a header file that is part of the Library.  You may convey such object
code under terms of your choice, provided that, if the incorporated
material is not limited to numerical parameters, data structure
layouts and accessors, or small macros, inline functions and templates
(ten or fewer lines in length), you do both of the following:

   a) Give prominent notice with each copy of the object code that the
   Library is used in it and that the Library and its use are
   covered by this License.

   b) Accompany the object code with a copy of the GNU GPL and this license
   document.

  4. Combined Works.

  You may convey a Combined Work under terms of your choice that,
taken together, effectively do not restrict modification of the
portions of the Library contained in the Combined Work and reverse
engineering for debugging such modifications, if you also do each of
the following:

   a) Give prominent notice with each copy of the Combined Work that
   the Library is used in it and that the Library and its use are
   covered by this License.

   b) Accompany the Combined Work with a copy of the GNU GPL and this license
   document.

   c) For a Combined Work that displays copyright notices during
   execution, include the copyright notice for the Library among
   these notices, as well as a reference directing the user to the
   copies of the GNU GPL and this license document.

   d) Do one of the following:

       0) Convey the Minimal Corresponding Source under the terms of this
       License, and the Corresponding Application Code in a form
       suitable for, and under terms that permit, the user to
       recombine or relink the Application with a modified version of
       the Linked Version to produce a modified Combined Work, in the
       manner specified by section 6 of the GNU GPL for conveying
       Corresponding Source.

       1) Use a suitable shared library mechanism for linking with the
       Library.  A suitable mechanism is one that (a) uses at run time
       a copy of the Library already present on the user's computer
       system, and (b) will operate properly with a modified version
       of the Library that is interface-compatible with the Linked
       Version.

   e) Provide Installation Information, but only if you would otherwise
   be required to provide such information under section 6 of the
   GNU GPL, and only to the extent that such information is
   necessary to install and execute a modified version of the
   Combined Work produced by recombining or relinking the
   Application with a modified version of the Linked Version. (If
   you use option 4d0, the Installation Information must accompany
   the Minimal Corresponding Source and Corresponding Application
   Code. If you use option 4d1, you must provide the Installation
   Information in the manner specified by section 6 of the GNU GPL
   for conveying Corresponding Source.)

  5. Combined Libraries.

  You may place library facilities that are a work based on the
Library side by side in a single library together with other library
facilities that are not Applications and are not covered by this
License, and convey such a combined library under terms of your
choice, if you do both of the following:

   a) Accompany the combined library with a copy of the same work based
   on the Library, uncombined with any other library facilities,
   conveyed under the terms of this License.

   b) Give prominent notice with the combined library that part of it
   is a work based on the Library, and explaining where to find the
   accompanying uncombined form of the same work.

  6. Revised Versions of the GNU Lesser General Public License.

  The Free Software Foundation may publish revised and/or new versions
of the GNU Lesser General Public License from time to time. Such new
versions will be similar in spirit to the present version, but may
differ in detail to address new problems or concerns.

  Each version is given a distinguishing version number. If the
Library as you received it specifies that a certain numbered version
of the GNU Lesser General Public License "or any later version"
applies to it, you have the option of following the terms and
conditions either of that published version or of any later version
published by the Free Software Foundation. If the Library as you
received it does not specify a version number of the GNU Lesser
General Public License, you may choose any version of the GNU Lesser
General Public License ever published by the Free Software Foundation.

  If the Library as you received it specifies that a proxy can decide
whether future versions of the GNU Lesser General Public License shall
apply, that proxy's public statement of acceptance of any version is
permanent authorization for you to choose that version for the
Library.
```