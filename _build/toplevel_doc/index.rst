SD Card Libary
..............

:Version: 59d2af25f8382b335bdfff02a9e68272537acfed
:Vendor: XMOS
:Description: SD card





Software Blocks
===============

SD card demo application (app_sdcard_test)
 Application demonstrating the use of FAT filesystem to read/write files on SD card using the SPI interface
FAT Filesystem Library (module_FatFs)
 FAT filesystem library
SD Card Library (module_sdcardSPI)
 SD card library using the SPI interface

Documentation
===============

  * `SD card Demo Quickstart Guide <././app_sdcard_test/doc_quickstart/index.html>`_ `PDF <././app_sdcard_test/doc_quickstart.pdf>`_ 
  * `SD card component <././module_sdcardSPI/doc/index.html>`_ `PDF <././module_sdcardSPI/doc.pdf>`_ 
  * `FAT Filesystem component <././module_FatFs/doc/index.html>`_ `PDF <././module_FatFs/doc.pdf>`_ 
  * `Release Notes <././changelog.html>`_

Key Features
============

* Read and write data operations on SD cards using either the SPI interface or native 4bit interface
* Port of FatFS - FAT file system module R0.09 (C)ChaN, 2011 (http://elm-chan.org/fsw/ff/00index_e.html).
* **Beware: FAT with long file names may be covered by various patents (in particular those held by Microsoft). Use of this code may require licensing from the patent holders**
* **Beware: 4bit SD protocol is subject to petents of the SD Association. When enabled on commercial products a license may be required. (see: https://www.sdcard.org/developers/howto/ )**
* Benchmark with 4bit interface multiblock read speed is about 4MBytes/sec. 1.2MBytes/sec with SPI. 
* This application was tested with Class 4, 8GB microSD cards from 3 popular vendors.
  The vendors include:

 - SanDisk
 - Transcend
 - Kingston

Firmware Overview
=================

This module provides functions to initialize SD cards, read and write data.
Resources (ports and clock blocks) used for the interface need to be specified in either "module_sdcardSPI/SDCardHostSPI.xc" or "module_sdcard4bit/SDCardHost4bit.xc" in the initialization of the SDif structure. 
If you run it in a core other than XS1_G you need pull-up resistor for miso line (if in spi mode) or Cmd line and D0(=Dat port bit 3) line (if in 4bit bus mode)

Known Issues
============

Required software (dependencies)
================================

  * sc_slicekit_support
  * sc_spi

Support
=======

  This package is support by XMOS Ltd. Issues can be raised against the software
  at:

      http://www.xmos.com/support

.. toctree::
   :hidden:

   changelog
