#! /bin/bash

function INIT_config(){
    USERNAME=$1
    PASSWORD=$2

# BASIC PACKAGES
    echo "> Upgrading the system..."
    apt-get update > /dev/null 2>&1
    apt-get upgrade > /dev/null 2>&1
    apt-get dist-upgrade > /dev/null 2>&1
    echo "==> Installing basic packages..."
    apt-get -y install make > /dev/null 2>&1
    apt-get -y install gcc > /dev/null 2>&1
    apt-get -y install libncurses-dev  > /dev/null 2>&1
    apt-get -y install unattended-upgrades > /dev/null 2>&1
    apt-get -y install ufw > /dev/null 2>&1
    apt-get -y install fail2ban > /dev/null 2>&1

# VIM
    echo "==> Installing Vim 9.0..."
    apt-get -y remove vim > /dev/null 2>&1
    apt-get -y autoremove > /dev/null 2>&1
    git clone https://github.com/vim/vim.git > /dev/null 2>&1
    cd vim/src
    ./configure > /dev/null 2>&1
    make > /dev/null 2>&1
    make install /dev/null 2>&1
    cd ../../
    rm -r vim
    echo "==> Configuring Vim..."
    git clone https://codeberg.org/yxm/vim-basic > /dev/null 2>&1
    mv vim-basic /root/.vim > /dev/null 2>&1 

# ECL.SH
    echo "==> Installing ecl.sh..."
    echo "" > /root/.bashrc    
    mkdir /root/.config > /dev/null 2>&1
    cd /root/.config > /dev/null 2>&1
    git clone https://github.com/yxm-dev/ecl.sh > /dev/null 2>&1 
    echo "# INCLUDES" >> /root/.bashrc
    echo "" >> $HOME/.bashrc
    echo "source $HOME/.config/ecl.sh/ecl.sh" >> $HOME/.bashrc
    echo "" >> $HOME/.bashrc
    rm -r /usr/share/bash-completion > /dev/null 2>&1

# BASIC CONFIG
## timezone
    echo "==> Configuring timezone..."
    timedatectl set-timezone America/Sao_Paulo > /dev/null 2>&1
## new sudo user
    echo "==> Creating and configuring sudo user $USERNAME..."
    useradd -m -s /bin/bash $USERNAME && echo "$USERNAME:$PASSWORD" | sudo chpasswd > /dev/null 2>&1
    usermod -a -G sudo $USERNAME > /dev/null 2>&1 
## config new sudo user
    cp -r $HOME/.bashrc $HOME/.vim $HOME/.ssh $HOME/.config /home/$USERNAME > /dev/null 2>&1
    sed -i "s/\/root\//\/home\/$USERNAME\//" $HOME/.bashrc > /dev/null 2>&1
    chown -R $USERNAME /home/$USERNAME/.bashrc /home/$USERNAME/.vim /home/$USERNAME/.ssh /home/$USERNAME/.config > /dev/null 2>&1
    chmod 700 /home/$USERNAME/.ssh/authorized_keys > /dev/null 2>&1

# SECURITY
## set auto updates
    echo "==> Allowing automatic security updates..."
    dpkg-reconfigure unattended-upgrades
## set reboot after updates
    echo "==> Setting reboot after updates..."
    Unattended-Upgrade::Automatic-Reboot-Time "04:00"; > /dev/null
## firewall
    echo "==> Enabling the firewall..."
    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw enable
## block SSH access after multiple attempts
    echo "==> Configuting SSH to block IPs after multiple attempts..."
    service fail2ban start > /dev/null
## block login as root
    # ........

# SERVER
## install nginx
    echo "==> Installing Nginx..."
    add-apt-repository ppa:ondrej/nginx -y > /dev/null 2>&1 
    apt-get update -y > /dev/null 2>&1 
    apt-get dist-upgrade -y  > /dev/null 2>&1 
    apt-get install nginx -y > /dev/null 2>&1 
## basic nginx config
    echo "==> Configuring Nginx..."
    cp nginx.conf /etc/nginx/nginx.conf > /dev/null 
    declare -i CPU > /dev/null 
    declare -i ULIMIT > /dev/null 
    CPUs=$(grep processor /proc/cpuinfo | wc -l) > /dev/null 
    ULIMIT=$(ulimit -n) > /dev/null 
    WORKERS=$(( CPUs * ULIMIT )) > /dev/null 
    TIMEOUT=15 > /dev/null 
    sed -i "s/<CPUs>/$CPUs/g" /etc/nginx/nginx.conf > /dev/null 
    sed -i "s/<WORKERS>/$WORKERS/g" /etc/nginx/nginx.conf > /dev/null 
    sed -i "s/<TIMEOUT>/$TIMEOU/g" /etc/nginx/nginx.conf > /dev/null 
## add fastcgi
    echo "> fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;" >> /etc/nginx/fastcgi_params > /dev/null
## restart nginx
    echo "==> Starting nginx service..."
    sudo service nginx restart > /dev/null

# DOCKER
## install docker
    echo "==> Installing docker..."
    apt-get install ca-certificates curl -y > /dev/null 2>&1
    install -m 0755 -d /etc/apt/keyrings > /dev/null 2>&1
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc > /dev/null 2>&1
    chmod a+r /etc/apt/keyrings/docker.asc > /dev/null 2>&1
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1
    apt-get -y update > /dev/null 2>&1
    apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
## allow $USERNAME use docker without sudo
    echo "==> Allowing $USERNAME to use docker without sudo..."
    groupadd docker > /dev/null 2>&1
    usermod -aG docker $USERNAME > /dev/null 2>&1
    newgrp docker > /dev/null 2>&1
    if [[ -d /home/"$USERNAME"/.docker ]]; then
        chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/.docker -R > /dev/null 2>&1
        chmod g+rwx "$HOME/$USERNAME/.docker" -R > /dev/null 2>&1
    fi
## force docker daemon to run after reboot
    echo "==> Enabling docker..."
    sudo systemctl enable docker.service > /dev/null 2>&1
    sudo systemctl enable containerd.service> /dev/null 2>&1
}

# BEGIN OF INIT SCRIPT

echo "Enter the username of the new sudo user:"
while : 
do
    read -e -r -p "> " USERNAME
    if [[ -n "$USERNAME" ]]; then
        echo "Enter the password for the new sudo user:"
        while :
        do
            read -e -r -p "> " PASSWORD
            if [[ -n "$USERNAME" ]]; then
                INIT_config $USERNAME $PASSWORD
                break
            else
                echo "Please, enter a password:"
                continue
            fi
        done
        break
    else
        echo "Please, enter a username:"
        continue
    fi
done

