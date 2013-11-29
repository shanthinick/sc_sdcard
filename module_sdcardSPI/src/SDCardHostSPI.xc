// MMCv3/SDv1/SDv2 (in SPI mode) control module
// Features and Limitations:
// * No Media Change Detection - Application program must re-mount the volume after media change or it results a hard error.

#include "diskio.h"    /* Common include file for FatFs and disk I/O layer */
#include <stdio.h> /* for the printf function */
#include <xs1.h>
#include <xclib.h>
#include "spi_master.h"
#include <xccompat.h>
#include "spi_conf.h"

BYTE cardType; /* b0:MMC, b1:SDv1, b2:SDv2, b3:Block addressing */
DSTATUS stat; /* Disk status */

/* List the ports used for interfaces */
spi_master_interface spi_if =
{
    XS1_CLKBLK_1,
    XS1_CLKBLK_2,
    XS1_PORT_1I,
    XS1_PORT_1J,
    XS1_PORT_1L
};
out buffered port:4 spi_ss = XS1_PORT_4E; // Chip select

out port p_led=XS1_PORT_8D;


void dly_us(int n)
{
  timer tmr;
  unsigned t;

  tmr :> t;
  t += 100*n;
  tmr when timerafter(t) :> void;
}

#define DLY_US(n) { dly_us(n); }    /* Delay n microseconds */

/*--------------------------------------------------------------------------

   Module Private Functions

---------------------------------------------------------------------------*/

/* MMC/SD command (SPI mode) */
#define CMD0   (0)     /* GO_IDLE_STATE */
#define CMD1   (1)     /* SEND_OP_COND */
#define ACMD41 (0x80+41) /* SEND_OP_COND (SDC) */
#define CMD8   (8)     /* SEND_IF_COND */
#define CMD9   (9)     /* SEND_CSD */
#define CMD10  (10)    /* SEND_CID */
#define CMD12  (12)    /* STOP_TRANSMISSION */
#define CMD13  (13)    /* SEND_STATUS */
#define ACMD13 (0x80+13) /* SD_STATUS (SDC) */
#define CMD16  (16)    /* SET_BLOCKLEN */
#define CMD17  (17)    /* READ_SINGLE_BLOCK */
#define CMD18  (18)    /* READ_MULTIPLE_BLOCK */
#define CMD23  (23)    /* SET_BLOCK_COUNT */
#define ACMD23 (0x80+23)  /* SET_WR_BLK_ERASE_COUNT (SDC) */
#define CMD24  (24)    /* WRITE_BLOCK */
#define CMD25  (25)    /* WRITE_MULTIPLE_BLOCK */
#define CMD41  (41)    /* SEND_OP_COND (ACMD) */
#define CMD55  (55)    /* APP_CMD */
#define CMD58  (58)    /* READ_OCR */

/* Card type flags (CardType) */
#define CT_MMC    0x01    /* MMC ver 3 */
#define CT_SD1    0x02    /* SD ver 1 */
#define CT_SD2    0x04    /* SD ver 2 */
#define CT_SDC    (CT_SD1|CT_SD2)  /* SD */
#define CT_BLOCK  0x08    /* Block addressing */

/*-----------------------------------------------------------------------*/
/* Wait for card ready                                                   */
/*-----------------------------------------------------------------------*/

static
int wait_ready (BYTE drv)  /* 1:OK, 0:Timeout */
{
  BYTE d[1];
  UINT tmr;

  for (tmr = 5000; tmr; tmr--)
  {  /* Wait for ready in timeout of 500ms */
 	d[0] = spi_master_in_byte(spi_if);
    if (d[0] == 0xFF) break;
    DLY_US(100);
  }
  return tmr ? 1 : 0;
}

/*-----------------------------------------------------------------------*/
/* Deselect the card and release SPI bus                                 */
/*-----------------------------------------------------------------------*/

static
void deselect (BYTE drv)
{
  BYTE d[1];
  sync(spi_if.sclk);
  spi_ss <: 0xF;

  /* Dummy clock (force DO hi-z for multiple slave SPI) */
  d[0] = spi_master_in_byte(spi_if);
}

/*-----------------------------------------------------------------------*/
/* Select the card and wait for ready                                    */
/*-----------------------------------------------------------------------*/

