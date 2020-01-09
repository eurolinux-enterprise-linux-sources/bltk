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

#ifndef __BLTK_H__
#define __BLTK_H__

#include <time.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <stdarg.h>

#define BLTK_WL_IDLE		"Idle"
#define	BLTK_WL_DEVELOPER	"SW Development (developer)"
#define BLTK_WL_PLAYER		"DVD Playback (player)"
#define BLTK_WL_READER		"Web Browser (reader)"
#define BLTK_WL_GAME		"3D Gaming (game)"
#define BLTK_WL_OFFICE		"Open Office (office)"
#define BLTK_WL_USER		"User"
#define BLTK_WL_DISCHARGING	"Discharging"
#define BLTK_WL_CHARGING	"Charging"
#define	BLTK_WL_DEBUG		"Debug"
#define BLTK_WL_IDLE_TEST	"Idle Test"

#define	BLTK_COMMON_VERSION		"1.0.9"

#define	BLTK_VERSION			BLTK_COMMON_VERSION
#define	BLTK_IDLE_TEST_VERSION		BLTK_COMMON_VERSION

#define	BLTK_WL_IDLE_VERSION		BLTK_COMMON_VERSION
#define	BLTK_WL_DEVELOPER_VERSION	BLTK_COMMON_VERSION
#define	BLTK_WL_PLAYER_VERSION		BLTK_COMMON_VERSION
#define	BLTK_WL_READER_VERSION		BLTK_COMMON_VERSION
#define	BLTK_WL_GAME_VERSION		BLTK_COMMON_VERSION
#define	BLTK_WL_OFFICE_VERSION		BLTK_COMMON_VERSION
#define	BLTK_WL_USER_VERSION		BLTK_COMMON_VERSION
#define	BLTK_WL_DISCHARGING_VERSION	BLTK_COMMON_VERSION
#define	BLTK_WL_CHARGING_VERSION	BLTK_COMMON_VERSION
#define	BLTK_WL_DEBUG_VERSION		BLTK_COMMON_VERSION
#define	BLTK_WL_IDLE_TEST_VERSION	BLTK_COMMON_VERSION

#define	BLTK_COMMENT		"/tmp/bltk_comment"

#define	BAT_SYNC		5
#define	BAT_SYNC_TIME		60
#define	BAT_SYNC_TIME_ALARM	600

#define DEFAULT			"default"

#define	DPMS_NULL		0
#define	DPMS_ON			1
#define	DPMS_OFF		2

#define	STR_LEN			2048
#define	SMALL_STR_LEN		256
#define BUFF_LEN		(SMALL_STR_LEN * 128)
#define	MAX_LINES		1024

#define MAX_BAT			16
#define MAX_CPU			16

#define DEF_STATE_NAME		"state"
#define DEF_ON_STATE		"on-line"
#define DEF_OFF_STATE		"off-line"

#define ON_STATE		1
#define OFF_STATE		0

#define DEF_ALARM_FILE		"alarm"
#define DEF_INFO_FILE		"info"
#define DEF_STATE_FILE		"state"

#define DEF_MAX_CHARGE_NAME	"last full capacity"
#define DEF_CUR_CHARGE_NAME	"remaining capacity"
#define DEF_CUR_VOLTAGE_NAME	"present voltage"
#define DEF_CUR_RATE_NAME	"present rate"
#define DEF_DES_CHARGE_NAME	"design capacity"
#define DEF_DES_VOLTAGE_NAME	"design voltage"
#define DEF_ALRM_CHARGE_NAME	"alarm"
#define DEF_PRESENT_NAME	"present"
#define DEF_CHARGING_STATE_NAME	"charging state"
#define DEF_CAPACITY_STATE_NAME	"capacity state"

#define DEF_WATT_NAME		"mWh"
#define DEF_AMPER_NAME		"mAh"
#define DEF_PRESENT_YES		"yes"

#define DEF_COLON		":"
#define DEF_EQUAL		"="

#define DEF_CPU_CUR_FREQ_FILE	"cpuinfo_cur_freq"
#define DEF_CPU_CUR_FREQ_FILE2	"scaling_cur_freq"

#define DEF_CPU_C_FILE		"power"
#define DEF_CPU_T_FILE		"throttling"

#define	DEF_CPU_FREQ_DIR	"cpufreq"

#define MAX_FREQ		256

