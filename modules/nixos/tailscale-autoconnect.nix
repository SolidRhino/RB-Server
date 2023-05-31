{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.services.tailscaleAutoconnect;
in
{
  options.services.tailscaleAutoconnect = {
    enable = mkEnableOption "tailscaleAutoconnect";
    clientIdFile = mkOption {
      type = types.str;
      description = "The client id to use for authentication with Tailscale";
    };

    clientSecreteFile = mkOption {
      type = types.str;
      description = "The client secret to use for authentication with Tailscale";
    };

    ephemeralNode = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to delete this node after shutdown";
    };

    preauthorizedNode = mkOption {
      type = types.bool;
      default = true;
      description = "Wheterher to preauthorize this node";
    };

    tags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "server" ];
      description = "The tags to use with this node";
    };

    advertiseExitNode = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to advertise this node as an exit node";
    };

    exitNode = mkOption {
      type = types.str;
      default = "";
      description = "The exit node to use for this node";
    };

    exitNodeAllowLanAccess = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to allow LAN access to this node";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.clientIdFile != "";
        message = "clientIdFile must be set";
      }
      {
        assertion = cfg.clientSecreteFile != "";
        message = "clientSecreteFile must be set";
      }
      {
        assertion = cfg.tags != "";
        message = "tags must be set";
      }
      {
        assertion = cfg.exitNodeAllowLanAccess -> cfg.exitNode != "";
        message = "exitNodeAllowLanAccess must be false if exitNode is not set";
      }
      {
        assertion = cfg.advertiseExitNode -> cfg.exitNode == "";
        message = "advertiseExitNode must be false if exitNode is set";
      }
    ];

    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";

      # make sure tailscale is running before trying to connect to tailscale
      after = [ "network-pre.target" "tailscale.service" ];
      wants = [ "network-pre.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";

      script = with pkgs; ''
          # wait for tailscaled to settle
          sleep 2

          # check if we are already authenticated to tailscale
          status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
          # if status is not null, then we are already authenticated
          echo "tailscale status: $status"
          if [ "$status" != "NeedsLogin" ]; then
              exit 0
          fi

          # otherwise authenticate with tailscale
          # timeout after 10 seconds to avoid hanging the boot process

          # generate new access token
          access_token="$(${coreutils}/bin/timeout 10 ${curl}/bin/curl -d "client_id=$(cat ${cfg.clientIdFile})" -d "client_secret=$(cat ${cfg.clientSecreteFile})" "https://api.tailscale.com/api/v2/oauth/token" | ${jq}/bin/jq -r .access_token)"

          # generate new authkey
          authkey="$(${coreutils}/bin/timeout 10 ${curl}/bin/curl "https://api.tailscale.com/api/v2/tailnet/-/keys" \
              -u $access_token: \
              --data-binary ${lib.escapeShellArg (builtins.toJSON {
              capabilities.devices.create = {
                reusable = false;
                ephemeral = cfg.ephemeralNode;
                preauthorized = cfg.preauthorizedNode;
                tags = map (x: "tag:${x}") cfg.tags;
              };
              expirySeconds = 86400;
            })} | ${jq}/bin/jq -r .key
          )"

          ${coreutils}/bin/timeout 10 ${tailscale}/bin/tailscale up \
            --authkey=$(cat "${cfg.authkeyFile}")

        # we have to proceed in two steps because some options are only available
        # after authentication
        ${coreutils}/bin/timeout 10 ${tailscale}/bin/tailscale up \
        ${lib.optionalString (cfg.advertiseExitNode) "--advertise-exit-node"} \
        ${lib.optionalString (cfg.exitNode != "") "--exit-node=${cfg.exitNode}"} \
        ${lib.optionalString (cfg.exitNodeAllowLanAccess) "--exit-node-allow-lan-access"}
      '';
    };

    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };

    services.tailscale = {
      enable = true;
      useRoutingFeatures =
        if cfg.advertiseExitNode
        then "server"
        else "client";
    };
  };
}

