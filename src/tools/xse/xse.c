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

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <strings.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <ctype.h>
#include <limits.h>
#include <time.h>
#include <sys/wait.h>
#include <signal.h>

#include <xse.h>

char *progname = "xse";
char *xchg_buf = NULL;
char *scen_file = NULL;
int default_release_flg = 0;
int check_delay_time_flg = 0;
int correct_delay_time_flg = 0;

long double user_delay = 0;

static Display *display = NULL;
static Window window = (Window) NULL;
static Window root = (Window) NULL;
static char *window_name = "NULL";

static Status status;

static void xse_exit(int status)
{
	char *fail_fname;

	if (status != 0) {
		fail_fname = getenv("BLTK_FAIL_FNAME");
		if (fail_fname != NULL) {
			(void)close(open(fail_fname, O_RDWR | O_CREAT, 0666));
		}
	}
	fini_xse();
	exit(status);
}

static char *get_action_str(int action)
{
	char *ret = "null";

	switch (action) {
	case DELAY:
		ret = "DELAY";
		break;
	case RUNCMD:
		ret = "RUNCMD";
		break;
	case SETWINDOWID:
		ret = "SETWINDOWID";
		break;
	case SETWINDOW:
		ret = "SETWINDOW";
		break;
	case ENDWINDOW:
		ret = "ENDWINDOW";
		break;
	case SYNCWINDOW:
		ret = "SYNCWINDOW";
		break;
	case FOCUSIN:
		ret = "FOCUSIN";
		break;
	case FOCUSOUT:
		ret = "FOCUSOUT";
		break;
	case PRESSKEY:
		ret = "PRESSKEY";
		break;
	case RELEASEKEY:
		ret = "RELEASEKEY";
		break;
	case TYPETEXT:
		ret = "TYPETEXT";
		break;
	case WAITSTARTCMD:
		ret = "WAITSTARTCMD";
		break;
	case WAITFINISHCMD:
		ret = "WAITFINISHCMD";
		break;
	case SENDWORKMSG:
		ret = "SENDWORKMSG";
		break;
	case SENDIDLEMSG:
		ret = "SENDIDLEMSG";
		break;
	case TRACEON:
		ret = "TRACEON";
		break;
	case TRACEOFF:
		ret = "TRACEOFF";
		break;
	case ENDSCEN:
		ret = "ENDSCEN";
		break;
	default:
		ret = "???????";
		break;
	}
	return (ret);
}

static char state_str[STR_LEN];

static char *get_state_str(int state)
{
	char *ret = state_str;
	int index = 0;

	ret[0] = '-';
	ret[1] = 0;

	if (state == F) {
		ret[index] = 'F';
		index++;
	} else if (state == E) {
		ret[index] = 'E';
		index++;
	} else if (state == X) {
		ret[index] = 'X';
		index++;
	} else {
		if (state & C) {
			ret[index] = 'C';
			index++;
		}
		if (state & S) {
			ret[index] = 'S';
			index++;
		}
		if (state & A) {
			ret[index] = 'A';
			index++;
		}
	}
	if (index == 0) {
		(void)sprintf(ret, "%x", state);
	}
	return (ret);
}

void print_scen1(xse_scen_t * scen1)
{
	int i = 0;
	char *string;
	char *action_str;
	char *state_str;

	(void)fprintf(stderr,
		      "N: Action	State	Count	Delay	String\n");
	action_str = get_action_str(scen1->action);
	state_str = get_state_str(scen1->state);
	string = scen1->string;
	if (string == NULL) {
		string = "null";
	}
	(void)fprintf(stderr,
		      "%d: %s	%s	%d	%d	%s\n",
		      i, action_str, state_str,
		      scen1->count, scen1->delay, string);
}

