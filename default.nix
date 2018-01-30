# This file defines Sai as a package with unresolved dependencies.
# We can use it to build using different revisions of the DappHub world.
# In particular, we use it via `dapp.nix` with a specific revision.

{ solidityPackage, dappsys }:

solidityPackage {
  name = "sai";
  src = ./src;
  deps = with dappsys; [
    ds-chief
    ds-guard
    ds-roles
    ds-spell
    ds-test
    ds-thing
    ds-token
    ds-value
  ];
}
