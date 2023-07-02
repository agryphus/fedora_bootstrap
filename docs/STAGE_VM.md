# Arch Encrypted Install Guide for VirtualBox

These are installation instructions intended for my personal use and reference.  However, others may find use.

I am running Arch Linux, currently, inside of a VirtualBox instance, so the guide will be tailored towards this type of setup.

---

## Creating the VM

I create the VM using the liveboot iso image found at: https://archlinux.org/download/.  Set the specs of the machine to your liking.

I also prefer to setup the machine with the classic boot loader as opposed to virtualizing an efi machine, because why would I want to deal with that.

---

## Inside the Installation Medium.

I followed the official installation guide found at: https://wiki.archlinux.org/title/installation_guide.  Deviations or specifications are listed below, and if a clarification is not present, it's probably obvious from the installation guide.

### 1.9: Partition the Disk

**For the love of God**: In a fresh VirtualBox VM, the main disk will always be *sda*.  Check the drive name of the space you want to install Arch to with *lsblk* and don't overwrite your system if your setup is different.

I create two partitions of sda using fdisk: sda1 with 200MB for the boot partition and sda2 with the remaining space.  The boot partition is set to fat32.  The remaining space is encrypted with 

    $ cryptsetup luksFormat /dev/sda2

After this, run

    $ cryptsetup open /dev/sda2 <name>

on the partition to see the decrypted space.  The \<name\> parameter can be anything, and will be reflected in /dev/mapper/\<name\>.  For the rest of this, I will assume a drive name of *crypt*.

At this point, format the drive to *btrfs* using *mkfs* as such

    $ mkfs.btrfs /dev/mapper/crypt

### 1.11: Mount the system

    $ mount /dev/mapper/crypt /mnt
    $ mkdir /mnt/boot
    $ mount /dev/sda1 /mnt/boot

Pretty straight forward.

### 2.2: Install essential packages

    $ pacstrap -K /mnt base linux linux-firmware networkmanager vim cryptsetup lvm2 grub sudo virtualbox-guest-utils man-db man-pages texinfo

I chose networkmanager as my means of connecting to the internet.  The Arch ISO currently ships with dhcpcd, and installs systemd-networkd in base, but according to this issue thread: https://gitlab.archlinux.org/archlinux/archiso/-/issues/187, it looks like the Arch ISO might come with networkmanager in future releases.

Cryptsetup and lvm2 are required for the encrpytion setup that we currently have.

The virtualbox-guest-utils package allows for mounting the Windows C drive.  Automounting works on the liveboot ISO, but not in the full install.

---

## After chroot-ing Into the OS

### 3.5 Network configuration

From the VM's perspective, it has a wired connection to the host, so there does not need to be any fiddling with wireless connections.  To enable this wired connection, execute:

    $ systemctl enable NetworkManager.service

Now the Network Manager will start on boot and internet should work.

### 3.6: Initramfs

On boot, the crypt hooks need to be added so that it can properly prompt for drive decryption.  Go to /etc/mkinitcpio.conf and add *encrypt* and *lvm2* to the HOOKS list.  After this, now run:

    $ mkinitcpio -P

### 3.7: Root password

I choose to run a setup where root has no password, and there is instead a main user with sudo privaledges, hence why sudo was pacstrapped.  To allow for this, uncomment this line from /etc/sudoers

    %wheel ALL=(ALL:ALL) ALL

To allow the initial login into the machine, the initial root password will simply be "password", and then quickly unset with my bootstrapping script.

### 3.8: Boot loader

I use grub as a bootloader.  Setting it up is fairly straightforward.

Get the UUID of both the encrypted drive, and its unencrypted space using "lsblk -f" (you may have to back out to the live boot ISO to see this information).  In /etc/default/grub, append the foollowing to GRUB_CMDLINE_LINUX_DEFAULT:

    cryptdevice=UUID=<crypt UUID>:crypt root=UUID=<decrypt UUID>

Now run the following:

    grub-install /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg

---

## Extra Configuration

This section contains some final configuration before the VM box is ready.  

### Auto-Mounting The C Drive

1. Go into the Shared Folders section of VirtualBox and create a new shared machine folder.  Link to the windows C drive, and name the folder C_DRIVE.  The Arch mount point is technically arbitrary since VirtualBox doesn't want to actually automount it for some reason and we are about to do that manually, but for sake of consistency, mount it to /mnt/c

2. Create the /mnt/c directory

3. Create a bash script with the following lines:

        #!/bin/bash
        mount -t vboxsf -o rw,uid=$(id -u),gid=$(id -g) C_DRIVE /mnt/c

4. Make the script executable (chmod 755 \<scirpt\>) and throw it in /usr/bin/

5. Create a new file *mountc.service* in /etc/systemd/system/ containing the following:

        [Unit]
        Description=Mounts the Windows C Drive

        [Service]
        ExecStart=/usr/bin/<script>

        [Install]
        WantedBy=multi-user.target 

6. Run

        $ systemctl enable mountc.service

### Remove the Installation Disk from the Virtual Machien

If the installation disk is not removed in VirtualBox, then there will be an extra screen to pass through before booting into the OS.

---

## Miscellaneous

### Resizing the File System

Resizing the main partition is surprisingly painless.  Simply use the Virtual Media Manager (unles File > Tools) in Virtual Box to expand the virtual disk, and use fdisk to remove the desired partition, and make a new one with a larger size.  I've done this live on the partition, without livebooting back into the Arch ISO, and it worked fine.  Fdisk will ask if you want to remove the luks signature -- keep it -- and then use "cryptsetup resize /dev/mapper/crypt" to automatically expand the crypt volume to fill the partiition.
