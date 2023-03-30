{pkgs, ...}: {
  # variable pertaining to package defaults.
  # generally, never CHANGE after initial setup.
  # @ initial setup, set it to match the release you're tracking (e.g. nixos-22.11 => 22.11)
  system.stateVersion = "22.11";

  nix = {
    # enable new CLI and flake support
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs.overlays = [
    # (for custom kernel)
    # avoid errors on missing modules such as md, raid0, raid1 etc.
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure ( x // { allowMissing = true ;});
    })
  ];

  # custom kernel, custom config
  boot.kernelPackages = let
    my-kernel-pkg = { stdenv, lib, linuxKernel , ...} @ args:
      (linuxKernel.manualConfig rec {
        inherit stdenv lib;

        version = "6.3.0-rc4"; # from `make menuconfig`
        modDirVersion = "${version}.nix4noobs";  # "${version}{CONFIG_LOCALVERSION}"
        configfile = ./linux-qemu.config;
        allowImportFromDerivation = true;
        src = builtins.fetchGit {
          url = "git@github.com:torvalds/linux.git";
          ref = "refs/tags/v6.3-rc4";
          rev = "197b6b60ae7bc51dd0814953c562833143b292aa";
        };
        kernelPatches = [];
      });
    my-kernel = pkgs.callPackage my-kernel-pkg {};
  in
    pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor my-kernel);

  # allow logging into `root` without a password
  users.users.root.initialHashedPassword = "";

  # install user `nixusr`
  users.users.nixusr = {
    isNormalUser = true;
    home = "/home/nixusr";
    description = "nixusr user";
    extraGroups = [ "wheel" ];
    uid = 1000;
    # `mkpasswd -m sha-512` | default: nix4noobs
    hashedPassword = "$6$bIj/yHEKrsB4GIg9$SW2OHgWTvoC5AVlENwhWkBY7tF6SSG8z6cT/bSEuyw2Jy7U2qui1isCQjeDd.ti94FI..DyKExk/FCR0FpyEO/";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDfiSeJDvonf1w5dNk5V+KcGvKODQva5PUxAO0UZYBvXbZwxuBnFQ0VGgvONRF/Sct+phdI4GFFKliDqZc9KtNiyM9SNjOrNQQfLJgWNHPmWNABx3gfFvQygNoTsS9GxulMitdGUtrXuK5l4yLAU1INC97v3/qIqjGSu9pPqnNWyWMa1d2VWa8QkA2zDSC0J1+ytt/ZqwtAyxP86lVjTb4aDpdRY3ucZH8xvk9sIR2gJsFXm9Tz58PJh/FEvJ/X9FTBkm8qq6/KDN2wNbJ/Bs7/x9rg4UmEhKpN3bStRVOOHPotUOxZ2I/uIUlMn9CIDhqVVTU6XruFVdUwzdUzbvyAKrcbcV8LdVdeOBRkTZgz9s7plHMl/Q2I1KGhecEqiGLwL7v3BJibf/S/saCSmziLU6FYrR8w8FtRStKKTaz7sE/50eVWBkQX+wFFsLw8HLdjJnHXBUZDHgYzXoVAAVFbzZxeA8E5924YF8bgLBkqn2FBrFnHiBgArkHWuv2I6V+gw9hMjPEQJje5h2E2l/NzL0sq/dlh7CXoJVf/9K6GM3fCjWfcJOmdu50sBzqFmIEZIgbGJnEkdRnCglk3VbBqNyMdhKKVBL5dRRmEBF2FbfoWCAihGW8sodZWbDMMZalzW1cgofA4LUrFQRktuR+G0cT73bBw0VbnZjuVF5Bq4w== samsung 2021-02-16"
    ];
  };

  # configure OpenSSH service
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # extra software to install
  environment.systemPackages = 
  [ pkgs.fortune ];
}
