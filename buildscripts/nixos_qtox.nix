let
  overlay = final: prev:
    # a fixed point overay for overriding a package set

    with final; {
      # use the final result of the overlay for scope

      libtoxcore =
        # build a custom libtoxcore
        prev.libtoxcore.overrideAttrs ({ ... }: {
          src = fetchFromGitHub {
            owner = "zoff99";
            repo = "c-toxcore";
            rev = "18c170b5210c50f402525c56fa02ad17ba04e399";
            fetchSubmodules = true;
            sha256 = "sha256-gBQyCRUTPoT6cJgx6TWUUjxpGQ5wGK+dvljZIGR0zp4=";
          };
          patches = [
            (fetchpatch {
              url =
                "https://raw.githubusercontent.com/Zoxcore/qTox_enhanced/zoxcore/push_notification/buildscripts/patches/tc___ftv2_capabilities.patch";
              sha256 = "sha256-LU4EDwEKLh5m3OByt/Mc1dyM3huCFwHFgWo083s6lKg=";
            })
          ];
          buildInputs = [
            libsodium msgpack ncurses libconfig
            libopus libvpx x264 ffmpeg
          ];
        });

      toxext =
        # use an existing package or package it here
        prev.toxext or stdenv.mkDerivation rec {
          pname = "toxext";
          version = "0.0.3";
          src = fetchFromGitHub {
            owner = pname;
            repo = pname;
            rev = "v${version}";
            hash = "sha256-I0Ay3XNf0sxDoPFBH8dx1ywzj96Vnkqzlu1xXsxmI1M=";
          };
          nativeBuildInputs = [ cmake pkg-config ];
          buildInputs = [ libtoxcore ];
        };

      toxextMessages =
        # use an existing package or package it here
        prev.toxextMessages or stdenv.mkDerivation rec {
          pname = "tox_extension_messages";
          version = "0.0.3";
          src = fetchFromGitHub {
            owner = "toxext";
            repo = pname;
            rev = "v${version}";
            hash = "sha256-qtjtEsvNcCArYW/Zyr1c0f4du7r/WJKNR96q7XLxeoA=";
          };
          nativeBuildInputs = [ cmake pkg-config ];
          buildInputs = [ libtoxcore toxext ];
        };

      qtox = prev.qtox.overrideAttrs ({ buildInputs, ... }: {
        version = "push_notification-";
        # take sources directly from this repo checkout
        buildInputs = buildInputs ++ [ curl libtoxcore toxext toxextMessages ];
      });

    };

in { pkgs ? import <nixpkgs> { } }:
# take nixpkgs from the environment
let
  pkgs' = pkgs.extend overlay;
  # apply overlay
in pkgs'.qtox
# select package