void print_scen(xse_scen_t * scen)
{
	int i = 0;
	xse_scen_t *scen1;
	char *string;
	char *action_str;
	char *state_str;

	(void)fprintf(stderr,
		      "N: Action	State	Count	Delay	String\n");
	while (1) {
		scen1 = &scen[i];
		action_str = get_action_str(scen1->action);
		state_str = get_state_str(scen1->state);
		string = scen1->string;
		if (string == NULL) {
			string = "null";
		}
		(void)fprintf(stderr,
			      "%d: %s	%s	%d	%d	%s\n",
			      i, action_str, state_str,
			      scen1->count, scen1->delay, string);

		if (scen1->action == ENDSCEN) {
			break;
		}

		i++;
	}
}

static int time_and_space_flg = 0;
static ld_t time_and_space = 0;

static void init_time_and_space()
{
	char *var;
	int ret;

	var = getenv("BLTK_TIME_AND_SPACE");
	if (var != NULL) {
		ret = sscanf(var, "%Lf", &time_and_space);
		if (ret != 1) {
			(void)fprintf(stderr,
				      "%s: Invalid BLTK_TIME_AND_SPACE=%s\n",
				      progname, var);
			xse_exit(1);
		}
		time_and_space_flg = 1;
	}
}

void delay(int msecs)
{
	ll_t t;
	ld_t msecs1;

	t = gettime();

	msecs = msecs * 1000;
	if (time_and_space_flg) {
		msecs1 = msecs * time_and_space;
		msecs = msecs1;
	}

	usleep(msecs);

	t = gettime() - t;
	user_delay += t;
}

void real_delay(int msecs)
{
	ll_t t;

	t = gettime();

	msecs = msecs * 1000;

	usleep(msecs);

	t = gettime() - t;
	user_delay += t;
}

void delay2(int msecs)
{
	usleep(msecs * 1000);
}

ll_t gettime(void)
{
	struct timeval tv;
	int ret;
	ll_t tv_sec, tv_usec;

	tv.tv_sec = 0;
	tv.tv_usec = 0;

	ret = gettimeofday(&tv, NULL);
	if (ret != 0) {
		(void)fprintf(stderr,
			      "gettimeofday() failed, "
			      "errno %d(%s)\n", errno, strerror(errno));
		xse_exit(1);
	}
	tv_sec = tv.tv_sec;
	tv_usec = tv.tv_usec;

	return (tv_sec * MSEC_IN_SEC + tv_usec / MCSEC_IN_MSEC);
}

int
wait_start_cmd(char *cmdname, int delay_time, int count, int state, int abort)
{
	ll_t start_time = gettime();
	ll_t wait_time;
	char cmd[STR_LEN];
	int ret = 0;

	if (delay_time <= 0) {
		delay_time = 100;
	}

	if (count <= 1) {
		count = 1200;
	}

	if (state == X) {
		(void)sprintf(cmd, "pgrep -x %s >/dev/null 2>&1", cmdname);
	} else {
		(void)sprintf(cmd, "pgrep %s >/dev/null 2>&1", cmdname);
	}

	while ((wait_time = gettime() - start_time) <= count * delay_time) {
		ret = WEXITSTATUS(system(cmd));
		if (ret == 0) {	/* found */
			return (0);
		} else if (ret == 1) {	/* not found */
			delay2(delay_time);
		} else {	/* failure */
			(void)fprintf(stderr, "%s: %s failed, ret = %d\n",
				      progname, cmd, ret);
			xse_exit(1);
		}
	}
	if (abort) {
		(void)fprintf(stderr, "%s: %s is not running, wait time %lld\n",
			      progname, cmdname, wait_time);
		xse_exit(1);
	}
	return (1);
}

