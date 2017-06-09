/// jar.sol -- contains gems, has a tag

// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "ds-vault/vault.sol";
import "ds-value/value.sol";

contract SaiJar is DSVault {
    DSValue  public  tag;

    function SaiJar(DSValue tag_) {
        tag = tag_;
    }
}