#define CAP_OK			0
#define CAP_CRITICAL		1
#define CAP_UNKNOWN		2

#define BAT_CAP_STATES		{ \
				"ok", \
				"critical" \
				}

#define MAX_CAP_STATES		2

#define CHARGED			0
#define CHARGING		1
#define DISCHARGING		2
#define CHARGING_DISCHARGING	3
#define CHARGING_UNKNOWN	4

#define BAT_CHARGE_STATES	{ \
				"charged", \
				"charging", \
				"discharging", \
				"charging/discharging" \
				}

#define MAX_CHARGE_STATES	4

#define MAX_C_STATES		8

#define	NEW_WORK_MSG		"N:"
#define	WORK_MSG		"W:"
#define	SLEEP_MSG		"I:"
#define	LOG_MSG			"S:"
#define	DEAD_MSG		"D:"
#define	FAIL_MSG		"F:"
#define	PASS_MSG		"P:"
#define	SYNC_MSG		"M:"

#define	MAIN_SLEEP_TIME		60
#define	DPMS_SLEEP		180
#define	DEF_SLEEP_NUM		6

#define	SEC_IN_MIN		60
#define	MIN_IN_HOUR		60
#define	SEC_IN_HOUR		3600

#define	MSEC_IN_MIN		60000
#define	MSEC_IN_HOUR		3600000

#define	min(a, b)		(a < b) ? (a) : (b)
#define	max(a, b)		(a > b) ? (a) : (b)

#define	MSEC_IN_SEC		1000
#define	MCSEC_IN_MSEC		1000
#define	MCSEC_IN_SEC		1000000

#define	SLEEP			1
#define WORK			2
#define	SLEEP_TIME		60

#define	DEF_REPORT_TIME		60

#define	DEF_MAKETIME		720

#define	DEF_READTIME		120
#define	DEF_GAMETIME		120

#define	DEF_RESULTS		"results"
#define	LAST_RESULTS		"last_results"
#define	HISTORY			"history"
#define	LAST_CMD		"last_cmd"

#define	M_PROC			(8192 * 1024)
#define	N_PROC			(cpu_num * 2)

#define	EMPTY_VALUE		-1

#define	MAX_FIELDS		99

typedef long long ll_t;
typedef unsigned long long ull_t;
typedef long double ld_t;
typedef double d_t;
typedef ll_t xtime_t;

typedef struct bat_path {
	int no;
	int is_mah;
	int des_cap;
	int des_vol;
	char *alrm_p;
	char *info_p;
	char *stat_p;
} bat_path_t;

extern bat_path_t **bat_path;

typedef struct bat_state {
	int last_full_cap;
	int cur_cap;
	int cur_vol;
	int cur_rate;
	int alrm;
	int cap_state;
	int charge_state;
} bat_state_t;

extern bat_state_t **bat;

extern int start_dpms_state;

extern int get_dpms_state(void);
extern void dpms_restore(void);
extern void set_dpms_on(void);
extern void set_dpms_off(void);
extern void set_screen_on(void);
extern void set_screen_off(void);

extern char proc_cpuinfo_path[STR_LEN];
extern char proc_meminfo_path[STR_LEN];
extern char proc_diskstats_path[STR_LEN];
extern char proc_interrupts_path[STR_LEN];
extern char hd_name[STR_LEN];
extern char hd_dev_name[STR_LEN];

extern int bat_num;
extern int bat_sync;
extern int bat_sync_time;
extern int bat_sync_time_alarm;

typedef struct cpu_load_path {
	int no;
} cpu_load_path_t;

extern cpu_load_path_t **cpu_load_path;

typedef struct cpu_load {
	ull_t cpu_sys;
	ull_t cpu_usr;
	ull_t cpu_iow;
	ull_t cpu_idl;
} cpu_load_t;

extern cpu_load_t **cpu_load;

typedef struct cpu_freq_path {
	int no;
	char *cur_freq_file;
	char *time_in_state_file;
} cpu_freq_path_t;

extern cpu_freq_path_t **cpu_freq_path;

typedef struct cpu_freq {
	int freq_num;
	int cur_freq;
	ull_t freq_value_array[MAX_FREQ];
	ull_t freq_time_array[MAX_FREQ];
} cpu_freq_t;

extern cpu_freq_t **cpu_freq;

