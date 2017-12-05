// (c) Nikolai Mushegian, 2017

// Testing using a `DSSpell` as the `hat` in a `DSChief` for one-off
// root calls or role changes.

import 'ds-test/test.sol';

import 'ds-spell/spell.sol';
import 'ds-chief/chief.sol';
import 'ds-token/token.sol';

contract Target is DSThing {
    bool public ouch;
    function poke() auth {
        ouch = true;
    }
}

contract SpellTest is DSTest {
    Target t;
    DSChief c;
    DSSpell s;
    function setUp() {
        var gov = new DSToken("GOV");
        var iou = new DSToken("IOU");
        t = new Target();
        c = new DSChief(gov, iou, 1);
    }
    function testRootCall() {
        // poke() sig: 0x18178358
        bytes data = [0x18, 0x17, 0x83, 0x58];
        s = new Spell(t, 0, data);
    }
    function testRoleChange() {
        require(false);
        // setUserRole(address,uint8,bool) sig:
        // TODO complex packing
    }
}
