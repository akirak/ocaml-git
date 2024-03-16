{
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";

    ocaml-overlays.url = "github:nix-ocaml/nix-overlays";
    ocaml-overlays.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    systems,
    nixpkgs,
    ocaml-overlays,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;

    eachSystem = f:
      nixpkgs.lib.genAttrs (import systems) (
        system: let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ocaml-overlays.overlays.default];
          };
        in
          f
          {
            inherit pkgs system;
            ocamlPackages = pkgs.ocaml-ng.ocamlPackages_5_2;
          }
      );
  in {
    ocamlPackages = eachSystem ({ocamlPackages, ...}: ocamlPackages);

    packages = eachSystem ({
      pkgs,
      ocamlPackages,
      ...
    }: {
      default = ocamlPackages.buildDunePackage {
        pname = "git";
        version = "3.15.0";
        duneVersion = "3";
        src = self.outPath;

        buildInputs = with ocamlPackages; [
          ocaml-syntax-shims
        ];

        propagatedBuildInputs = with ocamlPackages; [
          logs
          uri
          mirage-time
          mirage-clock
          tcpip
          mirage-flow
          domain-name
          bigstringaf
          result
          lwt
          fmt
          rresult
          tls
          ca-certs-nss
          ipaddr
          mimic
          paf
          tls-mirage
          httpaf
          decompress
          fpath
          encore
          checkseum
          astring
          digestif
          hex
          awa-mirage
          mimic-happy-eyeballs
          alcotest
          bos
          alcotest-lwt
          crowbar
          hxd
          duff
          ocamlgraph
          emile
          happy-eyeballs-lwt
          mirage-unix
          mirage-clock-unix
        ];
      };
    });

    devShells = eachSystem ({
      pkgs,
      ocamlPackages,
      ...
    }: {
      default = pkgs.mkShell {
        inputsFrom = [self.packages.${pkgs.system}.default];
        buildInputs =
          lib.optional pkgs.stdenv.isLinux pkgs.inotify-tools
          ++ (with ocamlPackages; [
            ocaml-lsp
            ocamlformat
            ocp-indent
            utop
            # Needed for generating documentation
            # opam
            # odoc
            # odig
            # (sherlodoc.override {enableServe = true;})
          ]);
      };
    });
  };
}
