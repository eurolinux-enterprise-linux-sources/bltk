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

#include "bltk.h"

int hd_stat_rd_wr_ignore = 0;
int sys_info_2_done = 0;
int cpu_intr_num = 0;

int prev_sum_bat_percent = 0;
int sum_bat_percent;

xtime_t prev_sync_time = 0;
xtime_t sync_time = 0;

static int stsrt_capacity[MAX_BAT];
static int des_voltage[MAX_BAT];

void write_to_stdout_work_out_log(char *str)
{
	(void)fprintf(stdout, "%s", str);
	write_to_work_out_log_only(str);
}

void write_to_warning_log(char *str)
{
	int fd = -1;
	char err_str[STR_LEN];

	fd = open(warning_log_fname, O_WRONLY | O_CREAT | O_APPEND, 0666);
	if (fd < 0) {
		(void)sprintf(err_str, "open() of %s failed: "
			      "errno %d (%s)\n",
			      warning_log_fname, errno, strerror(errno));
		write_to_err_log(str);
		write_to_err_log(err_str);
		prog_exit(1);
	}
	(void)write(fd, str, strlen(str));
	(void)close(fd);
	prog_err_printf("%s", str);
}

void write_to_err_log(char *str)
{
	int fd = -1;
	char err_str[STR_LEN];

	fd = open(err_log_fname, O_WRONLY | O_CREAT | O_APPEND, 0666);
	if (fd < 0) {
		(void)sprintf(err_str, "open() of %s failed: "
			      "errno %d (%s)\n",
			      err_log_fname, errno, strerror(errno));
		prog_err_printf("%s", str);
		prog_err_printf("%s", err_str);
		prog_exit(1);
	}
	(void)write(fd, str, strlen(str));
	(void)close(fd);
	prog_err_printf("%s", str);
	create_fail_file();
}

void write_to_work_out_log(char *str)
{
	write_to_work_out_log_only(str);
	if (verbose) {
		prog_err_printf("%s", str);
	}
}

void write_to_work_out_log_only(char *str)
{
	int fd = -1;
	char err_str[STR_LEN];

	fd = open(work_out_log_fname, O_WRONLY | O_CREAT | O_APPEND, 0666);
	if (fd < 0) {
		(void)sprintf(err_str, "open() of %s failed: "
			      "errno %d (%s)\n",
			      work_out_log_fname, errno, strerror(errno));
		write_to_err_log(str);
		write_to_err_log(err_str);
		prog_exit(1);
	}
	(void)write(fd, str, strlen(str));
	(void)close(fd);
}

#define	DEL_FILE_BUF_SIZE	(128 * 1024)

static char *file_buf = NULL;
static int file_buf_size = 0;
static int file_buf_ind = 0;

static void write_to_file_buf(char *str)
{
	char *new_file_buf;
	int new_file_buf_size;
	int sstr;
	char err_str[STR_LEN];

	sstr = strlen(str);

	if (file_buf_ind + sstr >= file_buf_size || file_buf == NULL) {
		new_file_buf_size = file_buf_size + DEL_FILE_BUF_SIZE + sstr;
		new_file_buf = (char *)malloc(new_file_buf_size);
		if (new_file_buf == NULL) {
			(void)sprintf(err_str, "malloc(%d) failed\n",
				      new_file_buf_size);
			write_to_err_log(err_str);
			prog_exit(1);
		}
		(void)memset(new_file_buf, 0, new_file_buf_size);
		if (file_buf != NULL) {
			(void)memcpy(new_file_buf, file_buf, file_buf_ind);
			(void)free(file_buf);
		}
		file_buf = new_file_buf;
		file_buf_size = new_file_buf_size;
	}
	(void)memcpy(file_buf + file_buf_ind, str, sstr);
	file_buf_ind += sstr;
}

static int flg = 0;

static void write_file_buf_to_file(void)
{
	char *buf = 0;
	int ind = 0;

	flg++;

	buf = file_buf;
	file_buf = 0;
	ind = file_buf_ind;

	file_buf_size = 0;
	file_buf_ind = 0;

	if (buf != 0) {
		(void)write(fd_proc_log, buf, ind);
	}
}

void turn_off_stat_memory(void)
{
	if (stat_memory) {
		debug("turn_off_stat_memory");
		write_file_buf_to_file();
		stat_memory = 0;
	}
}

#define	LAPTOP_MODE	"laptop_mode"

static int laptop_mode_stop_done = 0;

void laptop_mode_stop(void)
{
	char cmd[STR_LEN];

	if (!stat_log_proc_flg || laptop_mode_stop_done) {
		return;
	}

	laptop_mode_stop_done = 1;
	debug("laptop_mode_stop()");
	(void)sprintf(cmd, "%s %s >/dev/null 2>&1", bltk_sudo, LAPTOP_MODE);
	(void)prog_system(cmd);
}

void stat_sync(char *why)
{
	debug("stat_sync() by %s", why);
	sync();
}

void write_base(char *str)
{
	if (stat_memory) {
		write_to_file_buf(str);
	} else {
		(void)write(fd_proc_log, str, strlen(str));
	}
	if (!bat_stat_ignore && !idle_test_mode) {
		check_critical_state();
	}
}

static int send_sighup_done = 0;

static void send_sighup(void)
{
	if (!stat_log_proc_flg || send_sighup_done || pid_work_log == -1) {
		return;
	}
	debug("send_sighup()");
	(void)kill(pid_work_log, SIGHUP);
	send_sighup_done = 1;
}

static void check_sync_time(void)
{
	if (!stat_log_proc_flg) {
		return;
	}
	if (sum_bat_percent != prev_sum_bat_percent) {
		stat_sync("critical bat percentage");
		prev_sum_bat_percent = sum_bat_percent;
		prev_sync_time = sync_time;
	} else if (sync_time - prev_sync_time > bat_sync_time) {
		stat_sync("critical time");
		prev_sum_bat_percent = sum_bat_percent;
		prev_sync_time = sync_time;
	}
}

static int first_check_critical_state = 1;
static int critical_alarm = 0;
static int critical_alarm_done = 0;

void check_critical_state(void)
{
	int i;
	char err_str[STR_LEN];

	sync_time = prog_time();

	sum_bat_percent = 0;
	for (i = 1; i <= bat_num; i++) {
		sum_bat_percent += bat_percent[i];
	}

	if (first_check_critical_state) {
		first_check_critical_state = 0;
		prev_sync_time = sync_time;
		prev_sum_bat_percent = sum_bat_percent;
		return;
	}

	if (check_bat_flg && (sum_bat_percent == prev_sum_bat_percent)
	    && !critical_alarm) {
		if (sync_time - prev_sync_time >
		    bat_sync_time_alarm * MSEC_IN_SEC) {
			(void)sprintf(err_str,
				      "Battery capacity is not changed during %d sec\n",
				      bat_sync_time_alarm);
			write_to_work_out_log_only(err_str);
			critical_alarm = 1;
		}
	}
	if (check_bat_flg && (sum_bat_percent > prev_sum_bat_percent)
	    && !critical_alarm) {
		(void)sprintf(err_str,
			      "Battery capacity is increased from %d to %d\n",
			      prev_sum_bat_percent, sum_bat_percent);
		write_to_work_out_log_only(err_str);
		critical_alarm = 1;
	}

	if ((sum_bat_percent < bat_sync && bat_num > 0)
	    || abort_flg || critical_alarm) {
		if (!critical_alarm_done) {
			turn_off_stat_memory();
			if (stat_log_proc_flg) {
				if (stat_memory_saved) {
					send_sighup();
				}
				laptop_mode_stop();
				if (!idle_test_mode) {
					save_sys_info_2();
				}
			}
			critical_alarm_done = 1;
		}
		if (stat_log_proc_flg) {
			check_sync_time();
		}
	}
}

