pragma solidity ^0.4.8;


import "ds-test/test.sol";

import "ds-math/math.sol";

import 'ds-token/token.sol';
import 'ds-guard/guard.sol';
import 'ds-value/value.sol';

import './tub.sol';
import './top.sol';
import './tap.sol';
import './sai.t.sol';


contract MyFakePerson {
    SaiTap  public tap;

    SaiTub  public tub;

    DSToken public sai;

    DSToken public skr;

    DSToken public gem;

    function MyFakePerson(SaiTap _tap, SaiTub _tub, DSToken _gem, DSToken _skr) public {
        tap = _tap;
        tub = _tub;
        sai = tap.sai();
        skr = _skr;
        gem = _gem;

        sai.trust(tap, true);
        skr.trust(tub, true);
        gem.trust(tub, true);
        skr.trust(tap, true);
    }

    function join(uint wad) public {
        tub.join(wad);
    }

    function cash() public {
        tap.cash();
    }

    function open() public returns (bytes32) {
        return tub.open();
    }

    function lock(bytes32 cup, uint wad) public {
        tub.lock(cup, wad);
    }

    function draw(bytes32 cup, uint wad) public {
        tub.draw(cup, wad);
    }

    function transferFrom(DSToken t, address dst, uint amount) public {
        t.transfer(dst, amount);
    }

    function boom(uint wad) public {
        tap.boom(wad);
    }

    function shut(bytes32 cup) public {
        tub.shut(cup);
    }
}


contract Audit is SaiTestBase {

    // This test is confusing, draw doesn't fail due a division by zero, it fails because of these two rules:
    // - require(!off);
    // - require(safe(cup));
    // function testTOBSaiCageDiv0()) public {
    //     mom.setMat(ray(1 ether));
    //     tub.join(10 ether);
    //     var cup = tub.open();
    //     tub.lock(cup, 10 ether);

    //     // set fit to 0
    //     tub.cage(0, 0 ether);

    //     assertEq(tub.fit(), 0);

    //     // trigger the division by zero
    //     tub.draw(cup, 1 ether);
    // }
    
    function testTOBSaiCageDiv0() public {
        mom.setMat(ray(1 ether));
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        top.cage(0);
    }

    function testTOBSaiCageDiv0Bite() public {
        mom.setMat(ray(1 ether));
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        // set fit to 0
        tub.cage(0, 0 ether);

        assertEq(tub.fit(), 0);

        // trigger the division by zero
        tub.bite(cup);
    }

    function testTOBSai010() public {
        gem.mint(1000 ether);
        sai.mint(100 ether);
        // so it can pay back stability fee

        mom.setHat(1000 ether);
        mom.setTax(1000000400000000000000000000);

        var cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        // draw initial amount
        tub.draw(cup, 10 ether);

        // increase chi
        warp(1 days);
        tub.drip();


        // initial values
        // _chi                            = 1.035164129205985238932488761
        // cup.art                      = 10.000000000000000000
        // sin.balanceOf(tub)  = 10.351641292059852389
        // tab(cup)                    = 10.351641292059852389

        tub.draw(cup, 4 wei);
        // cup.art                      = 10.000000000000000004
        // sin.balanceOf(tub)  = 10.351641292059852393
        // tab(cup)                    = 10.351641292059852393

        tub.draw(cup, 1 wei);
        // cup.art                      = 10.000000000000000005
        // sin.balanceOf(tub)  = 10.351641292059852394
        // tab(cup)                    = 10.351641292059852395
        // the last digit for sin(tub) is 4, and for tab(cup) is 5

        // Details of tub.draw(cup, 1 wei)
        // cup.art    = cup.art + 1/ chi = cup.art + 1
        // sin(tub)   = sin(tub) + 1
        // tab(cup)  = cup.art * chi
        // Due to the rounding, tab(cup) is added by two
        // while sin(tub) is added by one

        // this should be true but fails
        assertTrue(tub.sin().balanceOf(tub) >= tub.tab(cup));
    }

    function testTOBSai011Pattern3() public {
        sin.mint(tap, 1 ether);
        // so the bust/flop will work

        // Get the per ratio less than .5
        var cup = tub.open();
        tub.join(1 ether);
        tub.lock(cup, 1 ether);
        tub.draw(cup, 1 ether);
        tap.bust(1.1 ether);
        // this mints skr and modifies per
        assertTrue(tub.per() < ray(1 ether / 2));

        assertTrue(gem.balanceOf(tub) == 1 ether);
        assertTrue(skr.balanceOf(this) == 1.1 ether);

        tub.join(1 wei);
        // create 1 skr for 0 gem

        assertTrue(skr.balanceOf(this) > 1.1 ether);

        // this should be true but fails
        assertTrue(gem.balanceOf(tub) > 1 ether);
    }

    function testTOBSai011Pattern4() public {
        // put some initial fee
        sai.mint(tap, 1 ether);

        MyFakePerson person = new MyFakePerson(tap, tub, gem, skr);
        gem.mint(person, 100 ether);
        bytes32 cup_1 = person.open();
        person.join(10 ether);
        person.lock(cup_1, 0.5 ether);
        person.draw(cup_1, 0.5 ether);
        // pay the fee
        // as a result pie() != skr.totalSupply (in per())
        person.boom(0.5 ether);

        assertTrue(gem.balanceOf(this) == 100 ether);

        tub.join(28 wei);
        // cost 29 gem

        tub.exit(10 wei);
        // return 11 gem
        tub.exit(10 wei);
        // return 11 gem
        tub.exit(8 wei);
        // return 8 gem

        // // cost 29 gem for 30 gem
        // this should be 100 ether or at least lower, but never should be higher
        assertTrue(gem.balanceOf(this) <= 100 ether);
    }

    function testTOBSai012() public {
        uint user0 = 575710461955084070048793674274572680;
        uint gems = 1059836680168385020599124280851040344;
        skr.mint(this, user0);
        gem.mint(tub, gems);
        // User has all skr supply
        assertEq(skr.balanceOf(this), skr.totalSupply());
        // 'user0' is the value of total skr in the system
        assertEq(skr.totalSupply(), user0);
        // 'gems' is the value of total eth backed by the system
        assertEq(gem.balanceOf(tub), gems);
        // this should be true as user wants to exit all the existing skr in the system, then should receive exactly the 'gems' amount
        assertEq(tub.bid(user0), gems);
        // tub.exit(user0);
        // assertEq(gem.balanceOf(tub), 0);
        // assertEq(skr.balanceOf(this), 0);
    }

}