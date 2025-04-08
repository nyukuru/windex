{
  config,
  pkgs,
  lib,
  packages,
  ...
}: let
  inherit
    (lib.options)
    mkEnableOption
    mkOption
    ;

  inherit
    (lib.modules)
    mkDefault
    mkIf
    ;

  inherit
    (lib.strings)
    concatStringsSep
    ;

  inherit
    (lib.types)
    strMatching
    package
    listOf
    enum
    str
    ;

  packages = packages.${builtins.currentSystem};
  cfg = config.windex;
in {
  options.windex = {
    enable = mkEnableOption "Windex, easy windows vm manager";
    image = mkOption {
      type = package;
      default = packages.windex-image;
      description = "Windows image ran by the runner";
    };

    cpu = mkOption {
      type = enum ["amd" "intel"];
      description = "CPU architecture of the host machine.";
    };

    vfio = {
      user = mkOption {
        type = str;
        description = "";
      };

      deviceIds = mkOption {
        type = listOf (strMatching "([0-9a-f]{4}:[0-9a-f]{4})?");
        default = [];
        description = "IOMMU Device Ids to be handed over to VFIO";
      };
    };

    lookingGlass = {
      enable = mkEnableOption "Looking glass auto-configuration";
      group = mkOption {
        type = str;
        default = "qemu-libvirtd";
        description = "Group with access to the looking glass client.";
      };
    };
  };

  config = mkIf cfg.enable {
    boot = {
      kernelModules = [
        "kvm-${cfg.cpu}"
        "vfio-virqfd"
        "vfio_pci"
        "vfio_iommu_type1"
        "vfio"
      ];

      kernelParams = [
        "${cfg.cpu}_iommu=on"
        "kvm.ignore_msrs=1"
      ];

      extraModprobeConfig = ''
        options vfio-pci ids=${concatStringsSep "," cfg.vfio.deviceIds}
      '';
    };

    security = {
      polkit.enable = true;
    };

    virtualisation = {
      libvirtd = {
        enable = true;
        onBoot = mkDefault "ignore";
        onShutdown = mkDefault "shutdown";

        qemu = {
          package = mkDefault pkgs.qemu_kvm;
          ovmf.enable = true;
        };

        extraConfig = ''
          user="${cfg.vfio.user}"
        '';
      };
    };

    systemd.tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 qemu-libvirtd ${cfg.lookingGlass.group} -"
    ];

  };
}
