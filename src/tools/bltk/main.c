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

#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/wait.h>
#include <limits.h>
#include <getopt.h>
#include <sys/file.h>
#include <libgen.h>
#include <stdarg.h>
#include <ctype.h>

#include "bltk.h"

#define	OUTPUT_CONSOLE		10
#define	OUTPUT_FILE		20
#define	OUTPUT_NULL		30
#define	OUTPUT_CONSOLE_FILE	40

#define	OUTPUT_MIN		OUTPUT_CONSOLE
#define	OUTPUT_MAX		OUTPUT_CONSOLE_FILE

int idle_mode = 0;
int idle_test_mode = 0;
/* debug */

int debug_flg = 0;

void debug(char *format, ...)
{
	char *strtime = get_prog_time_str();
	char str[STR_LEN];
	char str2[STR_LEN];
	char fname[STR_LEN];
	int fd = EMPTY_VALUE;
	va_list ap;

	if (!debug_flg) {
		return;
	}

	va_start(ap, format);
	(void)vsprintf(str, format, ap);
	va_end(ap);
	(void)sprintf(str2, "%s: %s: %s\n", strtime, procname, str);

	(void)sprintf(fname, "%s/debug.log", results);
	fd = open(fname, O_RDWR | O_CREAT | O_APPEND, 0666);
	(void)write(fd, str2, strlen(str2));
	(void)close(fd);
}

char *debug_vars_file = NULL;

int get_str_debug_var(char *name, char *var)
{
	int ret;
	char var2[STR_LEN];

	if (debug_vars_file == NULL) {
		return (1);
	}
	ret =
	    get_value_file(debug_vars_file, name, DEF_EQUAL, var2, STR_LEN, 1);
	if (ret == 0) {
		(void)strcmp(var, var2);
		debug("%s = %s", name, var);
	}
	return (ret);
}

int get_int_debug_var(char *name, int *var)
{
	int ret;
	char var2[STR_LEN];

	if (debug_vars_file == NULL) {
		return (1);
	}
	ret =
	    get_value_file(debug_vars_file, name, DEF_EQUAL, var2, STR_LEN, 1);
	if (ret == 0) {
		*var = atoi(var2);
		debug("%s = %i", name, *var);
	}
	return (ret);
}

static char prog_time_str[SMALL_STR_LEN];

char *get_prog_time_str()
{
	xtime_t t_cur, t, t_hh, t_mm, t_ss, t_uu;

	t_cur = prog_time();

	t = (t_cur - time_start);
	if (report_time_msec_flg == 0) {
		t = ((t + MSEC_IN_SEC / 2) / MSEC_IN_SEC) * MSEC_IN_SEC;
	}
	t_hh = t / MSEC_IN_HOUR;
	t = t % MSEC_IN_HOUR;
	t_mm = t / MSEC_IN_MIN;
	t = t % MSEC_IN_MIN;
	t_ss = t / MSEC_IN_SEC;
	t_uu = t % MSEC_IN_SEC;

	if (report_time_msec_flg == 0) {
		(void)sprintf(prog_time_str, "%02lli:%02lli:%02lli",
			      t_hh, t_mm, t_ss);
	} else {
		(void)sprintf(prog_time_str, "%02lli:%02lli:%02lli.%03lli",
			      t_hh, t_mm, t_ss, t_uu);
	}
	return (prog_time_str);
}

void prog_err_printf(char *format, ...)
{
	int sz;
	char *strtime = get_prog_time_str();
	char str[STR_LEN];
	va_list ap;

	va_start(ap, format);
	(void)vsprintf(str, format, ap);
	va_end(ap);
	sz = strlen(str);
	if (sz && str[sz - 1] == '\n') {
		(void)fprintf(stderr, "%s: %s", strtime, str);
	} else {
		(void)fprintf(stderr, "%s: %s\n", strtime, str);
	}
}

int bat_sync = BAT_SYNC;
int bat_sync_time = BAT_SYNC_TIME;
int bat_sync_time_alarm = BAT_SYNC_TIME_ALARM;
int check_bat_flg = 1;
int user_field_cnt = 0;
char user_field_cmd[MAX_FIELDS][STR_LEN];

void init_debug_vars(void)
{
	(void)get_int_debug_var("DEBUG", &debug_flg);
	(void)get_int_debug_var("BAT_SYNC", &bat_sync);
	(void)get_int_debug_var("BAT_SYNC_TIME", &bat_sync_time);
	(void)get_int_debug_var("BAT_SYNC_TIME_ALARM", &bat_sync_time_alarm);
}

static int dpms_flg = 0;

extern char *strsignal(int sig);

int init_completed = 0;

int fd_proc_log = 2;
int fd_stat_log = 2;
int fd_work_log = 2;

char *bltk_dirname = NULL;
char bltk_root[STR_LEN];
char bltk_extern[STR_LEN];
char *workload = NULL;

int stat_system = 0;

int comment_cnt = 0;
char *comment[MAX_LINES];

char *bltk_sudo = "bltk_sudo_NOT_SET";

char stop_fname[STR_LEN];

int show_demo = 0;
int show_demo_num = EMPTY_VALUE;
int show_demo_cnt = EMPTY_VALUE;
xtime_t show_demo_time = EMPTY_VALUE;
int manufacturer = 0;
int stat_memory = 1;
int stat_memory_saved = 1;
int stat_memory_flg = 0;
int bat_percent[MAX_BAT];
int bat_value[MAX_BAT];
char prt_str[STR_LEN];
char head_log_head[STR_LEN];
char log_head[STR_LEN];
xtime_t time_start, time_prev;

int ac_err_workaround = 0;

int idle_workload_flg = 0;
int developer_workload_flg = 0;
int player_workload_flg = 0;
int reader_workload_flg = 0;
int game_workload_flg = 0;
int office_workload_flg = 0;
int user_workload_flg = 0;
int init_user_workload_flg = 0;
int discharging_workload_flg = 0;
int charging_workload_flg = 0;
int debug_workload_flg = 0;

int start_prog_flg = 0;
char *start_prog = NULL;
int start_prog_su_flg = 0;

xtime_t arg_time = EMPTY_VALUE;
xtime_t idle_test_time = EMPTY_VALUE;

int arg_jobs = EMPTY_VALUE;

char *arg_file = NULL;
char *arg_prog = NULL;
char *arg_prog_args = NULL;
char *arg_title = NULL;

char *user_workload_prog = NULL;
char *init_user_workload_prog = NULL;

char *workload_name = "null";

int debug_mode = 0;
int pid_stat_log = EMPTY_VALUE;
int pid_work_log = EMPTY_VALUE;
int pid_spy_log = EMPTY_VALUE;
int pid_dpms = EMPTY_VALUE;
int parent_flg = 1;
int stat_log_proc_flg = 0;
int work_log_proc_flg = 0;
int dpms_proc_flg = 0;

int results_flg = 0;
char *results = DEF_RESULTS;

int abort_flg = 0;
int ac_ignore = 0;

int no_time_stat_ignore = 1;
int cpu_stat_ignore = 0;
int cpu_add_stat_ignore = 0;
int bat_stat_ignore = 0;
int disp_stat_ignore = 0;
int ac_stat_ignore = 0;
int hd_stat_ignore = 0;
int mem_stat_ignore = 0;

int stat_log_ignore = 0;
int work_log_ignore = 0;
int proc_log_ignore = 0;
int spy_log_enabled = 0;

int yes = 0;

typedef void (*sighandler_t) (int);

int proc_load = 13;
int report_time_flg = EMPTY_VALUE;
xtime_t report_time = DEF_REPORT_TIME * MSEC_IN_SEC;
int report_time_msec_flg = 0;
ld_t report_time_float = 0;

char stat_log_fname[STR_LEN];
char work_log_fname[STR_LEN];
char work_out_log_fname[STR_LEN];
char err_log_fname[STR_LEN];
char info_log_fname[STR_LEN];
char warning_log_fname[STR_LEN];

char *procname = "main";
int work_output_type = OUTPUT_FILE;
int work_output_flg = 0;

void write_report_str(char *work_type, char *comment);
void form_log_head(void);
void handler(int sig);

char arg_cmdline[STR_LEN];

static void set_bltk_root(char *path);
static void create_version_file(char *wl_name, char *wl_version);
static void get_info(int no);

static int sig_abort_flg = 0;
static int help_cnt = 0;
static int version_flg = 0;

void prog_sleep(unsigned int seconds)
{
	(void)usleep(seconds * MCSEC_IN_SEC);
}

static int prog_exit_flg = 0;

