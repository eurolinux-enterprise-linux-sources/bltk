Name:		bltk
Version:	1.1.0
Release:	4%{?dist}
Summary:	The BLTK measures notebook battery life under any workload

Group:		Applications/System
License:	BSD
URL:			http://www.lesswatts.org/projects/bltk/
Source0:	http://www.lesswatts.org/patches/bltk/%{name}-%{version}.tar.gz
Source1:	bltk.conf
Source2:  OOCALC_FILE_SAMPLE.ods
Source3:  OODRAW_FILE_SAMPLE.odg
Source4:  OOWRITER_FILE_SAMPLE.odt

Patch1:  bltk-1.0.9-man.patch
Patch3:  bltk-1.0.9-bltk_paths.patch
Patch4:  bltk-1.0.9-opt_developer.patch
Patch5:  bltk-1.1.0-cond_install.patch
Patch6:  bltk-1.0.9-opt_game.patch
Patch7:  bltk-1.0.9-conf.patch
Patch8:  bltk-1.0.9-opt_office.patch
Patch10: bltk-1.0.9-opt_player.patch
Patch11: bltk-1.0.9-home_dir.patch
Patch12: bltk-1.0.9-opt_reader.patch
Patch13: bltk-1.0.9-installed.patch
Patch15: bltk-1.0.9-xse.patch
Patch16: bltk-1.0.9-conf_home.patch
Patch17: bltk-1.1.0-rm_sudo.patch
Patch18: bltk-1.0.9-plot-path.patch
Patch19: bltk-1.0.9-rpm.patch

BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires:	libX11-devel

Requires: udisks2 gnuplot

%description
This tool kit is used to measure battery life and performance under
different workloads on Linux. Test can be used with various workloads to
simulate different types of laptop usage.
The following workloads are currently implemented:
	a) Idle workload - collect statistics only
	b) Developer workload - simulates code development in Linux environment
	c) Reader workload - simulates text reading on laptop
	d) DVD playback workload - simulates laptop entertaining usage
	e) 3d game workload - simulates 3D-gaming on laptop
	f) Office Activity workload - simulates laptop usage for different
		office activities (based on OpenOffice.org office suit)

%prep
%setup -q -n bltk

# %patch0 -p1 -b .all
%patch1 -p1 -b .man
%patch3 -p1 -b .bltk_paths
%patch4 -p1 -b .opt_developer
%patch5 -p1 -b .cond_install
%patch6 -p1 -b .opt_game
%patch7 -p1 -b .conf
%patch8 -p1 -b .opt_office
%patch10 -p1 -b .opt_player
%patch11 -p1 -b .home_dir
%patch12 -p1 -b .opt_reader
%patch13 -p1 -b .installed
%patch15 -p1 -b .xse
%patch16 -p1 -b .conf_home
%patch17 -p1 -b .rm_sudo
%patch18 -p1 -b .plot-path
%patch19 -p1 -b .rpm

%build
export CFLAGS="$RPM_OPT_FLAGS"
make
#make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make install DESTDIR=$RPM_BUILD_ROOT PACKAGE_BUILD=y

mkdir -p ${RPM_BUILD_ROOT}%{_bindir}
mkdir -p ${RPM_BUILD_ROOT}%{_libdir}
mkdir -p ${RPM_BUILD_ROOT}%{_libdir}/bltk
mkdir -p ${RPM_BUILD_ROOT}%{_libdir}/bltk/{bin,lib,doc,wl_developer,wl_game,wl_office,wl_player,wl_reader}
mkdir -p ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_developer/bin
mkdir -p ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_game/bin
mkdir -p ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_office/bin
mkdir -p ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_player/bin
mkdir -p ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_reader/bin
mkdir -p ${RPM_BUILD_ROOT}/etc
mkdir -p ${RPM_BUILD_ROOT}%{_mandir}/man{1,5}

install -m 644 %{SOURCE1}	${RPM_BUILD_ROOT}/etc
install -m 644 doc/bltk.1 ${RPM_BUILD_ROOT}/%{_mandir}/man1
install -m 644 doc/bltk_report.1 ${RPM_BUILD_ROOT}/%{_mandir}/man1
install -m 644 doc/bltk.conf.5 ${RPM_BUILD_ROOT}/%{_mandir}/man5

install -m 755 bin/bat_drain	${RPM_BUILD_ROOT}%{_libdir}/bltk/bin/bat_drain
install -m 755 bin/bat_drain_table	${RPM_BUILD_ROOT}%{_libdir}/bltk/bin/bat_drain_table

