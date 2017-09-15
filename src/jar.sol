/// jar.sol -- contains gems, has a tag

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "ds-vault/vault.sol";
import "ds-value/value.sol";

contract SaiJar is DSThing, DSVault {
    DSToken  public  skr;
    ERC20    public  gem;
    DSValue  public  pip;

    uint256  public  gap;  // Spread
    bool     public  off;  // Cage flag

    function SaiJar(DSToken skr_, ERC20 gem_, DSValue pip_) {
        skr = skr_;
        gem = gem_;
        pip = pip_;

        gap = WAD;
    }
    // ref per skr
    function tag() constant returns (uint wad) {
        return wmul(per(), uint(pip.read()));
    }
    // gem per skr
    function per() constant returns (uint ray) {
        // this avoids 0 edge case / rounding errors TODO delete me
        // TODO delegate edge case via fee built into conversion formula
        // TODO could also initialize with 1 gem and 1 skr, send skr to 0x0

        // TODO can we prove that skr.sum() == 0 --> pie() == 0 ?
        var ink = skr.totalSupply();
        var pie = gem.balanceOf(this);
        return skr.totalSupply() == 0 ? RAY : rdiv(pie, ink);
    }

    function calk(uint wad) note auth {
        gap = wad;
    }
    function ask(uint wad) constant returns (uint) {
        return rmul(wad, wmul(per(), gap));
    }
    function bid(uint wad) constant returns (uint) {
        return rmul(wad, wmul(per(), sub(2 * WAD, gap)));
    }

    function join(uint wad) note {
        require(!off);
        gem.transferFrom(msg.sender, this, ask(wad));
        skr.mint(msg.sender, wad);
    }

    function exit(uint wad) note {
        require(!off);
        gem.transfer(msg.sender, bid(wad));
        skr.burn(msg.sender, wad);
    }

    //------------------------------------------------------------------

    function cage(address tap, uint jam) note auth {
        off = true;
        gem.transfer(tap, jam);
    }
    function flow() note auth {
        require(off);
        off = false;
    }
}
