# Ergvein

![Build all](https://github.com/hexresearch/ergvein/workflows/Build%20all/badge.svg)

Ergvein is MVP implementation for [Cypra](https://cypra.io) ecosystem. It is cryptocurrency [SPV](https://bitcoin.org/en/operating-modes-guide#simplified-payment-verification-spv) wallet that is focused on privacy, decentralized exchange and heavy usage of smart contracts. The wallet is Bitcoin only at the moment. The project encourages users to host their own backend node.

**Wallet is not finished yet! Consider the product as alpha quality and subject for changes.**

Features:
* We use [SPV](https://bitcoin.org/en/operating-modes-guide#simplified-payment-verification-spv) design. Wallet doesn't trust nodes. All data is double checked: the wallet samples multiple nodes and checks results for consistency.
* Private keys are stored in encrypted storage and never leave your device. All wallet data is encrypted and protected by your password.
* Android platform
* Decentralized public network of indexing nodes that allows users to make money when they run them.

# How to build project

1. You need `nix` tool to build the repo. Install with non-root user:
```
bash <(curl https://nixos.org/nix/install)
```
1. Optional, to speed up (factor of 10 times) build, you can enable cachix binary cache. See secion below.
1. To build desktop version:
```
./shells.sh
cabal new-build all
cabal new-run ergvein
```
1. To build android version:
```
./make-android.sh
./install-apk.sh
```
1. If you are using NixOS you need to manually enable reflex-platform cache:
```
nix.binaryCaches = [ "https://cache.nixos.org/" "https://nixcache.reflex-frp.org" ];
nix.binaryCachePublicKeys = [ "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI=" ];
```

# How to build release

There are two files that are related to APK signing of release bundle: `./release/password` and `./release/release.keystore`.
First is encrypted by git-crypt and only our team can access it. That protects Google Play releases from tampering.

But, if you want to build your own release version with own signatures, you can create your own keys and sign with them. Here
how to perform this:
```
cd release && ./create_keystore.sh my_store.keystore
```
Fill password and answer questions for certificate, next put password in a file, for instance: `./release/my-password`.

Next, you can build release with:
```
./release-android --arg releasePasswordFile ./release/my-password --arg releaseKeyStore ./release/my_store.keystore
```
Results will be symlinked in folders `android-release` for bundle and `android-release-apk` for APK version, we provide both
as bundles are not easy for manual installation.

# How to use cachix

We provide binary cache for builds via cachix.org. To start using it to speed up your builds:
```
nix-env -iA cachix -f https://cachix.org/api/v1/install
cachix use ergvein
```

# Deploy index server with docker-compose

This docker-compose uses official docker image [ergvein/ergvein-index-server](https://hub.docker.com/r/ergvein/ergvein-index-server)

``` sh
cd index-server/docker-compose-example
```

Adjust connection settings for bitcoin node in config.yml and run:

``` sh
docker-compose up -d
```

Ergvein index server will listen on all network interfaces port tcp 8667.

Stop and purge all data:

``` sh
docker-compose down -v
```

Note that you need to have running and synced bitcoin nodes.

If you have no btc nodes, you may run them along with ergvein indexer like that:

``` sh
docker-compose -f docker-compose.yml -f docker-compose-btc.yml up -d
```

Also pay attention to `BTCNodeUser` and `BTCNodePassword` parameters in config.yml. In production environmnet use strong password for bitcoin node and generate `rpcauth` string (have a look at docker-compose-btc.yml file) with official bitcoin project python script:

``` sh
curl -sSL https://raw.githubusercontent.com/bitcoin/bitcoin/master/share/rpcauth/rpcauth.py | python3 - bitcoinrpcuser
```

In docker-compose file you have to escape `$` symbol with `$` (yes, should looks like double dollar sign).

If you want to run on tesnet networks update settings in config.yml and use CHAIN=test environment variable:

``` sh
CHAIN=test docker-compose -f docker-compose.yml -f docker-compose-btc.yml up -d
```

Stop and purge all data (including btc node):

``` sh
docker-compose -f docker-compose.yml -f docker-compose-btc.yml up -d
```


# Deploy indexer server with nixos module

You can use our NixOS module to deploy index server in ten minutes. Add the following to your `/etc/nixos/configuration.nix`:
``` nix
let ergvein = pkgs.fetchFromGitHub {
      owner = "hexresearch";
      repo = "ergvein";
      rev = "35a67a64c70c73cc100c929fe32f334ca6d549aa";
      sha256 = "18rly6g6qkysw3gv3fhvicsbxv37f1hm4ll7sckpdwcfbxvyrfwn";
    };
in {
  imports = [
    "${ergvein}/nix/modules/ergvein.nix"
    "${ergvein}/nix/modules/local-secrets.nix" # remove if using nixops secrets
  ];
  services.ergvein = {
    enable = true;
    externalAddress = { host = "127.0.0.1"; port = 8667; }; # here place your ip
  };
  deployment.keys = {
    btcpassword.text = "verysecretpassword";
  };

}
```

# UI prototyping

* Start the server:
    * ``cd ui-playground``
    * ``./watch.sh``
* Implement the design in pure HTML+CSS in ``index.html``
* You may use ``css/extra.css`` for fast CSS changes
* Alternatevly use Style.hs to mimic the Ergvein.Style module with Clay
   1. Change Style.hs
   2. ``./generate-css.sh``
   3. Sometimes hakyll fails to detect changes from the ``generate-css`` script. In this case, open ``css/style.css`` and press Ctrl+S

The page is accessible at ``127.0.0.1:8000``

Finally, transfer design choices and extra classes to the wallet.

# Troubleshooting

## Element inspector fails to render

If the page turns to blank when you open the element inspector or resize the window try exporting
`export WEBKIT_DISABLE_COMPOSITING_MODE=1` before running the app.

## pg_ctl failed to start

Error: `could not create lock file "/var/run/postgresql/.s.PGSQL.5434.lock": Permission denied`
Solution: `sudo chmod a+w /var/run/postgresql`
