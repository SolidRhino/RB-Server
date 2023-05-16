{ pkgs, config, lib, inputs, ... }:
{
  environment.systemPackages = with pkgs; [ nano vim git tailscale jq ];

  services = {
    openssh = {
      allowSFTP = false;
      enable = true;
      openFirewall = false;
      passwordAuthentication = false;
      permitRootLogin = "no";
      startWhenNeeded = true;
    };

    hardware.argonone.enable = true;

    tailscale = {
      enable = true;
    };
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://nixos-pi.cachix.org/"
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
      ];

      trusted-public-keys = [
        "nixos-pi.cachix.org-1:SPIYe50yOaVAHLETuPoKnfPXrB0/ADlG2lwCve0MXoo="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
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
    groups = {
      server = { };
    };
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
        hashedPassword = "$y$j9T$OmOVhczR/UZFeN5ISJ8xD0$OwAH3CGtPPuNJCG6tY1X3SGU9ttpEJ0F5kQrH2Bxqr3";
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
      checkReversePath = "loose";
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ ];
      enable = true;
      trustedInterfaces = [
        "tailscale0"
      ];
    };
    hostName = "server";
  };

  hardware = {
    bluetooth.enable = false;
  };

  #Setup sops
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.defaultSopsFile = ./secrets/secret.yaml;
  sops.secrets."tailscaile_client_id" = { };
  sops.secrets."tailscaile_client_secret" = { };

  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
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

      # generate new access token
      access_token="$(${curl}/bin/curl -d "client_id=$(cat ${config.sops.secrets.tailscaile_client_id.path})" -d "client_secret=$(cat ${config.sops.secrets.tailscaile_client_secret.path})" "https://api.tailscale.com/api/v2/oauth/token" | ${jq}/bin/jq -r .access_token)"

      # generate new authkey
      authkey="$(${curl}/bin/curl "https://api.tailscale.com/api/v2/tailnet/-/keys" \
          -u $access_token: \
          --data-binary '
        {
          "capabilities": {
            "devices": {
              "create": {
                "reusable": false,
                "ephemeral": false,
                "preauthorized": true,
                "tags": [ "tag:headless" ]
              }
            }
          },
          "expirySeconds": 86400
        }' | ${jq}/bin/jq -r .key
      )"

      # authenticate with new authkey
      ${tailscale}/bin/tailscale up -authkey $authkey
    '';
  };
}
