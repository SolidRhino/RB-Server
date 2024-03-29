{ config
, pkgs
, outputs
, ...
}: {
  imports = [ outputs.nixosModules.tailscale-autoconnect ];

  services.tailscaleAutoconnect = {
    enable = true;

    authkeyFile = config.sops.secrets.tailscale_key.path;
    advertiseExitNode = lib.mkDefault true;
  };

  sops.secrets.tailscale_key = {
    sopsFile = ./secrets.yaml;
  };

  #environment.persistence = {
  #  "/persist".directories = [ "/var/lib/tailscale" ];
  #};
}