install -m 755 bin/bltk	${RPM_BUILD_ROOT}%{_libdir}/bltk/bin
ln -s %{_libdir}/bltk/bin/bltk ${RPM_BUILD_ROOT}%{_bindir}/bltk
ln -s %{_libdir}/bltk/bin/bltk_plot ${RPM_BUILD_ROOT}%{_bindir}/bltk_plot
ln -s %{_libdir}/bltk/bin/bltk_report ${RPM_BUILD_ROOT}%{_bindir}/bltk_report
ln -s %{_libdir}/bltk/bin/bltk_report_compress ${RPM_BUILD_ROOT}%{_bindir}/bltk_report_compress
ln -s %{_libdir}/bltk/bin/bltk_report_table ${RPM_BUILD_ROOT}%{_bindir}/bltk_report_table
ln -s %{_libdir}/bltk/bin/bltk_report_uncompress ${RPM_BUILD_ROOT}%{_bindir}/bltk_report_uncompress

install -m 755 lib/libxse.so.0	${RPM_BUILD_ROOT}%{_libdir}/bltk/lib/libxse.so.0

install -m 755 bin/bltk_*	${RPM_BUILD_ROOT}%{_libdir}/bltk/bin/
install -m 755 bin/bat_*	${RPM_BUILD_ROOT}%{_libdir}/bltk/bin/

install -m 755 wl_developer/bin/bltk_wl_developer ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_developer/bin
install -m 755 wl_developer/bin/bltk_wl_developer_xse ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_developer/bin
install -m 755 wl_developer/bin/bltk_wl_developer_spy ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_developer/bin

install -m 755 wl_game/bin/bltk_wl_game ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_game/bin
install -m 755 wl_game/bin/bltk_wl_game_xse ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_game/bin

install -m 755 wl_office/bin/bltk_wl_office ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_office/bin
install -m 755 wl_office/bin/bltk_wl_office_xse ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_office/bin
install -m 755 wl_office/bin/bltk_wl_office_run_app ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_office/bin
install -m 644 %{SOURCE2} ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_office
install -m 644 %{SOURCE3} ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_office
install -m 644 %{SOURCE4} ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_office
install -m 644 wl_office/scen ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_office
install -m 644 wl_office/scen_install ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_office
install -m 644 wl_office/response_install ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_office
install -m 644 wl_office/text* ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_office

install -m 755 wl_player/bin/bltk_wl_player ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_player/bin
install -m 755 wl_player/bin/bltk_wl_player_make_binary ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_player/bin

install -m 755 wl_reader/bin/bltk_wl_reader ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_reader/bin
install -m 755 wl_reader/bin/bltk_wl_reader_xse ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_reader/bin
install -m 644 wl_reader/war_and_peace.html ${RPM_BUILD_ROOT}%{_libdir}/bltk/wl_reader

%clean
rm -rf $RPM_BUILD_ROOT

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

%files
%defattr(-,root,root,-)
%doc doc/HOWTO doc/Manual doc/README
%config(noreplace) %attr(0644,root,root) /etc/bltk.conf

%{_libdir}/bltk/bin/bltk
%{_bindir}/bltk
%{_bindir}/bltk_plot
%{_bindir}/bltk_report
%{_bindir}/bltk_report_compress
%{_bindir}/bltk_report_table
%{_bindir}/bltk_report_uncompress

%{_mandir}/man1/bltk*
%{_mandir}/man5/bltk.conf.*

%{_libdir}/bltk/lib/libxse.so.0

%{_libdir}/bltk/bin/bat_drain
%{_libdir}/bltk/bin/bat_drain_table
%{_libdir}/bltk/bin/bltk_calc
%{_libdir}/bltk/bin/bltk_check
%{_libdir}/bltk/bin/bltk_display_state
%{_libdir}/bltk/bin/bltk_get_ac_adapter
%{_libdir}/bltk/bin/bltk_get_bat
%{_libdir}/bltk/bin/bltk_get_cpufreq
%{_libdir}/bltk/bin/bltk_get_cpuinfo
%{_libdir}/bltk/bin/bltk_get_cpustat
%{_libdir}/bltk/bin/bltk_get_cpustate
%{_libdir}/bltk/bin/bltk_get_dmidecode
%{_libdir}/bltk/bin/bltk_get_hdparm
%{_libdir}/bltk/bin/bltk_get_hd_rpm
%{_libdir}/bltk/bin/bltk_get_info
%{_libdir}/bltk/bin/bltk_get_kernel_release
%{_libdir}/bltk/bin/bltk_get_lspci
%{_libdir}/bltk/bin/bltk_get_meminfo
%{_libdir}/bltk/bin/bltk_get_realpath
%{_libdir}/bltk/bin/bltk_get_stat
%{_libdir}/bltk/bin/bltk_get_system_release
%{_libdir}/bltk/bin/bltk_get_timer
%{_libdir}/bltk/bin/bltk_get_user_field
%{_libdir}/bltk/bin/bltk_get_xdpyinfo

