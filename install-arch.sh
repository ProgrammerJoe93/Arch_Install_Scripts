#!/bin/bash

INSTALLATION_DRIVE="/dev/nvme0n1" # Drive that Arch will be installed on
PARTITION=false                   # Whether to repartition INSTALLATION_DRIVE
FORMAT=false                      # Whether to format the partitions on INSTALLATION_DRIVE
FORMAT_HOME=false                 # Whether to format a separate home partition on INSTALLATION_DRIVE
# Size of each partition, Home will be the rest of the drive
PARTITION_EFI_SIZE="500M"
PARTITION_SWAP_SIZE="4G"
PARTITION_ROOT_SIZE="500G"
PARTITION_HOME=true               # Whether to have a separate home partition. If false, it's recommended to leave PARTITION_ROOT_SIZE blank
MOUNT_DATA="/dev/sda1"            # Mount an extra storage partition from another drive. Leave blank if none. This will not be partitioned/formatted
SCRIPT2_PATH="/data/install-arch/install-arch2.sh" # Path to the script that will run inside the new installation

# Set keyboard layout
loadkeys uk

# Get the time
timedatectl set-ntp true

# Format the disk
if [ $PARTITION ]
then
    (
        echo g                     # Create GPT table
        # EFI partition
        echo n                     # New partition
        echo                       # Use default partition number (1)
        echo                       # Use default first sector
        echo +$PARTITION_EFI_SIZE  # Set partition size
        echo t                     # set the type
        echo 1                     # EFI System type
        # Swap partition
        echo n                     # New partition
        echo                       # Use default partition number (2)
        echo                       # Use default first sector
        echo +$PARTITION_SWAP_SIZE # Set partition size
        echo t                     # set the type
        echo 19                    # Linux Swap type
        # Root partition
        echo n                     # New partition
        echo                       # Use default partition number (3)
        echo                       # Use default first sector
        echo +$PARTITION_ROOT_SIZE # Set partition size
        echo t                     # set the type
        echo 23                    # Linux root (x86-64) type
        # Home partition
        if [ $PARTITION_HOME ]
        then
            echo n                 # New partition
            echo                   # Use default partition number (4)
            echo                   # Use default first sector
            echo                   # Size will be the rest of the drive
            echo t                 # set the type
            echo 28                # Linux home type
        fi
        # Commit the changes
        echo w                     # Write out
    ) | fdisk $INSTALLATION_DRIVE
fi

P1="p1" # EFI partition
P2="p2" # Swap partition
P3="p3" # Root partition
P4="p4" # Home partition

# Format the partitions
echo "##### Format partitions #####"
if [ $FORMAT ]
then
    mkfs.fat -F 32 $INSTALLATION_DRIVE$P1 # EFI as FAT32
    mkswap $INSTALLATION_DRIVE$P2         # Swap
    (
        echo y
    ) | mkfs.ext4 $INSTALLATION_DRIVE$P3  # Root as EXT4
fi
if [ $FORMAT_HOME && $PARTITION_HOME ]
then
    mkfs.ext4 $INSTALLATION_DRIVE$P4      # Home as EXT4
fi

# Mount partitions
echo "##### Mount root #####"
mount $INSTALLATION_DRIVE$P3 /mnt
echo "##### Mount boot #####"
mkdir /mnt/boot
mount $INSTALLATION_DRIVE$P1 /mnt/boot
if [ $PARTITION_HOME ]
then
    echo "##### Mount home #####"
    mkdir /mnt/home
    mount $INSTALLATION_DRIVE$P4 /mnt/home
fi
if [ $MOUNT_DATA != "" ]
then
    echo "##### Mount data #####"
    mkdir /mnt/data
    mount $MOUNT_DATA /mnt/data
fi

echo "##### Turn on swap #####"
swapon $INSTALLATION_DRIVE$P2

# Install the initial packages
echo "##### Install initial packages #####"
pacstrap /mnt base base-devel linux linux-headers linux-firmware

# Generate fstab
echo "##### Generate fstab #####"
genfstab -U /mnt >> /mnt/etc/fstab

# Switch to the new installation
echo "##### Switch to new installation #####"
(
    echo "sh $SCRIPT2_PATH"
) | arch-chroot /mnt

echo "##### Rebooting #####"
# umount -a
# reboot
