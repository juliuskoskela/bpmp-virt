# Copyright 2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "bpmp-virt";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    microvm,
  }: let
    systems = with flake-utils.lib.system; [
      x86_64-linux
      aarch64-linux
    ];
  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        packages.qemu-bpmp = nixpkgs.legacyPackages.${system}.callPackage ./qemu-bpmp {};
        formatter = nixpkgs.legacyPackages.${system}.alejandra;
      }
    )
    // {
      nixosModules.bpmp-virt-host = import ./modules/bpmp-virt-host;
      nixosModules.bpmp-virt-guest = import ./modules/bpmp-virt-guest;
    };
}