void prog_exit(int status)
{
	int st;

	if (prog_exit_flg) {
		return;
	}
	prog_exit_flg = 1;
	abort_flg = 1;

	if (!init_completed) {
		exit(status);	/* real exit */
	}

	prog_sleep(1);
	turn_off_stat_memory();

	if (parent_flg) {
		if (pid_stat_log != EMPTY_VALUE) {
			if (!sig_abort_flg || show_demo == 0) {
				debug("send SIGTERM to stat, pid %d",
				      pid_stat_log);
				(void)kill(pid_stat_log, SIGTERM);
			} else {
				create_stop_file();
			}
			(void)waitpid(pid_stat_log, &st, 0);
			pid_stat_log = EMPTY_VALUE;
		}
		if (pid_spy_log != EMPTY_VALUE) {
			if (!sig_abort_flg) {
				debug("send SIGKILL to spy");
				(void)kill(pid_spy_log, SIGKILL);
			}
			(void)waitpid(pid_spy_log, &st, 0);
			pid_spy_log = EMPTY_VALUE;
		}
		if (pid_dpms != EMPTY_VALUE) {
			if (!sig_abort_flg) {
				debug("send SIGTERM to dpms");
				(void)kill(pid_dpms, SIGTERM);
			}
			(void)waitpid(pid_dpms, &st, 0);
			pid_dpms = EMPTY_VALUE;
		}
		if (access(fail_fname, F_OK) == 0 || status != 0) {
			write_report_str(FAIL_MSG, 0);
			(void)sprintf(prt_str, "Test failed "
				      "(see %s/work_out.log and other log "
				      "files for more details)\n", results);
			write_to_err_log(prt_str);
			(void)sprintf(prt_str, "Test failed\n");
			write_to_work_out_log_only(prt_str);
			status = 1;
		} else {
			write_report_str(PASS_MSG, 0);
			(void)sprintf(prt_str, "Test passed\n");
			write_to_stdout_work_out_log(prt_str);
			status = 0;
		}
		(void)prog_system("xset dpms force on >/dev/null 2>&1");
	}
	exit(status);		/* real exit */
}

void create_stop_file()
{
	(void)close(open(stop_fname, O_RDWR | O_CREAT, 0666));
}

int check_stop_file()
{
	if (access(stop_fname, F_OK) == 0) {
		return (1);
	}
	return (0);
}

void create_pass_file(void)
{
	(void)close(open(pass_fname, O_RDWR | O_CREAT, 0666));
}

void create_fail_file(void)
{
	(void)close(open(fail_fname, O_RDWR | O_CREAT, 0666));
}

static void set_signal(int sig)
{
	if (signal(sig, handler) == SIG_ERR) {
		(void)sprintf(prt_str, "signal(%d) failed: errno %d (%s)\n",
			      sig, errno, strerror(errno));
		write_to_err_log(prt_str);
		prog_exit(1);
	}
}

void save_sys_info(int no)
{
	char cmd[STR_LEN];

	/* results size decreasing - experimental */
	if (!stat_system)
		return;

	if (no != 0) {
		(void)sprintf(cmd, "./bin/bltk_save_sys_info %s/system%d",
			      results, no);
	} else {
		(void)sprintf(cmd, "./bin/bltk_save_sys_info %s/system",
			      results);
	}
	(void)prog_system(cmd);
}

void save_sys_info_2(void)
{
	if (!stat_log_proc_flg || sys_info_2_done) {
		return;
	}
	get_info(2);
	save_sys_info(2);
	sys_info_2_done = 1;
}

static int spy_log(void)
{
	char cmd[STR_LEN];
	int ret;

	(void)sprintf(cmd,
		      "rm -f %s/spy.log; ./bin/bltk_spy -t %llu -f %s/spy.log",
		      results, report_time / MCSEC_IN_MSEC, results);
	ret = prog_system(cmd);
	return (ret);
}

static char MSG_COMMENT[STR_LEN];

static char *get_comment(void)
{
	int fd = EMPTY_VALUE, sz;

	fd = open(BLTK_COMMENT, O_RDONLY);
	if (fd < 0) {
		return (NULL);
	}
	(void)memset(MSG_COMMENT, 0, STR_LEN);
	sz = read(fd, MSG_COMMENT, STR_LEN);
	(void)close(fd);
	(void)unlink(BLTK_COMMENT);
	if (sz > 1) {
		return (MSG_COMMENT);
	} else {
		return (NULL);
	}
}

int prog_system(char *cmd)
{
	int ret;

	ret = system(cmd);

	if (WIFSIGNALED(ret)) {
		debug("SYSTEM: signal %d (%s) received, cmd = %s\n",
		      WTERMSIG(ret), strsignal(WTERMSIG(ret)), cmd);
		if (WTERMSIG(ret) == SIGINT) {
			(void)kill(getpid(), SIGINT);
			(void)prog_sleep(10);
		} else if (WTERMSIG(ret) == SIGQUIT) {
			(void)kill(getpid(), SIGQUIT);
			(void)prog_sleep(10);
		} else if (WTERMSIG(ret) == SIGTERM) {
			(void)kill(getpid(), SIGTERM);
			(void)prog_sleep(10);
		}
	}
	return (ret);
}

void handler(int sig)
{
	debug("signal %d (%s) received", sig, strsignal(sig));

	(void)set_signal(sig);
	if (sig == SIGUSR1) {
		set_signal(SIGUSR1);
		write_report_str(WORK_MSG, get_comment());
		return;
	}
	if (sig == SIGUSR2) {
		set_signal(SIGUSR2);
		write_report_str(SLEEP_MSG, get_comment());
		return;
	}

	turn_off_stat_memory();

	if (sig == SIGHUP) {
		set_signal(SIGHUP);
		return;
	}

	(void)sprintf(prt_str, "%s: signal %d (%s) received\n",
		      procname, sig, strsignal(sig));
	write_to_work_out_log(prt_str);
	if (work_log_proc_flg || stat_log_proc_flg) {
		write_report_str(DEAD_MSG, 0);
	}

	save_sys_info_2();

	if (sig_abort_flg) {
		prog_exit(1);
	}
	sig_abort_flg = 1;

	sync();
	prog_exit(1);
}

char *get_realpath(char *path)
{
	char resolved_path[STR_LEN];
	char *ret;

	errno = 0;
	ret = realpath(path, resolved_path);
	if (ret == NULL) {
		(void)sprintf(prt_str,
			      "Cannot get realpath of %s, "
			      "errno %d(%s)\n", path, errno, strerror(errno));
		write_to_err_log(prt_str);
		prog_exit(1);
	}
	ret = strdup(resolved_path);

	return (ret);
}

char *get_realpath2(char *path)
{
	char resolved_path[STR_LEN];
	char *ret;

	errno = 0;
	ret = realpath(path, resolved_path);
	if (ret == NULL) {
		return (NULL);
	}
	ret = strdup(resolved_path);

	return (ret);
}

void prog_putenv(char *name, char *value)
{
	char str[STR_LEN];

	(void)sprintf(str, "%s=%s", name, value);
	(void)putenv(strdup(str));
	(void)strcat(str, "\n");
}

void prog_putenv_int(char *name, int value)
{
	char str[STR_LEN];

	(void)sprintf(str, "%s=%d", name, value);
	(void)putenv(strdup(str));
	(void)strcat(str, "\n");
}

xtime_t prog_time(void)
{
	struct timeval tv;
	int ret;
	xtime_t tv_sec, tv_usec;

	tv.tv_sec = 0;
	tv.tv_usec = 0;

	ret = gettimeofday(&tv, NULL);
	if (ret != 0) {
		(void)sprintf(prt_str,
			      "gettimeofday() failed, "
			      "errno %d(%s)\n", errno, strerror(errno));
		write_to_err_log(prt_str);
		prog_exit(1);
	}
	tv_sec = tv.tv_sec;
	tv_usec = tv.tv_usec;

	return (tv_sec * MSEC_IN_SEC + tv_usec / MCSEC_IN_MSEC);
}

void prog_usleep(xtime_t t)
{
	(void)usleep(t * MCSEC_IN_MSEC);
}

static xtime_t xtime(void)
{
	return (prog_time());
}

static void idle(xtime_t t)
{
	if (debug_mode) {
		return;
	}
	(void)usleep(t * MCSEC_IN_MSEC);
}

static void load(xtime_t t)
{
	xtime_t t1, t2, t3 = t;

	t1 = xtime();

	if (debug_mode) {
		return;
	}

	while (1) {
		t2 = xtime();
		if (t2 - t1 >= t3) {
			return;
		}
	}
}

static void check_exec_access(char *prog)
{
	if (access(prog, X_OK) != 0) {
		(void)sprintf(prt_str, "Cannot execute %s\n", prog);
		write_to_err_log(prt_str);
		prog_exit(1);
	}
}

static int run_workload(char *wl)
{
	int ret;
	char cmd[STR_LEN];

	if (user_workload_flg == 0) {
		check_exec_access(wl);
	}

	if (work_output_type == OUTPUT_FILE) {
		(void)sprintf(cmd, "%s >>%s 2>&1", wl, work_out_log_fname);
	} else if (work_output_type == OUTPUT_CONSOLE_FILE) {
		(void)sprintf(cmd,
			      "%s 2>&1 | tee -ai %s", wl, work_out_log_fname);
	} else if (work_output_type == OUTPUT_NULL) {
		(void)sprintf(cmd, "%s >>%s 2>&1", wl, "/dev/null");
	} else if (work_output_type == OUTPUT_CONSOLE) {
		(void)sprintf(cmd, "%s", wl);
	} else {
		(void)sprintf(prt_str,
			      "Output type is not valid, "
			      "type is %d, expected value is from %d to %d\n",
			      work_output_type, OUTPUT_MIN, OUTPUT_MAX);
		write_to_work_out_log(prt_str);
		return (1);
	}

	write_to_work_out_log(cmd);
	write_to_work_out_log("\n");
	write_report_str(NEW_WORK_MSG, 0);
	errno = 0;
	ret = prog_system(cmd);
	if (ret != 0 || access(fail_fname, F_OK) == 0) {
		(void)sprintf(prt_str, "%s failed\n", cmd);
		write_to_work_out_log(prt_str);
		return (1);
	}

	return (0);
}