static
int Select (BYTE drv)  /* 1:OK, 0:Timeout */
{
  BYTE d[1];

  sync(spi_if.sclk);
  spi_ss <: 0xD;

  /* Dummy clock (force DO enabled) */
  d[0] = spi_master_in_byte(spi_if);
  if (wait_ready(drv)) return 1;  /* OK */
  deselect(drv);
  return 0;      /* Failed */
}

/*-----------------------------------------------------------------------*/
/* Receive a data packet from the card                                   */
/*-----------------------------------------------------------------------*/
#pragma unsafe arrays
static inline
int rcvr_datablock (BYTE drv,  /* 1:OK, 0:Failed */
  BYTE buff[],      /* Data buffer to store received data */
  UINT btr      /* Byte count */
)
{
  BYTE d[2];
  UINT tmr;

  for (tmr = 1000; tmr; tmr--)
  {  /* Wait for data packet in timeout of 100ms */
	d[0] = spi_master_in_byte(spi_if);
    if (d[0] != 0xFF) break;
    DLY_US(100);
  }
  if (d[0] != 0xFE) return 0;    /* If not valid data token, return with error */

  /* Receive the data block into buffer */
  spi_master_in_buffer(spi_if, buff, btr);
  
  /* Discard CRC */
  d[0] = spi_master_in_short(spi_if);
  
  return 1;            /* Return with success */
}

/*-----------------------------------------------------------------------*/
/* Send a data packet to the card                                        */
/*-----------------------------------------------------------------------*/
#pragma unsafe arrays
static
int xmit_datablock (BYTE drv,  /* 1:OK, 0:Failed */
  const BYTE (&?buff)[],  /* 512 byte data block to be transmitted */
  BYTE token      /* Data/Stop token */
)
{
  BYTE d[2];

  if (!wait_ready(drv)) return 0;

  d[0] = token;
  /* Xmit a token */
  spi_master_out_byte(spi_if, d[0]);

  /* Is it data token? */
  if (token != 0xFD)
  {    
    /* Xmit the 512 byte data block to MMC/SD */
    spi_master_out_buffer(spi_if, buff, 512);
    /* Xmit dummy CRC (0xFF,0xFF) */
    d[0] = spi_master_in_short(spi_if);
    /* Receive data response */
    d[0] = spi_master_in_byte(spi_if);
	
    if ((d[0] & 0x1F) != 0x05)  /* If not accepted, return with error */
      return 0;
  }
  return 1;
}

/*-----------------------------------------------------------------------*/
/* Send a command packet to the card                                     */
/*-----------------------------------------------------------------------*/

static
BYTE send_cmd (BYTE drv,    /* Returns command response (bit7==1:Send failed)*/
  BYTE cmd,    /* Command byte */
  DWORD arg    /* Argument */
)
{
  BYTE n, d[1], buf[6];

  if (cmd & 0x80)
  {  /* ACMD<n> is the command sequense of CMD55-CMD<n> */
    cmd &= 0x7F;
    n = send_cmd(drv, CMD55, 0);
    if (n > 1) return n;
  }

  /* Select the card and wait for ready */
  deselect(drv);
  if (!Select(drv)) return 0xFF;

  /* Send a command packet */
  buf[0] = 0x40 | cmd;      /* Start + Command index */
  buf[1] = arg >> 24;    /* Argument[31..24] */
  buf[2] = arg >> 16;    /* Argument[23..16] */
  buf[3] = arg >> 8;    /* Argument[15..8] */
  buf[4] = arg;        /* Argument[7..0] */
  n = 0x01;            /* Dummy CRC + Stop */
  if (cmd == CMD0) n = 0x95;    /* (valid CRC for CMD0(0)) */
  if (cmd == CMD8) n = 0x87;    /* (valid CRC for CMD8(0x1AA)) */
  buf[5] = n;
  
  spi_master_out_buffer(spi_if, buf, 6);

  /* Receive command response */
  /* Skip a stuff byte when stop reading */
  if (cmd == CMD12) 
     d[0] = spi_master_in_byte(spi_if);
  n = 10;                /* Wait for a valid response in timeout of 10 attempts */
  do
    d[0] = spi_master_in_byte(spi_if);
  while ((d[0] & 0x80) && --n);
  return d[0];      /* Return with the response value */
}

/*--------------------------------------------------------------------------

   Public Functions

---------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------*/
/* Get Disk Status                                                       */
/*-----------------------------------------------------------------------*/