int
wait_finish_cmd(char *cmdname, int delay_time, int count, int state, int abort)
{
	ll_t start_time = gettime();
	ll_t wait_time;
	char cmd[STR_LEN];
	int ret = 0;

	if (state == X) {
		(void)sprintf(cmd, "pgrep -x %s >/dev/null 2>&1", cmdname);
	} else {
		(void)sprintf(cmd, "pgrep %s >/dev/null 2>&1", cmdname);
	}

	if (delay_time <= 0) {
		delay_time = 100;
	}

	if (count <= 1) {
		count = 1200;
	}

	while ((wait_time = gettime() - start_time) <= count * delay_time) {
		ret = WEXITSTATUS(system(cmd));
		if (ret == 1) {	/* not found */
			return (0);
		} else if (ret == 0) {	/* found */
			delay2(delay_time);
		} else {	/* failure */
			(void)fprintf(stderr, "%s: %s failed, ret = %d\n",
				      progname, cmd, ret);
			xse_exit(1);
		}
	}
	if (abort) {
		(void)fprintf(stderr, "%s: %s is running\n", progname, cmdname);
		xse_exit(1);
	}
	return (1);
}

void write_delay(char *fname)
{
	int fd = -1, wret;
	char string[STR_LEN];

	if (fname == 0) {
		fname = DELAY_FILE;
	}

	fd = open(fname, O_RDWR | O_TRUNC | O_CREAT, 0666);
	if (fd < 0) {
		(void)fprintf(stderr, "%s: open(%s) failed\n", progname, fname);
		xse_exit(1);
	}
	(void)sprintf(string, "%.2Lf\n", user_delay / 1000);
	wret = write(fd, string, strlen(string));
	if (wret != strlen(string)) {
		(void)fprintf(stderr, "%s: writing to %s failed\n",
			      progname, fname);
		xse_exit(1);
	}
	(void)close(fd);
}

static int setwinid_action(char *name, char *id, int foo)
{
	root = RootWindow(display, DefaultScreen(display));
	if (root == (Window) NULL) {
		(void)fprintf(stderr, "%s: Cannot get window root, "
			      "Name %s, Id %s\n", progname, name, id);
		xse_exit(1);
	}
	window = (Window) strtol(id, 0, 0);
	if (window == (Window) NULL) {
		(void)fprintf(stderr, "%s: Cannot get window id: "
			      "Name %s, Id %s\n", progname, name, id);
		xse_exit(1);
	}
	window_name = name;

	return (0);
}

static int readf_action(char *file, int size, int wait_time)
{
	int fd = -1;
	ssize_t r_ret = 0;
	time_t start_time = 0;

	if (size <= 1) {
		size = STR_LEN;
	}
	start_time = gettime();
	fd = open(file, O_RDONLY);
	if ((wait_time > 0) && (fd == -1)) {
		while ((gettime() - start_time) < wait_time) {
			(void)sleep(1);
			fd = open(file, O_RDONLY);
			if (fd != -1) {
				break;
			}
		}
	}
	if (fd < 0) {
		(void)fprintf(stderr,
			      "open(%s) failed with %d (%s)\n",
			      file, errno, strerror(errno));
		xse_exit(1);
	}
	if (xchg_buf != NULL) {
		(void)free(xchg_buf);
		xchg_buf = NULL;
	}
	xchg_buf = (char *)malloc((size_t) size);
	if (xchg_buf == NULL) {
		(void)fprintf(stderr, "malloc() failed\n");
		xse_exit(1);
	}
	(void)memset(xchg_buf, 0, size);
	r_ret = read(fd, xchg_buf, size);
	if (r_ret <= 0 || r_ret >= size) {
		(void)fprintf(stderr,
			      "Internal error: read() failed with %d (%s), "
			      "invalid file size = %d\n",
			      errno, strerror(errno), size);
		xse_exit(1);
	}
	if (fd != -1) {
		(void)close(fd);
	}
	return (0);
}

static int x_get_winid_action(char *title, int wait_time, int sleep_time)
{
	int ret = 0;
	char cmd[STR_LEN];

	(void)sprintf(cmd, "bltk_winid -S -t %d -s %d \"%s\" >./winid.tmp",
		      wait_time, sleep_time, title);
	ret = system(cmd);
	if (ret != 0) {
		(void)fprintf(stderr, "%s failed\n", cmd);
		xse_exit(1);
	}
	return (0);
}