void write_to_proc_log(char *str)
{
	if (proc_log_ignore == 0) {
		(void)write_base(str);
	}

	if (verbose) {
		prog_err_printf("%s", str);
	}
}

void write_to_stat_log(char *str)
{
	if (stat_log_ignore != 0) {
		(void)write(fd_stat_log, str, strlen(str));
	}
	if (verbose) {
		prog_err_printf("%s", str);
	}
}

void write_to_work_log(char *str)
{
	if (work_log_ignore == 0) {
		(void)write(fd_work_log, str, strlen(str));
	}
	if (verbose) {
		prog_err_printf("%s", str);
	}
}

ll_t calc_percentage(ll_t val_100, ll_t val)
{
	double res;
	ll_t val_pp;

	if (val_100 == 0) {
		res = 0;
	} else {
		res = (val * 100.0 / val_100) * 100;
	}
	val_pp = res;

	return (val_pp);
}

void sprt_percentage(ll_t val_pp, char *str)
{
	ll_t val_int, val_rem;
	int neg;

	str[0] = 0;

	if (val_pp < 0) {
		neg = 1;
		val_pp = -val_pp;
	} else {
		neg = 0;
	}

	val_int = val_pp / 100;
	val_rem = val_pp % 100;

	if (neg && (val_int != 0 || val_rem != 0)) {
		if (val_int != 0) {
			val_int = -val_int;
			(void)sprintf(str, "%4lld.%02lld", val_int, val_rem);
		} else {
			(void)sprintf(str, "  -0.%02lld", val_rem);
		}
	} else {
		(void)sprintf(str, "%4lld.%02lld", val_int, val_rem);
	}
	return;
}

double get_percentage(ll_t val_100, ll_t val, char *str)
{
	ll_t val_pp;
	double ret;

	val_pp = calc_percentage(val_100, val);
	if (str != NULL) {
		sprt_percentage(val_pp, str);
	}
	ret = val_pp / 100.0;

	return (ret);
}

double
get_percentage_delta(ll_t val_100, ll_t val_prev, ll_t val_curr, char *str)
{
	ll_t val_prev_pp, val_curr_pp, delta;
	double ret;

	val_prev_pp = calc_percentage(val_100, val_prev);
	val_curr_pp = calc_percentage(val_100, val_curr);
	delta = val_curr_pp - val_prev_pp;
	sprt_percentage(delta, str);
	ret = delta / 100.0;

	return (ret);
}

void hd_state(char *str)
{
	char cmd[STR_LEN];
	int ret;

	if (hd_stat_ignore) {
		(void)sprintf(str, "  -");
		return;
	}

	(void)sprintf(cmd, "./bin/bltk_hd_state %s >>%s 2>&1",
		      hd_dev_name, "/dev/null");

	ret = prog_system(cmd);
	ret = WEXITSTATUS(ret);
	if (ret == 100) {
		(void)sprintf(str, "err");
	} else if (ret == 101) {
		(void)sprintf(str, "a/i");
	} else if (ret == 102) {
		(void)sprintf(str, " st");
	} else if (ret == 103) {
		(void)sprintf(str, " sl");
	} else {
		(void)sprintf(str, "err");
	}
}

static int get_display_state(void)
{
	char cmd[STR_LEN];
	int ret;

	(void)sprintf(cmd, "./bin/bltk_display_state >>%s 2>&1", "/dev/null");

	ret = prog_system(cmd);
	ret = WEXITSTATUS(ret);
	return (ret);
}

static int get_user_field(int field_no, char *field)
{
	int ret;
	int err = 0;
	int fd = EMPTY_VALUE;
	ssize_t r_ret;
	char buf[BUFF_LEN];
	char cmd[STR_LEN];
	char file[STR_LEN];
	char str[STR_LEN];

	(void)strcpy(field, "-");
	(void)sprintf(file, "user_field.%d", field_no);
	(void)unlink(file);
	(void)sprintf(cmd, "%s > %s 2>&1", user_field_cmd[field_no], file);

	ret = prog_system(cmd);
	err = WEXITSTATUS(ret);
	if (ret) {
		(void)sprintf(str, "File %s, Line %d: "
			      "prog_system(%s) failed with %d\n",
			      __FILE__, __LINE__, cmd, err);
		(void)write_to_stdout_work_out_log(str);
		goto end;
	}
	fd = open(file, O_RDONLY);
	if (fd < 0) {
		err = errno;
		(void)sprintf(str, "File %s, Line %d: "
			      "open(%s, O_RDONLY) failed, errno %d(%s)\n",
			      __FILE__, __LINE__, file, err, strerror(err));
		(void)write_to_stdout_work_out_log(str);
		ret = 1;
		goto end;
	}
	(void)memset(buf, 0, BUFF_LEN);
	r_ret = read(fd, buf, BUFF_LEN);
	if (r_ret <= 0) {
		err = errno;
		(void)sprintf(str, "File %s, Line %d: "
			      "read(%s) failed with %d (%s)\n",
			      __FILE__, __LINE__, file, err, strerror(err));
		(void)write_to_stdout_work_out_log(str);
		ret = 1;
		goto end;
	}
	(void)strncpy(field, buf, (strlen(buf) - 1));
      end:
	if (fd != EMPTY_VALUE)
		(void)close(fd);
	(void)unlink(file);
	return (ret);
}

static char *str_charge_state(int state)
{
	char *ret;

	switch (state) {
	case CHARGED:
		ret = "ok";
		break;
	case CHARGING:
		ret = "+";
		break;
	case DISCHARGING:
		ret = "-";
		break;
	case CHARGING_DISCHARGING:
		ret = "+-";
		break;
	default:
		ret = "?";
		break;
	}
	return (ret);
}

static char *str_cap_state(int state)
{
	char *ret;

	switch (state) {
	case CAP_OK:
		ret = "ok";
		break;
	case CAP_CRITICAL:
		ret = "!";
		break;
	default:
		ret = "?";
		break;
	}
	return (ret);
}

static cpu_load_t s_cpu_load_state[MAX_CPU];
static cpu_load_t p_cpu_load_state[MAX_CPU];
static cpu_load_t c_cpu_load_state[MAX_CPU];

