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

    function mold(bytes32 param, uint val) {
        if (param == 'way') _way = val;
    }
}
