#!/bin/bash

sudo apt update -y && sudo apt upgrade -y

sudo apt install -y wget curl

wget https://github.com/prometheus/prometheus/releases/download/v2.37.6/prometheus-2.37.6.linux-amd64.tar.gz

tar xvfz prometheus-*.tar.gz

rm prometheus-*.tar.gz

sudo mkdir /etc/prometheus /var/lib/prometheus

cd prometheus-2.37.6.linux-amd64

sudo mv prometheus promtool /usr/local/bin/

sudo mv prometheus.yml /etc/prometheus/prometheus.yml

sudo mv consoles/ console_libraries/ /etc/prometheus/

prometheus --version

sudo useradd -rs /bin/false prometheus

sudo chown -R prometheus: /etc/prometheus /var/lib/prometheus

sudo cat /home/ubuntu/prom_config.txt > /etc/systemd/system/prometheus.service

sudo systemctl daemon-reload

sudo systemctl enable prometheus

sudo systemctl start prometheus

# Install grafana

sudo apt-get install -y apt-transport-https software-properties-common

sudo apt-get install -y adduser libfontconfig1 musl

wget https://dl.grafana.com/enterprise/release/grafana-enterprise_11.3.1_amd64.deb

sudo dpkg -i grafana-enterprise_11.3.1_amd64.deb

sudo systemctl daemon-reload

sudo systemctl enable grafana-server

sudo systemctl start grafana-server
