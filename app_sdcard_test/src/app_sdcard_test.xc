// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*
 ============================================================================
 Name        : sdcard_test
 Description : SD card host driver test
 ============================================================================
 */
#include <xs1.h>
#include <print.h>
#include <platform.h>

#include "ff.h"    /* file system routines */

FATFS Fatfs;            /* File system object */
FIL Fil;                /* File object */
BYTE Buff[512*40];      /* File read buffer (40 SD card blocks to let multiblock operations (if file not fragmented) */
timer t;

void die(FRESULT rc ) /* Stop with dying message */
{
  printstr("\nFailed with rc=");
  printint(rc);
  for(;;);
}

int main(void)
{
  FRESULT rc;                     /* Result code */
  DIR dir;                        /* Directory object */
  FILINFO fno;                    /* File information object */
  UINT bw, br, i;
  unsigned int T, T1;

  for( i = 0; i < sizeof(Buff); i++) Buff[i] = i + i / 512; // fill the buffer with some data

  f_mount(0, &Fatfs);             /* Register volume work area (never fails) for SD host interface #0 */
  {
    FATFS* unsafe fs;
    DWORD fre_clust, fre_sect, tot_sect;

unsafe {
    /* Get volume information and free clusters of drive 0 */
    rc = f_getfree("0:", &fre_clust, &fs);
    if(rc) die(rc);

    /* Get total sectors and free sectors */
    tot_sect = (fs->n_fatent - 2) * fs->csize;
    fre_sect = fre_clust * fs->csize;
    }

    /* Print free space in unit of KB (assuming 512 bytes/sector) */
    printint(fre_sect/2);
    printstrln("KB total drive space.");
    printint(tot_sect / 2);
    printstrln(" KB available");
  }

  /****************************/
  printstr("\nDeleting file Data.bin if existing...");
  rc = f_unlink ("Data.bin");    /* delete file if exist */
  if( FR_OK == rc) printstrln("deleted.");
  else printstrln("done.");

  /****************************/

  printstr("\nCreating a new file Data.bin...");
  rc = f_open(&Fil, "Data.bin", FA_WRITE | FA_CREATE_ALWAYS);
  if(rc) die(rc);
  printstrln("done.\n");

  printstrln("Writing data to the file...");
  t :> T1;
  rc = f_write(&Fil, Buff, sizeof(Buff), &bw);
  t :> T;
  T -= T1;
  if(rc) die(rc);
  printstr("Time taken:");
  printintln(T);
  printint(bw);
  printstr(" bytes written. Write rate: ");
  printint((bw*100000)/T);
  printstrln(" KBytes/Sec");

  printstr("\nClosing the file...");
  rc = f_close(&Fil);
  if(rc) die(rc);
  printstrln("done.");
  /****************************/

  printstr("\nOpening an existing file: Data.bin...");
  rc = f_open(&Fil, "Data.bin", FA_READ);
  if(rc) die(rc);
  printstrln("done.");

  printstrln("\nReading file content...");
  t :> T1;
  rc = f_read(&Fil, Buff, sizeof(Buff), &br);
  t :> T;
  T -= T1;
  if(rc) die(rc);
  printint(br);
  printstr(" bytes read. Read rate: ");
  printint((br*100000)/T);
  printstrln("KBytes/Sec");

  printstr("\nClosing the file...");
  rc = f_close(&Fil);
  if(rc) die(rc);
  printstrln("done.");

  /****************************/
#if _FS_MINIMIZE < 2
  printstrln("\nOpen root directory.");
  rc = f_opendir(&dir, "");
  if(rc) die(rc);

  printstrln("\nDirectory listing...");
  for(;;)
  {
    rc = f_readdir(&dir, &fno);    /* Read a directory item */
    if(rc || !fno.fname[0]) break; /* Error or end of dir */
    if(fno.fattrib & AM_DIR)
    {
      printstr("   <dir>  ");
      printstrln(fno.fname);
    }
    else
    {
        printstr(fno.fname); printstr("  ");
        printintln(fno.fsize);
    }
  }
  if(rc) die(rc);
#endif
  /****************************/

  printstrln("\nTest completed.");
  return 0;
}
