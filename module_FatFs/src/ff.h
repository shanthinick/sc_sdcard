/*---------------------------------------------------------------------------/
/  FatFs - FAT file system module include file  R0.09     (C)ChaN, 2011
/----------------------------------------------------------------------------/
/ FatFs module is a generic FAT file system module for small embedded systems.
/ This is a free software that opened for education, research and commercial
/ developments under license policy of following trems.
/
/  Copyright (C) 2011, ChaN, all right reserved.
/
/ * The FatFs module is a free software and there is NO WARRANTY.
/ * No restriction on use. You can use, modify and redistribute it for
/   personal, non-profit or commercial product UNDER YOUR RESPONSIBILITY.
/ * Redistributions of source code must retain the above copyright notice.
/
/----------------------------------------------------------------------------*/

#ifndef _FATFS
#define _FATFS  6502  /* Revision ID */

#if defined (__cplusplus) || defined (__XC__)
extern "C" {
#endif

#include "integer.h"  /* Basic integer types */
#include "ffconf.h"     /* FatFs configuration options */

#if _FATFS != _FFCONF
#error Wrong configuration file (ffconf.h).
#endif



/* Definitions of volume management */

#if _MULTI_PARTITION    /* Multiple partition configuration */
typedef struct {
  BYTE pd;  /* Physical drive number */
  BYTE pt;  /* Partition: 0:Auto detect, 1-4:Forced partition) */
} PARTITION;
extern PARTITION VolToPart[];  /* Volume - Partition resolution table */
#define LD2PD(vol) (VolToPart[vol].pd)  /* Get physical drive number */
#define LD2PT(vol) (VolToPart[vol].pt)  /* Get partition index */

#else            /* Single partition configuration */
#define LD2PD(vol) (vol)  /* Each logical drive is bound to the same physical drive number */
#define LD2PT(vol) 0    /* Always mounts the 1st partition or in SFD */

#endif



/* Type of path name strings on FatFs API */

#if _LFN_UNICODE      /* Unicode string */
#if !_USE_LFN
#error _LFN_UNICODE must be 0 in non-LFN cfg.
#endif
#ifndef _INC_TCHAR
typedef WCHAR TCHAR;
#define _T(x) L ## x
#define _TEXT(x) L ## x
#endif

#else            /* ANSI/OEM string */
#ifndef _INC_TCHAR
typedef char TCHAR;
#define _T(x) x
#define _TEXT(x) x
#endif

#endif



/* File system object structure (FATFS) */

typedef struct {
  BYTE  fs_type;    /* FAT sub-type (0:Not mounted) */
  BYTE  drv;      /* Physical drive number */
  BYTE  csize;      /* Sectors per cluster (1,2,4...128) */
  BYTE  n_fats;      /* Number of FAT copies (1,2) */
  BYTE  wflag;      /* win[] dirty flag (1:must be written back) */
  BYTE  fsi_flag;    /* fsinfo dirty flag (1:must be written back) */
  WORD  id;        /* File system mount ID */
  WORD  n_rootdir;    /* Number of root directory entries (FAT12/16) */
#if _MAX_SS != 512
  WORD  ssize;      /* Bytes per sector (512, 1024, 2048 or 4096) */
#endif
#if _FS_REENTRANT
  _SYNC_t  sobj;      /* Identifier of sync object */
#endif
#if !_FS_READONLY
  DWORD  last_clust;    /* Last allocated cluster */
  DWORD  free_clust;    /* Number of free clusters */
  DWORD  fsi_sector;    /* fsinfo sector (FAT32) */
#endif
#if _FS_RPATH
  DWORD  cdir;      /* Current directory start cluster (0:root) */
#endif
  DWORD  n_fatent;    /* Number of FAT entries (= number of clusters + 2) */
  DWORD  fsize;      /* Sectors per FAT */
  DWORD  fatbase;    /* FAT start sector */
  DWORD  dirbase;    /* Root directory start sector (FAT32:Cluster#) */
  DWORD  database;    /* Data start sector */
  DWORD  winsect;    /* Current sector appearing in the win[] */
  BYTE  win[_MAX_SS];  /* Disk access window for Directory, FAT (and Data on tiny cfg) */
} FATFS;



/* File object structure (FIL) */

typedef struct {
  FATFS*  fs;        /* Pointer to the owner file system object */
  WORD  id;        /* Owner file system mount ID */
  BYTE  flag;      /* File status flags */
  BYTE  pad1;
  DWORD  fptr;      /* File read/write pointer (0 on file open) */
  DWORD  fsize;      /* File size */
  DWORD  sclust;      /* File start cluster (0 when fsize==0) */
  DWORD  clust;      /* Current cluster */
  DWORD  dsect;      /* Current data sector */
#if !_FS_READONLY
  DWORD  dir_sect;    /* Sector containing the directory entry */
  BYTE*  dir_ptr;    /* Ponter to the directory entry in the window */
#endif
#if _USE_FASTSEEK
  DWORD*  cltbl;      /* Pointer to the cluster link map table (null on file open) */
#endif
#if _FS_SHARE
  UINT  lockid;      /* File lock ID (index of file semaphore table) */
#endif
#if !_FS_TINY
  BYTE  buf[_MAX_SS];  /* File data read/write buffer */
#endif
} FIL;



/* Directory object structure (DIR) */

typedef struct {
  FATFS*  fs;        /* Pointer to the owner file system object */
  WORD  id;        /* Owner file system mount ID */
  WORD  index;      /* Current read/write index number */
  DWORD  sclust;      /* Table start cluster (0:Root dir) */
  DWORD  clust;      /* Current cluster */
  DWORD  sect;      /* Current sector */
  BYTE*  dir;      /* Pointer to the current SFN entry in the win[] */
  BYTE*  fn;        /* Pointer to the SFN (in/out) {file[8],ext[3],status[1]} */
#if _USE_LFN
  WCHAR*  lfn;      /* Pointer to the LFN working buffer */
  WORD  lfn_idx;    /* Last matched LFN index number (0xFFFF:No LFN) */
#endif
} DIR;



/* File status structure (FILINFO) */

typedef struct {
  DWORD  fsize;      /* File size */
  WORD  fdate;      /* Last modified date */
  WORD  ftime;      /* Last modified time */
  BYTE  fattrib;    /* Attribute */
  TCHAR  fname[13];    /* Short file name (8.3 format) */
#if _USE_LFN
  TCHAR*  lfname;      /* Pointer to the LFN buffer */
  UINT   lfsize;      /* Size of LFN buffer in TCHAR */
#endif
} FILINFO;



/* File function return code (FRESULT) */

typedef enum {
  FR_OK = 0,        /* (0) Succeeded */
  FR_DISK_ERR,      /* (1) A hard error occured in the low level disk I/O layer */
  FR_INT_ERR,        /* (2) Assertion failed */
  FR_NOT_READY,      /* (3) The physical drive cannot work */
  FR_NO_FILE,        /* (4) Could not find the file */
  FR_NO_PATH,        /* (5) Could not find the path */
  FR_INVALID_NAME,    /* (6) The path name format is invalid */
  FR_DENIED,        /* (7) Acces denied due to prohibited access or directory full */
  FR_EXIST,        /* (8) Acces denied due to prohibited access */
  FR_INVALID_OBJECT,    /* (9) The file/directory object is invalid */
  FR_WRITE_PROTECTED,    /* (10) The physical drive is write protected */
  FR_INVALID_DRIVE,    /* (11) The logical drive number is invalid */
  FR_NOT_ENABLED,      /* (12) The volume has no work area */
  FR_NO_FILESYSTEM,    /* (13) There is no valid FAT volume */
  FR_MKFS_ABORTED,    /* (14) The f_mkfs() aborted due to any parameter error */
  FR_TIMEOUT,        /* (15) Could not get a grant to access the volume within defined period */
  FR_LOCKED,        /* (16) The operation is rejected according to the file shareing policy */
  FR_NOT_ENOUGH_CORE,    /* (17) LFN working buffer could not be allocated */
  FR_TOO_MANY_OPEN_FILES,  /* (18) Number of open files > _FS_SHARE */
  FR_INVALID_PARAMETER  /* (19) Given parameter is invalid */
} FRESULT;



/*--------------------------------------------------------------*/
/* FatFs module application interface                           */

/**
 * \brief Function to mount/unmount file system object to the FatFs module.
 *
 * \param vol Logical drive number to be mounted/unmounted n.
 * \param fs Pointer to new file system object (NULL for unmount)
 */
FRESULT f_mount (BYTE vol, FATFS *fs);            

/**
 * \brief Function to open or create a file.
 *
 * \param fp Pointer to the blank file object.
 * \param path Pointer to the file name.
 * \param mode Access mode and file open mode flags.
 */
FRESULT f_open (FIL *fp, const TCHAR* path, BYTE mode);     

/**
 * \brief Function to read data from a file.
 *
 * \param fp Pointer to the file object.
 * \param buff Pointer to data buffer.
 * \param btr Number of bytes to read.
 * \param br Pointer to number of bytes read.
 */
FRESULT f_read (FIL* fp, void* buff, UINT btr, UINT* br); 

/**
 * \brief Function to move file pointer of a file object.
 *
 * \param fp Pointer to the file object .
 * \param ofs File pointer from top of file .
 */
FRESULT f_lseek (FIL* fp, DWORD ofs);    

/**
 * \brief Function to close an open file object.
 *
 * \param fp     Pointer to the file object to be closed */
 */
FRESULT f_close (FIL *fp); 

/**
 * \brief Function to create a directory object.
 *
 * \param dj Pointer to directory object to create.
 * \param path Pointer to the directory path.
 */
FRESULT f_opendir (DIR* dj, const TCHAR* path);  

/**
 * \brief Function to read directory entry in sequence.
 *
 * \param dj Pointer to the open directory object.
 * \param fno Pointer to file information to return.
 */
FRESULT f_readdir (DIR* dj, FILINFO* fno);   
  
/**
 * \brief Function to get the file status.
 *
 * \param path Pointer to the file path.
 * \param fno Pointer to file information to return .
 */
FRESULT f_stat (const TCHAR* path, FILINFO* fno);  

/**
 * \brief Function to write data to the file.
 *
 * \param fp Pointer to the file object.
 * \param buff Pointer to the data to be written.
 * \param btw Number of bytes to write.
 * \param bw Pointer to number of bytes written.
 */
FRESULT f_write (FIL* fp, const void* buff, UINT btw, UINT* bw);  
  
/**
 * \brief Function to get number of free clusters on the drive.
 *
 * \param path Pointer to the logical drive number (root dir).
 * \param nclst Pointer to the variable to return number of free clusters.
 * \param fatfs Pointer to pointer to corresponding file system object to return.
 */
FRESULT f_getfree (const TCHAR* path, DWORD* nclst, FATFS** fatfs);  

/**
 * \brief Function to truncate a file.
 *
 * \param fp Pointer to the file object to be truncated.
 */
FRESULT f_truncate (FIL* fp);             

/**
 * \brief Function to flush cached data of a writing file.
 *
 * \param fp Pointer to the file object.
 */
FRESULT f_sync (FIL* fp);               

/**
 * \brief Function to delete an existing file or directory.
 *
 * \param path Pointer to the file or directory path.
 */
FRESULT f_unlink (const TCHAR* path);        

/**
 * \brief Function to create a new directory.
 *
 * \param path Pointer to the directory path.
 */
FRESULT  f_mkdir (const TCHAR* path);  

/**
 * \brief Function to change attribute of a file or directory.
 *
 * \param path Pointer to the file path.
 * \param value Attribute bits.
 * \param mask Attribute mask to change.
 */
FRESULT f_chmod (const TCHAR* path, BYTE value, BYTE mask);      

/**
 * \brief Function to rename a file or directory.
 *
 * \param path_old Pointer to the old name.
 * \param path_new Pointer to the new name.
 */
FRESULT f_rename (const TCHAR* path_old, const TCHAR* path_new);    
  
/**
 * \brief Function to change current drive.
 *
 * \param drv Function to change current drive.
 */
FRESULT f_chdrive (BYTE drv);              

/**
 * \brief Function to change current directory.
 *
 * \param path Pointer to the directory path.
 */
FRESULT f_chdir (const TCHAR* path);            

/**
 * \brief Function to get current directory.
 *
 * \param path Pointer to the directory path.
 * \param sz_path Size of path.
 */
FRESULT f_getcwd (TCHAR* path, UINT sz_path);

/**
 * \brief Function to divide a physical drive into multipe partitions.
 *
 * \param pdrv Physical drive number.
 * \param szt Pointer to the size table for each partitions.
 * \param work Pointer to the working buffer.
 */
FRESULT  f_fdisk (BYTE pdrv, const DWORD szt[], void* work);    
  BYTE pdrv,      /* Physical drive number */
  const DWORD szt[],  /* Pointer to the size table for each partitions */
  void* work      /* Pointer to the working buffer */
  
/**
 * \brief Function to put a character to the file.
 *
 * \param c The character to be output.
 * \param fp Pointer to the file object.
 */
int f_putc (TCHAR c, FIL* fp);              

/**
 * \brief Function to print a formatted string into a file.
 *
 * \param fil Pointer to the file object.
 * \param str Pointer to the formatted string.
 * \param ... Optional arguments... 
 */
int f_printf (FIL* fil, const TCHAR* str, ...);     

#define f_eof(fp) (((fp)->fptr == (fp)->fsize) ? 1 : 0)
#define f_error(fp) (((fp)->flag & FA__ERROR) ? 1 : 0)
#define f_tell(fp) ((fp)->fptr)
#define f_size(fp) ((fp)->fsize)

#ifndef EOF
#define EOF (-1)
#endif




/*--------------------------------------------------------------*/
/* Additional user defined functions                            */

/* RTC function */
#if !_FS_READONLY
DWORD get_fattime (void);
#endif

/* Unicode support functions */
#if _USE_LFN            /* Unicode - OEM code conversion */
WCHAR ff_convert (WCHAR, UINT);    /* OEM-Unicode bidirectional conversion */
WCHAR ff_wtoupper (WCHAR);      /* Unicode upper-case conversion */
#if _USE_LFN == 3          /* Memory functions */
void* ff_memalloc (UINT);      /* Allocate memory block */
void ff_memfree (void*);      /* Free memory block */
#endif
#endif

/* Sync functions */
#if _FS_REENTRANT
int ff_cre_syncobj (BYTE, _SYNC_t*);/* Create a sync object */
int ff_req_grant (_SYNC_t);      /* Lock sync object */
void ff_rel_grant (_SYNC_t);    /* Unlock sync object */
int ff_del_syncobj (_SYNC_t);    /* Delete a sync object */
#endif




/*--------------------------------------------------------------*/
/* Flags and offset address                                     */


/* File access control and file status flags (FIL.flag) */

#define  FA_READ        0x01
#define  FA_OPEN_EXISTING  0x00
#define FA__ERROR      0x80

#if !_FS_READONLY
#define  FA_WRITE      0x02
#define  FA_CREATE_NEW    0x04
#define  FA_CREATE_ALWAYS  0x08
#define  FA_OPEN_ALWAYS    0x10
#define FA__WRITTEN      0x20
#define FA__DIRTY      0x40
#endif


/* FAT sub type (FATFS.fs_type) */

#define FS_FAT12  1
#define FS_FAT16  2
#define FS_FAT32  3


/* File attribute bits for directory entry */

#define  AM_RDO  0x01  /* Read only */
#define  AM_HID  0x02  /* Hidden */
#define  AM_SYS  0x04  /* System */
#define  AM_VOL  0x08  /* Volume label */
#define AM_LFN  0x0F  /* LFN entry */
#define AM_DIR  0x10  /* Directory */
#define AM_ARC  0x20  /* Archive */
#define AM_MASK  0x3F  /* Mask of defined bits */


/* Fast seek feature */
#define CREATE_LINKMAP  0xFFFFFFFF



/*--------------------------------*/
/* Multi-byte word access macros  */

#if _WORD_ACCESS == 1  /* Enable word access to the FAT structure */
#define  LD_WORD(ptr)    (WORD)(*(WORD*)(BYTE*)(ptr))
#define  LD_DWORD(ptr)    (DWORD)(*(DWORD*)(BYTE*)(ptr))
#define  ST_WORD(ptr,val)  *(WORD*)(BYTE*)(ptr)=(WORD)(val)
#define  ST_DWORD(ptr,val)  *(DWORD*)(BYTE*)(ptr)=(DWORD)(val)
#else          /* Use byte-by-byte access to the FAT structure */
#define  LD_WORD(ptr)    (WORD)(((WORD)*((BYTE*)(ptr)+1)<<8)|(WORD)*(BYTE*)(ptr))
#define  LD_DWORD(ptr)    (DWORD)(((DWORD)*((BYTE*)(ptr)+3)<<24)|((DWORD)*((BYTE*)(ptr)+2)<<16)|((WORD)*((BYTE*)(ptr)+1)<<8)|*(BYTE*)(ptr))
#define  ST_WORD(ptr,val)  *(BYTE*)(ptr)=(BYTE)(val); *((BYTE*)(ptr)+1)=(BYTE)((WORD)(val)>>8)
#define  ST_DWORD(ptr,val)  *(BYTE*)(ptr)=(BYTE)(val); *((BYTE*)(ptr)+1)=(BYTE)((WORD)(val)>>8); *((BYTE*)(ptr)+2)=(BYTE)((DWORD)(val)>>16); *((BYTE*)(ptr)+3)=(BYTE)((DWORD)(val)>>24)
#endif

#if defined (__cplusplus) || defined (__XC__)
}
#endif

#endif /* _FATFS */