static cpu_freq_t s_cpu_freq_state[MAX_CPU];
static cpu_freq_t p_cpu_freq_state[MAX_CPU];
static cpu_freq_t c_cpu_freq_state[MAX_CPU];

static cpu_cstate_state_t s_cpu_cstate_state[MAX_CPU];
static cpu_cstate_state_t p_cpu_cstate_state[MAX_CPU];
static cpu_cstate_state_t c_cpu_cstate_state[MAX_CPU];

static bat_state_t s_bat_state[MAX_BAT];
static bat_state_t p_bat_state[MAX_BAT];
static bat_state_t c_bat_state[MAX_BAT];

static hd_stat_t p_hd_stat;
static hd_stat_t c_hd_stat;

static mem_stat_t s_mem_stat;
static mem_stat_t c_mem_stat;

static cpu_intr_t p_cpu_intr;
static cpu_intr_t c_cpu_intr;

void bat_state(void)
{
	int i, no;
	int des_cap, last_full_cap, cur_cap, is_mah, des_vol, bat_state;
	char *bat_state_str;
	char *unit;
	double p2;
	double p3;
	char err_str[STR_LEN];

	for (i = 1; i <= bat_num; i++) {
		get_bat_state(i, &c_bat_state[i]);
		get_bat_info(i, &c_bat_state[i]);
		get_bat_charge(i, &c_bat_state[i]);
		is_mah = bat_path[i]->is_mah;
		des_cap = bat_path[i]->des_cap;
		des_vol = bat_path[i]->des_vol;
		last_full_cap = c_bat_state[i].last_full_cap;
		cur_cap = c_bat_state[i].cur_cap;
		stsrt_capacity[i] = cur_cap;
		des_voltage[i] = des_vol;
		if (is_mah) {
			des_cap = des_cap * des_vol / 1000;
			last_full_cap = last_full_cap * des_vol / 1000;
			cur_cap = cur_cap * des_vol / 1000;
			unit = "mWh";
		} else {
			unit = "mWh";
		}
		bat_state = get_bat_charge_state(i);
		if (bat_state == CHARGED) {
			bat_state_str = "charged";
		} else if (bat_state == CHARGING) {
			bat_state_str = "charging";
		} else if (bat_state == DISCHARGING) {
			bat_state_str = "discharging";
		} else if (bat_state == CHARGING_DISCHARGING) {
			bat_state_str = "charging/discharging";
		} else {
			bat_state_str = "unknown";
		}
		if ((des_cap != last_full_cap) || (last_full_cap != cur_cap)) {
			no = bat_path[i]->no;
			if (no < 0) {
				no = 0;
			}
			p2 = get_percentage(des_cap, last_full_cap, NULL);
			p3 = get_percentage(des_cap, cur_cap, NULL);
			(void)sprintf(err_str,
				      "Warning: BAT%d capacity: "
				      "design %d %s (100%%), "
				      "last full %d %s (%.2f%%), "
				      "remaining %d %s (%.2f%%), %s.\a\n",
				      no,
				      des_cap,
				      unit,
				      last_full_cap,
				      unit, p2,
				      cur_cap, unit, p3, bat_state_str);
			write_to_warning_log(err_str);
		}
	}
}

void check_state(void)
{
	bat_state();
}