static int get_winid_action(char *title)
{
	int ret = 0;
	char cmd[STR_LEN];

	(void)sprintf(cmd, "bltk_winid -S \"%s\" >./winid.tmp", title);
	ret = system(cmd);
	if (ret != 0) {
		(void)fprintf(stderr, "%s failed\n", cmd);
		xse_exit(1);
	}
	return (0);
}

static int x_end_winid_action(char *title, int wait_time, int sleep_time)
{
	int ret = 0;
	char cmd[STR_LEN];

	(void)sprintf(cmd, "bltk_winid -F -t %d -s %d \"%s\"",
		      wait_time, sleep_time, title);
	ret = system(cmd);
	if (ret != 0) {
		(void)fprintf(stderr, "%s failed\n", cmd);
		xse_exit(1);
	}
	window = (Window) NULL;
	return (0);
}

static int end_winid_action(char *title)
{
	int ret = 0;
	char cmd[STR_LEN];

	(void)sprintf(cmd, "bltk_winid -F \"%s\"", title);
	ret = system(cmd);
	if (ret != 0) {
		(void)fprintf(stderr, "%s failed\n", cmd);
		xse_exit(1);
	}
	window = (Window) NULL;
	return (0);
}

static pid_t pid_array[1024];
static int pid_cnt = 0;

static int runcmd_action(char *name, int wait_time, int state)
{
	int ret = 0;
	char cmd[STR_LEN];
	pid_t pid = -1;

	(void)sprintf(cmd, "%s", name);

	if (state != X) {
		ret = system(cmd);
		if (ret != 0) {
			(void)fprintf(stderr, "%s failed with %d.\n", cmd, ret);
			xse_exit(1);
		}
	} else {
		if ((pid = fork()) == 0) {
			ret = system(cmd);
			if (ret != 0) {
				(void)fprintf(stderr, "%s failed with %d.\n",
					      cmd, ret);
				exit(1);
			}
			exit(0);
		} else if (pid < 0) {
			(void)fprintf(stderr,
				      "fork() failed: errno %d (%s)\n",
				      errno, strerror(errno));
			xse_exit(1);
		} else {
			pid_array[pid_cnt] = pid;
			pid_cnt++;
		}
	}
	return (0);
}

static pid_t work_log_pid = 0;

static void send_work_log_msg(int sig, char *comment)
{
	char *var;
	int sz, fd = -1;

	if (work_log_pid == -1) {
		return;
	}
	if (work_log_pid == 0) {
		var = getenv("BLTK_WORK_LOG_PROC");
		if (var == NULL) {
			work_log_pid = -1;
			return;
		}
		work_log_pid = atoi(var);
		if (work_log_pid <= 0) {
			work_log_pid = -1;
			return;
		}
	}
	sz = strlen(comment);
	fd = open(BLTK_COMMENT, O_RDWR | O_CREAT | O_TRUNC, 0666);
	(void)write(fd, comment, sz + 1);
	(void)close(fd);
	(void)kill(work_log_pid, sig);
}

static void send_work_msg(char *comment)
{
	send_work_log_msg(SIGUSR1, comment);
}

static void send_idle_msg(char *comment)
{
	send_work_log_msg(SIGUSR2, comment);
}

static int focus_action(int act)
{
	XEvent xevent;
	int ret;

	(void)memset(&xevent, 0, sizeof(XEvent));

	xevent.xfocus.display = display;
	xevent.xfocus.window = window;
	xevent.xfocus.type = act;
	xevent.xfocus.send_event = 1;

	status = XSendEvent(display, window, True, 0, &xevent);
	if (status == (Status) NULL) {
		(void)fprintf(stderr,
			      "%s: Set/unset focus: XSendEvent() failed\n",
			      progname);
		xse_exit(1);
	} else if (status == BadValue) {
		(void)fprintf(stderr,
			      "%s: Set/unset focus: XSendEvent() failed "
			      "with BadValue\n", progname);
		xse_exit(1);
	} else if (status == BadWindow) {
		(void)fprintf(stderr,
			      "%s: Set/unset focus: XSendEvent() failed "
			      "with BadValue\n", progname);
		xse_exit(1);
	}

	ret = XFlush(display);
	if (ret <= 0) {
		(void)fprintf(stderr, "%s: Set/unset focus: XFlush() failed, "
			      "err %d\n", progname, ret);
		xse_exit(1);
	}
/*
	XEventsQueued(display, QueuedAfterFlush);
	XEventsQueued(display, QueuedAlready);
*/
	(void)XSync(display, True);

	return (0);
}

