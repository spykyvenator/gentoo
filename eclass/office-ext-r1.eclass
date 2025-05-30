# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: office-ext-r1.eclass
# @MAINTAINER:
# The office team <office@gentoo.org>
# @AUTHOR:
# Tomáš Chvátal <scarabeus@gentoo.org>
# @SUPPORTED_EAPIS: 7 8
# @BLURB: Eclass for installing libreoffice extensions
# @DESCRIPTION:
# Eclass for easing maintenance of libreoffice extensions.

case ${EAPI} in
	7|8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_OFFICE_EXT_R1_ECLASS} ]]; then
_OFFICE_EXT_R1_ECLASS=1

# @ECLASS_VARIABLE: OFFICE_REQ_USE
# @PRE_INHERIT
# @DESCRIPTION:
# Useflags required on office implementation for the extension.
#
# Example:
# @CODE
# OFFICE_REQ_USE="java,jemalloc(-)?"
# @CODE
if [[ ${OFFICE_REQ_USE} ]]; then
	# Append the brackets for the depend below
	OFFICE_REQ_USE="[${OFFICE_REQ_USE}]"
fi

# @ECLASS_VARIABLE: OFFICE_IMPLEMENTATIONS
# @DESCRIPTION:
# List of implementations supported by the extension.
# Some work only for libreoffice and vice versa.
# Default value is all implementations.
#
# Example:
# @CODE
# OFFICE_IMPLEMENTATIONS=( "libreoffice" )
# @CODE
[[ -z ${OFFICE_IMPLEMENTATIONS} ]] && OFFICE_IMPLEMENTATIONS=( "libreoffice" )

# @ECLASS_VARIABLE: OFFICE_EXTENSIONS
# @PRE_INHERIT
# @REQUIRED
# @DESCRIPTION:
# Array containing list of extensions to install.
#
# Example:
# @CODE
# OFFICE_EXTENSIONS=( ${PN}_${PV}.oxt )
# @CODE
[[ -z ${OFFICE_EXTENSIONS} ]] && die "OFFICE_EXTENSIONS variable is unset."
if [[ "$(declare -p OFFICE_EXTENSIONS 2>/dev/null 2>&1)" != "declare -a"* ]]; then
	die "OFFICE_EXTENSIONS variable is not an array."
fi

# @ECLASS_VARIABLE: OFFICE_EXTENSIONS_LOCATION
# @DESCRIPTION:
# Path to the extensions location. Defaults to ${DISTDIR}.
#
# Example:
# @CODE
# OFFICE_EXTENSIONS_LOCATION="${S}/unpacked/"
# @CODE
: "${OFFICE_EXTENSIONS_LOCATION:=${DISTDIR}}"

# Most projects actually do not provide any relevant sourcedir as they are oxt.
S="${WORKDIR}"

IUSE="$(printf 'office_implementation_%s ' ${OFFICE_IMPLEMENTATIONS[@]})"
REQUIRED_USE="|| ( $(printf 'office_implementation_%s ' ${OFFICE_IMPLEMENTATIONS[@]}) )"

for i in ${OFFICE_IMPLEMENTATIONS[@]}; do
	if [[ ${i} == "libreoffice" ]]; then
		RDEPEND+="
			office_implementation_${i}? (
				|| (
					app-office/${i}${OFFICE_REQ_USE}
					app-office/${i}-bin${OFFICE_REQ_USE}
				)
			)
		"
	fi
done
BDEPEND="app-arch/unzip"

# @FUNCTION: office-ext-r1_src_unpack
# @DESCRIPTION:
# Flush the cache after removal of an extension.
office-ext-r1_src_unpack() {
	debug-print-function ${FUNCNAME} "$@"
	local i

	default

	for i in ${OFFICE_EXTENSIONS[@]}; do
		# Unpack the extensions where required and add case for oxt
		# which should be most common case for the extensions.
		if [[ -f ${OFFICE_EXTENSIONS_LOCATION}/${i} ]] ; then
			case ${i} in
				*.oxt)
					mkdir -p "${WORKDIR}/${i}/" || die
					pushd "${WORKDIR}/${i}/" > /dev/null || die
					einfo "Unpacking "${OFFICE_EXTENSIONS_LOCATION}/${i}" to ${PWD}"
					unzip -qo ${OFFICE_EXTENSIONS_LOCATION}/${i}
					assert "failed unpacking ${OFFICE_EXTENSIONS_LOCATION}/${i}"
					popd > /dev/null || die
					;;
				*) unpack ${i} ;;
			esac
		fi
	done
}

# @FUNCTION: office-ext-r1_src_install
# @DESCRIPTION:
# Install the extension source to the proper location.
office-ext-r1_src_install() {
	debug-print-function ${FUNCNAME} "$@"
	debug-print "Extensions: ${OFFICE_EXTENSIONS[@]}"

	local i j

	for i in ${OFFICE_IMPLEMENTATIONS[@]}; do
		if use office_implementation_${i}; then
			for j in ${OFFICE_EXTENSIONS[@]}; do
				pushd "${WORKDIR}/${j}/" > /dev/null || die
				insinto /usr/$(get_libdir)/${i}/share/extensions/${j/.oxt/}
				doins -r .
				popd > /dev/null || die
			done
		fi
	done
}

fi

EXPORT_FUNCTIONS src_unpack src_install
