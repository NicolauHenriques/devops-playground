![CI](../../actions/workflows/ci.yml/badge.svg)

# devops-playground

A hands-on DevOps learning repo built in WSL Ubuntu (24.04).  
The goal is to practise Linux, Bash, automation, and ops-style troubleshooting through small scripts and systemd user timers.

## Requirements
- Ubuntu (WSL is fine)
- bash
- git
- shellcheck (for linting)

## Development
- Lint: 'make lint'
- Format: 'make fmt'
- Format check: 'make fmt-check'

Install shellcheck:
```bash
sudo apt update
sudo apt install -y shellcheck
