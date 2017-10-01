#!/bin/bash
build_image_base=centos:7
build_maintainer="Bivio Software <$build_type@bivio.biz>"}

build_as_root() {
    curl radia.run | bash -s redhat-base
    curl radia.run | bash -s /biviosoftware/container-perl
}

build_as_run_user() {
    return
}