static int sync_action()
{
	XSync(display, False);
	(void)XCloseDisplay(display);
	display = XOpenDisplay(NULL);
	if (display == NULL) {
		(void)fprintf(stderr, "%s: Cannot open Display\n", progname);
		xse_exit(1);
	}
	return (0);
}

static int key_action(int type, int state, char *key)
{
	XEvent xevent;
	KeySym keysym;
	char *stype;
	int ret;

	(void)memset(&xevent, 0, sizeof(XEvent));

	xevent.xkey.time = 0;
	xevent.xkey.send_event = 1;
	xevent.xkey.root = root;
	xevent.xkey.window = window;
	xevent.xkey.display = display;
	xevent.xkey.type = type;
	xevent.xkey.same_screen = 1;
	xevent.xkey.state = state;
	keysym = XStringToKeysym(key);
	xevent.xkey.keycode = XKeysymToKeycode(display, keysym);

	if (type == KeyPress) {
		stype = "KeyPress";
	} else {
		stype = "KeyRelease";
	}

	status = XSendEvent(display, window, True, 0, &xevent);
	if (status == (Status) NULL) {
		(void)fprintf(stderr, "%s: Send Event: XSendEvent() failed, "
			      "type %s, key %s\n", progname, stype, key);
		xse_exit(1);
	} else if (status == BadValue) {
		(void)fprintf(stderr, "%s: Send Event: XSendEvent() failed, "
			      "type %s, key %s,err BadValue\n",
			      progname, stype, key);
		xse_exit(1);
	} else if (status == BadWindow) {
		(void)fprintf(stderr, "%s: Send Event: XSendEvent() failed, "
			      "type %s, key %s, err BadWindow\n",
			      progname, stype, key);
		xse_exit(1);
	}

	ret = XFlush(display);
	if (ret <= 0) {
		(void)fprintf(stderr, "%s: Send Event: XFlush() failed, "
			      "type %s, key %s, err %d\n",
			      progname, stype, key, ret);
		xse_exit(1);
	}

	return (0);
}

#define	XUPERKEY	"~!@#$%^&*()_+{}|:\"<>?"

static void type_action(char *string, int delay_time, int state)
{
	int i, sz, m, j;
	int fd = -1, buf_malloc = 0;
	char *buf = NULL;
	char *k;
	ssize_t r_ret;

	if (state == F) {
		fd = open(string, O_RDONLY);
		if (fd < 0) {
			(void)fprintf(stderr, "%s: open(%s) failed\n",
				      progname, string);
			xse_exit(1);
		}
		buf = malloc(STR_LEN);
		if (buf == NULL) {
			(void)fprintf(stderr, "%s: malloc() failed\n",
				      progname);
			xse_exit(1);
		}
		buf_malloc = 1;
		(void)memset(buf, 0, STR_LEN);
		r_ret = read(fd, buf, STR_LEN);
		if (r_ret < 0) {
			(void)fprintf(stderr, "%s: read(%s) failed\n",
				      progname, string);
			xse_exit(1);
		}
	} else if (state == E) {
		buf = getenv(string);
		if (buf == 0) {
			(void)fprintf(stderr, "%s: getenv(%s) failed\n",
				      progname, string);
			xse_exit(1);
		}
	} else {
		buf = string;
	}

	sz = strlen(buf);

	i = 0;
	while (i < sz) {
		m = 0;
		k = XKeysymToString(buf[i]);
		if (buf[i] == '\n') {
			k = "Return";
		}
		if (k == 0) {
			k = "question";
			m = ShiftMask;
		} else {
			if (isupper(buf[i])) {
				m = ShiftMask;
			}
			for (j = 0;; j++) {
				if (XUPERKEY[j] == 0) {
					break;
				}
				if (XUPERKEY[j] == buf[i]) {
					m = ShiftMask;
					break;
				}
			}
		}
		key_action(KeyPress, m, k);
		if (default_release_flg) {
			delay(delay_time);
			key_action(KeyRelease, m, k);
			delay(delay_time);
		} else {
			delay(delay_time);
		}

		i++;
		if (state == F && i == sz) {
			(void)memset(buf, 0, STR_LEN);
			sz = read(fd, buf, STR_LEN);
			if (sz < 0) {
				(void)fprintf(stderr, "%s: read(%s) failed\n",
					      progname, string);
				xse_exit(1);
			}
			i = 0;
		}
	}

	if (buf_malloc) {
		buf_malloc = 0;
		(void)free(buf);
		buf = NULL;
	}
	if (fd != -1) {
		(void)close(fd);
		fd = -1;
	}

	return;
}

