// (c) Nikolai Mushegian, 2017

// Testing using a `DSSpell` as the `hat` in a `DSChief` for one-off
// root calls or role changes.

pragma solidity ^0.4.18;

import 'ds-test/test.sol';

import 'ds-spell/spell.sol';
import 'ds-chief/chief.sol';
import 'ds-token/token.sol';

contract Target is DSThing {
    bool public ouch;
    function poke() public auth {
        ouch = true;
    }
}

contract SpellTest is DSTest {
    Target t;
    DSChief c;
    DSSpell s;
    function setUp() public {
        var gov = new DSToken("GOV");
        var iou = new DSToken("IOU");
        t = new Target();
        c = new DSChief(gov, iou, 1);
    }
    function testRootCall() public {
        // poke() sig: 0x18178358
        bytes memory data = hex"18178358";
        s = new DSSpell(t, 0, data);
    }
    // function testRoleChange() public {
        // require(false);
        // // setUserRole(address,uint8,bool) sig:
        // // TODO complex packing
    // }
}
