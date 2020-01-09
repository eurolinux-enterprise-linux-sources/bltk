/*
 *  Copyright (c) 2006 Intel Corp.
 *  Copyright (c) 2006 Konstantin Karasyov <konstantin.a.karasyov@intel.com>
 *  Copyright (c) 2006 Vladimir Lebedev <vladimir.p.lebedev@intel.com>
 *  All rights reserved.
 *
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *    Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 *    Neither the name of Intel Corporation nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 *  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 *  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 *  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 *  DAMAGE.
 *
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */

#ifndef __XSE_H__
#define __XSE_H__

#include <time.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include <bltk.h>

#define	MSEC_IN_SEC	1000
#define	MCSEC_IN_MSEC	1000
#define	MCSEC_IN_SEC	1000000
#define	ENDSCEN		0
#define	DELAY		1
#define	FOCUSIN		2
#define	FOCUSOUT	3
#define	PRESSKEY	4
#define RELEASEKEY	5
#define	TYPETEXT	6
#define	SETWINDOW	7
#define	ENDWINDOW	8
#define	RUNCMD		9
#define	WAITSTARTCMD	10
#define	WAITFINISHCMD	11
#define	SENDWORKMSG	12
#define	SENDIDLEMSG	13
#define	TRACEON		14
#define	TRACEOFF	15
#define	SETWINDOWID	16
#define	SYNCWINDOW	17

/* Alt */
#define	A	Mod1Mask
/*Ctrl */
#define	C	ControlMask
/* Shift */
#define	S	ShiftMask
/* Env */
#define	E	0xEEE
/* File */
#define	F	0xFFF
/* X - pgrep without -x option :-), 0 - with -x option */
#define	X	0xCCC

#define	DELAY_1_MIN	(1 * 60 * 1000)
#define	DELAY_2_MIN	(2 * 60 * 1000)
#define	WINDOWID	"WINDOWID"
#define	DELAY_FILE	"./user_delay.tmp"
#define	VI_CMD		"vi"
#define	CSCOPE_CMD	"cscope"
#define	F4		"F4"
#define	F11		"F11"
#define	Next		"Next"
#define	Prior		"Prior"
#define	Return		"Return"
#define	Up		"Up"
#define	Down		"Down"
#define	Left		"Left"
#define	Escape		"Escape"

typedef struct xse_scen {
	int action;
	int state;
	int count;
	int delay;
	char *string;
} xse_scen_t;

extern char *xchg_buf;
extern char *scen_file;
extern char *progname;
extern int default_release;
extern char *progname;
extern char *scen_file;
extern int default_release_flg;
extern int check_delay_time_flg;
extern void init_xse(void);
extern void fini_xse(void);
extern void run_scen(xse_scen_t * scen);
extern void print_scen(xse_scen_t * scen);
extern void delay(int msecs);
extern void delay2(int msecs);
extern void write_delay(char *fname);

extern xse_scen_t *read_scen(FILE * file, xse_scen_t * scen);
extern ll_t gettime(void);
extern int wait_start_app(char *appname, int delay_time, int cnt);
extern int wait_finish_app(char *appname, int delay_time, int cnt);
extern int kill(pid_t pid, int sig);
extern char *strdup(const char *s);
extern int wait_start_cmd(char *cmdname,
			  int delay_time, int count, int state, int abort);
extern int wait_finish_cmd(char *cmdname,
			   int delay_time, int count, int state, int abort);

#endif				/* __XSE_H__ */
