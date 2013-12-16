#ifndef _sdcard_spi_h_
#define _sdcard_spi_h_

#include <stdint.h>

/**
 * \brief Function to initialize disk.
 *
 * \param drv Physical drive nmuber (0).
 */
DSTATUS disk_initialize (BYTE drv);

/**
 * \brief Function to read data from a disk.
 *
 * \param drv Physical drive nmuber (0).
 * \param buff Pointer to the data buffer to store read data.
 * \param sector Start sector number (LBA).
 * \param count Sector count (1..128).
 */
DRESULT disk_read (BYTE drv, BYTE buff[], DWORD sector, BYTE count);

/**
 * \brief Function to write data to the disk.
 *
 * \param drv Physical drive nmuber (0).
 * \param buff Pointer to the data to be written.
 * \param sector Start sector number (LBA).
 * \param count Sector count (1..128).
 */
DRESULT disk_write (BYTE drv, const BYTE buff[], DWORD sector, BYTE count);
  
/**
 * \brief Function to control device specific features and miscellaneous functions.
 *
 * \param drv Physical drive nmuber (0).
 * \param ctrl Control code.
 * \param buff Buffer to send/receive control data.
 */
DRESULT disk_ioctl (BYTE drv, BYTE ctrl, BYTE buff[]);
  
/**
 * \brief Function to open or create a file.
 *
 * \param drv  Drive number (always 0).
 */
DSTATUS disk_status (BYTE drv);

#endif
  
