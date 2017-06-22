pragma solidity ^0.4.8;

import "ds-test/test.sol";
import 'ds-roles/roles.sol';
import './lpc.sol';

contract Tester {
    SaiLPC lpc;
    function Tester(SaiLPC lpc_) {
        lpc = lpc_;

        lpc.lps().approve(lpc, uint128(-1));
        lpc.ref().approve(lpc, uint128(-1));
        lpc.alt().approve(lpc, uint128(-1));
    }
    function pool(ERC20 gem, uint128 wad) {
        lpc.pool(gem, wad);
    }
    function exit(ERC20 gem, uint128 wad) {
        lpc.exit(gem, wad);
    }
    function take(ERC20 gem, uint128 wad) {
        lpc.take(gem, wad);
    }
}

contract LPCTest is DSTest, DSMath {
    ERC20   ref;
    ERC20   alt;
    DSToken lps;
    DSValue pip;
    SaiLPC  lpc;
    DSRoles mom;
    Tip     tip;

    Tester   t1;
    Tester   m1;
    Tester   m2;
    Tester   m3;

    function assertEqWad(uint128 x, uint128 y) {
        assertEq(uint256(x), uint256(y));
    }

    function ray(uint128 wad) returns (uint128) {
        return wad * 10 ** 9;
    }

    function setRoles() {
        mom.setRoleCapability(1, address(lpc), bytes4(sha3("pool(address,uint128)")), true);
        mom.setRoleCapability(1, address(lpc), bytes4(sha3("exit(address,uint128)")), true);
        mom.setRoleCapability(1, address(lpc), bytes4(sha3("take(address,uint128)")), true);
    }

    function setUp() {
        ref = new DSTokenBase(10 ** 24);
        alt = new DSTokenBase(10 ** 24);
        lps = new DSToken('LPS', 'LPS', 18);

        pip = new DSValue();
        pip.poke(bytes32(2 ether)); // 2 refs per gem

        var gap = 1.04 ether;

        tip = new Tip();

        lpc = new SaiLPC(ref, alt, pip, lps, tip);
        lpc.jump(gap);
        lps.setOwner(lpc);

        mom = new DSRoles();
        lpc.setAuthority(mom);
        mom.setRootUser(this, true);
        setRoles();

        t1 = new Tester(lpc);
        m1 = new Tester(lpc);
        m2 = new Tester(lpc);
        m3 = new Tester(lpc);

        mom.setUserRole(t1, 1, true);
        mom.setUserRole(m1, 1, true);
        mom.setUserRole(m2, 1, true);
        mom.setUserRole(m3, 1, true);

        alt.transfer(t1, 100 ether);
        ref.transfer(m1, 100 ether);
        ref.transfer(m2, 100 ether);
        ref.transfer(m3, 100 ether);
    }

    function testBasicLPC() {
        assertEqWad(lpc.per(), RAY);
        m1.pool(ref, 100 ether);
        assertEq(lps.balanceOf(m1), 100 ether);

        t1.take(ref, 50 ether);
        assertEq(ref.balanceOf(t1),  50 ether);
        assertEq(alt.balanceOf(lpc), 26 ether);
        assertEqWad(lpc.pie(), 102 ether);

        m2.pool(ref, 100 ether);
        assertEqWad(lpc.pie(), 202 ether);

        // m2 still has claim to $100 worth
        assertEqWad(rdiv(uint128(lps.balanceOf(m2)), lpc.per()), 100 ether);

        t1.take(ref, 50 ether);
        assertEqWad(lpc.pie(), 204 ether);

        pip.poke(bytes32(1 ether));  // 1 ref per gem

        m3.pool(ref, 100 ether);
        assertEqWad(lpc.pie(), 252 ether);

        // m3 has claim to $100
        assertEqWad(rdiv(uint128(lps.balanceOf(m3)), lpc.per()), 100 ether);
        // but m1, m2 have less claim each
        assertEqWad(rdiv(uint128(lps.balanceOf(m1) + lps.balanceOf(m2)), lpc.per()), 152 ether);
    }

    function testWarpLPC() {
        uint128 way = 999997417323343052486607343;  // 0.8 / day
        tip.coax(way);
        // t1 pools 100 ETH
        t1.pool(alt, 100 ether);

        // At time 0, we have a pie of 100 * 2 SAI
        assertEqWad(lpc.pie(), 200 ether);
        assertEqWad(lpc.per(), RAY);
        tip.warp(1 days);
        var par = ray(0.8 ether);
        // At time 1, we have a pie of 200 / 0.8 = 250 SAI
        var pie = rdiv(200 ether, par);
        assertEqWad(lpc.pie(), pie);
        assertEqWad(lpc.per(), par);

        tip.warp(1 days);
        par = rmul(par, par);
        // At time 2, we have a pie of 200 / (0.8 * 0.8) = 312.5 SAI
        pie = rdiv(200 ether, par);
        assertEqWad(lpc.pie(), pie);
        assertEqWad(lpc.per(), par);

        assertEq(lps.balanceOf(t1), 200 ether);

        // m1 takes 10 ETH
        m1.take(alt, 10 ether);
        assertEq(lps.balanceOf(m1), 0);
        assertEq(alt.balanceOf(m1), 10 ether);
        assertEq(alt.balanceOf(lpc), 90 ether);
        // m1 has to pay a value in SAI that is equivalent to 10 ETH adding the corresponding gap value
        uint128 refBalanceOfLPC = rdiv(wmul(wmul(10 ether, lpc.tag()), lpc.gap()), par);
        assertEq(ref.balanceOf(lpc), refBalanceOfLPC);
        pie += rdiv(wmul(wmul(10 ether, lpc.tag()), lpc.gap() - 1 ether), par);
        assertEqWad(lpc.pie(), pie);

        // m2 pools 100 SAI
        m2.pool(ref, 100 ether);
        assertEqWad(lpc.pie(), pie + 100 ether);

        tip.warp(1 days);
        // t1 exits all SAI in the system
        t1.exit(ref, refBalanceOfLPC + 100 ether);
        assertEq(ref.balanceOf(lpc), 0);
        assertEq(alt.balanceOf(lpc), 90 ether);

        // m2 exits the maximum LPS balance in ETH
        var maxAmountoExitM2 = wdiv(wmul(rdiv(wdiv(uint128(lps.balanceOf(m2)), lpc.gap()), lpc.per()), tip.par()), lpc.tag());
        m2.exit(alt, maxAmountoExitM2);
        assertEq(lps.balanceOf(m2), 0);
        assertEq(alt.balanceOf(lpc), 90 ether - maxAmountoExitM2);

        // t1 exits all the remaining ETH
        t1.exit(alt, 90 ether - maxAmountoExitM2);
        assertEqWad(lpc.pie(), 0);
    }
}
