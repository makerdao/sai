pragma solidity ^0.4.15;

import "ds-test/test.sol";
import "ds-math/math.sol";
import './vox.sol';

contract TestWarp is DSNote {
    uint  _era;

    function TestWarp() {
        _era = uint(now);
    }

    function era() constant returns (uint) {
        return _era == 0 ? now : _era;
    }

    function warp(uint age) note {
        require(_era != 0);
        _era = age == 0 ? 0 : _era + age;
    }
}

contract DevVox is SaiVox, TestWarp {}

contract VoxTest is DSTest, DSMath {
    DevVox vox;

    function wad(uint256 ray_) returns (uint256) {
        return wdiv(ray_, RAY);
    }

    function setUp() {
        vox = new DevVox();
    }
    function testVoxDefaultPar() {
        assertEq(vox.par(), RAY);
    }
    function testVoxDefaultWay() {
        assertEq(vox.way(), RAY);
    }
    function testVoxCoax() {
        vox.mold('way', 999999406327787478619865402);  // -5% / day
        assertEq(vox.way(), 999999406327787478619865402);
    }
    function testVoxProd() {
        vox.mold('way', 999999406327787478619865402);  // -5% / day
        vox.prod();
    }
    function testVoxProdAfterWarp1day() {
        vox.mold('way', 999999406327787478619865402);  // -5% / day
        vox.warp(1 days);
        vox.prod();
    }
    function testVoxParAfterWarp1day() {
        vox.mold('way', 999999406327787478619865402);  // -5% / day
        vox.warp(1 days);
        assertEq(wad(vox.par()), 0.95 ether);
    }
    function testVoxProdAfterWarp2day() {
        vox.mold('way', 999991977495368425989823173);  // -50% / day
        vox.warp(2 days);
        assertEq(wad(vox.par()), 0.25 ether);
    }
}
