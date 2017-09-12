/// jar.sol -- contains gems, has a tag

// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "ds-vault/vault.sol";
import "ds-value/value.sol";

contract SaiJar is DSThing, DSVault {
    DSToken  public  skr;
    ERC20    public  gem;
    DSValue  public  pip;
    uint256  public  gap;

    function SaiJar(DSToken skr_, ERC20 gem_, DSValue pip_) {
        skr = skr_;
        gem = gem_;
        pip = pip_;

        gap = WAD;
    }
    // ref per skr
    function tag() constant returns (uint256) {
        return rmul(per(), uint256(pip.read()));
    }
    // gem per skr
    function per() constant returns (uint256) {
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

    function join(address guy, uint256 jam) note auth {
        var ink = rdiv(jam, ask());
        mint(skr, ink);
        push(skr, guy, ink);
        pull(gem, guy, jam);
    }
    function exit(address guy, uint256 ink) note auth {
        var jam = rmul(ink, bid());
        pull(skr, guy, ink);
        burn(skr, ink);
        push(gem, guy, jam);
    }
}
