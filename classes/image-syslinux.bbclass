# This class creates an image which is booted using syslinux.
#
# The image has an MSDOS partition table and comes with 3 or 4 partitions:
#  - a VFAT boot partition
#  - a primary rootfs partition
#  - a secondary rootfs partition
#  - an optional config/data partition

# This is the default WIC kickstart file we use. 
WKS_FILE ??= "homebox-syslinux.wks.in"

# These are the default partition sizes (in megabytes)
HOMEBOX_BOOTFS_SIZE ??= "64"
HOMEBOX_ROOTFS_SIZE ??= "512"
HOMEBOX_CONFFS_SIZE ??= "64"

# If the gen-config image feature is enabled create a /conf partition.
HOMEBOX_WIC_EXTRA_PARTITIONS = " \
  ${@bb.utils.contains('IMAGE_FEATURES', 'gen-config', \
                       '${HOMEBOX_WIC_CONFFS_PARTITION}', '', d)} \
"

HOMEBOX_WIC_ROOT_EXCLUDES = " \
  ${@bb.utils.contains('IMAGE_FEATURES', 'gen-config', \
                       '${HOMEBOX_WIC_CONFFS_EXCLUDE}', '', d)} \
"

# Produce WIC debug output.
WIC_CREATE_EXTRA_ARGS += " -D"

# Do not use the redundant '.rootfs' suffix.
IMAGE_NAME_SUFFIX = ""

SYSLINUX_TIMEOUT = "50"
SYSLINUX_PROMPT  = "1"
SYSLINUX_SERIAL_TTY = "console=ttyS0,38400"
SYSLINUX_SERIAL     = "0 38400"
SYSLINUX_ALLOWOPTIONS = "1"
INITRD = "${@('${DEPLOY_DIR_IMAGE}/' + \
    d.getVar('INITRD_IMAGE', expand=True) + \
        '-${MACHINE}.cpio.gz') \
    if d.getVar('INITRD_IMAGE', True) else ''}"

do_image_syslinux_prepare () {
    # This is just an empty synchronisation point, which
    # we misuse to depend on similar tasks for a couple of
    # things we need:
    #   - kernel
    #   - initrd
    :
}

do_image_syslinux_prepare[depends] += " \
    virtual/kernel:do_deploy \
    ${INITRD_IMAGE}:do_image_complete \
"

# Schedule task, but only if we're not building an initrd image.
python () {
    image_fstypes = d.getVar('IMAGE_FSTYPES', True)
    initramfs_fstypes = d.getVar('INITRAMFS_FSTYPES', True)

    # Don't add any of these tasks to initramfs images
    if initramfs_fstypes not in image_fstypes:
        bb.build.addtask('image_syslinux_prepare', 'do_image', 'do_rootfs', d)
}