static int discharging_workload(void)
{
	int i, no = 0;
	char *m;
	xtime_t t1;
	pid_t pid[N_PROC];
	int status;
	char bat_s[MAX_BAT];

	write_report_str(NEW_WORK_MSG, 0);

	(void)memset(bat_s, 0, MAX_BAT);

	while (1) {
		for (i = 0; i < N_PROC; i++) {
			if ((pid[i] = fork()) == 0) {
				parent_flg = 0;
				work_log_proc_flg = 0;
				t1 = prog_time();
				while (prog_time() - t1 < report_time) {
					m = malloc(M_PROC);
					if (m == NULL) {
						(void)sprintf(prt_str,
							      "malloc(%d) "
							      " failed\n",
							      M_PROC);
						write_to_err_log(prt_str);
						prog_exit(1);
					}
					(void)memset(m, i, M_PROC);
					(void)free(m);
				}
				prog_exit(0);
			} else if (pid[i] < 0) {
				(void)sprintf(prt_str, "fork() failed: "
					      "errno %d (%s)\n",
					      errno, strerror(errno));
				write_to_err_log(prt_str);
				prog_exit(1);
			}
		}
		for (i = 0; i < N_PROC; i++) {
			(void)waitpid(pid[i], &status, 0);
		}
		write_report_str(WORK_MSG, 0);
		for (i = 1; i <= bat_num; i++) {
			if (bat_s[i] == 1) {
				continue;
			}
			no = bat_path[i]->no;
			if (no < 0) {
				no = 0;
			}
			if (bat_percent[i] <= 5) {
				(void)sprintf(prt_str,
					      "Battery %d nearly discharged\a\n",
					      no);
				write_to_work_out_log(prt_str);
			}
			if (bat_percent[i] == 0) {
				(void)sprintf(prt_str,
					      "Battery %d discharged\a\n", no);
				write_to_work_out_log(prt_str);
				bat_s[i] = 1;
			}
		}
	}
}

static int charging_workload(void)
{
	int i, cnt_bat, no = 0;
	char bat_s[MAX_BAT];

	write_report_str(NEW_WORK_MSG, 0);

	(void)memset(bat_s, 0, MAX_BAT);

	for (;;) {
		for (i = 1; i <= bat_num; i++) {
			if (bat_s[i] == 1) {
				continue;
			}
			no = bat_path[i]->no;
			if (no < 0) {
				no = 0;
			}
			if (bat_percent[i] >= 95) {
				(void)sprintf(prt_str,
					      "Battery %d nearly charged\a\n",
					      no);
				write_to_work_out_log(prt_str);
			}
			if (get_bat_charge_state(i) == CHARGED) {
				(void)sprintf(prt_str,
					      "Battery %d charged\a\n", no);
				write_to_work_out_log(prt_str);
				bat_s[i] = 1;
			}
		}
		cnt_bat = 0;
		for (i = 1; i <= bat_num; i++) {
			cnt_bat += bat_s[i];
		}
		if (cnt_bat == bat_num) {
			(void)sprintf(prt_str, "Charged\a\n");
			write_to_work_out_log(prt_str);
			create_pass_file();
			return (0);
		}
		(void)prog_usleep(report_time);
		write_report_str(SLEEP_MSG, 0);
	}
	return (0);
}

static ll_t load_idle_time = 60 * MSEC_IN_SEC;

static int debug_workload(void)
{
	char sstr[STR_LEN];
	char wstr[STR_LEN];
	xtime_t p;

	if (arg_time != EMPTY_VALUE) {
		load_idle_time = arg_time * MSEC_IN_SEC;
	}

	p = (load_idle_time * proc_load) / 100;

	(void)sprintf(sstr, "Idle for %llu msec\n", (load_idle_time - p));

	(void)sprintf(wstr, "Load for %llu msec\n", p);

	for (;;) {
		if (proc_load > 0) {
			load(p);
		}
		if (proc_load < 100) {
			idle(load_idle_time - p);
		}
	}
	return (0);
}

static int stat_log(void)
{
	xtime_t t_sleep;
	int cnt_report_time = 0;

	write_report_str(NEW_WORK_MSG, 0);

	cnt_report_time++;

	for (;;) {
		t_sleep = (report_time * cnt_report_time) -
		    (prog_time() - time_start);
		if (t_sleep >= 0) {
			(void)prog_usleep(t_sleep);
		}
		write_report_str(LOG_MSG, 0);
		cnt_report_time++;
		if (idle_workload_flg && idle_test_time != EMPTY_VALUE) {
			if (prog_time() - time_start >= idle_test_time * 1000) {
				break;
			}
		}
		if (show_demo) {
			if (check_stop_file()) {
				break;
			}
		}
	}
	prog_exit(0);
	return (0);
}

static int ask_results(void)
{
	char str[STR_LEN], *rstr;

	if (yes) {
		return (0);
	}
	if (access(results, F_OK) != 0) {
		return (0);
	}
	(void)fprintf(stdout, "Warning: %s exists, overwrite it? (y/n[n])",
		      results);
	str[0] = 0;
	rstr = fgets(str, STR_LEN, stdin);
	if (rstr != str) {
		prog_err_printf("fgets() failed, cannot continue the test\n");
		prog_exit(1);
	}
	if (rstr[0] != 'y') {
		prog_err_printf("Test aborted by user\n");
		prog_exit(1);
	}
	return (0);
}

static void start_warning(void)
{
	write_to_stdout_work_out_log("Please make sure:\n"
				     "  no other load is applied to the system,\n"
				     "  screen saver, dpms, battery warning are "
				     "turned off (see doc/HOWTO),\n"
				     "  auto update, other network activity, "
				     "cron commands, ... are turned off too.\n"
				     "Set screen to minimal brigthness, "
				     "remove usb mouse, flash, ... if present.\n");
	if (player_workload_flg) {
		write_to_stdout_work_out_log("Insert DVD if needed.\n");
	}
}

static void start_warning2(void)
{
	write_to_stdout_work_out_log("Do NOT touch anything\n");
}

static void pre_init_vars(void)
{
	char cmd[STR_LEN];

	(void)sprintf(cmd, "%s modprobe cpufreq_stats >>%s 2>&1",
		      bltk_sudo, warning_log_fname);
	(void)prog_system(cmd);
}

static int environment_init(int argc, char **argv)
{
	char cmdline[STR_LEN];
	char cmd[STR_LEN];
	char str[STR_LEN];
	int ret, i;

	(void)unlink(LAST_RESULTS);
	ret = symlink(results, LAST_RESULTS);
	if (ret != 0) {
		(void)sprintf(prt_str, "symlink(%s, %s) failed, "
			      "errno %d (%s)\n",
			      results, LAST_RESULTS, errno, strerror(errno));
		write_to_err_log(prt_str);
		prog_exit(1);
	}

	(void)sprintf(cmd, "rm -rf %s; mkdir -p -m 0777 %s", results, results);
	ret = prog_system(cmd);
	if (ret != 0) {
		(void)sprintf(prt_str, "%s failed\n", cmd);
		write_to_err_log(prt_str);
		prog_exit(1);
	}
	results = get_realpath(results);
	(void)sprintf(warning_log_fname, "%s/warning.log", results);
	prog_putenv("BLTK_DEBUG_LOG_FILE", warning_log_fname);

	prog_putenv("BLTK_RESULTS", results);

	(void)sprintf(stop_fname, "%s/stop", results);
	(void)sprintf(fail_fname, "%s/fail", results);
	(void)sprintf(pass_fname, "%s/pass", results);
	prog_putenv("BLTK_FAIL_FNAME", fail_fname);
	prog_putenv("BLTK_PASS_FNAME", pass_fname);

	(void)sprintf(err_log_fname, "%s/err.log", results);
	prog_putenv("BLTK_ERR_LOG_FILE", err_log_fname);

	if (!stat_log_ignore) {
		(void)sprintf(stat_log_fname, "%s/stat.log", results);
		fd_stat_log = open(stat_log_fname,
				   O_RDWR | O_CREAT | O_TRUNC | O_APPEND, 0666);
		if (fd_stat_log < 0) {
			(void)sprintf(prt_str, "open() of %s failed: "
				      "errno %d (%s)\n",
				      stat_log_fname, errno, strerror(errno));
			write_to_err_log(prt_str);
			prog_exit(1);
		}
		prog_putenv("BLTK_STAT_LOG_FILE", stat_log_fname);
	}

	(void)sprintf(info_log_fname, "%s/info.log", results);
	prog_putenv("BLTK_INFO_LOG_FILE", info_log_fname);

	if (!work_log_ignore) {
		(void)sprintf(work_log_fname, "%s/work.log", results);
		fd_work_log = open(work_log_fname,
				   O_RDWR | O_CREAT | O_TRUNC | O_APPEND, 0666);

		if (fd_work_log < 0) {
			(void)sprintf(prt_str, "open() of %s failed: "
				      "errno %d (%s)\n",
				      work_log_fname, errno, strerror(errno));
			write_to_err_log(prt_str);
			prog_exit(1);
		}
		prog_putenv("BLTK_WORK_LOG_FILE", work_log_fname);
		fd_proc_log = fd_work_log;
	}

	(void)sprintf(work_out_log_fname, "%s/work_out.log", results);

	prog_putenv("BLTK_WORK_OUT_LOG_FILE", work_out_log_fname);

	for (i = 1; i < MAX_BAT; i++) {
		bat_percent[i] = 100;
	}

	cmdline[0] = 0;
	(void)strcat(cmdline, "echo '");
	for (i = 0; i < argc; i++) {
		(void)strcat(cmdline, argv[i]);
		(void)strcat(cmdline, " ");
	}
	(void)strcat(cmdline, "'");

	(void)sprintf(cmd, "%s >>history", cmdline);
	(void)prog_system(cmd);

	(void)sprintf(cmd, "%s >last_cmd", cmdline);
	(void)prog_system(cmd);

	(void)sprintf(cmd, "%s >%s/cmd", cmdline, results);
	(void)prog_system(cmd);

	(void)sprintf(str, "%s/bin/bltk_sudo", bltk_root);
	bltk_sudo = strdup(str);
	if (access(str, X_OK) != 0) {
		(void)sprintf(prt_str, "Cannot access %s\n", str);
		write_to_err_log(prt_str);
		(void)sprintf(prt_str, "Please perform 'make su' command\n");
		write_to_err_log(prt_str);
		prog_exit(1);
	}
	(void)sprintf(cmd, "%s/bin/bltk_sudo", bltk_root);
	ret = prog_system(cmd);
	if (ret != 0) {
		(void)sprintf(prt_str, "Cannot run %s\n", str);
		write_to_err_log(prt_str);
		(void)sprintf(prt_str, "Please perform 'make su' command\n");
		write_to_err_log(prt_str);
		prog_exit(1);
	}
	prog_putenv("BLTK_SUDO_CMD", str);

	set_signal(SIGTERM);
	set_signal(SIGINT);
	set_signal(SIGQUIT);

	set_signal(SIGUSR1);
	set_signal(SIGUSR2);
	set_signal(SIGHUP);

	(void)sprintf(cmd, "mkdir -p -m 0777 %s/tmp", bltk_root);
	ret = prog_system(cmd);
	if (ret != 0) {
		(void)sprintf(prt_str, "%s failed\n", cmd);
		write_to_err_log(prt_str);
		prog_exit(1);
	}

	pre_init_vars();

	init_vars();

	return (0);
}