static void run_scen1(xse_scen_t * scen1);

static ll_t scen_trace_flg = 0;
static ll_t read_scen_cnt = 0;
static ll_t read_scen_prev_time = 0;

static void settrace(int val)
{
	scen_trace_flg = val;
	read_scen_cnt = 0;
	read_scen_prev_time = gettime();
}

xse_scen_t *read_scen(FILE * file, xse_scen_t * scen)
{
	int cnt, i, c;
	char readstr[STR_LEN];
	char action[STR_LEN];
	char state[STR_LEN];
	int count;
	int delay;
	char string[STR_LEN];
	ll_t read_scen_cur_time;
	ld_t ftime;

	while (1) {
		readstr[0] = 0;
		action[0] = 0;
		state[0] = 0;
		count = 0;
		delay = 0;
		string[0] = 0;
		scen->action = 0;
		scen->state = 0;
		scen->count = 0;
		scen->delay = 0;
		scen->string[0] = 0;
		if (fgets(readstr, STR_LEN, file) == NULL) {
			scen->action = ENDSCEN;
			return (scen);
		}

		cnt = strlen(readstr);
		readstr[cnt - 1] = 0;
		cnt = sscanf(readstr, "%s", action);
		c = action[0];
		if (c == '\n' || c == 0 || c == '#' || c == '/') {
			continue;
		}
		cnt = sscanf(readstr, "%s %s %i %i %[^#]",
			     action, state, &count, &delay, string);
		if (cnt != 5) {
			(void)fprintf(stderr, "%s: Unexpected LINE %d: %s\n",
				      progname, cnt, readstr);
			xse_exit(1);;
		}

		if (strcmp(action, "ENDSCEN") == 0) {
			scen->action = ENDSCEN;
		} else if (strcmp(action, "DELAY") == 0) {
			scen->action = DELAY;
		} else if (strcmp(action, "FOCUSIN") == 0) {
			scen->action = FOCUSIN;
		} else if (strcmp(action, "FOCUSOUT") == 0) {
			scen->action = FOCUSOUT;
		} else if (strcmp(action, "PRESSKEY") == 0) {
			scen->action = PRESSKEY;
		} else if (strcmp(action, "RELEASEKEY") == 0) {
			scen->action = RELEASEKEY;
		} else if (strcmp(action, "TYPETEXT") == 0) {
			scen->action = TYPETEXT;
		} else if (strcmp(action, "SETWINDOWID") == 0) {
			scen->action = SETWINDOWID;
		} else if (strcmp(action, "SETWINDOW") == 0) {
			scen->action = SETWINDOW;
		} else if (strcmp(action, "ENDWINDOW") == 0) {
			scen->action = ENDWINDOW;
		} else if (strcmp(action, "SYNCWINDOW") == 0) {
			scen->action = SYNCWINDOW;
		} else if (strcmp(action, "RUNCMD") == 0) {
			scen->action = RUNCMD;
		} else if (strcmp(action, "WAITSTARTCMD") == 0) {
			scen->action = WAITSTARTCMD;
		} else if (strcmp(action, "WAITFINISHCMD") == 0) {
			scen->action = WAITFINISHCMD;
		} else if (strcmp(action, "SENDWORKMSG") == 0) {
			scen->action = SENDWORKMSG;
		} else if (strcmp(action, "SENDIDLEMSG") == 0) {
			scen->action = SENDIDLEMSG;
		} else if (strcmp(action, "TRACEON") == 0) {
			scen->action = TRACEON;
		} else if (strcmp(action, "TRACEOFF") == 0) {
			scen->action = TRACEOFF;
		} else {
			(void)fprintf(stderr,
				      "%s: Unexpected LINE: %s, action = %s\n",
				      progname, readstr, action);
			xse_exit(1);
		}
		break;
	}

	scen->state = 0;
	for (i = 0; i < strlen(state); i++) {
		c = state[i];
		if (c == 'F') {
			scen->state = F;
		} else if (c == 'E') {
			scen->state = E;
		} else if (c == 'X') {
			scen->state = X;
		} else {
			if (c == 'A') {
				scen->state |= A;
			} else if (c == 'S') {
				scen->state |= S;
			} else if (c == 'C') {
				scen->state |= C;
			} else if (c != '0' && c != '-' && c != '1') {
				(void)fprintf(stderr,
					      "%s: Unexpected LINE: %s, state = %s\n",
					      progname, readstr, state);
				xse_exit(1);
			}
		}
	}

	scen->count = count;
	scen->delay = delay;
	(void)sprintf(scen->string, "%s", string);
	if (scen_trace_flg) {
		read_scen_cnt++;
		read_scen_cur_time = gettime();
		ftime =
		    (ll_t) (read_scen_cur_time - read_scen_prev_time) / 1000.0;
		(void)fprintf(stderr, "%3lld : %6.3Lf :	%s\n", read_scen_cnt,
			      ftime, readstr);
		read_scen_prev_time = read_scen_cur_time;
	}
	return (scen);
}

