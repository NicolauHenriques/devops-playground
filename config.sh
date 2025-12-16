#!/usr/bin/env bash
# Global config for devops-playground scripts.
# Any script can "source" this file to pick up shared defaults.

# --- Health check thresholds ---

# Disk usage thresholds for /
# Used by: health_disk.sh
export HEALTH_WARN_DISK=85    # warning at 85%
export HEALTH_CRIT_DISK=95    # critical at 95%

# Memory thresholds (MB free)
# We'll wire these in later for health_mem.sh
export HEALTH_WARN_MEM=800    # warning if free < 800MB
export HEALTH_CRIT_MEM=300    # critical if free < 300MB

# --- Log / backup settings ---

# Default age in days for deleting old logs
export CLEANUP_LOGS_DAYS=7

# Default age in days for deleting old backup archives
export BACKUP_RETENTION_DAYS=14