static void create_wl_version_file(char *wl_name, char *wl_version)
{
	int fd = EMPTY_VALUE, len, wret;
	char fname[STR_LEN];
	char str[STR_LEN];

	(void)sprintf(fname, "%s/%s", results, "workload");
	fd = open(fname, O_RDWR | O_CREAT | O_TRUNC | O_APPEND, 0666);
	if (fd < 0) {
		(void)sprintf(prt_str,
			      "open() of %s failed: errno %d (%s)\n",
			      fname, errno, strerror(errno));
		write_to_err_log(prt_str);
		prog_exit(1);
	}
	(void)sprintf(str, "%s %s\n", wl_name, wl_version);
	len = strlen(str);
	wret = write(fd, str, len);
	if (wret != len) {
		(void)sprintf(prt_str, "write() to %s failed: "
			      "errno %d (%s)\n", fname, errno, strerror(errno));
		write_to_err_log(prt_str);
		prog_exit(1);
	}
	(void)close(fd);
	create_version_file(wl_name, wl_version);
}

static void create_version_file(char *wl_name, char *wl_version)
{
	int fd = EMPTY_VALUE, len, wret;
	char fname[STR_LEN];
	char buf[STR_LEN];

	(void)sprintf(fname, "%s/%s", results, "version");
	fd = open(fname, O_RDWR | O_CREAT | O_TRUNC | O_APPEND, 0666);
	if (fd < 0) {
		(void)sprintf(prt_str,
			      "open() of %s failed: errno %d (%s)\n",
			      fname, errno, strerror(errno));
		write_to_err_log(prt_str);
		prog_exit(1);
	}
	(void)sprintf(buf, "bltk %s\n%s %s\n",
		      BLTK_VERSION, wl_name, wl_version);
	len = strlen(buf);
	wret = write(fd, buf, len);
	if (wret != len) {
		(void)sprintf(prt_str, "write() to %s failed: "
			      "errno %d (%s)\n", fname, errno, strerror(errno));
		write_to_err_log(prt_str);
		prog_exit(1);
	}
	(void)close(fd);
}

static void create_comment_file(void)
{
	int fd = EMPTY_VALUE, len, wret, i;
	char fname[STR_LEN];
	char str[STR_LEN];

	if (comment_cnt == 0) {
		return;
	}

	(void)sprintf(fname, "%s/%s", results, "comment");
	fd = open(fname, O_RDWR | O_CREAT | O_TRUNC | O_APPEND, 0666);
	if (fd < 0) {
		(void)sprintf(prt_str,
			      "open() of %s failed: errno %d (%s)\n",
			      fname, errno, strerror(errno));
		write_to_err_log(prt_str);
		prog_exit(1);
	}
	for (i = 0; i < comment_cnt; i++) {
		(void)sprintf(str, "%s\n", comment[i]);
		len = strlen(str);
		wret = write(fd, str, len);
		if (wret != len) {
			(void)sprintf(prt_str,
				      "write() to %s failed: "
				      "errno %d (%s)\n",
				      fname, errno, strerror(errno));
			write_to_err_log(prt_str);
			prog_exit(1);
		}
	}
	(void)close(fd);
}

struct option_help {
	char *name;
	char *help;
};

static char *pname = NULL;

static char popt_mask[256];
static int popt_mask_flg = 0;

static char *popt =
    "hVvo:aNcCBXAHt:r:swulm:Qp:d:iIDPRGOU:g:YZJ:T:F:W:L:MSn:j:K:e:E:yzq:xb:f:k:";

static struct option popt_long[] = {
	{"help", 0, 0, 'h'},
	{"version", 0, 0, 'V'},
	{"verbose", 0, 0, 'v'},
	{"ac-ignore", 0, 0, 'a'},
	{"time-stat-ignore", 0, 0, 'N'},
	{"ac-stat-ignore", 0, 0, 'A'},
	{"cpu-stat-ignore", 0, 0, 'c'},
	{"cpu-add-stat-ignore", 0, 0, 'C'},
	{"bat-stat-ignore", 0, 0, 'B'},
	{"disp-stat-ignore", 0, 0, 'X'},
	{"hd-stat-ignore", 0, 0, 'H'},

	{"report-time", 1, 0, 't'},
	{"results", 1, 0, 'r'},
	{"stat-ignore", 0, 0, 's'},
	{"work-stat-ignore", 0, 0, 'w'},
	{"stat-memory", 1, 0, 'm'},

	{"idle-test", 0, 0, 'i'},
	{"idle", 0, 0, 'I'},
	{"reader", 0, 0, 'R'},
	{"developer", 0, 0, 'D'},
	{"player", 0, 0, 'P'},
	{"game", 0, 0, 'G'},
	{"office", 0, 0, 'O'},
	{"user", 1, 0, 'U'},
	{"user-init", 1, 0, 'g'},
	{"discharging", 0, 0, 'Y'},
	{"charging", 0, 0, 'Z'},

	{"jobs", 1, 0, 'J'},
	{"time", 1, 0, 'T'},
	{"file", 1, 0, 'F'},
	{"prog", 1, 0, 'W'},
	{"title", 1, 0, 'L'},
	{"manufacturer", 0, 0, 'M'},
	{"show", 0, 0, 'S'},
	{"show-num", 1, 0, 'n'},
	{"show-cnt", 1, 0, 'j'},
	{"show-time", 1, 0, 'T'},

	{"comment", 1, 0, 'K'},

	{"init-prog", 1, 0, 'e'},
	{"init-prog-su", 1, 0, 'E'},

	{"yes", 0, 0, 'y'},

	{"debug", 0, 0, 'Q'},
	{"cpu-load", 1, 0, 'p'},
	{"disp-load", 1, 0, 'd'},

	{"output", 1, 0, 'o'},
	{"debug-vars", 0, 0, 'z'},
	{"debug-vars-file", 1, 0, 'q'},
	{"dpms", 0, 0, 'x'},
	{"spy", 0, 0, 'u'},
	{"simul-laptop", 0, 0, 'l'},
	{"bat-sync", 1, 0, 'b'},
	{"user-field", 1, 0, 'f'},
	{"stat-system", 1, 0, 'k'},

