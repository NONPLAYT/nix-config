{ modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

  fileSystems."/" = { device = "/dev/disk/by-uuid/36518660-7611-4950-846e-70f8f0604c6f"; fsType = "ext4"; };
}