DSTATUS disk_status (
  BYTE drv      /* Drive number (always 0) */
)
{
  DSTATUS s;
  BYTE d[1];

  /* Check if the card is kept initialized */
  s = stat;
  if (!(s & STA_NOINIT))
  {
    if (send_cmd(drv, CMD13, 0))  /* Read card status */
      s = STA_NOINIT;
    /* Receive following half of R2 */
	d[0] = spi_master_in_byte(spi_if);
    deselect(drv);
  }
  stat = s;

  return s;
}

/*-----------------------------------------------------------------------*/
/* Initialize Disk Drive                                                 */
/*-----------------------------------------------------------------------*/

DSTATUS disk_initialize (
  BYTE drv    /* Physical drive nmuber (0) */
)
{
  BYTE n, ty, cmd, buf[4];
  UINT buffer;
  UINT tmr;
  DSTATUS s;
  p_led <: 0x0; /* Turn ON LEDs */
 
  spi_master_init(spi_if, DEFAULT_SPI_CLOCK_DIV);
  spi_ss <: 0xF;
  stat = STA_NOINIT;
  buf[0]=0xFF;
  for (n = 10; n; n--) /* 80 dummy clocks */
     spi_master_out_byte(spi_if, buf[0]); /* Dummy writes */
     //buf[0] = spi_master_in_byte(spi_if); /* Some devices need dummy reads instead of writes */
	  
  ty = 0;
  if (send_cmd(drv, CMD0, 0) == 1) {      /* Enter Idle state */
    if (send_cmd(drv, CMD8, 0x1AA) == 1) {  /* SDv2? */
      /* Get trailing return value of R7 resp */
	  buffer = spi_master_in_word(spi_if);
      if (buffer && 0x01AA) {    /* The card can work at vdd range of 2.7-3.6V */
        for (tmr = 1000; tmr; tmr--) {      /* Wait for leaving idle state (ACMD41 with HCS bit) */
          if (send_cmd(drv, ACMD41, 1UL << 30) == 0) break;
          DLY_US(1000);
        }
        if (tmr && send_cmd(drv, CMD58, 0) == 0) {  /* Check CCS bit in the OCR */
	  buffer = spi_master_in_word(spi_if);
          ty = (buffer & 0x40000000) ? CT_SD2 | CT_BLOCK : CT_SD2;  /* SDv2 */
        }
      }
    } else {              /* SDv1 or MMCv3 */
      if (send_cmd(drv, ACMD41, 0) <= 1)   {
        ty = CT_SD1; cmd = ACMD41;  /* SDv1 */
      } else {
        ty = CT_MMC; cmd = CMD1;  /* MMCv3 */
      }
      for (tmr = 1000; tmr; tmr--) {      /* Wait for leaving idle state */
        if (send_cmd(drv, ACMD41, 0) == 0) break;
        DLY_US(1000);
      }
      if (!tmr || send_cmd(drv, CMD16, 512) != 0)  /* Set R/W block length to 512 */
        ty = 0;
    }
  }
  cardType = ty;
  s = ty ? 0 : STA_NOINIT;
  stat = s;

  deselect(drv);

  stop_clock(spi_if.blk1);
  set_clock_div(spi_if.blk1, 1);
  start_clock(spi_if.blk1);
  return s;
}


typedef unsigned char DATABLOCK[512];

/*-----------------------------------------------------------------------*/
/* Read Sector(s)                                                        */
/*-----------------------------------------------------------------------*/
#pragma unsafe arrays
DRESULT disk_read (
  BYTE drv,      /* Physical drive nmuber (0) */
  BYTE buff[],      /* Pointer to the data buffer to store read data */
  DWORD sector,    /* Start sector number (LBA) */
  BYTE count      /* Sector count (1..128) */
)
{
  BYTE BlockCount = 0;

  if (disk_status(drv) & STA_NOINIT) return RES_NOTRDY;
  if (!count) return RES_PARERR;
  if (!(cardType & CT_BLOCK)) sector *= 512;  /* Convert LBA to byte address if needed */

  if (count == 1) {  /* Single block read */
    if ((send_cmd(drv, CMD17, sector) == 0)  /* READ_SINGLE_BLOCK */
      && rcvr_datablock(drv, buff, 512))
      count = 0;
  }
  else {        /* Multiple block read */
    if (send_cmd(drv, CMD18, sector) == 0) {  /* READ_MULTIPLE_BLOCK */
      do {
        if (!rcvr_datablock(drv, (buff, DATABLOCK[])[BlockCount++], 512)) break;
      } while (--count);
      send_cmd(drv, CMD12, 0);        /* STOP_TRANSMISSION */
    }
  }
  deselect(drv);

  return count ? RES_ERROR : RES_OK;
}



