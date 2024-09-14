#!/bin/bash
sudo apt install openbox tightvncserver -y && vncserver

# Password
mkdir -p ~/.vnc
echo "$PASSVNCSERVER" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

vncserver -kill :1

> ~/.vnc/xstartup
cat <<EOF >> ~/.vnc/xstartup
#!/bin/sh

xrdb "$HOME/.Xresources"
xsetroot -solid "#ADD8E6"
export XKL_XMODMAP_DISABLE=1
/etc/X11/Xsession
xsetroot -cursor_name left_ptr &
openbox-session &
EOF

chmod +x ~/.vnc/xstartup && vncserver :1 -geometry 1366x768 -depth 24

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

sudo apt install ./google-chrome-stable_current_amd64.deb -y && rm -rf google-chrome-stable_current_amd64.deb
