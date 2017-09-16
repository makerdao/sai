/// jar.t.sol -- Unit tests for jar.sol

pragma solidity ^0.4.10;

import './jar.sol';
import 'ds-guard/guard.sol';
import "ds-test/test.sol";
import "ds-value/value.sol";
import "ds-vault/vault.sol";

contract JarTest is DSTest, DSThing {

	DSToken skr;
	DSToken gem;
	DSValue pip;
	SaiJar jar;
	DSGuard dad;

	function setUp() {
		skr = new DSToken("SKR");
		gem = new DSToken("GEM");
		pip = new DSValue();
		dad = new DSGuard();
		jar = new SaiJar(skr, gem, pip);

		//Set whitelist authority 
		skr.setAuthority(dad);

		//Permit jar to 'mint' and 'burn' SKR
		dad.permit(jar, skr, bytes4(sha3('mint(address,uint256)')));
		dad.permit(jar, skr, bytes4(sha3('burn(address,uint256)')));

		//Allow jar to mint, burn, and transfer gem/skr without approval
		gem.trust(jar, true);
        skr.trust(jar, true);

		gem.mint(6 ether);

		//Verify initial token balances
		assertEq(gem.balanceOf(this), 6 ether);
		assertEq(gem.balanceOf(jar), 0 ether);
		assertEq(skr.totalSupply(), 0 ether);

		assert(!jar.off());
	}

	function testPer() {
		jar.join(5 ether);
		assertEq(jar.per(), rdiv(5 ether, 5 ether));
	}

	function testTag() {
		jar.pip().poke(bytes32(1 ether));
		assertEq(jar.pip().read(), bytes32(1 ether));
		assertEq(wmul(jar.per(), uint(jar.pip().read())), jar.tag());
		jar.pip().poke(bytes32(5 ether));
		assertEq(jar.pip().read(), bytes32(5 ether));
		assertEq(wmul(jar.per(), uint(jar.pip().read())), jar.tag());
	}

	function testCalk() {
		assertEq(jar.gap(), WAD);
		jar.calk(2);
		assertEq(jar.gap(), 2);
		jar.calk(wmul(WAD,10));
		assertEq(jar.gap(), wmul(WAD, 10));
	}

	function testAsk() {
		assertEq(jar.per(), RAY);
		assertEq(jar.ask(3 ether), rmul(3 ether, wmul(RAY, jar.gap())));
		assertEq(jar.ask(wmul(WAD, 33)), rmul(wmul(WAD, 33), wmul(RAY, jar.gap())));
	}

	function testBid() {
		assertEq(jar.per(), RAY);
		assertEq(jar.bid(4 ether), rmul(4 ether, wmul(jar.per(), sub(2 * WAD, jar.gap()))));
		assertEq(jar.bid(wmul(5 ether,3333333)), rmul(wmul(5 ether,3333333), wmul(jar.per(), sub(2 * WAD, jar.gap()))));
	}

	function testJoin() {
		jar.join(3 ether);
		assertEq(gem.balanceOf(this), 3 ether);
		assertEq(gem.balanceOf(jar), 3 ether);
		assertEq(skr.totalSupply(), 3 ether);
		jar.join(1 ether);
		assertEq(gem.balanceOf(this), 2 ether);
		assertEq(gem.balanceOf(jar), 4 ether);
		assertEq(skr.totalSupply(), 4 ether);
	}

	function testExit() {
		gem.mint(10 ether);
		assertEq(gem.balanceOf(this), 16 ether);

		jar.join(12 ether);
		assertEq(gem.balanceOf(jar), 12 ether);
		assertEq(gem.balanceOf(this), 4 ether);
		assertEq(skr.totalSupply(), 12 ether);

		jar.exit(3 ether);
		assertEq(gem.balanceOf(jar), 9 ether);
		assertEq(gem.balanceOf(this), 7 ether);
		assertEq(skr.totalSupply(), 9 ether);

		jar.exit(7 ether);
		assertEq(gem.balanceOf(jar), 2 ether);
		assertEq(gem.balanceOf(this), 14 ether);
		assertEq(skr.totalSupply(), 2 ether);
	}

	function testCage() {
		jar.join(5 ether);
		assertEq(gem.balanceOf(jar), 5 ether);
		assertEq(gem.balanceOf(this), 1 ether);
		assertEq(skr.totalSupply(), 5 ether);
		assert(!jar.off());

		jar.cage(this, 5 ether);
		assertEq(gem.balanceOf(jar), 0 ether);
		assertEq(gem.balanceOf(this), 6 ether);
		assertEq(skr.totalSupply(), 5 ether);
		assert(jar.off());

		jar.cage(this, 0);
		assertEq(gem.balanceOf(jar), 0 ether);
		assertEq(gem.balanceOf(this), 6 ether);
		assertEq(skr.totalSupply(), 5 ether);
	}

	function testFlow() {
		jar.join(1 ether);
		jar.cage(this, 1 ether);
		assert(jar.off());
		jar.flow();
		assert(!jar.off());
	}
}