#!/usr/bin/env bash
set -Eeuo pipefail

ROLE="${ROLE:-node}"

# 1) Create dirs with exact ownership/permissions for running munged as 'munge'
install -d -m 0700 -o munge -g munge /etc/munge
install -d -m 0755 -o munge -g munge /run/munge        # /run is tmpfs
install -d -m 0700 -o munge -g munge /var/lib/munge

# 2) Ensure the key exists on controller; nodes wait for it via the shared volume
if [[ "$ROLE" == "controller" ]]; then
  if [[ ! -f /etc/munge/munge.key ]]; then
    echo "Creating shared MUNGE key on controller..."
    if command -v /usr/sbin/create-munge-key >/dev/null 2>&1; then
      /usr/sbin/create-munge-key
    else
      dd if=/dev/urandom bs=1 count=1024 of=/etc/munge/munge.key
    fi
  fi
else
  echo "Waiting for MUNGE key from controller..."
  until [[ -f /etc/munge/munge.key ]]; do
    sleep 1
  done
fi

# 3) Harden key perms and make sure 'munge' can read it
chown munge:munge /etc/munge/munge.key
chmod 0400        /etc/munge/munge.key

# 4) Diagnostics
echo "Diagnostics before starting munged:"
id munge || true
for p in /etc/munge /etc/munge/munge.key /run/munge /var/lib/munge; do
  if [[ -e "$p" ]]; then stat -c '%A %a %U:%G %u:%g %n' "$p"; else echo "MISSING $p"; fi
done

# 5) Start munged as the 'munge' user, log to stderr (Docker captures it)
echo "Starting munged as user 'munge'..."
su -s /bin/sh -c '/usr/sbin/munged --foreground --verbose --key-file=/etc/munge/munge.key --socket=/run/munge/munge.socket.2 --pid-file=/run/munge/munged.pid' munge &
MUNGED_PID=$!

# 6) Wait for the socket and a token round-trip to succeed
for i in {1..60}; do
  if [[ -S /run/munge/munge.socket.2 ]] && munge -n | unmunge >/dev/null 2>&1; then
    echo "MUNGE is up."
    break
  fi
  sleep 0.5
done
if [[ ! -S /run/munge/munge.socket.2 ]]; then
  echo "ERROR: MUNGE socket not present after wait. Current state:"
  ls -l /run/munge || true
  exit 1
fi

# 7) Slurm runtime dirs
install -d -m 0755 -o slurm -g slurm /var/spool/slurm
install -d -m 0755 -o root  -g root  /var/spool/slurmd
install -d -m 0755 -o slurm -g slurm /var/log/slurm

# 8) Start Slurm
if [[ "$ROLE" == "controller" ]]; then
  echo "Starting slurmctld..."
  exec /usr/sbin/slurmctld -Dvv
else
  echo "Starting slurmd..."
  exec /usr/sbin/slurmd -Dvv
fi