#!/bin/sh

mkdir /root/.fluentd-ui
cp /root/fluentd.conf /root/.fluentd-ui/fluent.conf

fluentd-ui start