%{_libdir}/bltk/bin/bltk_install
%{_libdir}/bltk/bin/bltk_func
%{_libdir}/bltk/bin/bltk_plot
%{_libdir}/bltk/bin/bltk_report
%{_libdir}/bltk/bin/bltk_report_check
%{_libdir}/bltk/bin/bltk_report_compress
%{_libdir}/bltk/bin/bltk_report_table
%{_libdir}/bltk/bin/bltk_report_uncompress
%{_libdir}/bltk/bin/bltk_save_sys_info
%{_libdir}/bltk/bin/bltk_spy
%{_libdir}/bltk/bin/bltk_time
%{_libdir}/bltk/bin/bltk_type_command
%{_libdir}/bltk/bin/bltk_winid
%{_libdir}/bltk/bin/bltk_wl_common

%{_libdir}/bltk/wl_developer/bin/bltk_wl_developer
%{_libdir}/bltk/wl_developer/bin/bltk_wl_developer_spy
%{_libdir}/bltk/wl_developer/bin/bltk_wl_developer_xse

%{_libdir}/bltk/wl_game/bin/bltk_wl_game
%{_libdir}/bltk/wl_game/bin/bltk_wl_game_xse

%{_libdir}/bltk/wl_office/bin/bltk_wl_office
%{_libdir}/bltk/wl_office/bin/bltk_wl_office_xse
%{_libdir}/bltk/wl_office/bin/bltk_wl_office_run_app
%{_libdir}/bltk/wl_office/OOCALC_FILE_SAMPLE.ods
%{_libdir}/bltk/wl_office/OODRAW_FILE_SAMPLE.odg
%{_libdir}/bltk/wl_office/OOWRITER_FILE_SAMPLE.odt
%{_libdir}/bltk/wl_office/scen
%{_libdir}/bltk/wl_office/scen_install
%{_libdir}/bltk/wl_office/response_install
%{_libdir}/bltk/wl_office/text1
%{_libdir}/bltk/wl_office/text2
%{_libdir}/bltk/wl_office/text3

%{_libdir}/bltk/wl_player/bin/bltk_wl_player
%{_libdir}/bltk/wl_player/bin/bltk_wl_player_make_binary

%{_libdir}/bltk/wl_reader/bin/bltk_wl_reader
%{_libdir}/bltk/wl_reader/bin/bltk_wl_reader_xse
%{_libdir}/bltk/wl_reader/war_and_peace.html

%changelog
* Wed Feb 13 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.1.0-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_19_Mass_Rebuild

* Wed Jul 18 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.1.0-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_18_Mass_Rebuild

* Mon May  7 2012 Jaroslav Škarvada <jskarvad@redhat.com> - 1.1.0-2
- Switched to udisks2

* Thu Mar 29 2012 Jaroslav Škarvada <jskarvad@redhat.com> - 1.1.0-1
- New version
- Dropped office_scen patch (upstreamed)
- Dropped hdparm patch (upstream added support for LVM)
- Reworked rm_sudo patch

* Thu Jan 12 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.0.9-12
- Rebuilt for https://fedoraproject.org/wiki/Fedora_17_Mass_Rebuild

* Wed Feb 23 2011 Jiri Skala <jskala@redhat.com> 1.0.9-11
- fixes #679022 - bltk_plot is broken
- fixes paths in bltk_get_hd_rpm

* Mon Feb 07 2011 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.0.9-10
- Rebuilt for https://fedoraproject.org/wiki/Fedora_15_Mass_Rebuild

* Mon May 10 2010 Jiri Skala <jskala@redhat.com> 1.0.9-9
- added udisks dependency

* Thu Feb 04 2010 Jiri Skala <jskala@redhat.com> 1.0.9-8
- removed requires openoffice

* Fri Dec 11 2009 Jiri Skala <jskala@redhat.com> 1.0.9-7
- fixes #542688 - bltk will run any command as root

* Thu Sep 03 2009 Jiri Skala <jskala@redhat.com> 1.0.9-6
- fixed misspelled bash variable with stop file

* Fri Jul 31 2009 Jiri Skala <jskala@redhat.com> 1.0.9-5
- bltk.conf can be located in ~/.bltk

* Tue Jul 28 2009 Jiri Skala <jskala@redhat.com> 1.0.9-4
- added man mages
- splitted patch to more files
- filled up scen file of office workload
- updated to latest upstream sources

* Fri Jul 24 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.0.9-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_12_Mass_Rebuild

* Tue Jul 14 2009 Jiri Skala <jskala@redhat.com> 1.0.9-1
- merged with latest upstream sources

* Fri Apr 10 2009 Jiri Skala <jskala@redhat.com> 1.0.8-2
- optimized bltk.conf - SOFFICE_PROG
- fixed working dir in reports
- fixed SIGHUP handling
- finalized implementation of stop file in office and reader WLs

* Thu Jan 29 2009 Jiri Skala <jskala@redhat.com> 1.0.8-1
- assembling package
