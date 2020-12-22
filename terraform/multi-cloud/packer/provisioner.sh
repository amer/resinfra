#!/bin/bash
set -o errexit

apt-get update
apt-get install -y nginx
systemctl enable --now nginx
