{
  description = "pix0l — rooted GrapheneOS OTA pipeline for the Pixel 10 Pro Fold (rango)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];

      perSystem = { pkgs, system, lib, ... }:
        let
          # custota-tool isn't in nixpkgs; install chenxiaolong's signed release binary.
          asset = {
            "aarch64-darwin" = { f = "custota-tool-6.5-universal-apple-darwin.zip"; h = "sha256-1FrA8ZINVS42yxpAj/Y3g2SXc8EufscuOV25ipvw014="; };
            "x86_64-darwin"  = { f = "custota-tool-6.5-universal-apple-darwin.zip"; h = "sha256-1FrA8ZINVS42yxpAj/Y3g2SXc8EufscuOV25ipvw014="; };
            "x86_64-linux"   = { f = "custota-tool-6.5-x86_64-unknown-linux-gnu.zip"; h = "sha256-k2Vm9qpp9mSdT1AfIhJxyj8s46aOBj/u8gr1OaTfwws="; };
            "aarch64-linux"  = { f = "custota-tool-6.5-aarch64-unknown-linux-gnu.zip"; h = "sha256-RyM4IFgh+kVCVlXRcyveIWU2bAN0krWvIzi5tuYwwZY="; };
          }.${system};

          custota-tool = pkgs.stdenv.mkDerivation {
            pname = "custota-tool";
            version = "6.5";
            src = pkgs.fetchurl {
              url = "https://github.com/chenxiaolong/Custota/releases/download/v6.5/${asset.f}";
              hash = asset.h;
            };
            nativeBuildInputs = [ pkgs.unzip ]
              ++ lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;
            buildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.stdenv.cc.cc.lib ];
            sourceRoot = ".";
            dontConfigure = true;
            dontBuild = true;
            installPhase = ''
              runHook preInstall
              install -Dm755 custota-tool $out/bin/custota-tool
              runHook postInstall
            '';
          };
        in {
          packages.custota-tool = custota-tool;

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.avbroot        # patch/sign/verify OTAs, read magisk preinit
              pkgs.android-tools  # adb, fastboot (flash + relock)
              custota-tool        # generate Custota csig/update-info
              pkgs.gh             # trigger/monitor CI, manage secrets/vars
              pkgs.git
              pkgs.jq
              pkgs.curl
              pkgs.openssl
              pkgs.openssh        # ssh-keygen: verify chenxiaolong's release sigs
              pkgs.unzip
              pkgs.coreutils
            ];
            shellHook = ''echo "pix0l dev shell"'';
          };
        };
    };
}
