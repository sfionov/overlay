# Copyright 2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

inherit eutils

DESCRIPTION="Dracut is a new initramfs infrastructure."
HOMEPAGE="http://sourceforge.net/apps/trac/dracut/wiki"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""
DEPEND=""
RDEPEND="app-arch/cpio
	 sys-fs/udev
	 sys-apps/util-linux
	 sys-apps/module-init-tools
	 sys-apps/coreutils
	 sys-apps/findutils
	 sys-apps/grep"

src_unpack() {
	unpack ${A}
	cd ${S}

	# Avoid bug #512796 (see RH Bugzilla)
	epatch "${FILESDIR}"/dracut-bug-512796.patch
	# Make a /lib symlink if needed
	epatch "${FILESDIR}"/dracut-lib-symlink.patch
	# /boot is not mounted automatically
	epatch "${FILESDIR}"/dracut-mount-boot.patch
	# There is no /lib/terminfo on Gentoo
	sed -i -e "s/#omit_dracutmodules=\"\"/omit_dracutmodules=\"terminfo\"/" dracut.conf
}

src_compile() {
	emake || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" sysconfdir=/etc install || die "failed install"
	dodoc AUTHORS COPYING HACKING README README.generic README.kernel README.modules
}
