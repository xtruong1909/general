#!/bin/bash

# Cài đặt Openbox và TightVNC server
sudo apt install openbox tightvncserver -y

# Tạo thư mục và thiết lập mật khẩu VNC
mkdir -p ~/.vnc
echo "$PASSVNCSERVER" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Dừng VNC server nếu đang chạy
vncserver -kill :1

# Tạo file cấu hình xstartup
cat <<EOF > ~/.vnc/xstartup
#!/bin/sh

xrdb "$HOME/.Xresources"
xsetroot -solid "#ADD8E6"
export XKL_XMODMAP_DISABLE=1
/etc/X11/Xsession
xsetroot -cursor_name left_ptr &
openbox-session &
EOF

chmod +x ~/.vnc/xstartup

# Khởi động lại VNC server
vncserver :1100 -geometry 1100x710 -depth 24

wget -O grass.deb https://files.getgrass.io/file/grass-extension-upgrades/ubuntu-22.04/grass_4.28.2_amd64.deb
mkdir grass && cd grass
ar x /home/annie19/grass.deb
tar -xvzf control.tar.gz
sed -i 's/grass/getgrass/g' control
tar -czvf control.tar.gz control md5sums 
rm -rf control md5sums
rm -rf /home/annie19/grass.deb
ar rcs /home/annie19/grass.deb debian-binary control.tar.gz data.tar.gz
cd && rm -rf grass
sudo dpkg -i grass.deb
sudo apt --fix-broken install -y
sudo dpkg -i grass.deb

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome-stable_current_amd64.deb -y
rm -rf google-chrome-stable_current_amd64.deb
