# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils autotools subversion

EAPI="2"

DESCRIPTION="RP-L2TP is a user-space implementation of L2TP for Linux and other UNIX systems"
HOMEPAGE="http://sourceforge.net/projects/rp-l2tp/"
ESVN_REPO_URI="http://wl500g.googlecode.com/svn/trunk/rp-l2tp"
ESVN_PROJECT="rp-l2tp"
SRC_URI=""

LICENSE="GPL-2"
KEYWORDS="amd64 ~ppc x86"
SLOT="0"
IUSE=""

src_prepare() {
	epatch "${FILESDIR}/${PN}-0.5-gentoo.patch"
	epatch "${FILESDIR}/${PN}-0.5-flags.patch"
	eautoreconf
}

src_compile() {
	emake -j1
}

src_install() {
	make RPM_INSTALL_ROOT="${D}" install || die "make install failed"

	dodoc README
	newdoc l2tp.conf rp-l2tpd.conf
	cp -pPR libevent/Doc "${D}/usr/share/doc/${PF}/libevent"

	newinitd "${FILESDIR}/rp-l2tpd-init" rp-l2tpd
}
