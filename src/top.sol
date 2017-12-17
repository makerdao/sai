/// top.sol -- global settlement manager

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain Break <rainbreak@riseup.net>

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

pragma solidity ^0.4.18;

import "./tub.sol";
import "./tap.sol";

contract SaiTop is DSThing {
    SaiVox   public  vox;
    SaiTub   public  tub;
    SaiTap   public  tap;

    DSToken  public  sai;
    DSToken  public  sin;
    DSToken  public  skr;
    ERC20    public  gem;

    uint256  public  fix;  // sai cage price (gem per sai)
    uint256  public  fit;  // skr cage price (ref per skr)
    uint256  public  caged;
    uint256  public  cooldown = 6 hours;

    function SaiTop(SaiTub tub_, SaiTap tap_) public {
        tub = tub_;
        tap = tap_;

        vox = tub.vox();

        sai = tub.sai();
        sin = tub.sin();
        skr = tub.skr();
        gem = tub.gem();
    }

    function era() public view returns (uint) {
        return block.timestamp;
    }

    // force settlement of the system at a given price (sai per gem).
    // This is nearly the equivalent of biting all cups at once.
    // Important consideration: the gems associated with free skr can
    // be tapped to make sai whole.
    function cage(uint price) internal {
        require(!tub.off() && price != 0);
        caged = era();

        tub.drip();  // collect remaining fees
        tap.heal();  // absorb any pending fees

        fit = rmul(wmul(price, vox.par()), tub.per());
        // Most gems we can get per sai is the full balance of the tub.
        // If there is no sai issued, we should still be able to cage.
        if (sai.totalSupply() == 0) {
            fix = rdiv(WAD, price);
        } else {
            fix = min(rdiv(WAD, price), rdiv(tub.pie(), sai.totalSupply()));
        }

        tub.cage(fit, rmul(fix, sai.totalSupply()));
        tap.cage(fix);

        tap.vent();    // burn pending sale skr
    }
    // cage by reading the last value from the feed for the price
    function cage() public note auth {
        cage(rdiv(uint(tub.pip().read()), vox.par()));
    }

    function flow() public note {
        require(tub.off());
        var empty = tub.din() == 0 && tap.fog() == 0;
        var ended = era() > caged + cooldown;
        require(empty || ended);
        tub.flow();
    }

    function setCooldown(uint cooldown_) public auth {
        cooldown = cooldown_;
    }
}
