#Simple Makefile for devops-playground
#Usage:
#	make health
#	make services
#	make net
#	make cleanup
#	make ps
#	make snapshot
#	make backup
#	make lint
#	make test
#	make smoke


.PHONY: health services net cleanup ps snapshot backup lint test smoke

health:
	./full_health.sh

services:
	./service_check.sh systemd-resolved.service wsl-pro.service

net:
	./net_check.sh google.com https://google.com

cleanup:
	./cleanup_logs.sh

ps:
	./ps_snapshot.sh

snapshot:
	./snapshot.sh

backup:
	./backup_logs.sh

lint:
	@find . -maxdepth 1 -type f -name "*.sh" -exec shellcheck {} +

test:
	./tests/smoke.sh

smoke:
	./smoke.sh