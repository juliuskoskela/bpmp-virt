# Copyright 2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "bpmp-virt";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    systems = with flake-utils.lib.system; [
      x86_64-linux
      aarch64-linux
    ];
  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        formatter = nixpkgs.legacyPackages.${system}.alejandra;
      }
    )
    // {
      nixosModules = {
        bpmp-virt-host = ./modules/bpmp-virt-host;
        bpmp-virt-guest = ./modules/bpmp-virt-guest;
      };
    };
}
