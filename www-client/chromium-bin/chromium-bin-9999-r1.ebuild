# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

CHROMIUM_LANGS="am ar bg bn ca cs da de el en_GB es es_LA et fa fi fil fr gu he
	hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt_BR pt_PT ro ru sk sl sr
	sv sw ta te th tr uk vi zh_CN zh_TW"

inherit chromium eutils multilib pax-utils unpacker

DESCRIPTION="The web browser from Google"
HOMEPAGE="http://www.google.com/chrome"

URI_BASE="http://commondatastorage.googleapis.com/chromium-browser-snapshots/"

SLOT="devel"
LICENSE="BSD"
KEYWORDS=""
IUSE="+plugins gnome"
RESTRICT="bindist mirror strip"

RDEPEND="
	app-arch/bzip2
	app-misc/ca-certificates
	dev-libs/atk
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/libgcrypt
	dev-libs/nspr
	dev-libs/nss
	gnome-base/gconf:2
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	net-print/cups
	sys-apps/dbus
	|| ( >=sys-devel/gcc-4.4.0[-nocxx] >=sys-devel/gcc-4.4.0[cxx] )
	virtual/udev
	x11-libs/cairo
	x11-libs/gdk-pixbuf
	x11-libs/gtk+:2
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXScrnSaver
	x11-libs/pango
	x11-misc/xdg-utils
"

QA_PREBUILT="*"
S=${WORKDIR}/chrome-linux

src_unpack() {
	# We have to do this inside of here, since it's a live ebuild. :-(

	if use x86; then
		G_ARCH="Linux";
	elif use amd64; then
		G_ARCH="Linux_x64";
	else
		die "This only supports x86 and amd64."
	fi
	REV=$(wget -q -O- $URI_BASE$G_ARCH/LAST_CHANGE)
	wget -O chrome-linux.zip $URI_BASE$G_ARCH/$REV/chrome-linux.zip
	unpack_zip "./chrome-linux.zip"
	rm ./chrome-linux.zip
}

pkg_setup() {
	CHROMIUM_HOME="/usr/$(get_libdir)/chromium-devel"
	chromium_suid_sandbox_check_kernel_config
}


src_install() {
	exeinto "${CHROMIUM_HOME}"

	sed -i -e "s/udev.so.0/udev.so.1/g" ./chrome
	doexe ./chrome || die

	doexe ./chrome_sandbox || die
	fperms 4755 "${CHROMIUM_HOME}/chrome_sandbox"

	if ! use arm; then
		doexe ./nacl_helper{,_bootstrap} || die
		insinto "${CHROMIUM_HOME}"
		doins ./nacl_irt_*.nexe || die
		doins ./libppGoogleNaClPluginChrome.so || die
	fi

	newexe "${FILESDIR}"/chromium-launcher-r3.sh chromium-launcher.sh || die

	# It is important that we name the target "chromium-browser",
	# xdg-utils expect it; bug #355517.
	dosym "${CHROMIUM_HOME}/chromium-launcher.sh" /usr/bin/chromium-devel || die
	# keep the old symlink around for consistency
	dosym "${CHROMIUM_HOME}/chromium-launcher.sh" /usr/bin/chromium-bin || die

	# Allow users to override command-line options, bug #357629.
	dodir /etc/chromium-devel || die
	insinto /etc/chromium-devel
	newins "${FILESDIR}/chromium.default" "default" || die

	pushd ./locales > /dev/null || die
	chromium_remove_language_paks
	popd

	insinto "${CHROMIUM_HOME}"
	doins ./*.pak || die

	doins -r ./locales || die
	doins -r ./resources || die

	newman ./chrome.1 chromium-bin.1 || die
	newman ./chrome.1 chromium-devel.1 || die

	doexe ./libffmpegsumo.so || die

	# Install icons and desktop entry.
	newicon -s 48 ./product_logo_48.png chromium-devel.png

	local mime_types="text/html;text/xml;application/xhtml+xml;"
	mime_types+="x-scheme-handler/http;x-scheme-handler/https;" # bug #360797
	mime_types+="x-scheme-handler/ftp;" # bug #412185
	mime_types+="x-scheme-handler/mailto;x-scheme-handler/webcal;" # bug #416393
	make_desktop_entry \
		chromium-devel \
		"Chromium-devel" \
		chromium-devel \
		"Network;WebBrowser" \
		"MimeType=${mime_types}\nStartupWMClass=chromium-devel"
	sed -e "/^Exec/s/$/ %U/" -i "${ED}"/usr/share/applications/*.desktop || die

	# Install GNOME default application entry (bug #303100).
	if use gnome; then
		dodir /usr/share/gnome-control-center/default-apps || die
		insinto /usr/share/gnome-control-center/default-apps
		newins "${FILESDIR}"/chromium-browser.xml chromium-devel.xml || die
	fi
}

any_cpu_missing_flag() {
	local value=$1
	grep '^flags' /proc/cpuinfo | grep -qv "$value"
}

pkg_preinst() {
	chromium_pkg_preinst
	if any_cpu_missing_flag sse2; then
		ewarn "The bundled PepperFlash plugin requires a CPU that supports the"
		ewarn "SSE2 instruction set, and at least one of your CPUs does not"
		ewarn "support this feature. Disabling PepperFlash."
		sed -e "/^exec/ i set -- --disable-bundled-ppapi-flash \"\$@\"" \
			-i "${D}${CHROMIUM_HOME}chrome" || die
	fi
}

pkg_postinst() {
	chromium_pkg_postinst

	einfo
	elog "Please notice the bundled flash player (PepperFlash)."
	elog "You can (de)activate all flash plugins via chrome://plugins"
	einfo
}
