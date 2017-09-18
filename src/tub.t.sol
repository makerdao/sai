/// tub.t.sol -- Unit tests for tub.sol

pragma solidity ^0.4.15;

import './tub.sol';
import './tap.sol';
import 'ds-guard/guard.sol';
import "ds-test/test.sol";

contract TubTest is DSTest, DSThing {

	SaiTub tub;
	SaiTap tap;
	SaiVox vox;

	DSGuard dad;

	DSValue pip;

	DSToken sai;
	DSToken sin;
	DSToken skr;
	DSToken gem;

	function setUp() {
		sai = new DSToken("SAI");
		sin = new DSToken("SIN");
		skr = new DSToken("SKR");
		gem = new DSToken("GEM");
		pip = new DSValue();
		dad = new DSGuard();
		vox = new SaiVox();
		tap = new SaiTap();
		tub = new SaiTub(sai, sin, skr, gem, pip, vox, tap);

		//Set whitelist authority 
		skr.setAuthority(dad);

		//Permit tub to 'mint' and 'burn' SKR
		dad.permit(tub, skr, bytes4(sha3('mint(address,uint256)')));
		dad.permit(tub, skr, bytes4(sha3('burn(address,uint256)')));

		//Allow tub to mint, burn, and transfer gem/skr without approval
		gem.trust(tub, true);
		skr.trust(tub, true);
		sai.trust(tub, true);gem.mint(6 ether);

		//Verify initial token balances
		assertEq(gem.balanceOf(this), 6 ether);
		assertEq(gem.balanceOf(tub), 0 ether);
		assertEq(skr.totalSupply(), 0 ether);

		assert(!tub.off());
	}

	function testPie() {
		assertEq(tub.pie(), gem.balanceOf(tub));
		assertEq(tub.pie(), 0 ether);
		gem.mint(75 ether);
		tub.join(72 ether);
		assertEq(tub.pie(), gem.balanceOf(tub));
		assertEq(tub.pie(), 72 ether);
	}

	function testPer() {
		tub.join(5 ether);
		assertEq(skr.totalSupply(), 5 ether);
		assertEq(tub.per(), rdiv(5 ether, 5 ether));
	}

	function testTag() {
		tub.pip().poke(bytes32(1 ether));
		assertEq(tub.pip().read(), bytes32(1 ether));
		assertEq(wmul(tub.per(), uint(tub.pip().read())), tub.tag());
		tub.pip().poke(bytes32(5 ether));
		assertEq(tub.pip().read(), bytes32(5 ether));
		assertEq(wmul(tub.per(), uint(tub.pip().read())), tub.tag());
	}

	function testGap() {
		assertEq(tub.gap(), WAD);
		tub.mold('gap', 2);
		assertEq(tub.gap(), 2);
		tub.mold('gap', wmul(WAD,10));
		assertEq(tub.gap(), wmul(WAD, 10));
	}

	function testAsk() {
		assertEq(tub.per(), RAY);
		assertEq(tub.ask(3 ether), rmul(3 ether, wmul(RAY, tub.gap())));
		assertEq(tub.ask(wmul(WAD, 33)), rmul(wmul(WAD, 33), wmul(RAY, tub.gap())));
	}

	function testBid() {
		assertEq(tub.per(), RAY);
		assertEq(tub.bid(4 ether), rmul(4 ether, wmul(tub.per(), sub(2 * WAD, tub.gap()))));
		assertEq(tub.bid(wmul(5 ether,3333333)), rmul(wmul(5 ether,3333333), wmul(tub.per(), sub(2 * WAD, tub.gap()))));
	}

	function testJoin() {
		tub.join(3 ether);
		assertEq(gem.balanceOf(this), 3 ether);
		assertEq(gem.balanceOf(tub), 3 ether);
		assertEq(skr.totalSupply(), 3 ether);
		tub.join(1 ether);
		assertEq(gem.balanceOf(this), 2 ether);
		assertEq(gem.balanceOf(tub), 4 ether);
		assertEq(skr.totalSupply(), 4 ether);
	}

	function testExit() {
		gem.mint(10 ether);
		assertEq(gem.balanceOf(this), 16 ether);

		tub.join(12 ether);
		assertEq(gem.balanceOf(tub), 12 ether);
		assertEq(gem.balanceOf(this), 4 ether);
		assertEq(skr.totalSupply(), 12 ether);

		tub.exit(3 ether);
		assertEq(gem.balanceOf(tub), 9 ether);
		assertEq(gem.balanceOf(this), 7 ether);
		assertEq(skr.totalSupply(), 9 ether);

		tub.exit(7 ether);
		assertEq(gem.balanceOf(tub), 2 ether);
		assertEq(gem.balanceOf(this), 14 ether);
		assertEq(skr.totalSupply(), 2 ether);
	}

	function testCage() {
		tub.join(5 ether);
		assertEq(gem.balanceOf(tub), 5 ether);
		assertEq(gem.balanceOf(this), 1 ether);
		assertEq(skr.totalSupply(), 5 ether);
		assert(!tub.off());

		tub.cage(tub.per(), 5 ether);
		assertEq(gem.balanceOf(tub), 0 ether);
		assertEq(gem.balanceOf(tap), 5 ether);
		assertEq(skr.totalSupply(), 5 ether);
		assert(tub.off());
	}

	function testFlow() {
		tub.join(1 ether);
		tub.cage(tub.per(), 1 ether);
		assert(tub.off());
		assert(!tub.out());
		tub.flow();
		assert(tub.out());
	}
}
