/// fab.sol -- factories

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.8;

import "ds-guard/guard.sol";

import "ds-token/token.sol";
import "ds-vault/vault.sol";

import "./tub.sol";

contract TubFab {
    function newTub(
        DSGuard guard, ERC20 gem, DSToken sai, DSToken sin, DSToken skr, DSVault pot
    ) returns (Tub tub) {
        tub = new Tub(gem, sai, sin, skr, pot);
        guard.okay(msg.sender, tub);
        tub.setAuthority(guard);
        guard.setAuthority(msg.sender);
    }
}
