#!/bin/bash
#
# Install perl-modules on clean CentOS 7
#
#TODO(robnagler)
#yum install -y httpd-devel perl-generators perl-ExtUtils-Embed
#SPECS# rpmbuild -ba perl.spec
#error: Failed build dependencies:
#	groff is needed by perl-4:5.16.3-291.el7.centos.x86_64
#	tcsh is needed by perl-4:5.16.3-291.el7.centos.x86_64
#	bzip2-devel is needed by perl-4:5.16.3-291.el7.centos.x86_64
#SPECS# yum install -y bzip2-devel tcsh groff
#
#
#[Thu Aug 24 02:40:02.076026 2017] [authz_core:debug] [pid 23938] mod_authz_core.c(835):
# [client 10.10.10.1:58981] AH01628: authorization result: granted (no directives), referer: http://10.10.10.50:8000/
#
#https://perl.apache.org/docs/2.0/user/porting/porting.html
#
## requireany explained
#http://www.the-art-of-web.com/system/apache-authorization/
#
## Need to add back in
#ipcclean

container_perl_install() {
    local src=$1 dst=$2 mode=$3
    install_download src/"$src" > "$dst"
    chmod "$mode" "$dst"
}

container_perl_main() {
    if (( $EUID != 0 )); then
        install_err 'must be run as root'
    fi
    if [[ ! -e /etc/fedora-release && ! -e /etc/yum.repos.d/epel.repo ]]; then
        yum --enablerepo=extras install -y -q epel-release
    fi
    local x=(
        awstats
        gcc-c++
        ghostscript
        gmp-devel
        httpd
        java-1.7.0-openjdk-devel
        # Needed by perl2html
        flex
        mdbtools
        mod_perl
        mod_ssl
        openssl-devel
        poppler-utils
        postgresql-devel
        procmail
        rpm-build
        xapian-core-devel

        perl-Algorithm-Diff
        perl-Archive-Zip
        perl-BSD-Resource
        perl-BerkeleyDB
        perl-Business-ISBN
        perl-Business-ISBN-Data
        perl-CPAN
        perl-Class-Load
        perl-Class-Load-XS
        perl-Class-Singleton
        perl-Convert-ASN1
        perl-Crypt-CBC
        perl-Crypt-DES
        perl-Crypt-Eksblowfish
        perl-Crypt-IDEA
        perl-Crypt-OpenSSL-RSA
        perl-Crypt-OpenSSL-Random
        perl-Crypt-RC4
        perl-Crypt-SSLeay
        perl-DBD-Pg
        perl-DBI
        perl-Data-OptList
        perl-Date-Manip
        perl-DateTime
        perl-DateTime-Locale
        perl-DateTime-TimeZone
        perl-Devel-Leak
        perl-Devel-Symdump
        perl-Device-SerialPort
        perl-Digest-HMAC
        perl-Digest-MD4
        perl-Digest-Perl-MD5
        perl-Digest-SHA1
        perl-Email-Abstract
        perl-Email-Address
        perl-Email-Date-Format
        perl-Email-MIME
        perl-Email-MIME-ContentType
        perl-Email-MIME-Encodings
        perl-Email-MessageID
        perl-Email-Reply
        perl-Email-Send
        perl-Email-Simple
        perl-Encode-Detect
        perl-Encode-Locale
        perl-Error
        perl-File-MMagic
        perl-HTML-Form
        perl-HTML-Parser
        perl-HTML-Tagset
        perl-HTTP-Cookies
        perl-HTTP-Date
        perl-HTTP-Message
        perl-HTTP-Negotiate
        perl-IO-Multiplex
        perl-IO-Socket-INET6
        perl-IO-Socket-SSL
        perl-IO-String
        perl-IO-stringy
        perl-Image-Size
        perl-LDAP
        perl-LWP-MediaTypes
        perl-LWP-Protocol-https
        perl-List-MoreUtils
        perl-MIME-Types
        perl-MIME-tools
        perl-MRO-Compat
        perl-Mail-DKIM
        perl-Mail-SPF
        perl-MailTools
        perl-Math-Random-ISAAC
        perl-Module-Implementation
        perl-Module-Runtime
        perl-Mozilla-CA
        perl-Net-CIDR-Lite
        perl-Net-DNS
        perl-Net-DNS-Resolver-Programmable
        perl-Net-Daemon
        perl-Net-HTTP
        perl-Net-IP
        perl-Net-SSLeay
        perl-Net-Server
        perl-NetAddr-IP
        perl-OLE-Storage_Lite
        perl-Package-DeprecationManager
        perl-Package-Stash
        perl-Package-Stash-XS
        perl-Params-Classify
        perl-Params-Util
        perl-Params-Validate
        perl-Parse-RecDescent
        perl-PathTools
        perl-Perl4-CoreLibs
        perl-PlRPC
        perl-Return-Value
        perl-Socket6
        perl-Sub-Exporter
        perl-Sub-Install
        perl-Sub-Uplevel
        perl-Sys-Hostname-Long
        perl-Template-Toolkit
        perl-TermReadKey
        perl-Test-Exception
        perl-Test-Fatal
        perl-Test-MockObject
        perl-Test-Requires
        perl-Test-Simple
        perl-Test-WWW-Selenium
        perl-Text-CSV
        perl-TimeDate
        perl-Try-Tiny
        perl-URI
        perl-WWW-RobotRules
        perl-XML-LibXML
        perl-XML-NamespaceSupport
        perl-XML-Parser
        perl-XML-SAX
        perl-XML-Simple
        perl-XML-XPath
        perl-YAML
        perl-YAML-Syck
        perl-libwww-perl
    )
    install_yum_install "${x[@]}"
    umask 022
    if [[ ! -L /usr/local/awstats ]]; then
        ln -s /usr/share/awstats /usr/local
    fi
    install_tmp_dir
    mkdir -p /root/.cpan{,/CPAN}
    container_perl_install MyConfig.pm /root/.cpan/CPAN/MyConfig.pm 400
    local f
    mkdir -p /usr/java
    for f in bcprov-jdk15-145.jar itextpdf-5.5.8.jar yui-compressor.jar; do
        container_perl_install "$f" /usr/java/"$f" 444
    done
    perl -pi -e 'm{local\(\$\[} && ($_ = q{})' /usr/share/perl5/*.pl
    cpan install OLLY/Search-Xapian-1.2.22.0.tar.gz
    (
        install_download src/gmp-6.0.0a.tar.bz2 | tar xjf -
        cd gmp-6.0.0/demos/perl
        install_download src/gmp-6.0.0.patch | patch -p0
        container_perl_make
    )
    (
        git clone --recursive --depth 1 https://github.com/biviosoftware/perl-misc
        cd perl-misc
        container_perl_make
    )
    (
        git clone --recursive --depth 1 https://github.com/biviosoftware/external-catdoc
        cd external-catdoc
        ./configure --prefix=/usr/local --disable-wordview
        make
        make install
    )
    (
        install_download src/perl2html-0.9.2.tar.bz2 | tar xjf -
        cd perl2html-0.9.2
        # https://lists.gnu.org/archive/html/octave-maintainers/2012-05/msg00208.html
        perl -pi -e 's{\@LEX\@}{flex --noyywrap}' Makefile.in
        ./configure
        make install
    )
}

container_perl_make() {
    perl Makefile.PL PREFIX=/usr/local < /dev/null
    make POD2MAN=/bin/true
    make POD2MAN=/bin/true pure_install
}

container_perl_main "${install_extra_args[@]}"
