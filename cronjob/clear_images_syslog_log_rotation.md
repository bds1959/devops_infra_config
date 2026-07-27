# Ubuntu Server Maintenance Configuration

This document describes the cron jobs and log rotation configuration required to prevent excessive disk usage caused by system logs, Docker/containerd logs, and unused Docker images.

---

## 1. Configure Docker/Containerd Log Rotation

Create the logrotate configuration file:

```bash
sudo vi /etc/logrotate.d/container-logs
```

Add the following configuration. Uncomment **only one** log path based on your environment.

```conf
#Pod
/var/lib/pods/*/*.log

# Docker
#/var/lib/docker/containers/*/*.log

# Docker (newer versions using embedded containerd)
#/var/lib/docker/containerd/containers/*/*.log

# Standalone containerd
#/var/lib/containerd/containers/*/*.log

{
    rotate 1
    missingok
    notifempty
    compress
    copytruncate
    maxsize 500M
}
```

> **Note:** Only one of the above paths should be enabled.

To identify the correct log location:

```bash
find /var/lib -path "*/containers/*.log"
```

---

## 2. Configure Cron Jobs

Edit the root user's crontab:

```bash
sudo crontab -e
```

Add the following entries:

```cron
# Rotate Docker/Containerd logs every 30 minutes
*/30 * * * * /usr/sbin/logrotate /etc/logrotate.d/container-logs

# Truncate syslog files every day at 2:00 AM
0 2 * * * truncate -s 0 /var/log/syslog*

# Remove unused Docker images, containers, networks and build cache every day at 3:00 AM
0 3 * * * docker system prune -a -f
```

---

## 3. Verify Configuration

Verify cron jobs:

```bash
sudo crontab -l
```

Verify log rotation configuration:

```bash
sudo logrotate -f /etc/logrotate.d/container-logs
```

Check journal/syslog disk usage:

```bash
journalctl --disk-usage
```

Check Docker disk usage:

```bash
docker system df
```

Verify container log files:

```bash
find /var/lib -path "*/containers/*.log"
```

---

## Summary

| Task | Schedule |
|------|----------|
| Docker/Containerd log rotation | Every 30 minutes |
| Truncate `/var/log/syslog*` | Daily at 2:00 AM |
| Docker cleanup (`docker system prune -a -f`) | Daily at 3:00 AM |
