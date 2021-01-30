let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { inherit config; };
  compilerVersion = "ghc8103";
  compilerSet = pkgs.haskell.packages."${compilerVersion}";
  gitIgnore = pkgs.nix-gitignore.gitignoreSourcePure;
  config = {
    packageOverrides = super: let self = super.pkgs; in rec {
      haskell = super.haskell // {
        packageOverrides = with pkgs.haskell.lib; self: super: {
          dear-imgui = super.callCabal2nixWithOptions "dear-imgui" (gitIgnore [./.gitignore] ./.) "--flag=sdl --flag=glfw --flag=opengl --flag=vulkan" {};
        };
      };
    };
  };

in {
  inherit pkgs;
  dear-imgui = compilerSet.dear-imgui;
  shell = compilerSet.shellFor {
    packages = p: [ p.dear-imgui ];
    buildInputs = with pkgs; [
      compilerSet.cabal-install
      compilerSet.haskell-language-server
    ];
  };
}
