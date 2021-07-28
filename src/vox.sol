/// vox.sol -- target price feed

// Copyright (C) 2016, 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2016, 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017        Rain Break <rainbreak@riseup.net>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import "./ds-thing/thing.sol";

contract SaiTargetPriceFeed is DSThing {
    uint256  _targetPrice;
    uint256  _rateOfChangePerSecond;

    uint256  public  fix;
    uint256  public  how;
    uint256  public  tau;

    constructor(uint targetPrice_) {
        _targetPrice = fix = targetPrice_;
        _rateOfChangePerSecond = RAY;
        tau  = era();
    }

    function era() public view virtual returns (uint) {
        return block.timestamp;
    }

    function mold(bytes32 param, uint val) public note auth {
        if (param == 'way') _rateOfChangePerSecond = val;
    }

    // Dai Target Price (ref per dai)
    function targetPrice() public returns (uint) {
        prod();
        return _targetPrice;
    }
    function rateOfChangePerSecond() public returns (uint) {
        prod();
        return _rateOfChangePerSecond;
    }

    function tell(uint256 ray) public note auth {
        fix = ray;
    }
    function tune(uint256 ray) public note auth {
        how = ray;
    }

    function prod() public note {
        uint age = era() - tau;
        if (age == 0) return;  // optimised
        tau = era();

        if (_rateOfChangePerSecond != RAY) _targetPrice = rmul(_targetPrice, rpow(_rateOfChangePerSecond, age));  // optimised

        if (how == 0) return;  // optimised
        int256 wag = int256(how * age);
        _rateOfChangePerSecond = inj(prj(_rateOfChangePerSecond) + (fix < _targetPrice ? wag : -wag));
    }

    function inj(int256 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) + RAY
            : rdiv(RAY, RAY + uint256(-x));
    }
    function prj(uint256 x) internal pure returns (int256) {
        return x >= RAY ? int256(x - RAY)
            : int256(RAY) - int256(rdiv(RAY, x));
    }
}
