// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>

pragma solidity ^0.4.15;

import 'ds-thing/thing.sol';
import 'ds-token/token.sol';

contract Flapper {
    function flap();
}

// Simple proxy SaiPot
contract SaiPot is DSThing {
    Flapper target;
    DSToken GEM;
    function setFlapper(Flapper where) auth {
        target = where;
    }
    function flap() note {
        GEM.push(target, GEM.balanceOf(this));
        target.flap();
    }
}
