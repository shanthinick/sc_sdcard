Overview
========

The SD card module is used to talk to the SD card through the SPI interface. 

Features
--------

  * Low level functions for accessing SD card
  * Uses SPI interface

Memory requirements
-------------------
+------------------+---------------+
| Resource         | Usage         |
+==================+===============+
| Stack            | 220 bytes     |
+------------------+---------------+
| Program          | 5 KB          |
+------------------+---------------+

Resource requirements
---------------------
+--------------+-------+
| Resource     | Usage |
+==============+=======+
| Clocks       |   1   |
+--------------+-------+
| Threads      |   1   |
+--------------+-------+

Performance
----------- 

The achievable effective bandwidth varies according to the available xCORE MIPS. The maximum pixel clock supported is 25MHz.

