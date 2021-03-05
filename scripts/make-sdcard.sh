#! /bin/bash

# TODO find latest image at https://downloads.raspberrypi.org/raspios_lite_armhf/images/

if [ "$#" -ne 3 ]; then
    echo "Usage: make-sdcard.sh <device> <hostname> <pubkey>"
    exit 1
fi

CARD_DEVICE=$1
PI_HOSTNAME=$2
SSH_KEY_FILE=$3
echo "Writing to ${CARD_DEVICE} to create ${PI_HOSTNAME}"

# TODO find most recent image automatically from https://downloads.raspberrypi.org/raspios_lite_armhf/images/
LATEST_IMAGE_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-01-12/2021-01-11-raspios-buster-armhf-lite.zip"
LATEST_IMAGE_FILENAME="2021-01-11-raspios-buster-armhf-lite.zip"

if [ ! -f $LATEST_IMAGE_FILENAME ]; then
    wget $LATEST_IMAGE_URL
else
    echo "${LATEST_IMAGE_FILENAME} already downloaded"
fi

# check whether filesystem on card is already mounted and unmount it
MOUNTS=$(cat /proc/mounts | grep $CARD_DEVICE | cut -d " " -f1)
for mdev in $MOUNTS
do
    echo "Mounted filesystem on ${mdev} - unmounting"
    sudo umount $mdev
done

echo "Writing image to $CARD_DEVICE"
unzip -p $LATEST_IMAGE_FILENAME | sudo dd bs=4M of=$CARD_DEVICE iflag=fullblock oflag=direct status=progress
sync

# The new filesystems may be mounted automatically by Linux check and mount if not
# boot filesystem
if grep -q ${CARD_DEVICE}1 /proc/mounts ; then
    BOOT_MOUNTPOINT=$(cat /proc/mounts | grep ${CARD_DEVICE}1 | cut -d " " -f2)
else
    tmp_mnt=$(mktemp -d)
    BOOT_MOUNTPOINT=${tmp_mnt}/boot
    mkdir -p $BOOT_MOUNTPOINT
    sudo mount ${CARD_DEVICE}1 $BOOT_MOUNTPOINT
fi

# root filesystem
if grep -q ${CARD_DEVICE}2 /proc/mounts ; then
    ROOT_MOUNTPOINT=$(cat /proc/mounts | grep ${CARD_DEVICE}2 | cut -d " " -f2)
else
    tmp_mnt=$(mktemp -d)
    ROOT_MOUNTPOINT=${tmp_mnt}/boot
    mkdir -p $ROOT_MOUNTPOINT
    sudo mount ${CARD_DEVICE}2 $ROOT_MOUNTPOINT
fi


echo "Boot mounted at ${BOOT_MOUNTPOINT}, rootfs at ${ROOT_MOUNTPOINT}"

# enable ssh
echo "Enabling SSH"
sudo touch ${BOOT_MOUNTPOINT}/ssh

# change hostname
# https://raspberrypi.stackexchange.com/questions/116565/how-to-change-host-name-before-first-boot
CURRENT_HOSTNAME=$(cat ${ROOT_MOUNTPOINT}/etc/hostname)
if [ $PI_HOSTNAME = $CURRENT_HOSTNAME ]; then
    echo "Name already set"
else
    echo "Setting Name" $PI_HOSTNAME
    sudo chmod 666 ${ROOT_MOUNTPOINT}/etc/hostname
    sudo chmod 666 ${ROOT_MOUNTPOINT}/etc/hosts
    sudo echo $PI_HOSTNAME > ${ROOT_MOUNTPOINT}/etc/hostname
    sudo sed -i "/127.0.1.1/s/$CURRENT_HOSTNAME/$PI_HOSTNAME/" ${ROOT_MOUNTPOINT}/etc/hosts
    sudo chmod 644 ${ROOT_MOUNTPOINT}/etc/hostname
    sudo chmod 644 ${ROOT_MOUNTPOINT}/etc/hosts
fi

# set up SSH key
# https://www.raspberrypi.org/forums/viewtopic.php?t=212480
echo "Setup SSH key"
sudo mkdir -p -m 700 ${ROOT_MOUNTPOINT}/home/pi/.ssh
sudo cp $SSH_KEY_FILE ${ROOT_MOUNTPOINT}/home/pi/.ssh/authorized_keys
sudo chown -R 1000:1000 ${ROOT_MOUNTPOINT}/home/pi/.ssh/

echo "Unmounting disks"
sudo umount $ROOT_MOUNTPOINT
sudo umount $BOOT_MOUNTPOINT
