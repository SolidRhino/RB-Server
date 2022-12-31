{ pkgs, config, lib, inputs, ... }:
{
  environment.systemPackages = with pkgs; [ vim git tailscale ];
  services = {
    openssh = {
      allowSFTP = false;
      enable = true;
      openFirewall = false;
      passwordAuthentication = false;
      permitRootLogin = "no";
      startWhenNeeded = true;
    };

    tailscale = {
      enable = true;
    };
  };

  services.hardware.argonone.enable = true;

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flake" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # Free up to 1GiB whenever there is less than 100MiB left.
    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
  };

  time = {
    timeZone = "Europe/Amsterdam";
  };

  users = {
    mutableUsers = false;
    users = {
      root = {
        hashedPassword = "!";
      };
      server = {
        extraGroups = [
          "wheel"
        ];
        group = "server";
        hashedPassword = "$y$j9T$6onXewS8c.KxiK609noHW.$wY4H93NlxCI5SBSiqsqctbZ7QNTt4XnuxEWCByRByN/";
        isNormalUser = true;
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQ2OaPn0ChXY6bmYuIeoTd+X4hvockuD6buHCpIlNXn"
            ];
          };
        };
      };
    };
  };

  networking = {
    interfaces."eth0".useDHCP = true;
    firewall = {
      allowedUDPPorts = [
        41641
      ];
      enable = true;
      trustedInterfaces = [
        "tailscale0"
      ];
    };
    hostName = "server";
  };

  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up -authkey tskey-auth-kGtZkF3CNTRL-MpPL5dqqLRPJ5w2TzFjbYP574iAe3hqF
    '';
  };

  system.stateVersion = "23.05";
}
