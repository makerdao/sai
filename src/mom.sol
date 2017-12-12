/// mom.sol -- admin manager

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.18;

import 'ds-thing/thing.sol';
import './tub.sol';
import './top.sol';
import './tap.sol';

contract SaiMom is DSThing {
    SaiTub  public  tub;
    SaiTap  public  tap;
    SaiVox  public  vox;

    function SaiMom(SaiTub tub_, SaiTap tap_, SaiVox vox_) public {
        tub = tub_;
        tap = tap_;
        vox = vox_;
    }
    // Debt ceiling
    function setCap(uint wad) public note auth {
        tub.mold("cap", wad);
    }
    // Liquidation ratio
    function setMat(uint ray) public note auth {
        tub.mold("mat", ray);
        var axe = tub.axe();
        var mat = tub.mat();
        require(axe >= RAY && axe <= mat);
    }
    // Stability fee
    function setTax(uint ray) public note auth {
        tub.mold("tax", ray);
        var tax = tub.tax();
        require(RAY <= tax);
        require(tax < 10002 * 10 ** 23);  // ~200% per hour
    }
    // Governance fee
    function setFee(uint ray) public note auth {
        tub.mold("fee", ray);
        var fee = tub.fee();
        require(RAY <= fee);
        require(fee < 10002 * 10 ** 23);  // ~200% per hour
    }
    // Liquidation fee
    function setAxe(uint ray) public note auth {
        tub.mold("axe", ray);
        var axe = tub.axe();
        var mat = tub.mat();
        require(axe >= RAY && axe <= mat);
    }
    // Join/Exit Spread
    function setTubGap(uint wad) public note auth {
        tub.mold("gap", wad);
    }
    // ETH/USD Feed
    function setPip(DSValue pip_) public note auth {
        tub.setPip(pip_);
    }
    // MKR/USD Feed
    function setPep(DSValue pep_) public note auth {
        tub.setPep(pep_);
    }
    // TRFM
    function setVox(SaiVox vox_) public note auth {
        tub.setVox(vox_);
    }
    // Boom/Bust Spread
    function setTapGap(uint wad) public note auth {
        tap.mold("gap", wad);
        var gap = tap.gap();
        require(gap <= 1.05 ether);
        require(gap >= 0.95 ether);
    }
    // Rate of change of target price (per second)
    function setWay(uint ray) public note auth {
        require(ray < 10002 * 10 ** 23);  // ~200% per hour
        require(ray > 9998 * 10 ** 23);
        vox.mold("way", ray);
    }
}
