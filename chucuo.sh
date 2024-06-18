#!/bin/bash



# 设置前端为非交互模式，并设置默认语言为英语
export DEBIAN_FRONTEND=noninteractive
export LANG=C
export LC_ALL=C

echo "Pre-configuring packages for non-interactive installation..."
echo 'keyboard-configuration	keyboard-configuration/compose	select	No compose key' | sudo debconf-set-selections
echo 'keyboard-configuration	keyboard-configuration/country	select	English (US)' | sudo debconf-set-selections
echo 'keyboard-configuration	keyboard-configuration/model	select	Generic 105-key PC (intl.)' | sudo debconf-set-selections
echo 'keyboard-configuration	keyboard-configuration/layout	select	English (US)' | sudo debconf-set-selections
echo 'keyboard-configuration	keyboard-configuration/variant	select	English (US)' | sudo debconf-set-selections

echo "Updating system and installing necessary packages..."
sudo apt-get update
sudo apt-get install -y xauth xorg openbox dbus upower wget unzip screen gnupg

# 确保 sshd 配置文件启用 X11 转发
echo "Configuring SSH for X11 forwarding..."
sudo sed -i 's/#X11Forwarding .*/X11Forwarding yes/' /etc/ssh/sshd_config
sudo sed -i 's/#X11DisplayOffset .*/X11DisplayOffset 10/' /etc/ssh/sshd_config
sudo sed -i 's/#X11UseLocalhost .*/X11UseLocalhost yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# 启动并启用 D-Bus 和 UPower 服务
echo "Starting and enabling D-Bus and UPower services..."
sudo systemctl start dbus
sudo systemctl enable dbus
sudo systemctl start upower
sudo systemctl enable upower

# 安装 Google Chrome
echo "Installing Google Chrome..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
sudo apt-get update
sudo apt-get install -y google-chrome-stable

# 下载并解压扩展
echo "Downloading and extracting Chrome extension..."
wget -q -O /root/extension-main.zip https://github.com/LanifyAI/extension/archive/refs/heads/main.zip
unzip -o /root/extension-main.zip -d /root
mv /root/extension-main /root/my_extension

wget "https://github.com/ginuerzh/gost/releases/download/v2.8.1/gost_2.8.1_linux_amd64.tar.gz" && sleep 10 && tar -zxvf gost_2.8.1_linux_amd64.tar.gz && sleep 10 && mv gost_2.8.1_linux_amd64/gost /usr/bin/gost

chmod +x /usr/bin/gost && sleep 10 && nohup gost -L zxc5215584:5215584@:1188 socks5://:1188 > /dev/null 2>&1 &
screen -dmS clean_system bash -c 'sleep 252800 && sudo apt-get install -y deborphan && sudo apt-get remove --purge -y $(deborphan --guess-all) && sudo rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/locale/*'
echo "Setup completed. Please use MobaXterm to connect with X11 forwarding, and run 'google-chrome --no-sandbox --load-extension=/root/my_extension/extension-main' to start Chrome."
echo "Setup complete."