typedef struct cpu_intr {
	int cpu_num;
	int cpu_no[MAX_CPU];
	ull_t timer[MAX_CPU];
	ull_t others[MAX_CPU];
} cpu_intr_t;

typedef struct cpu_cstate_path {
	int no;
	char *c_state_file;
	char *t_state_file;
} cpu_cstate_path_t;

extern cpu_cstate_path_t **cpu_cstate_path;

typedef struct cpu_cstate_state {
	int num_cstate_states;
	char bus_master_string[STR_LEN];
	int bus_master_present;
	int c_present[MAX_C_STATES];
	int cd_present[MAX_C_STATES];
	ull_t c_usage[MAX_C_STATES];
	ull_t c_duration[MAX_C_STATES];
	int t_state_present;
	int t_state;
} cpu_cstate_state_t;

typedef struct hd_stat {
	int hd_no;
	int rd_num;
	int rd_merg;
	int rd_sect;
	int rd_msec;
	int wr_num;
	int wr_merg;
	int wr_sect;
	int wr_msec;
} hd_stat_t;

typedef struct mem_stat {
	int mem_total;
	int mem_free;
	int mem_used;
	int swap_total;
	int swap_free;
	int swap_used;
} mem_stat_t;

extern cpu_cstate_state_t **cpu_cstate_state;

extern char proc_intr_file[STR_LEN];
extern char proc_diskstats_file[STR_LEN];
extern char proc_meminfo_file[STR_LEN];

extern char cpu_freq_base_dir[STR_LEN];
extern char *cpu_freq_dir;
extern char *cur_freq_file;

extern char cpu_cstate_dir[STR_LEN];
extern char *cpu_cstate_file;
extern char *cpu_tstate_file;

extern int cpu_num;
extern int cpu_freq_num;
extern int cpu_cstate_num;
extern int cpu_total;
extern int cpu_intr_num;

extern char ac_adapter_state_path[STR_LEN];
extern int ac_adapter_state_flg;
extern char *state_name;
extern char *on_state;
extern char *off_state;
extern int ac_state;
extern int check_bat_flg;

extern char *bat_cap_states[];
extern char *bat_charge_states[];

extern int verbose;
extern int simul_laptop;
extern char *simul_laptop_dir;

extern char stop_fname[STR_LEN];
extern char fail_fname[STR_LEN];
extern char pass_fname[STR_LEN];

extern int fd_proc_log;
extern int fd_stat_log;
extern int fd_work_log;
extern int fd_work_out_log;
extern int fd_err_log;
extern int fd_warning_log;

extern char *workload;

extern int manufacturer;
extern int stat_memory;
extern int stat_memory_saved;
extern int bat_percent[MAX_BAT];
extern int bat_value[MAX_BAT];
extern char prt_str[STR_LEN];
extern char head_log_head[STR_LEN];
extern char log_head[STR_LEN];
extern xtime_t time_start, time_prev;

extern int ac_err_workaround;

extern int idle_workload_flg;
extern int debug_workload_flg;
extern int develop_workload_flg;
extern int player_workload_flg;
extern int reader_workload_flg;
extern int game_workload_flg;
extern int office_workload_flg;
extern int user_workload_flg;
extern int init_user_workload_flg;
extern int discharging_workload_flg;
extern int charging_workload_flg;

extern xtime_t arg_time;
extern xtime_t read_time;

extern int debug_mode;
extern int pid_stat_log;
extern int pid_work_log;
extern int pid_dpms;
extern int parent_flg;
extern int stat_log_proc_flg;
extern int work_log_proc_flg;
extern int dpms_proc_flg;

extern char *results;

extern char *bltk_sudo;

extern int abort_flg;
extern int ac_ignore;

extern int no_time_stat_ignore;
extern int cpu_stat_ignore;
extern int cpu_add_stat_ignore;
extern int bat_stat_ignore;
extern int disp_stat_ignore;
extern int ac_stat_ignore;
extern int hd_stat_ignore;
extern int mem_stat_ignore;

extern int stat_log_ignore;
extern int work_log_ignore;
extern int proc_log_ignore;

extern int proc_load;
extern int disp_load;
extern xtime_t report_time;
extern int report_time_msec_flg;

extern int sys_info_2_done;

extern char cpu_stat_file[STR_LEN];

