/// jar.sol -- contains gems, has a tag

// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "ds-vault/vault.sol";
import "ds-value/value.sol";

contract SaiJar is DSVault {
    DSValue  public  pip;

    function SaiJar(ERC20 gem_, DSValue tag_) {
        token = gem_;
        pip = tag_;
    }
    function tag() constant returns (uint128) {
        return uint128(pip.read());
    }
}
