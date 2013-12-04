
Evaluation platforms
====================

.. _sec_hardware_platforms:

Recommended hardware
--------------------

sliceKIT
++++++++

This module may be evaluated using the sliceKIT modular development platform, available from digikey. Required board SKUs are:

   * XP-SKC-L2 (sliceKIT L2 Core Board) 
   * XA-SK-XTAG2 (sliceKIT xTAG adaptor) 
   * XA-SK-FLASH 1V0 Slice Card

Demonstration applications
--------------------------

Display controller application
++++++++++++++++++++++++++++++

   * Package: sc_sdcard
   * Application: app_sdcard_test

This demo uses the ``module_FatFs`` along with the ``module_sdcardSPI`` and ``module_spi_master``.

Required board SKUs for this demo are:

   * XP-SKC-L16 (sliceKIT L16 Core Board) plus XA-SK-XTAG2 (sliceKIT xTAG adaptor) 


