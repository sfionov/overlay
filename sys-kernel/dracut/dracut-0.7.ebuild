inherit eutils

DESCRIPTION="initramfs generation tool"
HOMEPAGE="http://sourceforge.net/projects/dracut/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="crypt dmraid lvm md nfs"

RDEPEND="app-shells/dash
	>=sys-apps/module-init-tools-3.6
	crypt? ( sys-fs/cryptsetup )
	dmraid? ( sys-fs/dmraid )
	lvm? ( sys-fs/lvm2 )
	md? ( sys-fs/mdadm )
	nfs? ( sys-apps/iproute2 net-misc/dhcp net-misc/bridge-utils net-fs/nfs-utils )"

DEPEND="${RDEPEND}"

src_unpack() {
	unpack "${A}"
	cd "${S}"
	epatch "${FILESDIR}/${PN}-0.7-unmount.patch"
	epatch "${FILESDIR}/${PN}-0.7-custom-paths.patch"
	epatch "${FILESDIR}/${PN}-0.7-lib-symlink.patch"
	epatch "${FILESDIR}/${PN}-0.7-absolute-path.patch"
	epatch "${FILESDIR}/${PN}-0.7-mount-boot.patch"
	epatch "${FILESDIR}/${PN}-0.7-terminfo.patch"

	# create config file
	local modules=""
	use crypt && modules="${modules} crypt"
	use dmraid && modules="${modules} dmraid"
	use lvm && modules="${modules} lvm"
	use md && modules="${modules} mdraid"
	use nfs && modules="${modules} network nfs"
	sed "s/<<OPTIONAL_MODULES>>/${modules}/g" "${FILESDIR}/dracut.conf" > "${S}/dracut.conf"
}

src_compile() {
	emake prefix=/usr sysconfdir=/etc || die "emake failed"
}

src_install() {
	emake prefix=/usr sysconfdir=/etc DESTDIR="${D}" install || die "emake install failed"
}

pkg_postinst() {
	elog 'To generate the initramfs:'
	elog ' # mount /boot (if necessary)'
	elog ' # dracut "" <kernel-version>'
	elog ''
	elog 'For command line documentation, see:'
	elog 'http://sourceforge.net/apps/trac/dracut/wiki/commandline'
	elog ''
	elog 'Simple example to select root and resume partition:'
	elog ' root=/dev/???? resume=/dev/????'
	elog ''
	elog 'Configuration is in /etc/dracut.conf.'
	elog 'The default config includes all available disk drivers and'
	elog 'should work on almost any system.'
	elog 'To include only drivers for this system, use the "-H" option.'
}
