export LOGNAME=$(logname)
cat > /home/$LOGNAME/gensyn/run/auto.run << 'EOF'
#!/bin/bash
# Thu muc chua du lieu goc - hardcode username tai day
BASE_DIR="/home/REPLACE_USERNAME/gensyn/run"
# Thu muc dich cua rl-swarm
TARGET_DIR="/root/rl-swarm"
# Thu muc con de copy temp-data
LOGIN_SUBDIR="modal-login"

# Tu dong tim so folder lon nhat
MAX_FOLDER=$(find "$BASE_DIR" -maxdepth 1 -type d -name '[0-9]*' -printf '%f\n' | sort -n | tail -1)
MAX_FOLDER=${MAX_FOLDER:-1}  # Mac dinh la 1 neu khong tim thay

echo "$(date) - Phat hien co $MAX_FOLDER folder, se lap tu 1 den $MAX_FOLDER"

# Ham copy file va restart
copy_and_restart() {
    local idx="$1"
    PEM_SOURCE="$BASE_DIR/$idx/swarm.pem"
    TEMP_SOURCE="$BASE_DIR/$idx/temp-data"
    
    systemctl stop rl-swarm
    sleep 5
    
    pkill -f "yarn start" 2>/dev/null || true
    pkill -f "node.*modal-login" 2>/dev/null || true
    sleep 3
    
    rm -f "$TARGET_DIR/swarm.pem"
    cp -f "$PEM_SOURCE" "$TARGET_DIR/"
    
    rm -rf "$TARGET_DIR/$LOGIN_SUBDIR/temp-data"
    cp -r "$TEMP_SOURCE" "$TARGET_DIR/$LOGIN_SUBDIR/"
    
    systemctl start rl-swarm
    
    # Cho userData.json xuat hien
    while [ ! -f "$TARGET_DIR/$LOGIN_SUBDIR/temp-data/userData.json" ]; do
        sleep 5
    done
    
    # Lay ORG_ID
    ORG_ID=$(awk 'BEGIN { FS = "\"" } !/^[ \t]*[{}]/ { print $(NF - 1); exit }' \
        "$TARGET_DIR/$LOGIN_SUBDIR/temp-data/userData.json")
    
    # Cho API key kich hoat
    while true; do
        STATUS=$(curl -s "http://localhost:3000/api/get-api-key-status?orgId=$ORG_ID")
        if [[ "$STATUS" == "activated" ]]; then
            break
        else
            sleep 5
        fi
    done
}

# Lan dau dung folder 1
echo "$(date) - Khoi dong lan dau, dung folder 1"
copy_and_restart 1

# Bat dau vong lap tu folder 2
CURRENT_INDEX=2
# Thoi gian cho toi da (10 phut)
TIMEOUT_SECONDS=600
last_detect_time=$(date +%s)

while true; do
    LOG_LAST=$(journalctl -u rl-swarm --since "10 seconds ago" -o cat)
    current_time=$(date +%s)
    
    if echo "$LOG_LAST" | grep -q "Joining round"; then
        last_detect_time=$current_time
        
        # Reset index neu vuot qua MAX_FOLDER truoc khi dung
        if (( CURRENT_INDEX > MAX_FOLDER )); then
            CURRENT_INDEX=1
        fis
        
        echo "$(date) - Phat hien Joining round, copy & restart voi folder $CURRENT_INDEX"
        copy_and_restart "$CURRENT_INDEX"
        ((CURRENT_INDEX++))
    else
        # Neu 10 phut khong phat hien Joining round thi chuyen index tiep
        if (( current_time - last_detect_time >= TIMEOUT_SECONDS )); then
            echo "$(date) - Khong phat hien Joining round trong 10 phut, chuyen sang thu muc $CURRENT_INDEX"
            
            # Reset index neu vuot qua MAX_FOLDER truoc khi dung
            if (( CURRENT_INDEX > MAX_FOLDER )); then
                CURRENT_INDEX=1
            fi
            
            copy_and_restart "$CURRENT_INDEX"
            ((CURRENT_INDEX++))
            last_detect_time=$current_time
        fi
    fi
    
    sleep 5
done
EOF

# Thay the REPLACE_USERNAME bang username thuc te
sed -i "s|REPLACE_USERNAME|$LOGNAME|g" /home/$LOGNAME/gensyn/run/auto.run

# Chmod executable
chmod +x /home/$LOGNAME/gensyn/run/auto.run

echo "Da tao file /home/$LOGNAME/gensyn/run/auto.run"
