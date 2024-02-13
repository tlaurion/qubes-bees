Name:           bees
Version:        0.10
Release:        1%{?dist}
Summary:        Best-Effort Extent-Same, a btrfs deduplication agent
License:        GPL-3.0-only
Group:          System/Filesystems
URL:            https://github.com/Zygo/bees
Source:         https://github.com/Zygo/bees/archive/refs/tags/v%{version}.tar.gz
BuildRequires:  gcc-c++
BuildRequires:  util-linux-core
BuildRequires:  systemd-devel
BuildRequires:  make
Requires:       btrfs-progs
Requires:       systemd
Requires:       util-linux

# This removes errors from the build process, but it's not a good practice (fc37 related)
%global CXXFLAGS %{optflags} -Wno-error=restrict

%description
bees is a block-oriented userspace deduplication agent designed for large btrfs
filesystems. It is an offline dedupe combined with an incremental data scan
capability to minimize time data spends on disk from write to dedupe.

%prep
%autosetup

%build
cat >localconf <<-EOF
    SYSTEMD_SYSTEM_UNIT_DIR=%{_unitdir}
    LIBEXEC_PREFIX=%{_bindir}
    LIB_PREFIX=%{_libdir}
    PREFIX=%{_prefix}
    LIBDIR=%{_libdir}
    DEFAULT_MAKE_TARGET=all
EOF

%make_build CXXFLAGS="%{CXXFLAGS}"

%install
%make_install

%files
%license COPYING
%doc README.md
%{_bindir}/bees
%{_sbindir}/beesd
%{_unitdir}/beesd@.service
%dir %{_sysconfdir}/bees
%{_sysconfdir}/bees/beesd.conf.sample

%changelog
* Mon Apr 14 2024 Thierry Laurion <insurgo@riseup.net> - 0.10-1
- Initial package for fedora 37

