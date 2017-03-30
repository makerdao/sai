pragma solidity ^0.4.8;

import "ds-test/test.sol";

import 'ds-token/token.sol';
import './tub.sol';

contract Test is DSTest {
    Tub tub;
    DSToken _gem;
    DSToken _sai;
    DSToken _sin;
    DSToken _skr;
    function setUp() {
        _gem = new DSToken("collateral", "COL", 18);
        _gem.mint(100 ether);

        _sai = new DSToken("SAI", "SAI", 18);
        _sin = new DSToken("SIN", "SIN", 18);
        _skr = new DSToken("SKR", "SKR", 18);
        
        tub = new Tub(_gem, _sai, _sin, _skr);

        _sai.setOwner(tub);
        _sin.setOwner(tub);
        _skr.setOwner(tub);

        _gem.approve(tub, 100000 ether);
        tub.skr().approve(tub, 100000 ether);
        tub.sai().approve(tub, 100000 ether);
    }
    function testBasic() {
        assertEq( tub.skr().balanceOf(tub), 0 ether );
        assertEq( tub.skr().balanceOf(this), 0 ether );
        assertEq( tub.gem().balanceOf(tub), 0 ether );

        // edge case
        assertEq( uint256(tub.per()), 1 ether );
        tub.join(10 ether);
        assertEq( uint256(tub.per()), 1 ether );

        assertEq( tub.skr().balanceOf(this), 10 ether );
        assertEq( tub.gem().balanceOf(tub), 10 ether );
        // price formula 
        tub.join(10 ether); 
        assertEq( uint256(tub.per()), 1 ether );
        assertEq( tub.skr().balanceOf(this), 20 ether );
        assertEq( tub.gem().balanceOf(tub), 20 ether );

        var cup = tub.open();

        assertEq( tub.skr().balanceOf(this), 20 ether );
        assertEq( tub.skr().balanceOf(tub), 0 ether );
        tub.lock(cup, 10 ether); // lock skr token
        assertEq( tub.skr().balanceOf(this), 10 ether );
        assertEq( tub.skr().balanceOf(tub), 10 ether );

        assertEq( tub.sai().balanceOf(this), 0 ether);
        tub.draw(cup, 5 ether);
        assertEq( tub.sai().balanceOf(this), 5 ether);


        assertEq( tub.sai().balanceOf(this), 5 ether);
        tub.wipe(cup, 2 ether);
        assertEq( tub.sai().balanceOf(this), 3 ether);

        assertEq( tub.sai().balanceOf(this), 3 ether);
        assertEq( tub.skr().balanceOf(this), 10 ether );
        tub.shut(cup);
        assertEq( tub.sai().balanceOf(this), 0 ether);
        assertEq( tub.skr().balanceOf(this), 20 ether );
    }
}
