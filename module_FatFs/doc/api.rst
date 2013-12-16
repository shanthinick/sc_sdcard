.. _sec_FatFs_api:

Project structure
=================

To build a project including the ``module_FatFs`` the following modules are required:
    * module: module_sdcardSPI module_spi_master

The below section details the APIs in the application. For details about the FatFS APIs please refer to the respective repositories.

Configuration defines
---------------------

The ``module_FatFs`` requires configurations defined in ffconf.h. The module requires nothing to be additionally defined.
However defines can be tuned in ffconf.h. Some of the defines are:

**_FS_TINY**
	This defines if the sector buffer in the file system object or the individual file object should be used. When _FS_TINY is set to 1, FatFs uses the sector buffer in the file system object.

**_FS_READONLY**
    Setting _FS_READONLY to 1 defines read only configuration. By default this is set to 0.
	
**_FS_MINIMIZE**
    This define sets minimization level to remove some functions. By default this is set to 0 to include full set of functions.


API
---

The``module_FatFs`` functionality is defined in
    * ``ff.c``
    * ``ccsbcs.c_``
    * ``ff.h``
    * ``ffconf.h``
    * ``integer.h``
    * ``diskio.h``
	
The FatFs module provides APIs to read/write files to SD card. 
 
The FatFs APIs are as follows:

.. doxygenfunction:: f_mount
.. doxygenfunction:: f_open
.. doxygenfunction:: f_read
.. doxygenfunction:: f_lseek
.. doxygenfunction:: f_close
.. doxygenfunction:: f_opendir
.. doxygenfunction:: f_readdir
.. doxygenfunction:: f_stat
.. doxygenfunction:: f_write
.. doxygenfunction:: f_getfree
.. doxygenfunction:: f_truncate
.. doxygenfunction:: f_unlink
.. doxygenfunction:: f_mkdir
.. doxygenfunction:: f_chmod
.. doxygenfunction:: f_rename
.. doxygenfunction:: f_chdrive
.. doxygenfunction:: f_chdir
.. doxygenfunction:: f_getcwd
.. doxygenfunction:: f_fdisk
.. doxygenfunction:: f_putc
.. doxygenfunction:: f_printf

The FatFs APIs use the module_sdcardSPI APIs.
