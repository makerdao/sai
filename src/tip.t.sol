pragma solidity ^0.4.13;

import "ds-test/test.sol";
import "ds-math/math.sol";
import './tip.sol';

contract TipTest is DSTest, DSMath {
    SaiTip tip;
    function setUp() {
        tip = new SaiTip();
    }
    function testTipDefaultPar() {
        assertEq(tip.par(), WAD);
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
    function testTipProdAfterWarp() {
        tip.coax(999999406327787478619865402);  // -5% / day
        tip.warp(1 days);
        tip.prod();
        assertTrue(false);
    }
    function testTipParAfterWarp() {
        tip.coax(999999406327787478619865402);  // -5% / day
        tip.warp(1 days);
        assertEq(tip.par(), 0.95 ether);
    }
}
