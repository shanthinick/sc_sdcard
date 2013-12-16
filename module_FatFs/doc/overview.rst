Overview
========

The FAT Filesystem module is used to read/write files into the FAT filesystem

Features
--------

  * APIs to access FAT filesystem
  * Port of FatFS - FAT file system module R0.09 (C)ChaN, 2011 (http://elm-chan.org/fsw/ff/00index_e.html).

Memory requirements
-------------------
+------------------+---------------+
| Resource         | Usage         |
+==================+===============+
| Stack            | 480 bytes     |
+------------------+---------------+
| Program          | 15 Kbytes     |
+------------------+---------------+

Resource requirements
---------------------
+--------------+-------+
| Resource     | Usage |
+==============+=======+
| Timers       |   1   |
+--------------+-------+
| Clocks       |   1   |
+--------------+-------+
| Threads      |   1   |
+--------------+-------+

Performance
----------- 

SPI mode 3 is used by the SD card driver. The performance measured includes FAT filesystem performance along with the SD card driver on SPI interface.

+----------+-------------------+
|   R/W    | PERFORMANCE       | 
+==========+===================+
|   WRITE  | 1061 KBytes/s     | 
+----------+-------------------+
|   READ   | 314 KBytes/s      |
+----------+-------------------+

