/// tap.sol -- liquidation engine (see also `vow`)

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

contract SaiTap is DSThing {
    DSToken  public  sai;
    DSToken  public  sin;
    DSToken  public  skr;

    SaiVox   public  vox;
    SaiTub   public  tub;

    uint256  public  gap;  // Boom-Bust Spread
    bool     public  off;  // Cage flag
    uint256  public  fix;  // Cage price

    // Surplus
    function joy() public view returns (uint) {
        return sai.balanceOf(this);
    }
    // Bad debt
    function woe() public view returns (uint) {
        return sin.balanceOf(this);
    }
    // Collateral pending liquidation
    function fog() public view returns (uint) {
        return skr.balanceOf(this);
    }


    function SaiTap(SaiTub tub_) public {
        tub = tub_;

        sai = tub.sai();
        sin = tub.sin();
        skr = tub.skr();

        vox = tub.vox();

        gap = WAD;
    }

    function mold(bytes32 param, uint val) public note auth {
        if (param == 'gap') gap = val;
    }

    // Cancel debt
    function heal() public note {
        if (joy() == 0 || woe() == 0) return;  // optimised
        var wad = min(joy(), woe());
        sai.burn(wad);
        sin.burn(wad);
    }

    // Feed price (sai per skr)
    function s2s() public returns (uint) {
        var tag = tub.tag();    // ref per skr
        var par = vox.par();    // ref per sai
        return rdiv(tag, par);  // sai per skr
    }
    // Boom price (sai per skr)
    function bid(uint wad) public returns (uint) {
        return rmul(wad, wmul(s2s(), sub(2 * WAD, gap)));
    }
    // Bust price (sai per skr)
    function ask(uint wad) public returns (uint) {
        return rmul(wad, wmul(s2s(), gap));
    }
    function flip(uint wad) internal {
        require(ask(wad) > 0);
        skr.push(msg.sender, wad);
        sai.pull(msg.sender, ask(wad));
        heal();
    }
    function flop(uint wad) internal {
        skr.mint(sub(wad, fog()));
        flip(wad);
        require(joy() == 0);  // can't flop into surplus
    }
    function flap(uint wad) internal {
        heal();
        sai.push(msg.sender, bid(wad));
        skr.burn(msg.sender, wad);
    }
    function bust(uint wad) public note {
        require(!off);
        if (wad > fog()) flop(wad);
        else flip(wad);
    }
    function boom(uint wad) public note {
        require(!off);
        flap(wad);
    }

    //------------------------------------------------------------------

    function cage(uint fix_) public note auth {
        require(!off);
        off = true;
        fix = fix_;
    }
    function cash(uint wad) public note {
        require(off);
        sai.burn(msg.sender, wad);
        require(tub.gem().transfer(msg.sender, rmul(wad, fix)));
    }
    function mock(uint wad) public note {
        require(off);
        sai.mint(msg.sender, wad);
        require(tub.gem().transferFrom(msg.sender, this, rmul(wad, fix)));
    }
    function vent() public note {
        require(off);
        skr.burn(fog());
    }
}
