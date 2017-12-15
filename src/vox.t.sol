pragma solidity ^0.4.18;

import "ds-test/test.sol";
import "ds-math/math.sol";
import './vox.sol';

contract TestWarp is DSNote {
    uint  _era;

    function TestWarp() public {
        _era = uint(now);
    }

    function era() public view returns (uint) {
        return _era == 0 ? now : _era;
    }

    function warp(uint age) public note {
        require(_era != 0);
        _era = age == 0 ? 0 : _era + age;
    }
}

contract DevVox is SaiVox, TestWarp {
    function DevVox(uint par_) SaiVox(par_) public {}
}

contract VoxTest is DSTest, DSMath {
    DevVox vox;

    function wad(uint256 ray_) internal pure returns (uint256) {
        return wdiv(ray_, RAY);
    }

    function setUp() public {
        vox = new DevVox(RAY);
    }
    function testVoxDefaultPar() public {
        assertEq(vox.par(), RAY);
    }
    function testVoxDefaultWay() public {
        assertEq(vox.way(), RAY);
    }
    function testVoxCoax() public {
        vox.mold('way', 999999406327787478619865402);  // -5% / day
        assertEq(vox.way(), 999999406327787478619865402);
    }
    function testVoxProd() public {
        vox.mold('way', 999999406327787478619865402);  // -5% / day
        vox.prod();
    }
    function testVoxProdAfterWarp1day() public {
        vox.mold('way', 999999406327787478619865402);  // -5% / day
        vox.warp(1 days);
        vox.prod();
    }
    function testVoxParAfterWarp1day() public {
        vox.mold('way', 999999406327787478619865402);  // -5% / day
        vox.warp(1 days);
        assertEq(wad(vox.par()), 0.95 ether);
    }
    function testVoxProdAfterWarp2day() public {
        vox.mold('way', 999991977495368425989823173);  // -50% / day
        vox.warp(2 days);
        assertEq(wad(vox.par()), 0.25 ether);
    }
}

contract VoxHowTest is DSTest, DSMath {
    DevVox vox;

    function ray(uint256 wad_) internal pure returns (uint256) {
        return wad_ * 10 ** 9;
    }
    function setUp() public {
        vox = new DevVox(ray(0.75 ether));
        vox.tune(ray(0.002 ether));
    }
    function test_price_too_low() public {
        vox.tell(ray(0.70 ether));
        vox.warp(1 seconds);
        assertEq(vox.way(), ray(1.002 ether));
        vox.warp(2 seconds);
        assertEq(vox.way(), ray(1.006 ether));
    }

    function test_price_too_high() public {
        vox.tell(ray(0.80 ether));
        vox.warp(1 seconds);
        assertEq(vox.way(), 998003992015968063872255489);
        vox.warp(2 seconds);
        assertEq(vox.way(), 994035785288270377733598410);
    }
}
