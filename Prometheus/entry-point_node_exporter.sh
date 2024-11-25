#!/bin/bash
sudo apt update -y && sudo apt upgrade -y

sudo apt install -y wget curl

wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz

tar xvfz node_exporter-*.tar.gz

sudo mv node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin

rm -r node_exporter-1.5.0.linux-amd64*

sudo useradd -rs /bin/false node_exporter

sudo cat /home/ubuntu/node_xporter.txt > /etc/systemd/system/node_exporter.service

sudo systemctl enable node_exporter

sudo systemctl daemon-reload

sudo systemctl start node_exporter
