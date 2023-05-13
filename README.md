[![build](https://github.com/SolidRhino/RB-Server/actions/workflows/build.yml/badge.svg)](https://github.com/SolidRhino/RB-Server/actions/workflows/build.yml)
### On NixOS

If you're running NixOS and want to use this template to build the Raspberry Pi
4 Image, you'll need to emulate an arm64 machine by adding the following to your
NixOS configuration.

```
{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
```

Then you will be able to run `nix build .#images.server` and get a result you can
flash to an SD Card and boot.

After you've booted, you will be able to rebuild the nixosConfiguration on the
Pi. For example, by running `nixos-rebuild --flake
github:SolidRhino/RB-Server`

Simply fork this repo and begin adding code to `./configuration.nix` and allow
this basic configuration to become your own.
