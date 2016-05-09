#!/bin/bash
#set timezone
dpkg-reconfigure tzdata
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8
printf "Please enter username: "
read -r USERNAME
printf "Please enter public-ssh-key: "
read -r AUTHORIZED_KEY
printf "Please enter webdav username: "
read -r WEBDAV_USER
printf "Please enter webdav password: "
read -r WEBDAV_PASSWORD
#update
apt-get update
apt-get upgrade
#install sudo
apt-get install sudo davfs2
useradd $USERNAME -G sudo -s /bin/bash -m -d /home/sayra
passwd $USERNAME
#ssh
mkdir ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
echo $AUTHORIZED_KEY >> ~/.ssh/authorized_keys
sed -i -e 's/PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config
sed -i -e 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config
sed -i -e 's/Subsystem sftp \/usr\/lib\/openssh\/sftp-server/#Subsystem sftp \/usr\/lib\/openssh\/sftp-server/g' /etc/ssh/sshd_config
echo "Subsystem sftp internal-sftp
Match Group sftponly
        ChrootDirectory %h
        ForceCommand internal-sftp
        AllowTcpForwarding yes" >> /etc/ssh/sshd_config
echo "AllowUsers root" >> /etc/ssh/sshd_config
groupadd sftponly
#webdav
chmod u+s /usr/sbin/mount.davfs
mkdir -p /media/webdav
echo "https://webdav.yandex.com.tr    /media/webdav  davfs noauto,user 0 0" >> /etc/fstab
usermod -a -G davfs2 root
usermod -a -G davfs2 $USERNAME
echo "/media/webdav $WEBDAV_USER $WEBDAV_PASSWORD" >> /etc/davfs2/secrets
#backup script
cat <<EOF > backup.sh
#!/bin/bash

DATE=`date +"%d-%m-%Y_%H.%M"`

7z a -mx9 -mmt /var/backups/etc/$DATE/nginx.7z /etc/nginx
7z a -mx9 -mmt /var/backups/etc/$DATE/php5.7z /etc/php5

for folder in /var/www/*
    do
        7z a -mx9 -mmt "/var/backups/www/$DATE/$(basename $folder).7z" "$folder"
    done
EOF
cat <<EOF > backupwebdav.sh
#!/bin/bash
mount /media/webdav

#www
backupsource=$(ls -td /var/backups/www/* | head -1)
backupdestination='/media/webdav/backups/www'

mkdir $backupdestination -p
cp $backupsource -R --remove-destination -r -f $backupdestination

#etc
backupsource=$(ls -td /var/backups/etc/* | head -1)
backupdestination='/media/webdav/backups/etc'

mkdir $backupdestination -p
cp $backupsource -R --remove-destination -r -f $backupdestination

#automysqlbackup
backupsource='/var/backups/automysqlbackup'
backupdestination='/media/webdav/backups/automysqlbackup'

mkdir $backupdestination -p
cp $backupsource -R --remove-destination -r -f $backupdestination
EOF
cat <<EOF > /root/cleanbackup.sh
#!/bin/bash
find /var/backups/etc/* -type d -mtime +10 -name *_04.00 -exec rm -R {} \;
find /var/backups/www/* -type d -mtime +10 -name *_04.00 -exec rm -R {} \;
EOF
cat <<EOF > /root/cleanbackupwebdav.sh
#!/bin/bash
mount /media/webdav
find /media/webdav/etc/* -type d -mtime +60 -name *_04.00 -exec rm -R {} \;
find /media/webdav/www/* -type d -mtime +60 -name *_04.00 -exec rm -R {} \;
EOF
cat <<EOF > /root/cleanlog.sh
#!/bin/bash
find /var/log/*.gz -exec rm {} \;
find /var/log/*.1 -exec rm {} \;
find /var/log/nginx/*.gz -exec rm {} \;
find /var/log/nginx/*.1 -exec rm {} \;
find /var/log/exim4/*.gz -exec rm {} \;
find /var/log/mysql/*.gz -exec rm {} \;
EOF
chmod u+x /root/cleanbackup.sh
chmod u+x /root/cleanbackupwebdav.sh
chmod u+x /root/backup.sh
chmod u+x /root/backupwebdav.sh
chmod u+x /root/cleanlog.sh
cat <(crontab -l) <(echo "30 03 * * * /root/cleanbackup.sh") | crontab -
cat <(crontab -l) <(echo "00 04 * * * /root/backup.sh") | crontab -
cat <(crontab -l) <(echo "0 0 * * 0 /root/cleanbackupwebdav.sh") | crontab -
cat <(crontab -l) <(echo "0 0 * * 0 /root/backupwebdav.sh") | crontab -
cat <(crontab -l) <(echo "0 0 * * 0 /root/cleanlog.sh") | crontab -
#swap installation
#touch /var/swap.img
#chmod 600 /var/swap.img
#dd if=/dev/zero of=/var/swap.img bs=1024k count=1000
#mkswap /var/swap.img
#echo "/var/swap.img    none    swap    sw    0    0" >> /etc/fstab
#sysctl -w vm.swappiness=30
service ssh restart
rm install-webserver-root.sh
