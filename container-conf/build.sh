#!/bin/bash
build_image_base=centos:7
build_maintainer="Bivio Software <$build_type@bivio.biz>"
export BIVIO_WANT_PERL=

build_as_root() {
    echo 'export BIVIO_WANT_PERL=' >> ~/.pre_bivio_bashrc
    curl radia.run | bash -s biviosoftware/container-perl
}

build_as_run_user() {
    echo 'export BIVIO_WANT_PERL=' >> ~/.pre_bivio_bashrc
}