void run_scen(xse_scen_t * scen)
{
	int i = 0;
	int from_file = 0;
	xse_scen_t scen_buf;
	xse_scen_t *scen1;
	FILE *file = NULL;

	if (scen_file != NULL) {
		file = fopen(scen_file, "r");
		if (file == NULL) {
			(void)fprintf(stderr, "%s: fopen(%s, r) failed\n",
				      progname, scen_file);
			xse_exit(1);
		} else {
			from_file = 1;
		}
		scen_buf.string = NULL;
		scen_buf.string = malloc(STR_LEN);
		if (scen_buf.string == NULL) {
			(void)fprintf(stderr, "%s: malloc() failed\n",
				      progname);
			xse_exit(1);
		}
	}
	while (1) {
		if (from_file) {
			scen1 = read_scen(file, &scen_buf);
		} else {
			scen1 = &scen[i];
		}
		if (scen1->action == ENDSCEN) {
			if (file != NULL) {
				(void)fclose(file);
				file = NULL;
			}
			return;
		}
		run_scen1(scen1);
		i++;
	}
}

static void run_scen1(xse_scen_t * scen1)
{
	int action = scen1->action;
	int state = scen1->state;
	char *string = scen1->string;
	int delay_time = scen1->delay;
	int count = scen1->count;
	int check_delay_time;
	int i;
	char *buf = NULL;
	int break_flg = 0;

	if (count == 0) {
		count = 1;
	}
	if (count < 0) {
		count = INT_MAX;
	}

	for (i = 1; i <= count; i++) {
		check_delay_time = 0;
		switch (action) {
		case DELAY:
			break;
		case RUNCMD:
			runcmd_action(string, delay_time, state);
			delay_time = 0;
			break;
		case SETWINDOWID:
			break_flg = 1;
			if (state == F) {
				readf_action(string, count, delay_time);
				setwinid_action(string, xchg_buf, delay_time);
			} else if (state == E || state == 0) {
				buf = getenv(string);
				if (buf == 0) {
					(void)fprintf(stderr, "%s: "
						      "getenv(%s) failed\n",
						      progname, string);
					xse_exit(1);
				}
				setwinid_action(string, buf, delay_time);
			} else {
				(void)fprintf(stderr,
					      "SCEN ERR: SETWINDOWID: "
					      "unknown state, "
					      "no %d, state %d\n", i, state);
				xse_exit(1);
			}
			delay_time = 0;
			break;
		case SETWINDOW:
			break_flg = 1;
			if (state == X) {
				x_get_winid_action(string,
						   count * delay_time / 1000,
						   delay_time / 1000);
			} else {
				get_winid_action(string);
			}
			readf_action("./winid.tmp", count, delay_time);
			setwinid_action(string, xchg_buf, delay_time);
			delay_time = 0;
			break;
		case ENDWINDOW:
			if (state == X) {
				x_end_winid_action(string,
						   count * delay_time / 1000,
						   delay_time / 1000);
			} else {
				end_winid_action(string);
			}
			delay_time = 0;
			break;
		case SYNCWINDOW:
			check_delay_time = 1;
			sync_action();
			break;
		case FOCUSIN:
			check_delay_time = 1;
			focus_action(FocusIn);
			break;
		case FOCUSOUT:
			check_delay_time = 1;
			focus_action(FocusOut);
			break;
		case PRESSKEY:
			check_delay_time = 1;
			key_action(KeyPress, state, string);
			break;
		case RELEASEKEY:
			check_delay_time = 1;
			if (!default_release_flg)
				key_action(KeyRelease, state, string);
			break;
		case TYPETEXT:
			type_action(string, delay_time, state);
			delay_time = 0;
			break;
		case WAITSTARTCMD:
			break_flg = 1;
			wait_start_cmd(string, delay_time, count, state, 1);
			delay_time = 0;
			break;
		case WAITFINISHCMD:
			break_flg = 1;
			wait_finish_cmd(string, delay_time, count, state, 1);
			delay_time = 0;
			break;
		case SENDWORKMSG:
			send_work_msg(string);
			delay_time = 0;
			break;
		case SENDIDLEMSG:
			send_idle_msg(string);
			delay_time = 0;
			break;
		case TRACEON:
			settrace(1);
			delay_time = 0;
			break;
		case TRACEOFF:
			settrace(0);
			delay_time = 0;
			break;
		default:
			(void)fprintf(stderr,
				      "SCEN ERR: unknown action, "
				      "no %d, action %d\n", i, action);
			xse_exit(1);
		}
		if (correct_delay_time_flg &&
		    check_delay_time && delay_time <= 0) {
			delay_time = 100;
		}

		if (check_delay_time_flg && check_delay_time && delay_time <= 0) {
			(void)fprintf(stderr,
				      "SCEN ERR: delay_time is zero, "
				      "no %d, action %d\n", i, action);
			xse_exit(1);
		}

		if (default_release_flg && action == PRESSKEY) {
			delay(delay_time);
			key_action(KeyRelease, state, string);
			delay(delay_time);
		} else {
			delay(delay_time);
		}
		if (break_flg) {
			break;
		}
	}
}

void init_xse()
{
	display = XOpenDisplay(NULL);
	if (display == NULL) {
		(void)fprintf(stderr, "%s: Cannot open Display\n", progname);
		xse_exit(1);
	}
	init_time_and_space();
}

void fini_xse()
{
	int status, i;

	if (display) {
		XSync(display, True);
		(void)XCloseDisplay(display);
		display = NULL;
	}
	for (i = 0; i < pid_cnt; i++) {
		(void)waitpid(pid_array[i], &status, 0);
	}

}
