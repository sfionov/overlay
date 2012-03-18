# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit eutils toolchain-funcs

DESCRIPTION="A modern version of the Layer 2 Tunneling Protocol (L2TP) daemon"
HOMEPAGE="http://www.xelerance.com/services/software/xl2tpd/"
SRC_URI="ftp://ftp.openswan.org/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="dnsretry kernel"

DEPEND="net-libs/libpcap"
RDEPEND="${DEPEND}
	kernel? ( >=sys-kernel/linux-headers-2.6.23 )
	net-dialup/ppp"

src_prepare() {
	epatch "${FILESDIR}/${PN}-1.3.0-LDFLAGS.patch"
	if use kernel; then
		epatch "${FILESDIR}/${PN}-1.3.0-kernel.patch"
		sed -i Makefile -e 's|#\(.*-DUSE_KERNEL\)|\1|' || die "sed Makefile enable kernel"
	fi
	sed -i Makefile -e 's| -O2 | |g' || die "sed Makefile"
	use dnsretry && epatch "${FILESDIR}/${PN}-dnsretry.patch"
}

src_compile() {
	emake CC=$(tc-getCC)
}

src_install() {
	emake PREFIX=/usr DESTDIR="${D}" install

	dodoc CREDITS README.xl2tpd \
		doc/README.patents doc/rfc2661.txt doc/*.sample

	dodir /etc/xl2tpd
	head -n 2 doc/l2tp-secrets.sample > "${ED}/etc/xl2tpd/l2tp-secrets" || die
	fperms 0600 /etc/xl2tpd/l2tp-secrets
	newinitd "${FILESDIR}"/xl2tpd-init xl2tpd

	keepdir /var/run/xl2tpd
}