/*-----------------------------------------------------------------------*/
/* Write Sector(s)                                                       */
/*-----------------------------------------------------------------------*/
#pragma unsafe arrays
DRESULT disk_write (
  BYTE drv,      /* Physical drive nmuber (0) */
  const BYTE buff[],  /* Pointer to the data to be written */
  DWORD sector,    /* Start sector number (LBA) */
  BYTE count      /* Sector count (1..128) */
)
{
  BYTE BlockCount = 0;

  if (disk_status(drv) & STA_NOINIT) return RES_NOTRDY;
  if (!count) return RES_PARERR;
  if (!(cardType & CT_BLOCK)) sector *= 512;  /* Convert LBA to byte address if needed */

  if (count == 1) {  /* Single block write */
    if ((send_cmd(drv, CMD24, sector) == 0)  /* WRITE_BLOCK */
      && xmit_datablock(drv, buff, 0xFE))
      count = 0;
  }
  else {        /* Multiple block write */
    if (cardType & CT_SDC) send_cmd(drv, ACMD23, count);
    if (send_cmd(drv, CMD25, sector) == 0) {  /* WRITE_MULTIPLE_BLOCK */
      do {
        if (!xmit_datablock(drv, (buff, DATABLOCK[])[BlockCount++], 0xFC)) break;
      } while (--count);
      if (!xmit_datablock(drv, null, 0xFD))  /* STOP_TRAN token */
        count = 1;
    }
  }
  deselect(drv);

  return count ? RES_ERROR : RES_OK;
}



/*-----------------------------------------------------------------------*/
/* Miscellaneous Functions                                               */
/*-----------------------------------------------------------------------*/
#pragma unsafe arrays
DRESULT disk_ioctl (
  BYTE drv,    /* Physical drive nmuber (0) */
  BYTE ctrl,    /* Control code */
  BYTE buff[]    /* Buffer to send/receive control data */
)
{
  DRESULT res;
  BYTE n, csd[16];
  WORD cs;

  if (disk_status(drv) & STA_NOINIT) return RES_NOTRDY;  /* Check if card is in the socket */

  res = RES_ERROR;
  switch (ctrl) {
    case CTRL_SYNC:    /* Make sure that no pending write process */
      if (Select(drv)) {
        deselect(drv);
        res = RES_OK;
      }
      break;

    case GET_SECTOR_COUNT :  /* Get number of sectors on the disk (DWORD) */
      if ((send_cmd(drv, CMD9, 0) == 0) && rcvr_datablock(drv, csd, 16)) {
        if ((csd[0] >> 6) == 1) {  /* SDC ver 2.00 */
          cs= csd[9] + ((WORD)csd[8] << 8) + 1;
          //*(DWORD*)buff = (DWORD)cs << 10;
          for(DWORD Val = cs << 10, i = 0; i < sizeof(DWORD); i++)
            buff[i] = (Val, BYTE[])[i];
        } else {          /* SDC ver 1.XX or MMC */
          n = (csd[5] & 15) + ((csd[10] & 128) >> 7) + ((csd[9] & 3) << 1) + 2;
          cs = (csd[8] >> 6) + ((WORD)csd[7] << 2) + ((WORD)(csd[6] & 3) << 10) + 1;
          //*(DWORD*)buff = (DWORD)cs << (n - 9);
          for(DWORD Val = (DWORD)cs << (n - 9), i = 0; i < sizeof(DWORD); i++)
            buff[i] = (Val, BYTE[])[i];
        }
        res = RES_OK;
      }
      break;

    case GET_BLOCK_SIZE :  /* Get erase block size in unit of sector (DWORD) */
      //*(DWORD*)buff = 128;
      for(DWORD Val = 128, i = 0; i < sizeof(DWORD); i++)
        buff[i] = (Val, BYTE[])[i];
      res = RES_OK;
      break;

    default:
      res = RES_PARERR;
      break;
  }

  deselect(drv);

  return res;
}

// User Provided Timer Function for FatFs module
DWORD get_fattime(void)
{
  return ((DWORD)(2010 - 1980) << 25)  /* Fixed to Jan. 1, 2010 */
          | ((DWORD)1 << 21)
          | ((DWORD)1 << 16)
          | ((DWORD)0 << 11)
          | ((DWORD)0 << 5)
          | ((DWORD)0 >> 1);
}