	{0, 0, 0, 0}
};
static struct option_help popt_help[] = {
	{"help", "this info"},
	{"version", "version"},
	{"verbose", "verbose"},
	{"ac-ignore", "ignore ac adapter state check (on/off)"},
	{"time-stat-ignore", "disable time statistics"},
	{"ac-stat-ignore", "disable ac adapter statistics"},
	{"cpu-stat-ignore", "disable cpu load statistics"},
	{"cpu-add-stat-ignore", "disable cpu additional statistics"},
	{"bat-stat-ignore", "disable battery statistics"},
	{"disp-stat-ignore", "Disable display state statistics"},
	{"hd-stat-ignore", "disable hard drive state statistics"},
	{"report-time", "frequency of report line generation in seconds"},
	{"results", "name of results directory"},
	{"stat-ignore", "disable all statistics"},
	{"work-stat-ignore", "disable workload statistics"},
	{"stat-memory", "dump statistics directly on disk or keep in memory,"
	 "\n\tif statistics are kept in memory, it will be dumped"
	 "\n\ton disk at low battery capacity, or at the test end"
	 "\n\t0 - disk, 1 - memory, default 1"},
	{"debug", "debug workload (see cpu-load and disp-load below)"},
	{"cpu-load", "debug workload, the time cpu loaded in percent"},
	{"disp-load", "Debug workload, the time display on in percent"},
	{"idle-test", "idle test"},
	{"idle", "idle workload"},
	{"developer", "developer workload"},
	{"player", "dvd-playback workload"},
	{"reader", "reader workload"},
	{"game", "3D-gaming workload"},
	{"office", "office productivity workload"},
	{"user", "user-specified workload (path to executable)"},
	{"user-init", "setup routines for user-specified workload"},
	{"discharging", "battery discharge mode"},
	{"charging", "battery charge mode"},
	{"jobs", "make jobs number"},
	{"time", "workload time"},
	{"file", "workload file"},
	{"prog", "workload program"
	 "\n\tname of player (player workload, default 'mplayer')"
	 "\n\tname of web-browser (reader workload, default 'firefox')"},
	{"title", "title of web-browser document"},
	{"manufacturer", "enable time and cpu load statistics only"},
	{"show", "demo/debug mode, one iteration only"},
	{"show-num", "demo/debug mode, 'show-num' iteration"},
	{"show-cnt", "demo/debug mode, 'show-cnt' sub iteration"},
	{"show-time", "demo/debug mode, debug time"},
	{"comment", "user comment for report"},
	{"init-prog", "run program before test starting"},
	{"init-prog-su", "run program as root before test starting"},
	{"yes", "auto 'yes' answer to all questions"},
	{"output", "direct workload output:"
	 "\n\t0 - file, 1 - file and console,"
	 "\n\t2 - /dev/null), other - console"},
	{"debug-vars", "debug option"},
	{"debug-vars-file", "debug option - debug variables file"},
	{"dpms", "debug option - try to use display power management"},
	{"spy", "debug option - try to find out unexpected system activity"},
	{"simul-laptop", "debug option, laptop simulation"},
	{"bat-sync", "debug option, battery critical capacity, default 5%"},
	{"user-field",
	 "the output of user-specified command being added to statistics"},
	{"stat-system", "debug option, save system files, default 0"},
	{0, 0}
};

static char *get_popt_help(char *name)
{
	int i;
	char *n;

	for (i = 0;; i++) {
		n = (char *)popt_help[i].name;
		if (n == NULL) {
			break;
		}
		if (strcmp(n, name) == 0) {
			return (popt_help[i].help);
		}
	}
	return ("Help NOT FOUND...........................");
}

static void check_popt(void);

static void usage(char *msg)
{
	if (msg) {
		(void)fprintf(stderr, "%s\n", msg);
	}
	(void)fprintf(stderr, "Usage: %s -%s\n", pname, popt);
	(void)fprintf(stderr, "\tType %s -h to get more information\n", pname);
}

static void check_free_popt(void)
{
	int i, j, s, found;

	s = strlen(popt);

	(void)fprintf(stdout, "  free:  ");
	for (i = 0; i < 255; i++) {
		if (!isalpha(i)) {
			continue;
		}
		found = 0;
		for (j = 0; j < s; j++) {
			if (i == popt[j]) {
				found = 1;
				break;
			}
		}
		if (!found) {
			(void)fprintf(stdout, " %c", i);
		}
	}
	(void)fprintf(stdout, "\n");
}

static void common_usage(void)
{
	int i, v;
	char s[SMALL_STR_LEN];
	char *h, *n;
	char *has_arg;

	if (!popt_mask_flg) {
		(void)fprintf(stdout, "Usage: %s -%s\n", pname, popt);
	}

	for (i = 0;; i++) {
		n = (char *)popt_long[i].name;
		if (n == NULL) {
			break;
		}
		v = popt_long[i].val;
		if (popt_mask_flg && !popt_mask[v]) {
			continue;
		}
		if (popt_long[i].has_arg) {
			has_arg = ":";
		} else {
			has_arg = "";
		}
		(void)sprintf(s, "  --%s%s(-%c%s)",
			      popt_long[i].name, has_arg,
			      popt_long[i].val, has_arg);
		h = get_popt_help(n);
		(void)fprintf(stdout, "%s - %s\n", s, h);
	}

	if (!popt_mask_flg) {
		(void)fprintf(stdout,
			      "Examples:\n"
			      "    bltk -D or --developer\n"
			      "        developer workload running\n"
			      "    bltk -R or --reader\n"
			      "        reader workload running\n"
			      "    bltk -i or --idle [-T 60]\n"
			      "        idle workload running for 60 seconds\n");
	}

	if (help_cnt > 1) {
		(void)fprintf(stdout, "Options Checker:\n");
		check_popt();
		check_free_popt();
	}
}

static int check_popt_help(char *name)
{
	int i;
	char *n;

	for (i = 0;; i++) {
		n = (char *)popt_help[i].name;
		if (n == NULL) {
			break;
		}
		if (strcmp(n, name) == 0) {
			return (0);
		}
	}
	(void)fprintf(stdout, "Help for %s NOT FOUND\n", name);
	return (EMPTY_VALUE);
}

static int check_short_popt(char *name, char *short_name, int has_arg)
{
	char *ptr;

	ptr = strstr(popt, short_name);
	if (ptr == NULL) {
		(void)fprintf(stdout,
			      "Short opt for %s NOT FOUND, short = %s\n",
			      name, short_name);
		return (EMPTY_VALUE);
	}
	if (has_arg && ptr[1] != ':') {
		(void)fprintf(stdout,
			      "Short opt for %s WITHOUT ARG, short = %s\n",
			      name, short_name);
		return (EMPTY_VALUE);
	} else if (!has_arg && ptr[1] == ':') {
		(void)fprintf(stdout,
			      "Short opt for %s WITH ARG, short = %s\n",
			      name, short_name);
		return (EMPTY_VALUE);
	}

	return (0);
}

static int check_long_popt(char *short_name, int has_arg)
{
	int i, ha;
	char *n, sn[2];

	for (i = 0;; i++) {
		n = (char *)popt_long[i].name;
		if (n == NULL) {
			break;
		}
		sn[0] = popt_long[i].val;
		sn[1] = 0;
		if (strncmp(short_name, sn, 1) != 0) {
			continue;
		}
		ha = popt_long[i].has_arg;
		if (has_arg && ha == 0) {
			(void)fprintf(stdout,
				      "Long opt for %s HAS NOT ARG, long = %s\n",
				      short_name, short_name);
			return (EMPTY_VALUE);
		} else if (!has_arg && ha) {
			(void)fprintf(stdout,
				      "Long opt for %s HAS ARG, long = %s\n",
				      short_name, n);
			return (EMPTY_VALUE);
		}
		return (0);
	}
	(void)fprintf(stdout, "Long opt for %s NOT FOUND\n", short_name);
	return (EMPTY_VALUE);
}

static void check_popt(void)
{
	int i, s, ha;
	char *n, sn[2];

	for (i = 0;; i++) {
		n = (char *)popt_long[i].name;
		if (n == NULL) {
			break;
		}
		sn[0] = popt_long[i].val;
		sn[1] = 0;
		ha = popt_long[i].has_arg;
		(void)check_popt_help(n);
		(void)check_short_popt(n, sn, ha);
	}
	s = strlen(popt);
	i = 0;
	while (i < s) {
		n = popt + i;
		sn[0] = n[0];
		sn[1] = 0;
		i++;
		if (popt[i] == ':') {
			ha = 1;
			i++;
		} else {
			ha = 0;
		}
		(void)check_long_popt(sn, ha);
	}
}

static void version(void)
{
	if (idle_test_mode) {
		(void)fprintf(stdout, "Idle Test %s\n", BLTK_IDLE_TEST_VERSION);
	} else {
		(void)fprintf(stdout,
			      "Battery Life Tool Kit %s\n", BLTK_VERSION);
	}
}

static void set_path()
{
	char *path, *npath;

	path = getenv("PATH");
	if (path == NULL) {
		return;
	}
	npath = malloc(strlen(path) + 128);
	if (npath == NULL) {
		return;
	}
	(void)sprintf(npath, "PATH=%s:/usr/sbin:/sbin", path);
	(void)putenv(npath);
	return;
}

static char *check_bltk_root(char *dir)
{
	char name[STR_LEN];

	if (dir == NULL) {
		dir = ".";
	}
	(void)sprintf(name, "%s/.bltk", dir);
	if (access(name, F_OK) == 0) {
		return (dir);
	}
	return (NULL);
}

static char *get_bltk_root_by_argv0(char *argv0)
{
	char *wp1, *wp2;

	wp1 = get_realpath2(argv0);

	if (wp1 == NULL) {
		return (NULL);
	}
	wp2 = dirname(wp1);
	if (wp2 == 0) {
		prog_err_printf("Cannot get directory name of %s, "
				"errno %d(%s)\n", wp1, errno, strerror(errno));
		return (NULL);
	}
	wp1 = dirname(wp2);
	if (wp1 == 0) {
		prog_err_printf("Cannot get directory name of %s, "
				"errno %d(%s)\n", wp2, errno, strerror(errno));
		return (NULL);
	}

	wp1 = check_bltk_root(wp1);

	return (wp1);
}

