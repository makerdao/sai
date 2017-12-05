// (c) Nikolai Mushegian, 2017

// Testing using a `DSSpell` as the `hat` in a `DSChief` for one-off role

import 'ds-test/test.sol';

import 'ds-spell/spell.sol';
import 'ds-chief/chief.sol';

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
        t = new Target();
    }
}
