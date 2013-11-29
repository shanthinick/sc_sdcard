.. _sec_sdcardSPI_api:

Project structure
=================

To build a project including the ``module_sdcardSPI`` the following module is required:
    * module: module_spi_master

The below section details the APIs in the SD card module. For details about the FatFS APIs please refer to the respective repositories.

Configuration defines
---------------------

The ``module_sdcardSPI`` requires a configuration defined in spi_conf.h. The module requires nothing to be additionally defined.

**SPI_MASTER_SD_CARD_COMPAT**
	This defines the SPI modifications needed for SD card usage. This needs to be set to 1 for SD cards to use SPI interface.


API
---

The``module_sdcardSPI`` functionality is defined in
    * ``SDCardHostSPI.xc``
    * ``spi_conf.h``

The SD card module provides APIs to read/write data to SD card. 

The SD card APIs are as follows:

.. doxygenfunction:: disk_initialize
.. doxygenfunction:: disk_status
.. doxygenfunction:: disk_read
.. doxygenfunction:: disk_write
.. doxygenfunction:: disk_ioctl

The SD card APIs use the module_spi_master APIs.