static char *get_bltk_root_by_path(char *argv0)
{
	char *path, *dpath, *res;
	int i, len;
	char name[STR_LEN];

	path = getenv("PATH");
	if (path == NULL) {
		return (NULL);
	}
	path = strdup(path);
	len = strlen(path);
	dpath = path;

	for (i = 0; i < len + 1; i++) {
		if (path[i] == ':' || path[i] == 0) {
			path[i] = 0;
			res = check_bltk_root(dpath);
			if (res == NULL) {
				(void)sprintf(name, "%s/..", dpath);
				res = check_bltk_root(name);
			}
			if (res != NULL) {
				res = get_realpath2(res);
				if (res != NULL) {
					return (res);
				}
			}
			dpath = path + i + 1;
		}
	}
	return (NULL);
}

static void set_bltk_root(char *argv0)
{
	char *wp1;
	int ret;
	char cwd[STR_LEN];

	wp1 = check_bltk_root(".");
	if (wp1 == NULL) {
		wp1 = get_bltk_root_by_argv0(argv0);
	}
	if (wp1 == NULL) {
		wp1 = get_bltk_root_by_path(argv0);
	}

	if (wp1 == NULL) {
		prog_err_printf("Cannot determine bltk root directory\n");
		prog_exit(1);
	}

	ret = chdir(wp1);
	if (ret != 0) {
		prog_err_printf("Cannot change current directory "
				"to %s, errno %d(%s)\n",
				wp1, errno, strerror(errno));
		prog_exit(1);
	}
	(void)sprintf(bltk_root, "%s", getcwd(cwd, STR_LEN));
	prog_putenv("BLTK_ROOT", bltk_root);
}

void get_info(int no)
{
	int ret = 0;
	char cmd[STR_LEN];
	char str[STR_LEN];

	(void)sprintf(cmd, "./bin/bltk_get_info %d", no);
	ret = prog_system(cmd);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "./bin/bltk_get_info failed\n",
			      __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
}

static void start_warnings(void)
{
	int ac_state;

	if (ac_ignore == 0) {
		if (ac_err_workaround == 0) {
			ac_state = get_ac_state();
			if (charging_workload_flg == 1) {
				if (ac_state != ON_STATE) {
					write_to_stdout_work_out_log
					    ("Plug in AC cable\n");
					if (wait_ac_state(ON_STATE) ==
					    EMPTY_VALUE) {
						(void)sprintf(prt_str,
							      "wait_ac_state(ON_STATE) "
							      "failed\n");
						write_to_err_log(prt_str);
						prog_exit(1);
					}
				}
			} else if (ac_state != OFF_STATE) {
				start_warning();
				write_to_stdout_work_out_log
				    ("Unplug AC cable\n");
				if (wait_ac_state(OFF_STATE) == EMPTY_VALUE) {
					(void)sprintf(prt_str,
						      "wait_ac_state(OFF_STATE) "
						      "failed\n");
					write_to_err_log(prt_str);
					prog_exit(1);
				}
				start_warning2();
			} else {
				start_warning();
				start_warning2();
			}
		} else {
			write_to_stdout_work_out_log("Cannot get AC state\n");

			if (charging_workload_flg == 1) {
				write_to_stdout_work_out_log
				    ("Plug in AC cable and press enter\n");
				(void)getchar();
			} else {
				start_warning();
				write_to_stdout_work_out_log
				    ("Unplug AC cable and press enter\n");
				(void)getchar();
				start_warning2();
			}
		}
	} else {
		if (charging_workload_flg != 1) {
			start_warning();
			start_warning2();
		}
	}
}

static void idle_test_final(void)
{
	char cmd[STR_LEN];

	get_info(2);
	save_sys_info(2);
	sys_info_2_done = 1;
	if (!idle_test_mode) {
		return;
	}
	(void)sprintf(cmd, "bin/bltk_report -i %s", results);
	(void)prog_system(cmd);
	(void)sprintf(cmd, "cat %s/Report", results);
	(void)prog_system(cmd);
}

static void find_free_results(void)
{
	int i;
	char name[STR_LEN];

	if (access(results, F_OK) != 0 && errno == ENOENT) {
		return;
	}
	for (i = 1;; i++) {
		(void)sprintf(name, "%s.%03d", results, i);
		if (access(name, F_OK) != 0 && errno == ENOENT) {
			results = strdup(name);
			return;
		}
	}
}