void write_report_str(char *work_type, char *comment)
{
	static int first = 1, report_no = -1;
	static char sprt[STR_LEN];
	static char strtime[SMALL_STR_LEN];
	static char strdtime[SMALL_STR_LEN];

	static char scpu[MAX_CPU][SMALL_STR_LEN];
	static char scpusys[MAX_CPU][SMALL_STR_LEN];
	static char scpuusr[MAX_CPU][SMALL_STR_LEN];
	static char scpuiow[MAX_CPU][SMALL_STR_LEN];
	static char scpuidl[MAX_CPU][SMALL_STR_LEN];
	static char scurcpu[MAX_CPU][SMALL_STR_LEN];
	static char scurcpusys[MAX_CPU][SMALL_STR_LEN];
	static char scurcpuusr[MAX_CPU][SMALL_STR_LEN];
	static char scurcpuiow[MAX_CPU][SMALL_STR_LEN];
	static char scurcpuidl[MAX_CPU][SMALL_STR_LEN];
	static char sfreq[MAX_CPU][SMALL_STR_LEN];

	static char *sac;

	static char shd[SMALL_STR_LEN];
	static char shdrd[SMALL_STR_LEN];
	static char shdwr[SMALL_STR_LEN];

	static char sswap[SMALL_STR_LEN];
	static char smem[SMALL_STR_LEN];

	static char sbat[MAX_BAT][SMALL_STR_LEN];
	static char sdelbat[MAX_BAT][SMALL_STR_LEN];
	static char scapbat[MAX_BAT][SMALL_STR_LEN];
	static char svolbat[MAX_BAT][SMALL_STR_LEN];
	static char sratebat[MAX_BAT][SMALL_STR_LEN];
	static char schargestatebat[MAX_BAT][SMALL_STR_LEN];
	static char scapstatebat[MAX_BAT][SMALL_STR_LEN];

	static char sdpms[SMALL_STR_LEN];
	static char smonitor[SMALL_STR_LEN];
	static char strrtime[SMALL_STR_LEN];

	static char scpubmstr[MAX_CPU][SMALL_STR_LEN];
	static char scputstate[MAX_CPU][SMALL_STR_LEN];
	static char scpucstate[MAX_CPU][SMALL_STR_LEN];
	static char scpuctstate[MAX_CPU][SMALL_STR_LEN];
	static char scpupstate[MAX_CPU][SMALL_STR_LEN];
	static char scputimer[MAX_CPU][SMALL_STR_LEN];
	static char scpuintr[MAX_CPU][SMALL_STR_LEN];
	static char s[SMALL_STR_LEN];
	static int dpms_on_cnt = 0, monitor_on_cnt = 0;
	static char *head;
	static char **user_field_value;

	int ret, i, c;
	int cur_cap, cur_vol, cur_rate;
	ll_t sys;
	ll_t usr;
	ll_t iow;
	ll_t idl;
	ll_t com;
	ll_t delta;
	double bat_dp[MAX_BAT];
	int bat_dv[MAX_BAT];
	double vtime;
	xtime_t t_cur, t, t_hh, t_mm, t_ss, t_uu, rtime;
	int dpms_on, monitor_on;

	if (first) {
		for (i = 0; i < MAX_CPU; i++) {
			(void)memset(&s_cpu_load_state[i], 'f',
				     sizeof(cpu_load_t));
			(void)memset(&p_cpu_load_state[i], 'f',
				     sizeof(cpu_load_t));
			(void)memset(&c_cpu_load_state[i], 'f',
				     sizeof(cpu_load_t));
		}
		for (i = 0; i < MAX_CPU; i++) {
			(void)memset(&s_cpu_freq_state[i], 'f',
				     sizeof(cpu_freq_t));
			(void)memset(&p_cpu_freq_state[i], 'f',
				     sizeof(cpu_freq_t));
			(void)memset(&c_cpu_freq_state[i], 'f',
				     sizeof(cpu_freq_t));
		}
		for (i = 0; i < MAX_CPU; i++) {
			(void)memset(&s_cpu_cstate_state[i], 'f',
				     sizeof(cpu_cstate_state_t));
			(void)memset(&p_cpu_cstate_state[i], 'f',
				     sizeof(cpu_cstate_state_t));
			(void)memset(&c_cpu_cstate_state[i], 'f',
				     sizeof(cpu_cstate_state_t));
		}
		for (i = 0; i < MAX_BAT; i++) {
			(void)memset(&s_bat_state[i], 'f', sizeof(bat_state_t));
			(void)memset(&p_bat_state[i], 'f', sizeof(bat_state_t));
			(void)memset(&c_bat_state[i], 'f', sizeof(bat_state_t));
		}
		(void)memset(&p_hd_stat, 'f', sizeof(hd_stat_t));
		(void)memset(&c_hd_stat, 'f', sizeof(hd_stat_t));

		(void)memset(&p_cpu_intr, 'f', sizeof(cpu_intr_t));
		(void)memset(&c_cpu_intr, 'f', sizeof(cpu_intr_t));
		if (user_field_cnt) {
			user_field_value =
			    (char **)malloc(sizeof(char *) * user_field_cnt);
			for (i = 0; i < user_field_cnt; i++) {
				user_field_value[i] = (char *)malloc(STR_LEN);
				if (!user_field_value[i]) {
					user_field_cnt = i;
					break;
				}
			}
		}
	}

	report_no += 1;

	head = work_type;

	t_cur = prog_time();

	if (cpu_stat_ignore == 0) {
		for (i = 1; i <= cpu_num; i++) {
			get_cpu_load(i, &c_cpu_load_state[i]);
		}
		for (i = 1; i <= cpu_freq_num; i++) {
			get_cur_freq(i, &c_cpu_freq_state[i]);
		}
	}

	if (cpu_add_stat_ignore == 0) {
		for (i = 1; i <= cpu_cstate_num; i++) {
			get_cpu_cstate_states(i, &c_cpu_cstate_state[i]);
		}
	}
	if (cpu_add_stat_ignore == 0) {
		get_cpu_intr(&c_cpu_intr);
	}

	if (first) {
		for (i = 1; i <= bat_num; i++) {
			get_bat_state(i, &c_bat_state[i]);
			get_bat_info(i, &c_bat_state[i]);
			c_bat_state[i].cur_cap = stsrt_capacity[i];
		}
	}

	for (i = 1; i <= bat_num; i++) {
		get_bat_charge(i, &c_bat_state[i]);
		if (first) {
			c_bat_state[i].cur_cap = stsrt_capacity[i];
		}
	}

	/* time */
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
		(void)sprintf(strtime, "%5d  %02lli:%02lli:%02lli",
			      report_no, t_hh, t_mm, t_ss);
	} else {
		(void)sprintf(strtime, "%5d  %02lli:%02lli:%02lli.%03lli",
			      report_no, t_hh, t_mm, t_ss, t_uu);
	}

	t = (t_cur - time_prev);
	time_prev = t_cur;
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
		(void)sprintf(strdtime, "%02lli:%02lli:%02lli",
			      t_hh, t_mm, t_ss);
	} else {
		(void)sprintf(strdtime, "%02lli:%02lli:%02lli.%03lli",
			      t_hh, t_mm, t_ss, t_uu);
	}

	/* cpu */
	if (first && cpu_stat_ignore == 0) {
		for (i = 1; i <= cpu_num; i++) {
			s_cpu_load_state[i].cpu_sys =
			    p_cpu_load_state[i].cpu_sys =
			    c_cpu_load_state[i].cpu_sys;
			s_cpu_load_state[i].cpu_usr =
			    p_cpu_load_state[i].cpu_usr =
			    c_cpu_load_state[i].cpu_usr;
			s_cpu_load_state[i].cpu_iow =
			    p_cpu_load_state[i].cpu_iow =
			    c_cpu_load_state[i].cpu_iow;
			s_cpu_load_state[i].cpu_idl =
			    p_cpu_load_state[i].cpu_idl =
			    c_cpu_load_state[i].cpu_idl;
		}
	}
	if (first && cpu_stat_ignore == 0) {
		for (i = 1; i <= cpu_freq_num; i++) {
			for (c = 0; c < c_cpu_freq_state[i].freq_num; c++) {
				s_cpu_freq_state[i].freq_value_array[c] =
				    p_cpu_freq_state[i].freq_value_array[c] =
				    c_cpu_freq_state[i].freq_value_array[c];
				s_cpu_freq_state[i].freq_time_array[c] =
				    p_cpu_freq_state[i].freq_time_array[c] =
				    c_cpu_freq_state[i].freq_time_array[c];
			}
		}
	}

	if (first && cpu_add_stat_ignore == 0) {
		for (i = 1; i <= cpu_intr_num; i++) {
			p_cpu_intr.timer[i] = c_cpu_intr.timer[i];
			p_cpu_intr.others[i] = c_cpu_intr.others[i];
		}
	}

	if (first && cpu_add_stat_ignore == 0) {
		for (i = 1; i <= cpu_cstate_num; i++) {
			for (c = 0; c < c_cpu_cstate_state[i].num_cstate_states;
			     c++) {
				if (c_cpu_cstate_state[i].c_present[c] == 0) {
					continue;
				}
				s_cpu_cstate_state[i].c_usage[c] =
				    p_cpu_cstate_state[i].c_usage[c] =
				    c_cpu_cstate_state[i].c_usage[c];
				s_cpu_cstate_state[i].c_duration[c] =
				    p_cpu_cstate_state[i].c_duration[c] =
				    c_cpu_cstate_state[i].c_duration[c];
			}
		}
	}

	if (cpu_stat_ignore == 0) {
		for (i = 1; i <= cpu_num; i++) {
			sys = c_cpu_load_state[i].cpu_sys -
			    s_cpu_load_state[i].cpu_sys;
			usr = c_cpu_load_state[i].cpu_usr -
			    s_cpu_load_state[i].cpu_usr;
			iow = c_cpu_load_state[i].cpu_iow -
			    s_cpu_load_state[i].cpu_iow;
			idl = c_cpu_load_state[i].cpu_idl -
			    s_cpu_load_state[i].cpu_idl;

			com = sys + usr + iow + idl;
			get_percentage(com, sys + usr, scpu[i]);
			get_percentage(com, sys, scpusys[i]);
			get_percentage(com, usr, scpuusr[i]);
			get_percentage(com, iow, scpuiow[i]);
			get_percentage(com, idl, scpuidl[i]);

			sys = c_cpu_load_state[i].cpu_sys -
			    p_cpu_load_state[i].cpu_sys;
			usr = c_cpu_load_state[i].cpu_usr -
			    p_cpu_load_state[i].cpu_usr;
			iow = c_cpu_load_state[i].cpu_iow -
			    p_cpu_load_state[i].cpu_iow;
			idl = c_cpu_load_state[i].cpu_idl -
			    p_cpu_load_state[i].cpu_idl;

			com = sys + usr + iow + idl;
			get_percentage(com, sys + usr, scurcpu[i]);
			get_percentage(com, sys, scurcpusys[i]);
			get_percentage(com, usr, scurcpuusr[i]);
			get_percentage(com, iow, scurcpuiow[i]);
			get_percentage(com, idl, scurcpuidl[i]);

			p_cpu_load_state[i].cpu_sys =
			    c_cpu_load_state[i].cpu_sys;
			p_cpu_load_state[i].cpu_usr =
			    c_cpu_load_state[i].cpu_usr;
			p_cpu_load_state[i].cpu_iow =
			    c_cpu_load_state[i].cpu_iow;
			p_cpu_load_state[i].cpu_idl =
			    c_cpu_load_state[i].cpu_idl;
		}
	}
	if (cpu_stat_ignore == 0) {
		for (i = 1; i <= cpu_freq_num; i++) {
			if (first) {
				c_cpu_freq_state[i].cur_freq = 0;
			} else if (c_cpu_freq_state[i].freq_num > 0) {
				c_cpu_freq_state[i].cur_freq =
				    get_average_time_in_state(c_cpu_freq_state
							      [i].freq_num,
							      c_cpu_freq_state
							      [i].
							      freq_value_array,
							      p_cpu_freq_state
							      [i].
							      freq_time_array,
							      c_cpu_freq_state
							      [i].
							      freq_time_array);
			}
			(void)sprintf(sfreq[i], "%7d",
				      c_cpu_freq_state[i].cur_freq);
		}
	}

	/* bat */
	if (first) {
		for (i = 1; i <= bat_num; i++) {
			s_bat_state[i].cur_cap =
			    p_bat_state[i].cur_cap = c_bat_state[i].cur_cap;
			s_bat_state[i].last_full_cap =
			    p_bat_state[i].last_full_cap =
			    c_bat_state[i].last_full_cap;
		}
	}

	if (ac_stat_ignore) {
		sac = "  -";
	} else if (ac_err_workaround) {
		sac = "err";
	} else {
		ret = get_ac_state();
		if (ret == ON_STATE) {
			sac = " on";
		} else {
			sac = "off";
		}
	}

	for (i = 1; i <= bat_num; i++) {
		bat_value[i] = c_bat_state[i].cur_cap;
		bat_percent[i] = get_percentage(bat_path[i]->des_cap,
						c_bat_state[i].cur_cap,
						sbat[i]);

		bat_dv[i] = c_bat_state[i].cur_cap - p_bat_state[i].cur_cap;
		bat_dp[i] = get_percentage_delta(bat_path[i]->des_cap,
						 p_bat_state[i].cur_cap,
						 c_bat_state[i].cur_cap,
						 sdelbat[i]);
		if (bat_path[i]->is_mah) {
			cur_cap = c_bat_state[i].cur_cap *
			    des_voltage[i] / 1000;
		} else {
			cur_cap = c_bat_state[i].cur_cap;
		}
		(void)sprintf(scapbat[i], "%8d", cur_cap);
		p_bat_state[i].cur_cap = c_bat_state[i].cur_cap;
		c_bat_state[i].cur_cap = 0;

		cur_vol = c_bat_state[i].cur_vol;
		(void)sprintf(svolbat[i], "%6d", cur_vol);
		p_bat_state[i].cur_vol = c_bat_state[i].cur_vol;
		c_bat_state[i].cur_vol = 0;

		if (bat_path[i]->is_mah) {
			cur_rate = c_bat_state[i].cur_rate *
			    des_voltage[i] / 1000;
		} else {
			cur_rate = c_bat_state[i].cur_rate;
		}
		(void)sprintf(sratebat[i], "%6d", cur_rate);
		p_bat_state[i].cur_rate = c_bat_state[i].cur_rate;
		c_bat_state[i].cur_rate = 0;

		(void)sprintf(schargestatebat[i], "%6s",
			      str_charge_state(c_bat_state[i].charge_state));
		p_bat_state[i].charge_state = c_bat_state[i].charge_state;
		c_bat_state[i].charge_state = 0;

		(void)sprintf(scapstatebat[i], "%5s",
			      str_cap_state(c_bat_state[i].cap_state));
		p_bat_state[i].cap_state = c_bat_state[i].cap_state;
		c_bat_state[i].cap_state = 0;
	}

	if (disp_stat_ignore) {
		(void)sprintf(sdpms, "   -");
		(void)sprintf(smonitor, "   -");
	} else {
		ret = get_display_state();
		if (ret >= 100) {
			dpms_on = 1;
			(void)sprintf(sdpms, "  on");
		} else {
			dpms_on = 0;
			(void)sprintf(sdpms, " off");
		}
		dpms_on_cnt += dpms_on;
		ret %= 100;
		if (ret == 0 || ret == 1) {
			monitor_on = 1;
			(void)sprintf(smonitor, "  on");
		} else if (ret == 2) {
			monitor_on = 0;
			(void)sprintf(smonitor, " off");
		} else if (ret == 3) {
			monitor_on = 0;
			(void)sprintf(smonitor, "  st");
		} else if (ret == 4) {
			monitor_on = 0;
			(void)sprintf(smonitor, " sus");
		} else {
			monitor_on = 0;
			(void)sprintf(smonitor, " err");
		}
		monitor_on_cnt += monitor_on;
	}

	t = t_cur - time_start;

	(void)sprintf(strrtime, "       -");

	rtime = 0;

	if (no_time_stat_ignore == 0) {
		for (i = 1; i <= bat_num; i++) {
			cur_cap = c_bat_state[i].cur_cap;
			if (t != 0 && bat_dp[i] != 0) {
				vtime = (double)(s_bat_state[i].cur_cap -
						 cur_cap) / t;
				if (vtime < 0) {
					vtime = -vtime;
				}
				if (vtime != 0) {
					if (charging_workload_flg) {
						rtime += (double)
						    (s_bat_state[i].
						     last_full_cap -
						     cur_cap) / vtime;
					} else {
						rtime +=
						    (double)(cur_cap) / vtime;
					}
				}
			}
		}
		if (rtime != 0) {
			t = rtime;
			t_hh = t / SEC_IN_HOUR;
			t = t % SEC_IN_HOUR;
			t_mm = t / SEC_IN_MIN;
			t_ss = t % SEC_IN_MIN;

			(void)sprintf(strrtime, "%02lli:%02lli:%02lli",
				      t_hh, t_mm, t_ss);
		}
	}

	if (hd_stat_ignore == 0) {
		int del_rd = 0, del_wr = 0;

		hd_state(shd);

		if (hd_stat_rd_wr_ignore == 0) {
			get_hd_stat(1, &c_hd_stat);
			if (!first) {
				del_rd = c_hd_stat.rd_num - p_hd_stat.rd_num;
				del_wr = c_hd_stat.wr_num - p_hd_stat.wr_num;
			}
			(void)sprintf(shdrd, "%8i", del_rd);
			(void)sprintf(shdwr, "%8i", del_wr);
			p_hd_stat.rd_num = c_hd_stat.rd_num;
			p_hd_stat.wr_num = c_hd_stat.wr_num;
		}
	}

	if (mem_stat_ignore == 0) {
		get_mem_stat(&c_mem_stat);
		(void)sprintf(smem, "%8i", c_mem_stat.mem_used);
		(void)sprintf(sswap, "%8i", c_mem_stat.swap_used);
	}

	if (cpu_add_stat_ignore == 0) {
		for (i = 1; i <= cpu_cstate_num; i++) {
			(void)sprintf(scpubmstr[i], "%10s ",
				      c_cpu_cstate_state[i].bus_master_string);
			(void)sprintf(scputstate[i], "%2i ",
				      c_cpu_cstate_state[i].t_state);
			scpucstate[i][0] = 0;
			for (c = 0; c <
			     c_cpu_cstate_state[i].num_cstate_states; c++) {
				if (c_cpu_cstate_state[i].c_present[c]
				    == 0) {
					continue;
				}
				delta = c_cpu_cstate_state[i].c_usage[c] -
				    p_cpu_cstate_state[i].c_usage[c];
				(void)sprintf(s, "%8lli", delta);
				(void)strcat(scpucstate[i], s);
				(void)strcat(scpucstate[i], " ");
				p_cpu_cstate_state[i].c_usage[c] =
				    c_cpu_cstate_state[i].c_usage[c];
			}
			scpuctstate[i][0] = 0;
			for (c = 0; c <
			     c_cpu_cstate_state[i].num_cstate_states; c++) {
				if (c_cpu_cstate_state[i].cd_present[c]
				    == 0) {
					continue;
				}
				delta = c_cpu_cstate_state[i].c_duration[c] -
				    p_cpu_cstate_state[i].c_duration[c];
				(void)sprintf(s, "%10lli", delta);
				(void)strcat(scpuctstate[i], s);
				(void)strcat(scpuctstate[i], " ");
				p_cpu_cstate_state[i].c_duration[c] =
				    c_cpu_cstate_state[i].c_duration[c];
			}
		}
	}

	if (cpu_add_stat_ignore == 0) {
		for (i = 1; i <= cpu_freq_num; i++) {
			scpupstate[i][0] = 0;
			for (c = 0; c < c_cpu_freq_state[i].freq_num; c++) {
				delta = c_cpu_freq_state[i].freq_time_array[c] -
				    p_cpu_freq_state[i].freq_time_array[c];
				(void)sprintf(s, "%8lli", delta);
				(void)strcat(scpupstate[i], s);
				(void)strcat(scpupstate[i], " ");
			}
		}
	}
	if (cpu_stat_ignore == 0 || cpu_add_stat_ignore == 0) {
		for (i = 1; i <= cpu_freq_num; i++) {
			for (c = 0; c < c_cpu_freq_state[i].freq_num; c++) {
				p_cpu_freq_state[i].freq_time_array[c] =
				    c_cpu_freq_state[i].freq_time_array[c];
			}
		}
	}

	if (cpu_add_stat_ignore == 0) {
		for (i = 1; i <= cpu_intr_num; i++) {
			delta = c_cpu_intr.timer[i] - p_cpu_intr.timer[i];
			(void)sprintf(scputimer[i], "%8llu", delta);
			(void)strcat(scputimer[i], " ");
			p_cpu_intr.timer[i] = c_cpu_intr.timer[i];
			delta = c_cpu_intr.others[i] - p_cpu_intr.others[i];
			(void)sprintf(scpuintr[i], "%8llu", delta);
			(void)strcat(scpuintr[i], " ");
			p_cpu_intr.others[i] = c_cpu_intr.others[i];
		}
	}

	sprt[0] = 0;

	if (no_time_stat_ignore == 0) {
		(void)strcat(sprt, head);
		(void)strcat(sprt, " ");
		(void)strcat(sprt, strtime);
		(void)strcat(sprt, " ");
		(void)strcat(sprt, strdtime);
		(void)strcat(sprt, " ");
		(void)strcat(sprt, strrtime);
		(void)strcat(sprt, " ");
	} else if (no_time_stat_ignore == 1) {
		(void)strcat(sprt, head);
		(void)strcat(sprt, " ");
		(void)strcat(sprt, strtime);
		(void)strcat(sprt, " ");
		(void)strcat(sprt, strdtime);
		(void)strcat(sprt, " ");
	}

	if (bat_stat_ignore == 0) {
		for (i = 1; i <= bat_num; i++) {
			(void)strcat(sprt, sbat[i]);
			(void)strcat(sprt, " ");
			(void)strcat(sprt, sdelbat[i]);
			(void)strcat(sprt, " ");
			(void)strcat(sprt, scapbat[i]);
			(void)strcat(sprt, " ");
			(void)strcat(sprt, svolbat[i]);
			(void)strcat(sprt, " ");
			(void)strcat(sprt, sratebat[i]);
			(void)strcat(sprt, " ");
			(void)strcat(sprt, schargestatebat[i]);
			(void)strcat(sprt, " ");
			(void)strcat(sprt, scapstatebat[i]);
			(void)strcat(sprt, " ");
		}
	}

	if (cpu_stat_ignore == 0) {
		for (i = 1; i <= cpu_num; i++) {
			(void)strcat(sprt, scpu[i]);
			(void)strcat(sprt, " ");
			if (cpu_add_stat_ignore == 0) {
				(void)strcat(sprt, scpusys[i]);
				(void)strcat(sprt, " ");
				(void)strcat(sprt, scpuusr[i]);
				(void)strcat(sprt, " ");
				(void)strcat(sprt, scpuiow[i]);
				(void)strcat(sprt, " ");
				(void)strcat(sprt, scpuidl[i]);
				(void)strcat(sprt, " ");
			}
			(void)strcat(sprt, scurcpu[i]);
			(void)strcat(sprt, " ");
			if (cpu_add_stat_ignore == 0) {
				(void)strcat(sprt, scurcpusys[i]);
				(void)strcat(sprt, " ");
				(void)strcat(sprt, scurcpuusr[i]);
				(void)strcat(sprt, " ");
				(void)strcat(sprt, scurcpuiow[i]);
				(void)strcat(sprt, " ");
				(void)strcat(sprt, scurcpuidl[i]);
				(void)strcat(sprt, " ");
			}
		}
		for (i = 1; i <= cpu_freq_num; i++) {
			(void)strcat(sprt, sfreq[i]);
			(void)strcat(sprt, " ");
		}
	}

	if (disp_stat_ignore == 0) {
		(void)strcat(sprt, sdpms);
		(void)strcat(sprt, " ");
		(void)strcat(sprt, smonitor);
		(void)strcat(sprt, " ");
	}

	if (ac_stat_ignore == 0) {
		(void)strcat(sprt, sac);
		(void)strcat(sprt, " ");
	}

	if (hd_stat_ignore == 0) {
		(void)strcat(sprt, shd);
		(void)strcat(sprt, " ");
		if (hd_stat_rd_wr_ignore == 0) {
			(void)strcat(sprt, shdrd);
			(void)strcat(sprt, " ");
			(void)strcat(sprt, shdwr);
			(void)strcat(sprt, " ");
		}
	}

	if (mem_stat_ignore == 0) {
		(void)strcat(sprt, smem);
		(void)strcat(sprt, " ");
		(void)strcat(sprt, sswap);
		(void)strcat(sprt, " ");
	}

	if (cpu_add_stat_ignore == 0) {
		for (i = 1; i <= cpu_cstate_num; i++) {
			(void)strcat(sprt, scpucstate[i]);
			(void)strcat(sprt, scpuctstate[i]);
			(void)strcat(sprt, scpubmstr[i]);
			(void)strcat(sprt, scputstate[i]);
		}
	}
	if (cpu_add_stat_ignore == 0) {
		for (i = 1; i <= cpu_freq_num; i++) {
			(void)strcat(sprt, scpupstate[i]);
		}
	}
	if (cpu_add_stat_ignore == 0) {
		for (i = 1; i <= cpu_intr_num; i++) {
			(void)strcat(sprt, scputimer[i]);
			(void)strcat(sprt, scpuintr[i]);
		}
	}
	for (i = 0; i < user_field_cnt; i++) {
		get_user_field(i, user_field_value[i]);
		(void)sprintf(s, "%16.16s", user_field_value[i]);
		(void)strcat(sprt, s);
		(void)strcat(sprt, " ");
	}
	if (comment) {
		(void)strcat(sprt, " ");
		(void)strcat(sprt, comment);
	}

	(void)strcat(sprt, "\n");

	if (report_no % 100 == 0) {
		if (cpu_num > 1 || cpu_freq_num > 1 ||
		    bat_num > 1 || cpu_cstate_num > 1) {
			write_to_proc_log(head_log_head);
		}
		write_to_proc_log(log_head);
	}

	first = 0;
	write_to_proc_log(sprt);
}

