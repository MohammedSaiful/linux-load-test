# Linux Service Account & Load Testing Assignment

## Overview

This assignment covers Linux service account management, temporary storage, load testing, SSH configuration, monitoring, automation, log rotation, and cleanup.

**Environment:** Ubuntu 24.04 on WSL2
**Service Account:** `bgdsvc_saiful`
**Temporary Storage:** 256 MB `tmpfs`
**Load Testing:** `stress-ng`

---

# Part 1 — Service Account

### Objective

Create a dedicated Linux service account instead of running the workload as the normal user or root.

### Create User

```bash
export SVC_NAME=bgdsvc_saiful

sudo useradd -r -m -s /usr/sbin/nologin "$SVC_NAME"
```

### Verify

```bash
id "$SVC_NAME"
```

### Why?

* `-r` → creates a system account
* `-m` → creates a home directory
* `nologin` → prevents interactive login

Using a dedicated service account provides better **security and process isolation**.

---

# Part 2 — tmpfs Temporary Storage

### Objective

Create a 256 MB temporary filesystem for the service's test data.

### Create Mount Point

```bash
sudo mkdir -p "/mnt/${SVC_NAME}_tmp"
```

### Mount tmpfs

```bash
sudo mount -t tmpfs \
-o size=256M,mode=1770,uid=$(id -u "$SVC_NAME"),gid=$(id -g "$SVC_NAME") \
tmpfs "/mnt/${SVC_NAME}_tmp"
```

### Verify

```bash
mount | grep "$SVC_NAME"
df -h "/mnt/${SVC_NAME}_tmp"
```

### What is tmpfs?

`tmpfs` is a temporary filesystem that primarily uses memory for storage. It is useful for temporary files and testing.

---

# Part 3 — Load Testing

### Objective

Generate controlled CPU, memory, and disk workload and observe system behavior.

### CPU Test

```bash
stress-ng --cpu 2 --timeout 30s
```

### Memory Test

```bash
stress-ng --vm 1 --vm-bytes 128M --timeout 30s
```

### Monitor the System

```bash
top
free -h
ps -u "$SVC_NAME"
df -h "/mnt/${SVC_NAME}_tmp"
```

### What I Observed

During the tests:

* CPU usage increased during CPU stress.
* Memory usage increased during memory stress.
* tmpfs usage increased when test files were created.
* Processes running under the service account could be monitored.

### Lesson

Load testing helps understand how a system behaves when its resources are under pressure.

---

# Part 4 — SSH Key-Based Access

### Objective

Configure SSH public-key authentication for the service account.

### Generate Key

```bash
ssh-keygen -t ed25519 -f ~/.ssh/${SVC_NAME}_key
```

This creates:

```text
~/.ssh/bgdsvc_saiful_key
~/.ssh/bgdsvc_saiful_key.pub
```

The private key must remain secret.

### Configure SSH Key

The public key was placed in:

```text
/home/bgdsvc_saiful/.ssh/authorized_keys
```

Permissions:

```bash
sudo chmod 700 "/home/$SVC_NAME/.ssh"
sudo chmod 600 "/home/$SVC_NAME/.ssh/authorized_keys"
```

### Test

```bash
ssh -i ~/.ssh/${SVC_NAME}_key "$SVC_NAME"@localhost
```

The key authentication succeeded, but interactive login was rejected because the account uses:

```text
/usr/sbin/nologin
```

This was expected.

---

# Part 5 — SSH Hardening

### Objective

Improve SSH security by restricting authentication and access.

The SSH configuration was changed to:

```text
Port 2222
PermitRootLogin no
PasswordAuthentication no
AllowUsers bgdsvc_saiful
```

### Verify Configuration

```bash
sudo sshd -T | grep -E 'port|permitrootlogin|passwordauthentication|allowusers'
```

Expected:

```text
port 2222
permitrootlogin no
passwordauthentication no
allowusers bgdsvc_saiful
```

### Verify Listening Port

```bash
sudo ss -tlnp | grep ssh
```

### Lesson

SSH hardening reduces unnecessary access by:

* Disabling root login
* Disabling password authentication
* Restricting allowed users
* Using SSH keys

---

# Part 6 — Monitoring & Automation

### Objective

Create scripts to monitor the system and automatically clean old test files.

### Monitoring Script

```text
/usr/local/bin/bgdsvc_saiful_monitor.sh
```

