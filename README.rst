SD Card Libary
..............

:Stable release: 0.0.1

:Status:  alpha

:Maintainer:  interactive_matter

:Description:  SD card driver library


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

Known Issues
============


Required Repositories
================

* xcommon git\@github.com:xcore/xcommon.git

Support
=======

Issues may be submitted via the Issues tab in this github repo. Response to any issues submitted are at the discretion of the maintainers of this component.
