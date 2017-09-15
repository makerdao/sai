pragma solidity ^0.4.13;

import "ds-test/test.sol";
import "ds-math/math.sol";
import './tip.sol';

contract TipTest is DSTest, DSMath {
    SaiTip tip;

    function wad(uint256 ray_) returns (uint256) {
        return wdiv(ray_, RAY);
    }

    function setUp() {
        tip = new SaiTip();
    }
    function testTipDefaultPar() {
        assertEq(tip.par(), RAY);
    }
    function testTipDefaultWay() {
        assertEq(tip.way(), RAY);
    }
    function testTipCoax() {
        tip.coax(999999406327787478619865402);  // -5% / day
        assertEq(tip.way(), 999999406327787478619865402);
    }
    function testTipProd() {
        tip.coax(999999406327787478619865402);  // -5% / day
        tip.prod();
    }
    function testTipProdAfterWarp1day() {
        tip.coax(999999406327787478619865402);  // -5% / day
        tip.warp(1 days);
        tip.prod();
    }
    function testTipParAfterWarp1day() {
        tip.coax(999999406327787478619865402);  // -5% / day
        tip.warp(1 days);
        assertEq(wad(tip.par()), 0.95 ether);
    }
    function testTipProdAfterWarp2day() {
        tip.coax(999991977495368425989823173);  // -50% / day
        tip.warp(2 days);
        assertEq(wad(tip.par()), 0.25 ether);
    }
}