void init_first_stat(void)
{
	if (mem_stat_ignore == 0) {
		get_mem_stat(&s_mem_stat);
	}
}

void form_log_head(void)
{
	int i, c, sz, no, cno, r_cno = 0, rd_cno = 0;
	char s[STR_LEN];
	char err_str[STR_LEN];

	log_head[0] = 0;
	head_log_head[0] = 0;

	if (no_time_stat_ignore == 0) {
		if (report_time_msec_flg == 0) {
			(void)strcat(log_head,
				     "T:     N      time    dtime    rtime ");
			(void)strcat(head_log_head,
				     "T:     N                        time ");
		} else {
			(void)strcat(log_head,
				     "T:     N          time        dtime        rtime ");
			(void)strcat(head_log_head,
				     "T:     N                                    time ");
		}
	} else if (no_time_stat_ignore == 1) {
		if (report_time_msec_flg == 0) {
			(void)strcat(log_head, "T:     N      time    dtime ");
			(void)strcat(head_log_head,
				     "T:     N               time ");
		} else {
			(void)strcat(log_head,
				     "T:     N          time        dtime ");
			(void)strcat(head_log_head,
				     "T:     N                       time ");
		}
	}

	if (bat_stat_ignore == 0) {
		for (i = 1; i <= bat_num; i++) {
			no = bat_path[i]->no;
			if (no < 0) {
				no = 0;
			}
			(void)sprintf(s,
				      "    bat    dbat      cap    vol"
				      "   rate charge state ");
			(void)strcat(log_head, s);
			(void)sprintf(s,
				      "                               "
				      "                bat%d ", no);
			(void)strcat(head_log_head, s);
		}
	}

	if (cpu_stat_ignore == 0) {
		for (i = 1; i <= cpu_num; i++) {
			no = cpu_load_path[i]->no;
			if (no < 0) {
				no = 0;
			}
			(void)strcat(log_head, "   load ");
			(void)strcat(head_log_head, "        ");
			if (cpu_add_stat_ignore == 0) {
				(void)strcat(log_head,
					     "    sys "
					     "   user " "    iow " "   idle ");
				(void)strcat(head_log_head,
					     "        "
					     "        " "        " "        ");
			}
			(void)strcat(log_head, "  cload ");
			if (cpu_add_stat_ignore == 0) {
				(void)strcat(head_log_head, "        ");
				(void)strcat(log_head,
					     "   csys "
					     "  cuser " "   ciow " "  cidle ");
				(void)strcat(head_log_head,
					     "        " "        " "        ");
			}
			(void)sprintf(s, "   cpu%d ", no);
			(void)strcat(head_log_head, s);
		}
		for (i = 1; i <= cpu_freq_num; i++) {
			no = cpu_freq_path[i]->no;
			if (no < 0) {
				no = 0;
			}
			(void)strcat(log_head, "   freq ");
			(void)sprintf(s, "   cpu%d ", no);
			(void)strcat(head_log_head, s);
		}
	}

	if (disp_stat_ignore == 0) {
		(void)strcat(log_head, "dpms disp ");
		(void)strcat(head_log_head, "     disp ");
	}

	if (ac_stat_ignore == 0) {
		(void)strcat(log_head, " ac ");
		(void)strcat(head_log_head, " ac ");
	}

	if (hd_stat_ignore == 0) {
		hd_stat_rd_wr_ignore = get_hd_stat(1, &c_hd_stat);
		if (hd_stat_rd_wr_ignore == 0) {
			(void)strcat(log_head, " hd       rd       wr ");
			(void)strcat(head_log_head, "                   hd ");
		} else {
			(void)sprintf(err_str,
				      "Warning: cannot get HD statistics\n");
			(void)write_to_warning_log(err_str);
			(void)strcat(log_head, " hd ");
			(void)strcat(head_log_head, " hd ");
		}
	}

	if (mem_stat_ignore == 0) {
		(void)strcat(log_head, "     mem ");
		(void)strcat(head_log_head, "     mem ");
		(void)strcat(log_head, "    swap ");
		(void)strcat(head_log_head, "    swap ");
	}

	if (cpu_add_stat_ignore == 0) {
		for (i = 1; i <= cpu_cstate_num; i++) {
			no = cpu_cstate_path[i]->no;
			if (no < 0) {
				no = 0;
			}
			get_cpu_cstate_states(i, &c_cpu_cstate_state[i]);
			cno = c_cpu_cstate_state[i].num_cstate_states;
			r_cno = 0;
			for (c = 0; c < cno; c++) {
				if (c_cpu_cstate_state[i].c_present[c] == 0) {
					continue;
				}
				r_cno++;
				(void)sprintf(s, "      C%d ", c);
				(void)strcat(log_head, s);
			}
			rd_cno = 0;
			for (c = 0; c < cno; c++) {
				if (c_cpu_cstate_state[i].cd_present[c] == 0) {
					continue;
				}
				rd_cno++;
				(void)sprintf(s, "       Cd%d ", c);
				(void)strcat(log_head, s);
			}
			(void)strcat(log_head, "   bus-mas ");
			(void)strcat(log_head, " T ");
			sz = 9 * r_cno + 11 * rd_cno - 5 + 11 + 3;

			(void)memset(s, ' ', STR_LEN);
			(void)sprintf(s + sz, "cpu%d ", no);
			(void)strcat(head_log_head, s);
		}
	}

	if (cpu_stat_ignore == 0) {
		for (i = 1; i <= cpu_freq_num; i++) {
			no = cpu_freq_path[i]->no;
			if (no < 0) {
				no = 0;
			}
			get_cur_freq(i, &c_cpu_freq_state[i]);
			cno = c_cpu_freq_state[i].freq_num;
			if (cno <= 0) {
				continue;
			}
			r_cno = 0;
			if (cpu_add_stat_ignore == 0) {
				for (c = 0; c < cno; c++) {
					r_cno++;
					(void)sprintf(s, "      P%d ", c);
					(void)strcat(log_head, s);
				}
				if (r_cno <= 0) {
					continue;
				}
			}
			sz = 9 * r_cno - 5;
			(void)memset(s, ' ', STR_LEN);
			(void)sprintf(s + sz, "cpu%d ", no);
			(void)strcat(head_log_head, s);
		}
	}
	if (cpu_add_stat_ignore == 0) {
		get_cpu_intr(&c_cpu_intr);
		cpu_intr_num = c_cpu_intr.cpu_num;
		for (i = 1; i <= cpu_intr_num; i++) {
			no = c_cpu_intr.cpu_no[i];
			(void)sprintf(s, "   timer ");
			(void)strcat(log_head, s);
			(void)sprintf(s, "    intr ");
			(void)strcat(log_head, s);

			(void)sprintf(s, "         ");
			(void)strcat(head_log_head, s);
			(void)sprintf(s, "    cpu%d ", no);
			(void)strcat(head_log_head, s);
		}
	}
	for (i = 0; i < user_field_cnt; i++) {
		(void)sprintf(s,
			      ((i + 1) ==
			       user_field_cnt) ? "     User fields" :
			      "                 ");
		(void)strcat(head_log_head, s);
		if (i < 10) {
			(void)sprintf(s, "          field%d ", i);
		} else {
			(void)sprintf(s, "         field%d ", i);
		}
		(void)strcat(log_head, s);
	}

	(void)strcat(log_head, "\n");
	(void)strcat(head_log_head, "\n");
}

