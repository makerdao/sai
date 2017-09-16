/// vox.sol -- target price feed

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.15;

import "./lib.sol";

contract SaiVox is DaiVox {
    function SaiVox() DaiVox(RAY) {
        how = 0;  // zero initial sensitivity
    }

    // Rate of change of target price (per second)
    function coax(uint ray) note auth {
        _way = ray;
        require(_way < 10002 * 10 ** 23);  // ~200% per hour
        require(_way >  9998 * 10 ** 23);
    }
}
