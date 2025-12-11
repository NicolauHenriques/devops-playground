#Simple Makefile for devops-playground
#Usage:
#	make health
#	make services
#	make net
#	make cleanup
#	make ps
#	make snapshot


.PHONY: health services net cleanup ps snapshot backup

health:
	./full_health.sh

services:
	./service_check.sh systemd-resolved.service wsl-pro.service

net:
	./net_check.sh google.com https://google.com

cleanup:
	./cleanup_logs.sh 7

ps:
	./ps_snapshot.sh

snapshot:
	./snapshot.sh

backup:
	./backup_logs.sh 14