#define	DISK_STATS_BLTK_FNAME	proc_diskstats_path

/* Get HD stat */
int get_hd_stat(int hd_no, hd_stat_t * hd_stat)
{
	char *fname = DISK_STATS_BLTK_FNAME;
	int fd = -1;
	char str[STR_LEN];
	char buf[BUFF_LEN];
	char *ptr;
	int rw, ret;
	char dmask[STR_LEN];

	(void)sprintf(dmask, " %s ", hd_name);

	hd_stat->rd_num = 0;
	hd_stat->rd_merg = 0;
	hd_stat->rd_sect = 0;
	hd_stat->rd_msec = 0;
	hd_stat->wr_num = 0;
	hd_stat->wr_merg = 0;
	hd_stat->wr_sect = 0;
	hd_stat->wr_msec = 0;

	if (access(fname, R_OK) != 0) {
		return (1);
	}
	fd = open(fname, O_RDONLY);
	if (fd < 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "open(%s) failed\n", __FILE__, __LINE__, fname);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	(void)memset(buf, 0, BUFF_LEN);
	rw = read(fd, buf, BUFF_LEN);
	if (rw < 0 || rw > BUFF_LEN - 1) {
		(void)sprintf(str, "File %s, Line %d: "
			      "read from %s failed\n",
			      __FILE__, __LINE__, fname);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	ptr = strstr(buf, dmask);

	if (ptr == NULL) {
		(void)sprintf(str,
			      "diskstats %s: strstr(\" $dmask \") failed, "
			      "str %s(end)\n", hd_name, buf);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	ptr += strlen(dmask);
	ret = sscanf(ptr,
		     "%i %i %i %i %i %i %i %i",
		     &hd_stat->rd_num, &hd_stat->rd_merg,
		     &hd_stat->rd_sect, &hd_stat->rd_msec,
		     &hd_stat->wr_num, &hd_stat->wr_merg,
		     &hd_stat->wr_sect, &hd_stat->wr_msec);
	if (ret != 8) {
		(void)sprintf(str,
			      "diskstats %s: sscanf() failed, "
			      "ret %d, str +%s+\n", hd_name, ret, ptr);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	(void)close(fd);

	return (0);
}

#define	MEM_INFO_BLTK_FNAME		proc_meminfo_path

int get_mem_stat_field(char *buf, char *name, int *value)
{
	char *fname = MEM_INFO_BLTK_FNAME;
	char str[STR_LEN];
	char *ptr;
	int ret;

	ptr = strstr(buf, name);
	if (ptr == NULL) {
		(void)sprintf(str,
			      "%s: strstr(\"%s:\") failed, "
			      "str %s\n", fname, name, buf);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	ptr += strlen(name);
	ret = sscanf(ptr, "%i", value);
	if (ret != 1) {
		(void)sprintf(str,
			      "%s: sscanf() failed, "
			      "ret %d, buf %s\n", fname, ret, ptr);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	return (0);
}

/* Get Swap stat */
int get_mem_stat(mem_stat_t * mem_stat)
{
	char *fname = MEM_INFO_BLTK_FNAME;
	int fd = -1;
	char str[STR_LEN];
	char buf[BUFF_LEN];
	int rw, ret;

	mem_stat->mem_total = 0;
	mem_stat->mem_free = 0;
	mem_stat->mem_used = -1;
	mem_stat->swap_total = 0;
	mem_stat->swap_free = 0;
	mem_stat->swap_used = -1;

	if (access(fname, R_OK) != 0) {
		return (1);
	}
	fd = open(fname, O_RDONLY);
	if (fd < 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "open(%s) failed\n", __FILE__, __LINE__, fname);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	(void)memset(buf, 0, BUFF_LEN);
	rw = read(fd, buf, BUFF_LEN);
	if (rw < 0 || rw > BUFF_LEN - 1) {
		(void)sprintf(str, "File %s, Line %d: "
			      "read from %s failed\n",
			      __FILE__, __LINE__, fname);
		(void)write_to_err_log(str);
		(void)close(fd);
		prog_exit(1);
	}

	ret = 0;
	ret += get_mem_stat_field(buf, "MemTotal:", &mem_stat->mem_total);
	ret += get_mem_stat_field(buf, "MemFree:", &mem_stat->mem_free);
	ret += get_mem_stat_field(buf, "SwapTotal:", &mem_stat->swap_total);
	ret += get_mem_stat_field(buf, "SwapFree:", &mem_stat->swap_free);
	if (ret != 0) {
		(void)close(fd);
		return (-1);
	}
	mem_stat->mem_used = mem_stat->mem_total - mem_stat->mem_free;
	mem_stat->swap_used = mem_stat->swap_total - mem_stat->swap_free;
	(void)close(fd);

	return (0);
}
