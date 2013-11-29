// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#ifndef _spi_conf_h_
#define _spi_conf_h_
#include <xs1.h>

/* SPI modification needed by SD card */
#undef SPI_MASTER_SD_CARD_COMPAT
#define SPI_MASTER_SD_CARD_COMPAT 1

#endif
