#! /bin/bash

function INIT_config(){
    USERNAME=$1
    PASSWORD=$2

# BASIC PACKAGES
    echo "Installing basic packages..."
    apt install make -y > /dev/null
    apt install gcc -y > /dev/null
    apt install libcurses-dev -y > /dev/null
    apt install unattented-upgrades -y > /dev/null
    apt install ufw -y > /dev/null
    apt install fail2ban -y > /dev/null 

# VIM
    echo "Configuring vim..."
    git clone https://codeberg.org/yxm/vim-basic > /dev/null 
    mv vim-basic $HOME/.vim > /dev/null 

# ECL.SH
    echo "Installing ecl.sh..."
    echo "" > $HOME/.bashrc > /dev/null
    mkdir $HOME/.config > /dev/null
    cd $HOME/.config > /dev/null
    git clone https://github.com/yxm-dev/ecl.sh > /dev/null 
    echo "# INCLUDES" >> $HOME/.bashrc > /dev/null
    echo "" >> $HOME/.bashrc > /dev/null
    echo "source $HOME/.config/ecl.sh/ecl.sh" >> $HOME/.bashrc > /dev/null
    echo "" >> $HOME/.bashrc > /dev/null
    rm -r /user/share/bash-completion > /dev/null

# BASIC CONFIG
## timezone
    echo "Configuring timezone..."
    timedatectl set-timezone America/Sao_Paulo > /dev/null
## new sudo user
    echo "Creating and configuring sudo user $USERNAME..."
    useradd -m -s /bin/bash $USERNAME && echo "$USERNAME:$PASSWORD" | sudo chpasswd > /dev/null 
    usermod -a -G sudo $USERNAME > /dev/null 
## config new sudo user
    cp -r $HOME/.bashrc $HOME/.vim $HOME/.ssh $HOME/.config /home/$USERNAME > /dev/null
    sed -i "s/\/root\//\/home\/$USERNAME\//" $HOME/.bashrc > /dev/null
    chown -R $USERNAME /home/$USERNAME/.bashrc /home/$USERNAME/.vim /home/$USERNAME/.ssh /home/$USERNAME/.config > /dev/null
    chmod 700 /home/$USERNAME/.ssh/authorized_keys > /dev/null

# SECURITY
## set auto updates
    echo "Allowing automatic security updates..."
    dpkg-reconfigure unattended-upgrades > /dev/null
## set reboot after updates
    echo "Setting reboot after updates..."
    Unattended-Upgrade::Automatic-Reboot-Time "04:00"; > /dev/null
## firewall
    echo "Enabling firewal..."
    ufw allow ssh > /dev/null 
    ufw allow http > /dev/null 
    ufw allow https > /dev/null 
    ufw enable > /dev/null 
## block SSH access after multiple attempts
    echo "Configuting SSH to block IPs after multiple attempts..."
    service fail2ban start > /dev/null
## block login as root
    # ........

# SERVER
## install nginx
    echo "Installing Nginx..."
    add-apt-repository ppa:ondrej/nginx -y > /dev/null 
    apt update -y > /dev/null 
    apt dist-upgrade -y > /dev/null 
    apt install nginx -y > /dev/null 
## basic nginx config
    echo "Configuring Nginx..."
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
    echo "fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;" >> /etc/nginx/fastcgi_params > /dev/null
## restart nginx
    echo "Starting nginx service..."
    sudo service nginx restart > /dev/null

# DOCKER
## install docker
    echo "Installing docker..."
    apt-get update > /dev/null
    apt-get install ca-certificates curl -y > /dev/null
    install -m 0755 -d /etc/apt/keyrings > /dev/null
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc > /dev/null
    chmod a+r /etc/apt/keyrings/docker.asc > /dev/null
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update > /dev/null
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y > /dev/null
## allow $USERNAME use docker without sudo
    echo "Allowing $USERNAME to use docker without sudo..."
    groupadd docker > /dev/null
    usermod -aG docker $USERNAME > /dev/null
    newgrp docker > /dev/null
    if [[ -d /home/"$USERNAME"/.docker ]]; then
        chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/.docker -R > /dev/null
        chmod g+rwx "$HOME/$USERNAME/.docker" -R > /dev/null
    fi
## force docker daemon to run after reboot
    echo "Enabling docker..."
    sudo systemctl enable docker.service > /dev/null
    sudo systemctl enable containerd.service> /dev/null
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

