# Nix/NixOS (Community)

If installing **tracker** via **nix** please ensure you're running a kernel with
libbpf CO-RE support, see Tracker's [prerequisites] for more info.

[prerequisites]: ../../installing/prerequisites.md

Direct issues installing **tracker** via **nix** through the channels mentioned
[here](https://nixos.wiki/wiki/Support).

```console
nix-env --install -A nixpkgs.tracker
```

Or through your configuration as usual

NixOS:

```nix
  # your other config ...
  environment.systemPackages = with pkgs; [
    # your other packages ...
    tracker
  ];
```

home-manager:

```nix
  # your other config ...
  home.packages = with pkgs; [
    # your other packages ...
    tracker
  ];
```

