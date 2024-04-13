#! /bin/bash

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

function INIT_config(){
    USERNAME=$1
    PASSWORD=$2
    
# BASIC PACKAGES
    apt install \
## for dev
        make \
        gcc \
        libncurses-dev \
## security
        unattended-upgrades \
        ufw \
        fail2ban -y

# VIM
    git clone https://codeberg.org/yxm/vim-basic
    mv vim $HOME/.vim

# ECL.SH
    echo "" > $HOME/.bashrc
    mkdir $HOME/.config
    cd $HOME/.config
    git clone https://github.com/yxm-dev/ecl.sh
    echo "# INCLUDES" >> $HOME/.bashrc
    echo "" >> $HOME/.bashrc
    echo "source $HOME/.config/ecl.sh/ecl.sh" >> $HOME/.bashrc
    echo "" >> $HOME/.bashrc
    rm -r /user/share/bash-completion

# BASIC CONFIG
## timezone
    timedatectl set-timezone America/Sao_Paulo
## new sudo user
    useradd -m -s /bin/bash $USERNAME && echo "$USERNAME:$PASSWORD" | sudo chpasswd
    usermod -a -G sudo $USERNAME
## config new sudo user
    cp -r $HOME/.bashrc $HOME/.vim $HOME/.ssh $HOME/.config /home/$USERNAME
    chown -R $USERNAME /home/$USERNAME/.bashrc /home/$USERNAME/.vim /home/$USERNAME/.ssh /home/$USERNAME/.config
    chmod 700 /home/$USERNAME/.ssh/authorized_keys

# SECURITY
## set auto updates 
    echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true" | sudo debconf-set-selections && sudo dpkg-reconfigure -f noninteractive unattended-upgrades
## set reboot after updates
    Unattended-Upgrade::Automatic-Reboot-Time "04:00";
## firewall
    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw enable
## block SSH access after multiple attempts
    service fail2ban start
## block login as root
    # ........

# SERVER
## install nginx
    add-apt-repository ppa:ondrej/nginx -y
    apt update
    apt dist-upgrade -y
    apt install nginx -y
## basic nginx config
    cp nginx.conf /etc/nginx/nginx.conf
    declare -i CPU
    declare -i ULIMIT
    CPUs=$(grep processor /proc/cpuinfo | wc -l)
    ULIMIT=$(ulimit -n)
    WORKERS=$(( CPUs * ULIMIT ))
    TIMEOUT=15
    sed -i "s/<CPUs>/$CPUs/g" /etc/nginx/nginx.conf
    sed -i "s/<WORKERS>/$WORKERS/g" /etc/nginx/nginx.conf
    sed -i "s/<TIMEOUT>/$TIMEOU/g" /etc/nginx/nginx.conf
## add fastcgi
    echo "fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;" >> /etc/nginx/fastcgi_params
## restart nginx
    sudo service nginx restart
    
# DOCKER
## install docker
    apt-get update
    apt-get install ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
## allow $USERNAME use docker without sudo
    groupadd docker
    usermod -aG docker $USERNAME
    newgrp docker
    if [[ -d /home/"$USERNAME"/.docker ]]; then
        chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/.docker -R
        chmod g+rwx "$HOME/$USERNAME/.docker" -R
    fi
## force docker daemon to run after reboot
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
}
