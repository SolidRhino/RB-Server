{
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
}