extern char stat_log_fname[STR_LEN];
extern char work_log_fname[STR_LEN];
extern char work_out_log_fname[STR_LEN];
extern char err_log_fname[STR_LEN];
extern char info_log_fname[STR_LEN];
extern char warning_log_fname[STR_LEN];

extern char *procname;
extern int work_output_flg;

extern int init_completed;

extern int user_field_cnt;
extern char user_field_cmd[MAX_FIELDS][STR_LEN];

extern int idle_test_mode;

extern void write_to_err_log(char *str);
extern void write_to_warning_log(char *str);
extern void write_to_proc_log(char *str);
extern void write_to_stat_log(char *str);
extern void write_to_work_log(char *str);
extern void write_to_work_out_log(char *str);
extern void write_to_work_out_log_only(char *str);
extern void write_to_stdout_work_out_log(char *str);

extern int init_vars(void);
extern int create_dump_file(void);
extern int get_host_info(void);
extern int get_ac_state(void);
extern int wait_ac_state(int state);

extern int get_bat_state(int bat_no, bat_state_t * bat);
extern int get_bat_info(int bat_no, bat_state_t * bat);
extern int get_bat_alarm(int bat_no, bat_state_t * bat);
extern int get_bat_charge(int bat_no, bat_state_t * bat);
extern double get_bat_charge_percent(int bat_no, bat_state_t * bat);
extern int get_bat_charge_state(int bat_no);
extern char *get_bat_charge_state_str(int bat_no);
extern int wait_bat_charge_state(int state, int bat_no);

extern int get_cpu_load(int cpu_no, cpu_load_t * cpu);
extern double get_cpu_load_percent(cpu_load_t * cpu1, cpu_load_t * cpu2,
				   int iow_status);
extern double get_cpu_load_percent_time(int cpu_no, int iow_status, int time);

extern int get_cur_freq(int cpu_no, cpu_freq_t * cpu);
extern int get_time_in_state(char *fname, ull_t * st, ull_t * tm);
extern ull_t get_average_time_in_state(int cnt,
				       ull_t * st, ull_t * prev_tm,
				       ull_t * cur_tm);
extern int cp_time_in_state(int cnt, ull_t * src_tm, ull_t * dst_tm);

extern int get_cpu_cstate_states(int cpu_no, cpu_cstate_state_t * cpu);

extern int get_simple_pseudo_file(char *file_name, char *value);
extern int set_simple_pseudo_file(char *file_name, char *value);

extern int get_value_file(char *file_name, char *name, char *delim, char *value,
			  size_t size, int val_no);
extern int get_buf_pseudo_file(char *file_name, char *buf);
extern int get_value_pseudo_file(char *file_name, char *name, char *delim,
				 char *value, size_t size, int val_no);
extern int get_value_buf_pseudo_file(char *buf, char *name,
				     char *delim, char *value,
				     size_t size, int val_no);

extern void create_stop_file(void);
extern int check_stop_file(void);
extern void create_fail_file(void);
extern void create_pass_file(void);

extern void sync(void);
extern int fsync(int fd);
extern char *realpath(const char *path, char *resolved_path);
extern int putenv(char *string);
extern char *strdup(const char *s);
extern void usleep(unsigned long usec);

extern int getopt(int argc, char *const argv[], const char *optstring);
extern char *optarg;
extern int optind, opterr, optopt;

extern int kill(pid_t pid, int sig);
extern int symlink(const char *oldpath, const char *newpath);

extern void check_state(void);

extern void write_report_str(char *work_type, char *comment);
extern void form_log_head(void);

extern void handler(int sig);
extern void prog_exit(int status);
extern xtime_t prog_time(void);
extern void prog_sleep(unsigned int seconds);
extern void prog_usleep(xtime_t tm);
extern int prog_system(char *cmd);
extern void prog_err_printf(char *format, ...);

extern void turn_off_stat_memory(void);

extern int get_hd_stat(int hd_no, hd_stat_t * hd_stat);
extern int get_mem_stat(mem_stat_t * mem_stat);
extern int get_cpu_intr(cpu_intr_t * cpu_intr);

extern void init_first_stat(void);

extern void save_sys_info_1(void);
extern void save_sys_info_2(void);

extern void check_critical_state(void);

extern void debug(char *format, ...);

extern int get_str_debug_var(char *name, char *var);

extern int get_int_debug_var(char *name, int *var);

extern char *get_prog_time_str();

#endif				/* __BLTK_H__ */
