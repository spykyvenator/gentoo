# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

USE_RUBY="ruby31 ruby32"

RUBY_FAKEGEM_EXTRADOC="CHANGELOG.md README.rdoc"

RUBY_FAKEGEM_GEMSPEC="activesupport.gemspec"

RUBY_FAKEGEM_BINWRAP=""

inherit ruby-fakegem

DESCRIPTION="Utility Classes and Extension to the Standard Library"
HOMEPAGE="https://github.com/rails/rails"
SRC_URI="https://github.com/rails/rails/archive/v${PV}.tar.gz -> rails-${PV}.tgz"

LICENSE="MIT"
SLOT="$(ver_cut 1-2)"
KEYWORDS="amd64 arm arm64 ~hppa ~loong ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="test"

RUBY_S="rails-${PV}/${PN}"

ruby_add_rdepend "
	>=dev-ruby/concurrent-ruby-1.0.2:1
	>=dev-ruby/i18n-1.6:1
	>=dev-ruby/minitest-5.1
	dev-ruby/tzinfo:2
	>=dev-ruby/zeitwerk-2.3:2
"

# memcache-client, nokogiri, builder, and redis are not strictly needed,
# but there are tests using this code.
ruby_add_bdepend "test? (
	>=dev-ruby/dalli-3.0.1
	dev-ruby/connection_pool
	>=dev-ruby/nokogiri-1.8.1
	>=dev-ruby/builder-3.1.0
	>=dev-ruby/listen-3.3:3
	dev-ruby/rack
	dev-ruby/rexml
	dev-ruby/mocha
	<dev-ruby/minitest-5.16:*
	)"

PATCHES=(
	"${FILESDIR}"/${PN}-6.1.7.3-ruby-thread-noise.patch
	"${FILESDIR}"/${PN}-6.1.7.4-bytesplice.patch
	"${FILESDIR}"/${PN}-6.1.7.4-class_serial.patch
)

all_ruby_prepare() {
	# Set the secure permissions that tests expect.
	chmod 0755 "${HOME}" || die "Failed to fix permissions on home"

	# Remove items from the common Gemfile that we don't need for this
	# test run. This also requires handling some gemspecs.
	sed -i -e "/\(system_timer\|pg\|execjs\|jquery-rails\|mysql\|journey\|ruby-prof\|stackprof\|benchmark-ips\|turbolinks\|coffee-rails\|debugger\|sprockets-rails\|bcrypt\|uglifier\|minitest\|sprockets\|stackprof\|rack-cache\|sqlite\|websocket-client-simple\|\libxml-ruby\|bootsnap\|aws-sdk\|webmock\|capybara\|sass-rails\|selenium-webdriver\|webpacker\|webrick\|rack-test\|net-smtp\|net-imap\|net-pop\|digest\|matrix\)/ s:^:#:" \
		-e '/group :\(doc\|rubocop\|job\|cable\|storage\|ujs\|test\) do/,/^end/ s:^:#:' \
		-e 's/gemspec/gemspec path: "activesupport"/' \
		-e '5igem "builder"; gem "rack"' ../Gemfile || die
	rm ../Gemfile.lock || die
#	sed -i -e '1igem "tzinfo", "~> 1.1"' test/abstract_unit.rb || die

	# Avoid test that depends on timezone and test that fails on 32-bit arches
	sed -e '/test_implicit_coercion/,/^  end/ s:^:#:' \
		-e '/test_iso8601_output_and_reparsing/askip "Broken on 32-bit arches"' \
		-i test/core_ext/duration_test.rb || die

	# Avoid tests that seem to trigger race conditions.
	rm -f test/evented_file_update_checker_test.rb || die

	# Avoid test that generates filename that is too long
	sed -i -e '/test_filename_max_size/askip "gentoo"' test/cache/stores/file_store_test.rb || die

	# Avoid tests requiring a live redis running
	rm -f test/cache/stores/redis_cache_store_test.rb || die
	sed -i -e '/cache_stores:redis/ s:^:#:' Rakefile || die
	sed -i -e '/test_redis_cache_store/askip "lacking keywords"' test/cache/cache_store_setting_test.rb || die
}