int main(int argc, char **argv)
{
	int ret = 0;
	char cmd[STR_LEN];
	int wl_cnt = 0, i;
	char results_str[STR_LEN];
	char results_parent[STR_LEN];

	(void)umask(0);
	(void)set_path(0);

	time_start = time_prev = prog_time();

	(void)prog_system("xset dpms 0 0 0 >/dev/null 2>&1");
	(void)prog_system("xset s off >/dev/null 2>&1");

	init_first_stat();

	(void)memset(popt_mask, 0, 256);

	pname = argv[0];
	while (1) {
		int opt;
		int ind = 0;

		opt = getopt_long(argc, argv, popt, popt_long, &ind);
		if (opt == -1) {
			break;
		}
		if (opt != 'h') {
			popt_mask_flg++;
			popt_mask[opt] = 1;
		}

		switch (opt) {
		case 'h':
			help_cnt++;
			break;
		case 'V':
			version_flg = 1;
			version();
			break;
		case 'v':
			verbose = 1;
			break;
		case 'o':
			work_output_type = atol(optarg);
			work_output_flg = 1;
			if (work_output_type == 0) {
				work_output_type = OUTPUT_FILE;
			} else if (work_output_type == 1) {
				work_output_type = OUTPUT_CONSOLE_FILE;
			} else if (work_output_type == 2) {
				work_output_type = OUTPUT_NULL;
			} else {
				work_output_type = OUTPUT_CONSOLE;
			}
			break;
		case 't':
			report_time_flg = 1;
			ret = sscanf(optarg, "%Lf", &report_time_float);
			report_time = report_time_float * MCSEC_IN_SEC;
			report_time = (report_time + MCSEC_IN_MSEC / 2) /
			    MCSEC_IN_MSEC;
			report_time_msec_flg = (strstr(optarg, ".") != 0);
			break;
		case 'r':
			results_flg = 1;
			results = optarg;
			break;
		case 'a':
			ac_ignore = 1;
			break;
		case 'N':
			no_time_stat_ignore = 1;
			break;
		case 'A':
			ac_stat_ignore = 1;
			break;
		case 'c':
			cpu_stat_ignore = 1;
			break;
		case 'B':
			bat_stat_ignore = 1;
			break;
		case 'C':
			cpu_add_stat_ignore = 1;
			break;
		case 'X':
			disp_stat_ignore = 1;
			break;
		case 's':
			stat_log_ignore = 1;
			break;
		case 'w':
			work_log_ignore = 1;
			break;
		case 'u':
			spy_log_enabled = 1;
			break;
		case 'H':
			hd_stat_ignore = 1;
			break;
		case 'm':
			stat_memory_flg = 1;
			stat_memory = atol(optarg);
			break;
		case 'Q':
			debug_workload_flg = 1;
			wl_cnt++;
			break;
		case 'p':
			proc_load = atol(optarg);
			break;
		case 'D':
			developer_workload_flg = 1;
			wl_cnt++;
			break;
		case 'J':
			arg_jobs = atoi(optarg);
			break;
		case 'T':
			arg_time = show_demo_time = idle_test_time =
			    atoi(optarg);
			break;
		case 'P':
			player_workload_flg = 1;
			wl_cnt++;
			break;
		case 'R':
			reader_workload_flg = 1;
			wl_cnt++;
			break;
		case 'F':
			arg_file = optarg;
			break;
		case 'W':
			arg_prog = optarg;
			break;
		case 'L':
			arg_title = optarg;
			break;
		case 'G':
			game_workload_flg = 1;
			wl_cnt++;
			break;
		case 'O':
			office_workload_flg = 1;
			wl_cnt++;
			break;
		case 'U':
			user_workload_flg = 1;
			user_workload_prog = optarg;
			if (init_user_workload_flg == 0) {
				wl_cnt++;
			}
			break;
		case 'g':
			init_user_workload_flg = 1;
			init_user_workload_prog = optarg;
			if (user_workload_flg == 0) {
				user_workload_flg = 1;
				wl_cnt++;
			}
			break;
		case 'Y':
			discharging_workload_flg = 1;
			wl_cnt++;
			break;
		case 'Z':
			charging_workload_flg = 1;
			wl_cnt++;
			break;
		case 'M':
			manufacturer = 1;
			no_time_stat_ignore = 1;
			cpu_add_stat_ignore = 1;
			disp_stat_ignore = 1;
			hd_stat_ignore = 1;
			mem_stat_ignore = 1;
			stat_memory_flg = 1;
			stat_memory = 1;
			ac_stat_ignore = 1;
			break;
		case 'S':
			show_demo++;
			break;
		case 'n':
			if (!show_demo) {
				show_demo = 1;
			}
			show_demo_num = atoi(optarg);
			break;
		case 'j':
			if (!show_demo) {
				show_demo = 1;
			}
			show_demo_cnt = atoi(optarg);
			break;
		case 'K':
			comment[comment_cnt] = optarg;
			comment_cnt++;
			break;
		case 'e':
			start_prog_flg = 1;
			start_prog = optarg;
			start_prog_su_flg = 1;
			break;
		case 'E':
			start_prog_flg = 1;
			start_prog = optarg;
			break;
		case 'y':
			yes = 1;
			break;
		case 'z':
			debug_flg = 1;
			break;
		case 'q':
			debug_vars_file = optarg;
			break;
		case 'x':
			/* development and investigation now */
			dpms_flg = 1;
			prog_putenv("BLTK_DPMS", "TRUE");
			break;
		case 'l':
			simul_laptop = 1;
			simul_laptop_dir = optarg;
			break;
		case 'I':
			idle_mode = 1;
			prog_putenv("IDLE_MODE", "TRUE");
			wl_cnt++;
			break;
		case 'i':
			idle_test_mode = 1;
			prog_putenv("IDLE_TEST_MODE", "TRUE");
			wl_cnt++;
			break;
		case 'b':
			bat_sync = atol(optarg);
			break;
		case 'f':
			strncpy(user_field_cmd[user_field_cnt], optarg,
				STR_LEN);
			user_field_cnt++;
			break;
		case 'k':
			stat_system = atoi(optarg);
			break;
		default:
			usage("ERROR: Bad options");
			popt_mask_flg++;
			common_usage();
			prog_exit(1);
			break;
		}
	}

	if (help_cnt > 0) {
		common_usage();
		prog_exit(0);
	}

	if (version_flg) {
		prog_exit(0);
	}

	if (argc - optind != 0 && wl_cnt != 0) {
		usage("ERROR: Arguments are not allowed");
		prog_exit(1);
	}
	if (wl_cnt > 1) {
		usage("ERROR: Few workloads are not allowed");
		prog_exit(1);
	}
	if (argc - optind != 0) {
		user_workload_flg = 1;
		wl_cnt = 1;
		arg_cmdline[0] = 0;
		for (i = optind; i < argc; i++) {
			(void)strcat(arg_cmdline, argv[i]);
			(void)strcat(arg_cmdline, " ");
		}
		user_workload_prog = arg_cmdline;
	}

	if (user_workload_flg) {
		if (user_workload_prog == NULL) {
			usage("ERROR: User workload is not passed");
			prog_exit(1);
		}
	}

	if (developer_workload_flg) {
		workload_name = "developer";
	} else if (player_workload_flg) {
		workload_name = "player";
	} else if (reader_workload_flg) {
		workload_name = "reader";
	} else if (game_workload_flg) {
		workload_name = "game";
	} else if (office_workload_flg) {
		workload_name = "office";
	} else if (debug_workload_flg) {
		workload_name = "debugger";
	} else if (user_workload_flg) {
		workload_name = "user";
	} else if (discharging_workload_flg) {
		workload_name = "discharging";
	} else if (charging_workload_flg) {
		workload_name = "charging";
	} else {
		idle_workload_flg = 1;
		if (idle_test_mode) {
			workload_name = "idle-test";
		} else {
			workload_name = "idle";
		}
	}

	if (show_demo) {
		if (report_time_flg == EMPTY_VALUE) {
			report_time = 1 * MSEC_IN_SEC;
		}
		if (idle_test_time == EMPTY_VALUE) {
			idle_test_time = show_demo_time = 10;
		}
	}

	if (!results_flg) {
		(void)sprintf(results_str, "%s.results", workload_name);
		results = strdup(results_str);
	}

	init_debug_vars();

	if (results[0] != '/') {
		if (getcwd(results_parent, STR_LEN) == NULL) {
			prog_err_printf
			    ("getcwd() failed, cannot continue the test\n");
			prog_exit(1);
		}
		(void)sprintf(results_str, "%s/%s", results_parent, results);
		results = results_str;
	}

	if (!results_flg) {
		find_free_results();
	}
	ask_results();

	(void)fprintf(stdout, "Results will be available in %s directory\n",
		      results);

	/* Debugging */
	if (simul_laptop) {
		prog_putenv("BLTK_SIMUL_LAPTOP", "TRUE");
		prog_putenv("BLTK_SIMUL_LAPTOP_DIR",
			    get_realpath(simul_laptop_dir));
	} else {
		prog_putenv("BLTK_SIMUL_LAPTOP", "FALSE");
	}

	set_bltk_root(argv[0]);

	if (cpu_stat_ignore) {
		cpu_add_stat_ignore = 1;
	}

	environment_init(argc, argv);

	if (show_demo) {
		prog_putenv("BLTK_SHOW_DEMO", "TRUE");
		if (show_demo_num != EMPTY_VALUE) {
			prog_putenv_int("BLTK_SHOW_DEMO_NUM", show_demo_num);
		}
		if (show_demo_cnt != EMPTY_VALUE) {
			prog_putenv_int("BLTK_SHOW_DEMO_CNT", show_demo_cnt);
		}
		if (show_demo_time != EMPTY_VALUE) {
			prog_putenv_int("BLTK_SHOW_DEMO_TIME", show_demo_time);
		}
		if (show_demo == 1) {
			prog_putenv("BLTK_SHOW_DEMO_SLEEP", "TRUE");
		} else {
			prog_putenv("BLTK_SHOW_DEMO_SLEEP", "FALSE");
		}
	}

	if (manufacturer) {
		prog_putenv("BLTK_MANUFACTURER", "TRUE");
	}

	if (arg_file != NULL) {
		prog_putenv("BLTK_WL_FILE", arg_file);
	}
	if (arg_time != EMPTY_VALUE) {
		prog_putenv_int("BLTK_WL_TIME", arg_time);
	}
	if (arg_jobs != EMPTY_VALUE) {
		prog_putenv_int("BLTK_WL_JOBS", arg_jobs);
	}
	if (arg_prog != NULL) {
		prog_putenv("BLTK_WL_PROG", arg_prog);
	}
	if (arg_prog_args != NULL) {
		prog_putenv("BLTK_WL_PROG_ARGS", arg_prog_args);
	}
	if (arg_prog_args != NULL) {
		prog_putenv("BLTK_WL_PROG_FLG", arg_prog_args);
	}
	if (arg_title != NULL) {
		prog_putenv("BLTK_WL_TITLE", arg_title);
	}

	if (debug_workload_flg) {
		if (stat_memory_flg == 0) {
			stat_memory = 1;
		}
		if (work_output_flg == 0) {
			work_output_type = OUTPUT_CONSOLE_FILE;
		}
		if (proc_load < 0) {
			proc_load = 0;
		}
		if (proc_load > 100) {
			proc_load = 100;
		}
		create_wl_version_file(BLTK_WL_DEBUG, BLTK_WL_DEBUG_VERSION);
		(void)sprintf(prt_str, "%s Workload %s: cpu load %d\n",
			      BLTK_WL_DEBUG, BLTK_WL_DEBUG_VERSION, proc_load);
		write_to_stdout_work_out_log(prt_str);
	} else if (developer_workload_flg) {
		if (stat_memory_flg == 0) {
			stat_memory = 1;
		}
		if (work_output_flg == 0) {
			work_output_type = OUTPUT_FILE;
		}
		create_wl_version_file(BLTK_WL_DEVELOPER,
				       BLTK_WL_DEVELOPER_VERSION);
		workload = "./wl_developer/bin/bltk_wl_developer";
		(void)sprintf(prt_str, "%s Workload %s\n",
			      BLTK_WL_DEVELOPER, BLTK_WL_DEVELOPER_VERSION);
		write_to_stdout_work_out_log(prt_str);
	} else if (player_workload_flg) {
		if (stat_memory_flg == 0) {
			stat_memory = 1;
		}
		if (work_output_flg == 0) {
			work_output_type = OUTPUT_FILE;
		}
		create_wl_version_file(BLTK_WL_PLAYER, BLTK_WL_PLAYER_VERSION);
		workload = "./wl_player/bin/bltk_wl_player";
		(void)sprintf(prt_str, "%s Workload %s\n",
			      BLTK_WL_PLAYER, BLTK_WL_PLAYER_VERSION);
		write_to_stdout_work_out_log(prt_str);
	} else if (reader_workload_flg) {
		if (stat_memory_flg == 0) {
			stat_memory = 1;
		}
		if (work_output_flg == 0) {
			work_output_type = OUTPUT_FILE;
		}
		create_wl_version_file(BLTK_WL_READER, BLTK_WL_READER_VERSION);
		workload = "./wl_reader/bin/bltk_wl_reader";
		(void)sprintf(prt_str, "%s Workload %s\n",
			      BLTK_WL_READER, BLTK_WL_READER_VERSION);
		write_to_stdout_work_out_log(prt_str);
	} else if (game_workload_flg) {
		if (stat_memory_flg == 0) {
			stat_memory = 1;
		}
		if (work_output_flg == 0) {
			work_output_type = OUTPUT_FILE;
		}
		create_wl_version_file(BLTK_WL_GAME, BLTK_WL_GAME_VERSION);
		workload = "./wl_game/bin/bltk_wl_game";
		(void)sprintf(prt_str, "%s Workload %s\n",
			      BLTK_WL_GAME, BLTK_WL_GAME_VERSION);
		write_to_stdout_work_out_log(prt_str);
	} else if (office_workload_flg) {
		if (stat_memory_flg == 0) {
			stat_memory = 1;
		}
		if (work_output_flg == 0) {
			work_output_type = OUTPUT_FILE;
		}
		create_wl_version_file(BLTK_WL_OFFICE, BLTK_WL_OFFICE_VERSION);
		workload = "./wl_office/bin/bltk_wl_office";
		(void)sprintf(prt_str, "%s Workload %s\n",
			      BLTK_WL_OFFICE, BLTK_WL_OFFICE_VERSION);
		write_to_stdout_work_out_log(prt_str);
	} else if (user_workload_flg) {
		create_wl_version_file(BLTK_WL_USER, BLTK_WL_USER_VERSION);
		workload = user_workload_prog;
		if (init_user_workload_flg) {
			(void)sprintf(prt_str,
				      "%s Workload %s: init: %s, prog: %s\n",
				      BLTK_WL_USER, BLTK_WL_USER_VERSION,
				      init_user_workload_prog,
				      user_workload_prog);
		} else {
			(void)sprintf(prt_str,
				      "%s Workload %s: prog: %s\n",
				      BLTK_WL_USER, BLTK_WL_USER_VERSION,
				      user_workload_prog);
		}
		write_to_stdout_work_out_log(prt_str);
		if (init_user_workload_flg) {
			if (work_output_type == OUTPUT_FILE) {
				(void)sprintf(cmd, "%s >>%s 2>&1",
					      init_user_workload_prog,
					      work_out_log_fname);
			} else if (work_output_type == OUTPUT_CONSOLE_FILE) {
				(void)sprintf(cmd, "%s 2>&1 | tee -ai %s",
					      init_user_workload_prog,
					      work_out_log_fname);
			} else if (work_output_type == OUTPUT_NULL) {
				(void)sprintf(cmd, "%s >>%s 2>&1",
					      init_user_workload_prog,
					      "/dev/null");
			} else if (work_output_type == OUTPUT_CONSOLE) {
				(void)sprintf(cmd, "%s",
					      init_user_workload_prog);
			} else {
				(void)sprintf(prt_str,
					      "Output type is not valid, "
					      "type is %d, expected value "
					      "is from %d to %d\n",
					      work_output_type, OUTPUT_MIN,
					      OUTPUT_MAX);
				write_to_work_out_log(prt_str);
				prog_exit(1);
			}
			ret = prog_system(cmd);
			if (ret != 0 || access(fail_fname, F_OK) == 0) {
				(void)sprintf(prt_str, "%s failed\n", cmd);
				write_to_err_log(prt_str);
				prog_exit(1);
			}
		}
	} else if (discharging_workload_flg) {
		if (stat_memory_flg == 0) {
			stat_memory = 1;
		}
		if (work_output_flg == 0) {
			work_output_type = OUTPUT_CONSOLE_FILE;
		}
		create_wl_version_file(BLTK_WL_DISCHARGING,
				       BLTK_WL_DISCHARGING_VERSION);
		(void)sprintf(prt_str, "%s Workload %s:\n",
			      BLTK_WL_DISCHARGING, BLTK_WL_DISCHARGING_VERSION);
		write_to_stdout_work_out_log(prt_str);
	} else if (charging_workload_flg) {
		if (stat_memory_flg == 0) {
			stat_memory = 1;
		}
		if (work_output_flg == 0) {
			work_output_type = OUTPUT_CONSOLE_FILE;
		}
		create_wl_version_file(BLTK_WL_CHARGING,
				       BLTK_WL_CHARGING_VERSION);
		(void)sprintf(prt_str, "%s Workload %s:\n",
			      BLTK_WL_CHARGING, BLTK_WL_CHARGING_VERSION);
		write_to_stdout_work_out_log(prt_str);
	} else if (idle_test_mode) {
		work_log_ignore = 1;
		if (stat_memory_flg == 0) {
			stat_memory = 1;
		}
		if (work_output_flg == 0) {
			work_output_type = OUTPUT_CONSOLE_FILE;
		}
		idle_workload_flg = 1;
		create_wl_version_file(BLTK_WL_IDLE_TEST,
				       BLTK_WL_IDLE_TEST_VERSION);
		(void)sprintf(prt_str, "%s Workload %s\n",
			      BLTK_WL_IDLE_TEST, BLTK_WL_IDLE_TEST_VERSION);
		write_to_stdout_work_out_log(prt_str);
	} else {		/* Idle Test */
		work_log_ignore = 1;
		if (stat_memory_flg == 0) {
			stat_memory = 1;
		}
		if (work_output_flg == 0) {
			work_output_type = OUTPUT_CONSOLE_FILE;
		}
		idle_workload_flg = 1;
		create_wl_version_file(BLTK_WL_IDLE, BLTK_WL_IDLE_VERSION);
		(void)sprintf(prt_str, "%s Workload %s\n",
			      BLTK_WL_IDLE, BLTK_WL_IDLE_VERSION);
		write_to_stdout_work_out_log(prt_str);
	}

	if (ac_ignore == 1 || charging_workload_flg == 1) {
		check_bat_flg = 0;
	}

	debug("check_bat_flg %d", check_bat_flg);

	check_state();

	if (ac_adapter_state_flg == 0) {
		ac_err_workaround = 1;
	}

	if (bat_num <= 0 && !idle_test_mode) {
		stat_memory_flg = 1;
		stat_memory = 0;
	}

	stat_memory_saved = stat_memory;

	sync();

	create_comment_file();
	save_sys_info(0);

	if (!idle_test_mode) {
		start_warnings();
	}

	if (dpms_flg) {
		(void)prog_system("xset dpms 0 0 0 >/dev/null 2>&1");
		(void)prog_system("xset s off >/dev/null 2>&1");
	} else {
		(void)prog_system("xset -dpms >/dev/null 2>&1");
		(void)prog_system("xset s off >/dev/null 2>&1");
	}

	if (start_prog_flg) {
		if (start_prog_su_flg) {
			(void)sprintf(cmd, "%s '%s'", bltk_sudo, start_prog);
		} else {
			(void)sprintf(cmd, "%s", start_prog);
		}
		(void)sprintf(prt_str, "Start prog %s\n", cmd);
		write_to_stdout_work_out_log(prt_str);
		ret = prog_system(cmd);
		if (ret != 0 || access(fail_fname, F_OK) == 0) {
			(void)sprintf(prt_str, "%s failed\n", cmd);
			write_to_err_log(prt_str);
			prog_exit(1);
		}
	}

	prog_sleep(1);

	/*
	 * C states number depends on AC state (P35 for example) ->
	 * get new params
	 */
	get_info(1);

	form_log_head();

	if (idle_test_mode) {
		if (!yes) {
			write_to_stdout_work_out_log
			    ("Press enter to start the test");
			(void)getchar();
			write_to_stdout_work_out_log("\n");
		}
	}

	save_sys_info(1);
	init_completed = 1;

	(void)sprintf(prt_str, "Test started\n");
	write_to_stdout_work_out_log(prt_str);

	pid_work_log = getpid();
	prog_putenv_int("BLTK_WORK_LOG_PROC", pid_work_log);
	procname = "work.log";
	fd_proc_log = fd_work_log;
	work_log_proc_flg = 1;

	time_start = time_prev = prog_time();

	if (stat_log_ignore == 0) {
		if ((pid_stat_log = fork()) == 0) {
			parent_flg = 0;
			stat_log_proc_flg = 1;
			procname = "stat.log";
			fd_proc_log = fd_stat_log;
			stat_log();
			prog_exit(0);
		} else if (pid_stat_log < 0) {
			(void)sprintf(prt_str,
				      "fork() failed: errno %d (%s)\n",
				      errno, strerror(errno));
			write_to_err_log(prt_str);
			prog_exit(1);
		} else {
			prog_putenv_int("BLTK_STAT_LOG_PROC", pid_stat_log);
		}
	}

	proc_log_ignore = work_log_ignore;

	if (spy_log_enabled) {
		if ((pid_spy_log = fork()) == 0) {
			parent_flg = 0;
			procname = "spy.log";
			spy_log();
			prog_exit(0);
		} else if (pid_spy_log < 0) {
			(void)sprintf(prt_str,
				      "fork() failed: errno %d (%s)\n",
				      errno, strerror(errno));
			write_to_err_log(prt_str);
			prog_exit(1);
		} else {
			prog_putenv_int("BLTK_SPY_LOG_PROC", pid_spy_log);
		}
	}

	ret = 0;

	if (developer_workload_flg) {
		procname = "developer";
		ret = run_workload(workload);
	} else if (player_workload_flg) {
		procname = "player";
		ret = run_workload(workload);
	} else if (reader_workload_flg) {
		procname = "reader";
		ret = run_workload(workload);
	} else if (game_workload_flg) {
		procname = "game";
		ret = run_workload(workload);
	} else if (office_workload_flg) {
		procname = "office";
		ret = run_workload(workload);
	} else if (debug_workload_flg) {
		procname = "debugger";
		ret = debug_workload();
	} else if (user_workload_flg) {
		procname = "user";
		ret = run_workload(workload);
	} else if (discharging_workload_flg) {
		procname = "discharging";
		ret = discharging_workload();
	} else if (charging_workload_flg) {
		procname = "charging";
		ret = charging_workload();
	} else if (idle_workload_flg) {
		if (report_time == EMPTY_VALUE) {
			report_time = 1 * MSEC_IN_SEC;
		}
		procname = "idle";
		if (!idle_workload_flg) {
			while (1) {
				(void)prog_sleep(1024 * SEC_IN_HOUR);
			}
		} else {
			int ret = 0, status = 0;

			while (1) {
				errno = 0;
				ret = waitpid(pid_stat_log, &status, 0);
				if (ret == -1 && errno == EINTR) {
					continue;
				} else {
					break;
				}
			}
			idle_test_final();
		}
	} else {
		procname = "unknown";
		ret = EMPTY_VALUE;
	}
	prog_exit(ret);
}
