#!/bin/bash

container_perl_download() {
    local src=$1 dst=${2:-} mode=${3:-}
    (
        install_url=https://github.com/biviosoftware/container-perl/raw/master/src
        if [[ $dst ]]; then
            install_download "$src" > "$dst"
            chmod "$mode" "$dst"
        else
            install_download "$src"
        fi
    )
}

container_perl_install_base() {
    install_repo_eval redhat-base
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
        php
        php-dom
        poppler-utils
        postgresql-devel
        procmail
        spamassassin
        strace
        rpm-build
        xapian-core-devel

        # First pass on textlive
        texlive
        texlive-collection-latex
        texlive-collection-latexrecommended
        texlive-collection-xetex
        texlive-latex
        texlive-multirow
        texlive-xetex
        texlive-xetex-def
        # texlive-collection-latexextra

        ImageMagick-perl
        perl-Algorithm-Diff
        perl-Archive-Zip
        perl-BSD-Resource
        perl-BerkeleyDB
        perl-Business-ISBN
        perl-Business-ISBN-Data
        perl-Canary-Stability
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
        perl-JSON
        perl-JSON-XS
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
    perl -pi -e 'm{local\(\$\[} && ($_ = q{})' /usr/share/perl5/*.pl
    (
        # https://wiki.apache.org/spamassassin/SoughtRules
        # Update: this is no longer active, and should not be used.
        rm -f /etc/mail/spamassassin/sought.conf
        # http://forums.sentora.org/showthread.php?tid=1118
        chown -R vagrant:vagrant /etc/mail/spamassassin /var/lib/spamassassin
    )
    umask 022
    cat > /etc/php.d/bivio.ini <<'EOF'
[Date]
date.timezone = America/Denver
EOF
    chmod 444 /etc/php.d/bivio.ini
}

container_perl_install_rest() {
    umask 022
    install_tmp_dir
    if [[ ! -L /usr/local/awstats ]]; then
        ln --relative -s /usr/share/awstats /usr/local
    fi
    mkdir -p /root/.cpan{,/CPAN}
    container_perl_download MyConfig.pm /root/.cpan/CPAN/MyConfig.pm 400
    local f
    mkdir -p /usr/java
    for f in bcprov-jdk15-145.jar itextpdf-5.5.8.jar yui-compressor.jar; do
        container_perl_download "$f" /usr/java/"$f" 444
    done
    cpan install OLLY/Search-Xapian-1.2.22.0.tar.gz
    cpan install DPARIS/Crypt-Blowfish-2.14.tar.gz
    (
        container_perl_download gmp-6.0.0a.tar.bz2 | tar xjf -
        cd gmp-6.0.0/demos/perl
        container_perl_download gmp-6.0.0.patch | patch -p0
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
        container_perl_download perl2html-0.9.2.tar.bz2 | tar xjf -
        cd perl2html-0.9.2
        # https://lists.gnu.org/archive/html/octave-maintainers/2012-05/msg00208.html
        perl -pi -e 's{\@LEX\@}{flex --noyywrap}' Makefile.in
        ./configure
        make install
    )
    (
        container_perl_download postgrey-1.37.tar.bz2 | tar xjf -
        cd postgrey-1.37
        container_perl_download postgrey-1.37.patch | patch || exit 1
        install -m 0755 postgrey /usr/sbin/postgrey
        install -d -m 0755 /usr/share/postgrey
        install -m 0444 postgrey_whitelist_clients /usr/share/postgrey
        # POSIT: rsconf/component/postgrey.py sets etc
        ln --relative -s /srv/postgrey/etc /etc/postgrey
    )
    # fpm needs ruby & bind is needed for bivio-named
    install_yum_install ruby-devel bind
    gem install fpm
}

container_perl_main() {
    if (( $EUID != 0 )); then
        install_err 'must be run as root'
    fi
    local p
    for p in "$@"; do
        container_perl_install_$p
    done
}

container_perl_make() {
    perl Makefile.PL PREFIX=/usr/local < /dev/null
    make POD2MAN=/bin/true
    make POD2MAN=/bin/true pure_install
}

# Must be here, because https://github.com/radiasoft/download/issues/154
container_perl_main "${install_extra_args[@]}"
