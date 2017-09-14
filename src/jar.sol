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
    function tag() constant returns (uint256 wad) {
        return rmul(per(), uint256(pip.read()));
    }
    // gem per skr
    function per() constant returns (uint256 ray) {
        // this avoids 0 edge case / rounding errors TODO delete me
        // TODO delegate edge case via fee built into conversion formula
        // TODO could also initialize with 1 gem and 1 skr, send skr to 0x0

        // TODO can we prove that skr.sum() == 0 --> pie() == 0 ?
        var ink = skr.totalSupply();
        var pie = gem.balanceOf(this);
        return skr.totalSupply() == 0 ? RAY : rdiv(pie, ink);
    }

    function jump(uint256 wad) note auth {
        gap = wad;
    }
    function bid() constant returns (uint256) {
        return rmul(per(), sub(2 * WAD, gap) * (RAY / WAD));
    }
    function ask() constant returns (uint256) {
        return rmul(per(), gap * (RAY / WAD));
    }

    function join(uint256 jam) note {
        require(!off);
        var ink = rdiv(jam, ask());
        skr.mint(msg.sender, ink);
        gem.transferFrom(msg.sender, this, jam);
    }

    function exit(uint256 ink) note {
        require(!off);
        var jam = rmul(ink, bid());
        skr.burn(msg.sender, ink);
        gem.transfer(msg.sender, jam);
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
