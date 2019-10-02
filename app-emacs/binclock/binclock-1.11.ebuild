# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit elisp

DESCRIPTION="Display the current time using a binary clock"
HOMEPAGE="http://www.davep.org/emacs/"
SRC_URI="https://github.com/davep/${PN}.el/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2" # v2 only
SLOT="0"
KEYWORDS="~alpha ~amd64 ppc ppc64 ~sparc x86"

S="${WORKDIR}/${PN}.el-${PV}"
SITEFILE="50${PN}-gentoo.el"
