Example application
===================

This tutorial describes a demo application that reads and writes files on SD card using the SPI interface. 

app_sdcard_test
-----------------------------
- Demonstrate read and write files on SD card using the SPI interface. At the end, it prints the read/write performances of the filesystem on SD card using the SPI.

Application notes
-----------------

Getting started
+++++++++++++++

   #. Connect XA-SK-FLASH 1V0 Slice Card to the XP-SKC-L16 sliceKIT Core board using the connector marked with the ``TRIANGLE``.
   #. Connect the xTAG Adapter to sliceKIT Core board, and connect xTAG-2 to the adapter. 
   #. Connect the xTAG-2 to host PC. Note that the USB cable is not provided with the sliceKIT starter kit.
   #. Set the ``XMOS LINK`` to ``OFF`` on the xTAG Adapter(XA-SK-XTAG2).
   #. Make sure the SD card slot in XA-SK-FLASH slice has a Class-4 SD card in it.
   #. Switch on the power supply to the sliceKIT Core board.

Import and Build the Application
++++++++++++++++++++++++++++++++

   #. Open xTIMEcomposer and check that it is operating in online mode. Open the edit perspective (Window->Open Perspective->XMOS Edit).
   #. Locate the ``'SD card demo'`` item in the xSOFTip pane on the bottom left of the window and drag it into the Project Explorer window in the xTIMEcomposer. This will also cause the modules on which this application depends to be imported as well. 
   #. Click on the app_sdcard_test item in the Explorer pane then click on the build icon (hammer) in xTIMEcomposer. Check the console window to verify that the application has built successfully.

Run the Application
+++++++++++++++++++

Now that the application has been compiled, the next step is to run it on the sliceKIT Core Board using the tools to load the application over JTAG (via the xTAG-2 and xTAG Adapter card) into the xCORE multicore microcontroller.

   #. Select the file ``app_sdcard_test.xe`` in the ``app_display_controller_demo`` project from the Project Explorer.
   #. Click on the ``Run`` icon (the white arrow in the green circle). 
   #. At the ``Select Device`` dialog select ``XMOS xTAG-2 connect to L1[0..1]`` and click ``OK``.
   #. The application starts executing and reads/writes contents into SD card.
