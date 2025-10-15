#!/bin/bash
set -euo pipefail

# ======= Options =======
# Đặt true nếu muốn GIỮ lại thư mục $USER_HOME/gensyn/run
KEEP_DATA=false

# ======= Resolve USER_HOME giống hệt script cài đặt =======
LOGNAME=$(logname 2>/dev/null || true)
if [ -z "${LOGNAME:-}" ]; then
  LOGNAME="${SUDO_USER:-root}"
fi
if [ "$LOGNAME" = "root" ]; then
  USER_HOME="/root"
else
  USER_HOME="/home/$LOGNAME"
fi

RUN_DIR="$USER_HOME/gensyn/run"
TARGET_DIR="/root/rl-swarm"
CONFIG_FILE="$TARGET_DIR/rgym_exp/config/rg-swarm.yaml"
CONFIG_BAK="$CONFIG_FILE.backup"

echo "==> Uninstall Gensyn bits installed by /root/gensyn.install"
echo "    USER_HOME=$USER_HOME"
echo "    RUN_DIR=$RUN_DIR"

# ======= 1) Dừng & vô hiệu hóa services =======
for SVC in rl-swarm rl-swarm2; do
  if systemctl list-unit-files | grep -q "^${SVC}.service"; then
    echo "-> Stopping $SVC ..."
    systemctl stop "$SVC" 2>/dev/null || true
    echo "-> Disabling $SVC ..."
    systemctl disable "$SVC" 2>/dev/null || true
  fi
done

# ======= 2) Xóa unit files =======
changed=false
for UNIT in /etc/systemd/system/rl-swarm.service /etc/systemd/system/rl-swarm2.service; do
  if [ -f "$UNIT" ]; then
    echo "-> Removing $UNIT"
    rm -f "$UNIT"
    changed=true
  fi
done

if $changed; then
  echo "-> Reloading systemd daemon"
  systemctl daemon-reload
  systemctl reset-failed rl-swarm rl-swarm2 2>/dev/null || true
fi

# ======= 3) Khôi phục config nếu có backup =======
if [ -f "$CONFIG_BAK" ]; then
  echo "-> Restoring config from $CONFIG_BAK to $CONFIG_FILE"
  # Tạo dir nếu chưa có (phòng khi thư mục bị thiếu)
  mkdir -p "$(dirname "$CONFIG_FILE")"
  mv -f "$CONFIG_BAK" "$CONFIG_FILE"
else
  echo "-> No config backup found at $CONFIG_BAK (nothing to restore)"
fi

# ======= 4) Xóa auto.run & (tùy chọn) thư mục run =======
if [ -f "$RUN_DIR/auto.run" ]; then
  echo "-> Removing $RUN_DIR/auto.run"
  rm -f "$RUN_DIR/auto.run"
fi

if [ -d "$RUN_DIR" ]; then
  if [ "$KEEP_DATA" = false ]; then
    echo "-> Removing $RUN_DIR (and its contents)"
    rm -rf "$RUN_DIR"
  else
    echo "-> KEEP_DATA=true, keeping $RUN_DIR"
  fi
fi

# ======= 5) Thông tin trạng thái =======
echo "==> Done."
echo "==> Current service states (should be not-found/inactive):"
systemctl status rl-swarm 2>&1 | sed -n '1,5p' || true
systemctl status rl-swarm2 2>&1 | sed -n '1,5p' || true

echo "==> Verify:"
echo "   - Unit files:   ls -l /etc/systemd/system/rl-swarm*.service || true"
echo "   - Config file:  test -f \"$CONFIG_FILE\" && echo \"Config restored: $CONFIG_FILE\" || echo \"Config missing\""
echo "   - Run folder:   test -d \"$RUN_DIR\" && echo \"Kept $RUN_DIR\" || echo \"Removed $RUN_DIR\""