It records:

* Date/time
* Memory usage
* tmpfs usage
* Service-account processes

Example:

```bash
free -h
df -h "/mnt/${SVC_NAME}_tmp"
ps -u "$SVC_NAME"
```

Logs are stored in:

```text
/var/log/bgdsvc_saiful/monitor.log
```

### Cleanup Script

```text
/usr/local/bin/bgdsvc_saiful_cleanup_old_files.sh
```

It removes files older than one day:

```bash
find "$TMPDIR" -type f -mtime +1 -delete
```

### Cron Jobs

```cron
*/5 * * * * /usr/local/bin/bgdsvc_saiful_monitor.sh
0 2 * * * /usr/local/bin/bgdsvc_saiful_cleanup_old_files.sh
```

This means:

* Monitoring → every 5 minutes
* Cleanup → every day at 2:00 AM

### Lesson

Cron can automate repetitive system administration tasks.

---

# Part 7 — Log Rotation

### Objective

Prevent the monitoring log from growing indefinitely.

Configuration:

```text
/etc/logrotate.d/bgdsvc_saiful
```

```text
/var/log/bgdsvc_saiful/*.log {
    daily
    rotate 5
    compress
    missingok
    notifempty
    size 10M
    create 0640 bgdsvc_saiful bgdsvc_saiful
}
```

### Important Options

| Option       | Purpose                       |
| ------------ | ----------------------------- |
| `daily`      | Check logs daily              |
| `rotate 5`   | Keep 5 old logs               |
| `compress`   | Compress old logs             |
| `missingok`  | Ignore missing logs           |
| `notifempty` | Don't rotate empty logs       |
| `size 10M`   | Rotate when log reaches 10 MB |

### Test

```bash
sudo logrotate -d /etc/logrotate.d/bgdsvc_saiful
```

Force rotation for testing:

```bash
sudo logrotate -f /etc/logrotate.d/bgdsvc_saiful
```

### Lesson

Log rotation prevents logs from consuming unlimited disk space.

---

# Part 8 — Cleanup

### Objective

Remove everything created during the assignment.

Cleanup order:

```text
Processes
   ↓
Automation
   ↓
tmpfs
   ↓
Logs
   ↓
Service Account
```

### Cleanup Script

```text
04_cleanup.sh
```

Main operations:

```bash
sudo pkill -u "$SVC_NAME"

sudo crontab -r -u "$SVC_NAME"
sudo rm -f "/etc/logrotate.d/$SVC_NAME"

sudo rm -f "/usr/local/bin/${SVC_NAME}_monitor.sh"
sudo rm -f "/usr/local/bin/${SVC_NAME}_cleanup_old_files.sh"

sudo umount "/mnt/${SVC_NAME}_tmp"
sudo rmdir "/mnt/${SVC_NAME}_tmp"

sudo rm -rf "/var/log/$SVC_NAME"

sudo userdel -r "$SVC_NAME"
```

The cleanup script was designed to be **idempotent**, meaning it can safely handle resources that have already been removed.

### Verify Cleanup

```bash
id "$SVC_NAME"
mount | grep "$SVC_NAME"
pgrep -u "$SVC_NAME"
```

The user, mount, and processes should no longer exist.

---

# Final Observations

During load testing, I observed increased CPU and memory usage depending on the workload. Temporary storage usage also increased when test files were generated.

The monitoring tools helped me understand how Linux resources behave under load.

---

# What I Would Do Differently in Production

For a real production server, I would avoid running heavy load tests directly on the live system.

Instead, I would:

* Use a dedicated staging/load-testing environment.
* Apply CPU and memory limits.
* Use continuous monitoring and alerting.
* Use centralized logging.
* Maintain backups and recovery procedures.
* Follow least-privilege access.
* Use automation/configuration management.
* Use scaling when necessary.

---

# Key Concepts Learned

* Linux service accounts
* Least privilege
* tmpfs
* CPU/memory/disk load testing
* Process monitoring
* SSH public-key authentication
* SSH hardening
* Cron automation
* Logrotate
* Bash scripting
* Idempotent cleanup
* Linux system administration

## Overall Workflow

```text
Create User
    ↓
Create tmpfs
    ↓
Generate Load
    ↓
Configure SSH
    ↓
Harden SSH
    ↓
Monitor & Automate
    ↓
Rotate Logs
    ↓
Clean Everything
```
