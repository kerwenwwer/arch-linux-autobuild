step1(){
    read -p "hostname: " hostname
    read -p "username: " username
    read -p "password: " password
    echo 'Configure mirrorlist ...'
    mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    echo 'Server = http://archlinux.cs.nctu.edu.tw/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
    echo 'Server = http://shadow.ind.ntou.edu.tw/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
    echo 'Server = http://ftp.tku.edu.tw/Linux/ArchLinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
    echo 'Server = http://ftp.yzu.edu.tw/Linux/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist

    echo 'Install ArchLinux ...'
    pacstrap /mnt base base-devel

    echo 'Generate fstab ...'
    genfstab -p -U /mnt >> /mnt/etc/fstab

    #chroot
    cp $0 /mnt/archlinux-install.sh
    arch-chroot /mnt bash /archlinux-install.sh --config $hostname $username $password
    rm /mnt/archlinux-install.sh
    echo 'System installed. Please reboot.'
    exit
}

step2(){
    echo 'Configure pacman ...'
    sed -i '/^#\[multilib\]$/{N;s/#//g;P;D;}' /etc/pacman.conf
    echo 'Configure yaourt ...'
    # yaourt 
    echo '[archlinuxfr]' >> /etc/pacman.conf
    echo 'SigLevel = Never' >> /etc/pacman.conf
    echo 'Server = http://repo.archlixnux.fr/$arch' >> /etc/pacman.conf
    echo '[archlinuxcn]' >> /etc/pacman.conf
	echo 'SigLevel = Never' >> /etc/pacman.conf
	echo 'Server = http://cdn.repo.archlinuxcn.org/$arch' >> /etc/pacman.conf
	echo 'Install base shell packages ...'

    pacman -Sy  gedit vim net-tools wireless_tools dhclient wpa_supplicant grub os-prober efibootmgr intel-ucode 
	
	echo 'Install user desktop packages ...'

	pacman -Sy xorg-xinit xfce4 xfce4-goodies firefox fcitx fcitx-im arc-gtk-theme cpupower i7z qt4 qt5-base  
	yaourt -S xscreensaver-arch-logo

    echo 'Change system limit ...'
    echo '*               -       nofile          10000' >> /etc/security/limits.conf

    echo 'Configure sudo ...'
    sed -i 's/^# \(%wheel ALL=(ALL) ALL\)$/\1/' /etc/sudoers

    echo 'Configure network ...'
    echo '$hostname' > /etc/hostname
    echo '127.0.0.1  $hostname.localdomain  $hostname' >> /etc/hosts
    systemctl enable NetworkManager	
    echo 'nameserver 1.1.1.1' > /etc/resolv.conf #cloudfare dns
    echo 'nameserver 1.0.0.1' >> /etc/resolv.conf
    echo 'Configure time ...'
    # set locale time
    ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
    # start ntp systemd unit
    echo 'Start systemd unit' 	
    #systemctl enable ntpd.service


    echo 'Configure Locale ...'
    mv /etc/locale.gen /etc/locale.gen.bak
    echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
    echo 'zh_TW.UTF-8 UTF-8' >> /etc/locale.gen
    echo 'ja_JP.UTF-8 UTF-8' >> /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf

    echo 'Configure IME ...'
    echo 'LANG=zh_TW.UTF-8' >> /etc/skel/.xprofile
    echo 'export GTK_IM_MODULE=fcitx' >> /etc/skel/.xprofile
    echo 'export QT_IM_MODULE=fcitx' >> /etc/skel/.xprofile
    echo 'export XMODIFIERS=@im=fcitx' >> /etc/skel/.xprofile
		

    echo 'Creating boot image ...'
    mkinitcpio -p linux

    echo 'Create user account'
    useradd -m -u 1001 $username 
    echo "$username:$password" |chpasswd
    usermod $username -G wheel

	echo 'Configure Xorg'
	cd /home/$username
	touch .xinitrc
	echo 'exec startxfce4' >> ~/.xinitrc
	echo 'export GTK_IM_MODULE=fcitx' >> ~/.xinitrc
    echo 'export QT_IM_MODULE=fcitx' >> ~/.xinitrc
    echo 'export XMODIFIERS=@im=fcitx' >> ~/.xinitrc




    echo 'Configure Grub:'
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
    grub-mkconfig -o /boot/grub/grub.cfg
	systemctl enable dhcpcd.service
	exit
}

if [ $# != 0 ] && [ "$1" == "--config" ]; then
    hostname=$2
    username=$3
    password=$4
    step2;
else
    step1;
fi

